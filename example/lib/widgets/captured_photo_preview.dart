import 'dart:typed_data';

import 'package:flutter/material.dart';

class CapturedPhotoPreview extends StatelessWidget {
  const CapturedPhotoPreview({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last photo',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 3 / 2,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}
