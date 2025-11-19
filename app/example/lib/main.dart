import 'package:flutter/material.dart';
import 'package:ios_camera_lens_switcher/ios_camera_lens_switcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = IosCameraLensSwitcher();

  bool _isLoading = true;
  List<CameraLensDescriptor> _lenses = const <CameraLensDescriptor>[];
  String? _selectedLensId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLenses();
  }

  Future<void> _loadLenses() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final lenses = await _plugin.listAvailableLenses();
      final previousId = _selectedLensId;
      final fallbackId = lenses.isNotEmpty ? lenses.first.id : null;
      final resolvedId =
          previousId != null && lenses.any((lens) => lens.id == previousId)
          ? previousId
          : fallbackId;

      if (!mounted) return;
      setState(() {
        _lenses = lenses;
        _selectedLensId = resolvedId;
      });
    } on CameraLensSwitcherException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '${error.code}: ${error.message ?? 'Unknown error'}';
        _lenses = const <CameraLensDescriptor>[];
        _selectedLensId = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _switchLens(CameraLensDescriptor lens) async {
    if (lens.id == _selectedLensId) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      final descriptor = await _plugin.switchLens(lens.category);
      if (!mounted) return;
      setState(() {
        _selectedLensId = descriptor.id;
      });
    } on CameraLensSwitcherException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '${error.code}: ${error.message ?? 'Unknown error'}';
      });
    } finally {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('iOS Camera Lens Switcher')),
        body: SafeArea(
          child: Builder(
            builder: (context) {
              if (_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_lenses.isEmpty) {
                return _LensEmptyState(
                  message: _errorMessage,
                  onRetry: _loadLenses,
                );
              }
              final selectedLens = _selectedLensId != null
                  ? _lenses.firstWhere(
                      (lens) => lens.id == _selectedLensId,
                      orElse: () => _lenses.first,
                    )
                  : _lenses.first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage case final message?)
                    _LensErrorBanner(message: message),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Current lens: ${selectedLens.name} (${selectedLens.category.name})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _lenses.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final lens = _lenses[index];
                        final subtitle = _buildSubtitle(lens);
                        final isActive = lens.id == _selectedLensId;
                        return ListTile(
                          title: Text(lens.name),
                          subtitle: Text(subtitle),
                          trailing: _LensStatusIndicator(isActive: isActive),
                          selected: isActive,
                          onTap: isActive ? null : () => _switchLens(lens),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _buildSubtitle(CameraLensDescriptor lens) {
    final parts = <String>[lens.category.name, lens.position.name];
    final fieldOfView = lens.fieldOfView;
    if (fieldOfView != null) {
      parts.add('${fieldOfView.toStringAsFixed(1)}° FOV');
    }
    return parts.join(' • ');
  }
}

class _LensEmptyState extends StatelessWidget {
  const _LensEmptyState({required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message ?? 'No lenses detected. Check camera permissions.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _LensStatusIndicator extends StatelessWidget {
  const _LensStatusIndicator({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return isActive
        ? const Icon(Icons.check_circle, color: Colors.green)
        : const Icon(Icons.switch_camera_outlined);
  }
}

class _LensErrorBanner extends StatelessWidget {
  const _LensErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colorScheme.errorContainer,
      padding: const EdgeInsets.all(12),
      child: Text(
        message,
        style: TextStyle(color: colorScheme.onErrorContainer),
      ),
    );
  }
}
