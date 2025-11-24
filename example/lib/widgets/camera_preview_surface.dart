import 'package:flutter/material.dart';
import 'package:iris_camera/iris_camera.dart';

class CameraPreviewSurface extends StatelessWidget {
  const CameraPreviewSurface({
    super.key,
    required this.onTapFocus,
    required this.zoomFactor,
    required this.onZoomChanged,
    required this.isSwitchingLens,
    required this.lensName,
    required this.focusIndicatorController,
    required this.supportsFocus,
  });

  final TapToFocusCallback onTapFocus;
  final double zoomFactor;
  final ValueChanged<double> onZoomChanged;
  final bool isSwitchingLens;
  final String lensName;
  final FocusIndicatorController focusIndicatorController;
  final bool supportsFocus;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: IrisCameraPreview(
                aspectRatio: 3 / 4,
                showFocusIndicator: supportsFocus,
                enableTapToFocus: supportsFocus,
                onTapFocus: onTapFocus,
                focusIndicatorController: focusIndicatorController,
                placeholder: Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Text(
                    'Camera preview is available on iOS devices.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            if (isSwitchingLens)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                children: [
                  _ZoomSlider(
                    value: zoomFactor,
                    onChanged: onZoomChanged,
                  ),
                  const SizedBox(height: 12),
                  LensBadge(label: lensName),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LensBadge extends StatelessWidget {
  const LensBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(label.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(letterSpacing: 1.4, color: Colors.white70)),
    );
  }
}

class _ZoomSlider extends StatelessWidget {
  const _ZoomSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        trackHeight: 3,
      ),
      child: Slider(
        value: value.clamp(1.0, 5.0),
        min: 1.0,
        max: 5.0,
        divisions: 16,
        label: '${value.toStringAsFixed(1)}x',
        onChanged: onChanged,
      ),
    );
  }
}
