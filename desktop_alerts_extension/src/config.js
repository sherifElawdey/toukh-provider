/**
 * Build-time configuration. Every value here is public (the same web config
 * the provider web app ships in `web/firebase-messaging-sw.js`); no secrets
 * belong in an extension.
 */
export const CONFIG = Object.freeze({
  firebase: {
    apiKey: 'AIzaSyC51eQ97nsVL7Fv_uYlngnG7QCBSk7h3P0',
    projectId: 'toukh-b5708',
    appId: '1:919479487381:web:addf15415897f372f1449c',
    messagingSenderId: '919479487381',
  },

  /** Must match `FUNCTIONS_REGION` in `toukh/functions/index.js`. */
  functionsBase: 'https://us-central1-toukh-b5708.cloudfunctions.net',

  /** Google endpoints (overridable for the Firebase emulator or tests). */
  endpoints: {
    identityToolkit: 'https://identitytoolkit.googleapis.com/v1',
    secureToken: 'https://securetoken.googleapis.com/v1',
    installations: 'https://firebaseinstallations.googleapis.com/v1',
    fcmRegistrations: 'https://fcmregistrations.googleapis.com/v1',
  },

  /**
   * Web-push key for FCM. Empty uses Firebase's default key, which needs no
   * console setup. Set it to the project's own "Web Push certificate" public
   * key (Firebase console → Cloud Messaging) to use that instead.
   */
  vapidKey: '',

  /**
   * Where the HAVIT Partner web dashboard (the `toukh_provider` web build) is
   * hosted, without a trailing slash — e.g. `https://partner.example.com`.
   * Orders open at `{dashboardUrl}/#/orders/{orderId}`. Users can also set it
   * under Advanced in the extension. Empty: "View order" opens the order card
   * inside the extension instead.
   */
  dashboardUrl: 'https://havitpartner.toukh.com',

  /** Provider logins are `provider{E.164 digits}@toukh.com` (see phone_auth_helpers.dart). */
  syntheticEmailDomain: 'toukh.com',
});
