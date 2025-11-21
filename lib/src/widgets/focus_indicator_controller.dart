import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Controls the focus indicator overlay rendered by [IrisCameraPreview].
class FocusIndicatorController extends ChangeNotifier {
  FocusIndicatorController({this.visibleDuration = const Duration(seconds: 1)});

  final Duration visibleDuration;
  Offset? _normalizedPoint;
  Timer? _timer;

  Offset? get normalizedPoint => _normalizedPoint;

  void showIndicator(Offset normalizedPoint) {
    _normalizedPoint = normalizedPoint;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer(visibleDuration, () {
      _normalizedPoint = null;
      notifyListeners();
    });
  }

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
