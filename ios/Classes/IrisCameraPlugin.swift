import AVFoundation
import Flutter
import UIKit

public class IrisCameraPlugin: NSObject, FlutterPlugin {
  private static let channelName = "iris_camera"

  private let sessionQueue = DispatchQueue(label: "iris_camera.session")
  private let captureSession = AVCaptureSession()
  private let photoOutput = AVCapturePhotoOutput()
  private var currentInput: AVCaptureDeviceInput?
  private var selectedLensID: String?
  private var pendingPhotoCapture: PhotoCaptureDelegate?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = IrisCameraPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    let previewFactory = CameraPreviewFactory(sessionProvider: { instance.captureSession })
    registrar.register(previewFactory, withId: "\(channelName)/preview")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "listAvailableLenses":
      result(listAvailableLenses())
    case "switchLens":
      switchLens(arguments: call.arguments, result: result)
    case "takePhoto":
      takePhoto(arguments: call.arguments, result: result)
    case "setFocus":
      setFocus(arguments: call.arguments, result: result)
    case "setZoom":
      setZoom(arguments: call.arguments, result: result)
    case "setWhiteBalance":
      setWhiteBalance(arguments: call.arguments, result: result)
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
            self.startSessionIfNeeded()
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
    ensurePhotoOutputAttached()

    return descriptorDictionary(for: device)
  }

  private func listAvailableLenses() -> [[String: Any]] {
    return devices().compactMap { device in
      if device.position == .front {
        // The preview layer is backed by a single AVCaptureSession that is
        // shared with still photo capture. Supporting the front camera would
        // require a dedicated preview pipeline to handle mirrored output, so
        // it is excluded for now to avoid exposing a lens that cannot render.
        return nil
      }
      return descriptorDictionary(for: device)
    }
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
      "supportsFocus": supportsManualFocus(device),
    ]

    let fovValue = Double(device.activeFormat.videoFieldOfView)
    if fovValue.isFinite {
      descriptor["fieldOfView"] = fovValue
    }

    return descriptor
  }

  private func supportsManualFocus(_ device: AVCaptureDevice) -> Bool {
    if device.isLockingFocusWithCustomLensPositionSupported {
      return true
    }
    let supportsRequestedModes = device.isFocusModeSupported(.autoFocus) ||
      device.isFocusModeSupported(.continuousAutoFocus)
    if device.isFocusPointOfInterestSupported && supportsRequestedModes {
      return true
    }
    return false
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
      return fallbackPosition == .unspecified ? "external" : "unknown"
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

  private func startSessionIfNeeded() {
    guard !captureSession.isRunning else { return }
    captureSession.startRunning()
  }

  private func ensurePhotoOutputAttached() {
    if captureSession.outputs.contains(where: { $0 === photoOutput }) {
      return
    }
    guard captureSession.canAddOutput(photoOutput) else {
      return
    }
    captureSession.addOutput(photoOutput)
    photoOutput.isHighResolutionCaptureEnabled = true
  }

  private func takePhoto(arguments: Any?, result: @escaping FlutterResult) {
    ensureAuthorization { [weak self] authResult in
      guard let self else { return }
      switch authResult {
      case .failure(let error):
        DispatchQueue.main.async {
          result(error.flutterError)
        }
      case .success:
        self.sessionQueue.async {
          self.startSessionIfNeeded()
          self.capturePhoto(arguments: arguments, result: result)
        }
      }
    }
  }

  private func capturePhoto(arguments: Any?, result: @escaping FlutterResult) {
    guard currentInput != nil else {
      DispatchQueue.main.async {
        result(FlutterError(
          code: "session_not_configured",
          message: "No active camera session is available for capture.",
          details: nil
        ))
      }
      return
    }

    let payload = arguments as? [String: Any]
    let flashMode = flashMode(from: payload?["flashMode"] as? String)
    let settings = AVCapturePhotoSettings()
    let supportedFlashModes: [AVCaptureDevice.FlashMode] =
      (photoOutput.supportedFlashModes as [Any]).compactMap { value in
        if let mode = value as? AVCaptureDevice.FlashMode {
          return mode
        }
        if let number = value as? NSNumber {
          return AVCaptureDevice.FlashMode(rawValue: number.intValue)
        }
        return nil
      }
    if supportedFlashModes.contains(flashMode) {
      settings.flashMode = flashMode
    }

    let exposureMicros = payload?["exposureDurationMicros"] as? Double ??
      (payload?["exposureDurationMicros"] as? NSNumber)?.doubleValue
    let isoOverride = payload?["iso"] as? Double ??
      (payload?["iso"] as? NSNumber)?.doubleValue
    let appliedManualExposure = applyManualExposure(
      exposureMicros: exposureMicros,
      iso: isoOverride
    )

    let cleanup: (() -> Void)? = appliedManualExposure ? { [weak self] in
      guard let self else { return }
      self.sessionQueue.async {
        self.restoreAutomaticExposure()
      }
    } : nil

    let delegate = PhotoCaptureDelegate(cleanup: cleanup) { [weak self] captureResult in
      guard let self else { return }
      self.pendingPhotoCapture = nil
      DispatchQueue.main.async {
        switch captureResult {
        case .success(let data):
          result(FlutterStandardTypedData(bytes: data))
        case .failure(let error):
          result(error.flutterError)
        }
      }
    }

    pendingPhotoCapture = delegate
    photoOutput.capturePhoto(with: settings, delegate: delegate)
  }

  private func flashMode(from rawValue: String?) -> AVCaptureDevice.FlashMode {
    switch rawValue {
    case "on":
      return .on
    case "off":
      return .off
    default:
      return .auto
    }
  }

  private func applyManualExposure(exposureMicros: Double?, iso: Double?) -> Bool {
    guard let device = currentInput?.device else { return false }
    if exposureMicros == nil && iso == nil {
      return false
    }
    do {
      try device.lockForConfiguration()
      defer { device.unlockForConfiguration() }
      if device.isExposureModeSupported(.custom) {
        let duration = clampedExposureDuration(micros: exposureMicros, device: device) ?? device.exposureDuration
        let isoValue = clampedISO(iso: iso, device: device) ?? device.iso
        device.setExposureModeCustom(duration: duration, iso: isoValue, completionHandler: nil)
        return true
      }
    } catch {
      return false
    }
    return false
  }

  private func clampedExposureDuration(micros: Double?, device: AVCaptureDevice) -> CMTime? {
    guard let micros else { return nil }
    let seconds = micros / 1_000_000.0
    var duration = CMTimeMakeWithSeconds(seconds, preferredTimescale: 1_000_000_000)
    let minDuration = device.activeFormat.minExposureDuration
    let maxDuration = device.activeFormat.maxExposureDuration
    if CMTimeCompare(duration, minDuration) < 0 {
      duration = minDuration
    } else if CMTimeCompare(duration, maxDuration) > 0 {
      duration = maxDuration
    }
    return duration
  }

  private func clampedISO(iso: Double?, device: AVCaptureDevice) -> Float? {
    guard let iso else { return nil }
    let minISO = device.activeFormat.minISO
    let maxISO = device.activeFormat.maxISO
    let clamped = max(Double(minISO), min(iso, Double(maxISO)))
    return Float(clamped)
  }

  private func restoreAutomaticExposure() {
    guard let device = currentInput?.device else { return }
    do {
      try device.lockForConfiguration()
      if device.isExposureModeSupported(.continuousAutoExposure) {
        device.exposureMode = .continuousAutoExposure
      }
      device.unlockForConfiguration()
    } catch { }
  }

  private func setFocus(arguments: Any?, result: @escaping FlutterResult) {
    guard let device = currentInput?.device else {
      result(FlutterError(
        code: "focus_failed",
        message: "No active camera session is available for focus updates.",
        details: nil
      ))
      return
    }
    let payload = arguments as? [String: Any]
    let x = payload?["x"] as? Double
    let y = payload?["y"] as? Double
    let lensPosition = payload?["lensPosition"] as? Double ??
      (payload?["lensPosition"] as? NSNumber)?.doubleValue

    sessionQueue.async {
      do {
        try device.lockForConfiguration()
        var applied = false
        if let lensPosition,
           device.isLockingFocusWithCustomLensPositionSupported {
          let clamped = Float(max(0.0, min(lensPosition, 1.0)))
          device.setFocusModeLocked(lensPosition: clamped, completionHandler: nil)
          applied = true
        }
        if let x, let y,
           device.isFocusPointOfInterestSupported,
           device.isFocusModeSupported(.autoFocus) || device.isFocusModeSupported(.continuousAutoFocus) {
          let point = CGPoint(
            x: max(0.0, min(x, 1.0)),
            y: max(0.0, min(y, 1.0))
          )
          device.focusPointOfInterest = point
          if device.isFocusModeSupported(.autoFocus) {
            device.focusMode = .autoFocus
          } else if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
          }
          applied = true
        }
        device.unlockForConfiguration()
        DispatchQueue.main.async {
          if applied {
            result(nil)
          } else {
            result(FlutterError(
              code: "focus_not_supported",
              message: "Manual focus is not supported on this device.",
              details: nil
            ))
          }
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "focus_failed",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    }
  }

  private func setZoom(arguments: Any?, result: @escaping FlutterResult) {
    guard let device = currentInput?.device else {
      result(FlutterError(
        code: "zoom_failed",
        message: "No active camera session is available for zoom updates.",
        details: nil
      ))
      return
    }
    let payload = arguments as? [String: Any]
    let zoom = payload?["zoomFactor"] as? Double ??
      (payload?["zoomFactor"] as? NSNumber)?.doubleValue ?? 1.0
    let clamped = max(1.0, min(zoom, Double(device.activeFormat.videoMaxZoomFactor)))
    sessionQueue.async {
      do {
        try device.lockForConfiguration()
        device.videoZoomFactor = CGFloat(clamped)
        device.unlockForConfiguration()
        DispatchQueue.main.async { result(nil) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "zoom_failed",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    }
  }

  private func setWhiteBalance(arguments: Any?, result: @escaping FlutterResult) {
    guard let device = currentInput?.device else {
      result(FlutterError(
        code: "white_balance_failed",
        message: "No active camera session is available for white balance updates.",
        details: nil
      ))
      return
    }
    let payload = arguments as? [String: Any]
    let temperature = payload?["temperature"] as? Double ??
      (payload?["temperature"] as? NSNumber)?.doubleValue
    let tint = payload?["tint"] as? Double ??
      (payload?["tint"] as? NSNumber)?.doubleValue

    sessionQueue.async {
      do {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        if temperature == nil && tint == nil {
          if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            device.whiteBalanceMode = .continuousAutoWhiteBalance
          }
          DispatchQueue.main.async { result(nil) }
          return
        }
        let tempValue = Float(temperature ?? 5000)
        let tintValue = Float(tint ?? 0)
        let ttValues = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
          temperature: tempValue,
          tint: tintValue
        )
        var gains = device.deviceWhiteBalanceGains(for: ttValues)
        gains = self.normalizedGains(gains, device: device)
        device.setWhiteBalanceModeLocked(with: gains, completionHandler: nil)
        DispatchQueue.main.async { result(nil) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "white_balance_failed",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    }
  }

  private func normalizedGains(_ gains: AVCaptureDevice.WhiteBalanceGains, device: AVCaptureDevice) -> AVCaptureDevice.WhiteBalanceGains {
    var clamped = gains
    let maxGain = device.maxWhiteBalanceGain
    let minGain: Float = 1.0
    clamped.redGain = max(minGain, min(gains.redGain, maxGain))
    clamped.greenGain = max(minGain, min(gains.greenGain, maxGain))
    clamped.blueGain = max(minGain, min(gains.blueGain, maxGain))
    return clamped
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

private enum PhotoCaptureError: Error {
  case captureFailed(message: String)

  var flutterError: FlutterError {
    switch self {
    case .captureFailed(let message):
      return FlutterError(
        code: "photo_capture_failed",
        message: message,
        details: nil
      )
    }
  }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let completion: (Result<Data, PhotoCaptureError>) -> Void
  private let cleanup: (() -> Void)?

  init(
    cleanup: (() -> Void)?,
    completion: @escaping (Result<Data, PhotoCaptureError>) -> Void
  ) {
    self.cleanup = cleanup
    self.completion = completion
    super.init()
  }

  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    if let error {
      completion(.failure(.captureFailed(message: error.localizedDescription)))
      cleanup?()
      return
    }
    guard let data = photo.fileDataRepresentation() else {
      completion(.failure(.captureFailed(message: "No image data was produced.")))
      cleanup?()
      return
    }
    completion(.success(data))
    cleanup?()
  }
}

private final class CameraPreviewFactory: NSObject, FlutterPlatformViewFactory {
  private let sessionProvider: () -> AVCaptureSession

  init(sessionProvider: @escaping () -> AVCaptureSession) {
    self.sessionProvider = sessionProvider
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    CameraPreviewPlatformView(frame: frame, sessionProvider: sessionProvider)
  }
}

private final class CameraPreviewPlatformView: NSObject, FlutterPlatformView {
  private let containerView: CameraPreviewContainerView

  init(frame: CGRect, sessionProvider: @escaping () -> AVCaptureSession) {
    containerView = CameraPreviewContainerView(frame: frame, sessionProvider: sessionProvider)
    super.init()
  }

  func view() -> UIView {
    containerView
  }
}

private final class CameraPreviewContainerView: UIView {
  private let sessionProvider: () -> AVCaptureSession
  private var previewLayer: AVCaptureVideoPreviewLayer?

  init(frame: CGRect, sessionProvider: @escaping () -> AVCaptureSession) {
    self.sessionProvider = sessionProvider
    super.init(frame: frame)
    backgroundColor = .black
    configurePreviewLayer()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func configurePreviewLayer() {
    let layer = AVCaptureVideoPreviewLayer(session: sessionProvider())
    layer.videoGravity = .resizeAspectFill
    layer.frame = bounds
    self.layer.addSublayer(layer)
    previewLayer = layer
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    previewLayer?.frame = bounds
  }
}
