---
phase: 18-heal-quests-by-size
plan: 11
subsystem: quests
tags: [quests, acceptance, no-effect, notice, board, tdd]
requires: ["18-10"]
provides:
  - "const String questNoEffectCode = 'QUEST_NO_EFFECT' in lib/repository/quest_acceptance_failure.dart"
  - "QuestAcceptanceFailure.noEffect (enum value right after starving), mapped from extensions.code only on both error shapes (graphqlErrors and HTTP 400 parsedResponse)"
  - "questAcceptanceNoticeFor(QuestAcceptanceFailure.noEffect) -> KGNotification(title: 'Missione non accettata', description: questNoEffectLine)"
  - "QuestAcceptanceOutcomeListener._staleListFailures gains noEffect: silent QuestCubit.refreshQuests(cityId:) after the refusal"
affects: [18-12, 18-13]
tech-stack:
  added: []
  patterns: ["one constant for the sheet line and the refusal banner (questNoEffectLine)"]
key-files:
  created: []
  modified:
    - lib/repository/quest_acceptance_failure.dart
    - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart
    - lib/screens/mainScreen/components/quest_acceptance_outcome_listener.dart
    - test/repository/quest_acceptance_failure_test.dart
    - test/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice_test.dart
    - test/screens/mainScreen/components/quest_acceptance_outcome_listener_test.dart
decisions:
  - "The refusal notice reuses questNoEffectLine from quest_blocked_reason.dart: one copy of the string in lib"
  - "noEffect is a stale-list failure: the Board rereads its list once per refusal (the sheet was already recomposed by the existing _onAcceptanceOutcome)"
metrics:
  duration: "~10 min"
  completed: 2026-11-10
  tasks: 1
  files: 6
---

# Phase 18 Plan 11: Heal with no effect refusal Summary

A `QUEST_NO_EFFECT` refusal of `acceptQuest` becomes `QuestAcceptanceFailure.noEffect` (from `extensions.code` only), shows the in-world banner «Missione non accettata» / «Il tempio non può fare nulla per te adesso» through the shared `questNoEffectLine` constant, and silently rereads the Board list (D-20, HEAL-06 second half).

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | QUEST_NO_EFFECT as a failure, its in-world notice and the list reread | 16ec2ef (test), aca0056 (feat) |

## RED

Running the three test files after the RED commit failed at compile time, as expected:

```
test/repository/quest_acceptance_failure_test.dart:59:32: Error: Member not found: 'noEffect'.
test/repository/quest_acceptance_failure_test.dart:63:32: Error: Member not found: 'noEffect'.
test/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice_test.dart:72:34: Error: Member not found: 'noEffect'.
test/screens/mainScreen/components/quest_acceptance_outcome_listener_test.dart:188:67: Error: Member not found: 'noEffect'.
```

New tests (3): «maps QUEST_NO_EFFECT to noEffect (D-20)» (both shapes in one test), «a no-effect refusal says the temple can do nothing (D-20)», «a no-effect refusal publishes the notice and rereads the list (D-20)» (publishNotice once with dedupKey `quest-acceptance|noEffect|h-1`, refreshQuests(cityId: 'city-1') once, reset once).

## Other switches over QuestAcceptanceFailure

None needed a change: the only exhaustive switch is `questAcceptanceNoticeFor`; `questAcceptanceFailureFrom` has a default branch; `board.dart:289` only compares against `starving`; the repository and the cubit only construct `timedOut` / `unknown`.

## Verification

- `flutter test test/repository test/screens/mainScreen/questAcceptanceCubit test/screens/mainScreen/components test/screens/mainScreen/tabs/board` → 1106 tests, All tests passed.
- Full suite `flutter test` → **3904 tests, All tests passed** (3901 expected after 18-10 + 3 new).
- `flutter analyze --no-fatal-infos` → `47 issues found.` (all info, 0 error, 0 warning), ANALYZE_GATE_OK.
- `dart format` on the six touched files, one by one: 0 changed (all formatter-clean).
- Acceptance greps: `questNoEffectCode` = 2, `'QUEST_NO_EFFECT'` = 1, `QuestAcceptanceFailure.noEffect` = 1 in notice and 1 in listener, one file in `lib` holds the copy, no chrome in the listener, `D-20)` in each of the three test files.
- `git diff develop...HEAD --stat -- lib/graphql/fragments` prints nothing (no fragment selection before the gated 18-12).

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Files modified exist; commits 16ec2ef and aca0056 present in `git log`.
