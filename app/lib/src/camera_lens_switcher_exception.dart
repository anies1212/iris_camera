import 'package:flutter/services.dart';

class CameraLensSwitcherException implements Exception {
  CameraLensSwitcherException(this.code, this.message, [this.details]);

  factory CameraLensSwitcherException.fromPlatformException(PlatformException error) {
    return CameraLensSwitcherException(error.code, error.message, error.details);
  }

  final String code;
  final String? message;
  final Object? details;

  @override
  String toString() => 'CameraLensSwitcherException($code, $message, $details)';
}
