import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iris_camera/iris_camera.dart';

import '../widgets/camera_preview_surface.dart';
import '../widgets/camera_top_bar.dart';
import '../widgets/control_card.dart';
import '../widgets/lens_pagination.dart';
import '../widgets/lens_empty_state.dart';
import '../widgets/shutter_controls.dart';

class CameraExperiencePage extends StatefulWidget {
  const CameraExperiencePage({super.key});

  @override
  State<CameraExperiencePage> createState() => _CameraExperiencePageState();
}

class _CameraExperiencePageState extends State<CameraExperiencePage> {
  final IrisCamera _camera = IrisCamera();
  final PageController _lensPageController =
      PageController(viewportFraction: 0.32);
  final FocusIndicatorController _focusIndicatorController =
      FocusIndicatorController();

  bool _isLoading = true;
  bool _isSwitchingLens = false;
  bool _isCapturing = false;
  List<CameraLensDescriptor> _lenses = const [];
  String? _selectedLensId;
  Uint8List? _lastPhoto;
  PhotoFlashMode _flashMode = PhotoFlashMode.auto;
  double _zoomFactor = 1.0;
  double _manualFocusPosition = 0.5;
  bool _useManualCaptureSettings = false;
  double _exposureDurationMs = 20;
  double _isoValue = 200;
  double? _whiteBalanceTemperature;
  double? _whiteBalanceTint;
  String? _platformVersion;

  CameraLensDescriptor? _lensById(String? id) {
    for (final lens in _lenses) {
      if (lens.id == id) {
        return lens;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadLenses();
    _loadPlatformVersion();
  }

  @override
  void dispose() {
    _lensPageController.dispose();
    _focusIndicatorController.dispose();
    super.dispose();
  }

  Future<void> _loadLenses() async {
    setState(() => _isLoading = true);
    final lenses = await _camera.listAvailableLenses();
    final firstLens = lenses.isNotEmpty ? lenses.first : null;

    setState(() {
      _lenses = lenses;
      _selectedLensId = firstLens?.id;
    });

    if (firstLens != null) {
      await _camera.switchLens(firstLens.category);
      _lensPageController.jumpToPage(0);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPlatformVersion() async {
    final version = await _camera.getPlatformVersion();
    if (!mounted) return;
    setState(() => _platformVersion = version);
  }

  Future<void> _switchLensByIndex(int index) async {
    if (index < 0 || index >= _lenses.length) {
      return;
    }
    final lens = _lenses[index];
    if (lens.id == _selectedLensId && !_isSwitchingLens) {
      return;
    }

    setState(() {
      _isSwitchingLens = true;
      _selectedLensId = lens.id;
    });

    final descriptor = await _camera.switchLens(lens.category);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedLensId = descriptor.id;
      _isSwitchingLens = false;
    });
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || _selectedLensId == null) {
      return;
    }
    setState(() => _isCapturing = true);
    try {
      final bytes = await _camera.capturePhoto(
        options: PhotoCaptureOptions(
          flashMode: _flashMode,
          exposureDuration: _useManualCaptureSettings
              ? Duration(milliseconds: _exposureDurationMs.round())
              : null,
          iso: _useManualCaptureSettings ? _isoValue : null,
        ),
      );
      if (!mounted) return;
      setState(() => _lastPhoto = bytes);
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _handleTapFocus(Offset point) async {
    await _camera.setFocus(point: point);
  }

  Future<void> _setZoom(double value) async {
    setState(() => _zoomFactor = value);
    await _camera.setZoom(value);
  }

  Future<void> _setManualFocusPosition(double value) async {
    setState(() => _manualFocusPosition = value);
    final lens = _lensById(_selectedLensId);
    if (lens?.supportsFocus != true) {
      return;
    }
    await _camera.setFocus(lensPosition: value);
  }

  void _setFlash(PhotoFlashMode mode) {
    setState(() => _flashMode = mode);
  }

  Future<void> _applyWhiteBalance({
    double? temperature,
    double? tint,
    bool reset = false,
  }) async {
    final nextTemperature =
        reset ? null : (temperature ?? _whiteBalanceTemperature ?? 5000);
    final nextTint = reset ? null : (tint ?? _whiteBalanceTint ?? 0);
    setState(() {
      _whiteBalanceTemperature = nextTemperature;
      _whiteBalanceTint = nextTint;
    });
    await _camera.setWhiteBalance(
      temperature: nextTemperature,
      tint: nextTint,
    );
  }

  void _toggleManualCaptureSettings(bool value) {
    setState(() => _useManualCaptureSettings = value);
  }

  void _previewWhiteBalanceTemperature(double value) {
    setState(() => _whiteBalanceTemperature = value);
  }

  void _previewWhiteBalanceTint(double value) {
    setState(() => _whiteBalanceTint = value);
  }

  void _previewManualFocus(double value) {
    setState(() => _manualFocusPosition = value);
  }

  void _updateIsoValue(double value) {
    setState(() => _isoValue = value);
  }

  void _updateExposureValue(double value) {
    setState(() => _exposureDurationMs = value);
  }

  @override
  Widget build(BuildContext context) {
    final lens = _lensById(_selectedLensId);
    final supportsFocus = lens?.supportsFocus ?? false;
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : _lenses.isEmpty
                  ? LensEmptyState(onRetry: _loadLenses)
                  : Column(
                      children: [
                        CameraTopBar(
                          lensName: lens?.name ?? 'Lens',
                          flashMode: _flashMode,
                          onFlashChanged: _setFlash,
                          isSwitching: _isSwitchingLens,
                          platformVersion: _platformVersion,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: CameraPreviewSurface(
                              onTapFocus: _handleTapFocus,
                              zoomFactor: _zoomFactor,
                              onZoomChanged: _setZoom,
                              isSwitchingLens: _isSwitchingLens,
                              focusIndicatorController:
                                  _focusIndicatorController,
                              supportsFocus: lens?.supportsFocus ?? false,
                              lensName: lens?.category.name ?? '',
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Column(
                            children: [
                              ControlCard(
                                title: 'White balance',
                                trailing: TextButton(
                                  onPressed: (_whiteBalanceTemperature !=
                                              null ||
                                          _whiteBalanceTint != null)
                                      ? () => _applyWhiteBalance(reset: true)
                                      : null,
                                  child: const Text('Auto'),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LabeledSlider(
                                      label:
                                          'Temperature ${(_whiteBalanceTemperature ?? 5000).round()}K',
                                      value: (_whiteBalanceTemperature ?? 5000)
                                          .clamp(2500, 7500),
                                      min: 2500,
                                      max: 7500,
                                      divisions: 25,
                                      onChanged: (value) {
                                        _previewWhiteBalanceTemperature(value);
                                      },
                                      onChangeEnd: (value) =>
                                          _applyWhiteBalance(
                                              temperature: value),
                                    ),
                                    const SizedBox(height: 8),
                                    LabeledSlider(
                                      label:
                                          'Tint ${(_whiteBalanceTint ?? 0).toStringAsFixed(0)}',
                                      value: (_whiteBalanceTint ?? 0)
                                          .clamp(-150, 150),
                                      min: -150,
                                      max: 150,
                                      divisions: 30,
                                      onChanged: (value) {
                                        _previewWhiteBalanceTint(value);
                                      },
                                      onChangeEnd: (value) =>
                                          _applyWhiteBalance(tint: value),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              ControlCard(
                                title: 'Manual focus',
                                trailing: supportsFocus
                                    ? Text(
                                        _manualFocusPosition.toStringAsFixed(2),
                                        style: const TextStyle(
                                            color: Colors.white70),
                                      )
                                    : const Text(
                                        'Not supported',
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                child: LabeledSlider(
                                  label: supportsFocus
                                      ? 'Lens position'
                                      : 'Lens does not support focus',
                                  value: _manualFocusPosition.clamp(0.0, 1.0),
                                  min: 0.0,
                                  max: 1.0,
                                  divisions: 50,
                                  onChanged: supportsFocus
                                      ? (value) => _previewManualFocus(value)
                                      : null,
                                  onChangeEnd: supportsFocus
                                      ? _setManualFocusPosition
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ControlCard(
                                title: 'Capture tuning',
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Manual'),
                                    Switch.adaptive(
                                      value: _useManualCaptureSettings,
                                      onChanged: _toggleManualCaptureSettings,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    LabeledSlider(
                                      label:
                                          'Exposure ${_exposureDurationMs.toStringAsFixed(0)} ms',
                                      value: _exposureDurationMs.clamp(1, 500),
                                      min: 1,
                                      max: 500,
                                      divisions: 50,
                                      onChanged: _useManualCaptureSettings
                                          ? (value) =>
                                              _updateExposureValue(value)
                                          : null,
                                      onChangeEnd: _useManualCaptureSettings
                                          ? (value) =>
                                              _updateExposureValue(value)
                                          : null,
                                    ),
                                    const SizedBox(height: 8),
                                    LabeledSlider(
                                      label:
                                          'ISO ${_isoValue.toStringAsFixed(0)}',
                                      value: _isoValue.clamp(50, 800),
                                      min: 50,
                                      max: 800,
                                      divisions: 30,
                                      onChanged: _useManualCaptureSettings
                                          ? (value) => _updateIsoValue(value)
                                          : null,
                                      onChangeEnd: _useManualCaptureSettings
                                          ? (value) => _updateIsoValue(value)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        LensPagination(
                          controller: _lensPageController,
                          lenses: _lenses,
                          selectedLensId: _selectedLensId,
                          onPageChanged: (index) {
                            _switchLensByIndex(index);
                          },
                        ),
                        const SizedBox(height: 8),
                        ShutterControls(
                          isCapturing: _isCapturing,
                          lastPhoto: _lastPhoto,
                          onShutter: _capturePhoto,
                          onReload: _loadLenses,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
        ),
      ),
    );
  }
}
