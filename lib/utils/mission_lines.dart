import 'package:klimmeck_guide/models/enums/quest_type.dart';

/// Etichetta sopra la pedina (solo flusso guidato, D-16) e riga di stato delle
/// azioni bloccate del Diario (ogni missione in corso) — copy D-30.
const String missionInProgressLabel = 'Missione in corso';

/// Cosa sta facendo il personaggio durante una missione che si risolve da sola,
/// sopra la pedina (UAT 2026-11-14); `null` per story e worldMission, che
/// hanno «Missione in corso», e per un tipo ignoto.
String? missionActivityLabelOf(QuestType? type) => switch (type) {
  QuestType.hunt => 'Cacciando…',
  QuestType.aid => 'Soccorrendo…',
  QuestType.enemy || QuestType.boss => 'Combattendo…',
  QuestType.dungeon => 'Esplorando…',
  QuestType.study || QuestType.magic => 'Studiando…',
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
