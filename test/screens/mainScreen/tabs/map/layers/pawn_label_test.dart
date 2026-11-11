import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/pawn_visuals.dart';
import 'package:klimmeck_guide/utils/prison_lines.dart';

void main() {
  Future<RenderParagraph> pumpLabel(WidgetTester tester, String text) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: PawnLabel.markerWidth,
            height: PawnLabel.markerHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: PawnLabel(text: text),
            ),
          ),
        ),
      ),
    );
    return tester.renderObject<RenderParagraph>(find.byType(RichText));
  }

  testWidgets('the longest prison line is shown whole, unit included', (
    tester,
  ) async {
    final line = prisonMarkerLine(const Duration(hours: 9, minutes: 59));

    final paragraph = await pumpLabel(tester, line);

    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a short prison line keeps its unit too', (tester) async {
    final paragraph = await pumpLabel(
      tester,
      prisonMarkerLine(const Duration(minutes: 6)),
    );

    expect(paragraph.didExceedMaxLines, isFalse);
  });
}
