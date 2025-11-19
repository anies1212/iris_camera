// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'package:flutter/services.dart';

import 'ios_camera_lens_switcher_platform_interface.dart';
import 'src/camera_lens_descriptor.dart';
import 'src/camera_lens_switcher_exception.dart';

export 'src/camera_lens_descriptor.dart'
    show CameraLensDescriptor, CameraLensCategory, CameraLensPosition;
export 'src/camera_lens_switcher_exception.dart'
    show CameraLensSwitcherException;

class IosCameraLensSwitcher {
  Future<String?> getPlatformVersion() {
    return IosCameraLensSwitcherPlatform.instance.getPlatformVersion();
  }

  Future<List<CameraLensDescriptor>> listAvailableLenses() {
    return _wrapPlatformExceptions(
      () => IosCameraLensSwitcherPlatform.instance.listAvailableLenses(),
    );
  }

  Future<CameraLensDescriptor> switchLens(CameraLensCategory category) {
    return _wrapPlatformExceptions(
      () => IosCameraLensSwitcherPlatform.instance.switchLens(category),
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
