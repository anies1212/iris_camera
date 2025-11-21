import 'package:flutter/material.dart';
import 'package:iris_camera/iris_camera.dart';

class ManualFocusPreviewSection extends StatelessWidget {
  const ManualFocusPreviewSection({
    super.key,
    required this.title,
    required this.focusEnabled,
    required this.onTap,
  });

  final String title;
  final bool focusEnabled;
  final TapToFocusCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          IrisCameraPreview(
            aspectRatio: 3 / 2,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            placeholder: const Center(
              child: Text(
                'Camera preview is only available on iOS.',
                textAlign: TextAlign.center,
              ),
            ),
            showFocusIndicator: true,
            enableTapToFocus: focusEnabled,
            onTapFocus: focusEnabled ? onTap : null,
          ),
        ],
      ),
    );
  }
}
