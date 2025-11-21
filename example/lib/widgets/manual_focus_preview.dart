import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iris_camera/iris_camera.dart';

import 'captured_photo_preview.dart';
import 'lens_controls.dart';
import 'lens_status_indicator.dart';
import 'manual_focus_preview_section.dart';

class ManualFocusPreview extends StatelessWidget {
  const ManualFocusPreview({
    super.key,
    required this.selectedLens,
    required this.lenses,
    required this.onLensSelected,
    required this.onCaptureRequested,
    required this.isCapturing,
    required this.lastPhotoBytes,
    required this.flashMode,
    required this.onFlashModeChanged,
    required this.exposureSeconds,
    required this.onExposureChanged,
    required this.isoValue,
    required this.onIsoChanged,
    required this.manualFocusPosition,
    required this.onManualFocusChanged,
    required this.onManualFocusChangeEnd,
    required this.onPreviewTap,
    required this.zoomFactor,
    required this.onZoomChanged,
    required this.whiteBalanceTemperature,
    required this.whiteBalanceTint,
    required this.autoWhiteBalance,
    required this.onWhiteBalanceChanged,
  });

  final CameraLensDescriptor selectedLens;
  final List<CameraLensDescriptor> lenses;
  final ValueChanged<CameraLensDescriptor> onLensSelected;
  final VoidCallback onCaptureRequested;
  final bool isCapturing;
  final Uint8List? lastPhotoBytes;
  final PhotoFlashMode flashMode;
  final ValueChanged<PhotoFlashMode> onFlashModeChanged;
  final double? exposureSeconds;
  final ValueChanged<double?> onExposureChanged;
  final double? isoValue;
  final ValueChanged<double?> onIsoChanged;
  final double manualFocusPosition;
  final ValueChanged<double> onManualFocusChanged;
  final ValueChanged<double> onManualFocusChangeEnd;
  final TapToFocusCallback onPreviewTap;
  final double zoomFactor;
  final ValueChanged<double> onZoomChanged;
  final double whiteBalanceTemperature;
  final double whiteBalanceTint;
  final bool autoWhiteBalance;
  final Future<void> Function({
    double? temperature,
    double? tint,
    bool auto,
  }) onWhiteBalanceChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ManualFocusPreviewSection(
          title: 'Live preview (${selectedLens.category.name})',
          focusEnabled: selectedLens.supportsFocus,
          onTap: onPreviewTap,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current lens: ${selectedLens.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (!selectedLens.supportsFocus)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Manual/tap focus not supported on this lens.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.orange.shade700),
                  ),
                ),
              const SizedBox(height: 12),
              FlashPicker(
                value: flashMode,
                onChanged: onFlashModeChanged,
              ),
              const SizedBox(height: 8),
              ExposurePicker(
                value: exposureSeconds,
                onChanged: onExposureChanged,
              ),
              const SizedBox(height: 8),
              IsoPicker(
                value: isoValue,
                onChanged: onIsoChanged,
              ),
              const SizedBox(height: 8),
              ManualFocusSlider(
                value: manualFocusPosition,
                enabled: selectedLens.supportsFocus,
                onChanged: onManualFocusChanged,
                onChangeEnd: onManualFocusChangeEnd,
              ),
              const SizedBox(height: 8),
              ZoomSlider(
                value: zoomFactor,
                onChanged: onZoomChanged,
              ),
              const SizedBox(height: 8),
              WhiteBalanceControls(
                temperature: whiteBalanceTemperature,
                tint: whiteBalanceTint,
                autoEnabled: autoWhiteBalance,
                onAutoToggled: (enabled) {
                  onWhiteBalanceChanged(auto: enabled);
                },
                onTemperatureChanged: (value) {
                  onWhiteBalanceChanged(temperature: value);
                },
                onTintChanged: (value) {
                  onWhiteBalanceChanged(tint: value);
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: isCapturing ? null : onCaptureRequested,
                icon: const Icon(Icons.camera),
                label: Text(isCapturing ? 'Capturing…' : 'Capture'),
              ),
              const SizedBox(width: 12),
              if (lastPhotoBytes case final bytes?)
                Expanded(
                  child: CapturedPhotoPreview(bytes: bytes),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: lenses.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final lens = lenses[index];
            final isActive = lens.id == selectedLens.id;
            return ListTile(
              title: Text(lens.name),
              subtitle: Text(buildLensSubtitle(lens)),
              trailing: LensStatusIndicator(isActive: isActive),
              selected: isActive,
              onTap: isActive ? null : () => onLensSelected(lens),
            );
          },
        ),
      ],
    );
  }
}
