import 'package:flutter/material.dart';
import 'package:iris_camera/iris_camera.dart';

class FlashPicker extends StatelessWidget {
  const FlashPicker({super.key, required this.value, required this.onChanged});

  final PhotoFlashMode value;
  final ValueChanged<PhotoFlashMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Flash'),
        const SizedBox(width: 8),
        DropdownButton<PhotoFlashMode>(
          value: value,
          onChanged: (mode) {
            if (mode != null) onChanged(mode);
          },
          items: const [
            DropdownMenuItem(
              value: PhotoFlashMode.auto,
              child: Text('Auto'),
            ),
            DropdownMenuItem(
              value: PhotoFlashMode.on,
              child: Text('On'),
            ),
            DropdownMenuItem(
              value: PhotoFlashMode.off,
              child: Text('Off'),
            ),
          ],
        ),
      ],
    );
  }
}

class ExposurePicker extends StatelessWidget {
  const ExposurePicker(
      {super.key, required this.value, required this.onChanged});

  final double? value;
  final ValueChanged<double?> onChanged;

  static const _options = <double?>[null, 0.5, 1, 2, 4];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Exposure'),
        const SizedBox(width: 8),
        DropdownButton<double?>(
          value: value,
          onChanged: onChanged,
          items: _options
              .map(
                (seconds) => DropdownMenuItem<double?>(
                  value: seconds,
                  child: Text(
                    seconds == null ? 'Auto' : '${seconds.toStringAsFixed(1)}s',
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class IsoPicker extends StatelessWidget {
  const IsoPicker({super.key, required this.value, required this.onChanged});

  final double? value;
  final ValueChanged<double?> onChanged;

  static const _options = <double?>[null, 100, 200, 400, 800, 1600];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('ISO'),
        const SizedBox(width: 8),
        DropdownButton<double?>(
          value: value,
          onChanged: onChanged,
          items: _options
              .map(
                (iso) => DropdownMenuItem<double?>(
                  value: iso,
                  child: Text(iso == null ? 'Auto' : iso.toStringAsFixed(0)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class ManualFocusSlider extends StatelessWidget {
  const ManualFocusSlider({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Manual focus'),
        Slider(
          value: value,
          onChanged: enabled ? onChanged : null,
          onChangeEnd: enabled ? onChangeEnd : null,
        ),
        if (!enabled)
          Text(
            'Unavailable for this lens',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.orange.shade700),
          ),
      ],
    );
  }
}

class ZoomSlider extends StatelessWidget {
  const ZoomSlider({super.key, required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Zoom'),
        Slider(
          value: value,
          min: 1.0,
          max: 4.0,
          divisions: 30,
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class WhiteBalanceControls extends StatelessWidget {
  const WhiteBalanceControls({
    super.key,
    required this.temperature,
    required this.tint,
    required this.autoEnabled,
    required this.onAutoToggled,
    required this.onTemperatureChanged,
    required this.onTintChanged,
  });

  final double temperature;
  final double tint;
  final bool autoEnabled;
  final ValueChanged<bool> onAutoToggled;
  final ValueChanged<double> onTemperatureChanged;
  final ValueChanged<double> onTintChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Auto white balance'),
            Switch(
              value: autoEnabled,
              onChanged: onAutoToggled,
            ),
          ],
        ),
        if (!autoEnabled) ...[
          const Text('Temperature (K)'),
          Slider(
            value: temperature,
            min: 3000,
            max: 7500,
            divisions: 18,
            label: temperature.toStringAsFixed(0),
            onChanged: onTemperatureChanged,
          ),
          const Text('Tint'),
          Slider(
            value: tint,
            min: -150,
            max: 150,
            divisions: 30,
            label: tint.toStringAsFixed(0),
            onChanged: onTintChanged,
          ),
        ],
      ],
    );
  }
}
