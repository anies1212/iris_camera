import 'package:flutter/material.dart';
import 'package:iris_camera/iris_camera.dart';

class CameraTopBar extends StatelessWidget {
  const CameraTopBar({
    super.key,
    required this.lensName,
    required this.flashMode,
    required this.onFlashChanged,
    required this.isSwitching,
    required this.platformVersion,
  });

  final String lensName;
  final PhotoFlashMode flashMode;
  final ValueChanged<PhotoFlashMode> onFlashChanged;
  final bool isSwitching;
  final String? platformVersion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lensName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  isSwitching
                      ? 'Reconfiguring lens…'
                      : 'Tap to focus • Swipe to switch lenses',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  'Platform: ${platformVersion ?? 'Loading…'}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
          FlashSelector(
            value: flashMode,
            onChanged: onFlashChanged,
          ),
        ],
      ),
    );
  }
}

class FlashSelector extends StatelessWidget {
  const FlashSelector(
      {super.key, required this.value, required this.onChanged});

  final PhotoFlashMode value;
  final ValueChanged<PhotoFlashMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PhotoFlashMode>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white12
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      segments: const [
        ButtonSegment(value: PhotoFlashMode.off, label: Text('Flash Off')),
        ButtonSegment(value: PhotoFlashMode.auto, label: Text('Auto')),
        ButtonSegment(value: PhotoFlashMode.on, label: Text('On')),
      ],
      selected: {value},
      onSelectionChanged: (values) {
        if (values.isNotEmpty) {
          onChanged(values.first);
        }
      },
    );
  }
}
