import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'iris_camera_platform_interface.dart';
import 'camera_lens_descriptor.dart';
import 'photo_capture_options.dart';

class MethodChannelIrisCamera extends IrisCameraPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('iris_camera');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<List<CameraLensDescriptor>> listAvailableLenses() async {
    final rawList =
        await methodChannel.invokeListMethod<Object?>('listAvailableLenses') ??
            const <Object?>[];
    return rawList
        .map(_coerceMap)
        .map(CameraLensDescriptor.fromMap)
        .toList(growable: false);
  }

  @override
  Future<CameraLensDescriptor> switchLens(CameraLensCategory category) async {
    final response = await methodChannel.invokeMethod<Object?>(
      'switchLens',
      <String, dynamic>{'category': category.name},
    );
    final map = _coerceMap(response);
    return CameraLensDescriptor.fromMap(map);
  }

  @override
  Future<Uint8List> capturePhoto(PhotoCaptureOptions options) async {
    final bytes = await methodChannel.invokeMethod<Uint8List>(
      'takePhoto',
      options.toMap(),
    );
    if (bytes == null) {
      throw PlatformException(
        code: 'photo_capture_failed',
        message: 'Platform returned no image data.',
      );
    }
    return bytes;
  }

  @override
  Future<void> setFocus({
    Offset? point,
    double? lensPosition,
  }) async {
    final args = <String, dynamic>{};
    if (point != null) {
      args['x'] = point.dx;
      args['y'] = point.dy;
    }
    if (lensPosition != null) {
      args['lensPosition'] = lensPosition;
    }
    await methodChannel.invokeMethod('setFocus', args);
  }

  @override
  Future<void> setZoom(double zoomFactor) async {
    await methodChannel.invokeMethod<void>(
      'setZoom',
      <String, dynamic>{'zoomFactor': zoomFactor},
    );
  }

  @override
  Future<void> setWhiteBalance({
    double? temperature,
    double? tint,
  }) async {
    final args = <String, dynamic>{};
    if (temperature != null) {
      args['temperature'] = temperature;
    }
    if (tint != null) {
      args['tint'] = tint;
    }
    await methodChannel.invokeMethod<void>('setWhiteBalance', args);
  }

  Map<String, Object?> _coerceMap(Object? payload) {
    if (payload case Map<Object?, Object?> rawMap) {
      return rawMap.map((key, value) {
        if (key is! String) {
          throw FormatException(
            'Expected map key to be a String but received $key',
          );
        }
        return MapEntry(key, value);
      });
    }
    throw FormatException('Expected a map payload but received $payload');
  }
}
