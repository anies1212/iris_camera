import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ios_camera_lens_switcher_method_channel.dart';
import 'src/camera_lens_descriptor.dart';

abstract class IosCameraLensSwitcherPlatform extends PlatformInterface {
  /// Constructs a IosCameraLensSwitcherPlatform.
  IosCameraLensSwitcherPlatform() : super(token: _token);

  static final Object _token = Object();

  static IosCameraLensSwitcherPlatform _instance = MethodChannelIosCameraLensSwitcher();

  /// The default instance of [IosCameraLensSwitcherPlatform] to use.
  ///
  /// Defaults to [MethodChannelIosCameraLensSwitcher].
  static IosCameraLensSwitcherPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IosCameraLensSwitcherPlatform] when
  /// they register themselves.
  static set instance(IosCameraLensSwitcherPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List<CameraLensDescriptor>> listAvailableLenses() {
    throw UnimplementedError('listAvailableLenses() has not been implemented.');
  }

  Future<CameraLensDescriptor> switchLens(CameraLensCategory category) {
    throw UnimplementedError('switchLens() has not been implemented.');
  }
}
