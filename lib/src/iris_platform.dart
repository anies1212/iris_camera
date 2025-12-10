import 'package:flutter/foundation.dart';

/// Supported platforms for iris_camera.
enum IrisPlatform {
  iOS,
  android,
  web,
}

/// Returns the current platform.
///
/// Throws [UnsupportedError] if running on an unsupported platform.
IrisPlatform get currentPlatform {
  if (kIsWeb) {
    return IrisPlatform.web;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return IrisPlatform.iOS;
    case TargetPlatform.android:
      return IrisPlatform.android;
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      throw UnsupportedError(
        'iris_camera is not supported on ${defaultTargetPlatform.name}.',
      );
  }
}

/// Returns the current platform, or null if unsupported.
IrisPlatform? get currentPlatformOrNull {
  if (kIsWeb) {
    return IrisPlatform.web;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return IrisPlatform.iOS;
    case TargetPlatform.android:
      return IrisPlatform.android;
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return null;
  }
}

/// Whether the current platform is supported.
bool get isPlatformSupported => currentPlatformOrNull != null;
