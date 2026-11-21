import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/participant_story.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/shared/components/new_entry_sigil.dart';

import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

const String _aria = 'char-aria';
const String _birth = 'Nata a Drustea.';
const String _deed = 'Ha salvato Bosa dai predoni.';
const String _failureLine = 'Storia non leggibile';
const Duration _openingTime = Duration(milliseconds: 400);

const StoryReader _adventurer = StoryReader(
  characterId: _aria,
  name: 'Aria',
  title: TitleType.adventurer,
);

void main() {
  Future<void> pumpStory(
    WidgetTester tester, {
    StoryReader reader = _adventurer,
    required List<String>? entries,
    String pendingLine = ParticipantStory.readingLine,
  }) async {
    seedSvgCache([CloudinaryAssets.arrowDown]);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ParticipantStory(
              reader: reader,
              entries: entries,
              pendingLine: pendingLine,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  double openFactorOf(WidgetTester tester) => tester
      .widget<SizeTransition>(
        find.descendant(
          of: find.byKey(ParticipantStory.keyFor(_aria)),
          matching: find.byType(SizeTransition),
        ),
      )
      .sizeFactor
      .value;

  Future<void> openStory(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownHeader));
    await tester.pump();
    await tester.pump(_openingTime);
  }

  testWidgets('the header reads the name and the rank (D-03)', (tester) async {
    await pumpStory(tester, entries: const [_birth]);

    expect(find.text('Aria · ${TitleType.adventurer.label}'), findsOneWidget);
    expect(find.text('Aria · Avventuriero'), findsOneWidget);
  });

  testWidgets('the header reads the name alone while the rank is unknown', (
    tester,
  ) async {
    await pumpStory(
      tester,
      reader: const StoryReader(characterId: _aria, name: 'Aria'),
      entries: const [_birth],
    );

    expect(find.text('Aria'), findsOneWidget);
    expect(find.textContaining('·'), findsNothing);
  });

  testWidgets('the dropdown is closed at first and opens on a tap (D-03)', (
    tester,
  ) async {
    await pumpStory(tester, entries: const [_birth]);

    expect(find.byType(Dropdown), findsOneWidget);
    expect(openFactorOf(tester), 0);
    expect(find.text(_birth).hitTestable(), findsNothing);

    await openStory(tester);

    expect(openFactorOf(tester), 1);
    expect(find.text(_birth).hitTestable(), findsOneWidget);
  });

  testWidgets('the entries follow the served order, oldest first (D-03)', (
    tester,
  ) async {
    await pumpStory(tester, entries: const [_birth, _deed]);
    await openStory(tester);

    expect(
      tester.getTopLeft(find.text(_birth)).dy,
      lessThan(tester.getTopLeft(find.text(_deed)).dy),
    );
    expect(find.byType(NewEntrySigil), findsNothing);
  });

  testWidgets('an empty story reads the in-world line (D-03)', (tester) async {
    await pumpStory(tester, entries: const []);
    await openStory(tester);

    expect(
      find.text('Di questo avventuriero non si sa ancora nulla'),
      findsOneWidget,
    );
    expect(find.text(ParticipantStory.readingLine), findsNothing);
  });

  testWidgets('a story not readable yet shows the pending line', (
    tester,
  ) async {
    await pumpStory(tester, entries: null);
    await openStory(tester);

    expect(find.text('Lettura della storia…'), findsOneWidget);
    expect(find.text(ParticipantStory.emptyLine), findsNothing);
  });

  testWidgets('a failed read shows the line the page gives', (tester) async {
    await pumpStory(tester, entries: null, pendingLine: _failureLine);
    await openStory(tester);

    expect(find.text(_failureLine), findsOneWidget);
    expect(find.text(ParticipantStory.readingLine), findsNothing);
    expect(find.byType(NewEntrySigil), findsNothing);
  });

  test('two readers with the same fields are equal', () {
    expect(
      const StoryReader(
        characterId: _aria,
        name: 'Aria',
        title: TitleType.adventurer,
      ),
      _adventurer,
    );
    expect(
      const StoryReader(characterId: _aria, name: 'Aria'),
      isNot(_adventurer),
    );
  });
}
