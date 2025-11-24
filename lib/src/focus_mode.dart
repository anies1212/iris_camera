/// Focus mode to control auto vs locked behavior.
enum FocusMode {
  /// Automatic/continuous autofocus when supported.
  auto,

  /// Locks focus after a single auto-focus pass or at the current lens position.
  locked,
}
