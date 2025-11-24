import 'package:flutter/material.dart';
import 'package:iris_camera/iris_camera.dart';

class LensPagination extends StatelessWidget {
  const LensPagination({
    super.key,
    required this.controller,
    required this.lenses,
    required this.selectedLensId,
    required this.onPageChanged,
  });

  final PageController controller;
  final List<CameraLensDescriptor> lenses;
  final String? selectedLensId;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (lenses.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 92,
      child: PageView.builder(
        controller: controller,
        itemCount: lenses.length,
        onPageChanged: onPageChanged,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final lens = lenses[index];
          final isActive = lens.id == selectedLensId;
          return AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isActive ? 1.0 : 0.9,
            child: Center(
              child: LensCard(
                label: _lensLabel(lens),
                subtitle: lens.category.name,
                isActive: isActive,
              ),
            ),
          );
        },
      ),
    );
  }

  String _lensLabel(CameraLensDescriptor lens) {
    return switch (lens.category) {
      CameraLensCategory.ultraWide => '0.5×',
      CameraLensCategory.wide => '1×',
      CameraLensCategory.telephoto => '3×',
      CameraLensCategory.dual => 'Dual',
      CameraLensCategory.triple => 'Triple',
      CameraLensCategory.continuity => 'Continuity',
      CameraLensCategory.trueDepth => 'TrueDepth',
      CameraLensCategory.external => 'External',
      CameraLensCategory.unknown => 'Lens',
    };
  }
}

class LensCard extends StatelessWidget {
  const LensCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.isActive,
  });

  final String label;
  final String subtitle;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive ? Colors.white : Colors.white10;
    final background =
        isActive ? Colors.white12 : Colors.white.withValues(alpha: 0.06);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: background,
        border: Border.all(color: borderColor, width: isActive ? 2 : 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
