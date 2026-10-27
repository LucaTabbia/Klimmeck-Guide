import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/use_type.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spell_recovery_status.dart';
import 'package:klimmeck_guide/utils/spell_lines.dart';

import '../helpers/fixtures/spell_fixtures.dart';

void main() {
  final spell = Spell.fromJson(spellJson());

  group('spellSummaryLine', () {
    String line({
      Spell? of,
      int? usages = 1,
      SpellRecoveryStatus recovery = const SpellRecoveryFull(),
    }) => spellSummaryLine(
      spell: of ?? spell,
      usages: usages,
      recovery: recovery,
    );

    test('full usages show the recovery time', () {
      expect(line(usages: 3), 'Usi: 3 · Recupero: 2 h · Danno: Fuoco 12');
    });

    test('below the maximum shows the countdown', () {
      expect(
        line(recovery: const SpellRecoveryCountdown(remainingMinutes: 12)),
        'Usi: 1/3 · prossimo tra 12 min · Danno: Fuoco 12',
      );
    });

    test('under one minute reads «meno di 1 min»', () {
      expect(
        line(recovery: const SpellRecoveryCountdown(remainingMinutes: 0)),
        'Usi: 1/3 · prossimo tra meno di 1 min · Danno: Fuoco 12',
      );
    });

    test('long countdowns use hours and minutes', () {
      expect(
        line(recovery: const SpellRecoveryCountdown(remainingMinutes: 150)),
        'Usi: 1/3 · prossimo tra 2 h 30 min · Danno: Fuoco 12',
      );
    });

    test('a passed instant reads «in arrivo…»', () {
      expect(
        line(recovery: const SpellRecoveryArriving()),
        'Usi: 1/3 · in arrivo… · Danno: Fuoco 12',
      );
    });

    test('no instants reads «in recupero»', () {
      expect(
        line(recovery: const SpellRecoveryUnknown()),
        'Usi: 1/3 · in recupero · Danno: Fuoco 12',
      );
    });

    test('zero power drops the number', () {
      expect(
        line(of: Spell.fromJson(spellJson(power: 0)), usages: 3),
        'Usi: 3 · Recupero: 2 h · Danno: Fuoco',
      );
    });

    test('no energy drops the damage item', () {
      expect(
        line(of: Spell.fromJson(spellJson(energy: null)), usages: 3),
        'Usi: 3 · Recupero: 2 h',
      );
    });

    test('no recovery time at full usages drops the recovery item', () {
      expect(
        line(of: Spell.fromJson(spellJson(recoveryTime: null)), usages: 3),
        'Usi: 3 · Danno: Fuoco 12',
      );
    });

    test('unknown maximum shows the bare usages', () {
      expect(
        line(of: Spell.fromJson(spellJson(maxUsages: null)), usages: 2),
        startsWith('Usi: 2 · '),
      );
    });

    test('unknown usages fall back to the maximum', () {
      expect(line(usages: null), startsWith('Usi: 3 · '));
    });

    test('unknown usages and maximum drop the usages item', () {
      expect(
        line(of: Spell.fromJson(spellJson(maxUsages: null)), usages: null),
        'Recupero: 2 h · Danno: Fuoco 12',
      );
    });
  });

  group('detail labels', () {
    test('spellUseTypeLabel', () {
      expect(spellUseTypeLabel(UseType.attack), 'Uso: Attacco');
      expect(spellUseTypeLabel(null), isNull);
    });

    test('spellMaxUsagesLabel', () {
      expect(spellMaxUsagesLabel(3), 'Usi massimi: 3');
      expect(spellMaxUsagesLabel(null), isNull);
    });

    test('spellRecoveryTimeLabel', () {
      expect(spellRecoveryTimeLabel(spell), 'Recupero: 2 h');
      expect(
        spellRecoveryTimeLabel(Spell.fromJson(spellJson(recoveryTime: null))),
        isNull,
      );
    });

    test('spellLearnLabel with XP and study time', () {
      expect(spellLearnLabel(spell), 'Per impararla: 100 XP · 1 h di studio');
    });

    test('spellLearnLabel with XP only', () {
      expect(
        spellLearnLabel(Spell.fromJson(spellJson(requiredLearnTime: null))),
        'Per impararla: 100 XP',
      );
    });

    test('spellLearnLabel with study time only', () {
      expect(
        spellLearnLabel(Spell.fromJson(spellJson(minXpToLearn: null))),
        'Per impararla: 1 h di studio',
      );
    });

    test('spellLearnLabel without requirements', () {
      expect(
        spellLearnLabel(
          Spell.fromJson(
            spellJson(minXpToLearn: null, requiredLearnTime: null),
          ),
        ),
        isNull,
      );
    });

    test('spellRecoveryLabel is null at full usages', () {
      expect(spellRecoveryLabel(const SpellRecoveryFull()), isNull);
    });
  });

  group('copy constants', () {
    test('empty-state lines', () {
      expect(noSpellSlotsLine, 'Nessuno slot per le magie: cresci di rango');
      expect(noKnownSpellsLine, 'Non hai ancora imparato nessuna magia');
    });
  });
}
