# iris_camera

iOS-first camera toolkit for Flutter. `iris_camera` exposes live preview widgets, structured lens descriptors, lens switching, and still-photo capture powered by AVFoundation – all through a single Dart API.

  The plugin focuses on real hardware parity: it shares one `AVCaptureSession` between preview and capture so you always see exactly what the sensor sees when you trigger a shot, and it surfaces precise metadata (position, category, field of view, focus capability) for every selectable lens.

> **Platform coverage:** only iOS is supported right now. Android and web implementations are planned for **v2.0.0**, but at the moment the plugin will no-op on other platforms.

---

## Features

- 🔍 **Lens discovery** – enumerate every physical lens that AVFoundation exposes (wide, ultra-wide, telephoto, dual/triple arrays, Continuity cameras, etc.).
- 🔁 **Hardware switching** – swap the active sensor with a single `switchLens` call; the plugin reconfigures the capture session for you and returns the selected descriptor.
- 🖼️ **Shared preview widget** – `IrisCameraPreview` renders the native `AVCaptureVideoPreviewLayer` via a `UiKitView`, so the Flutter UI always shows what the active sensor sees – flip on `enableTapToFocus` and `showFocusIndicator` for built-in gestures and overlays (customizable via `FocusIndicatorStyle`).
- 📸 **Still capture** – `capturePhoto()` grabs a high-resolution JPEG from the same session, with flash mode plus manual exposure/ISO controls via `PhotoCaptureOptions`.
- 🎯 **Manual focus & zoom** – call `setFocus()` to drive tap-to-focus points or custom lens positions, and `setZoom()` to animate digital zoom factors.
- ⚪ **White balance overrides** – `setWhiteBalance()` accepts temperature/tint overrides or reverts to auto when omitted.
- ⚠️ **Structured errors** – `CameraLensSwitcherException` wraps native error codes/messages so your app can react consistently to permission or hardware failures.

---

## Installation

```bash
flutter pub add iris_camera
```

```dart
import 'package:iris_camera/iris_camera.dart';

final camera = IrisCamera();
final lenses = await camera.listAvailableLenses();

await camera.switchLens(CameraLensCategory.ultraWide);
final photo = await camera.capturePhoto(
  options: const PhotoCaptureOptions(flashMode: PhotoFlashMode.auto),
);
```

Use the provided `IrisCameraPreview` widget to show the live feed:

```dart
IrisCameraPreview(
  aspectRatio: 3 / 2,
  borderRadius: const BorderRadius.all(Radius.circular(16)),
  enableTapToFocus: true,
  onTapFocus: (point) => camera.setFocus(point: point),
  showFocusIndicator: true,
  focusIndicatorStyle: const FocusIndicatorStyle(color: Colors.amber),
)
```

The full demo app is in [`example/lib/main.dart`](example/lib/main.dart).

---

## iOS Setup

Add the camera usage string to your Info.plist:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs the camera to capture photos.</string>
```

Nothing else is required; the plugin automatically requests permission the first time you call `switchLens` or `capturePhoto`.

> Front-facing lenses are currently filtered out of `listAvailableLenses`. The shared preview/capture session mirrors the native output, so supporting front cameras would require a dedicated mirrored preview pipeline to avoid confusing users with flipped feeds. This is tracked for a future release; for now we only expose lenses we can render authentically.

---

## Dart API Surface

```dart
final camera = IrisCamera();

Future<List<CameraLensDescriptor>> listAvailableLenses();
Future<CameraLensDescriptor> switchLens(CameraLensCategory category);
Future<Uint8List> capturePhoto({PhotoCaptureOptions options});
Future<void> setFocus({Offset? point, double? lensPosition});
Future<void> setZoom(double zoomFactor);
Future<void> setWhiteBalance({double? temperature, double? tint});
```

- `CameraLensDescriptor` exposes `id`, `name`, `position`, `category`, optional `focalLength`, `fieldOfView`, and `supportsFocus` to indicate whether tap/manual focus is available for that lens.
- `PhotoCaptureOptions` currently supports `flashMode` (`auto`, `on`, `off`), optional `exposureDuration`, and ISO overrides.
- `setFocus` accepts either a normalized preview `point` (`Offset(dx, dy)` in [0–1]) or a `lensPosition` (0–1) to drive custom focus behaviour.
- `setZoom` clamps values to the device’s supported zoom range, and `setWhiteBalance` accepts temperature/tint overrides (pass nulls to return to auto).
- Errors throw `CameraLensSwitcherException` (`code`, `message`, `details`).

##

## Widgets

| Widget               | Description                                                                 |
| -------------------- | --------------------------------------------------------------------------- |
| `IrisCameraPreview`  | Embeds the `AVCaptureVideoPreviewLayer` via `UiKitView` with built-in tap-to-focus + optional overlays (tweak via `FocusIndicatorStyle` or `FocusIndicatorController`). |

---

## Example Interaction Flow

```dart
final lenses = await camera.listAvailableLenses();
final ultraWide = lenses.firstWhere(
  (lens) => lens.category == CameraLensCategory.ultraWide,
  orElse: () => lenses.first,
);

try {
  await camera.switchLens(ultraWide.category);
  final photoBytes = await camera.capturePhoto();
  // Save photoBytes to disk or upload.

  // Tap-to-focus at the center of the preview.
  await camera.setFocus(point: const Offset(0.5, 0.5));
} on CameraLensSwitcherException catch (error) {
  debugPrint('Camera error: ${error.code} -> ${error.message}');
}
```

Tap-to-focus gestures and the indicator overlay are baked into the preview:

```dart
final focusController = FocusIndicatorController();

IrisCameraPreview(
  enableTapToFocus: true,
  onTapFocus: (point) => camera.setFocus(point: point),
  showFocusIndicator: true,
  focusIndicatorController: focusController, // Optional override.
  focusIndicatorStyle: const FocusIndicatorStyle(
    color: Colors.greenAccent,
    size: 72,
  ),
);
```

---

## Roadmap

1. Finalize front-camera support (mirrored preview + capture pipeline).
2. Android implementation (likely CameraX) with the same Dart API.
3. Video capture hooks built on the shared session.
4. Publish v1.0 once cross-platform parity is reached, then revisit v2 for Android.

---

## License

MIT — see [LICENSE](LICENSE).
