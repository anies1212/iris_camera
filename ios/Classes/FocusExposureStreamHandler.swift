import Flutter

/// AF/AE state exposed to Flutter.
enum FocusExposureStateNative: String {
  case focusing
  case focusLocked
  case focusFailed
  case exposureSearching
  case exposureLocked
  case exposureFailed
  case combinedLocked
  case unknown
}

/// Emits AF/AE state changes over a Flutter event channel.
final class FocusExposureStreamHandler: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  func emit(state: FocusExposureStateNative) {
    sink?([
      "state": state.rawValue
    ])
  }
}
