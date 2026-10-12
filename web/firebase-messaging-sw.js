/* eslint-disable no-undef */
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
  const clientList = await self.clients.matchAll({
    type: 'window',
    includeUncontrolled: true,
  });
  for (const client of clientList) {
    client.postMessage({
      type: 'toukh-notification',
      title: title,
      body: body,
    });
  }
  if (payload.notification) {
    return;
  }
  return self.registration.showNotification(title, {
    body: body,
    icon: 'icons/Icon-192.png',
  });
});
