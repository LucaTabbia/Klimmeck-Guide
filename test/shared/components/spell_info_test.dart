import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spell_recovery_status.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/spell_info.dart';

import '../../helpers/fixtures/spell_fixtures.dart';
import '../../helpers/svg_cache_seed.dart';
import '../../helpers/test_app.dart';

final _fireDart = Spell.fromJson(spellJson());

const _blankSpell = Spell(
  id: 'spell-blank',
  name: null,
  description: null,
  useType: null,
  energyDamage: null,
  requiredLearnTime: null,
  minXpToLearn: null,
  recoveryTime: null,
  maxUsages: null,
);

Future<void> _pump(
  WidgetTester tester,
  Spell spell, {
  required int? usages,
  required SpellRecoveryStatus recovery,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: SpellInfo(spell: spell, usages: usages, recovery: recovery),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(
    () =>
        seedSvgCache([CloudinaryAssets.fireEnergy, CloudinaryAssets.attackUse]),
  );

  testWidgets('shows every detail of a recovering spell', (tester) async {
    await _pump(
      tester,
      _fireDart,
      usages: 1,
      recovery: const SpellRecoveryCountdown(remainingMinutes: 12),
    );

    expect(find.text('Dardo di fuoco'), findsOneWidget);
    expect(find.text('Un dardo che brucia il bersaglio'), findsOneWidget);
    expect(find.text('Attacco: Fuoco 12'), findsOneWidget);
    expect(find.text('Uso: Attacco'), findsOneWidget);
    expect(find.text('Usi massimi: 3'), findsOneWidget);
    expect(find.text('Recupero: 2 h'), findsOneWidget);
    expect(find.text('Per impararla: 100 XP · 1 h di studio'), findsOneWidget);
    expect(find.text('Usi: 1/3 · prossimo tra 12 min'), findsOneWidget);
    expect(find.byType(CachedSvg), findsNWidgets(2));
  });

  testWidgets('a full spell shows only its usages as current line', (
    tester,
  ) async {
    await _pump(
      tester,
      _fireDart,
      usages: 3,
      recovery: const SpellRecoveryFull(),
    );

    expect(find.text('Usi: 3'), findsOneWidget);
    expect(find.textContaining('prossimo tra'), findsNothing);
  });

  testWidgets('partial catalog data renders without the missing lines', (
    tester,
  ) async {
    await _pump(
      tester,
      _blankSpell,
      usages: null,
      recovery: const SpellRecoveryFull(),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SpellInfo), findsOneWidget);
    expect(find.byType(CachedSvg), findsNothing);
    expect(find.textContaining('Danno'), findsNothing);
    expect(find.textContaining('Uso'), findsNothing);
    expect(find.textContaining('Recupero'), findsNothing);
    expect(find.textContaining('Per impararla'), findsNothing);
  });
}
