import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/asset_item.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../helpers/fixtures/potion_fixtures.dart';
import '../../helpers/svg_cache_seed.dart';
import '../../helpers/test_app.dart';

LootItem _loot({
  EffectType? effect,
  int? power,
  List<InjuryType> injuries = const [],
}) => LootItem(
  id: 'l-1',
  name: 'Pozione',
  description: 'Cura le ferite',
  rarity: null,
  buyPrice: null,
  sellPrice: null,
  effect: effect,
  power: power,
  canHeal: injuries,
);

final _helm = AssetItem.fromJson({
  'id': 'e-1',
  'name': 'Elmo',
  'description': 'Un elmo robusto',
  'equipType': 'helm',
  'rarity': 'common',
});

final _herbs = LootItem.fromJson(healPotionJson());

Future<void> _pump(
  WidgetTester tester,
  AssetItem assetItem, {
  bool isDisabled = false,
  String? statusLine,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          child: ItemRow(
            assetItem: assetItem,
            size: 80,
            showCoins: false,
            isDisabled: isDisabled,
            statusLine: statusLine,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

double _topOf(WidgetTester tester, String key) =>
    tester.getTopLeft(find.byKey(ValueKey(key))).dy;

double _cardOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.byKey(const ValueKey('item-card-opacity-l-herb')),
    )
    .opacity;

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.healEffect,
      CloudinaryAssets.munitionEffect,
      CloudinaryAssets.helmetType,
    ]),
  );

  group('effect line', () {
    testWidgets('a loot item shows «Cura: 12» under the description', (
      tester,
    ) async {
      await _pump(tester, _loot(effect: EffectType.heal, power: 12));

      expect(find.text('Cura le ferite'), findsOneWidget);
      expect(find.text('Cura: 12'), findsOneWidget);
      expect(find.byKey(const ValueKey('item-effect-l-1')), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Cura: 12')).dy,
        greaterThan(tester.getTopLeft(find.text('Cura le ferite')).dy),
      );
    });

    testWidgets('a zero power shows only the effect', (tester) async {
      await _pump(tester, _loot(effect: EffectType.heal, power: 0));

      expect(find.text('Cura'), findsOneWidget);
    });

    testWidgets('a loot item without effect shows no line', (tester) async {
      await _pump(tester, _loot(power: 12));

      expect(find.text('Cura le ferite'), findsOneWidget);
      expect(find.byKey(const ValueKey('item-effect-l-1')), findsNothing);
    });

    testWidgets('an equipment item shows no line', (tester) async {
      await _pump(tester, _helm);

      expect(find.text('Un elmo robusto'), findsOneWidget);
      expect(find.byKey(const ValueKey('item-effect-e-1')), findsNothing);
    });
  });

  group('injuries line', () {
    testWidgets('a heal item lists the injuries it cures under the effect', (
      tester,
    ) async {
      await _pump(
        tester,
        _loot(
          effect: EffectType.heal,
          power: 12,
          injuries: [InjuryType.blackEye, InjuryType.blindness],
        ),
      );

      expect(find.text('Cura: cecità, occhio nero'), findsOneWidget);
      expect(find.byKey(const ValueKey('item-injuries-l-1')), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Cura: cecità, occhio nero')).dy,
        greaterThan(tester.getTopLeft(find.text('Cura: 12')).dy),
      );
    });

    testWidgets('a heal item without injuries shows no injuries line', (
      tester,
    ) async {
      await _pump(tester, _loot(effect: EffectType.heal, power: 12));

      expect(find.byKey(const ValueKey('item-effect-l-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('item-injuries-l-1')), findsNothing);
    });
  });

  group('recovery line (BE Phase 18)', () {
    testWidgets(
      'a heal item with a recovery shows the Ricarica line under the Cura line (D-13)',
      (tester) async {
        await _pump(tester, _herbs);

        final recovery = find.byKey(const ValueKey('item-recovery-l-herb'));
        expect(tester.widget<Text>(recovery).data, 'Ricarica: 30 min');
        expect(
          _topOf(tester, 'item-recovery-l-herb'),
          greaterThan(_topOf(tester, 'item-injuries-l-herb')),
        );
      },
    );

    testWidgets('no Ricarica line without a recovery (D-13)', (tester) async {
      await _pump(tester, LootItem.fromJson(healPotionJson(recovery: null)));

      expect(
        find.byKey(const ValueKey('item-injuries-l-herb')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('item-recovery-l-herb')), findsNothing);
    });

    testWidgets('an equipment row has no Ricarica line (D-13)', (tester) async {
      await _pump(tester, _helm);

      expect(find.byKey(const ValueKey('item-recovery-e-1')), findsNothing);
    });
  });

  group('disabled row (BE Phase 18)', () {
    testWidgets(
      'an enabled row is fully opaque and has no status line (D-12)',
      (tester) async {
        await _pump(tester, _herbs);

        expect(_cardOpacity(tester), 1);
        expect(find.byKey(const ValueKey('item-status-l-herb')), findsNothing);
      },
    );

    testWidgets('a disabled row dims its card (D-12)', (tester) async {
      await _pump(tester, _herbs, isDisabled: true);

      expect(_cardOpacity(tester), KlimmeckGuideTheme.pendingInkOpacity);
    });

    testWidgets('the status line is shown under the other lines (D-12)', (
      tester,
    ) async {
      await _pump(tester, _herbs, statusLine: 'pronta fra 1 h 12 min');

      final status = find.byKey(const ValueKey('item-status-l-herb'));
      expect(tester.widget<Text>(status).data, 'pronta fra 1 h 12 min');
      expect(
        _topOf(tester, 'item-status-l-herb'),
        greaterThan(_topOf(tester, 'item-recovery-l-herb')),
      );
    });

    testWidgets('a row without onSelect ignores the tap (D-12)', (
      tester,
    ) async {
      await _pump(
        tester,
        _herbs,
        isDisabled: true,
        statusLine: 'pronta fra 1 h 12 min',
      );

      await tester.tap(find.byKey(const ValueKey('l-herb')));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(_cardOpacity(tester), KlimmeckGuideTheme.pendingInkOpacity);
    });
  });
}
