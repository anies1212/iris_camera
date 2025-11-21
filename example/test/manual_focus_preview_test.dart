import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_camera/iris_camera.dart';
import 'package:iris_camera_example/widgets/manual_focus_preview_section.dart';

void main() {
  testWidgets('IrisCameraPreview normalizes tap coordinates',
      (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      Offset? received;
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 320,
            height: 240,
            child: ManualFocusPreviewSection(
              title: 'Preview',
              focusEnabled: true,
              onTap: _TestTapRecorder.record,
            ),
          ),
        ),
      );
      await tester.pump();

      final gestureFinder = find.descendant(
        of: find.byType(IrisCameraPreview),
        matching: find.byType(GestureDetector),
      );
      expect(gestureFinder, findsOneWidget);
      final rect = tester.getRect(gestureFinder);
      final tapPoint = Offset(
        rect.left + rect.width * 0.3,
        rect.top + rect.height * 0.7,
      );

      _TestTapRecorder.last = null;
      await tester.tapAt(tapPoint);
      await tester.pumpAndSettle();

      received = _TestTapRecorder.last;
      expect(received, isNotNull);
      final Offset point = received!;
      expect(point.dx, closeTo(0.3, 0.05));
      expect(point.dy, closeTo(0.7, 0.05));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

class _TestTapRecorder {
  static Offset? last;

  static void record(Offset point) {
    last = point;
  }
}
