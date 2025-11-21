import 'package:flutter/services.dart';

/// Structured error returned by the camera platform implementation.
class CameraLensSwitcherException implements Exception {
  CameraLensSwitcherException(this.code, this.message, [this.details]);

  factory CameraLensSwitcherException.fromPlatformException(
    PlatformException error,
  ) {
    return CameraLensSwitcherException(
      error.code,
      error.message,
      error.details,
    );
  }

  /// Machine-readable error code from the platform layer.
  final String code;

  /// Human-readable message describing the failure.
  final String? message;

  /// Optional structured details from the platform.
  final Object? details;

  @override
  String toString() => 'CameraLensSwitcherException($code, $message, $details)';
}
