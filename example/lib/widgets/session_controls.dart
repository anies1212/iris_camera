import 'package:flutter/material.dart';
import 'package:iris_camera/iris_camera.dart';

import 'control_card.dart';

class SessionControls extends StatelessWidget {
  const SessionControls({
    super.key,
    required this.torchEnabled,
    required this.onToggleTorch,
    required this.onInitialize,
    required this.onPause,
    required this.onResume,
    required this.onDispose,
    required this.onResolutionChanged,
    required this.currentPreset,
    required this.minFps,
    required this.maxFps,
    required this.onMinFpsChanged,
    required this.onMaxFpsChanged,
    required this.onApplyFrameRate,
    required this.isStreaming,
    required this.onToggleImageStream,
  });

  final bool torchEnabled;
  final VoidCallback onToggleTorch;
  final VoidCallback onInitialize;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onDispose;
  final ResolutionPreset currentPreset;
  final ValueChanged<ResolutionPreset> onResolutionChanged;
  final double minFps;
  final double maxFps;
  final ValueChanged<double> onMinFpsChanged;
  final ValueChanged<double> onMaxFpsChanged;
  final VoidCallback onApplyFrameRate;
  final bool isStreaming;
  final VoidCallback onToggleImageStream;

  @override
  Widget build(BuildContext context) {
    return ControlCard(
      title: 'Session',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                  onPressed: onInitialize, child: const Text('Initialize')),
              ElevatedButton(onPressed: onPause, child: const Text('Pause')),
              ElevatedButton(onPressed: onResume, child: const Text('Resume')),
              ElevatedButton(
                  onPressed: onDispose, child: const Text('Dispose')),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButton<ResolutionPreset>(
            value: currentPreset,
            isExpanded: true,
            dropdownColor: Colors.black87,
            items: ResolutionPreset.values
                .map(
                  (preset) => DropdownMenuItem(
                    value: preset,
                    child: Text(preset.name),
                  ),
                )
                .toList(),
            onChanged: (preset) {
              if (preset != null) onResolutionChanged(preset);
            },
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: 'Min FPS (${minFps.toStringAsFixed(0)})',
            value: minFps,
            min: 1,
            max: 120,
            divisions: 119,
            onChanged: onMinFpsChanged,
          ),
          LabeledSlider(
            label: 'Max FPS (${maxFps.toStringAsFixed(0)})',
            value: maxFps,
            min: 1,
            max: 240,
            divisions: 239,
            onChanged: onMaxFpsChanged,
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: onApplyFrameRate,
                child: const Text('Apply FPS'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onToggleImageStream,
                icon: Icon(isStreaming ? Icons.stop : Icons.play_arrow),
                label: Text(isStreaming ? 'Stop stream' : 'Start stream'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onToggleTorch,
                icon: Icon(
                  torchEnabled ? Icons.flash_on : Icons.flash_off,
                  color: torchEnabled ? Colors.amber : Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
