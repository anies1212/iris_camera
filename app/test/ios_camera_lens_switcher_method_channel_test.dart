import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_camera_lens_switcher/ios_camera_lens_switcher_method_channel.dart';
import 'package:ios_camera_lens_switcher/src/camera_lens_descriptor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelIosCameraLensSwitcher platform = MethodChannelIosCameraLensSwitcher();
  const MethodChannel channel = MethodChannel('ios_camera_lens_switcher');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getPlatformVersion') {
          return '42';
        }
        if (methodCall.method == 'listAvailableLenses') {
          return [
            {
              'id': 'back_wide',
              'name': 'Back Wide',
              'position': 'back',
              'category': 'wide',
              'focalLength': 4.5,
              'fieldOfView': 65.0,
            }
          ];
        }
        if (methodCall.method == 'switchLens') {
          return {
            'id': 'front_true_depth',
            'name': 'Front TrueDepth',
            'position': 'front',
            'category': 'trueDepth',
          };
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('listAvailableLenses', () async {
    final lenses = await platform.listAvailableLenses();
    expect(lenses, hasLength(1));
    expect(lenses.first.position, CameraLensPosition.back);
    expect(lenses.first.category, CameraLensCategory.wide);
  });

  test('switchLens', () async {
    final result = await platform.switchLens(CameraLensCategory.trueDepth);
    expect(result.position, CameraLensPosition.front);
    expect(result.category, CameraLensCategory.trueDepth);
  });
}
