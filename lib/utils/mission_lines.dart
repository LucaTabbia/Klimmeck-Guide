import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/utils/game_duration_format.dart';

/// Etichetta sopra la pedina (solo flusso guidato, D-16) e riga di stato delle
/// azioni bloccate del Diario (ogni missione in corso) — copy D-30.
const String missionInProgressLabel = 'Missione in corso';

/// Etichetta della «Fase di ricerca» di una quest col sorteggio (D-26, D-32).
const String spellResearchLabel = 'Ricercando…';

/// Foglio sulla mappa durante la parte di apprendimento (D-26): una riga corta.
const String spellLearningPaperLabel = 'Apprendimento…';

/// Riga della parte di apprendimento (D-29): la magia servita e il tempo che
/// manca; senza nome leggibile «una magia», senza tempo solo i puntini.
String spellLearningLine(String? spellName, Duration? remaining) {
  final name = spellName?.trim() ?? '';
  final subject = name.isEmpty ? 'Imparando una magia' : 'Imparando «$name»';
  if (remaining == null || remaining <= Duration.zero) return '$subject…';
  return '$subject: ${formatGameDuration(remaining)}';
}

/// Cosa sta facendo il personaggio durante una missione che si risolve da sola,
/// sopra la pedina (UAT 2026-11-14); le tre scuole sono la «Fase di ricerca»
/// (D-26); `null` per story e worldMission, che hanno «Missione in corso», e
/// per un tipo ignoto.
String? missionActivityLabelOf(QuestType? type) => switch (type) {
  QuestType.hunt => 'Cacciando…',
  QuestType.aid => 'Soccorrendo…',
  QuestType.enemy || QuestType.boss => 'Combattendo…',
  QuestType.dungeon => 'Esplorando…',
  QuestType.study => 'Studiando…',
  QuestType.arcane ||
  QuestType.shamanic ||
  QuestType.theVoid => spellResearchLabel,
  QuestType.heal => 'In cura…',
  QuestType.job => 'Lavorando…',
  QuestType.crime => 'Tramando…',
  QuestType.guard => 'Di guardia…',
  QuestType.worldMission || QuestType.story || null => null,
};

/// Descrizione del banner di ogni azione rifiutata con MISSION_IN_PROGRESS
/// (D-30); il titolo resta quello dell'azione.
const String missionInProgressRefusalLine =
    "Sei impegnato in una missione: aspetta l'esito";
