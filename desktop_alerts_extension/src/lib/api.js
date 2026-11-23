/**
 * Calls HAVIT Cloud Functions (`onCall`) over the callable HTTP protocol:
 * POST {data} with the user's Firebase ID token → {result} | {error}.
 */
import {CONFIG} from '../config.js';
import {AppError, getIdToken} from './auth.js';

const REASON_CODES = {
  not_provider: 'notStore',
  not_active: 'notActive',
};

async function post(name, data, token) {
  let res;
  try {
    res = await fetch(`${CONFIG.functionsBase}/${name}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify({data: data ?? {}}),
    });
  } catch (e) {
    throw new AppError('networkError', e.message);
  }
  let body = {};
  try {
    body = await res.json();
  } catch (_) {
    body = {};
  }
  return {status: res.status, body};
}

export async function callFunction(name, data) {
  let {status, body} = await post(name, data, await getIdToken());
  if (status === 401 || body?.error?.status === 'UNAUTHENTICATED') {
    ({status, body} = await post(name, data, await getIdToken({force: true})));
  }
  if (body && 'result' in body) return body.result;
  const err = body?.error || {};
  const reason = err.details?.reason;
  throw new AppError(
      REASON_CODES[reason] || 'genericError',
      err.message || `HTTP ${status}`,
      {status: err.status, reason},
  );
}
