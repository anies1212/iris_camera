import 'package:flutter/material.dart';

class StatusStrip extends StatelessWidget {
  const StatusStrip({
    super.key,
    required this.cameraState,
    required this.orientation,
    required this.focusExposureState,
    required this.isStreaming,
    required this.isRecording,
    required this.lastVideoPath,
    required this.imageStats,
  });

  final String cameraState;
  final String orientation;
  final String focusExposureState;
  final bool isStreaming;
  final bool isRecording;
  final String? lastVideoPath;
  final String imageStats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('State: $cameraState', style: _textStyle(context)),
          Text('Orientation: $orientation', style: _textStyle(context)),
          Text('AF/AE: $focusExposureState', style: _textStyle(context)),
          Text('Image stream: ${isStreaming ? 'on ($imageStats)' : 'off'}',
              style: _textStyle(context)),
          Text(
              'Recording: ${isRecording ? 'recording...' : lastVideoPath ?? 'idle'}',
              style: _textStyle(context)),
        ],
      ),
    );
  }

  TextStyle? _textStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70);
}
