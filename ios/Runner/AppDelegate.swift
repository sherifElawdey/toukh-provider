import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Dedicated Maps iOS key (`Toukh Maps iOS` in GCP) — not the Firebase API key.
    // Same value as `ios/Runner/Info.plist` → `GMSApiKey`.
    GMSServices.provideAPIKey("AIzaSyArN_FJmw4O5DneJ8ZGlK2zmkbeS1jqu1Y")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
