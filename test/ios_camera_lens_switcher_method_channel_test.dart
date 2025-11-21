import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_camera/src/iris_camera_method_channel.dart';
import 'package:iris_camera/src/camera_lens_descriptor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelIrisCamera();
  const MethodChannel channel = MethodChannel('iris_camera');
  MethodCall? lastCall;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      lastCall = methodCall;
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
            'supportsFocus': true,
            'focalLength': 4.5,
            'fieldOfView': 65.0,
          },
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
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('listAvailableLenses', () async {
    final lenses = await platform.listAvailableLenses();
    expect(lenses, hasLength(1));
    expect(lenses.first.position, CameraLensPosition.back);
    expect(lenses.first.category, CameraLensCategory.wide);
    expect(lenses.first.supportsFocus, isTrue);
  });

  test('switchLens', () async {
    final result = await platform.switchLens(CameraLensCategory.trueDepth);
    expect(result.position, CameraLensPosition.front);
    expect(result.category, CameraLensCategory.trueDepth);
  });

  test('setFocus', () async {
    lastCall = null;
    await platform.setFocus(
      point: const Offset(0.25, 0.75),
      lensPosition: 0.9,
    );
    expect(lastCall?.method, 'setFocus');
    expect(lastCall?.arguments, {
      'x': 0.25,
      'y': 0.75,
      'lensPosition': 0.9,
    });
  });

  test('setZoom', () async {
    lastCall = null;
    await platform.setZoom(2.5);
    expect(lastCall?.method, 'setZoom');
    expect(lastCall?.arguments, {'zoomFactor': 2.5});
  });

  test('setWhiteBalance', () async {
    lastCall = null;
    await platform.setWhiteBalance(temperature: 5200, tint: 10);
    expect(lastCall?.method, 'setWhiteBalance');
    expect(lastCall?.arguments, {'temperature': 5200, 'tint': 10});
  });
}
