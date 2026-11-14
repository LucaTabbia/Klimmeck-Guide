---
phase: 21-innkeeper-mission-completion-flow
plan: 04
subsystem: players-lock
tags: [mission-lock, board, quest-availability, satchel, map-pawn]
requires: ["21-03"]
provides:
  - "QuestViewer.isOnMission (default false; QuestViewer.of reads CharacterStatus.missionInProgress)"
  - "QuestAvailability.missionInProgress, last blocking reason (after noEffect), torn sheet"
  - "questMissionInProgressLine = \"Missione in corso: aspetta l'esito\" (lib/models/quest/quest_blocked_reason.dart)"
  - "disabledSatchelPages(isOnMission) closes the Shop only"
  - "CharacterMarkerLayer.missionLabelKey (ValueKey('map.missionLabel')); drag gate on missionInProgress, label on guidedMissionInProgress"
affects: [21-05, 21-16]
tech-stack:
  added: []
  patterns: ["prison precedent (quick 261110-cgd): viewer flag + availability value + Board line + satchel input + PawnLabel"]
key-files:
  created: []
  modified:
    - lib/models/quest/quest_viewer.dart
    - lib/models/quest/quest_availability.dart
    - lib/models/quest/quest_blocked_reason.dart
    - lib/screens/mainScreen/components/satchel_availability.dart
    - lib/screens/mainScreen/main_screen.dart
    - lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart
    - test/models/quest/quest_availability_test.dart
    - test/models/quest/quest_blocked_reason_test.dart
    - test/helpers/fixtures/quest_fixtures.dart
    - test/screens/mainScreen/components/satchel_availability_test.dart
    - test/screens/mainScreen/tabs/map/character_marker_layer_test.dart
    - test/helpers/fixtures/travel_fixtures.dart
decisions:
  - "The mission line is the last check of _availabilityOf (after noEffect), so every existing reason keeps its precedence (D-23)"
  - "During a mission the satchel closes only the Shop; travel / aid / prison / off-city still close Board and Shop"
metrics:
  completed: 2026-11-14
  tasks: 3
  files: 12
---

# Phase 21 Plan 04: Players' lock on the Board, the Map pawn and the satchel Summary

During any mission in progress (served `CharacterStatus.missionInProgress`) every quest on the Board is refused with a torn sheet and the line «Missione in corso: aspetta l'esito», the satchel Shop page closes (the Board stays readable), and the Map pawn cannot be dragged; during the innkeeper's guided flow only (`guidedMissionInProgress`) the pawn shows the in-world label «Missione in corso» (D-11, D-13, D-16, D-23, D-30). Nothing is derived from lanes or quests.

## Commits

| Task | Commit | Subject |
|------|--------|---------|
| 1 RED | e72e61b7 | test(quests): expect the mission line on every quest |
| 1 GREEN | b12d5e0a | feat(quests): block every acceptance during a mission |
| 2 RED | 6c9ae8db | test(map): expect the mission lock on the pawn and the shop |
| 2 GREEN | 9e5d49b8 | feat(map): lock the pawn and the shop during a mission |

## RED evidence

- Task 1: `flutter test test/models/quest` failed at compile time — `No named parameter with the name 'isOnMission'` (quest_fixtures.dart), `Member not found: 'missionInProgress'`, `The getter 'isOnMission' isn't defined for the type 'QuestViewer'` (+56 -10).
- Task 2: `flutter test` of satchel_availability_test + character_marker_layer_test failed at compile time — `No named parameter with the name 'isOnMission'`, `Member not found: 'missionLabelKey'`.

## Tests

- `flutter test test/models/quest test/screens/mainScreen/tabs/board test/shared/components/popup` → +515 all green.
- `flutter test test/screens/mainScreen test/models/quest` → +1501 all green.
- New titled cases: group `mission in progress (Phase 21)` in quest_availability_test (7 cases: every type D-13, owner D-13, prison D-23, busy lane D-23, existing reasons D-23, torn D-13, `QuestViewer.of` D-16), the D-30 line in quest_blocked_reason_test, two D-11 cases in satchel_availability_test, three D-16 cases in character_marker_layer_test. The torn-sheet table in quest_availability_test gained `missionInProgress: (true, true)` (it pins every value).
- The "every type" test also asserts each quest is `available` without the mission, so the mission value is the only cause.

## Extra `QuestAvailability` sites

`grep -rn "QuestAvailability\.imprisoned" lib`: only `quest_availability.dart` (enum, `isSheetTorn`, `_availabilityOf`), `quest_blocked_reason.dart` (switch arm) and `quest_sheet_details.dart:107` (`isImprisoned`, prison-only by design — unchanged). No other site lists the blocked states.

## Format and analyzer

All 12 touched files were formatter-clean before the change; each was formatted one by one after it (no change except a record literal in `main_screen.dart` the formatter expanded). Analyzer: `47 issues found` (47 info / 0 warning / 0 error), `ANALYZE_GATE_OK` after both code tasks.

## Deviations from Plan

None in behaviour. Notes:
- `travellingCharacterJson` writes the new flags with `if (x != null)` (the style already used in that fixture) instead of the null-aware element `?x` mentioned as an example.
- The pawn label key carries a doc line («Solo durante il flusso guidato della Locanda (FE Phase 21 D-16).»).

## Known Stubs

None. The two status flags are not yet selected in `CharacterFragment` (gated plan 21-16, by design — Pitfall 2), so on today's BE they stay `false` and nothing locks.

## Self-Check: PASSED

- Commits e72e61b7, b12d5e0a, 6c9ae8db, 9e5d49b8 present on `feat/21-innkeeper-mission-completion`.
- All modified files exist; `git diff HEAD~2 -- lib` adds no AppBar / AlertDialog / CircularProgressIndicator.
