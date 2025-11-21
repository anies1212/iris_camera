import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iris_camera/iris_camera.dart';

import 'widgets/lens_empty_state.dart';
import 'widgets/manual_focus_preview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = IrisCamera();

  bool _isLoading = true;
  List<CameraLensDescriptor> _lenses = const <CameraLensDescriptor>[];
  String? _selectedLensId;
  Uint8List? _lastPhotoBytes;
  bool _isCapturingPhoto = false;
  PhotoFlashMode _flashMode = PhotoFlashMode.auto;
  double? _selectedExposureSeconds;
  double? _selectedIso;
  double _manualLensPosition = 0.5;
  double _zoomFactor = 1.0;
  double _whiteBalanceTemperature = 5000;
  double _whiteBalanceTint = 0;
  bool _autoWhiteBalance = true;

  @override
  void initState() {
    super.initState();
    _loadLenses();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadLenses() async {
    setState(() {
      _isLoading = true;
    });
    final lenses = await _plugin.listAvailableLenses();
    final fallbackId = lenses.isNotEmpty ? lenses.first.id : null;
    final resolvedId = _selectedLensId != null &&
            lenses.any((lens) => lens.id == _selectedLensId)
        ? _selectedLensId
        : fallbackId;
    final resolvedLens = _lensById(lenses, resolvedId);

    if (!mounted) return;
    setState(() {
      _lenses = lenses;
      _selectedLensId = resolvedId;
      _isLoading = false;
    });

    if (resolvedLens != null) {
      await _plugin.switchLens(resolvedLens.category);
    }
  }

  Future<void> _switchLens(CameraLensDescriptor lens) async {
    if (lens.id == _selectedLensId) {
      return;
    }
    final descriptor = await _plugin.switchLens(lens.category);
    if (!mounted) return;
    setState(() {
      _selectedLensId = descriptor.id;
    });
  }

  Future<void> _capturePhoto() async {
    if (_isCapturingPhoto) {
      return;
    }
    setState(() {
      _isCapturingPhoto = true;
    });
    try {
      final options = PhotoCaptureOptions(
        flashMode: _flashMode,
        exposureDuration: _selectedExposureSeconds != null
            ? Duration(
                microseconds: (_selectedExposureSeconds! * 1000000).round(),
              )
            : null,
        iso: _selectedIso,
      );
      final bytes = await _plugin.capturePhoto(options: options);
      if (!mounted) return;
      setState(() {
        _lastPhotoBytes = bytes;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCapturingPhoto = false;
        });
      }
    }
  }

  Future<void> _focusAtPoint(Offset normalized) async {
    final lens = _lensById(_lenses, _selectedLensId);
    if (lens?.supportsFocus != true) return;
    try {
      await _plugin.setFocus(point: normalized);
    } on CameraLensSwitcherException catch (error) {
      if (error.code != 'focus_not_supported') {
        rethrow;
      }
    }
  }

  Future<void> _setManualLensPosition(double value) async {
    final lens = _lensById(_lenses, _selectedLensId);
    if (lens?.supportsFocus != true) return;
    setState(() {
      _manualLensPosition = value;
    });
    try {
      await _plugin.setFocus(lensPosition: value);
    } on CameraLensSwitcherException catch (error) {
      if (error.code != 'focus_not_supported') {
        rethrow;
      }
    }
  }

  Future<void> _setZoom(double value) async {
    setState(() {
      _zoomFactor = value;
    });
    await _plugin.setZoom(value);
  }

  Future<void> _setWhiteBalance({
    double? temperature,
    double? tint,
    bool auto = false,
  }) async {
    if (auto) {
      setState(() {
        _autoWhiteBalance = true;
      });
      await _plugin.setWhiteBalance();
      return;
    }
    setState(() {
      _autoWhiteBalance = false;
      if (temperature != null) {
        _whiteBalanceTemperature = temperature;
      }
      if (tint != null) {
        _whiteBalanceTint = tint;
      }
    });
    await _plugin.setWhiteBalance(
      temperature: _whiteBalanceTemperature,
      tint: _whiteBalanceTint,
    );
  }

  CameraLensDescriptor? _lensById(
    List<CameraLensDescriptor> lenses,
    String? id,
  ) {
    if (id == null) {
      return null;
    }
    for (final lens in lenses) {
      if (lens.id == id) {
        return lens;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('iOS Camera Lens Switcher')),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _lenses.isEmpty
                  ? LensEmptyState(onRetry: _loadLenses)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ManualFocusPreview(
                        selectedLens: _selectedLensId != null
                            ? _lensById(_lenses, _selectedLensId) ??
                                _lenses.first
                            : _lenses.first,
                        lenses: _lenses,
                        onLensSelected: _switchLens,
                        onCaptureRequested: _capturePhoto,
                        isCapturing: _isCapturingPhoto,
                        lastPhotoBytes: _lastPhotoBytes,
                        flashMode: _flashMode,
                        onFlashModeChanged: (mode) {
                          setState(() => _flashMode = mode);
                        },
                        exposureSeconds: _selectedExposureSeconds,
                        onExposureChanged: (seconds) {
                          setState(() => _selectedExposureSeconds = seconds);
                        },
                        isoValue: _selectedIso,
                        onIsoChanged: (iso) {
                          setState(() => _selectedIso = iso);
                        },
                        manualFocusPosition: _manualLensPosition,
                        onManualFocusChanged: (value) {
                          setState(() => _manualLensPosition = value);
                        },
                        onManualFocusChangeEnd: _setManualLensPosition,
                        onPreviewTap: _focusAtPoint,
                        zoomFactor: _zoomFactor,
                        onZoomChanged: _setZoom,
                        whiteBalanceTemperature: _whiteBalanceTemperature,
                        whiteBalanceTint: _whiteBalanceTint,
                        autoWhiteBalance: _autoWhiteBalance,
                        onWhiteBalanceChanged: _setWhiteBalance,
                      ),
                    ),
        ),
      ),
    );
  }
}
