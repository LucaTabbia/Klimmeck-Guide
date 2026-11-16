---
phase: 23-spell-origins-void-and-shamanic-quests
plan: 13
subsystem: notifications
tags: [research, result-sheet, push, banner, dedup]
requires: ["23-12"]
provides:
  - "spellFoundLine, spellLearningTimeLine, spellResearchFailedLine, spellLearnTimeOf in lib/utils/quest_outcome_lines.dart"
  - "QuestResultSheet.spellFoundKey / spellLearningTimeKey / spellResearchFailedKey; no life bar when result.isLearningEnd"
  - "NotificationCategory.alsoAcceptedWireTypes (was legacyWireTypes); questEnd accepts spellResearchSucceeded and spellResearchFailed"
  - "questEndEventOf: banner copy by research outcome (Ricerca riuscita / Ricerca conclusa / Missione conclusa)"
affects: [23-14, 23-08]
tech-stack:
  added: []
  patterns: ["one category accepting several wire types: same toggle, tap and dedup key"]
key-files:
  created: []
  modified:
    - lib/utils/quest_outcome_lines.dart
    - lib/shared/components/popup/quest_result_sheet.dart
    - lib/models/notification_category.dart
    - lib/models/quest_result/quest_end_event.dart
    - test/utils/quest_outcome_lines_test.dart
    - test/shared/components/popup/quest_result_sheet_test.dart
    - test/models/notification_category_test.dart
    - test/models/push_event_test.dart
    - test/models/quest_result/quest_end_event_test.dart
    - test/repository/services/push/data_message_handler_test.dart
decisions:
  - "No new notification category: the two research pushes are accepted wire types of questEnd (planner choice 1, not vetoed)"
  - "legacyWireTypes renamed alsoAcceptedWireTypes (it now holds current types too)"
  - "The result sheet stays text: «Magia scoperta» is a line, not a spell card"
  - "One pure formatter spellLearnTimeOf(Spell?) for the sheet line and the banner (Boy Scout, no duplicated ms > 0 rule)"
metrics:
  duration: "~30 min"
  completed: 2026-11-16
---

# Phase 23 Plan 13: Research result sheets and research pushes as quest ends Summary

The research outcome reaches the player: the sheet of a research with a spell found names the spell and its learning time, a failed research says so, the small sheet at the end of the learning shows only the spell and its lore (no life bar); the pushes `spellResearchSucceeded` and `spellResearchFailed` notify, dedup and open the sheet exactly like `questEnd`; the in-session banner carries the same news as the push.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect the research lines on the result sheet | 23181135 |
| 1 GREEN | Show the research outcome on the result sheet | ad080a89 |
| 2 RED | Expect the research pushes as quest ends | 02993755 |
| 2 GREEN | Open the result from the research pushes | 640a93b0 |
| 3 | Bookkeeping | (this docs commit) |

## RED failures

- `quest_outcome_lines_test.dart`: `Method not found: 'spellFoundLine'` / `'spellLearningTimeLine'` / `'spellResearchFailedLine'` and the missing sheet keys (expected compile failure).
- `notification_category_test.dart`: «the research pushes are quest ends» — `fromWireType` returned null.
- `push_event_test.dart`: both research cases — `tryParse` returned null (push dropped).
- `data_message_handler_test.dart`: «a research push follows the quest end toggle» — nothing shown (type unknown).
- `quest_end_event_test.dart`: the three research cases — generic copy «Missione conclusa».

Learning-end sheet: after the GREEN only the life bar needed a rule (`_result.isLearningEnd`); rewards, experience, level, title, injuries, consumables, spells used and enemies already vanish when empty. No other block was fixed.

## Copy (for the UAT copy review of 23-08)

| Where | Text |
|-------|------|
| Result sheet, spell found | `Magia scoperta: Dardo` (no readable name: `Magia scoperta`) |
| Result sheet, learning time | `Tempo di apprendimento: 30 min` · `Tempo di apprendimento: 12 h` (absent without a positive `requiredLearnTime`) |
| Result sheet, failed research | `La ricerca non ha rivelato alcuna magia` |
| Learning-end sheet | `Magia appresa: Dardo` + the lore lines (unchanged copy) |
| Banner, spell found | title `Ricerca riuscita`, body `Hai scoperto «Dardo»: l'apprendimento dura 30 min.` · without a valid time `Hai scoperto «Dardo».` · without a name `Hai scoperto una magia: l'apprendimento dura 30 min.` |
| Banner, failed research | title `Ricerca conclusa`, body `Nessuna magia scoperta: scopri com'è andata la missione.` |
| Banner, any other result | `Missione conclusa` / `La tua missione è terminata: scopri com'è andata.` (unchanged) |

Durations go through `formatGameDuration` («30 min»), while the BE push says «30 minuti»: whichever arrives first is shown (dedup), as accepted by the plan.

## Push behaviour

| Wire type | Category | Toggle | Tap | Dedup key |
|-----------|----------|--------|-----|-----------|
| `questEnd` | `questEnd` | «Fine quest» | opens the result `id` | `questEnd\|<id>` |
| `spellResearchSucceeded` | `questEnd` | «Fine quest» | opens the result `id` | `questEnd\|<id>` |
| `spellResearchFailed` | `questEnd` | «Fine quest» | opens the result `id` | `questEnd\|<id>` |
| `ambushDefeat` (legacy) | `ambush` | unchanged | unchanged | `ambush\|<id>` |
| unknown (e.g. `spellResearch`) | — | — | dropped («Push dropped: unknown or malformed message») | — |

Title and body of a push are the served strings; the banner published by `questResultReceived` uses `questEndEventOf` and shares the key `questEnd|<result id>`, so a result never shows two banners. `notification_popup_registry.dart`, the settings section and the preferences store are untouched (no new category); no file under `lib/screens` or `lib/repository` changed in Task 2.

## Verification

- Task 1: `flutter test test/shared/components/popup test/utils test/screens/mainScreen/components` → `+631: All tests passed!`.
- Task 2: `flutter test test/models test/utils test/shared/components/popup test/repository/services/push test/screens/mainScreen/components test/screens/auth test/screens/mainScreen/tabs/settings` → `+2140: All tests passed!`.
- Acceptance greps: the three line functions 3 times and `isLearningEnd` once in `quest_result_sheet.dart`, `Magia scoperta` 0 there; `D-31` 3 in the sheet test; `legacyWireTypes` nowhere in `lib` / `test`; `spellResearchSucceeded` 2 and `spellResearchFailed` 2 in `notification_category.dart`; `Ricerca riuscita` 1 in `quest_end_event.dart`; `git show --name-only HEAD HEAD~1 | grep -E "^lib/(screens|repository)/"` empty.
- Analyzer `47 issues found`, `ANALYZE_GATE_OK`.
- Full suite: `+5161: All tests passed!` (5146 + 15).

## Deviations from Plan

1. **[Boy Scout] One learn-time formatter.** The plan put the `requiredLearnTime > 0 → formatGameDuration` rule both in `spellLearningTimeLine` and in a private `_spellFoundBody`. A public pure `spellLearnTimeOf(Spell?)` in `quest_outcome_lines.dart` now serves both (added in the Task 2 GREEN commit, together with the refactor of `spellLearningTimeLine`); `quest_end_event.dart` imports it instead of `game_duration_format.dart`.
2. **[Test shape] Toggle case.** «a research push follows the quest end toggle» first handles the push with the default (enabled) toggle — one notification with the served title — then disables `questEnd` and handles it again — still one. The harness has no `enable` helper; the default is enabled.
3. One analyzer info (`curly_braces_in_flow_control_structures`) appeared during the GREEN and was fixed before the commit; the gate stayed at 47.

## Notes for 23-14

- Nothing of this plan reaches a real BE until 23-14 selects `spellFound { id name requiredLearnTime }` and `spellResearchFailed` in the `QuestResult` selection (subscription `questResultReceived`, `unacknowledgedQuestResults`, `questResult(id)`). Without `requiredLearnTime` in `spellFound` the sheet shows only «Magia scoperta» and the banner only «Hai scoperto «…».».
- The two push types need no selection: they are FCM data.

## Threat Flags

None: only the two exact wire names were added (T-23-47); no new payload key, no router change (T-23-48); no `appLog` added (T-23-49); shared dedup key (T-23-50).

## Self-Check: PASSED

- Commits 23181135, ad080a89, 02993755, 640a93b0 present in `git log`; the ten modified files exist.
