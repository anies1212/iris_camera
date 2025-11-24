import 'dart:typed_data';

import 'package:flutter/material.dart';

class CapturedPhotoThumbnail extends StatelessWidget {
  const CapturedPhotoThumbnail({super.key, this.bytes});

  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white24),
          ),
          child: bytes == null
              ? const SizedBox.expand()
              : Image.memory(
                  bytes!,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }
}
