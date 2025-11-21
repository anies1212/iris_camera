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

class IrisCamera {
  Future<String?> getPlatformVersion() {
    return IrisCameraPlatform.instance.getPlatformVersion();
  }

  Future<List<CameraLensDescriptor>> listAvailableLenses() {
    return _wrapPlatformExceptions(
      () => IrisCameraPlatform.instance.listAvailableLenses(),
    );
  }

  Future<CameraLensDescriptor> switchLens(CameraLensCategory category) {
    return _wrapPlatformExceptions(
      () => IrisCameraPlatform.instance.switchLens(category),
    );
  }

  Future<Uint8List> capturePhoto({
    PhotoCaptureOptions options = const PhotoCaptureOptions(),
  }) {
    return _wrapPlatformExceptions(
      () => IrisCameraPlatform.instance.capturePhoto(options),
    );
  }

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

  Future<void> setZoom(double zoomFactor) {
    return _wrapPlatformExceptions(
      () => IrisCameraPlatform.instance.setZoom(zoomFactor),
    );
  }

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
