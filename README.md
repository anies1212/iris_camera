# iris_camera

📸 iOS-first camera toolkit for Flutter, powered by AVFoundation. Render the native preview, switch lenses, stream frames, capture photos, tune exposure/white balance/torch/zoom, and listen to lifecycle + orientation + AF/AE state – all from Dart.

> Platform coverage: iOS only for now. Android/Web backends are planned for v2. Other platforms no-op safely.

---

## Highlights
- 🔍 Lens discovery & switching – list every lens (front included by default; exclude with `includeFrontCameras: false`) and reconfigure with `switchLens`.
- 🖼️ Native preview widget – `IrisCameraPreview` wraps `AVCaptureVideoPreviewLayer` with tap-to-focus + overlay hooks.
- 📸 Still capture – `capturePhoto` with flash/ISO/exposure overrides.
- 🎛️ Pro controls – focus mode/point, exposure mode/point/EV, white balance, frame rate range, torch, zoom, resolution presets.
- 📡 Streams – live BGRA image stream, orientation stream, lifecycle state stream, AF/AE state stream.
- 🔧 Lifecycle – explicit `initialize/pause/resume/dispose` and structured errors via `IrisCameraException`.

---

## Install
```bash
flutter pub add iris_camera
```

```dart
import 'package:iris_camera/iris_camera.dart';

final camera = IrisCamera();
final lenses = await camera.listAvailableLenses(); // includeFrontCameras defaults to true
await camera.switchLens(lenses.first.category);
final photo = await camera.capturePhoto(
  options: const PhotoCaptureOptions(flashMode: PhotoFlashMode.auto),
);
```

Live preview:
```dart
final focusController = FocusIndicatorController();

IrisCameraPreview(
  aspectRatio: 3 / 2,
  enableTapToFocus: true,
  showFocusIndicator: true,
  onTapFocus: (point) => camera.setFocus(point: point),
  focusIndicatorController: focusController,
);
```

---

## iOS setup
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs the camera to capture photos.</string>
```
That’s it. Permissions are requested automatically on first use.

> Exclude front cameras by calling `listAvailableLenses(includeFrontCameras: false)`.

---

## API quick reference
Key methods:
- `listAvailableLenses({includeFrontCameras})` → `List<CameraLensDescriptor>`
- `switchLens(CameraLensCategory category)` → `CameraLensDescriptor`
- `capturePhoto({PhotoCaptureOptions options})` → `Uint8List`
- Focus: `setFocus(point/lensPosition)`, `setFocusMode`, `focusExposureStateStream`
- Exposure: `setExposureMode`, `setExposurePoint`, `setExposureOffset`, `getMin/MaxExposureOffset`, `getExposureOffsetStepSize`
- Zoom/torch/WB: `setZoom`, `setTorch`, `setWhiteBalance`
- Frame/format: `setFrameRateRange`, `setResolutionPreset`
- Streams: `imageStream`, `orientationStream`, `stateStream`
- Lifecycle: `initialize`, `pauseSession`, `resumeSession`, `disposeSession`
- Errors: `IrisCameraException(code, message, details)`

Data classes:
- `CameraLensDescriptor` (`id`, `name`, `position`, `category`, `supportsFocus`, optional `focalLength`, `fieldOfView`)
- `PhotoCaptureOptions` (`flashMode`, `exposureDuration`, `iso`)
- `OrientationEvent`, `CameraStateEvent`, `FocusExposureStateEvent`, `IrisImageFrame`

Widget:
- `IrisCameraPreview` with tap-to-focus + focus indicator styling/control.

---

## iris_camera vs camera (iOS)

| Capability | [iris_camera](https://pub.dev/packages/iris_camera) | [camera](https://pub.dev/packages/camera) |
| --- | --- | --- |
| Still photos | ✅ Shared session JPEG capture | ✅ |
| Live preview widget | ✅ `IrisCameraPreview` (iOS) | ✅ |
| Lens discovery/switching | ✅ Enumerate + switch by category (wide/ultraWide/telephoto/etc.), front opt-in | ⚪️ List only (no switching API) |
| Tap/manual focus | ✅ (point or lens position) | ✅ |
| Exposure controls | ✅ mode/point/EV/ISO/exposure duration | ✅ (mode/point/offset) |
| White balance override | ✅ temperature/tint | ⚪️ (not exposed) |
| Zoom | ✅ | ✅ |
| Torch | ✅ (torch separate from flash) | ✅ |
| Frame rate range | ✅ min/max FPS | ⚪️ limited |
| Resolution preset | ✅ | ✅ |
| Live image stream | ✅ BGRA | ✅ |
| Orientation stream | ✅ device/video | ✅ |
| AF/AE state stream | ✅ | ⚪️ basic focus/exposure mode only |
| Lifecycle controls | ✅ initialize/pause/resume/dispose + state stream | ✅ (controller init/dispose) |
| Video recording | ❌ (planned) | ✅ |
| Android/Web | ❌ (planned v2) | ✅ |

---

## Example flow
```dart
final lenses = await camera.listAvailableLenses();
final tele = lenses.firstWhere(
  (lens) => lens.category == CameraLensCategory.telephoto,
  orElse: () => lenses.first,
);

await camera.switchLens(tele.category);
await camera.initialize();
camera.stateStream.listen((event) => debugPrint('state=${event.state}'));
camera.focusExposureStateStream.listen((event) => debugPrint('af/ae=${event.state}'));

await camera.setExposureMode(ExposureMode.locked);
await camera.setFocusMode(FocusMode.locked);
final photo = await camera.capturePhoto();
```

---

## License
MIT — see [LICENSE](LICENSE).
