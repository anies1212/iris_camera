import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'iris_camera_method_channel.dart';
import 'camera_lens_descriptor.dart';
import 'photo_capture_options.dart';

abstract class IrisCameraPlatform extends PlatformInterface {
  IrisCameraPlatform() : super(token: _token);

  static final Object _token = Object();

  static IrisCameraPlatform _instance = MethodChannelIrisCamera();

  static IrisCameraPlatform get instance => _instance;

  static set instance(IrisCameraPlatform instance) {
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

  Future<Uint8List> capturePhoto(PhotoCaptureOptions options) {
    throw UnimplementedError('capturePhoto() has not been implemented.');
  }

  Future<void> setFocus({
    Offset? point,
    double? lensPosition,
  }) {
    throw UnimplementedError('setFocus() has not been implemented.');
  }

  Future<void> setZoom(double zoomFactor) {
    throw UnimplementedError('setZoom() has not been implemented.');
  }

  Future<void> setWhiteBalance({
    double? temperature,
    double? tint,
  }) {
    throw UnimplementedError('setWhiteBalance() has not been implemented.');
  }
}
