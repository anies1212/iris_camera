# ios_camera_lens_switcher

Flutter plugin that lets you enumerate every camera lens on an iPhone (wide, ultra-wide, telephoto, Continuity/remote, etc.) and switch between them from Dart with a single API. The end goal is to make it trivial for camera or live-streaming apps to expose "lens switcher" UI without re-implementing the native camera stack.

---

## Highlights

- Enumerates all physical lenses exposed by `AVCaptureDeviceDiscoverySession` (built-in and external Continuity cameras).
- Common Dart model (`CameraLensDescriptor`) so Flutter widgets can display a consistent selector UI.
- Simple commands: `listAvailableLenses()` + `switchLens(CameraLensCategory.*)` (events stream planned).
- Graceful fallbacks (front/back only) on Android and desktop so the plugin can still build everywhere.

---

## Quick Start

```bash
flutter pub add ios_camera_lens_switcher
```

```dart
final controller = IosCameraLensSwitcher();
final lenses = await controller.listAvailableLenses();

try {
  await controller.switchLens(CameraLensCategory.ultraWide);
} on CameraLensSwitcherException catch (error) {
  debugPrint('Failed to switch lens: ${error.code} -> ${error.message}');
}
```

More usage examples are in `example/lib/main.dart`.

---

## iOS Setup

Add a camera usage description so iOS lets your app enumerate cameras:

```xml
<!-- ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>This app needs access to the camera to switch lenses.</string>
```

Continuity/remote cameras still piggyback on the same permission, so nothing else is required. The plugin will automatically call `AVCaptureDevice.requestAccess` the first time `switchLens` is invoked.

---

## Error Handling

Most plugin methods can throw `CameraLensSwitcherException`. Catch it to react to permission issues or missing hardware:

```dart
try {
  await controller.switchLens(CameraLensCategory.telephoto);
} on CameraLensSwitcherException catch (error) {
  if (error.code == 'camera_permission_denied') {
    // Prompt user to enable camera access in Settings
  }
}
```

---

## Public API

```dart
final switcher = IosCameraLensSwitcher();

Future<List<CameraLensDescriptor>> listAvailableLenses();
Future<CameraLensDescriptor> switchLens(CameraLensCategory category);
```

- `CameraLensDescriptor` contains `id`, `name`, `type` (`wide`, `ultraWide`, `telephoto`, `continuity`, `frontFacing`, etc.), `focalLength`, and `fieldOfView`.
- Errors throw `CameraLensSwitcherException` with `code` + `message`.

---

## Architecture & Design

### Layered Structure

1. **Platform interface (`lib/ios_camera_lens_switcher_platform_interface.dart`)** defines the abstract methods and default `MethodChannel` implementation.
2. **Dart facade (`lib/ios_camera_lens_switcher.dart`)** exposes a friendly API and transforms platform maps into strongly typed models so apps can manage their own selection state.
3. **iOS implementation** (primary target):
   - Uses `AVCaptureDevice.DiscoverySession` w/ `dualCamera`, `ultraWideCamera`, `telephotoCamera`, `builtInWideAngleCamera`, `continuityCamera`.
   - Reports each lens as a descriptor. `id` is the `uniqueID` of `AVCaptureDevice`.
   - Switching lens rebuilds an internal `AVCaptureSession` input so that the device is active and validated before returning to Flutter.
4. **Android/desktop/web**: initially stubbed to expose only the default front/back cameras so the plugin can ship as a general package. Proper multi-lens support can be added incrementally (`Camera2` + logical/physical IDs on Android).

### Method Channel Contract

| Method                | Arguments                       | Result                                            |
|-----------------------|---------------------------------|---------------------------------------------------|
| `listAvailableLenses` | none                            | `List<Map>` each describing a `CameraLensDescriptor` |
| `switchLens`          | `{ "category": "<type-name>" }` | `Map` describing the selected lens                |

All calls are idempotent and respond with structured errors if the requested lens is unavailable.

### State Management

- Dart side caches `List<CameraLensDescriptor>` to avoid re-querying.
- (Planned) Streams from the native side will be debounced before emitting to Flutter widgets to avoid UI thrash while the session reconfigures.
- (Planned) Native implementations will publish state changes to keep Flutter UI in sync after system-level switches (e.g., Control Center camera change).

### Test Strategy

- Unit tests on the platform interface ensure serialization/deserialization for `CameraLensDescriptor`.
- iOS unit tests cover:
  - Correct discovery session filters (based on device capabilities).
  - Session reconfiguration when switching lenses.
  - Graceful handling when a lens becomes unavailable mid-session.
- Integration test (`example/integration_test/`) uses `camera` package’s preview to confirm the selected lens is actually applied.

---

## Planned Roadmap

1. Ship a polished Flutter example that shows thumbnails for each lens and toggles between them.
2. Add Android multi-camera support (logical/physical camera IDs).
3. Explore macOS Continuity Camera detection (same API as iOS but different permissions).
4. Publish v0.1.0 to pub.dev with documentation + screenshots.

---

## Contributing

1. Fork the repo.
2. Run `flutter test` and `flutter analyze` before opening a PR.
3. For platform-specific changes, add notes to the **Architecture & Design** section if you introduce a new concept.

---

## License

MIT — see [LICENSE](LICENSE).
