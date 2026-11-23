/**
 * FCM web-push token for this extension's service worker.
 *
 * Does what the Firebase JS SDK's `getToken()` does, without bundling the
 * SDK (MV3 forbids remote code; this keeps the extension build-free):
 *   1. Push API subscription on the extension's own service worker.
 *   2. A Firebase Installation (FIS) for an auth token.
 *   3. FCM Registrations API: subscription → FCM token.
 * The token is what `sendInboxPush` sends to (via the desktop device row).
 * Runs in the service worker only.
 */
import {CONFIG} from '../config.js';
import {AppError} from './auth.js';
import {base64UrlToBytes, bytesToBase64Url, generateFid} from './b64.js';

/** Firebase's built-in web-push key (used when no project key is set). */
const DEFAULT_VAPID_KEY =
  'BDOU99-h67HcA6JeFXHbSNMu7e2yNNu3RzoMj8TM4W88jITfq7ZmPvIM1Iv-4_l2LxQcYwhqby2xGpWwzjfAnG4';
const FIS_BASE = CONFIG.endpoints.installations;
const FCM_BASE = CONFIG.endpoints.fcmRegistrations;
const SDK_VERSION = 'w:0.6.4';
/** The SDK refreshes its registration weekly; FCM drops tokens idle for months. */
const TOKEN_REFRESH_MS = 7 * 24 * 60 * 60 * 1000;

const vapidKey = () => CONFIG.vapidKey || DEFAULT_VAPID_KEY;
const {apiKey, projectId, appId} = CONFIG.firebase;

async function request(url, init) {
  let res;
  try {
    res = await fetch(url, init);
  } catch (e) {
    throw new AppError('networkError', e.message);
  }
  const text = await res.text();
  let body = {};
  try {
    body = text ? JSON.parse(text) : {};
  } catch (_) {
    body = {};
  }
  if (!res.ok) {
    throw new AppError('genericError', body?.error?.message || `HTTP ${res.status}`, {httpStatus: res.status});
  }
  return body;
}

// ---- 1. Push subscription ---------------------------------------------------

async function subscribe() {
  const reg = self.registration;
  const key = base64UrlToBytes(vapidKey());
  const existing = await reg.pushManager.getSubscription();
  if (existing) {
    const current = existing.options?.applicationServerKey;
    if (current && bytesToBase64Url(current) === bytesToBase64Url(key)) return existing;
    await existing.unsubscribe();
  }
  try {
    // Extensions may receive pushes without showing a notification
    // (Chrome 121+), so a duplicate push can be ignored quietly.
    return await reg.pushManager.subscribe({userVisibleOnly: false, applicationServerKey: key});
  } catch (_) {
    try {
      return await reg.pushManager.subscribe({userVisibleOnly: true, applicationServerKey: key});
    } catch (e) {
      throw new AppError('pushBlocked', e.message);
    }
  }
}

function subscriptionKeys(sub) {
  return {
    endpoint: sub.endpoint,
    auth: bytesToBase64Url(sub.getKey('auth')),
    p256dh: bytesToBase64Url(sub.getKey('p256dh')),
  };
}

// ---- 2. Firebase Installation ----------------------------------------------

async function createInstallation() {
  const body = await request(`${FIS_BASE}/projects/${projectId}/installations`, {
    method: 'POST',
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'x-goog-api-key': apiKey},
    body: JSON.stringify({fid: generateFid(), authVersion: 'FIS_v2', appId, sdkVersion: SDK_VERSION}),
  });
  return {
    fid: body.fid,
    refreshToken: body.refreshToken,
    authToken: body.authToken?.token,
    authExpiresAt: Date.now() + parseInt(body.authToken?.expiresIn || '0', 10) * 1000,
  };
}

async function refreshInstallationAuth(fis) {
  const body = await request(
      `${FIS_BASE}/projects/${projectId}/installations/${fis.fid}/authTokens:generate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'x-goog-api-key': apiKey,
          'Authorization': `FIS_v2 ${fis.refreshToken}`,
        },
        body: JSON.stringify({installation: {sdkVersion: SDK_VERSION, appId}}),
      });
  return {
    ...fis,
    authToken: body.token,
    authExpiresAt: Date.now() + parseInt(body.expiresIn || '0', 10) * 1000,
  };
}

async function installationAuth(device) {
  let fis = device.fis;
  if (!fis?.fid || !fis.refreshToken) return createInstallation();
  if (!fis.authToken || fis.authExpiresAt - Date.now() < 60 * 60 * 1000) {
    try {
      fis = await refreshInstallationAuth(fis);
    } catch (e) {
      // Installation deleted server-side: start a new one.
      if (e.httpStatus === 401 || e.httpStatus === 404) return createInstallation();
      throw e;
    }
  }
  return fis;
}

// ---- 3. FCM registration ----------------------------------------------------

function fcmHeaders(fis) {
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'x-goog-api-key': apiKey,
    'x-goog-firebase-installations-auth': `FIS ${fis.authToken}`,
  };
}

function fcmBody(keys) {
  const web = {
    // As the SDK sends it: the host of the service worker's scope.
    origin: new URL(self.registration.scope).host,
    endpoint: keys.endpoint,
    auth: keys.auth,
    p256dh: keys.p256dh,
  };
  if (vapidKey() !== DEFAULT_VAPID_KEY) web.applicationPubKey = vapidKey();
  return JSON.stringify({web});
}

/**
 * Returns `{device, changed}` with a current FCM token in `device.fcmToken`.
 * `device` is the stored device record; the caller persists the result.
 */
export async function ensurePushToken(device, {force = false} = {}) {
  const sub = await subscribe();
  const keys = subscriptionKeys(sub);
  const fis = await installationAuth(device);
  const sameSub = device.endpoint === keys.endpoint && device.p256dh === keys.p256dh;
  const fresh = device.tokenAt && Date.now() - device.tokenAt < TOKEN_REFRESH_MS;

  if (device.fcmToken && sameSub && fresh && !force) {
    return {device: {...device, fis}, changed: false};
  }

  let token = null;
  if (device.fcmToken && sameSub) {
    try {
      const body = await request(`${FCM_BASE}/projects/${projectId}/registrations/${device.fcmToken}`, {
        method: 'PATCH', headers: fcmHeaders(fis), body: fcmBody(keys),
      });
      token = body.token || null;
    } catch (_) {
      token = null; // fall through to a fresh registration
    }
  } else if (device.fcmToken) {
    await deleteRegistration(device.fcmToken, fis).catch(() => {});
  }
  if (!token) {
    const body = await request(`${FCM_BASE}/projects/${projectId}/registrations`, {
      method: 'POST', headers: fcmHeaders(fis), body: fcmBody(keys),
    });
    token = body.token;
  }
  if (!token) throw new AppError('genericError', 'FCM returned no token');

  return {
    device: {
      ...device,
      fis,
      fcmToken: token,
      endpoint: keys.endpoint,
      p256dh: keys.p256dh,
      tokenAt: Date.now(),
    },
    changed: token !== device.fcmToken,
  };
}

async function deleteRegistration(token, fis) {
  await request(`${FCM_BASE}/projects/${projectId}/registrations/${token}`, {
    method: 'DELETE', headers: fcmHeaders(fis),
  });
}

/** Best-effort teardown on sign-out. */
export async function removePushToken(device) {
  try {
    if (device?.fcmToken && device.fis) {
      const fis = await installationAuth(device);
      await deleteRegistration(device.fcmToken, fis);
    }
  } catch (_) {
    // The server row is already gone; FCM expires the token eventually.
  }
  try {
    const sub = await self.registration.pushManager.getSubscription();
    if (sub) await sub.unsubscribe();
  } catch (_) {
    // ignore
  }
  const {fis, ...rest} = device || {};
  return {...rest, fis, fcmToken: null, endpoint: null, p256dh: null, tokenAt: null};
}

/** Firebase web-push payload: {data, notification?, from, fcmMessageId}. */
export function parsePushEvent(event) {
  try {
    const json = event.data?.json() || {};
    return {data: json.data || {}, notification: json.notification || null, raw: json};
  } catch (_) {
    return {data: {}, notification: null, raw: null};
  }
}
