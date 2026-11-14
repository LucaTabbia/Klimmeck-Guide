import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/companion/companion_vitality.dart';
import 'package:klimmeck_guide/utils/companion_lines.dart';

void main() {
  test('life line «Vita: 40 / 100» (D-09)', () {
    expect(companionLifeLine(40, 100), 'Vita: 40 / 100');
    expect(companionLifeLine(40, null), isNull);
    expect(companionLifeLine(40, 0), isNull);
  });

  test('resting line «A riposo: in forze fra 1 h 20 min» (D-09)', () {
    expect(
      companionRestingLine(const Duration(minutes: 80)),
      'A riposo: in forze fra 1 h 20 min',
    );
  });

  test('defeated line «Sconfitto: torna fra 3 h» (D-09)', () {
    expect(
      companionDefeatedLine(const Duration(hours: 3)),
      'Sconfitto: torna fra 3 h',
    );
  });

  test('status line follows the vitality (D-09)', () {
    expect(
      companionStatusLine(
        const CompanionResting(
          life: 40,
          maxLifePoints: 100,
          remaining: Duration(minutes: 80),
        ),
      ),
      'A riposo: in forze fra 1 h 20 min',
    );
    expect(
      companionStatusLine(
        const CompanionDefeated(
          life: 1,
          maxLifePoints: 100,
          remaining: Duration(hours: 3),
        ),
      ),
      'Sconfitto: torna fra 3 h',
    );
    expect(
      companionStatusLine(const CompanionSteady(life: 100, maxLifePoints: 100)),
      isNull,
    );
  });

  test('potion wait line «Pozione: pronta fra 20 min» (D-05)', () {
    expect(
      companionPotionWaitLine(const Duration(minutes: 20)),
      'Pozione: pronta fra 20 min',
    );
  });

  test('recovery time line «Recupero completo: 10 h» (D-01)', () {
    expect(
      companionRecoveryTimeLine(const Duration(hours: 10)),
      'Recupero completo: 10 h',
    );
    expect(companionRecoveryTimeLine(null), isNull);
  });

  test('give label «Dai a Fenrir» (D-08, D-20)', () {
    expect(giveToCompanionLabel('Fenrir'), 'Dai a Fenrir');
  });

  test('prompt title «Come chiamerai il tuo Worg?» (D-18)', () {
    expect(companionNamePromptTitle('Worg'), 'Come chiamerai il tuo Worg?');
    expect(companionNameFieldLabel, 'Nome');
  });

  test('without a species the prompt reads «Come chiamerai il tuo '
      'compagno?» (D-18)', () {
    for (final species in ['', '   ']) {
      expect(
        companionNamePromptTitle(species),
        'Come chiamerai il tuo compagno?',
        reason: '«$species»',
      );
    }
  });

  test('rename label «Dai un nome» / «Cambia nome» (D-19)', () {
    expect(renameCompanionLabel(hasName: false), 'Dai un nome');
    expect(renameCompanionLabel(hasName: true), 'Cambia nome');
  });

  test('prompt actions «Chiamalo così» and «Più tardi» (D-18)', () {
    expect(companionNameConfirmLabel, 'Chiamalo così');
    expect(companionNameSkipLabel, 'Più tardi');
  });

  test('level line «Livello 3» (D-37)', () {
    expect(companionLevelLine(3), 'Livello 3');
    expect(companionLevelLine(null), isNull);
  });

  test('species and level «Worg · Livello 3», species alone without level '
      '(D-37)', () {
    expect(companionSpeciesLevelLine('Worg', 3), 'Worg · Livello 3');
    expect(companionSpeciesLevelLine('Worg', null), 'Worg');
  });
}
