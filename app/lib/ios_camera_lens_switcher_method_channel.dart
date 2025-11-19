import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ios_camera_lens_switcher_platform_interface.dart';
import 'src/camera_lens_descriptor.dart';

/// An implementation of [IosCameraLensSwitcherPlatform] that uses method channels.
class MethodChannelIosCameraLensSwitcher extends IosCameraLensSwitcherPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ios_camera_lens_switcher');

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
