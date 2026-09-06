import Flutter
import UIKit
import Vision
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var clothingAnalysisChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "mmm/clothing_analysis",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "classifyImage" || call.method == "segmentForeground" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let bytes = call.arguments as? FlutterStandardTypedData else {
        result(FlutterError(code: "invalid_image", message: "Image bytes are required.", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          if call.method == "segmentForeground" {
            guard #available(iOS 17.0, *) else {
              DispatchQueue.main.async { result(nil) }
              return
            }
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(data: bytes.data, options: [:])
            try handler.perform([request])
            guard let observation = request.results?.first else {
              DispatchQueue.main.async { result(nil) }
              return
            }
            let buffer = observation.instanceMask
            let width = CVPixelBufferGetWidth(buffer)
            let height = CVPixelBufferGetHeight(buffer)
            CVPixelBufferLockBaseAddress(buffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
            guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
              DispatchQueue.main.async { result(nil) }
              return
            }
            let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
            let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
            var mask = [UInt8](repeating: 0, count: width * height)
            var minX = width
            var minY = height
            var maxX = -1
            var maxY = -1
            var foreground = 0
            for y in 0..<height {
              for x in 0..<width {
                let value = pointer[y * bytesPerRow + x]
                if value > 0 {
                  mask[y * width + x] = 255
                  foreground += 1
                  minX = min(minX, x)
                  minY = min(minY, y)
                  maxX = max(maxX, x)
                  maxY = max(maxY, y)
                }
              }
            }
            let hasForeground = maxX >= minX && maxY >= minY
            let payload: [String: Any] = [
              "width": width,
              "height": height,
              "mask": FlutterStandardTypedData(bytes: Data(mask)),
              "confidence": Double(foreground) / Double(max(1, width * height)),
              "boundingBox": hasForeground
                ? [
                    Double(minX) / Double(width),
                    Double(minY) / Double(height),
                    Double(maxX + 1) / Double(width),
                    Double(maxY + 1) / Double(height),
                  ]
                : [0.0, 0.0, 1.0, 1.0],
            ]
            DispatchQueue.main.async { result(payload) }
            return
          }
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
