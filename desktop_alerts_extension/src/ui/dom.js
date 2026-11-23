/** Tiny DOM helpers shared by the popup and the order-card window. */
import {resolveLang, translator} from '../lib/i18n.js';
import {DEFAULT_SETTINGS} from '../lib/storage.js';

/** `h('div', {class: 'x', onclick}, child, 'text')` — text is never parsed as HTML. */
export function h(tag, attrs = {}, ...children) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v == null || v === false) continue;
    if (k.startsWith('on') && typeof v === 'function') el.addEventListener(k.slice(2), v);
    else if (k === 'class') el.className = v;
    else if (k === 'dataset') Object.assign(el.dataset, v);
    else if (v === true) el.setAttribute(k, '');
    else el.setAttribute(k, String(v));
  }
  for (const c of children.flat()) {
    if (c == null || c === false) continue;
    el.append(c instanceof Node ? c : document.createTextNode(String(c)));
  }
  return el;
}

/** Current language + translator; sets <html lang/dir>. */
export async function setupLang() {
  const {settings} = await chrome.storage.local.get('settings');
  const s = {...DEFAULT_SETTINGS, ...(settings || {})};
  const lang = resolveLang(s.language, chrome.i18n.getUILanguage());
  document.documentElement.lang = lang;
  document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
  return {lang, t: translator(lang), settings: s};
}

/** Fills `[data-i18n]` text and `[data-i18n-placeholder]` placeholders. */
export function applyStaticText(t, root = document) {
  root.querySelectorAll('[data-i18n]').forEach((el) => {
    el.textContent = t(el.dataset.i18n);
  });
  root.querySelectorAll('[data-i18n-placeholder]').forEach((el) => {
    el.placeholder = t(el.dataset.i18nPlaceholder);
  });
  root.querySelectorAll('[data-i18n-title]').forEach((el) => {
    el.title = t(el.dataset.i18nTitle);
  });
}

/** Sends a command to the service worker; resolves to its result or throws {code}. */
export async function command(cmd, payload = {}) {
  const res = await chrome.runtime.sendMessage({cmd, ...payload});
  if (!res?.ok) {
    const err = new Error(res?.message || 'failed');
    err.code = res?.code || 'genericError';
    throw err;
  }
  return res.result;
}
