/// Focus/auto-exposure state reported by the platform.
enum FocusExposureState {
  /// AF is actively adjusting focus.
  focusing,

  /// AF locked focus successfully.
  focusLocked,

  /// AF failed to lock focus.
  focusFailed,

  /// AE is searching/adjusting exposure.
  exposureSearching,

  /// AE locked exposure successfully.
  exposureLocked,

  /// AE failed to lock exposure.
  exposureFailed,

  /// Both AF and AE are locked.
  combinedLocked,

  /// Fallback for unknown/unsupported states.
  unknown,
}

/// State update emitted when AF/AE changes.
class FocusExposureStateEvent {
  /// Creates a focus/exposure state event.
  FocusExposureStateEvent({
    required this.state,
  });

  /// Reported AF/AE state.
  final FocusExposureState state;

  /// Parses a platform map into a [FocusExposureStateEvent].
  factory FocusExposureStateEvent.fromMap(Map<String, Object?> map) {
    final raw = map['state'] as String?;
    final state = switch (raw) {
      'focusing' => FocusExposureState.focusing,
      'focusLocked' => FocusExposureState.focusLocked,
      'focusFailed' => FocusExposureState.focusFailed,
      'exposureSearching' => FocusExposureState.exposureSearching,
      'exposureLocked' => FocusExposureState.exposureLocked,
      'exposureFailed' => FocusExposureState.exposureFailed,
      'combinedLocked' => FocusExposureState.combinedLocked,
      _ => FocusExposureState.unknown,
    };
    return FocusExposureStateEvent(state: state);
  }
}
