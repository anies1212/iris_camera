## 1.0.1

- Improved output format for better clarity.
- Enhanced GitHub workflow reliability.
- Fixed AI prompt issues for better performance.
- Refined secret management in AI model implementations.
- Addressed context collection inaccuracies.
## 0.0.1

- Initial release of `iris_camera` (previously `ios_camera_lens_switcher`):
  - Shared `IrisCameraPreview` widget wired to the same `AVCaptureSession` used for still capture.
    - Built-in `enableTapToFocus` + `onTapFocus` gestures, automatic focus indicators, and customizable overlays via `FocusIndicatorStyle`.
  - Lens discovery + switching via strongly typed `CameraLensDescriptor`.
  - Still-photo capture with flash, optional manual exposure duration, ISO, manual focus (tap-to-focus + lens position), zoom, and custom white balance controls.
  - Optional focus indicators via `FocusIndicatorController` and `IrisCameraPreview(showFocusIndicator: true)`.
  - Graceful error handling through `CameraLensSwitcherException`.
  - iOS-only implementation; front-facing lenses are temporarily filtered until mirrored preview support is added.
