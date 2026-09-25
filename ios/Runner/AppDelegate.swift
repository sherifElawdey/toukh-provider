import FirebaseCore
import FirebaseMessaging
import Flutter
import GoogleMaps
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Dedicated Maps iOS key (`Toukh Maps iOS` in GCP) — not the Firebase API key.
    // Same value as `ios/Runner/Info.plist` → `GMSApiKey`.
    GMSServices.provideAPIKey("AIzaSyArN_FJmw4O5DneJ8ZGlK2zmkbeS1jqu1Y")

    // Configure Firebase early so APNs device tokens can be handed to Messaging
    // before Dart finishes Firebase.initializeApp().
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    UNUserNotificationCenter.current().delegate = self
    // Required for FCM on iOS — without this, getAPNSToken() stays nil.
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
