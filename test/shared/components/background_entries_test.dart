import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/background_entries.dart';
import 'package:klimmeck_guide/shared/components/new_entry_sigil.dart';

import '../../helpers/svg_cache_seed.dart';
import '../../helpers/test_app.dart';

const String _birth = 'Nata a Drustea.';
const String _deed = 'Ha salvato Bosa dai predoni.';

void main() {
  Future<void> pumpEntries(
    WidgetTester tester, {
    required List<String> entries,
    Set<String> newEntries = const {},
  }) async {
    seedSvgCache([CloudinaryAssets.newEntrySigil]);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: BackgroundEntries(entries: entries, newEntries: newEntries),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows every entry in the served order', (tester) async {
    await pumpEntries(tester, entries: const [_birth, _deed]);

    expect(
      tester.getTopLeft(find.text(_birth)).dy,
      lessThan(tester.getTopLeft(find.text(_deed)).dy),
    );
    expect(find.byType(NewEntrySigil), findsNothing);
  });

  testWidgets(
    'a short centred line parts each entry from the next, none after the last',
    (tester) async {
      await pumpEntries(tester, entries: const [_birth, _deed, 'Terza voce.']);

      final separators = find.byKey(BackgroundEntries.separatorKey);
      expect(separators, findsNWidgets(2));
      final page = tester.getRect(find.byType(BackgroundEntries));
      final line = tester.getRect(separators.first);
      expect(line.width, lessThan(page.width / 2));
      expect(line.center.dx, closeTo(page.center.dx, 1));
      expect(line.top, greaterThan(tester.getBottomLeft(find.text(_birth)).dy));
      expect(line.bottom, lessThan(tester.getTopLeft(find.text(_deed)).dy));
    },
  );

  testWidgets('a single entry has no separator', (tester) async {
    await pumpEntries(tester, entries: const [_birth]);

    expect(find.byKey(BackgroundEntries.separatorKey), findsNothing);
  });

  testWidgets('only a new entry carries the sigil', (tester) async {
    await pumpEntries(
      tester,
      entries: const [_birth, _deed],
      newEntries: const {_deed},
    );

    final sigil = tester.getRect(find.byType(NewEntrySigil));
    expect(find.byType(NewEntrySigil), findsOneWidget);
    expect(sigil.top, closeTo(tester.getTopLeft(find.text(_deed)).dy, 1));
    expect(sigil.top, greaterThan(tester.getTopLeft(find.text(_birth)).dy));
    expect(
      sigil.left,
      greaterThanOrEqualTo(tester.getTopRight(find.text(_deed)).dx),
    );
    expect(
      tester.getTopLeft(find.text(_deed)).dx,
      tester.getTopLeft(find.text(_birth)).dx,
    );
  });

  testWidgets('no entry, nothing drawn', (tester) async {
    await pumpEntries(tester, entries: const []);

    expect(find.byType(Text), findsNothing);
    expect(find.byType(NewEntrySigil), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
