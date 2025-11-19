import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_camera_lens_switcher/ios_camera_lens_switcher.dart';
import 'package:ios_camera_lens_switcher/ios_camera_lens_switcher_method_channel.dart';
import 'package:ios_camera_lens_switcher/ios_camera_lens_switcher_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIosCameraLensSwitcherPlatform
    with MockPlatformInterfaceMixin
    implements IosCameraLensSwitcherPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<List<CameraLensDescriptor>> listAvailableLenses() async {
    return [
      CameraLensDescriptor(
        id: 'front_true_depth',
        name: 'Front TrueDepth',
        position: CameraLensPosition.front,
        category: CameraLensCategory.trueDepth,
      ),
    ];
  }

  @override
  Future<CameraLensDescriptor> switchLens(CameraLensCategory category) async {
    return CameraLensDescriptor(
      id: 'back_wide',
      name: 'Back Wide',
      position: CameraLensPosition.back,
      category: category,
    );
  }
}

class ThrowingSwitchPlatform
    with MockPlatformInterfaceMixin
    implements IosCameraLensSwitcherPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('0');

  @override
  Future<List<CameraLensDescriptor>> listAvailableLenses() async =>
      <CameraLensDescriptor>[];

  @override
  Future<CameraLensDescriptor> switchLens(CameraLensCategory category) {
    throw PlatformException(
      code: 'lens_not_found',
      message: 'Lens not available',
    );
  }
}

void main() {
  final IosCameraLensSwitcherPlatform initialPlatform =
      IosCameraLensSwitcherPlatform.instance;

  test('$MethodChannelIosCameraLensSwitcher is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIosCameraLensSwitcher>());
  });

  test('getPlatformVersion', () async {
    IosCameraLensSwitcher iosCameraLensSwitcherPlugin = IosCameraLensSwitcher();
    MockIosCameraLensSwitcherPlatform fakePlatform =
        MockIosCameraLensSwitcherPlatform();
    IosCameraLensSwitcherPlatform.instance = fakePlatform;

    expect(await iosCameraLensSwitcherPlugin.getPlatformVersion(), '42');
  });

  test('listAvailableLenses delegates to platform', () async {
    IosCameraLensSwitcher iosCameraLensSwitcherPlugin = IosCameraLensSwitcher();
    MockIosCameraLensSwitcherPlatform fakePlatform =
        MockIosCameraLensSwitcherPlatform();
    IosCameraLensSwitcherPlatform.instance = fakePlatform;

    final lenses = await iosCameraLensSwitcherPlugin.listAvailableLenses();
    expect(lenses.single.id, 'front_true_depth');
  });

  test('switchLens delegates to platform', () async {
    final plugin = IosCameraLensSwitcher();
    final fakePlatform = MockIosCameraLensSwitcherPlatform();
    IosCameraLensSwitcherPlatform.instance = fakePlatform;

    final descriptor = await plugin.switchLens(CameraLensCategory.telephoto);
    expect(descriptor.category, CameraLensCategory.telephoto);
  });

  test('switchLens wraps PlatformException', () async {
    final plugin = IosCameraLensSwitcher();
    final throwingPlatform = ThrowingSwitchPlatform();
    IosCameraLensSwitcherPlatform.instance = throwingPlatform;

    expect(
      () => plugin.switchLens(CameraLensCategory.wide),
      throwsA(isA<CameraLensSwitcherException>()),
    );
  });

  tearDown(() {
    IosCameraLensSwitcherPlatform.instance = initialPlatform;
  });
}
