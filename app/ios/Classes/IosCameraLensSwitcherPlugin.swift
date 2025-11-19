import AVFoundation
import Flutter
import UIKit

public class IosCameraLensSwitcherPlugin: NSObject, FlutterPlugin {
  private static let channelName = "ios_camera_lens_switcher"

  private let sessionQueue = DispatchQueue(label: "ios_camera_lens_switcher.session")
  private let captureSession = AVCaptureSession()
  private var currentInput: AVCaptureDeviceInput?
  private var selectedLensID: String?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = IosCameraLensSwitcherPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "listAvailableLenses":
      result(listAvailableLenses())
    case "switchLens":
      switchLens(arguments: call.arguments, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func switchLens(arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any], let categoryName = args["category"] as? String else {
      result(FlutterError(
        code: "invalid_arguments",
        message: "Expected { category: <String> } for switchLens.",
        details: nil
      ))
      return
    }

    ensureAuthorization { [weak self] authorizationResult in
      guard let self = self else { return }
      switch authorizationResult {
      case .failure(let error):
        DispatchQueue.main.async {
          result(error.flutterError)
        }
      case .success:
        self.sessionQueue.async {
          let outcome: Result<[String: Any], CameraSwitchError>
          do {
            let descriptor = try self.configureSessionAndSwitch(categoryName: categoryName)
            outcome = .success(descriptor)
          } catch let error as CameraSwitchError {
            outcome = .failure(error)
          } catch {
            outcome = .failure(.configurationFailed(message: error.localizedDescription))
          }

          DispatchQueue.main.async {
            switch outcome {
            case .success(let descriptor):
              result(descriptor)
            case .failure(let error):
              result(error.flutterError)
            }
          }
        }
      }
    }
  }

  private func configureSessionAndSwitch(categoryName: String) throws -> [String: Any] {
    guard let device = device(matchingCategory: categoryName) else {
      throw CameraSwitchError.lensNotFound(category: categoryName)
    }

    let newInput: AVCaptureDeviceInput
    do {
      newInput = try AVCaptureDeviceInput(device: device)
    } catch let error as NSError {
      if error.domain == AVFoundationErrorDomain,
         error.code == AVError.applicationIsNotAuthorizedToUseDevice.rawValue {
        throw CameraSwitchError.notAuthorized
      }
      throw CameraSwitchError.configurationFailed(message: error.localizedDescription)
    }

    if let currentDevice = currentInput?.device,
       categoryString(from: currentDevice.deviceType, fallbackPosition: currentDevice.position) == categoryName {
      return descriptorDictionary(for: currentDevice)
    }

    captureSession.beginConfiguration()
    defer {
      captureSession.commitConfiguration()
    }

    if let currentInput {
      captureSession.removeInput(currentInput)
    }

    guard captureSession.canAddInput(newInput) else {
      if let currentInput {
        captureSession.addInput(currentInput)
      }
      throw CameraSwitchError.configurationFailed(message: "Cannot attach \(device.localizedName) to capture session.")
    }

    captureSession.addInput(newInput)
    currentInput = newInput
    selectedLensID = device.uniqueID

    return descriptorDictionary(for: device)
  }

  private func listAvailableLenses() -> [[String: Any]] {
    return devices().map(descriptorDictionary)
  }

  private func devices() -> [AVCaptureDevice] {
    let types = supportedDeviceTypes()
    let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: .video, position: .unspecified)
    return discovery.devices
  }

  private func supportedDeviceTypes() -> [AVCaptureDevice.DeviceType] {
    var types: [AVCaptureDevice.DeviceType] = [
      .builtInWideAngleCamera,
      .builtInUltraWideCamera,
      .builtInTelephotoCamera,
      .builtInDualCamera,
      .builtInTrueDepthCamera,
    ]
    if #available(iOS 13.0, *) {
      types.append(.builtInDualWideCamera)
      types.append(.builtInTripleCamera)
    }
    if #available(iOS 17.0, *) {
      types.append(.continuityCamera)
    }
    return types
  }

  private func device(matchingCategory category: String) -> AVCaptureDevice? {
    return devices().first { device in
      categoryString(from: device.deviceType, fallbackPosition: device.position) == category
    }
  }

  private func descriptorDictionary(for device: AVCaptureDevice) -> [String: Any] {
    var descriptor: [String: Any] = [
      "id": device.uniqueID,
      "name": device.localizedName,
      "position": positionString(from: device.position),
      "category": categoryString(from: device.deviceType, fallbackPosition: device.position),
    ]

    let fovValue = Double(device.activeFormat.videoFieldOfView)
    if fovValue.isFinite {
      descriptor["fieldOfView"] = fovValue
    }

    return descriptor
  }

  private func positionString(from position: AVCaptureDevice.Position) -> String {
    switch position {
    case .back:
      return "back"
    case .front:
      return "front"
    case .unspecified:
      return "external"
    @unknown default:
      return "unspecified"
    }
  }

  private func categoryString(from deviceType: AVCaptureDevice.DeviceType, fallbackPosition: AVCaptureDevice.Position) -> String {
    switch deviceType {
    case .builtInWideAngleCamera:
      return "wide"
    case .builtInUltraWideCamera:
      return "ultraWide"
    case .builtInTelephotoCamera:
      return "telephoto"
    case .builtInTrueDepthCamera:
      return "trueDepth"
    case .builtInDualCamera:
      return "dual"
    default:
      if #available(iOS 13.0, *) {
        if deviceType == .builtInDualWideCamera {
          return "dual"
        }
        if deviceType == .builtInTripleCamera {
          return "triple"
        }
      }
      if #available(iOS 17.0, *), deviceType == .continuityCamera {
        return "continuity"
      }
      if fallbackPosition == .unspecified {
        return "external"
      }
      return "unknown"
    }
  }

  private func ensureAuthorization(completion: @escaping (Result<Void, CameraSwitchError>) -> Void) {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .authorized:
      completion(.success(()))
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        completion(granted ? .success(()) : .failure(.notAuthorized))
      }
    default:
      completion(.failure(.notAuthorized))
    }
  }
}

private enum CameraSwitchError: Error {
  case lensNotFound(category: String)
  case notAuthorized
  case configurationFailed(message: String)

  var flutterError: FlutterError {
    switch self {
    case .lensNotFound(let category):
      return FlutterError(
        code: "lens_not_found",
        message: "No camera lens found for category \(category).",
        details: nil
      )
    case .notAuthorized:
      return FlutterError(
        code: "camera_permission_denied",
        message: "Camera access has not been granted. Request permission before switching lenses.",
        details: nil
      )
    case .configurationFailed(let message):
      return FlutterError(
        code: "switch_failed",
        message: message,
        details: nil
      )
    }
  }
}
