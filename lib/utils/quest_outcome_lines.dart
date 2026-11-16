import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/enums/dungeon_turn_kind.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/quest_result/quest_companion_outcome.dart';
import 'package:klimmeck_guide/models/quest_result/quest_outcome.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/utils/game_duration_format.dart';

// Copy provvisoria (quick 261110-cgd): righe del foglio esiti per l'arresto
// della crime e lo scontro della guard. Il FE non ricava nulla: la durata
// della prigione arriva dallo stato, le monete raddoppiate sono già nei premi.
// Righe della «Fase di ricerca» (Phase 23 D-29, D-31): magia scoperta, tempo
// di apprendimento, ricerca senza esito.

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

/// «Il tuo compagno guadagna N PE» (D-03), «Fenrir guadagna N PE» quando
/// l'esito serve il nome (D-20, D-27): il numero servito dal backend, nessuna
/// riga a zero.
String? companionXpGainedLine(int petXpGained, {String? name}) {
  if (petXpGained <= 0) return null;
  final subject = name == null || name.trim().isEmpty
      ? QuestCompanionOutcome.unnamedLabel
      : name.trim();
  return '$subject guadagna $petXpGained PE';
}

/// «Fenrir: 120 / 300 di vita» (D-10): solo se il compagno è sceso di vita
/// senza cadere.
String? companionFightLifeLine(QuestCompanionOutcome? companion) {
  if (companion == null || companion.isDefeated) return null;
  if (companion.lifePoints >= companion.lifeBefore) return null;
  return '${companion.name}: ${companion.lifePoints} / '
      '${companion.maxLifePoints} di vita';
}

/// Sconfitta del compagno (D-10, D-27): la durata è `fullLifeAt − resolvedAt`,
/// un fatto datato e mai contato da adesso (Pitfall 7). Senza una data utile
/// resta la sola sconfitta.
String? companionDefeatResultLine(
  QuestCompanionOutcome? companion,
  DateTime resolvedAt,
) {
  if (companion == null || !companion.isDefeated) return null;
  final defeat = '${companion.name} è stato sconfitto';
  final fullLifeAt = companion.fullLifeAt;
  if (fullLifeAt == null || !fullLifeAt.isAfter(resolvedAt)) return defeat;
  final rest = formatGameDuration(fullLifeAt.difference(resolvedAt));
  return '$defeat: riposa e tornerà fra $rest';
}

/// «Magia scoperta: Dardo» (D-31): il FE stampa il servito, non calcola.
String? spellFoundLine(QuestResult result) {
  final spell = result.spellFound;
  if (spell == null) return null;
  final name = spell.name?.trim() ?? '';
  return name.isEmpty ? 'Magia scoperta' : 'Magia scoperta: $name';
}

/// Durata dell'apprendimento della magia scoperta (D-31), da
/// `requiredLearnTime` in ms: il FE stampa il servito, non calcola.
String? spellLearningTimeLine(QuestResult result) {
  final milliseconds = result.spellFound?.requiredLearnTime;
  if (milliseconds == null || milliseconds <= 0) return null;
  return 'Tempo di apprendimento: '
      '${formatGameDuration(Duration(milliseconds: milliseconds))}';
}

/// Ricerca senza magia (D-29): il FE stampa il servito, non calcola.
String? spellResearchFailedLine(QuestResult result) =>
    result.spellResearchFailed
    ? 'La ricerca non ha rivelato alcuna magia'
    : null;

const String onFootLine = 'Prosegui a piedi';

/// [onFootLine] quando l'imboscata ha lasciato il personaggio senza
/// cavalcatura e il viaggio prosegue (D-28): chi è stato portato in una
/// città non cammina più.
String? onFootLineOf(QuestResult result) {
  final ambush = result.ambush;
  if (ambush == null || !ambush.isOnFoot) return null;
  return ambush.reachedCity == null ? onFootLine : null;
}

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
