import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'captured_photo_thumbnail.dart';

class ShutterControls extends StatelessWidget {
  const ShutterControls({
    super.key,
    required this.isCapturing,
    required this.lastPhoto,
    required this.onShutter,
    required this.onReload,
  });

  final bool isCapturing;
  final Uint8List? lastPhoto;
  final VoidCallback onShutter;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CapturedPhotoThumbnail(bytes: lastPhoto),
          const Spacer(),
          ShutterButton(
            isCapturing: isCapturing,
            onPressed: onShutter,
          ),
          const Spacer(),
          IconButton(
            onPressed: isCapturing ? null : onReload,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class ShutterButton extends StatelessWidget {
  const ShutterButton({
    super.key,
    required this.isCapturing,
    required this.onPressed,
  });

  final bool isCapturing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCapturing ? null : onPressed,
      child: Container(
        width: 84,
        height: 84,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isCapturing ? Colors.redAccent : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
