import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/enums/dungeon_turn_kind.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
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

/// «Il tuo compagno guadagna N PE» (D-03): il numero servito dal backend,
/// nessuna riga a zero.
String? companionXpGainedLine(int petXpGained) =>
    petXpGained > 0 ? 'Il tuo compagno guadagna $petXpGained PE' : null;

/// Riga dei turni di una dungeon o di un'aid di dungeon (D-21): stampa i
/// numeri del BE così come arrivano, mai un turno in più né una quota.
/// `null` senza turni: il foglio ripiega sulla riga delle tappe (D-24).
String? dungeonTurnLine(QuestResult result) {
  final total = result.turnsTotal;
  if (total == null || total <= 0) return null;
  final last = result.lastTurn;
  return switch (result.outcome) {
    QuestOutcome.success when _isAid(result) && last != null =>
      'Soccorso effettuato al raggiungimento del $last° piano su $total',
    QuestOutcome.success => _completedTurnsLine(result, total),
    QuestOutcome.failure when last != null =>
      'Caduto al $last° piano su $total${_turnKindSuffix(result.lastTurnKind)}',
    QuestOutcome.failure => _completedTurnsLine(result, total),
    QuestOutcome.rescued ||
    QuestOutcome.death ||
    QuestOutcome.gmCompleted => null,
  };
}

String _completedTurnsLine(QuestResult result, int total) =>
    'Piani superati: ${result.turnsCompleted ?? 0} su $total';

bool _isAid(QuestResult result) => result.quest?.type == QuestType.aid;

String _turnKindSuffix(DungeonTurnKind? kind) => switch (kind) {
  DungeonTurnKind.exploration => ', in esplorazione',
  DungeonTurnKind.fight => ', in uno scontro',
  null => '',
};
