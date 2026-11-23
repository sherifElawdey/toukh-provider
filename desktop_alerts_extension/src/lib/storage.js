/**
 * chrome.storage layout
 *   local:   session {uid, refreshToken, phone}, store, device, settings,
 *            alerts, seen, alertWindowId
 *   session: idToken {token, expiresAt} — memory only, gone when Chrome quits.
 * The password is never stored.
 */
import {CONFIG} from '../config.js';

/**
 * Store policy, not user choices: alerts, sound, a repeat every 5 s until the
 * order is handled, and the order card window are always on. Applied over
 * whatever is stored, so older installs that switched something off are
 * switched back on.
 */
export const MANDATORY_SETTINGS = Object.freeze({
  alertsEnabled: true,
  soundEnabled: true,
  repeat: true,
  repeatEverySec: 5,
  popupWindow: true,
});

/** Lowest volume a store can set: the alert must stay audible. */
export const MIN_VOLUME = 0.2;

export const DEFAULT_SETTINGS = Object.freeze({
  sound: 'ring',
  volume: 0.8,
  language: 'auto',
  dashboardUrl: CONFIG.dashboardUrl,
  deviceLabel: '',
});

export const SOUNDS = Object.freeze({
  ring: 'assets/sounds/havit-ring.mp3',
  notify: 'assets/sounds/havit-notify.mp3',
  chime: 'assets/sounds/havit-chime.mp3',
});

export async function getLocal(keys) {
  return chrome.storage.local.get(keys);
}

export async function setLocal(values) {
  return chrome.storage.local.set(values);
}

export async function removeLocal(keys) {
  return chrome.storage.local.remove(keys);
}

export async function getSettings() {
  const {settings} = await getLocal('settings');
  return withPolicy({...DEFAULT_SETTINGS, ...(settings || {})});
}

/** Stored settings with the mandatory alert policy applied. */
export function withPolicy(settings) {
  const s = {...settings, ...MANDATORY_SETTINGS};
  s.volume = clampVolume(s.volume);
  return s;
}

export function clampVolume(v) {
  const n = Number(v);
  return Number.isFinite(n) ? Math.min(1, Math.max(MIN_VOLUME, n)) : DEFAULT_SETTINGS.volume;
}

/**
 * Validates and saves a settings patch; returns the full settings. Only the
 * tone and volume (plus language, computer name, dashboard address) can
 * change; the alert policy keys are ignored.
 */
export async function saveSettings(patch) {
  const current = await getSettings();
  const next = {...current};
  const p = patch || {};
  if (p.sound in SOUNDS) next.sound = p.sound;
  if (typeof p.volume === 'number') next.volume = clampVolume(p.volume);
  if (['auto', 'ar', 'en'].includes(p.language)) next.language = p.language;
  if (typeof p.deviceLabel === 'string') next.deviceLabel = p.deviceLabel.trim().slice(0, 60);
  if (typeof p.dashboardUrl === 'string') next.dashboardUrl = normalizeDashboardUrl(p.dashboardUrl);
  const stored = {...next};
  for (const k of Object.keys(MANDATORY_SETTINGS)) delete stored[k];
  await setLocal({settings: stored});
  return withPolicy(stored);
}

/** https only, no trailing slash or hash; '' clears it. */
export function normalizeDashboardUrl(raw) {
  const s = String(raw || '').trim();
  if (!s) return '';
  let u;
  try {
    u = new URL(s);
  } catch (_) {
    throw new Error('invalid_url');
  }
  if (u.protocol !== 'https:') throw new Error('invalid_url');
  return `${u.origin}${u.pathname}`.replace(/\/+$/, '');
}

export function orderUrl(dashboardUrl, orderId) {
  return `${dashboardUrl}/#/orders/${encodeURIComponent(orderId)}`;
}
