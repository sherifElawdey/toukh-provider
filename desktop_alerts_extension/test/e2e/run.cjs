/* eslint-disable no-console */
/**
 * End-to-end test: the real extension in Chrome for Testing, the real backend
 * handlers (toukh/functions) on the in-memory Firestore used by its unit
 * tests, and a local stand-in for Google's Auth / Installations / FCM APIs.
 *
 * What is real: extension code, Chrome (service worker, notifications,
 * offscreen audio, windows, alarms), deliverProviderOrderIfNeeded →
 * sendInboxPush (the FCM message it builds), the desktop callables and
 * updateProviderOrderSlice. What is simulated: Google's servers and FCM's
 * relay — the message sendInboxPush builds is delivered to the extension's
 * service worker with DevTools' push delivery (ServiceWorker.deliverPushMessage).
 *
 * Run: npm i -D puppeteer && npm run e2e   (from the extension folder)
 * Env: E2E_OUT=dir for screenshots; HEADFUL=1 to watch.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');
const http = require('http');
const assert = require('assert/strict');

const EXT_SRC = path.resolve(__dirname, '../..');
const FUNCTIONS = path.resolve(EXT_SRC, '../../toukh/functions');
const OUT = process.env.E2E_OUT || fs.mkdtempSync(path.join(os.tmpdir(), 'havit-e2e-'));
const puppeteer = require(process.env.PUPPETEER_PATH || 'puppeteer');

// ---- backend: real handlers, in-memory Firestore, captured FCM -------------
const fcmMessages = [];
const messagingPath = require.resolve('firebase-admin/messaging', {paths: [FUNCTIONS]});
require.cache[messagingPath] = {
  id: messagingPath, filename: messagingPath, loaded: true,
  exports: {getMessaging: () => ({
    sendEachForMulticast: async (m) => {
      fcmMessages.push(m);
      return {successCount: m.tokens.length, responses: m.tokens.map(() => ({success: true}))};
    },
  })},
};
const dbPath = require.resolve(path.join(FUNCTIONS, 'db.js'));
require.cache[dbPath] = {id: dbPath, filename: dbPath, loaded: true, exports: {ensureApp: () => {}, getDb: () => db}};

const {FakeFirestore} = require(path.join(FUNCTIONS, 'test/helpers/fakeFirestore'));
const {deliverProviderOrderIfNeeded} = require(path.join(FUNCTIONS, 'notifications/deliverProviderOrderIfNeeded'));
const devices = require(path.join(FUNCTIONS, 'desktopAlerts/desktopDevices'));
const orders = require(path.join(FUNCTIONS, 'desktopAlerts/desktopOrderAlerts'));

const db = new FakeFirestore();
const UID = 'p1';
const PHONE = '01012345678';
const PASSWORD = 'secret123';
const CALLABLES = {
  registerDesktopAlertDevice: devices.registerDesktopAlertDeviceHandler,
  unregisterDesktopAlertDevice: devices.unregisterDesktopAlertDeviceHandler,
  getDesktopOrderAlerts: orders.getDesktopOrderAlertsHandler,
  acceptProviderOrderFromDesktop: orders.acceptProviderOrderFromDesktopHandler,
  declineProviderOrderFromDesktop: orders.declineProviderOrderFromDesktopHandler,
};
const calls = [];
const fcmRegistrations = [];

async function seed() {
  await db.doc(`providers/${UID}`).set({
    name: 'مطعم النيل',
    status: 'active',
    address: '١٢ شارع التحرير، الدقي، الجيزة',
    city: 'giza',
    fcmTokens: ['phone-token-1'],
    deliveryConfig: {offersDelivery: false, manageFromAccount: false},
  });
  await db.doc('users/c1').set({name: 'Ahmed'});
}

async function placeOrder(id, extra = {}) {
  await db.doc(`masterOrders/${id}`).set({
    clientId: 'c1',
    providerIds: [UID],
    paymentMethod: 'cash',
    isPaid: false,
    globalStatus: 'pending',
    providerStatusMap: {[UID]: 'pending'},
    providerOrderRefs: [{providerId: UID, providerName: 'مطعم النيل'}],
    createdAt: new Date(),
    providerSlices: {[UID]: {
      status: 'placed', providerState: 'pending', fulfillmentMode: 'courier',
      customerId: 'c1', customerName: 'أحمد محمود', customerPhone: '+201011112222',
      deliveryAddress: {title: 'البيت', formattedAddress: '١٥ شارع ٩، المعادي', buildingNumber: '١٥', landmark: 'أمام البنك الأهلي', lat: 29.96, lng: 31.25},
      orderPrice: 205, deliveryPrice: 25, totalEgp: 230,
      items: [
        {name: 'كشري كبير', quantity: 2, unitPrice: 60, lineTotalEgp: 120},
        {name: 'عصير مانجو', quantity: 1, unitPrice: 35, lineTotalEgp: 35},
        {name: 'أرز بلبن', quantity: 2, unitPrice: 25, lineTotalEgp: 50},
      ],
      note: 'من غير بصل لو سمحت',
      createdAt: new Date(),
      ...extra,
    }},
  });
}

function setSliceStatus(id, status) {
  const m = db.raw(`masterOrders/${id}`);
  m.providerSlices[UID].status = status;
  return db.doc(`masterOrders/${id}`).set(m);
}

// ---- local stand-in for Google APIs + a fake dashboard ----------------------
const STATUS = {'invalid-argument': [400, 'INVALID_ARGUMENT'], 'unauthenticated': [401, 'UNAUTHENTICATED'],
  'permission-denied': [403, 'PERMISSION_DENIED'], 'not-found': [404, 'NOT_FOUND'],
  'failed-precondition': [400, 'FAILED_PRECONDITION']};

function startServer() {
  const server = http.createServer(async (req, res) => {
    const url = new URL(req.url, 'http://x');
    let raw = '';
    for await (const c of req) raw += c;
    const json = (code, body) => {
      res.writeHead(code, {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'});
      res.end(JSON.stringify(body));
    };
    const p = url.pathname;
    try {
      if (p.endsWith('/accounts:signInWithPassword')) {
        const b = JSON.parse(raw);
        if (b.email !== 'provider201012345678@toukh.com' || b.password !== PASSWORD) {
          return json(400, {error: {message: 'INVALID_LOGIN_CREDENTIALS'}});
        }
        return json(200, {localId: UID, idToken: 'id-1', refreshToken: 'refresh-1', expiresIn: '3600'});
      }
      if (p.endsWith('/token')) return json(200, {id_token: 'id-2', refresh_token: 'refresh-1', expires_in: '3600'});
      if (p.endsWith('/installations')) {
        const b = JSON.parse(raw);
        assert.match(b.fid, /^[cdef][\w-]{21}$/);
        assert.equal(b.authVersion, 'FIS_v2');
        return json(200, {fid: b.fid, refreshToken: 'fis-refresh', authToken: {token: 'fis-auth', expiresIn: '604800s'}});
      }
      if (p.endsWith('authTokens:generate')) return json(200, {token: 'fis-auth', expiresIn: '604800s'});
      if (p.includes('/registrations')) {
        assert.equal(req.headers['x-goog-firebase-installations-auth'], 'FIS fis-auth');
        fcmRegistrations.push({method: req.method, path: p, body: raw ? JSON.parse(raw) : null});
        if (req.method === 'DELETE') return json(200, {});
        const b = JSON.parse(raw);
        assert.ok(b.web.endpoint && b.web.auth && b.web.p256dh, 'push subscription keys');
        return json(200, {token: 'fcm-desktop-token-e2e-0001'});
      }
      if (p.startsWith('/functions/')) {
        const name = p.split('/').pop();
        const auth = String(req.headers.authorization || '');
        if (!/^Bearer id-\d$/.test(auth)) return json(401, {error: {status: 'UNAUTHENTICATED', message: 'no token'}});
        const data = JSON.parse(raw || '{}').data;
        calls.push({name, data});
        try {
          const result = await CALLABLES[name](db, {auth: {uid: UID}, data});
          return json(200, {result});
        } catch (e) {
          const [code, status] = STATUS[e.code] || [500, 'INTERNAL'];
          return json(code, {error: {status, message: e.message, details: e.details}});
        }
      }
      if (p.startsWith('/dashboard')) {
        res.writeHead(200, {'Content-Type': 'text/html'});
        return res.end('<!doctype html><title>HAVIT Partner</title><h1>Dashboard</h1>');
      }
      json(404, {error: {message: 'not found'}});
    } catch (e) {
      console.error('server error', p, e);
      json(500, {error: {message: e.message}});
    }
  });
  return new Promise((r) => server.listen(0, '127.0.0.1', () => r(server)));
}

// ---- test copy of the extension pointed at the stand-in --------------------
function prepareExtension(base) {
  const dir = path.join(OUT, 'ext');
  fs.rmSync(dir, {recursive: true, force: true});
  fs.cpSync(EXT_SRC, dir, {recursive: true, filter: (s) => !/node_modules|[/\\]test([/\\]|$)/.test(s.slice(EXT_SRC.length))});
  const cfgPath = path.join(dir, 'src/config.js');
  let cfg = fs.readFileSync(cfgPath, 'utf8');
  cfg = cfg
      .replace(/functionsBase: '[^']+'/, `functionsBase: '${base}/functions'`)
      .replace(/identityToolkit: '[^']+'/, `identityToolkit: '${base}/identitytoolkit/v1'`)
      .replace(/secureToken: '[^']+'/, `secureToken: '${base}/securetoken/v1'`)
      .replace(/installations: '[^']+'/, `installations: '${base}/fis/v1'`)
      .replace(/fcmRegistrations: '[^']+'/, `fcmRegistrations: '${base}/fcm/v1'`)
      .replace(/dashboardUrl: '[^']*'/, `dashboardUrl: '${base}/dashboard'`);
  fs.writeFileSync(cfgPath, cfg);
  const mPath = path.join(dir, 'manifest.json');
  const m = JSON.parse(fs.readFileSync(mPath, 'utf8'));
  m.host_permissions.push('http://127.0.0.1/*');
  m.content_security_policy.extension_pages = m.content_security_policy.extension_pages
      .replace('connect-src', `connect-src ${base}`);
  fs.writeFileSync(mPath, JSON.stringify(m, null, 2));
  return dir;
}

// ---- helpers ----------------------------------------------------------------
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function until(fn, label, timeout = 15000) {
  const end = Date.now() + timeout;
  let last;
  while (Date.now() < end) {
    try {
      last = await fn();
      if (last) return last;
    } catch (e) {
      last = e;
    }
    await sleep(250);
  }
  throw new Error(`timeout: ${label} (last: ${last && last.message ? last.message : JSON.stringify(last)})`);
}

/** The FCM web-push payload a browser receives for `message`. */
function webPushPayload(message) {
  return JSON.stringify({
    data: message.data,
    notification: message.notification || message.webpush?.notification ?
      {...(message.notification || {}), ...(message.webpush?.notification || {})} : undefined,
    from: '919479487381',
    priority: 'high',
    fcmMessageId: `e2e-${Date.now()}`,
  });
}

const results = [];
async function step(name, fn) {
  const t0 = Date.now();
  try {
    await fn();
    results.push({name, ok: true, ms: Date.now() - t0});
    console.log(`  ✔ ${name}`);
  } catch (e) {
    results.push({name, ok: false, error: e.message});
    console.log(`  ✖ ${name}\n      ${e.stack.split('\n').slice(0, 3).join('\n      ')}`);
    throw e;
  }
}

// ---- the run ----------------------------------------------------------------
(async () => {
  await seed();
  const server = await startServer();
  const base = `http://127.0.0.1:${server.address().port}`;
  const extDir = prepareExtension(base);
  console.log(`HAVIT Desktop Alerts e2e — screenshots: ${OUT}`);

  const browser = await puppeteer.launch({
    headless: !process.env.HEADFUL,
    pipe: true,
    enableExtensions: [extDir],
    args: ['--no-first-run', '--lang=en-US', '--autoplay-policy=no-user-gesture-required'],
  });
  let failed = false;
  const swLogsRef = [];
  try {
    const swTarget = await browser.waitForTarget((t) => t.type() === 'service_worker' && t.url().endsWith('/src/background.js'));
    const extId = new URL(swTarget.url()).host;
    const extUrl = (p) => `chrome-extension://${extId}/${p}`;
    var sw = await swTarget.worker();
    const swLogs = swLogsRef;
    const watchLogs = (w) => w.on('console', (m) => swLogs.push(`[sw:${m.type()}] ${m.text()}`));
    watchLogs(sw);
    const swEval = async (fn, ...args) => {
      // The worker may have been stopped and restarted (MV3); re-attach.
      try {
        return await sw.evaluate(fn, ...args);
      } catch (_) {
        const t = await browser.waitForTarget((x) => x.type() === 'service_worker' && x.url().startsWith(`chrome-extension://${extId}/`));
        sw = await t.worker();
        watchLogs(sw);
        return sw.evaluate(fn, ...args);
      }
    };
    const notifications = () => swEval(() => new Promise((r) => chrome.notifications.getAll(r)));
    const badge = () => swEval(() => chrome.action.getBadgeText({}));
    const local = (k) => swEval((key) => chrome.storage.local.get(key), k);
    const soundState = async () => {
      const t = browser.targets().find((x) => x.url().endsWith('/src/offscreen/offscreen.html'));
      if (!t) return {exists: false};
      const s = await t.createCDPSession();
      const r = await s.send('Runtime.evaluate', {expression: 'JSON.stringify(globalThis.havitSoundState?.())', returnByValue: true});
      await s.detach();
      return {exists: true, ...JSON.parse(r.result.value || '{}')};
    };
    const alertWindowPage = async () => {
      const t = await browser.waitForTarget((x) => x.url().includes('/src/alert/alert.html'), {timeout: 10000});
      const page = await t.page();
      await page.setViewport({width: 440, height: 720});
      return page;
    };

    // Push delivery through DevTools, as FCM would deliver it.
    const helper = await browser.newPage();
    await helper.goto(extUrl('src/popup/popup.html'));
    const cdp = await helper.createCDPSession();
    const regs = [];
    cdp.on('ServiceWorker.workerRegistrationUpdated', (e) => regs.push(...e.registrations));
    await cdp.send('ServiceWorker.enable');
    const registrationId = (await until(() => regs.find((r) => r.scopeURL.startsWith(`chrome-extension://${extId}/`)), 'sw registration')).registrationId;
    const deliver = async (message) => cdp.send('ServiceWorker.deliverPushMessage', {
      origin: `chrome-extension://${extId}`, registrationId, data: webPushPayload(message),
    });
    /** Backend places + notifies, exactly like onMasterOrderCreated. */
    const orderArrives = async (id, extra) => {
      await placeOrder(id, extra);
      fcmMessages.length = 0;
      const r = await deliverProviderOrderIfNeeded(db, {providerId: UID, orderId: id});
      assert.equal(r.sent, true, 'backend sent the push');
      const msg = fcmMessages[0];
      assert.ok(msg.tokens.includes('fcm-desktop-token-e2e-0001'), 'desktop token targeted');
      assert.ok(msg.tokens.includes('phone-token-1'), 'phone still targeted');
      await deliver(msg);
      return msg;
    };

    console.log('Sign-in & registration');
    const popup = helper;
    await popup.setViewport({width: 380, height: 600});
    await step('popup shows sign-in when signed out', async () => {
      await popup.waitForSelector('#view-signin:not([hidden])');
      await popup.screenshot({path: path.join(OUT, '01-popup-signin.png'), fullPage: true});
    });
    await step('wrong password is refused with a clear message', async () => {
      await popup.type('#phone', PHONE);
      await popup.type('#password', 'nope');
      await popup.click('#signin-btn');
      await popup.waitForSelector('#signin-error:not([hidden])');
      assert.match(await popup.$eval('#signin-error', (e) => e.textContent), /Wrong mobile number or password/);
    });
    await step('sign in → push token → device registered on the store', async () => {
      await popup.$eval('#password', (e) => (e.value = ''));
      await popup.type('#password', PASSWORD);
      await popup.click('#signin-btn');
      await popup.waitForSelector('#view-main:not([hidden])', {timeout: 20000});
      await until(async () => (await local('device')).device?.status === 'connected', 'connected');
      const rows = (await db.collection(`providers/${UID}/desktopDevices`).get()).docs.map((d) => d.data());
      assert.equal(rows.length, 1);
      assert.equal(rows[0].fcmToken, 'fcm-desktop-token-e2e-0001');
      assert.equal(rows[0].enabled, true);
      assert.ok(fcmRegistrations.some((r) => r.method === 'POST'), 'FCM registration called');
      assert.deepEqual(db.raw(`providers/${UID}`).fcmTokens, ['phone-token-1'], 'mobile tokens untouched');
      await popup.waitForFunction(() => document.querySelector('#conn-text').textContent === 'Connected');
      assert.equal(await popup.$eval('#store-name', (e) => e.textContent), 'مطعم النيل');
      await popup.screenshot({path: path.join(OUT, '02-popup-signed-in-en.png'), fullPage: true});
    });

    console.log('New order with every HAVIT page closed');
    await step('close every extension/HAVIT page', async () => {
      for (const p of await browser.pages()) if (p !== helper) await p.close();
      await helper.goto('about:blank');
      const pages = (await browser.pages()).map((p) => p.url());
      assert.deepEqual(pages, ['about:blank']);
    });
    let firstMsg;
    await step('order placed → backend push → OS notification with order details', async () => {
      firstMsg = await orderArrives('ord_e2e_ab12cd');
      const n = await until(async () => (await notifications())['order:ord_e2e_ab12cd'], 'notification');
      assert.ok(n);
      const alerts = (await local('alerts')).alerts;
      const s = alerts.ord_e2e_ab12cd.summary;
      assert.equal(s.ref, '#AB12CD');
      assert.equal(s.itemCount, 5);
      assert.equal(s.totalEgp, 230);
      assert.equal(s.paymentMethod, 'cash');
      assert.equal(s.customerPhone, null, 'phone never sent for a waiting order');
      assert.equal(alerts.ord_e2e_ab12cd.state, 'ringing');
      await until(async () => (await badge()) === '1', 'badge shows 1');
    });
    await step('alert sound is playing, repeating every 5 seconds', async () => {
      const s = await until(async () => {
        const st = await soundState();
        return st.exists && st.playing && st.looping ? st : null;
      }, 'sound playing');
      assert.match(s.src, /havit-ring\.mp3$/);
      assert.equal(s.repeat, true);
      assert.equal(s.periodMs, 5000);
    });
    let card;
    await step('order card window opens with the full order', async () => {
      card = await alertWindowPage();
      await card.waitForSelector('.order.ringing');
      const text = await card.$eval('.order', (e) => e.innerText);
      for (const want of ['NEW ORDER', '#AB12CD', '230 EGP', 'Cash on delivery', '5 items', 'أحمد محمود', 'المعادي', 'كشري كبير', 'من غير بصل']) {
        assert.ok(text.includes(want), `card shows ${want}`);
      }
      assert.ok(!text.includes('1011112222'), 'card hides the customer phone');
      assert.equal(await card.$('.order .phone'), null);
      assert.equal(await card.$('#silence-all'), null, 'no way to silence');
      await sleep(300);
      await card.screenshot({path: path.join(OUT, '03-order-card-en-dark.png')});
      await card.emulateMediaFeatures([{name: 'prefers-color-scheme', value: 'light'}]);
      await sleep(200);
      await card.screenshot({path: path.join(OUT, '03-order-card-en-light.png')});
      await card.emulateMediaFeatures([]);
    });
    await step('a duplicate push for the same order does not alert again', async () => {
      await deliver(firstMsg);
      await sleep(1500);
      const alerts = (await local('alerts')).alerts;
      assert.equal(Object.keys(alerts).length, 1);
      const getCalls = calls.filter((c) => c.name === 'getDesktopOrderAlerts' && c.data?.orderIds?.[0] === 'ord_e2e_ab12cd');
      assert.equal(getCalls.length, 1, 'no second summary fetch for a seen order');
    });
    await step('"View order" opens the dashboard on that order; it keeps ringing', async () => {
      await card.click('.order-actions .btn-primary');
      const tab = await until(async () => (await browser.pages()).find((p) => p.url().includes('/dashboard/#/orders/ord_e2e_ab12cd')), 'dashboard tab');
      assert.ok(tab);
      await sleep(1500);
      assert.equal((await local('alerts')).alerts.ord_e2e_ab12cd.state, 'ringing');
      assert.equal((await soundState()).looping, true, 'still ringing after View');
    });
    const reminderPage = async () => {
      const t = await browser.waitForTarget((x) => x.url().includes('/src/reminder/reminder.html'), {timeout: 70000});
      const page = await t.page();
      await page.setViewport({width: 380, height: 420});
      await page.waitForSelector('.row-order');
      return page;
    };
    /** Closes a window the way the user's X does (the stored id stays). */
    const userCloses = async (key) => {
      const {[key]: id} = await local(key);
      await swEval((wid) => chrome.windows.remove(wid), id);
    };
    let reminder;
    await step('closing the order card (X) opens the smaller accept / decline / details dialog', async () => {
      await userCloses('alertWindowId');
      reminder = await reminderPage();
      const text = await reminder.$eval('body', (e) => e.innerText);
      for (const want of ['An order is waiting for you', '#AB12CD', '230 EGP', 'أحمد محمود', 'Accept order', 'Decline', 'Order details']) {
        assert.ok(text.includes(want), `reminder shows ${want}`);
      }
      assert.ok(!text.includes('1011112222'), 'no phone in the reminder');
      assert.equal((await soundState()).looping, true, 'still ringing');
      await sleep(300);
      await reminder.screenshot({path: path.join(OUT, '06-reminder-en.png')});
    });
    await step('reminder "Order details" opens the order; it keeps ringing', async () => {
      const before = (await browser.pages()).filter((p) => p.url().includes('/dashboard/#/orders/ord_e2e_ab12cd')).length;
      await reminder.click('.btn-details');
      await until(async () => (await browser.pages()).filter((p) => p.url().includes('/dashboard/#/orders/ord_e2e_ab12cd')).length > before, 'details tab');
      assert.equal((await soundState()).looping, true);
    });
    await step('reminder "Decline" asks once, then declines through the backend', async () => {
      await reminder.bringToFront();
      await reminder.click('.btn-decline');
      await reminder.waitForSelector('.confirm');
      assert.match(await reminder.$eval('.confirm', (e) => e.innerText), /Decline order #AB12CD\?/);
      await sleep(200);
      await reminder.screenshot({path: path.join(OUT, '07-reminder-confirm-en.png')});
      assert.equal(db.raw('masterOrders/ord_e2e_ab12cd').providerSlices[UID].status, 'placed', 'nothing sent before confirming');
      await reminder.click('.confirm .btn-danger');
      await until(() => db.raw('masterOrders/ord_e2e_ab12cd').providerSlices[UID].status === 'cancelled', 'slice declined');
      const slice = db.raw('masterOrders/ord_e2e_ab12cd').providerSlices[UID];
      assert.equal(slice.providerState, 'rejected');
      assert.equal(slice.cancelReason, 'unavailable');
      assert.equal(slice.cancelledByRole, 'provider');
      assert.equal(db.raw('masterOrders/ord_e2e_ab12cd').globalStatus, 'cancelled');
      await until(async () => !(await local('alerts')).alerts.ord_e2e_ab12cd, 'resolved');
      await until(async () => !(await soundState()).looping, 'sound stopped');
      await until(async () => (await notifications())['result:ord_e2e_ab12cd'], 'declined notification');
      await until(async () => !browser.targets().some((x) => x.url().includes('/src/reminder/reminder.html')), 'reminder closed');
    });
    await step('reminder "Accept" accepts; a closed reminder comes back while an order waits', async () => {
      const dbg = (m) => process.env.E2E_DEBUG && console.log(`      · ${m} (${new Date().toISOString().slice(11, 19)})`);
      await orderArrives('ord_e2e_yz34ab');
      await alertWindowPage();
      dbg('card open');
      await userCloses('alertWindowId');
      reminder = await reminderPage();
      dbg('reminder open');
      await userCloses('reminderWindowId');
      await until(async () => !browser.targets().some((x) => x.url().includes('/src/reminder/reminder.html')), 'reminder closed');
      dbg('reminder closed');
      reminder = await reminderPage(); // back on the next status check (≤ 30 s)
      dbg('reminder back');
      await reminder.click('.btn-success');
      await until(() => db.raw('masterOrders/ord_e2e_yz34ab').providerSlices[UID].status === 'preparing', 'accepted');
      await until(async () => !(await soundState()).looping, 'sound stopped');
      await until(async () => !browser.targets().some((x) => x.url().includes('/src/reminder/reminder.html')), 'reminder closed');
    });

    console.log('Accept from the desktop');
    await step('second order → "Accept order" uses the backend accept', async () => {
      await orderArrives('ord_e2e_ef34gh');
      card = await alertWindowPage();
      await card.waitForSelector('.order.ringing');
      await until(async () => (await soundState()).looping, 'ringing again');
      const btn = await card.$$eval('.order', (els) => els.map((e) => e.querySelector('.ref').textContent));
      assert.ok(btn.includes('#EF34GH'));
      await card.evaluate(() => {
        const el = [...document.querySelectorAll('.order')].find((o) => o.querySelector('.ref').textContent === '#EF34GH');
        el.querySelector('.btn-success').click();
      });
      await until(() => db.raw('masterOrders/ord_e2e_ef34gh').providerSlices[UID].status === 'preparing', 'slice accepted');
      const slice = db.raw('masterOrders/ord_e2e_ef34gh').providerSlices[UID];
      assert.equal(slice.fulfillmentMode, 'courier', 'same patch the app sends for a courier store');
      assert.ok(slice.acceptedAt, 'acceptedAt set by updateProviderOrderSlice');
      await until(async () => (await notifications())['result:ord_e2e_ef34gh'], 'result notification');
      assert.equal((await notifications())['order:ord_e2e_ef34gh'], undefined);
      assert.equal((await local('alerts')).alerts.ord_e2e_ef34gh, undefined);
    });
    await step('accepting the same order again is refused (no double accept)', async () => {
      const r = await orders.acceptProviderOrderFromDesktopHandler(db, {auth: {uid: UID}, data: {masterOrderId: 'ord_e2e_ef34gh'}});
      assert.deepEqual(r, {ok: false, reason: 'not_pending', status: 'preparing'});
    });

    console.log('Handled elsewhere / missed while away');
    await step('order accepted on the phone → desktop stops ringing (status poll)', async () => {
      await orderArrives('ord_e2e_ij56kl');
      await until(async () => (await soundState()).looping, 'ringing');
      await setSliceStatus('ord_e2e_ij56kl', 'preparing');
      await until(async () => !(await local('alerts')).alerts.ord_e2e_ij56kl, 'resolved by poll', 70000);
      await until(async () => !(await soundState()).looping, 'sound stopped');
      assert.equal((await notifications())['order:ord_e2e_ij56kl'], undefined);
    });
    await step('order placed while the push was missed → caught up on wake', async () => {
      await placeOrder('ord_e2e_mn78op');
      const page = await browser.newPage();
      await page.goto(extUrl('src/popup/popup.html'));
      await page.evaluate(() => chrome.runtime.sendMessage({cmd: 'refresh'}));
      await until(async () => (await local('alerts')).alerts.ord_e2e_mn78op, 'caught up');
      await page.close();
    });
    await step('customer cancels → alert removed, phone/address no longer served', async () => {
      await setSliceStatus('ord_e2e_mn78op', 'cancelled');
      await until(async () => !(await local('alerts')).alerts.ord_e2e_mn78op, 'cancel resolved', 70000);
      const {orders: [s]} = await orders.getDesktopOrderAlertsHandler(db, {auth: {uid: UID}, data: {orderIds: ['ord_e2e_mn78op']}});
      assert.equal(s.customerPhone, null);
      assert.equal(s.address, null);
    });

    console.log('Settings, Arabic UI, sign-out');
    await step('alerts, sound, repeat and the card can\'t be switched off; tone and volume can change', async () => {
      const page = await browser.newPage();
      await page.setViewport({width: 380, height: 900});
      await page.goto(extUrl('src/popup/popup.html'));
      await page.waitForSelector('#view-main:not([hidden])');
      for (const sel of ['#alerts-enabled', '#sound-enabled', '#repeat', '#repeat-every', '#popup-window']) {
        assert.equal(await page.$(sel), null, `${sel} removed`);
      }
      const saved = await page.evaluate(() => chrome.runtime.sendMessage({cmd: 'saveSettings', patch: {
        alertsEnabled: false, soundEnabled: false, repeat: false, popupWindow: false, sound: 'chime', volume: 0,
      }}));
      const r = saved.result;
      assert.deepEqual([r.alertsEnabled, r.soundEnabled, r.repeat, r.repeatEverySec, r.popupWindow], [true, true, true, 5, true]);
      assert.equal(r.sound, 'chime');
      assert.equal(r.volume, 0.2, 'volume floor');
      const device = (await db.collection(`providers/${UID}/desktopDevices`).get()).docs[0].data();
      assert.equal(device.enabled, true);
      await page.evaluate(() => chrome.runtime.sendMessage({cmd: 'saveSettings', patch: {sound: 'ring', volume: 0.8}}));
      await page.screenshot({path: path.join(OUT, '02b-popup-settings.png'), fullPage: true});
      await page.close();
    });
    await step('phone shown only to a store delivering itself, once out for delivery', async () => {
      await placeOrder('ord_e2e_uv12wx', {fulfillmentMode: 'store', status: 'preparing'});
      const get = async () => (await orders.getDesktopOrderAlertsHandler(db, {auth: {uid: UID}, data: {orderIds: ['ord_e2e_uv12wx']}})).orders[0].customerPhone;
      assert.equal(await get(), null);
      await setSliceStatus('ord_e2e_uv12wx', 'out_for_delivery');
      assert.equal(await get(), '+201011112222');
    });
    await step('Arabic UI renders right-to-left', async () => {
      await orderArrives('ord_e2e_qr90st');
      const page = await browser.newPage();
      await page.setViewport({width: 380, height: 900});
      await page.goto(extUrl('src/popup/popup.html'));
      await page.evaluate(() => chrome.runtime.sendMessage({cmd: 'saveSettings', patch: {language: 'ar'}}));
      await page.reload();
      await page.waitForSelector('#view-main:not([hidden])');
      assert.equal(await page.evaluate(() => document.documentElement.dir), 'rtl');
      await page.waitForFunction(() => document.querySelector('#conn-text').textContent === 'متصل');
      await page.emulateMediaFeatures([{name: 'prefers-color-scheme', value: 'light'}]);
      await page.screenshot({path: path.join(OUT, '04-popup-signed-in-ar-light.png'), fullPage: true});
      const cardAr = await alertWindowPage();
      await cardAr.reload();
      await cardAr.waitForSelector('.order');
      assert.match(await cardAr.$eval('.badge-new', (e) => e.textContent), /طلب جديد/);
      await sleep(300);
      await cardAr.screenshot({path: path.join(OUT, '05-order-card-ar.png')});
      await userCloses('alertWindowId');
      const remAr = await reminderPage();
      await remAr.reload();
      await remAr.waitForSelector('.row-order');
      assert.equal(await remAr.evaluate(() => document.documentElement.dir), 'rtl');
      await sleep(300);
      await remAr.screenshot({path: path.join(OUT, '08-reminder-ar.png')});
      await page.evaluate(() => chrome.runtime.sendMessage({cmd: 'saveSettings', patch: {language: 'en'}}));
      await page.close();
    });
    await step('sign out unregisters this computer and clears local data', async () => {
      const page = await browser.newPage();
      await page.goto(extUrl('src/popup/popup.html'));
      await page.evaluate(() => chrome.runtime.sendMessage({cmd: 'signOut'}));
      await until(async () => (await db.collection(`providers/${UID}/desktopDevices`).get()).size === 0, 'row removed');
      assert.ok(fcmRegistrations.some((r) => r.method === 'DELETE'), 'FCM token deleted');
      const left = await local(['session', 'alerts', 'store']);
      assert.equal(left.session, undefined);
      assert.deepEqual(left.alerts, {});
      await until(async () => (await badge()) === '', 'badge cleared');
      await until(async () => !(await soundState()).looping, 'sound off');
      await page.close();
    });
  } catch (_) {
    failed = true;
    if (process.env.E2E_DEBUG) {
      console.log('--- service worker console ---\n' + swLogsRef.join('\n'));
      try {
        const st = await sw.evaluate(() => chrome.storage.local.get(['alerts', 'seen', 'device', 'settings']));
        console.log('--- storage ---\n' + JSON.stringify(st, null, 1).slice(0, 3000));
      } catch (e) {
        console.log('storage read failed', e.message);
      }
      console.log('--- callable calls ---\n' + calls.map((c) => `${c.name} ${JSON.stringify(c.data)}`).join('\n'));
    }
  } finally {
    await browser.close();
    server.close();
  }
  const passed = results.filter((r) => r.ok).length;
  console.log(`\n${passed}/${results.length} steps passed${failed ? ' — FAILED' : ''}`);
  fs.writeFileSync(path.join(OUT, 'results.json'), JSON.stringify(results, null, 2));
  process.exit(failed ? 1 : 0);
})();
