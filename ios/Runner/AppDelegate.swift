import Flutter
import UIKit
import Vision
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var clothingAnalysisChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "mmm/clothing_analysis",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "classifyImage" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let bytes = call.arguments as? FlutterStandardTypedData else {
        result(FlutterError(code: "invalid_image", message: "Image bytes are required.", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let request = VNClassifyImageRequest()
#if targetEnvironment(simulator)
          if #available(iOS 17.0, *) {
            if let supported = try? request.supportedComputeStageDevices,
               let cpu = supported[.main]?.first(where: {
                 if case .cpu = $0 { return true }
                 return false
               }) {
              request.setComputeDevice(cpu, for: .main)
            }
          }
#endif
          try VNImageRequestHandler(data: bytes.data, options: [:]).perform([request])
          let labels = (request.results ?? [])
            .filter { $0.confidence >= 0.05 }
            .prefix(20)
            .map { ["label": $0.identifier, "confidence": Double($0.confidence)] as [String: Any] }
          DispatchQueue.main.async { result(Array(labels)) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "vision_failed", message: error.localizedDescription, details: nil))
          }
        }
      }
    }
    clothingAnalysisChannel = channel
  }
}
