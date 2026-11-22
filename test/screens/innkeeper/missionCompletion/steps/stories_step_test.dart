import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/mission_back_button.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/participant_story.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/stories_step.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';

import '../../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

const String _aldo = 'char-aldo';
const String _bea = 'char-bea';
const String _birth = 'Nato a Drustea.';
const String _deed = 'Ha salvato Bosa dai predoni.';
const Duration _openingTime = Duration(milliseconds: 400);

const List<StoryReader> _readers = [
  StoryReader(characterId: _aldo, name: 'Aldo'),
  StoryReader(characterId: _bea, name: 'Bea'),
];

Character _characterWith(String id, String name, List<String> background) {
  final json = participantCharacterJson(id: id, name: name);
  return Character.fromJson({
    ...json,
    'infos': {
      ...json['infos'] as Map<String, dynamic>,
      'background': background,
    },
  });
}

final MissionParticipantsLoaded _loaded = MissionParticipantsLoaded(
  characters: {
    _aldo: _characterWith(_aldo, 'Aldo', const [_birth, _deed]),
    _bea: _characterWith(_bea, 'Bea', const []),
  },
  places: const {},
);

const MissionParticipantsFailed _failed = MissionParticipantsFailed(
  failure: InnkeeperFailure.connection,
);

void main() {
  late int starts;
  late int retries;
  late int nexts;

  setUp(() {
    starts = 0;
    retries = 0;
    nexts = 0;
  });

  Widget startFooter({bool isStarting = false}) =>
      StoriesStartFooter(isStarting: isStarting, onStart: () => starts++);

  Future<void> pumpStep(
    WidgetTester tester,
    MissionParticipantsState participants, {
    List<StoryReader> readers = _readers,
    Widget? footer,
    VoidCallback? onBack,
  }) async {
    useLandscapePhone(tester);
    seedSvgCache([CloudinaryAssets.arrowDown]);
    await tester.pumpWidget(
      buildTestApp(
        home: Builder(
          builder: (context) => Theme(
            // i pulsanti compatti del wizard, come nella schermata vera
            data: KlimmeckGuideTheme.compactButtonsOf(Theme.of(context)),
            child: Scaffold(
              body: MissionBackScope(
                onBack: onBack,
                child: StoriesStep(
                  readers: readers,
                  participants: participants,
                  onRetry: () => retries++,
                  footer: footer ?? startFooter(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> openStory(WidgetTester tester, String characterId) async {
    await tester.tap(
      find.descendant(
        of: find.byKey(ParticipantStory.keyFor(characterId)),
        matching: find.byType(DropdownHeader),
      ),
    );
    await tester.pump();
    await tester.pump(_openingTime);
  }

  double openFactorOf(WidgetTester tester, String characterId) => tester
      .widget<SizeTransition>(
        find.descendant(
          of: find.byKey(ParticipantStory.keyFor(characterId)),
          matching: find.byType(SizeTransition),
        ),
      )
      .sizeFactor
      .value;

  VoidCallback? onPressedOf(WidgetTester tester, Key key) =>
      tester.widget<ButtonStyleButton>(find.byKey(key)).onPressed;

  testWidgets(
    'one closed dropdown per reader, the names shown before the read ends (D-01, D-02)',
    (tester) async {
      await pumpStep(tester, const MissionParticipantsLoading());

      expect(find.byType(Dropdown), findsNWidgets(2));
      expect(find.text('Aldo'), findsOneWidget);
      expect(find.text('Bea'), findsOneWidget);
      expect(openFactorOf(tester, _aldo), 0);
      expect(openFactorOf(tester, _bea), 0);
      expect(find.text(ParticipantStory.readingLine), findsNWidgets(2));
    },
  );

  testWidgets(
    'a loaded story shows its entries oldest first after the tap (D-03)',
    (tester) async {
      await pumpStep(tester, _loaded);
      expect(find.text(_birth).hitTestable(), findsNothing);

      await openStory(tester, _aldo);

      expect(find.text(_birth).hitTestable(), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(_birth)).dy,
        lessThan(tester.getTopLeft(find.text(_deed)).dy),
      );
      expect(find.text(ParticipantStory.readingLine), findsNothing);
    },
  );

  testWidgets('a participant without story reads the in-world line (D-03)', (
    tester,
  ) async {
    await pumpStep(tester, _loaded);

    await openStory(tester, _bea);

    expect(
      find.text('Di questo avventuriero non si sa ancora nulla').hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('the rank follows the name when the reader has one (D-03)', (
    tester,
  ) async {
    await pumpStep(
      tester,
      _loaded,
      readers: const [
        StoryReader(
          characterId: _aldo,
          name: 'Aldo',
          title: TitleType.adventurer,
        ),
        StoryReader(characterId: _bea, name: 'Bea'),
      ],
    );

    expect(find.text('Aldo · Avventuriero'), findsOneWidget);
    expect(find.text('Bea'), findsOneWidget);
  });

  testWidgets(
    'a failed read shows the failure line and Riprova, which asks to read again (D-31)',
    (tester) async {
      await pumpStep(tester, _failed);

      expect(
        find.text(
          MissionCompletionScreen.failureLineOf(InnkeeperFailure.connection),
        ),
        findsNWidgets(3),
      );
      expect(find.text(ParticipantStory.readingLine), findsNothing);

      await tester.tap(find.byKey(StoriesStep.retryKey));

      expect(retries, 1);
      expect(find.text(MissionCompletionScreen.retryLabel), findsOneWidget);
    },
  );

  testWidgets('no Riprova is offered while the read has not failed', (
    tester,
  ) async {
    await pumpStep(tester, _loaded);

    expect(find.byKey(StoriesStep.retryKey), findsNothing);
  });

  testWidgets(
    'the start footer shows the note and Inizia la missione, tapped once it starts (D-02, D-28)',
    (tester) async {
      await pumpStep(tester, _loaded);

      expect(find.text(MissionCompletionScreen.startNote), findsOneWidget);
      expect(find.text('Inizia la missione'), findsOneWidget);
      expect(starts, 0);

      await tester.tap(find.byKey(MissionCompletionScreen.startKey));

      expect(starts, 1);
      expect(find.byType(KGLoader), findsNothing);
    },
  );

  testWidgets('while starting the button is disabled and the loader shows', (
    tester,
  ) async {
    await pumpStep(tester, _loaded, footer: startFooter(isStarting: true));

    expect(onPressedOf(tester, MissionCompletionScreen.startKey), isNull);
    expect(find.byType(KGLoader), findsOneWidget);
  });

  testWidgets('a failed read leaves Inizia la missione enabled (D-31)', (
    tester,
  ) async {
    await pumpStep(tester, _failed);

    await tester.tap(find.byKey(MissionCompletionScreen.startKey));

    expect(starts, 1);
  });

  testWidgets('a read still running leaves Inizia la missione enabled (D-31)', (
    tester,
  ) async {
    await pumpStep(tester, const MissionParticipantsLoading());

    expect(onPressedOf(tester, MissionCompletionScreen.startKey), isNotNull);
  });

  testWidgets('the start note sits beside Inizia la missione, on its row', (
    tester,
  ) async {
    await pumpStep(tester, _loaded);

    final button = tester.getRect(find.byKey(MissionCompletionScreen.startKey));
    final note = tester.getRect(find.text(MissionCompletionScreen.startNote));

    expect(note.left, greaterThanOrEqualTo(button.right));
    expect(note.center.dy, closeTo(button.center.dy, 1));
  });

  testWidgets('the next footer shows Avanti and a disabled Indietro', (
    tester,
  ) async {
    await pumpStep(
      tester,
      _loaded,
      footer: StoriesNextFooter(onNext: () => nexts++),
    );

    expect(onPressedOf(tester, MissionCompletionScreen.backKey), isNull);
    expect(find.text('Avanti'), findsOneWidget);
    expect(find.byKey(MissionCompletionScreen.startKey), findsNothing);
    expect(find.text(MissionCompletionScreen.startNote), findsNothing);

    await tester.tap(find.byKey(MissionCompletionScreen.nextKey));

    expect(nexts, 1);
  });

  testWidgets('five readers in landscape do not overflow', (tester) async {
    const names = ['Aldo', 'Bea', 'Cosimo', 'Dora', 'Elio'];
    await pumpStep(
      tester,
      _failed,
      readers: [
        for (final name in names)
          StoryReader(
            characterId: 'char-${name.toLowerCase()}',
            name: name,
            title: TitleType.adventurer,
          ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Dropdown), findsNWidgets(5));
    expect(
      find.descendant(
        of: find.byType(StoriesStep),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
    final start = tester.getRect(find.byKey(MissionCompletionScreen.startKey));
    expect(start.bottom, lessThanOrEqualTo(360));
    expect(
      find.byKey(MissionCompletionScreen.startKey).hitTestable(),
      findsOneWidget,
    );
  });
}
