// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'package:flutter/services.dart';

import 'iris_camera_platform_interface.dart';
import 'photo_capture_options.dart';
import 'camera_lens_descriptor.dart';
import 'camera_lens_switcher_exception.dart';

/// Main entry point for interacting with the native camera implementation.
class IrisCamera {
  /// Returns the platform version string (primarily for testing).
  Future<String?> getPlatformVersion() {
    return IrisCameraPlatform.instance.getPlatformVersion();
  }

  /// Lists all available camera lenses on the device.
  Future<List<CameraLensDescriptor>> listAvailableLenses() {
    return _wrapPlatformExceptions(
      () => IrisCameraPlatform.instance.listAvailableLenses(),
    );
  }

  /// Switches to a lens by category (e.g. wide, ultraWide, telephoto).
  Future<CameraLensDescriptor> switchLens(CameraLensCategory category) {
    return _wrapPlatformExceptions(
      () => IrisCameraPlatform.instance.switchLens(category),
    );
  }

  /// Captures a still photo using the active lens.
  ///
  /// Provide [options] to override flash, exposure, or ISO.
  Future<Uint8List> capturePhoto({
    PhotoCaptureOptions options = const PhotoCaptureOptions(),
  }) {
    return _wrapPlatformExceptions(
      () => IrisCameraPlatform.instance.capturePhoto(options),
    );
  }

  /// Sets focus either to a normalized preview [point] or to a [lensPosition].
  Future<void> setFocus({
    Offset? point,
    double? lensPosition,
  }) {
    return _wrapPlatformExceptions(
      () => IrisCameraPlatform.instance.setFocus(
        point: point,
        lensPosition: lensPosition,
      ),
    );
  }

  /// Applies digital zoom to the active lens.
  Future<void> setZoom(double zoomFactor) {
    return _wrapPlatformExceptions(
      () => IrisCameraPlatform.instance.setZoom(zoomFactor),
    );
  }

  /// Overrides white balance with temperature/tint or resets to auto when omitted.
  Future<void> setWhiteBalance({
    double? temperature,
    double? tint,
  }) {
    return _wrapPlatformExceptions(
      () => IrisCameraPlatform.instance.setWhiteBalance(
        temperature: temperature,
        tint: tint,
      ),
    );
  }

  Future<T> _wrapPlatformExceptions<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PlatformException catch (error) {
      throw CameraLensSwitcherException.fromPlatformException(error);
    } on FormatException catch (error) {
      throw CameraLensSwitcherException('invalid_payload', error.message);
    }
  }
}
