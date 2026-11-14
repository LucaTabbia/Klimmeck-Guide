import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_prize_options.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionPrizeOptionsCubit/mission_prize_options_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/recap_step.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../../helpers/fixtures/mission_fixtures.dart';
import '../../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../../helpers/fixtures/shop_fixtures.dart';
import '../../../../helpers/fixtures/spell_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

const String _aldo = 'char-aldo';
const String _bea = 'char-bea';

final RequestCard _card = requestCardsOf(
  worldMissionEntriesJson(
    names: const ['Aldo', 'Bea'],
  ).map(PendingRequest.fromJson).toList(),
).single;

final Map<String, dynamic> _orc = missionEnemyJson(
  id: 'enemy-orc',
  name: 'Orco',
);
final Map<String, dynamic> _goblin = missionEnemyJson(
  id: 'enemy-goblin',
  name: 'Goblin',
);

final List<Map<String, dynamic>> _participants = [
  missionParticipantJson(),
  missionParticipantJson(
    character: _bea,
    name: 'Bea',
    pendingQuest: 'pq-world-2',
  ),
];

/// Due scontri: il primo perso con la mano schiacciata, il secondo vinto con
/// la vita di Aldo corretta a 650 (la correzione vince, D-06).
final List<Map<String, dynamic>> _fights = [
  missionFightJson(
    verdict: 'failure',
    enemies: [
      missionFightEnemyJson(),
      missionFightEnemyJson(enemy: _orc, quantity: 1),
    ],
    outcomes: [
      missionOutcomeJson(simulated: missionEffectsJson()),
      missionOutcomeJson(
        character: _bea,
        hpBefore: 500,
        simulated: missionEffectsJson(hpAfter: 450, injuriesAdded: const []),
      ),
    ],
  ),
  missionFightJson(
    verdict: 'success',
    enemies: [missionFightEnemyJson(enemy: _goblin, quantity: 2)],
    outcomes: [
      missionOutcomeJson(
        hpBefore: 700,
        simulated: missionEffectsJson(hpAfter: 600),
        corrected: missionEffectsJson(hpAfter: 650),
      ),
      missionOutcomeJson(
        character: _bea,
        hpBefore: 450,
        simulated: missionEffectsJson(hpAfter: 450, injuriesAdded: const []),
      ),
    ],
  ),
];

final Map<String, dynamic> _aldoPrize = missionPrizeJson(
  items: [
    {'item': 'l-relic', 'quantity': 1},
  ],
  pet: 'pet-travel-horse',
  spell: fireballSpellId,
  cure: const {'lifePointsShare': 0.5, 'canHeal': <String>[]},
);

MissionDraft _draft({
  List<Map<String, dynamic>> fights = const [],
  List<Map<String, dynamic>> prizes = const [],
}) => MissionDraft.tryFromJson(
  missionDraftJson(
    step: 'recap',
    participants: _participants,
    fights: fights,
    prizes: prizes,
  ),
)!;

final MissionPrizeOptions _aldoOptions = MissionPrizeOptions.tryFromJson(
  missionPrizeOptionsJson(
    block: {
      'randomLoot': [
        {'item': lootAssetJson(id: 'l-relic')['item'], 'quantity': 1},
      ],
      'pet': petJson(),
      'spell': spellJson(id: fireballSpellId, name: 'Palla di fuoco'),
    },
  ),
)!;

void main() {
  late MockMissionPrizeOptionsCubit prizeOptionsCubit;
  late int completions;

  setUp(() {
    seedSvgCache([
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
    ]);
    completions = 0;
    prizeOptionsCubit = MockMissionPrizeOptionsCubit();
    whenListen(
      prizeOptionsCubit,
      const Stream<MissionPrizeOptionsState>.empty(),
      initialState: MissionPrizeOptionsState(options: {_aldo: _aldoOptions}),
    );
  });

  Future<void> pumpStep(
    WidgetTester tester,
    MissionDraft draft, {
    bool isSubmitting = false,
  }) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: BlocProvider<MissionPrizeOptionsCubit>.value(
            value: prizeOptionsCubit,
            child: RecapStep(
              card: _card,
              draft: draft,
              isSubmitting: isSubmitting,
              onComplete: () => completions++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      60,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  Future<void> tapComplete(WidgetTester tester) async {
    await tester.tap(find.byKey(RecapStep.completeKey));
    await tester.pumpAndSettle();
  }

  Finder confirmButton() => find.descendant(
    of: find.byType(DestructiveConfirmationDialog),
    matching: find.widgetWithText(ElevatedButton, RecapStep.completeLabel),
  );

  group('missionRecapLinesOf', () {
    test('lists the quest, the fights, the PV and the injuries (D-08)', () {
      expect(
        missionRecapLinesOf(
          questTitle: 'La torre',
          draft: _draft(fights: _fights),
        ),
        [
          'La torre',
          'Scontro 1: 3x Lupo, 1x Orco · Sconfitta',
          'Scontro 2: 2x Goblin · Vittoria',
          'Aldo: PV 800 → 650',
          'Ferite: mano destra schiacciata',
          'Bea: PV 500 → 450',
        ],
      );
    });

    test('zero fights lists no fight and no PV line (D-24)', () {
      expect(missionRecapLinesOf(questTitle: 'La torre', draft: _draft()), [
        'La torre',
      ]);
    });
  });

  testWidgets('lists each fight with its enemies and verdict (D-02, D-21)', (
    tester,
  ) async {
    await pumpStep(tester, _draft(fights: _fights));

    expect(
      find.text('Scontro 1: 3x Lupo, 1x Orco · Sconfitta'),
      findsOneWidget,
    );
    expect(find.text('Scontro 2: 2x Goblin · Vittoria'), findsOneWidget);
  });

  testWidgets(
    "lists each character's PV from the first fight's start to the last fight's effective HP (D-06)",
    (tester) async {
      await pumpStep(tester, _draft(fights: _fights));

      expect(find.text('Aldo: PV 800 → 650'), findsOneWidget);
      expect(find.text('Bea: PV 500 → 450'), findsOneWidget);
    },
  );

  testWidgets('lists the injuries the fights add (D-14)', (tester) async {
    await pumpStep(tester, _draft(fights: _fights));

    expect(find.text('Ferite: mano destra schiacciata'), findsOneWidget);
  });

  testWidgets('zero fights lists no fight and no PV line (D-24)', (
    tester,
  ) async {
    await pumpStep(tester, _draft());

    expect(find.textContaining('Scontro'), findsNothing);
    expect(find.textContaining('PV'), findsNothing);
    expect(find.text(_card.questTitle), findsOneWidget);
  });

  testWidgets('shows the chosen prizes per character (D-22)', (tester) async {
    await pumpStep(tester, _draft(prizes: [_aldoPrize]));

    await reveal(tester, find.byType(CoinsDisplay));
    expect(
      tester.widget<CoinsDisplay>(find.byType(CoinsDisplay)).coins,
      const Coins(gold: 2),
    );
    for (final line in [
      '+150 XP',
      '1x l-relic',
      'Cavallo da viaggio',
      'Palla di fuoco',
      'Vita: almeno il 50%',
    ]) {
      await reveal(tester, find.text(line));
      expect(find.text(line), findsOneWidget);
    }
  });

  testWidgets(
    '«Completa» asks «Completa la missione» with the recap and completes on confirm (D-08)',
    (tester) async {
      await pumpStep(tester, _draft(fights: _fights));

      await tapComplete(tester);

      final dialog = tester.widget<DestructiveConfirmationDialog>(
        find.byType(DestructiveConfirmationDialog),
      );
      expect(dialog.title, MissionCompletionScreen.title);
      expect(
        dialog.body,
        missionRecapLinesOf(
          questTitle: _card.questTitle,
          draft: _draft(fights: _fights),
        ).join('\n'),
      );
      expect(dialog.confirmButtonStyle, KlimmeckGuideTheme.primaryButtonStyle);
      await tester.tap(confirmButton());
      await tester.pumpAndSettle();

      expect(completions, 1);
    },
  );

  testWidgets('cancel does not complete (D-08)', (tester) async {
    await pumpStep(tester, _draft(fights: _fights));

    await tapComplete(tester);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(completions, 0);
    expect(find.byType(DestructiveConfirmationDialog), findsNothing);
  });

  testWidgets('«Completa» is disabled while submitting', (tester) async {
    await pumpStep(tester, _draft(), isSubmitting: true);

    expect(
      tester
          .widget<ElevatedButton>(find.byKey(RecapStep.completeKey))
          .onPressed,
      isNull,
    );
  });

  testWidgets('a fight with no verdict disables «Completa» (D-24)', (
    tester,
  ) async {
    await pumpStep(tester, _draft(fights: [_fights.first, missionFightJson()]));

    expect(
      tester
          .widget<ElevatedButton>(find.byKey(RecapStep.completeKey))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'a defeat still completes: no reject or aid action exists (D-05)',
    (tester) async {
      await pumpStep(tester, _draft(fights: [_fights.first]));

      final buttons = tester.widgetList<ButtonStyleButton>(
        find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
      );
      expect(buttons.map((button) => button.key), [RecapStep.completeKey]);
      expect(buttons.single.onPressed, isNotNull);
    },
  );
}
