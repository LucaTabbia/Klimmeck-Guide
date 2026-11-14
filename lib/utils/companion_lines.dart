/// Testi del compagno: Diario, scheda dettagli, foglio pozioni e richiesta del
/// nome. Ogni durata passa da [formatGameDuration] (Phase 18 D-17).
library;

import 'package:klimmeck_guide/models/companion/companion_vitality.dart';
import 'package:klimmeck_guide/utils/game_duration_format.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

const String companionNameFieldLabel = 'Nome';
const String companionNameConfirmLabel = 'Chiamalo così';
const String companionNameSkipLabel = 'Più tardi';

/// Null senza un massimo servito positivo (D-09).
String? companionLifeLine(int life, int? maxLifePoints) {
  if (maxLifePoints == null || maxLifePoints <= 0) return null;
  return 'Vita: $life / $maxLifePoints';
}

String companionRestingLine(Duration remaining) =>
    'A riposo: in forze fra ${formatGameDuration(remaining)}';

String companionDefeatedLine(Duration remaining) =>
    'Sconfitto: torna fra ${formatGameDuration(remaining)}';

/// Riga di stato sotto la vita: nessuna quando il compagno è in forze (D-09).
String? companionStatusLine(CompanionVitality vitality) => switch (vitality) {
  CompanionResting(:final remaining) => companionRestingLine(remaining),
  CompanionDefeated(:final remaining) => companionDefeatedLine(remaining),
  CompanionSteady() => null,
};

String companionPotionWaitLine(Duration remaining) =>
    'Pozione: ${potionReadyInLine(remaining)}';

/// Tempo servito dal minimo alla vita piena, solo da leggere (D-01).
String? companionRecoveryTimeLine(Duration? recovery) {
  if (recovery == null) return null;
  return 'Recupero completo: ${formatGameDuration(recovery)}';
}

String giveToCompanionLabel(String name) => 'Dai a $name';

String companionNamePromptTitle(String species) =>
    'Come chiamerai il tuo $species?';

String renameCompanionLabel({required bool hasName}) =>
    hasName ? 'Cambia nome' : 'Dai un nome';
