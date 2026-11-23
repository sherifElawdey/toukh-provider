import {localPhone} from '../lib/phone.js';
import {activeIds} from '../lib/alertState.js';
import {DEFAULT_SETTINGS, SOUNDS, withPolicy} from '../lib/storage.js';
import {applyStaticText, command, h, setupLang} from '../ui/dom.js';

const $ = (id) => document.getElementById(id);
const {t} = await setupLang();
applyStaticText(t);

// ---- sign in ----------------------------------------------------------------

$('signin-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const btn = $('signin-btn');
  const err = $('signin-error');
  err.hidden = true;
  btn.disabled = true;
  btn.textContent = t('signingIn');
  try {
    await command('signIn', {phone: $('phone').value, password: $('password').value});
    $('password').value = '';
  } catch (ex) {
    err.textContent = t(ex.code);
    err.hidden = false;
  } finally {
    btn.disabled = false;
    btn.textContent = t('signIn');
    await render();
  }
});

$('phone').addEventListener('input', (e) => {
  e.target.value = e.target.value.replace(/[^\d+\s-]/g, '');
});

// ---- settings controls ------------------------------------------------------

const save = (patch) => command('saveSettings', {patch}).catch(() => {});

const soundChoice = $('sound-choice');
for (const key of Object.keys(SOUNDS)) {
  soundChoice.append(h('button', {
    type: 'button',
    role: 'radio',
    'aria-checked': 'false',
    dataset: {sound: key},
    onclick: async () => {
      await save({sound: key});
      await command('testSound').catch(() => {});
    },
  }, t(`sound_${key}`)));
}

let volumeTimer = null;
$('volume').addEventListener('input', (e) => {
  clearTimeout(volumeTimer);
  const volume = Number(e.target.value) / 100;
  volumeTimer = setTimeout(() => save({volume}), 150);
});

$('play-sound').addEventListener('click', () => command('testSound').catch(() => {}));
$('test-alert').addEventListener('click', () => command('testAlert').catch(() => {}));
$('open-dashboard').addEventListener('click', () => command('openDashboard').then(() => window.close()));
$('pending-show').addEventListener('click', () => command('openOrders').then(() => window.close()));
$('conn-retry').addEventListener('click', async () => {
  $('conn-retry').disabled = true;
  await command('retry').catch(() => {});
  $('conn-retry').disabled = false;
});

$('sign-out').addEventListener('click', async () => {
  if (!confirm(t('signOutConfirm'))) return;
  await command('signOut').catch(() => {});
  await render();
});

$('advanced-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const msg = $('advanced-msg');
  const before = (await chrome.storage.local.get('settings')).settings?.language || 'auto';
  try {
    const next = await command('saveSettings', {patch: {
      deviceLabel: $('device-label').value,
      dashboardUrl: $('dashboard-url').value,
      language: $('language').value,
    }});
    if (next.language !== before) return location.reload();
    msg.textContent = t('saved');
  } catch (ex) {
    msg.textContent = t(ex.message === 'invalid_url' ? 'invalidUrl' : 'genericError');
  }
});

// ---- render -----------------------------------------------------------------

function setValue(el, prop, value) {
  if (document.activeElement !== el) el[prop] = value;
}

async function render() {
  const data = await chrome.storage.local.get([
    'session', 'store', 'device', 'settings', 'alerts', 'lastSignOutReason',
  ]);
  const signedIn = !!data.session?.uid;
  $('view-signin').hidden = signedIn;
  $('view-main').hidden = !signedIn;

  if (!signedIn) {
    if (data.lastSignOutReason && $('signin-error').hidden) {
      $('signin-error').textContent = t(data.lastSignOutReason);
      $('signin-error').hidden = false;
    }
    return;
  }

  const s = withPolicy({...DEFAULT_SETTINGS, ...(data.settings || {})});
  const store = data.store || {};
  $('hero-sub').textContent = store.name || t('tagline');
  $('store-name').textContent = store.name || '—';
  $('store-branch').textContent = store.branch || '';
  $('store-phone').textContent = localPhone(data.session.phone);
  if (store.logoUrl) {
    $('store-logo').src = store.logoUrl;
    $('store-logo').hidden = false;
  }

  // Waiting orders
  const count = activeIds(data.alerts || {}).length;
  $('pending').hidden = count === 0;
  $('pending-text').textContent = count === 1 ? t('oneActiveOrder') : t('activeOrders', {n: count});

  // Connection
  const status = data.device?.status;
  const dot = $('conn-dot');
  const ok = status === 'connected';
  dot.className = `dot ${ok ? 'ok' : status === 'connecting' ? 'warn' : 'bad'}`;
  $('conn-text').textContent = t(ok ? 'connected' : status === 'connecting' ? 'connecting' : 'disconnected');
  $('conn-retry').hidden = ok || status === 'connecting';
  $('conn-error').hidden = ok || status === 'connecting' || !data.device?.errorCode;
  $('conn-error').textContent = data.device?.errorCode ? t(data.device.errorCode) : '';
  $('device-text').textContent = s.deviceLabel || (navigator.userAgentData?.platform || 'Chrome');

  // OS / Chrome notification permission
  const level = await chrome.notifications.getPermissionLevel();
  const allowed = level === 'granted';
  $('perm-dot').className = `dot ${allowed ? 'ok' : 'bad'}`;
  $('perm-text').textContent = t(allowed ? 'allowed' : 'blocked');
  $('perm-help').hidden = allowed;

  // Settings
  soundChoice.querySelectorAll('button').forEach((b) => {
    b.setAttribute('aria-checked', String(b.dataset.sound === s.sound));
  });
  setValue($('volume'), 'value', Math.round(s.volume * 100));
  setValue($('device-label'), 'value', s.deviceLabel);
  setValue($('dashboard-url'), 'value', s.dashboardUrl);
  setValue($('language'), 'value', s.language);
}

let pending = null;
chrome.storage.onChanged.addListener((_changes, area) => {
  if (area !== 'local') return;
  clearTimeout(pending);
  pending = setTimeout(render, 50);
});

await render();
