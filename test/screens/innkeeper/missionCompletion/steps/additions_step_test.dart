import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/mission_back_button.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/participant_story.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/additions_step.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/shared/components/sheet_text_field.dart';

import '../../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

const String _aldo = 'char-aldo';
const String _bea = 'char-bea';
const String _birth = 'Nato a Drustea.';
const String _savedAddition = 'Ha visto il drago.';
const String _emojiFamily = '👨‍👩‍👧‍👦';
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
    _aldo: _characterWith(_aldo, 'Aldo', const [_birth]),
    _bea: _characterWith(_bea, 'Bea', const []),
  },
  places: const {},
);

const MissionParticipantsFailed _failed = MissionParticipantsFailed(
  failure: InnkeeperFailure.connection,
);

void main() {
  late Map<String, String> texts;
  late List<(String, String)> changes;
  late int concludes;
  late int retries;

  setUp(() {
    texts = const {};
    changes = [];
    concludes = 0;
    retries = 0;
  });

  /// La pagina non possiede i testi: qui li tiene il test, come farà la
  /// schermata.
  Future<void> pumpStep(
    WidgetTester tester, {
    Map<String, String> initialTexts = const {},
    MissionParticipantsState participants = const MissionParticipantsLoading(),
    List<StoryReader> readers = _readers,
    bool isSubmitting = false,
  }) async {
    useLandscapePhone(tester);
    seedSvgCache([CloudinaryAssets.arrowDown]);
    texts = initialTexts;
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          // come il wizard: la tastiera resta visibile alle pagine
          resizeToAvoidBottomInset: false,
          body: MissionBackScope(
            onBack: () {},
            child: StatefulBuilder(
              builder: (context, setState) => AdditionsStep(
                readers: readers,
                participants: participants,
                texts: texts,
                onChanged: (characterId, text) {
                  changes.add((characterId, text));
                  setState(() => texts = {...texts, characterId: text});
                },
                isSubmitting: isSubmitting,
                onConclude: () => concludes++,
                onRetry: () => retries++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> type(
    WidgetTester tester,
    String characterId,
    String text,
  ) async {
    await tester.enterText(
      find.byKey(AdditionsStep.fieldKeyFor(characterId)),
      text,
    );
    await tester.pump();
  }

  String fieldText(WidgetTester tester, String characterId) => tester
      .widget<TextField>(
        find.descendant(
          of: find.byKey(AdditionsStep.fieldKeyFor(characterId)),
          matching: find.byType(TextField),
        ),
      )
      .controller!
      .text;

  VoidCallback? concludeOnPressed(WidgetTester tester) => tester
      .widget<ButtonStyleButton>(find.byKey(AdditionsStep.concludeKey))
      .onPressed;

  group('isTooLong', () {
    test('a text of 1000 emoji families is not too long: clusters are '
        'counted, not UTF-16 units (D-07)', () {
      expect(_emojiFamily.length, greaterThan(1));
      expect(AdditionsStep.isTooLong(_emojiFamily * 1000), isFalse);
      expect(AdditionsStep.isTooLong(_emojiFamily * 1001), isTrue);
    });

    test('an empty text is not too long', () {
      expect(AdditionsStep.isTooLong(''), isFalse);
    });
  });

  testWidgets(
    'each participant has the story dropdown and one field (D-06, D-08)',
    (tester) async {
      await pumpStep(tester, participants: _loaded);

      expect(find.byType(Dropdown), findsNWidgets(2));
      expect(find.byType(SheetTextField), findsNWidgets(2));
      expect(find.text(AdditionsStep.fieldLabel), findsNWidgets(2));
      for (final id in [_aldo, _bea]) {
        expect(
          tester.getTopLeft(find.byKey(ParticipantStory.keyFor(id))).dy,
          lessThan(
            tester.getTopLeft(find.byKey(AdditionsStep.fieldKeyFor(id))).dy,
          ),
        );
      }
      expect(
        tester.getTopLeft(find.byKey(AdditionsStep.fieldKeyFor(_aldo))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(ParticipantStory.keyFor(_bea))).dy,
        ),
      );
    },
  );

  testWidgets('the story so far is read again from the dropdown (D-04, D-08)', (
    tester,
  ) async {
    await pumpStep(tester, participants: _loaded);
    expect(find.text(_birth).hitTestable(), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byKey(ParticipantStory.keyFor(_aldo)),
        matching: find.byType(DropdownHeader),
      ),
    );
    await tester.pump();
    await tester.pump(_openingTime);

    expect(find.text(_birth).hitTestable(), findsOneWidget);
  });

  testWidgets('a field starts from the text of the draft (D-05)', (
    tester,
  ) async {
    await pumpStep(tester, initialTexts: const {_aldo: _savedAddition});

    expect(fieldText(tester, _aldo), _savedAddition);
    expect(fieldText(tester, _bea), isEmpty);
  });

  testWidgets('typing reports the participant and the text', (tester) async {
    await pumpStep(tester);

    await type(tester, _bea, 'Ha perso la spada.');

    expect(changes, [(_bea, 'Ha perso la spada.')]);
  });

  testWidgets('the field counts up to 1000 (D-07)', (tester) async {
    await pumpStep(tester);

    expect(find.text('0/1000'), findsNWidgets(2));

    await type(tester, _aldo, 'Drago');

    expect(find.text('5/1000'), findsOneWidget);
  });

  testWidgets('1001 characters show the error and disable Concludi (D-07)', (
    tester,
  ) async {
    await pumpStep(tester);

    await type(tester, _aldo, 'a' * 1001);

    expect(find.text('Massimo 1000 caratteri'), findsOneWidget);
    expect(concludeOnPressed(tester), isNull);
  });

  testWidgets('exactly 1000 characters are accepted', (tester) async {
    await pumpStep(tester);

    await type(tester, _aldo, 'a' * 1000);

    expect(find.text(AdditionsStep.tooLongMessage), findsNothing);
    expect(concludeOnPressed(tester), isNotNull);
  });

  testWidgets('spaces around the text do not count (D-07)', (tester) async {
    await pumpStep(tester);

    await type(tester, _aldo, '   ${'a' * 1000}   ');

    expect(find.text(AdditionsStep.tooLongMessage), findsNothing);
    expect(concludeOnPressed(tester), isNotNull);
  });

  testWidgets('shortening a text too long enables Concludi again', (
    tester,
  ) async {
    await pumpStep(tester);
    await type(tester, _bea, 'a' * 1001);

    await type(tester, _bea, 'a' * 999);

    expect(find.text(AdditionsStep.tooLongMessage), findsNothing);
    expect(concludeOnPressed(tester), isNotNull);
  });

  testWidgets('Concludi asks to conclude', (tester) async {
    await pumpStep(tester, initialTexts: const {_aldo: _savedAddition});

    expect(find.text('Concludi'), findsOneWidget);
    await tester.tap(find.byKey(AdditionsStep.concludeKey));

    expect(concludes, 1);
  });

  testWidgets('Concludi is disabled while submitting', (tester) async {
    await pumpStep(tester, isSubmitting: true);

    expect(concludeOnPressed(tester), isNull);
  });

  testWidgets('an empty page can conclude: every addition is optional (D-06)', (
    tester,
  ) async {
    await pumpStep(tester);

    await tester.tap(find.byKey(AdditionsStep.concludeKey));

    expect(concludes, 1);
  });

  testWidgets(
    'a new set of texts does not overwrite a field being typed (Pitfall 3)',
    (tester) async {
      await pumpStep(tester, initialTexts: const {_aldo: _savedAddition});
      await type(tester, _aldo, 'Scritto ora');

      await pumpStep(tester, initialTexts: const {_aldo: 'Dalla bozza'});

      expect(fieldText(tester, _aldo), 'Scritto ora');
    },
  );

  testWidgets(
    'a failed read shows the failure line and Riprova, and never blocks '
    'Concludi (D-31)',
    (tester) async {
      await pumpStep(tester, participants: _failed);

      expect(
        find.text(
          MissionCompletionScreen.failureLineOf(InnkeeperFailure.connection),
        ),
        findsNWidgets(3),
      );
      expect(concludeOnPressed(tester), isNotNull);

      await tester.tap(find.byKey(AdditionsStep.retryKey));

      expect(retries, 1);
    },
  );

  testWidgets('no Riprova is offered while the read has not failed', (
    tester,
  ) async {
    await pumpStep(tester, participants: _loaded);

    expect(find.byKey(AdditionsStep.retryKey), findsNothing);
  });

  testWidgets('the bottom row holds Indietro and Concludi in landscape', (
    tester,
  ) async {
    await pumpStep(tester, participants: _loaded);

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(MissionBackButton.buttonKey).hitTestable(),
      findsOneWidget,
    );
    final conclude = tester.getRect(find.byKey(AdditionsStep.concludeKey));
    expect(conclude.bottom, lessThanOrEqualTo(360));
    expect(
      find.descendant(
        of: find.byType(AdditionsStep),
        matching: find.byType(ListView),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'in landscape with the keyboard open nothing overflows and the bottom '
    'row is hidden (Pitfall 6)',
    (tester) async {
      const names = ['Aldo', 'Bea', 'Cosimo', 'Dora', 'Elio'];
      await pumpStep(
        tester,
        participants: _failed,
        readers: [
          for (final name in names)
            StoryReader(characterId: 'char-${name.toLowerCase()}', name: name),
        ],
      );
      expect(tester.takeException(), isNull);

      tester.view.viewInsets = const FakeViewPadding(bottom: 700);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(AdditionsStep.concludeKey), findsNothing);
      expect(find.byKey(MissionBackButton.buttonKey), findsNothing);
      expect(find.byKey(AdditionsStep.retryKey), findsNothing);
      expect(find.byType(SheetTextField), findsNWidgets(5));
    },
  );
}
