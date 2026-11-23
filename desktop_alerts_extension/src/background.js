/**
 * HAVIT Desktop Alerts — service worker.
 *
 * Delivery: the backend's `sendInboxPush` sends every store push to this
 * computer's FCM token (row in providers/{uid}/desktopDevices). Chrome wakes
 * this worker for each push even with no HAVIT tab and no Chrome window open,
 * as long as Chrome itself is running.
 *
 * Reliability nets for what push can't cover:
 *   - catch-up: on browser start, sign-in, and waking from sleep/lock, ask the
 *     server for orders still waiting (pushes may have expired meanwhile);
 *   - status poll: every 30 s while an alert is open, so an order accepted in
 *     the app or cancelled by the customer stops ringing here too;
 *   - heartbeat: every 6 h, refresh the push token and the device row.
 */
import {callFunction} from './lib/api.js';
import {AppError, SessionEndedError, signInWithPhone} from './lib/auth.js';
import {randomId} from './lib/b64.js';
import {resolveLang, translator} from './lib/i18n.js';
import {summaryFromPush} from './lib/format.js';
import {
  activeIds, addAlert, applySummaries, isNew, pruneSeen,
  resolve, ringAgain, ringAll, ringingIds, silence,
} from './lib/alertState.js';
import {
  clearNotification, closeAlertWindow, closeReminderWindow, isAlertWindowOpen,
  isReminderWindowOpen, openAlertWindow, openReminderWindow, openTab, setBadge,
  showInfo, showOrderNotification, showResult,
} from './lib/notify.js';
import {ensurePushToken, parsePushEvent, removePushToken} from './lib/push.js';
import {playOnce, startRinging, stopRinging} from './lib/sound.js';
import {
  getLocal, getSettings, orderUrl, removeLocal, saveSettings, setLocal,
} from './lib/storage.js';

const ALARM_HEARTBEAT = 'heartbeat';
const ALARM_POLL = 'poll';
const HEARTBEAT_MIN = 360;
const POLL_MIN = 0.5; // Chrome's minimum alarm period
const NEW_ORDER_TYPES = new Set(['order_placed']);
/** Other store pushes that deserve one sound (no repeat). */
const ATTENTION_TYPES = new Set(['home_service_request_placed', 'store_assigned', 'admin_urgent_alert']);

// ---- small utilities --------------------------------------------------------

/** Serializes read-modify-write of alerts so a push and a poll can't race. */
let chain = Promise.resolve();
function locked(fn) {
  const run = chain.then(fn, fn);
  chain = run.catch(() => {});
  return run;
}

async function i18n() {
  const settings = await getSettings();
  const lang = resolveLang(settings.language, chrome.i18n.getUILanguage());
  return {settings, lang, t: translator(lang)};
}

async function signedIn() {
  const {session} = await getLocal('session');
  return session?.uid ? session : null;
}

async function setDevice(patch) {
  const {device} = await getLocal('device');
  const next = {...(device || {}), ...patch};
  await setLocal({device: next});
  return next;
}

async function ensureDeviceId() {
  const {device} = await getLocal('device');
  if (device?.deviceId) return device;
  return setDevice({deviceId: `dsk_${randomId(24)}`});
}

function platformLabel() {
  const p = navigator.userAgentData?.platform || navigator.platform || '';
  if (/mac/i.test(p)) return 'macOS';
  if (/win/i.test(p)) return 'Windows';
  if (/cros/i.test(p) || /chrome os/i.test(p)) return 'ChromeOS';
  if (/linux/i.test(p)) return 'Linux';
  return p.slice(0, 40) || 'unknown';
}

// ---- session & device registration -----------------------------------------

/**
 * Makes sure this computer has a push token and a current device row.
 * Safe to call any time; records the outcome for the popup's status line.
 */
async function syncDevice({force = false} = {}) {
  if (!(await signedIn())) return;
  const settings = await getSettings();
  await setDevice({status: 'connecting'});
  try {
    const base = await ensureDeviceId();
    const {device} = await ensurePushToken(base, {force});
    const result = await callFunction('registerDesktopAlertDevice', {
      deviceId: device.deviceId,
      fcmToken: device.fcmToken,
      enabled: true, // alerts are mandatory for stores
      label: settings.deviceLabel || `${platformLabel()} · Chrome`,
      platform: platformLabel(),
      extensionVersion: chrome.runtime.getManifest().version,
    });
    await setLocal({
      device: {...device, status: 'connected', errorCode: null, lastSyncAt: Date.now()},
      store: result.store,
    });
  } catch (e) {
    await handleError(e, {context: 'sync'});
  }
}

/**
 * Session problems sign out; anything else is recorded as a connection
 * problem only when it came from registering this computer (`markDevice`).
 */
async function handleError(e, {context, markDevice = true} = {}) {
  console.warn(`[HAVIT] ${context || 'error'}`, e);
  if (e instanceof SessionEndedError ||
      (e instanceof AppError && ['notStore', 'notActive'].includes(e.code))) {
    const {t} = await i18n();
    const code = e instanceof SessionEndedError ? 'sessionExpired' : e.code;
    await signOut({remote: false});
    await setLocal({lastSignOutReason: code});
    await showInfo('info:session', t('appName'), t(code), {sticky: true});
    return;
  }
  if (markDevice) await setDevice({status: 'error', errorCode: e?.code || 'genericError'});
}

async function signIn({phone, password}) {
  const {session, idToken} = await signInWithPhone(phone, password);
  await chrome.storage.session.set({idToken});
  await setLocal({session, lastSignOutReason: null, alerts: {}, seen: {}});
  await ensureDeviceId();
  await syncDevice({force: true});
  const {device} = await getLocal('device');
  if (device?.status !== 'connected') {
    // Keep the sign-in; the popup shows the connection problem with Retry.
    if (!(await signedIn())) {
      const {lastSignOutReason} = await getLocal('lastSignOutReason');
      throw new AppError(lastSignOutReason || 'genericError');
    }
  }
  await chrome.alarms.create(ALARM_HEARTBEAT, {periodInMinutes: HEARTBEAT_MIN});
  await catchUp();
}

/** Unregisters this computer (remote) and clears everything local. */
async function signOut({remote = true} = {}) {
  const {device} = await getLocal('device');
  if (remote && device?.deviceId) {
    await callFunction('unregisterDesktopAlertDevice', {deviceId: device.deviceId}).catch(() => {});
  }
  const cleared = await removePushToken(device || {}).catch(() => device);
  await locked(async () => {
    const {alerts} = await getLocal('alerts');
    for (const id of activeIds(alerts || {})) await clearNotification(`order:${id}`);
    await setLocal({alerts: {}, seen: {}});
  });
  await chrome.storage.session.remove('idToken');
  await removeLocal(['session', 'store']);
  await setLocal({device: {...(cleared || {}), status: 'signedOut'}});
  await chrome.alarms.clear(ALARM_HEARTBEAT);
  await chrome.alarms.clear(ALARM_POLL);
  await stopRinging();
  await closeAlertWindow();
  await closeReminderWindow();
  await setBadge(0);
}

// ---- alerts -----------------------------------------------------------------

/** Applies sound, badge, poll alarm and window to the current alerts. */
async function refreshSurfaces(alerts) {
  const settings = await getSettings();
  const ids = activeIds(alerts);
  await setBadge(ids.length);
  if (ringingIds(alerts).length > 0) await startRinging(settings);
  else await stopRinging();
  if (ids.length > 0) {
    const existing = await chrome.alarms.get(ALARM_POLL);
    if (!existing) await chrome.alarms.create(ALARM_POLL, {periodInMinutes: POLL_MIN});
  } else {
    await chrome.alarms.clear(ALARM_POLL);
  }
}

/** New orders: an OS notification each, and the order card window, always. */
async function presentNewOrders(summaries) {
  if (summaries.length === 0) return;
  const {t, lang} = await i18n();
  for (const s of summaries) await showOrderNotification(s, t, lang);
  await closeReminderWindow(); // the full card lists every waiting order
  await openAlertWindow({focus: true});
}

async function fetchSummaries(orderIds) {
  const res = await callFunction('getDesktopOrderAlerts', orderIds ? {orderIds} : {});
  return Array.isArray(res?.orders) ? res.orders : [];
}

async function onNewOrderPush(data) {
  const orderId = String(data.orderId || '').trim();
  if (!orderId) return;

  await locked(async () => {
    const state = await getLocal(['alerts', 'seen']);
    const st = {alerts: state.alerts || {}, seen: state.seen || {}};
    if (!isNew(st, orderId)) return; // one alert per order

    let summary;
    try {
      [summary] = await fetchSummaries([orderId]);
    } catch (e) {
      // Offline or slow backend: alert from the push itself rather than miss it.
      console.warn('[HAVIT] summary fetch failed, using push payload', e);
      summary = summaryFromPush(data);
    }
    if (!summary?.found || !summary.incoming) {
      await setLocal({seen: {...st.seen, [orderId]: Date.now()}});
      return; // accepted / cancelled before it got here
    }
    const next = addAlert(st, summary);
    await setLocal(next);
    await presentNewOrders([summary]);
    await refreshSurfaces(next.alerts);
  });
}

/** Orders still waiting that this computer hasn't alerted yet. */
async function catchUp() {
  if (!(await signedIn())) return;
  try {
    const waiting = await fetchSummaries(null);
    await locked(async () => {
      const state = await getLocal(['alerts', 'seen']);
      let st = {alerts: state.alerts || {}, seen: pruneSeen(state.seen || {})};
      const fresh = waiting.filter((s) => isNew(st, s.orderId));
      for (const s of fresh) st = addAlert(st, s);
      await setLocal(st);
      await presentNewOrders(fresh);
      await refreshSurfaces(st.alerts);
    });
    await poll();
  } catch (e) {
    await handleError(e, {context: 'catchUp', markDevice: false});
  }
}

/**
 * Drops alerts whose orders were handled anywhere (that stops their sound);
 * everything still waiting keeps ringing.
 */
async function poll() {
  await locked(async () => {
    const {alerts = {}, accepting = {}} = await getLocal(['alerts', 'accepting']);
    let next = ringAll(alerts);
    for (const id of Object.keys(accepting)) if (alerts[id]) next = {...next, [id]: alerts[id]};
    const ids = activeIds(next);
    if (ids.length === 0) {
      await setLocal({alerts: next});
      await refreshSurfaces(next);
      return;
    }
    try {
      const summaries = await fetchSummaries(ids);
      const applied = applySummaries(next, summaries);
      next = applied.alerts;
      for (const id of applied.resolved) await clearNotification(`order:${id}`);
    } catch (e) {
      if (e instanceof SessionEndedError) throw e;
      console.warn('[HAVIT] poll failed', e);
    }
    await setLocal({alerts: next});
    await refreshSurfaces(next);
    await ensureOrderPrompt(next);
  }).catch((e) => handleError(e, {context: 'poll', markDevice: false}));
}

/** Pauses one order's ring while its accept is in flight. */
async function silenceOrder(orderId) {
  await locked(async () => {
    const {alerts = {}} = await getLocal('alerts');
    const next = silence(alerts, orderId);
    await setLocal({alerts: next});
    await refreshSurfaces(next);
  });
}

async function ringOrderAgain(orderId) {
  await locked(async () => {
    const {alerts = {}} = await getLocal('alerts');
    const next = ringAgain(alerts, orderId);
    await setLocal({alerts: next});
    await refreshSurfaces(next);
  });
}

async function resolveOrder(orderId) {
  await locked(async () => {
    const {alerts = {}} = await getLocal('alerts');
    const next = resolve(alerts, orderId);
    await setLocal({alerts: next});
    await refreshSurfaces(next);
  });
  await clearNotification(`order:${orderId}`);
}

/** Opens the order; it keeps ringing until it is accepted or otherwise handled. */
async function viewOrder(orderId) {
  const settings = await getSettings();
  if (settings.dashboardUrl) {
    await openTab(orderUrl(settings.dashboardUrl, orderId));
  } else {
    await openAlertWindow({focus: true, query: `?order=${encodeURIComponent(orderId)}`});
  }
}

async function openDashboard() {
  const settings = await getSettings();
  if (settings.dashboardUrl) await openTab(`${settings.dashboardUrl}/#/orders`);
  else await openAlertWindow({focus: true});
}

/**
 * While orders wait, the order card or — once the card was closed — the
 * smaller reminder must be on screen; with nothing waiting the reminder goes.
 */
async function ensureOrderPrompt(alerts) {
  if (activeIds(alerts).length === 0) {
    await closeReminderWindow();
    return;
  }
  if (await isAlertWindowOpen() || await isReminderWindowOpen()) return;
  await openReminderWindow({focus: true});
}

const ACTIONS = {
  accept: {fn: 'acceptProviderOrderFromDesktop', failed: 'acceptFailed'},
  decline: {fn: 'declineProviderOrderFromDesktop', failed: 'declineFailed'},
};

/**
 * Accept or decline through the backend's guarded callables (same rules and
 * same slice update as the app). The ring pauses while the call runs and
 * comes back if the order is still waiting afterwards.
 */
async function actOnOrder(orderId, action) {
  const {t} = await i18n();
  const {fn, failed} = ACTIONS[action];
  const {alerts = {}} = await getLocal('alerts');
  const ref = alerts[orderId]?.summary?.ref || `#${orderId.slice(-6).toUpperCase()}`;
  await silenceOrder(orderId);
  await setLocal({accepting: {...((await getLocal('accepting')).accepting || {}), [orderId]: action}});
  try {
    const r = await callFunction(fn, {masterOrderId: orderId});
    if (r?.ok && action === 'decline') {
      await resolveOrder(orderId);
      await showResult(orderId, t('declined', {ref}), '');
      return {ok: true};
    }
    if (r?.ok) {
      await resolveOrder(orderId);
      if (r.followUp === 'request_courier') {
        await showResult(orderId, t('acceptedCourier', {ref}), '');
        await setLocal({pendingCourier: {orderId}});
      } else {
        await showResult(orderId, t('accepted', {ref}), t('acceptedBody'));
      }
      return {ok: true, followUp: r.followUp || null};
    }
    const reason = r?.reason;
    if (reason === 'not_pending' || reason === 'not_found') {
      await resolveOrder(orderId);
      await showResult(orderId, t('alreadyHandled', {ref}), '');
    } else if (reason === 'in_progress') {
      await ringOrderAgain(orderId); // until the other computer's accept lands
      await showResult(orderId, t('inProgress', {ref}), '');
    } else {
      // Pharmacy quote, system-managed, store-courier: finish in the dashboard.
      await ringOrderAgain(orderId);
      await showResult(orderId, t('needsDashboard', {ref}), '');
      await viewOrder(orderId);
    }
    return {ok: false, reason};
  } catch (e) {
    if (e instanceof SessionEndedError) {
      await handleError(e, {context: 'accept'});
    } else {
      await ringOrderAgain(orderId);
      await showInfo(`result:${orderId}`, t(failed, {ref}), '', {sticky: true});
    }
    return {ok: false, reason: e?.code || 'genericError'};
  } finally {
    const {accepting = {}} = await getLocal('accepting');
    delete accepting[orderId];
    await setLocal({accepting});
    const {alerts: after = {}} = await getLocal('alerts');
    await ensureOrderPrompt(after);
  }
}

async function sendTestAlert() {
  const {settings, t, lang} = await i18n();
  const sample = {
    orderId: 'test',
    ref: '#TEST01',
    customerName: lang === 'ar' ? 'أحمد محمود' : 'Ahmed Mahmoud',
    itemCount: 3,
    lineCount: 2,
    items: lang === 'ar' ?
      [{name: 'كشري كبير', quantity: 2}, {name: 'عصير مانجو', quantity: 1}] :
      [{name: 'Large koshari', quantity: 2}, {name: 'Mango juice', quantity: 1}],
    totalEgp: 185,
    currency: 'EGP',
    paymentMethod: 'cash',
    createdAtMs: Date.now(),
    address: {formattedAddress: lang === 'ar' ? 'شارع ٩، المعادي' : '9 Street, Maadi'},
    canAccept: false,
  };
  const {store} = await getLocal('store');
  sample.businessName = store?.name || t('appName');
  await showOrderNotification(sample, t, lang);
  await playOnce(settings);
  await openAlertWindow({focus: true, query: '?test=1'});
}

// ---- push -------------------------------------------------------------------

async function onPush(event) {
  const {data, notification} = parsePushEvent(event);
  if (!(await signedIn())) return;
  const type = String(data.type || '');

  if (NEW_ORDER_TYPES.has(type)) return onNewOrderPush(data);

  // Any other store push (customer cancelled, courier assigned, …): if it is
  // about an open alert, re-check it; then show it like the app's inbox does.
  const {alerts = {}} = await getLocal('alerts');
  if (data.orderId && alerts[data.orderId]) await poll();

  const settings = await getSettings();
  const title = notification?.title || data.title || 'HAVIT';
  const body = notification?.body || data.body || '';
  const key = data.notificationId || `${type}:${data.orderId || Date.now()}`;
  await setLocal({[`route:${key}`]: data.rootRoute || ''});
  await showInfo(`info:${key}`, title, body, {sticky: ATTENTION_TYPES.has(type)});
  if (ATTENTION_TYPES.has(type)) await playOnce(settings, 'notify');
}

self.addEventListener('push', (event) => {
  event.waitUntil(onPush(event).catch((e) => console.error('[HAVIT] push', e)));
});

self.addEventListener('pushsubscriptionchange', (event) => {
  event.waitUntil(syncDevice({force: true}));
});

// ---- lifecycle --------------------------------------------------------------

async function boot() {
  if (!(await signedIn())) {
    await setBadge(0);
    return;
  }
  await chrome.alarms.create(ALARM_HEARTBEAT, {periodInMinutes: HEARTBEAT_MIN});
  await syncDevice();
  await catchUp();
}

chrome.runtime.onInstalled.addListener(async ({reason}) => {
  await ensureDeviceId();
  if (reason === 'install') await chrome.action.openPopup?.().catch(() => {});
  await boot();
});

chrome.runtime.onStartup.addListener(() => boot());

chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (alarm.name === ALARM_HEARTBEAT) {
    await syncDevice();
  } else if (alarm.name === ALARM_POLL) {
    await poll();
  }
});

// Back from sleep or a locked screen: pushes may have expired meanwhile.
chrome.idle.onStateChanged.addListener((state) => {
  if (state === 'active') catchUp();
});

// ---- notification actions ---------------------------------------------------

function splitId(notificationId) {
  const i = notificationId.indexOf(':');
  return i < 0 ? [notificationId, ''] : [notificationId.slice(0, i), notificationId.slice(i + 1)];
}

chrome.notifications.onClicked.addListener(async (nid) => {
  const [kind, id] = splitId(nid);
  await clearNotification(nid);
  if (kind === 'order' || kind === 'result') {
    if (id && id !== 'test') return viewOrder(id);
  }
  if (kind === 'info') {
    const key = `route:${id}`;
    const {[key]: route} = await getLocal(key);
    await removeLocal(key);
    const settings = await getSettings();
    if (route && settings.dashboardUrl) return openTab(`${settings.dashboardUrl}/#${route}`);
    if (id === 'session') return chrome.action.openPopup?.().catch(() => {});
  }
  return openDashboard();
});

chrome.notifications.onButtonClicked.addListener(async (nid, index) => {
  const [kind, id] = splitId(nid);
  if (kind !== 'order' || !id || id === 'test') return clearNotification(nid);
  if (index === 0) return viewOrder(id);
  if (index === 1) return actOnOrder(id, 'accept');
});

// Closing a notification doesn't stop the sound: only handling the order does.
chrome.notifications.onClosed.addListener(async (nid) => {
  const [kind, id] = splitId(nid);
  if (kind === 'info') await removeLocal(`route:${id}`);
});

// Our own closes clear the stored id first, so a match here means the user
// closed it (X / exit). Closing the order card while orders still wait brings
// up the smaller reminder asking to accept, decline or open the order.
chrome.windows.onRemoved.addListener(async (windowId) => {
  const {alertWindowId, reminderWindowId} = await getLocal(['alertWindowId', 'reminderWindowId']);
  if (reminderWindowId === windowId) await removeLocal('reminderWindowId');
  if (alertWindowId === windowId) {
    await removeLocal('alertWindowId');
    const {alerts = {}} = await getLocal('alerts');
    if (activeIds(alerts).length > 0) await openReminderWindow({focus: true});
  }
});

// ---- messages from the popup and the order-card window ---------------------

const COMMANDS = {
  signIn: (m) => signIn(m),
  signOut: () => signOut(),
  retry: () => syncDevice({force: true}).then(catchUp),
  saveSettings: async (m) => {
    const before = await getSettings();
    const after = await saveSettings(m.patch);
    if (before.deviceLabel !== after.deviceLabel) await syncDevice();
    // A new tone or volume applies to the ring in progress.
    const {alerts = {}} = await getLocal('alerts');
    await refreshSurfaces(alerts);
    return after;
  },
  testAlert: () => sendTestAlert(),
  testSound: async () => playOnce(await getSettings()),
  accept: (m) => actOnOrder(m.orderId, 'accept'),
  decline: (m) => actOnOrder(m.orderId, 'decline'),
  view: (m) => viewOrder(m.orderId),
  openDashboard: () => openDashboard(),
  openOrders: async () => {
    await closeReminderWindow();
    await openAlertWindow({focus: true});
  },
  refresh: () => catchUp(),
};

chrome.runtime.onMessage.addListener((msg, sender, reply) => {
  if (msg?.target === 'offscreen' || sender.id !== chrome.runtime.id) return false;
  const run = COMMANDS[msg?.cmd];
  if (!run) return false;
  Promise.resolve(run(msg))
      .then((result) => reply({ok: true, result}))
      .catch((e) => reply({ok: false, code: e?.code || 'genericError', message: e?.message}));
  return true; // async reply
});
