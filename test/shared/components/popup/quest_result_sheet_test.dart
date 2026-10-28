import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/hp_delta_bar.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_result_sheet.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../helpers/fixtures/quest_result_fixtures.dart';
import '../../../helpers/landscape.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

Future<void> _pump(
  WidgetTester tester,
  QuestResult result, {
  VoidCallback? onContinue,
  String? characterName,
  int position = 1,
  int total = 1,
  bool isAcknowledging = false,
  bool hasAcknowledgeFailed = false,
}) async {
  useLandscapePhone(tester);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: QuestResultSheet(
          result: result,
          onContinue: onContinue ?? () {},
          characterName: characterName,
          position: position,
          total: total,
          isAcknowledging: isAcknowledging,
          hasAcknowledgeFailed: hasAcknowledgeFailed,
        ),
      ),
    ),
  );
}

String _hpValue(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(HpDeltaBar.valueKey)).data!;

TextButton _button(WidgetTester tester) =>
    tester.widget<TextButton>(find.byKey(QuestResultSheet.continueKey));

Finder _inSection(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.emptySheet,
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.healEffect,
      CloudinaryAssets.helmetType,
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
    ]),
  );

  group('success', () {
    testWidgets('shows the D-03 content and hides the unchanged sections', (
      tester,
    ) async {
      await _pump(tester, questResult(successResultJson()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Text>(find.byKey(QuestResultSheet.headerKey)).data,
        'Vittoria',
      );
      expect(find.text('Lupi di Valantar'), findsOneWidget);
      expect(find.text('Caccia'), findsOneWidget);
      expect(
        _inSection(QuestResultSheet.enemyKey, find.text('Lupo grigio')),
        findsOneWidget,
      );
      expect(find.byKey(QuestResultSheet.hpKey), findsOneWidget);
      expect(
        _inSection(QuestResultSheet.injuriesKey, find.text('Taglio profondo')),
        findsOneWidget,
      );
      expect(
        _inSection(QuestResultSheet.consumablesKey, find.byType(ItemRow)),
        findsOneWidget,
      );
      expect(
        _inSection(QuestResultSheet.spellsKey, find.text('Dardo di fuoco ×2')),
        findsOneWidget,
      );
      expect(
        _inSection(QuestResultSheet.rewardsKey, find.byType(CoinsDisplay)),
        findsOneWidget,
      );
      expect(
        _inSection(QuestResultSheet.rewardsKey, find.byType(ItemRow)),
        findsOneWidget,
      );
      expect(find.text('Esperienza: 200 → 260 (+60)'), findsOneWidget);
      expect(find.text('Livello 1 → 2'), findsOneWidget);
      expect(find.byKey(QuestResultSheet.titleKey), findsNothing);
      expect(find.byKey(QuestResultSheet.spellLearnedKey), findsNothing);
      expect(find.byKey(QuestResultSheet.rescuedKey), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(QuestResultSheet.continueKey),
          matching: find.text('Continua'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the local resolution instant', (tester) async {
      final result = questResult(successResultJson());
      await _pump(tester, result);

      final expected = DateFormat(
        'dd/MM HH:mm',
      ).format(result.resolvedAt.toLocal());
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('the header uses the outcome ink', (tester) async {
      await _pump(tester, questResult(successResultJson()));

      expect(
        tester
            .widget<Text>(find.byKey(QuestResultSheet.headerKey))
            .style
            ?.color,
        KlimmeckGuideTheme.darkBronze,
      );
    });
  });

  group('HP animation', () {
    testWidgets('counts from hpBefore to hpAfter in the loss ink', (
      tester,
    ) async {
      await _pump(tester, questResult(successResultJson()));
      await tester.pump();
      expect(_hpValue(tester), '900 / 1200');

      await tester.pumpAndSettle();
      expect(_hpValue(tester), '640 / 1200');
      expect(tester.widget<HpDeltaBar>(find.byType(HpDeltaBar)).isLoss, isTrue);
    });

    testWidgets('a tap on the block skips to the end', (tester) async {
      // Senza oggetti: le quantità a matita delle card animano da sole.
      await _pump(
        tester,
        questResult(
          questResultJson(consumablesUsed: const [], rewardItems: const []),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(QuestResultSheet.hpKey));
      await tester.pump(const Duration(milliseconds: 100));
      final midway = int.parse(_hpValue(tester).split(' / ').first);
      expect(midway, greaterThan(640));

      await tester.tap(find.byKey(QuestResultSheet.hpKey));
      await tester.pump();
      expect(_hpValue(tester), '640 / 1200');
      expect(tester.hasRunningAnimations, isFalse);

      await tester.tap(find.byKey(QuestResultSheet.hpKey));
      await tester.pump();
      expect(_hpValue(tester), '640 / 1200');
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('the button is enabled on the first frame', (tester) async {
      await _pump(tester, questResult(successResultJson()));

      expect(_button(tester).onPressed, isNotNull);
    });
  });

  testWidgets('failure: no rewards and no experience line', (tester) async {
    await _pump(tester, questResult(failureResultJson()));
    await tester.pumpAndSettle();

    expect(find.text('Sconfitta'), findsOneWidget);
    expect(find.byKey(QuestResultSheet.rewardsKey), findsNothing);
    expect(find.byKey(QuestResultSheet.xpKey), findsNothing);
  });

  testWidgets('rescued: the aid as quest, no HP block, no rewards', (
    tester,
  ) async {
    await _pump(tester, questResult(rescuedResultJson()));

    expect(find.text('Sei stato salvato'), findsOneWidget);
    expect(find.text('Soccorso'), findsOneWidget);
    expect(find.byKey(QuestResultSheet.hpKey), findsNothing);
    expect(find.byKey(QuestResultSheet.rewardsKey), findsNothing);
  });

  group('death', () {
    testWidgets('shows the dead character and «Riposa in pace»', (
      tester,
    ) async {
      await _pump(
        tester,
        questResult(deathResultJson()),
        characterName: 'Aldo',
      );

      expect(find.text('È morto'), findsOneWidget);
      expect(find.text('Aldo'), findsOneWidget);
      expect(find.text('Recluta · Livello 1'), findsOneWidget);
      expect(find.byKey(QuestResultSheet.hpKey), findsNothing);
      expect(find.byKey(QuestResultSheet.rewardsKey), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(QuestResultSheet.continueKey),
          matching: find.text('Riposa in pace'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(QuestResultSheet.headerKey))
            .style
            ?.color,
        KlimmeckGuideTheme.deepNight,
      );
    });

    testWidgets('a historical sheet shows no name line', (tester) async {
      await _pump(tester, questResult(deathResultJson()));

      expect(find.text('Aldo'), findsNothing);
      expect(find.byKey(QuestResultSheet.deadNameKey), findsNothing);
      expect(find.text('Recluta · Livello 1'), findsOneWidget);
    });

    testWidgets('the button is disabled while acknowledging', (tester) async {
      await _pump(
        tester,
        questResult(deathResultJson()),
        isAcknowledging: true,
      );

      expect(_button(tester).onPressed, isNull);
    });

    testWidgets('a failed acknowledgement shows the error line', (
      tester,
    ) async {
      await _pump(
        tester,
        questResult(deathResultJson()),
        hasAcknowledgeFailed: true,
      );

      expect(
        tester
            .widget<Text>(find.byKey(QuestResultSheet.acknowledgeErrorKey))
            .data,
        'Conferma non riuscita: riprova',
      );
      expect(_button(tester).onPressed, isNotNull);
    });
  });

  testWidgets('gmCompleted: no enemy and the title change', (tester) async {
    await _pump(tester, questResult(gmCompletedResultJson()));

    expect(find.text('Missione completata'), findsOneWidget);
    expect(find.text('Storia'), findsOneWidget);
    expect(find.byKey(QuestResultSheet.enemyKey), findsNothing);
    expect(find.text('Recluta → Avventuriero'), findsOneWidget);
  });

  group('rescuers', () {
    testWidgets('counts the saved adventurers', (tester) async {
      await _pump(tester, questResult(rescuerSuccessResultJson()));

      expect(find.text('Hai salvato 2 avventurieri'), findsOneWidget);
    });

    testWidgets('one saved adventurer reads singular', (tester) async {
      await _pump(
        tester,
        questResult(questResultJson(rescuedCharacters: const ['c-2'])),
      );

      expect(find.text('Hai salvato 1 avventuriero'), findsOneWidget);
    });
  });

  group('degraded data', () {
    testWidgets('a missing spell reads «Magia sconosciuta»', (tester) async {
      await _pump(
        tester,
        questResult(
          questResultJson(
            spellsUsed: const [
              {'usages': 1, 'spell': null},
            ],
          ),
        ),
      );

      expect(find.text('Magia sconosciuta ×1'), findsOneWidget);
    });

    testWidgets('an unknown quest type shows no type line', (tester) async {
      await _pump(tester, questResult(questResultJson(questType: 'unknown')));

      expect(tester.takeException(), isNull);
      expect(find.byKey(QuestResultSheet.questTypeKey), findsNothing);
      expect(find.text('Caccia'), findsNothing);
    });

    testWidgets('shows the learned spell', (tester) async {
      await _pump(
        tester,
        questResult(
          questResultJson(spellLearned: const {'id': 's-9', 'name': 'Scudo'}),
        ),
      );

      expect(
        tester.widget<Text>(find.byKey(QuestResultSheet.spellLearnedKey)).data,
        'Magia appresa: Scudo',
      );
    });
  });

  group('counter', () {
    testWidgets('shows «k di N» in a queue', (tester) async {
      await _pump(
        tester,
        questResult(successResultJson()),
        position: 2,
        total: 3,
      );

      expect(
        tester.widget<Text>(find.byKey(QuestResultSheet.counterKey)).data,
        '2 di 3',
      );
    });

    testWidgets('a single sheet has no counter', (tester) async {
      await _pump(tester, questResult(successResultJson()));

      expect(find.byKey(QuestResultSheet.counterKey), findsNothing);
    });
  });

  group('dismissal', () {
    testWidgets('the button calls onContinue once', (tester) async {
      var calls = 0;
      await _pump(
        tester,
        questResult(successResultJson()),
        onContinue: () => calls++,
      );

      await tester.tap(find.byKey(QuestResultSheet.continueKey));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('tapping anywhere else calls nothing', (tester) async {
      var calls = 0;
      await _pump(
        tester,
        questResult(successResultJson()),
        onContinue: () => calls++,
      );

      await tester.tap(find.byKey(QuestResultSheet.headerKey));
      await tester.tapAt(const Offset(5, 5));
      await tester.ensureVisible(find.byKey(QuestResultSheet.hpKey));
      await tester.pump();
      await tester.tap(find.byKey(QuestResultSheet.hpKey));
      await tester.fling(
        find.byKey(QuestResultSheet.headerKey),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(calls, 0);
    });

    testWidgets('no AppBar and no exception in landscape', (tester) async {
      for (final json in [
        successResultJson(),
        failureResultJson(),
        rescuedResultJson(),
        deathResultJson(),
        gmCompletedResultJson(),
        rescuerSuccessResultJson(),
      ]) {
        await _pump(tester, questResult(json), position: 1, total: 2);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(AppBar), findsNothing);
      }
    });
  });
  group('layout (09-REVIEW WR-02)', () {
    testWidgets('a narrow surface keeps the parchment ratio and the button '
        'inside it', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        buildTestApp(
          home: Scaffold(
            body: QuestResultSheet(
              result: questResult(successResultJson()),
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final parchment = tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CachedSvg &&
              widget.url == CloudinaryAssets.url(CloudinaryAssets.emptySheet),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(parchment.width / parchment.height, closeTo(315 / 375, 1e-6));
      final button = tester.getRect(find.byKey(QuestResultSheet.continueKey));
      expect(parchment.contains(button.topLeft), isTrue);
      expect(parchment.contains(button.bottomRight), isTrue);
    });
  });
}
