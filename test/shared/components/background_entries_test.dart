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
  });

  testWidgets('no entry, nothing drawn', (tester) async {
    await pumpEntries(tester, entries: const []);

    expect(find.byType(Text), findsNothing);
    expect(find.byType(NewEntrySigil), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
