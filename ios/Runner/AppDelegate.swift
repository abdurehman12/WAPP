
// import UIKit
// import Flutter
// import flutter_downloader

// @UIApplicationMain
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     GeneratedPluginRegistrant.register(with: self)
//     FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }

// private func registerPlugins(registry: FlutterPluginRegistry) {
//     if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
//        FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
//     }
// }
import UIKit
import Flutter
import GoogleMaps
import flutter_downloader

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Initialize Google Maps with your API key
    GMSServices.provideAPIKey("AIzaSyCcr56ZxhkvdYntPYfiUmPruGo8kt4eqWk")
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Initialize FlutterDownloaderPlugin
    FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// Function to register the Flutter Downloader plugin
private func registerPlugins(registry: FlutterPluginRegistry) {
  if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
    FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
  }
}
