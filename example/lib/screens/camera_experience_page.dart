import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iris_camera/iris_camera.dart';

import '../widgets/camera_preview_surface.dart';
import '../widgets/camera_top_bar.dart';
import '../widgets/control_card.dart';
import '../widgets/exposure_focus_controls.dart';
import '../widgets/lens_empty_state.dart';
import '../widgets/lens_pagination.dart';
import '../widgets/session_controls.dart';
import '../widgets/status_strip.dart';
import '../widgets/video_controls.dart';

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
  bool _isRecording = false;
  bool _enableAudio = true;
  List<CameraLensDescriptor> _lenses = const [];
  String? _selectedLensId;
  PhotoFlashMode _flashMode = PhotoFlashMode.auto;
  double _zoomFactor = 1.0;
  double _manualFocusPosition = 0.5;
  bool _useManualCaptureSettings = false;
  double _exposureDurationMs = 20;
  double _isoValue = 200;
  double? _whiteBalanceTemperature;
  double? _whiteBalanceTint;
  String? _platformVersion;
  bool _torchEnabled = false;
  ExposureMode _exposureMode = ExposureMode.auto;
  FocusMode _focusMode = FocusMode.auto;
  double _evMin = -2;
  double _evMax = 2;
  double _evValue = 0;
  ResolutionPreset _preset = ResolutionPreset.high;
  double _minFps = 24;
  double _maxFps = 60;
  bool _isStreaming = false;
  int _frameCount = 0;
  String? _lastFrameInfo;
  CameraLifecycleState _state = CameraLifecycleState.disposed;
  DeviceOrientation _deviceOrientation = DeviceOrientation.unknown;
  VideoOrientation _videoOrientation = VideoOrientation.unknown;
  FocusExposureState _focusExposureState = FocusExposureState.unknown;
  String? _lastVideoPath;

  CameraLensDescriptor? _lensById(String? id) {
    if (id == null) return null;
    for (final lens in _lenses) {
      if (lens.id == id) return lens;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadLenses();
    _loadPlatformVersion();
    _listenStreams();
  }

  @override
  void dispose() {
    _lensPageController.dispose();
    _focusIndicatorController.dispose();
    _camera.disposeSession();
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
      _jumpToLensPage(0);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _jumpToLensPage(int index) {
    if (_lensPageController.hasClients) {
      _lensPageController.jumpToPage(index);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lensPageController.hasClients) {
        _lensPageController.jumpToPage(index);
      }
    });
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
      await _camera.capturePhoto(
        options: PhotoCaptureOptions(
          flashMode: _flashMode,
          exposureDuration: _useManualCaptureSettings
              ? Duration(milliseconds: _exposureDurationMs.round())
              : null,
          iso: _useManualCaptureSettings ? _isoValue : null,
        ),
      );
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
    if (lens?.supportsFocus != true || Platform.isAndroid) {
      return;
    }
    await _camera.setFocus(lensPosition: value);
  }

  void _setFlash(PhotoFlashMode mode) {
    setState(() => _flashMode = mode);
  }

  Future<void> _toggleTorch() async {
    _torchEnabled = !_torchEnabled;
    setState(() {});
    await _camera.setTorch(_torchEnabled);
  }

  Future<void> _initialize() async {
    await _camera.initialize();
    await _loadExposureBounds();
  }

  Future<void> _loadExposureBounds() async {
    final min = await _camera.getMinExposureOffset();
    final max = await _camera.getMaxExposureOffset();
    final current = await _camera.getExposureOffset();
    if (!mounted) return;
    setState(() {
      _evMin = min;
      _evMax = max;
      _evValue = current;
    });
  }

  Future<void> _setEv(double value) async {
    setState(() => _evValue = value);
    final applied = await _camera.setExposureOffset(value);
    if (!mounted) return;
    setState(() => _evValue = applied);
  }

  Future<void> _setExposureMode(ExposureMode mode) async {
    await _camera.setExposureMode(mode);
    final current = await _camera.getExposureMode();
    if (!mounted) return;
    setState(() => _exposureMode = current);
  }

  Future<void> _setFocusMode(FocusMode mode) async {
    await _camera.setFocusMode(mode);
    final current = await _camera.getFocusMode();
    if (!mounted) return;
    setState(() => _focusMode = current);
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

  Future<void> _startVideo() async {
    if (_isRecording) return;
    final path = await _camera.startVideoRecording(
      filePath: null,
      enableAudio: _enableAudio,
    );
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _lastVideoPath = path;
    });
  }

  Future<void> _stopVideo() async {
    if (!_isRecording) return;
    final path = await _camera.stopVideoRecording();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _lastVideoPath = path;
    });
  }

  Future<void> _toggleImageStream() async {
    if (_isStreaming) {
      await _camera.stopImageStream();
      setState(() {
        _isStreaming = false;
        _frameCount = 0;
        _lastFrameInfo = null;
      });
    } else {
      setState(() {
        _isStreaming = true;
        _frameCount = 0;
        _lastFrameInfo = null;
      });
      await _camera.startImageStream();
    }
  }

  void _listenStreams() {
    _camera.stateStream.listen((event) {
      if (!mounted) return;
      setState(() => _state = event.state);
    });
    _camera.orientationStream.listen((event) {
      if (!mounted) return;
      setState(() {
        _deviceOrientation = event.deviceOrientation;
        _videoOrientation = event.videoOrientation;
      });
    });
    _camera.focusExposureStateStream.listen((event) {
      if (!mounted) return;
      setState(() => _focusExposureState = event.state);
    });
    _camera.imageStream.listen((frame) {
      if (!_isStreaming || !mounted) return;
      setState(() {
        _frameCount += 1;
        _lastFrameInfo =
            '${frame.width}x${frame.height} stride ${frame.bytesPerRow}';
      });
    });
  }

  Future<void> _applyFrameRate() async {
    await _camera.setFrameRateRange(minFps: _minFps, maxFps: _maxFps);
  }

  Future<void> _setResolutionPreset(ResolutionPreset preset) async {
    setState(() => _preset = preset);
    await _camera.setResolutionPreset(preset);
  }

  @override
  Widget build(BuildContext context) {
    final lens = _lensById(_selectedLensId);
    final supportsLensPosition =
        !Platform.isAndroid && (lens?.supportsFocus ?? false);
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: lens == null
                        ? LensEmptyState(onRetry: _loadLenses)
                        : CameraPreviewSurface(
                            onTapFocus: _handleTapFocus,
                            zoomFactor: _zoomFactor,
                            onZoomChanged: _setZoom,
                            isSwitchingLens: _isSwitchingLens,
                            lensName: lens.name,
                            focusIndicatorController: _focusIndicatorController,
                            supportsFocus: lens.supportsFocus,
                          ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusStrip(
                            cameraState: _state.name,
                            orientation:
                                '${_deviceOrientation.name}/${_videoOrientation.name}',
                            focusExposureState: _focusExposureState.name,
                            isStreaming: _isStreaming,
                            isRecording: _isRecording,
                            lastVideoPath: _lastVideoPath,
                            imageStats:
                                '${_frameCount}f${_lastFrameInfo != null ? ' ($_lastFrameInfo)' : ''}',
                          ),
                          const SizedBox(height: 12),
                          CameraTopBar(
                            lensName:
                                _lensById(_selectedLensId)?.name ?? 'Lens',
                            flashMode: _flashMode,
                            onFlashChanged: _setFlash,
                            isSwitching: _isSwitchingLens,
                            platformVersion: _platformVersion,
                            onCaptureTap: _capturePhoto,
                          ),
                          const SizedBox(height: 12),
                          ControlCard(
                            title: 'Lenses',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isSwitchingLens)
                                  const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                IconButton(
                                  onPressed:
                                      _isSwitchingLens ? null : _loadLenses,
                                  icon: const Icon(Icons.refresh,
                                      color: Colors.white70),
                                  tooltip: 'Reload lenses',
                                ),
                              ],
                            ),
                            child: _lenses.isEmpty
                                ? const SizedBox.shrink()
                                : LensPagination(
                                    controller: _lensPageController,
                                    lenses: _lenses,
                                    selectedLensId: _selectedLensId,
                                    onPageChanged: _switchLensByIndex,
                                    onLensTap: (_) => _capturePhoto(),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          ExposureFocusControls(
                            zoom: _zoomFactor,
                            onZoomChanged: _setZoom,
                            focusPosition: _manualFocusPosition,
                            onFocusPositionChanged: _setManualFocusPosition,
                            supportsLensPosition: supportsLensPosition,
                            exposureMode: _exposureMode,
                            onExposureModeChanged: _setExposureMode,
                            focusMode: _focusMode,
                            onFocusModeChanged: _setFocusMode,
                            evMin: _evMin,
                            evMax: _evMax,
                            evValue: _evValue,
                            onEvChanged: _setEv,
                            wbTemperature: _whiteBalanceTemperature,
                            wbTint: _whiteBalanceTint,
                            onWhiteBalanceChanged: (temp, tint) =>
                                _applyWhiteBalance(
                                    temperature: temp, tint: tint),
                            onResetWhiteBalance: () =>
                                _applyWhiteBalance(reset: true),
                          ),
                          const SizedBox(height: 12),
                          SessionControls(
                            torchEnabled: _torchEnabled,
                            onToggleTorch: _toggleTorch,
                            onInitialize: _initialize,
                            onPause: _camera.pauseSession,
                            onResume: _camera.resumeSession,
                            onDispose: _camera.disposeSession,
                            onResolutionChanged: _setResolutionPreset,
                            currentPreset: _preset,
                            minFps: _minFps,
                            maxFps: _maxFps,
                            onMinFpsChanged: (v) => setState(() => _minFps = v),
                            onMaxFpsChanged: (v) => setState(() => _maxFps = v),
                            onApplyFrameRate: _applyFrameRate,
                            isStreaming: _isStreaming,
                            onToggleImageStream: _toggleImageStream,
                          ),
                          const SizedBox(height: 12),
                          VideoControls(
                            isRecording: _isRecording,
                            enableAudio: _enableAudio,
                            lastVideoPath: _lastVideoPath,
                            onToggleAudio: (v) =>
                                setState(() => _enableAudio = v),
                            onStart: _startVideo,
                            onStop: _stopVideo,
                          ),
                          const SizedBox(height: 12),
                          ControlCard(
                            title: 'Manual photo settings',
                            child: Column(
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Flash auto'),
                                      selected:
                                          _flashMode == PhotoFlashMode.auto,
                                      onSelected: (_) =>
                                          _setFlash(PhotoFlashMode.auto),
                                    ),
                                    ChoiceChip(
                                      label: const Text('On'),
                                      selected: _flashMode == PhotoFlashMode.on,
                                      onSelected: (_) =>
                                          _setFlash(PhotoFlashMode.on),
                                    ),
                                    ChoiceChip(
                                      label: const Text('Off'),
                                      selected:
                                          _flashMode == PhotoFlashMode.off,
                                      onSelected: (_) =>
                                          _setFlash(PhotoFlashMode.off),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Switch(
                                          value: _useManualCaptureSettings,
                                          onChanged:
                                              _toggleManualCaptureSettings,
                                        ),
                                        const Text('Manual'),
                                      ],
                                    ),
                                  ],
                                ),
                                LabeledSlider(
                                  label:
                                      'Exposure (${_exposureDurationMs.toStringAsFixed(0)} ms)',
                                  value: _exposureDurationMs,
                                  min: 1,
                                  max: 200,
                                  divisions: 199,
                                  onChanged: _useManualCaptureSettings
                                      ? _updateExposureValue
                                      : null,
                                ),
                                LabeledSlider(
                                  label:
                                      'ISO (${_isoValue.toStringAsFixed(0)})',
                                  value: _isoValue,
                                  min: 50,
                                  max: 1600,
                                  divisions: 155,
                                  onChanged: _useManualCaptureSettings
                                      ? _updateIsoValue
                                      : null,
                                ),
                                LabeledSlider(
                                  label:
                                      'Preview WB temp (${(_whiteBalanceTemperature ?? 5000).round()}K)',
                                  value: (_whiteBalanceTemperature ?? 5000)
                                      .clamp(2000, 8000),
                                  min: 2000,
                                  max: 8000,
                                  divisions: 60,
                                  onChanged: (value) =>
                                      _previewWhiteBalanceTemperature(value),
                                  onChangeEnd: (value) =>
                                      _applyWhiteBalance(temperature: value),
                                ),
                                LabeledSlider(
                                  label:
                                      'Preview WB tint (${(_whiteBalanceTint ?? 0).toStringAsFixed(0)})',
                                  value:
                                      (_whiteBalanceTint ?? 0).clamp(-50, 50),
                                  min: -50,
                                  max: 50,
                                  divisions: 100,
                                  onChanged: (value) =>
                                      _previewWhiteBalanceTint(value),
                                  onChangeEnd: (value) =>
                                      _applyWhiteBalance(tint: value),
                                ),
                                LabeledSlider(
                                  label:
                                      'Preview manual focus (${_manualFocusPosition.toStringAsFixed(2)})',
                                  value: _manualFocusPosition,
                                  min: 0,
                                  max: 1,
                                  divisions: 100,
                                  onChanged: _previewManualFocus,
                                  onChangeEnd: _setManualFocusPosition,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
