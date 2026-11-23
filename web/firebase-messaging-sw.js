/* eslint-disable no-undef */

// Push notifications for the provider web app while the site is closed,
// in a background tab, or the browser is minimised.
//
// Browsers don't let a service worker play its own audio: a closed site
// gets the system notification sound. When a tab of the app is still open,
// the page plays the order alarm (see `toukh-notification` below).

const ORDER_ALERT_TYPES = new Set([
  'order_placed',
  'home_service_request_placed',
  'delivery_request',
  'driver_requested',
  'store_assigned',
]);

function isUrgent(data) {
  const type = data.type || '';
  return data.ring === '1' || ORDER_ALERT_TYPES.has(type) ||
    type.startsWith('ride_offer');
}

// Registered before the Firebase SDK so it runs first for every click,
// including notifications the SDK displayed itself.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  if (event.action === 'dismiss') return;
  const raw = event.notification.data || {};
  // Shown by the Firebase SDK: the FCM payload sits under FCM_MSG.
  const data = raw.FCM_MSG ? (raw.FCM_MSG.data || {}) : raw;
  event.waitUntil(openApp(data));
});

async function openApp(data) {
  const scope = self.registration.scope;
  const windows = await self.clients.matchAll({
    type: 'window',
    includeUncontrolled: true,
  });
  for (const client of windows) {
    if (client.url.startsWith(scope) && 'focus' in client) {
      client.postMessage({type: 'toukh-notification-click', data: data});
      return client.focus();
    }
  }
  // Closed site: reopen it; the app reads `toukh_notif` and opens the item.
  const url = new URL(scope);
  if (Object.keys(data).length > 0) {
    url.searchParams.set('toukh_notif', JSON.stringify(data));
  }
  return self.clients.openWindow(url.href);
}

importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyC51eQ97nsVL7Fv_uYlngnG7QCBSk7h3P0',
  authDomain: 'toukh-b5708.firebaseapp.com',
  projectId: 'toukh-b5708',
  storageBucket: 'toukh-b5708.firebasestorage.app',
  messagingSenderId: '919479487381',
  appId: '1:919479487381:web:addf15415897f372f1449c',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(async (payload) => {
  const notification = payload.notification || {};
  const data = payload.data || {};
  const title = notification.title || data.title || 'Havit';
  const body = notification.body || data.body || data.description || '';
  const urgent = isUrgent(data);

  // An open but hidden tab rings the order alarm itself.
  const windows = await self.clients.matchAll({
    type: 'window',
    includeUncontrolled: true,
  });
  for (const client of windows) {
    client.postMessage({
      type: 'toukh-notification',
      title: title,
      body: body,
      urgent: urgent,
      data: data,
    });
  }

  // The SDK already shows messages that carry a notification block, with
  // the server's `webpush.notification` options (sticky, vibration…).
  if (payload.notification) return;

  const tag = data.notificationId || undefined;
  return self.registration.showNotification(title, {
    body: body,
    icon: 'icons/Icon-192.png',
    badge: 'icons/Icon-192.png',
    tag: tag,
    renotify: Boolean(tag),
    requireInteraction: urgent,
    silent: false,
    vibrate: urgent ? [400, 200, 400, 200, 400, 200, 400] : [200],
    data: data,
  });
});
