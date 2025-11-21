import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Controls the focus indicator overlay rendered by [IrisCameraPreview].
class FocusIndicatorController extends ChangeNotifier {
  /// Creates a controller for the focus indicator overlay.
  ///
  /// [visibleDuration] controls how long the indicator remains visible
  /// after a tap-to-focus event.
  FocusIndicatorController({this.visibleDuration = const Duration(seconds: 1)});

  /// How long the indicator stays visible after being shown.
  final Duration visibleDuration;
  Offset? _normalizedPoint;
  Timer? _timer;

  /// Last normalized point used for the indicator, or null when hidden.
  Offset? get normalizedPoint => _normalizedPoint;

  /// Shows the indicator at a normalized [normalizedPoint] (0–1 coordinates).
  void showIndicator(Offset normalizedPoint) {
    _normalizedPoint = normalizedPoint;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer(visibleDuration, () {
      _normalizedPoint = null;
      notifyListeners();
    });
  }

  /// Hides the indicator immediately.
  void hideIndicator() {
    _timer?.cancel();
    _normalizedPoint = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
