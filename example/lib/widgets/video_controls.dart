import 'package:flutter/material.dart';

import 'control_card.dart';

class VideoControls extends StatelessWidget {
  const VideoControls({
    super.key,
    required this.isRecording,
    required this.enableAudio,
    required this.lastVideoPath,
    required this.onToggleAudio,
    required this.onStart,
    required this.onStop,
  });

  final bool isRecording;
  final bool enableAudio;
  final String? lastVideoPath;
  final ValueChanged<bool> onToggleAudio;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return ControlCard(
      title: 'Video',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: enableAudio,
            onChanged: isRecording ? null : onToggleAudio,
            title: const Text('Enable audio'),
            dense: true,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isRecording ? null : onStart,
                  icon:
                      const Icon(Icons.fiber_manual_record, color: Colors.red),
                  label: const Text('Start'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isRecording ? onStop : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lastVideoPath == null ? 'No recording yet' : 'Last: $lastVideoPath',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
