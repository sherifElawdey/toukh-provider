import test from 'node:test';
import assert from 'node:assert/strict';
import {egyptMobileE164, localPhone, syntheticEmail} from '../src/lib/phone.js';
import {_STRINGS_FOR_TEST, resolveLang, translator} from '../src/lib/i18n.js';
import {
  formatMoney, itemsLine, orderNotificationText, paymentLabel, summaryFromPush,
} from '../src/lib/format.js';
import {
  activeIds, addAlert, applySummaries, isNew, pruneSeen, resolve, ringAgain,
  ringAll, ringingIds, silence,
} from '../src/lib/alertState.js';
import {DEFAULT_SETTINGS, MIN_VOLUME, withPolicy} from '../src/lib/storage.js';
import {base64UrlToBytes, bytesToBase64Url, generateFid} from '../src/lib/b64.js';

const tEn = translator('en');
const tAr = translator('ar');

test('phone → the same login the Partner app uses', () => {
  for (const input of ['01012345678', '1012345678', '+20 101 234 5678', '201012345678', '010-1234-5678']) {
    assert.equal(egyptMobileE164(input), '+201012345678', input);
  }
  assert.equal(egyptMobileE164('12345'), '');
  assert.equal(egyptMobileE164('0101234567'), '');
  assert.equal(syntheticEmail('+201012345678'), 'provider201012345678@toukh.com');
  assert.equal(localPhone('+201012345678'), '01012345678');
});

test('both languages define every key', () => {
  const en = Object.keys(_STRINGS_FOR_TEST.en).sort();
  const ar = Object.keys(_STRINGS_FOR_TEST.ar).sort();
  assert.deepEqual(ar, en);
  assert.equal(resolveLang('auto', 'ar-EG'), 'ar');
  assert.equal(resolveLang('auto', 'en-US'), 'en');
  assert.equal(resolveLang('ar', 'en-US'), 'ar');
  assert.equal(tEn('accepted', {ref: '#AB12CD'}), 'Order #AB12CD accepted');
});

test('Arabic copy stays in the apps\' register (no street slang)', () => {
  const banned = /(مفيش|دلوقتي|لسه|عايز|يلا|بتاعك|دوس|الباسورد|كمّل|اتفرّج|حافيت|طوخ)/;
  for (const [k, v] of Object.entries(_STRINGS_FOR_TEST.ar)) assert.doesNotMatch(v, banned, k);
  assert.match(_STRINGS_FOR_TEST.ar.appName, /هافيت/);
});

const summary = {
  orderId: 'abcXYZ123',
  ref: '#XYZ123',
  customerName: 'Ahmed',
  itemCount: 5,
  lineCount: 4,
  items: [{name: 'Koshari', quantity: 2}, {name: 'Juice', quantity: 1}, {name: 'Rice', quantity: 1}, {name: 'Salad', quantity: 1}],
  totalEgp: 230,
  currency: 'EGP',
  paymentMethod: 'cash',
  isPaid: false,
  createdAtMs: Date.UTC(2026, 10, 13, 18, 5),
  businessName: 'Nile Restaurant',
  address: {formattedAddress: '15 Street, Maadi'},
  canAccept: true,
};

test('notification text carries the order essentials, not the phone', () => {
  const n = orderNotificationText({...summary, customerPhone: '+201000000000'}, tEn, 'en');
  assert.equal(n.title, 'NEW ORDER · #XYZ123');
  assert.match(n.message, /Ahmed · 5 items · 230 EGP · Cash on delivery/);
  assert.match(n.message, /2× Koshari, 1× Juice, 1× Rice, \+1 more/);
  assert.match(n.message, /15 Street, Maadi/);
  assert.doesNotMatch(n.message, /2010/);
  assert.match(n.contextMessage, /^Nile Restaurant · /);

  const ar = orderNotificationText(summary, tAr, 'ar');
  assert.match(ar.title, /^طلب جديد · #XYZ123$/);
  assert.match(ar.message, /الدفع عند الاستلام/);
  assert.match(ar.message, /، /);

  const pickup = orderNotificationText({...summary, fulfillmentMode: 'pickup'}, tEn, 'en');
  assert.match(pickup.message, /Pickup from store/);
});

test('payment and money labels', () => {
  assert.equal(paymentLabel({paymentMethod: 'wallet', isPaid: true}, tEn), 'Paid · HAVIT Pay');
  assert.equal(paymentLabel({paymentMethod: 'cash'}, tEn), 'Cash on delivery');
  assert.equal(formatMoney(230, 'EGP', 'en'), '230 EGP');
  assert.equal(formatMoney(12.5, 'EGP', 'en'), '12.5 EGP');
  assert.match(formatMoney(230, 'EGP', 'ar'), /ج\.م$/);
  assert.equal(itemsLine({items: [], lineCount: 0}, tEn), '');
});

test('push payload fallback when the summary can\'t be fetched', () => {
  const s = summaryFromPush({
    orderId: 'order0000ab12cd',
    payloadJson: JSON.stringify({customerName: 'Mona', totalEgp: 99, items: [{name: 'Tea', quantity: 3}]}),
  });
  assert.equal(s.ref, '#AB12CD');
  assert.equal(s.itemCount, 3);
  assert.equal(s.canAccept, true);
  assert.equal(s.partial, true);
  assert.equal(summaryFromPush({orderId: 'x', payloadJson: 'not json'}).customerName, null);
  assert.equal(summaryFromPush({orderId: 'x', payloadJson: '{"orderKind":"pharmacy_request"}'}).canAccept, false);
});

test('alert lifecycle: one alert per order, resolved anywhere stops it', () => {
  const now = 1_000_000_000;
  let st = {alerts: {}, seen: {}};
  assert.equal(isNew(st, 'o1'), true);
  st = addAlert(st, {orderId: 'o1', createdAtMs: now - 1000}, now);
  assert.equal(isNew(st, 'o1'), false);
  assert.deepEqual(ringingIds(st.alerts), ['o1']);

  // Accepted on the phone → poll returns incoming:false → resolved.
  const r = applySummaries(st.alerts, [{orderId: 'o1', found: true, incoming: false}]);
  assert.deepEqual(r.resolved, ['o1']);
  assert.deepEqual(activeIds(r.alerts), []);
  // Still seen: a late duplicate push won't alert again.
  assert.equal(isNew({alerts: r.alerts, seen: st.seen}, 'o1'), false);

  // Archived / missing orders count as resolved too.
  st = addAlert(st, {orderId: 'o2', createdAtMs: now}, now);
  assert.deepEqual(applySummaries(st.alerts, [{orderId: 'o2', found: false}]).resolved, ['o2']);
});

test('every waiting order rings until handled — old ones too, no timeout', () => {
  const now = 2_000_000_000;
  let st = addAlert({alerts: {}, seen: {}}, {orderId: 'a', createdAtMs: now}, now);
  st = addAlert(st, {orderId: 'old', createdAtMs: now - 6 * 3600e3}, now);
  assert.deepEqual(ringingIds(st.alerts).sort(), ['a', 'old']);

  // Paused only while an accept is in flight; a failed accept rings again.
  const accepting = silence(st.alerts, 'a');
  assert.deepEqual(ringingIds(accepting), ['old']);
  assert.deepEqual(ringingIds(ringAgain(accepting, 'a')).sort(), ['a', 'old']);
  assert.deepEqual(ringingIds(ringAll(accepting)).sort(), ['a', 'old']);

  assert.deepEqual(activeIds(resolve(st.alerts, 'a')), ['old']);
  const seen = pruneSeen({x: now - 4 * 864e5, y: now - 1000}, now);
  assert.deepEqual(Object.keys(seen), ['y']);
});

test('alert policy is mandatory: only tone and volume are the store\'s choice', () => {
  const s = withPolicy({...DEFAULT_SETTINGS, alertsEnabled: false, soundEnabled: false,
    repeat: false, repeatEverySec: 25, popupWindow: false, sound: 'chime', volume: 0});
  assert.equal(s.alertsEnabled, true);
  assert.equal(s.soundEnabled, true);
  assert.equal(s.repeat, true);
  assert.equal(s.repeatEverySec, 5);
  assert.equal(s.popupWindow, true);
  assert.equal(s.sound, 'chime');
  assert.equal(s.volume, MIN_VOLUME, 'volume can\'t go silent');
  assert.equal(withPolicy({...DEFAULT_SETTINGS, volume: 0.6}).volume, 0.6);
});

test('base64url and FIDs match the Firebase SDK format', () => {
  const bytes = new Uint8Array([251, 255, 0, 1, 2, 62, 63]);
  assert.deepEqual(base64UrlToBytes(bytesToBase64Url(bytes)), bytes);
  assert.doesNotMatch(bytesToBase64Url(bytes), /[+/=]/);
  for (let i = 0; i < 50; i++) assert.match(generateFid(), /^[cdef][\w-]{21}$/);
});
