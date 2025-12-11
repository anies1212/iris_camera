import 'package:flutter/material.dart';
import 'package:iris_camera/iris_camera.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final IrisCamera _camera = IrisCamera();
  bool _isInitialized = false;
  double _zoomFactor = 1.0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    // List available camera lenses
    final lenses = await _camera.listAvailableLenses();

    // Switch to the first available lens (usually back camera)
    if (lenses.isNotEmpty) {
      await _camera.switchLens(lenses.first.category);
    }

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _capturePhoto() async {
    await _camera.capturePhoto(
      options: const PhotoCaptureOptions(flashMode: PhotoFlashMode.auto),
    );
  }

  Future<void> _setZoom(double factor) async {
    setState(() => _zoomFactor = factor);
    await _camera.setZoom(factor);
  }

  @override
  void dispose() {
    _camera.disposeSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Camera preview - uses platform view internally
          const Positioned.fill(
            child: IrisCameraPreview(),
          ),
          // Zoom slider
          Positioned(
            bottom: 100,
            left: 32,
            right: 32,
            child: Slider(
              value: _zoomFactor,
              min: 1.0,
              max: 5.0,
              onChanged: _setZoom,
            ),
          ),
          // Capture button
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _capturePhoto,
                child: const Icon(Icons.camera),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
