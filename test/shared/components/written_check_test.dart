import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/written_check.dart';
import 'package:klimmeck_guide/shared/components/written_ink.dart';

import '../../helpers/svg_cache_seed.dart';
import '../../helpers/test_app.dart';

const double _side = 100;

/// Parte della spunta che si vede, come rettangolo dentro il suo riquadro.
Rect? _visibleInk(WidgetTester tester) {
  final clip = find.byKey(WrittenInk.clipKey);
  if (clip.evaluate().isEmpty) return null;
  final clipper = tester.widget<ClipRect>(clip).clipper!;
  return clipper.getClip(const Size(_side, _side));
}

void main() {
  setUp(() => seedSvgCache([CloudinaryAssets.check]));

  Future<void> pump(WidgetTester tester, {required bool isShown}) async {
    await tester.pumpWidget(
      buildTestApp(
        home: Center(
          child: WrittenCheck(isShown: isShown, side: _side),
        ),
      ),
    );
  }

  testWidgets('a check already there shows whole, without writing it', (
    tester,
  ) async {
    await pump(tester, isShown: true);

    expect(_visibleInk(tester), const Rect.fromLTWH(0, 0, _side, _side));
  });

  testWidgets('a hidden check draws nothing', (tester) async {
    await pump(tester, isShown: false);

    expect(find.byType(CachedSvg), findsNothing);
  });

  testWidgets('a new check is written from left to right', (tester) async {
    await pump(tester, isShown: false);

    await pump(tester, isShown: true);
    await tester.pump(WrittenCheck.strokeDuration ~/ 2);
    final halfway = _visibleInk(tester)!;

    expect(halfway.left, 0);
    expect(halfway.width, greaterThan(0));
    expect(halfway.width, lessThan(_side));

    await tester.pumpAndSettle();
    expect(_visibleInk(tester), const Rect.fromLTWH(0, 0, _side, _side));
  });

  testWidgets('a removed check is wiped from left to right', (tester) async {
    await pump(tester, isShown: true);

    await pump(tester, isShown: false);
    await tester.pump(WrittenCheck.strokeDuration ~/ 2);
    final halfway = _visibleInk(tester)!;

    expect(halfway.right, _side);
    expect(halfway.left, greaterThan(0));
    expect(halfway.left, lessThan(_side));

    await tester.pumpAndSettle();
    expect(find.byType(CachedSvg), findsNothing);
  });
}
