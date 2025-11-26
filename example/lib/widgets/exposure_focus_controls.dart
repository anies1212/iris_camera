import 'package:flutter/material.dart';
import 'package:iris_camera/iris_camera.dart';

import 'control_card.dart';

class ExposureFocusControls extends StatelessWidget {
  const ExposureFocusControls({
    super.key,
    required this.zoom,
    required this.onZoomChanged,
    required this.focusPosition,
    required this.onFocusPositionChanged,
    required this.supportsLensPosition,
    required this.exposureMode,
    required this.onExposureModeChanged,
    required this.focusMode,
    required this.onFocusModeChanged,
    required this.evMin,
    required this.evMax,
    required this.evValue,
    required this.onEvChanged,
    required this.wbTemperature,
    required this.wbTint,
    required this.onWhiteBalanceChanged,
    required this.onResetWhiteBalance,
  });

  final double zoom;
  final ValueChanged<double> onZoomChanged;
  final double focusPosition;
  final ValueChanged<double> onFocusPositionChanged;
  final bool supportsLensPosition;
  final ExposureMode exposureMode;
  final ValueChanged<ExposureMode> onExposureModeChanged;
  final FocusMode focusMode;
  final ValueChanged<FocusMode> onFocusModeChanged;
  final double evMin;
  final double evMax;
  final double evValue;
  final ValueChanged<double> onEvChanged;
  final double? wbTemperature;
  final double? wbTint;
  final void Function(double temperature, double tint) onWhiteBalanceChanged;
  final VoidCallback onResetWhiteBalance;

  @override
  Widget build(BuildContext context) {
    return ControlCard(
      title: 'Focus & Exposure',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledSlider(
            label: 'Zoom (${zoom.toStringAsFixed(1)}x)',
            value: zoom,
            min: 1,
            max: 10,
            divisions: 90,
            onChanged: onZoomChanged,
          ),
          LabeledSlider(
            label: 'Lens position (${focusPosition.toStringAsFixed(2)})',
            value: focusPosition,
            min: 0,
            max: 1,
            divisions: 100,
            onChanged: supportsLensPosition ? onFocusPositionChanged : null,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Exposure auto'),
                selected: exposureMode == ExposureMode.auto,
                onSelected: (_) => onExposureModeChanged(ExposureMode.auto),
              ),
              ChoiceChip(
                label: const Text('Exposure locked'),
                selected: exposureMode == ExposureMode.locked,
                onSelected: (_) => onExposureModeChanged(ExposureMode.locked),
              ),
              ChoiceChip(
                label: const Text('Focus auto'),
                selected: focusMode == FocusMode.auto,
                onSelected: (_) => onFocusModeChanged(FocusMode.auto),
              ),
              ChoiceChip(
                label: const Text('Focus locked'),
                selected: focusMode == FocusMode.locked,
                onSelected: (_) => onFocusModeChanged(FocusMode.locked),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label:
                'Exposure offset (${evValue.toStringAsFixed(2)} EV) range ${evMin.toStringAsFixed(1)}..${evMax.toStringAsFixed(1)}',
            value: evValue.clamp(evMin, evMax),
            min: evMin,
            max: evMax,
            divisions: (evMax > evMin) ? 40 : null,
            onChanged: onEvChanged,
          ),
          const SizedBox(height: 8),
          Text(
            'White balance (iOS: temperature/tint, Android: auto/lock)',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Colors.white70),
          ),
          Row(
            children: [
              Expanded(
                child: LabeledSlider(
                  label: 'Temp (${(wbTemperature ?? 5000).round()}K)',
                  value: (wbTemperature ?? 5000).clamp(2000, 8000),
                  min: 2000,
                  max: 8000,
                  divisions: 60,
                  onChanged: (value) =>
                      onWhiteBalanceChanged(value, wbTint ?? 0),
                ),
              ),
              Expanded(
                child: LabeledSlider(
                  label: 'Tint (${(wbTint ?? 0).toStringAsFixed(0)})',
                  value: (wbTint ?? 0).clamp(-50, 50),
                  min: -50,
                  max: 50,
                  divisions: 100,
                  onChanged: (value) =>
                      onWhiteBalanceChanged(wbTemperature ?? 5000, value),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onResetWhiteBalance,
              child: const Text('Reset WB'),
            ),
          ),
        ],
      ),
    );
  }
}
