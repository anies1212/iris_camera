import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_camera/src/iris_camera_method_channel.dart';
import 'package:iris_camera/src/camera_lens_descriptor.dart';
import 'package:iris_camera/src/exposure_mode.dart';
import 'package:iris_camera/src/resolution_preset.dart';
import 'package:iris_camera/src/focus_mode.dart';
import 'package:iris_camera/src/method_channel_keys.dart';
import 'package:iris_camera/src/focus_exposure_state_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final isMobilePlatform = Platform.isIOS || Platform.isAndroid;

  final platform = MethodChannelIrisCamera();
  const MethodChannel channel = MethodChannel('iris_camera');
  MethodCall? lastCall;

  setUp(() {
    final handlers = <String, dynamic Function(MethodCall)>{
      IrisMethod.getPlatformVersion.method: (_) => '42',
      IrisMethod.listAvailableLenses.method: (_) => [
            {
              'id': 'back_wide',
              'name': 'Back Wide',
              'position': 'back',
              'category': 'wide',
              'supportsFocus': true,
              'focalLength': 4.5,
              'fieldOfView': 65.0,
            },
          ],
      IrisMethod.switchLens.method: (_) => {
            'id': 'front_true_depth',
            'name': 'Front TrueDepth',
            'position': 'front',
            'category': 'trueDepth',
          },
      IrisMethod.getMinExposureOffset.method: (_) => -2.0,
      IrisMethod.getMaxExposureOffset.method: (_) => 2.5,
      IrisMethod.getExposureOffset.method: (_) => 0.5,
      IrisMethod.getExposureOffsetStepSize.method: (_) => 0.1,
      IrisMethod.setExposureOffset.method: (call) =>
          (call.arguments as Map<Object?, Object?>)['offset'],
      IrisMethod.getExposureMode.method: (_) => 'locked',
      IrisMethod.setResolutionPreset.method: (_) => null,
      IrisMethod.startImageStream.method: (_) => null,
      IrisMethod.stopImageStream.method: (_) => null,
      IrisMethod.setTorch.method: (_) => null,
      IrisMethod.setFocusMode.method: (_) => null,
      IrisMethod.getFocusMode.method: (_) => 'locked',
      IrisMethod.setFrameRateRange.method: (_) => null,
      IrisMethod.initialize.method: (_) => null,
      IrisMethod.pauseSession.method: (_) => null,
      IrisMethod.resumeSession.method: (_) => null,
      IrisMethod.disposeSession.method: (_) => null,
    };

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      lastCall = methodCall;
      final handler = handlers[methodCall.method];
      return handler?.call(methodCall);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  },
      skip: isMobilePlatform
          ? null
          : 'Method channel only available on iOS/Android.');

  test('listAvailableLenses', () async {
    final lenses = await platform.listAvailableLenses();
    expect(lenses, hasLength(1));
    expect(lenses.first.position, CameraLensPosition.back);
    expect(lenses.first.category, CameraLensCategory.wide);
    expect(lenses.first.supportsFocus, isTrue);
  },
      skip: isMobilePlatform
          ? null
          : 'Method channel only available on iOS/Android.');

  test('switchLens', () async {
    final result = await platform.switchLens(CameraLensCategory.trueDepth);
    expect(result.position, CameraLensPosition.front);
    expect(result.category, CameraLensCategory.trueDepth);
  },
      skip: isMobilePlatform
          ? null
          : 'Method channel only available on iOS/Android.');

  test('setFocus', () async {
    lastCall = null;
    await platform.setFocus(
      point: const Offset(0.25, 0.75),
      lensPosition: 0.9,
    );
    expect(lastCall?.method, IrisMethod.setFocus.method);
    expect(lastCall?.arguments, {
      'x': 0.25,
      'y': 0.75,
      'lensPosition': 0.9,
    });
  },
      skip: isMobilePlatform
          ? null
          : 'Method channel only available on iOS/Android.');

  test('setZoom', () async {
    lastCall = null;
    await platform.setZoom(2.5);
    expect(lastCall?.method, IrisMethod.setZoom.method);
    expect(lastCall?.arguments, {'zoomFactor': 2.5});
  },
      skip: isMobilePlatform
          ? null
          : 'Method channel only available on iOS/Android.');

  test('setWhiteBalance', () async {
    lastCall = null;
    await platform.setWhiteBalance(temperature: 5200, tint: 10);
    expect(lastCall?.method, IrisMethod.setWhiteBalance.method);
    expect(lastCall?.arguments, {'temperature': 5200, 'tint': 10});
  },
      skip: isMobilePlatform
          ? null
          : 'Method channel only available on iOS/Android.');

  test('exposure controls', () async {
    expect(await platform.getMinExposureOffset(), -2.0);
    expect(await platform.getMaxExposureOffset(), 2.5);
    expect(await platform.getExposureOffset(), 0.5);
    expect(await platform.getExposureOffsetStepSize(), 0.1);
    await platform.setExposureMode(ExposureMode.locked);
    expect(lastCall?.method, IrisMethod.setExposureMode.method);
    expect(lastCall?.arguments, {'mode': 'locked'});

    lastCall = null;
    await platform.setExposurePoint(const Offset(0.2, 0.8));
    expect(lastCall?.method, IrisMethod.setExposurePoint.method);
    expect(lastCall?.arguments, {'x': 0.2, 'y': 0.8});

    final appliedOffset = await platform.setExposureOffset(1.2);
    expect(appliedOffset, 1.2);

    final mode = await platform.getExposureMode();
    expect(mode, ExposureMode.locked);

    lastCall = null;
    await platform.setResolutionPreset(ResolutionPreset.high);
    expect(lastCall?.method, IrisMethod.setResolutionPreset.method);
    expect(lastCall?.arguments, {'preset': 'high'});
  },
      skip: isMobilePlatform
          ? null
          : 'Method channel only available on iOS/Android.');

  test('image stream wiring', () async {
    lastCall = null;
    await platform.startImageStream();
    expect(lastCall?.method, IrisMethod.startImageStream.method);
    await platform.stopImageStream();
    expect(lastCall?.method, IrisMethod.stopImageStream.method);
  },
      skip: isMobilePlatform
          ? null
          : 'Method channel only available on iOS/Android.');

  test('torch', () async {
    lastCall = null;
    await platform.setTorch(true);
    expect(lastCall?.method, IrisMethod.setTorch.method);
    expect(lastCall?.arguments, {'enabled': true});
  },
      skip: isMobilePlatform
          ? null
          : 'Method channel only available on iOS/Android.');

  test('focus mode', () async {
    lastCall = null;
    await platform.setFocusMode(FocusMode.locked);
    expect(lastCall?.method, IrisMethod.setFocusMode.method);
    expect(lastCall?.arguments, {'mode': 'locked'});

    final mode = await platform.getFocusMode();
    expect(mode, FocusMode.locked);
  },
      skip: isMobilePlatform
          ? null
          : 'Method channel only available on iOS/Android.');

  test('frame rate range', () async {
    lastCall = null;
    await platform.setFrameRateRange(minFps: 24, maxFps: 60);
    expect(lastCall?.method, IrisMethod.setFrameRateRange.method);
    expect(lastCall?.arguments, {'minFps': 24.0, 'maxFps': 60.0});
  },
      skip: isMobilePlatform
          ? null
          : 'Method channel only available on iOS/Android.');

  test('lifecycle controls', () async {
    lastCall = null;
    await platform.initialize();
    expect(lastCall?.method, IrisMethod.initialize.method);
    await platform.pauseSession();
    expect(lastCall?.method, IrisMethod.pauseSession.method);
    await platform.resumeSession();
    expect(lastCall?.method, IrisMethod.resumeSession.method);
    await platform.disposeSession();
    expect(lastCall?.method, IrisMethod.disposeSession.method);
  },
      skip: isMobilePlatform
          ? null
          : 'Method channel only available on iOS/Android.');

  test('focus/exposure state stream mapping', () async {
    final event = FocusExposureStateEvent.fromMap({'state': 'focusLocked'});
    expect(event.state, FocusExposureState.focusLocked);
  });
}
