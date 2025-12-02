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
    DispatchQueue.main.async { [weak self] in
      self?.sink?([
        "state": state.rawValue
      ])
    }
  }
}

/// Emits burst capture progress updates.
final class BurstProgressStreamHandler: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  func emit(total: Int, completed: Int, status: BurstProgressStatusNative, error: String?) {
    guard let sink else { return }
    var payload: [String: Any] = [
      "total": total,
      "completed": completed,
      "status": status.rawValue,
    ]
    if let error {
      payload["error"] = error
    }
    DispatchQueue.main.async {
      sink(payload)
    }
  }
}

enum BurstProgressStatusNative: String {
  case inProgress
  case done
  case error
}
