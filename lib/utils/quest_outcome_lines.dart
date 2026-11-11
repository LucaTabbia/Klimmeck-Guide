import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/quest_result/quest_outcome.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';

// Copy provvisoria (quick 261110-cgd): righe del foglio esiti per l'arresto
// della crime e lo scontro della guard. Il FE non ricava nulla: la durata
// della prigione arriva dallo stato, le monete raddoppiate sono già nei premi.

const String confiscatedCoinsTitle = 'Monete confiscate';

/// «Sei stato arrestato.» per un arresto; nessuna durata scritta a mano.
String? arrestLine(QuestResult result) =>
    result.arrested ? 'Sei stato arrestato.' : null;

/// Monete confiscate dal server con l'arresto; `null` se assenti o zero.
Coins? confiscatedCoinsOf(QuestResult result) {
  final coins = result.coinsLost;
  if (!result.arrested || coins == null || coins.toCopper() <= 0) return null;
  return coins;
}

/// Esito dello scontro alla fine di una guard; nessuna riga senza scontro.
String? guardEncounterLine(QuestResult result) {
  if (!result.guardEncounter) return null;
  return switch (result.outcome) {
    QuestOutcome.success =>
      'Scontro durante la guardia: vittoria, paga raddoppiata',
    QuestOutcome.failure => 'Scontro durante la guardia: sconfitta',
    _ => null,
  };
}
