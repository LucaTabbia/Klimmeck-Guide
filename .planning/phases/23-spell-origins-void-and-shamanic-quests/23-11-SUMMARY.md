---
phase: 23-spell-origins-void-and-shamanic-quests
plan: 11
subsystem: quests
tags: [research, learning, copy, countdown, cubit]
requires: ["23-10"]
provides:
  - "isSpellResearchQuest(QuestType?, QuestPrizes?) in lib/models/quest/spell_research.dart"
  - "spellResearchLabel ('Ricercando…', D-32), spellLearningPaperLabel ('Apprendimento…'), spellLearningLine(name, remaining) in lib/utils/mission_lines.dart"
  - "questStateLabel: travelling > waiting > learning («Apprendimento…») > research («Ricercando…») > per-type switch"
  - "missionActivityLabelOf: the three school types read «Ricercando…»; study keeps «Studiando…»"
  - "SpellLearningCubit / SpellLearningState(remaining) on ServerDeadlineCountdown (not wired yet)"
affects: [23-12, 23-13, 23-08]
tech-stack:
  added: []
  patterns: ["countdown cubit on ServerDeadlineCountdown, shape of PrisonCubit"]
key-files:
  created:
    - lib/models/quest/spell_research.dart
    - lib/screens/mainScreen/tabs/map/spellLearningCubit/spell_learning_cubit.dart
    - lib/screens/mainScreen/tabs/map/spellLearningCubit/spell_learning_state.dart
    - test/models/quest/spell_research_test.dart
    - test/screens/mainScreen/tabs/map/spellLearningCubit/spell_learning_cubit_test.dart
  modified:
    - lib/utils/mission_lines.dart
    - lib/models/quest/quest_state_label.dart
    - test/utils/mission_lines_test.dart
    - test/models/quest/quest_state_label_test.dart
    - test/screens/mainScreen/tabs/map/quest_paper_layer_test.dart
decisions:
  - "D-32 applied: the research label is «Ricercando…» (U+2026), not «Fase di ricerca» (the name of the part)"
  - "The learning label wins over the research label on the paper; travelling and waiting win over both"
  - "SpellLearningCubit exposes only follow(DateTime? endsAt); it never reads requiredLearnTime nor DateTime.now"
metrics:
  duration: "~25 min"
  completed: 2026-11-16
---

# Phase 23 Plan 11: Research and learning copy rules, learning countdown cubit Summary

The pure rule that tells a draw quest, the copy of its two parts and the cubit that counts down the learning part. The Map paper and the quest overlay follow `questStateLabel` by themselves; the pawn follows `missionActivityLabelOf` by type. Nothing else is wired (23-12).

## Copy (for the UAT «Copy and visuals to review» of 23-08)

| Where | Text |
|-------|------|
| Map paper, quest overlay, pawn (school types) during the research part | `Ricercando…` |
| Map paper during the learning part | `Apprendimento…` |
| Learning line (pawn and overlay, wired in 23-12) | `Imparando «Dardo»: 28 min` · `Imparando «Dardo»: 1 h 30 min` · `Imparando «Dardo»…` (no time left) · `Imparando una magia: 28 min` / `Imparando una magia…` (no readable name) |
| `study` quest without a draw | `Studiando…` (unchanged) |

The duration goes through `formatGameDuration` (Phase 18 D-17).

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect the research and learning labels | 37631215 |
| 1 GREEN | Label the research and learning parts | ce6d7bbc |
| 2 RED | Expect the learning countdown cubit | a17bd051 |
| 2 GREEN | Count down the learning part | ace5c130 |
| 3 | Bookkeeping | (this docs commit) |

## RED failures

- `spell_research_test.dart`: `Error when reading 'lib/models/quest/spell_research.dart': No such file or directory` (expected compile failure).
- `mission_lines_test.dart`: `Undefined name 'spellResearchLabel'`, `'spellLearningPaperLabel'`, `Method not found: 'spellLearningLine'` (expected compile failure).
- `quest_state_label_test.dart`: `a started school quest reads the research part (D-26, D-32)`, `a started study quest reads the research part only with a spell draw (D-26)`, `the learning part reads its own label and wins over the research (D-26)` — `Actual: 'Studiando…'`.
- `quest_paper_layer_test.dart`: `Found 0 widgets with text "Ricercando…"`.
- `spell_learning_cubit_test.dart`: `Error when reading '…/spell_learning_cubit.dart': No such file or directory` (expected compile failure).

Green at the first run: `travelling and waiting win over the parts (D-26)` (the travelling / waiting checks already came first; the case pins that the new checks sit after them).

## Pins rewritten

- `test/utils/mission_lines_test.dart` table: arcane / shamanic / theVoid → `'Ricercando…'`.
- `test/models/quest/quest_state_label_test.dart`: the two old cases «a started arcane quest reads like a study (quick 261110-mag, D-20)» and «a started rite reads like a study (D-09, Pitfall 3)» replaced by the D-26 cases.
- `test/screens/mainScreen/tabs/map/quest_paper_layer_test.dart:115` retitled «… and reads Ricercando (D-14, D-26, D-32)».
- `character_marker_layer_test.dart`: no case pinned «Studiando…» for a school type; nothing to rewrite (36 green).

## Verification

- `flutter test test/models/quest test/utils test/screens/mainScreen/tabs/map`: `+814: All tests passed!`; cubit test `+7`.
- `grep -rn "'Ricercando…'" lib` → one line, `lib/utils/mission_lines.dart:9`.
- Analyzer `47 issues found`, `ANALYZE_GATE_OK`.
- Full suite: `+5138: All tests passed!`.

## Deviations from Plan

1. **D-32 (user copy decision relayed by the orchestrator during 23-09):** every `'Fase di ricerca'` literal of the plan is `'Ricercando…'` (constant `spellResearchLabel`); the acceptance grep was run on `'Ricercando…'`. Test titles carry `D-32` next to `D-26`. The plan texts were already rewritten in the 23-09 docs commit.
2. Added a pin `spellLearningPaperLabel == 'Apprendimento…'` and, in the «travelling and waiting» case, a waiting party on a `study` quest with the draw (still «In attesa del gruppo …»).

## Notes for 23-12

- The pawn label comes from `missionActivityLabelOf(type)`, by type only: a `study` quest with `prizes.spellDraw` still reads «Studiando…» above the pawn, and a school quest in its learning part still reads «Ricercando…» there. 23-12 must ask `lane.isLearning` first (then `spellLearningLine(lane.learningSpell?.name, SpellLearningCubit.state.remaining)`) and `isSpellResearchQuest(type, boardQuest?.prizes)` before the per-type label.
- `SpellLearningCubit.follow(lane.learningEndsAt)` is the only input; it emits `null` at or after the end and when not learning.
- The quest overlay (`world_map.dart` `stateLabel`) already reads «Ricercando…» / «Apprendimento…» through `questStateLabel`; the full learning line there is 23-12's job.
- Until 23-14 selects `prizes { spellDraw }` and `learningSpell`, only the school types change label on a real BE.

## Known Stubs

- `SpellLearningCubit` is not provided nor wired anywhere yet: intentional, wired by 23-12.

## Self-Check: PASSED

- Files created exist; commits 37631215, ce6d7bbc, a17bd051, ace5c130 present in `git log`.
