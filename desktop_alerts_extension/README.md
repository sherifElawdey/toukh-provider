# HAVIT Desktop Alerts (Chrome extension)

Real-time new-order alerts for HAVIT stores (restaurants, pharmacies, supermarkets, shops) on their computers. Alerts still arrive when the HAVIT website is closed, every HAVIT tab is closed, or the user is working in another app. Chrome itself has to be running.

It works alongside the HAVIT Partner app and dashboard and doesn't replace them. It signs in with the same store account, receives the same order pushes, and accepts orders through the same backend logic.

## How it works

```
Customer places order
  → onMasterOrderCreated → deliverProviderOrderIfNeeded        (existing, unchanged)
  → sendInboxPush(recipient: "provider")                       (existing + desktop tokens)
      ├─ providers/{uid}.fcmTokens            → phones / web app (unchanged)
      └─ providers/{uid}/desktopDevices/*     → this extension   (new)
  → Chrome wakes the extension's service worker (no tab needed)
  → getDesktopOrderAlerts → native notification + order card window + HAVIT sound
  → View order  → {dashboardUrl}/#/orders/{id}
  → Accept order → acceptProviderOrderFromDesktop → updateProviderOrderSlice (existing)
```

| Piece | Where |
|---|---|
| Extension | `toukh_provider/desktop_alerts_extension/` (this folder; plain MV3, no build step) |
| Device registry + callables | `toukh/functions/desktopAlerts/` |
| Push fan-out to desktops | `toukh/functions/notifications/deliver.js` (`sendInboxPush`) |
| Callable exports | `toukh/functions/index.js` (`registerDesktopAlertDevice`, `unregisterDesktopAlertDevice`, `getDesktopOrderAlerts`, `acceptProviderOrderFromDesktop`, `declineProviderOrderFromDesktop`) |
| Deep link through splash/login | `toukh_provider/lib/core/router/pending_order_link.dart` + `provider_redirect.dart` |

### Reused, not duplicated

- **Accounts:** the Partner app login (`provider{E.164}@toukh.com` + password via Firebase Auth). The password is never stored; only the refresh token is kept.
- **Orders:** reads `masterOrders/{id}.providerSlices[uid]`, the same data the app reads.
- **Accept:** builds the exact patch `ProviderOrdersCubit.approve` sends (from the store's `deliveryConfig`) and runs the existing `updateProviderOrderSliceHandler`. The new callable only adds a "still waiting?" check and a 60-second per-order lock, so two computers can't accept the same order twice.
- **Notifications:** the existing `order_placed` push from `deliverProviderOrderIfNeeded`, which already has idempotency. No new trigger was added.
- **Brand:** the partner logo, the apps' `notify` and `ring` sounds, the `AppColors` palette, and the Cairo font.

### Accounts, branches and employees (current model)

HAVIT has **one login per store**. A branch is its own store account (`providers/{uid}`), and there are no separate employee accounts. So:

- Each computer signs in with its branch's account and only gets that branch's orders. The server sends each store's push only to that store's devices.
- Several employees or computers per branch: sign each computer in with the branch account. Each one becomes its own row in `providers/{uid}/desktopDevices` with its own tone and volume. A store can have up to 10 computers; the least recently active one is removed first.
- Signing out unregisters the computer on the server, deletes its FCM token, and clears all local data.

Per-employee logins and permissions would need a staff model in the backend that doesn't exist today. That is outside this feature.

### Which orders can be accepted from the desktop

The desktop offers **Accept** only for standard store orders that are still waiting (`placed` / `pending`). These open in the dashboard instead, as the app requires:

- pharmacy requests (they need a price quote),
- system-managed orders,
- store-courier orders,
- list ("qaima") orders.

When the store is the first to accept a multi-store courier order, the app asks it to request a courier next. The desktop says so and opens the order.

### Alert policy (not configurable by stores)

- Alerts are always on; there is no switch to turn them off on a computer.
- The sound always plays and repeats every 5 seconds (start to start). The 24-second ring loops back to back. It stops only when the order is handled: accepted (here, in the app or on another computer), cancelled, or quoted/answered in the dashboard. Viewing the order or closing the notification does not stop it.
- The order card window always opens for a new order.
- **Closing the order card (X) while an order is still waiting** opens a smaller dialog (`src/reminder/`) asking the store to act. For each waiting order it shows the order number, customer name, total and item count, with **Accept**, **Decline** and **Order details**.
  - Decline asks once to confirm, then calls `declineProviderOrderFromDesktop`. That sends the app's own decline (`status: cancelled`, `providerState: rejected`, reason `unavailable`, by `provider`) through `updateProviderOrderSlice`, which restores stock, records the timeline event and frees any courier.
  - Accept and decline share one per-order lock, so they can't both go through.
  - Pharmacy, system-managed and store-courier orders show only Order details, as in the app.
- If that smaller dialog is closed too, it comes back within about 30 seconds while an order still waits. It closes itself once nothing waits. A new order replaces it with the full card.
- Stores choose only the **tone** and the **volume**. Volume can't go below 20%.

### Customer details

Stores see the customer's **name and address** only. The phone number is removed on the server (`getDesktopOrderAlerts`). It is sent only when the store delivers the order itself (`fulfillmentMode: store`) **and** the order is `out_for_delivery`, so the store can call the customer on the way. Waiting orders, the only ones the extension lists, never include it.

### Duplicates, statuses, cleanup

- One alert per order: orders already seen are remembered for 3 days, and the backend's `providerPushSentAt` already prevents duplicate sends.
- While any alert is open, the extension re-checks it every 30 seconds. An order accepted in the app, accepted on another computer, cancelled by the customer, or archived stops ringing everywhere within about 30 seconds.
- Address is only returned while the order is open; the phone rule is above.
- If FCM reports a dead desktop token, the server deletes that device row. The extension's 6-hourly heartbeat re-registers the computer if it's still installed.
- **Catch-up:** when the browser starts, when someone signs in, and when the computer wakes from sleep or lock, the extension asks the server for orders still waiting. Pushes can expire while a computer is off, and this covers that. Every order still waiting rings, however old.

## Limits (what this can't do)

Chrome and the operating system decide when code can run. The extension cannot:

- receive alerts while **Chrome is fully quit**. On macOS, closing windows is fine but ⌘Q quits Chrome. On Windows, Chrome keeps running in the tray after the last window closes (the extension asks for the `background` permission, and "Continue running background apps when Google Chrome is closed" must stay on).
- receive alerts while the **computer is asleep or off**. Missed orders are caught up when it wakes.
- show anything if the **OS blocks Chrome's notifications** or Focus / Do Not Disturb is on. The popup shows the permission state. Sound still plays when notifications are hidden.
- play sound if the computer itself is muted.

## Setup and deployment

### 1. Backend (Cloud Functions)

```bash
cd toukh/functions
npm test                              # 350+ tests incl. test/desktopAlerts.test.js
firebase deploy --only functions      # default codebase
```

Deploy the whole default codebase, not just the four new callables. `sendInboxPush` is bundled into every function that sends store pushes (`onMasterOrderCreated`, `notifyPlacedProviderOrders`, `broadcastPharmacyRequest`, …).

Optional: in the Firestore console, add a **TTL policy** on collection `desktopAcceptLocks`, field `expiresAt`, so expired accept locks get purged. They are tiny and harmless if you don't.

No Firestore rules or index changes are needed. The new data is written only by the Admin SDK, and client rules deny it by default.

### 2. Google Cloud: API key

The extension calls these Google APIs with the project's web API key (in `src/config.js`):

- Identity Toolkit
- Token Service
- Firebase Installations
- FCM Registration

If that key has **HTTP-referrer restrictions**, those calls fail from an extension. In that case, create a separate API key for the extension, restricted to those four APIs, and put it in `src/config.js`.

### 3. Configure the extension

In `src/config.js`:

- `dashboardUrl`: where the HAVIT Partner web dashboard (the `toukh_provider` web build) is hosted, for example `https://partner.example.com`. **View order** opens `{dashboardUrl}/#/orders/{orderId}`. If it's left empty, View order opens the extension's own order card instead. Staff can also set it under **Advanced**.
- `vapidKey` (optional): leave empty to use Firebase's default web-push key, which needs no console setup.

### 4. Provider web dashboard

Rebuild and deploy the provider web app so it includes the `PendingOrderLink` router change. Without it, a deep link to an order is dropped by the splash screen and login.

- If the user is already signed in on the dashboard, View order opens the order directly.
- If not, the dashboard's normal login runs and then returns to that order.

### 5. Install on store computers

- **Testing:** `chrome://extensions` → Developer mode → **Load unpacked** → pick this folder.
- **Production:**
  1. Run `npm run package`. It writes `dist/havit-desktop-alerts-<version>.zip`.
  2. Upload it to the Chrome Web Store, as unlisted or private to your domain.
  3. Alternatively, force-install it with Chrome enterprise policy (`ExtensionInstallForcelist`).

  If you need a stable extension ID before publishing (for example, to restrict the API key by extension), add a `key` to `manifest.json`.

Then, on each computer:

1. Click the HAVIT icon and sign in with the store's mobile number and password (the same ones as the Partner app).
2. Check that the status shows **Connected** and **Allowed**.
3. Click **Send a test alert** to check the notification, the sound, and the order card.
4. In the OS settings:
   - **macOS:** System Settings → Notifications → Google Chrome → Allow, style **Alerts** (Alerts stay on screen; Banners disappear).
   - **Windows:** Settings → System → Notifications → Google Chrome on, and Do Not Disturb off during working hours.

## Development

```bash
npm test          # unit tests (phone → login, i18n parity and tone, text, alert state, base64/FID)
npm i -D puppeteer
npm run e2e       # end-to-end in Chrome for Testing (see below)
```

`test/e2e/run.cjs` runs the real extension in Chrome for Testing against:

- the **real** backend handlers on the in-memory Firestore from the functions' unit tests: `deliverProviderOrderIfNeeded` → `sendInboxPush`, the four desktop callables, and `updateProviderOrderSlice`;
- a local stand-in for Google's Auth, Installations and FCM endpoints.

The FCM message the backend builds is delivered to the extension's service worker with DevTools' push delivery. Only Google's relay is simulated.

The run covers:

- sign-in and device registration;
- a new order arriving with every HAVIT page closed: notification, ringing sound, and order card;
- duplicate pushes;
- View order opening `#/orders/{id}`;
- Accept going through the backend;
- double-accept refusal;
- an order accepted on the phone stopping the ring;
- catch-up of a missed push;
- a customer cancellation;
- turning alerts off on the server;
- the Arabic RTL UI;
- sign-out cleanup.

Screenshots go to `$E2E_OUT`.

The Arabic copy follows the apps' register: refined Egyptian, with the brand written هافيت. `test/logic.test.mjs` checks for the excluded slang words.
