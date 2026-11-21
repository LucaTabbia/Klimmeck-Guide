---
phase: 24-participants-stories-and-innkeeper-wounds
plan: 01
subsystem: models
tags: [mission-draft, corrections, wire-boundary, switch, baseline]
requires: []
provides:
  - "MissionBackgroundAddition, MissionDraft.backgroundAdditions, MissionDraft.additionOf, MissionDraftStep.stories"
  - "MissionFightEffects.injuriesRemoved / innkeeperInjuries, MissionFightOutcome.innkeeperInjuriesBefore (lenient, default empty)"
  - "MissionCorrection.injuriesRemoved / declaresRemovals, withInjuryRemovalToggled, withRemovalsDeclared"
  - "fightsInputWithCorrections(..., declaresRemovals:), MissionBackgroundAdditionInput, SaveMissionDraftInput.backgroundAdditions, backgroundAdditionsInputOf"
  - "InnkeeperFailure.additionTooLong, backgroundAdditionTooLongCode, MissionCompletionScreen.additionTooLongMessage"
  - "storyAndWoundCorrectionsEnabled (off)"
  - "suite baseline of the stacked branch: 5296"
affects: [24-02, 24-05, 24-06, 24-07, 24-10]
tech-stack:
  added: []
  patterns: ["input key sent only when declared or non-empty (declaresRemovals)", "fixtures write a new wire key only when given"]
key-files:
  created:
    - lib/config/story_and_wound_corrections.dart
    - test/config/story_and_wound_corrections_test.dart
  modified:
    - lib/models/mission/mission_draft.dart
    - lib/models/mission/mission_fight.dart
    - lib/models/request/mission_draft_inputs.dart
    - lib/repository/innkeeper_failure.dart
    - lib/screens/innkeeper/missionCompletion/mission_completion_screen.dart
    - test/models/mission/mission_draft_test.dart
    - test/models/mission/mission_fight_test.dart
    - test/models/request/mission_draft_inputs_test.dart
    - test/repository/innkeeper_failure_test.dart
    - test/screens/innkeeper/missionCompletion/mission_completion_screen_test.dart
    - test/helpers/fixtures/mission_fixtures.dart
decisions:
  - "MissionDraftStep.stories opens MissionPage.recap until 24-06 adds the last page"
  - "injuriesRemoved leaves the app only for a correction that declares its removals or carries some; nothing declares them yet"
  - "backgroundAdditionsInputOf sends one entry per participant, trimmed, the empty ones included; a text keyed by a non-participant is ignored"
metrics:
  duration: "~20 min"
  completed: 2026-11-21
---

# Phase 24 Plan 01: Innkeeper-side models and inputs, the switch, suite baseline Summary

The innkeeper-side models read the BE Phase 25 draft leniently (story additions, the wire step `stories`, the three wound lists) and the inputs can express wound removals and the additions section; no GraphQL document changed and no new key reaches today's BE (the switch exists and is off, with no consumer yet).

## Suite baseline

Measured before any edit, on HEAD `2cd1a27b`:

```
02:13 +5296: All tests passed!
```

Written into `24-VALIDATION.md` (5296). The full suite was not re-run after the changes (REPO-RULES: full suite only here and in 24-10).

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect additions, the stories step and wound origins on the draft | 8cdbbc08 |
| 1 GREEN | Read additions, the stories step and wound origins leniently | 6de2eed4 |
| 2 RED | Expect wound removals and the additions section on the inputs | a26abec4 |
| 2 GREEN | Send wound removals and story additions, map the too-long refusal | 2e7a4823 |
| 3 | Bookkeeping | (this docs commit) |

## TDD

- **Task 1 RED (8cdbbc08):** compile failure, as expected: `mission_draft_test.dart` and `mission_fight_test.dart` did not load (`MissionBackgroundAddition`, `backgroundAdditions`, `additionOf`, `MissionDraftStep.stories`, `injuriesRemoved`, `innkeeperInjuries`, `innkeeperInjuriesBefore` undefined). `flutter test test/models/mission` → `+9 -2`.
- **Task 1 GREEN (6de2eed4):** `flutter test test/models/mission test/screens/innkeeper` → 376 passed.
- **Task 2 RED (a26abec4):** compile failure, as expected: the four test files did not load (`injuriesRemoved` / `declaresRemovals` on the correction, `MissionBackgroundAdditionInput`, `backgroundAdditionsInputOf`, `InnkeeperFailure.additionTooLong`, `additionTooLongMessage`, the switch file). Run: `+43 -4`.
- **Task 2 GREEN (2e7a4823):** `flutter test test/models test/repository/innkeeper_failure_test.dart test/config test/screens/innkeeper` → 1565 passed.
- **Green at the first run:** none measurable — every new case sat in a file that did not compile at RED. «an unknown step still reads null» (mission_draft_test) pins behaviour that already held (it uses the unknown name `additions`, the FE page name, to guard the naming trap of the REPO-RULES).

## Gates

- Analyzer after each code task: `47 issues found.` → `ANALYZE_GATE_OK`.
- Trailer check after every commit: `0`.
- `git diff --stat 2cd1a27b -- lib/graphql`: empty (nothing selected).
- `grep -rn storyAndWoundCorrectionsEnabled lib | grep -v lib/config/`: empty (no consumer yet).
- Formatted, one by one: every file in `key-files`. All the existing ones were formatter-clean before the edits (no `style` commit needed).

## Deviations from Plan

None on the contract. Additions beyond the listed cases (same scope):

- Extra test cases: «un-removing a wound keeps the other added ones (D-16)», «the other corrections keep the removals (D-13)», «backgroundAdditionsInputOf ignores the text of a stranger and sends a blank text as empty (D-06)».
- The screen test has no `failureLineOf` group: the case «an addition too long reads its own line (D-07)» lives in the group «failures that stay», whose loop also gained the pair (`additionTooLong`, its line) as a widget case («Passo 1 di 5 · Luogo» still pinned: 24-04 rewrites it).
- Boy scout: `MissionCorrection._without` shared by the two wound toggles.

## Notes for the next plans

- `fightsInputWithCorrections(draft, fightIndex, corrections, {declaresRemovals = false})` is the ONE place that declares removals; `MissionCorrection.withRemovalsDeclared()` is sticky through `_copy`.
- `withInjuryRemovalToggled`: first tap adds to `injuriesRemoved`; second tap un-removes AND drops the wound from `injuries`. `fromEffects` seeds `injuriesRemoved` as served (never repaired) and never declares.
- `_pageOf(MissionDraftStep.stories)` returns `MissionPage.recap` with the comment «fino al 24-06»: 24-06 must point it to `MissionPage.additions`.
- Fixtures: `missionEffectsJson(injuriesRemoved:, innkeeperInjuries:)`, `missionOutcomeJson(innkeeperInjuriesBefore:)`, `missionDraftJson(backgroundAdditions:)` (keys written only when non-null), `missionBackgroundAdditionJson({character, text})`.
- `InnkeeperFailure.additionTooLong` has no exhaustive switch to update elsewhere (all the other switches have a default branch).

## Known Stubs

None. `storyAndWoundCorrectionsEnabled` is intentionally unused until 24-06 / 24-07.

## Self-Check: PASSED

Files created exist (`lib/config/story_and_wound_corrections.dart`, `test/config/story_and_wound_corrections_test.dart`); commits `8cdbbc08`, `6de2eed4`, `a26abec4`, `2e7a4823` are in `git log`.
