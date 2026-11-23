/**
 * Desktop surfaces: the OS notification (chrome.notifications), the branded
 * order-card window, and the toolbar badge.
 *
 * Notification ids: `order:{id}` (new order, with actions), `result:{id}`
 * (after accept), `info:{key}` (other store pushes, errors), `test`.
 */
import {orderNotificationText} from './format.js';

// Absolute: a relative path resolves against src/ (the worker) and fails.
const ICON = chrome.runtime.getURL('assets/icons/icon-128.png');
const WINDOW_URL = 'src/alert/alert.html';
const WINDOW_SIZE = {width: 440, height: 720};

const create = (id, options) => new Promise((resolve) => {
  chrome.notifications.create(id, options, () => {
    const err = chrome.runtime.lastError;
    if (err) console.warn('[HAVIT] notification failed', id, err.message);
    resolve();
  });
});

export async function clearNotification(id) {
  await chrome.notifications.clear(id).catch(() => {});
}

/**
 * Stays on screen until acted on (`requireInteraction`); silent because the
 * extension plays its own HAVIT sound. Buttons: View order, Accept.
 */
export async function showOrderNotification(summary, t, lang) {
  const {title, message, contextMessage} = orderNotificationText(summary, t, lang);
  const buttons = [{title: t('viewOrder')}];
  if (summary.canAccept) buttons.push({title: t('accept')});
  await create(`order:${summary.orderId}`, {
    type: 'basic',
    iconUrl: ICON,
    title,
    message,
    contextMessage,
    buttons,
    priority: 2,
    requireInteraction: true,
    silent: true,
  });
}

export async function showInfo(id, title, message, {sticky = false, silent = true} = {}) {
  await create(id, {
    type: 'basic',
    iconUrl: ICON,
    title,
    message: message || '',
    priority: sticky ? 2 : 1,
    requireInteraction: sticky,
    silent,
  });
}

/** Replaces the order's notification with the outcome of an action. */
export async function showResult(orderId, title, message) {
  await clearNotification(`order:${orderId}`);
  await showInfo(`result:${orderId}`, title, message);
}

export async function setBadge(count) {
  await chrome.action.setBadgeBackgroundColor({color: '#D92D20'});
  await chrome.action.setBadgeText({text: count > 0 ? String(Math.min(count, 99)) : ''});
}

const WINDOWS = {
  card: {key: 'alertWindowId', url: WINDOW_URL, size: WINDOW_SIZE},
  // The smaller "act on this order" prompt shown after the card is closed.
  reminder: {key: 'reminderWindowId', url: 'src/reminder/reminder.html', size: {width: 380, height: 300}},
};

async function openWindow(kind, {focus = true, query = ''} = {}) {
  const {key, url, size} = WINDOWS[kind];
  const {[key]: windowId} = await chrome.storage.local.get(key);
  if (windowId) {
    try {
      const win = await chrome.windows.get(windowId, {populate: true});
      const tab = win.tabs?.[0];
      if (query && tab) await chrome.tabs.update(tab.id, {url: chrome.runtime.getURL(`${url}${query}`)});
      await chrome.windows.update(windowId, focus ? {focused: true, drawAttention: true} : {drawAttention: true});
      return;
    } catch (_) {
      // closed meanwhile
    }
  }
  let position = {};
  try {
    const anchor = await chrome.windows.getLastFocused();
    if (anchor?.left != null && anchor.width) {
      position = {
        left: Math.max(0, anchor.left + anchor.width - size.width - 16),
        top: Math.max(0, (anchor.top || 0) + 16),
      };
    }
  } catch (_) {
    // no Chrome window open: let Chrome place it
  }
  const win = await chrome.windows.create({
    url: chrome.runtime.getURL(`${url}${query}`),
    type: 'popup',
    focused: focus,
    ...size,
    ...position,
  });
  await chrome.storage.local.set({[key]: win.id});
}

async function closeWindow(kind) {
  const {key} = WINDOWS[kind];
  const {[key]: windowId} = await chrome.storage.local.get(key);
  if (!windowId) return;
  await chrome.storage.local.remove(key);
  await chrome.windows.remove(windowId).catch(() => {});
}

async function isOpen(kind) {
  const {key} = WINDOWS[kind];
  const {[key]: windowId} = await chrome.storage.local.get(key);
  if (!windowId) return false;
  try {
    await chrome.windows.get(windowId);
    return true;
  } catch (_) {
    await chrome.storage.local.remove(key);
    return false;
  }
}

/** Opens (or brings forward) the order-card window, top-right of the screen. */
export const openAlertWindow = (opts) => openWindow('card', opts);
export const closeAlertWindow = () => closeWindow('card');
export const isAlertWindowOpen = () => isOpen('card');

/** The compact "accept / decline / details" prompt. */
export const openReminderWindow = (opts) => openWindow('reminder', opts);
export const closeReminderWindow = () => closeWindow('reminder');
export const isReminderWindowOpen = () => isOpen('reminder');

/** Opens a URL in a normal Chrome window (creating one if none is open). */
export async function openTab(url) {
  try {
    const win = await chrome.windows.getLastFocused({windowTypes: ['normal']});
    if (win?.id != null) {
      await chrome.tabs.create({url, windowId: win.id, active: true});
      await chrome.windows.update(win.id, {focused: true});
      return;
    }
  } catch (_) {
    // fall through
  }
  await chrome.windows.create({url, focused: true, type: 'normal'});
}
