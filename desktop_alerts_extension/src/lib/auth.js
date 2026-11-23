/**
 * Firebase Auth over its REST API — the same accounts and password the
 * HAVIT Partner app signs in with. Only the refresh token is kept (local);
 * ID tokens live in session storage and expire within the hour.
 */
import {CONFIG} from '../config.js';
import {egyptMobileE164, syntheticEmail} from './phone.js';

const SIGN_IN_URL = `${CONFIG.endpoints.identityToolkit}/accounts:signInWithPassword`;
const REFRESH_URL = `${CONFIG.endpoints.secureToken}/token`;
const REFRESH_MARGIN_MS = 5 * 60 * 1000;

/** `code` is an i18n key the UI can show as-is. */
export class AppError extends Error {
  constructor(code, message, extra = {}) {
    super(message || code);
    this.code = code;
    Object.assign(this, extra);
  }
}

/** The stored login no longer works; the user must sign in again. */
export class SessionEndedError extends AppError {
  constructor(message) {
    super('sessionExpired', message);
  }
}

async function postJson(url, init) {
  let res;
  try {
    res = await fetch(url, init);
  } catch (e) {
    throw new AppError('networkError', e.message);
  }
  let body = {};
  try {
    body = await res.json();
  } catch (_) {
    body = {};
  }
  return {ok: res.ok, status: res.status, body};
}

function authErrorCode(message) {
  const m = String(message || '');
  if (/INVALID_LOGIN_CREDENTIALS|INVALID_PASSWORD|EMAIL_NOT_FOUND|INVALID_EMAIL/.test(m)) return 'wrongLogin';
  if (/TOO_MANY_ATTEMPTS/.test(m)) return 'tooMany';
  if (/USER_DISABLED/.test(m)) return 'notActive';
  return 'genericError';
}

/** Signs in; returns the session to store plus a fresh ID token. */
export async function signInWithPhone(phoneInput, password) {
  const phone = egyptMobileE164(phoneInput);
  if (!phone) throw new AppError('invalidPhone');
  if (!password) throw new AppError('wrongLogin');
  const {ok, body} = await postJson(`${SIGN_IN_URL}?key=${CONFIG.firebase.apiKey}`, {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
      email: syntheticEmail(phone, CONFIG.syntheticEmailDomain),
      password,
      returnSecureToken: true,
    }),
  });
  if (!ok) throw new AppError(authErrorCode(body?.error?.message), body?.error?.message);
  const session = {uid: body.localId, refreshToken: body.refreshToken, phone};
  const idToken = {
    token: body.idToken,
    expiresAt: Date.now() + Number(body.expiresIn || 3600) * 1000,
  };
  return {session, idToken};
}

let refreshing = null;

/**
 * A valid ID token for the stored session, refreshed when close to expiry.
 * Throws SessionEndedError when the account was disabled, deleted or its
 * password changed (refresh token revoked).
 */
export async function getIdToken({force = false} = {}) {
  const {session} = await chrome.storage.local.get('session');
  if (!session?.refreshToken) throw new SessionEndedError('signed out');
  const {idToken} = await chrome.storage.session.get('idToken');
  if (!force && idToken?.token && idToken.expiresAt - Date.now() > REFRESH_MARGIN_MS) {
    return idToken.token;
  }
  refreshing ??= (async () => {
    const {ok, body} = await postJson(`${REFRESH_URL}?key=${CONFIG.firebase.apiKey}`, {
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: new URLSearchParams({grant_type: 'refresh_token', refresh_token: session.refreshToken}),
    });
    if (!ok) {
      const msg = body?.error?.message || '';
      if (/TOKEN_EXPIRED|USER_DISABLED|USER_NOT_FOUND|INVALID_REFRESH_TOKEN|INVALID_GRANT_TYPE/.test(msg)) {
        throw new SessionEndedError(msg);
      }
      throw new AppError('networkError', msg);
    }
    const next = {
      token: body.id_token,
      expiresAt: Date.now() + Number(body.expires_in || 3600) * 1000,
    };
    await chrome.storage.session.set({idToken: next});
    if (body.refresh_token && body.refresh_token !== session.refreshToken) {
      await chrome.storage.local.set({session: {...session, refreshToken: body.refresh_token}});
    }
    return next.token;
  })().finally(() => {
    refreshing = null;
  });
  return refreshing;
}
