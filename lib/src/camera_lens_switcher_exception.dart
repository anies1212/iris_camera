import 'package:flutter/services.dart';

/// Structured error returned by the camera platform implementation.
class IrisCameraException implements Exception {
  IrisCameraException(this.code, this.message, [this.details]);

  factory IrisCameraException.fromPlatformException(
    PlatformException error,
  ) {
    return IrisCameraException(
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
  @override
  String toString() => 'IrisCameraException($code, $message, $details)';
}

/// Backward-compatible alias for [IrisCameraException].
typedef CameraLensSwitcherException = IrisCameraException;
