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
import 'package:klimmeck_guide/theme/kg_theme.dart';

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

const List<String> _fiveNames = ['Aldo', 'Bea', 'Cosimo', 'Dora', 'Elio'];

List<StoryReader> _readersOf(List<String> names) => [
  for (final name in names)
    StoryReader(characterId: 'char-${name.toLowerCase()}', name: name),
];

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
        home: Builder(
          builder: (context) => Theme(
            // i pulsanti compatti del wizard, come nella schermata vera
            data: KlimmeckGuideTheme.compactButtonsOf(Theme.of(context)),
            child: Scaffold(
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
        ),
      ),
    );
    await tester.pump();
  }

  Finder fieldOf(String characterId) =>
      find.byKey(AdditionsStep.fieldKeyFor(characterId));

  Finder summaryOf(String characterId) =>
      find.byKey(AdditionsStep.summaryKeyFor(characterId));

  /// Apre o chiude la tendina del partecipante.
  Future<void> toggle(WidgetTester tester, String characterId) async {
    final header = find.descendant(
      of: find.byKey(ParticipantStory.keyFor(characterId)),
      matching: find.byType(DropdownHeader),
    );
    await tester.ensureVisible(header);
    await tester.pump();
    await tester.tap(header);
    await tester.pump();
    await tester.pump(_openingTime);
  }

  /// Scrive nel campo come fa l'oste: dentro la tendina aperta.
  Future<void> type(
    WidgetTester tester,
    String characterId,
    String text,
  ) async {
    final isClosed = tester
        .widget<ExcludeFocus>(
          find.ancestor(
            of: fieldOf(characterId),
            matching: find.byType(ExcludeFocus),
          ),
        )
        .excluding;
    if (isClosed) await toggle(tester, characterId);
    await tester.enterText(fieldOf(characterId), text);
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
    'each participant has one closed dropdown holding the story and the '
    'field (D-06, D-08, D-23)',
    (tester) async {
      await pumpStep(tester, participants: _loaded);

      expect(find.byType(Dropdown), findsNWidgets(2));
      expect(find.byType(SheetTextField), findsNWidgets(2));
      for (final id in [_aldo, _bea]) {
        expect(
          find.descendant(
            of: find.byKey(ParticipantStory.keyFor(id)),
            matching: fieldOf(id),
          ),
          findsOneWidget,
        );
        expect(fieldOf(id).hitTestable(), findsNothing);
      }
      expect(find.text(AdditionsStep.fieldLabel).hitTestable(), findsNothing);
    },
  );

  testWidgets('an open dropdown shows the story and the field under it '
      '(D-23)', (tester) async {
    await pumpStep(tester, participants: _loaded);

    await toggle(tester, _aldo);

    expect(find.text(_birth).hitTestable(), findsOneWidget);
    expect(fieldOf(_aldo).hitTestable(), findsOneWidget);
    expect(fieldOf(_bea).hitTestable(), findsNothing);
    expect(
      tester.getTopLeft(find.text(_birth)).dy,
      lessThan(tester.getTopLeft(fieldOf(_aldo)).dy),
    );
    expect(find.text('0/1000').hitTestable(), findsOneWidget);
  });

  group('the header sums up the addition (D-23)', () {
    testWidgets('an empty field adds nothing to the header', (tester) async {
      await pumpStep(tester, participants: _loaded);

      expect(summaryOf(_aldo), findsNothing);
      expect(summaryOf(_bea), findsNothing);
    });

    testWidgets('a text of the draft is counted on the closed header', (
      tester,
    ) async {
      await pumpStep(tester, initialTexts: const {_aldo: _savedAddition});

      expect(summaryOf(_aldo).hitTestable(), findsOneWidget);
      expect(
        tester.widget<Text>(summaryOf(_aldo)).data,
        'aggiunta ${_savedAddition.length}/1000',
      );
      expect(summaryOf(_bea), findsNothing);
    });

    testWidgets('the count follows the typing and stays when closed', (
      tester,
    ) async {
      await pumpStep(tester);

      await type(tester, _bea, 'Drago');
      await toggle(tester, _bea);

      expect(fieldOf(_bea).hitTestable(), findsNothing);
      expect(tester.widget<Text>(summaryOf(_bea)).data, 'aggiunta 5/1000');
    });

    testWidgets('only spaces add nothing to the header (D-06)', (tester) async {
      await pumpStep(tester);

      await type(tester, _aldo, '   ');

      expect(summaryOf(_aldo), findsNothing);
    });

    testWidgets('a text too long is counted in the error colour, a text '
        'within the limit is not (D-07)', (tester) async {
      await pumpStep(tester);
      await type(tester, _aldo, 'a' * 1001);
      await type(tester, _bea, 'a' * 1000);
      await toggle(tester, _aldo);
      await toggle(tester, _bea);

      final tooLong = tester.widget<Text>(summaryOf(_aldo));
      final withinLimit = tester.widget<Text>(summaryOf(_bea));

      expect(tooLong.data, 'aggiunta 1001/1000');
      expect(tooLong.style?.color, KlimmeckGuideTheme.bloodRed);
      expect(withinLimit.data, 'aggiunta 1000/1000');
      expect(withinLimit.style?.color, isNot(KlimmeckGuideTheme.bloodRed));
      expect(summaryOf(_aldo).hitTestable(), findsOneWidget);
      expect(concludeOnPressed(tester), isNull);
    });
  });

  testWidgets('the text survives closing and opening the dropdown (D-23)', (
    tester,
  ) async {
    await pumpStep(tester);
    await type(tester, _aldo, 'Scritto ora');

    await toggle(tester, _aldo);
    expect(fieldOf(_aldo).hitTestable(), findsNothing);
    await toggle(tester, _aldo);

    expect(fieldOf(_aldo).hitTestable(), findsOneWidget);
    expect(fieldText(tester, _aldo), 'Scritto ora');
    expect(changes, [(_aldo, 'Scritto ora')]);
  });

  testWidgets('closing the dropdown leaves the field being typed (D-23)', (
    tester,
  ) async {
    await pumpStep(tester);
    await type(tester, _aldo, 'Scritto ora');
    expect(tester.testTextInput.isVisible, isTrue);

    await toggle(tester, _aldo);

    expect(tester.testTextInput.isVisible, isFalse);
  });

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

    expect(find.text('5/1000').hitTestable(), findsOneWidget);
  });

  testWidgets('1001 characters show the error and disable Concludi (D-07)', (
    tester,
  ) async {
    await pumpStep(tester);

    await type(tester, _aldo, 'a' * 1001);

    expect(find.text('Massimo 1000 caratteri').hitTestable(), findsOneWidget);
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

  for (final names in [_fiveNames.take(2).toList(), _fiveNames]) {
    testWidgets('${names.length} participants fit a landscape phone, closed '
        'and open, with Indietro and Concludi on the bottom row', (
      tester,
    ) async {
      final readers = _readersOf(names);
      await pumpStep(
        tester,
        participants: _loaded,
        readers: readers,
        initialTexts: {
          for (final reader in readers) reader.characterId: 'a' * 1001,
        },
      );
      expect(tester.takeException(), isNull);

      for (final reader in readers) {
        await toggle(tester, reader.characterId);
        expect(tester.takeException(), isNull);
      }

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
  }

  testWidgets(
    'in landscape with the keyboard open nothing overflows and the bottom '
    'row is hidden (Pitfall 6)',
    (tester) async {
      await pumpStep(
        tester,
        participants: _failed,
        readers: _readersOf(_fiveNames),
      );
      await type(tester, 'char-elio', 'Scritto ora');
      expect(tester.takeException(), isNull);

      tester.view.viewInsets = const FakeViewPadding(bottom: 700);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(AdditionsStep.concludeKey), findsNothing);
      expect(find.byKey(MissionBackButton.buttonKey), findsNothing);
      expect(find.byKey(AdditionsStep.retryKey), findsNothing);
      expect(find.byType(SheetTextField), findsNWidgets(5));
      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      expect(viewport.height, greaterThan(0));
      expect(tester.getRect(fieldOf('char-elio')).overlaps(viewport), isTrue);
    },
  );
}
