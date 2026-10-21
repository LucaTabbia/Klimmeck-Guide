import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/shared/components/tear/tearable_paper.dart';

import '../../../helpers/haptic_recorder.dart';
import '../../../helpers/test_app.dart';

const _selection = 'HapticFeedbackType.selectionClick';
const _medium = 'HapticFeedbackType.mediumImpact';
const _light = 'HapticFeedbackType.lightImpact';

Widget _harness({
  required VoidCallback onTorn,
  bool canTear = true,
  bool isEnabled = true,
}) => buildTestApp(
  home: Center(
    child: SizedBox(
      width: 400,
      height: 300,
      child: TearablePaper(
        onTorn: onTorn,
        canTear: canTear,
        isEnabled: isEnabled,
        child: const ColoredBox(color: Color(0xFF000000)),
      ),
    ),
  ),
);

void main() {
  final paper = find.byType(TearablePaper);

  testWidgets('renders the child once at rest', (tester) async {
    await tester.pumpWidget(_harness(onTorn: () {}));
    expect(find.byType(ClipPath), findsNothing);
  });

  testWidgets('a full drag tears, haptics fire, halves stay apart', (
    tester,
  ) async {
    var torn = 0;
    final haptics = recordHaptics(tester);
    await tester.pumpWidget(_harness(onTorn: () => torn++));

    await tester.drag(paper, const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(torn, 1);
    expect(haptics, [_selection, _medium]);
    expect(find.byType(ClipPath), findsNWidgets(2));
    expect(tester.state<TearablePaperState>(paper).isTorn, isTrue);

    await tester.drag(paper, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(torn, 1);
  });

  testWidgets('recompose restores the paper and allows a new tear', (
    tester,
  ) async {
    var torn = 0;
    recordHaptics(tester);
    await tester.pumpWidget(_harness(onTorn: () => torn++));
    await tester.drag(paper, const Offset(-300, 0));
    await tester.pumpAndSettle();

    tester.state<TearablePaperState>(paper).recompose();
    await tester.pumpAndSettle();
    expect(find.byType(ClipPath), findsNothing);
    expect(tester.state<TearablePaperState>(paper).isTorn, isFalse);

    await tester.drag(paper, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(torn, 2);
  });

  testWidgets('a short slow drag springs back', (tester) async {
    var torn = 0;
    final haptics = recordHaptics(tester);
    await tester.pumpWidget(_harness(onTorn: () => torn++));

    final gesture = await tester.startGesture(tester.getCenter(paper));
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(-10, 0));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(torn, 0);
    expect(haptics, isEmpty);
    expect(find.byType(ClipPath), findsNothing);
  });

  testWidgets('a fast left fling tears', (tester) async {
    var torn = 0;
    recordHaptics(tester);
    await tester.pumpWidget(_harness(onTorn: () => torn++));

    await tester.fling(paper, const Offset(-120, 0), 1500);
    await tester.pumpAndSettle();

    expect(torn, 1);
  });

  testWidgets('a right drag is ignored', (tester) async {
    var torn = 0;
    final haptics = recordHaptics(tester);
    await tester.pumpWidget(_harness(onTorn: () => torn++));

    await tester.drag(paper, const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(torn, 0);
    expect(haptics, isEmpty);
  });

  testWidgets('canTear false resists with a light haptic', (tester) async {
    var torn = 0;
    final haptics = recordHaptics(tester);
    await tester.pumpWidget(_harness(onTorn: () => torn++, canTear: false));

    await tester.drag(paper, const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(torn, 0);
    expect(haptics, [_light]);
    expect(find.byType(ClipPath), findsNothing);
  });

  testWidgets('isEnabled false ignores drags', (tester) async {
    var torn = 0;
    final haptics = recordHaptics(tester);
    await tester.pumpWidget(_harness(onTorn: () => torn++, isEnabled: false));

    await tester.drag(paper, const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(torn, 0);
    expect(haptics, isEmpty);
  });

  testWidgets('a vertical drag still scrolls the enclosing view', (
    tester,
  ) async {
    var torn = 0;
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      buildTestApp(
        home: SingleChildScrollView(
          controller: controller,
          child: TearablePaper(
            onTorn: () => torn++,
            child: const SizedBox(height: 2000),
          ),
        ),
      ),
    );

    await tester.drag(paper, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(0));
    expect(torn, 0);
  });
}
