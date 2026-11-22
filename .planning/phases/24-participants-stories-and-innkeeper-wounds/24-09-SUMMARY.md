---
phase: 24-participants-stories-and-innkeeper-wounds
plan: 09
subsystem: quests
tags: [result-sheet, story-page, innkeeper-wounds, wax-sigil, background]
requires: ["24-08"]
provides:
  - "QuestResultSheet.storyPageKey / QuestResultSheet.storyPageLine"
  - "the result sheet's «Guarite» reads QuestResult.healedOrRemovedInjuries"
  - "tests proving the sigil on an appended background entry (cubit, listener, Profile)"
affects: [24-10, 24-11]
tech-stack:
  added: []
  patterns: ["the sheet prints served facts only: a flag for the story, two served lists for the healed line"]
key-files:
  created: []
  modified:
    - lib/shared/components/popup/quest_result_sheet.dart
    - test/shared/components/popup/quest_result_sheet_test.dart
    - test/screens/mainScreen/newEntriesCubit/new_entries_cubit_test.dart
    - test/screens/mainScreen/components/new_entries_listener_test.dart
    - test/screens/mainScreen/tabs/profile/profile_background_test.dart
decisions:
  - "the story line sits right after the lore-unlock lines and before «Hai salvato …», drawn by the sheet's own `_line` (same style as its neighbours)"
  - "the potion sheet keeps healedLine(result.injuriesHealed): a potion never carries removals"
  - "the sigil needs no production code: the three proofs were green at the first run"
metrics:
  duration: "~20 min"
  completed: 2026-11-21
---

# Phase 24 Plan 09: Result sheet and the sigil proof Summary

The result sheet reads «La tua storia ha una nuova pagina» only when the served `backgroundEntryAdded` is true, and its single «Guarite: …» line lists the wounds healed by a cure followed by the wounds the innkeeper took off, each once; the wax sigil on an appended background entry is proven by tests with no new production code.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect the story line and removed wounds on the result sheet | 832b14dc |
| 1 GREEN | Tell the new story page and removed wounds on the result sheet | f8cca4d7 |
| 2 | Prove the sigil marks an appended background entry (tests only) | 776fee22 |
| 3 | Bookkeeping | (this docs commit) |

## TDD

- **Task 1 RED (832b14dc):** the test file did not compile (`QuestResultSheet.storyPageKey`, `storyPageLine` missing); the removed-wounds cases would also fail on behaviour (the line read `injuriesHealed` only).
- **Task 1 GREEN (f8cca4d7):** `flutter test test/shared/components/popup test/screens/mainScreen/components test/screens/mainScreen/questResultsCubit` → 530 passed; analyzer «47 issues found» (`ANALYZE_GATE_OK`). Acceptance greps: story copy 1, `healedOrRemovedInjuries` 1, `healedLine(_result.injuriesHealed)` 0.
- **Task 2 (776fee22):** **green at the first run: the sigil needs no new code.** `flutter test test/screens/mainScreen/newEntriesCubit test/screens/mainScreen/components/new_entries_listener_test.dart test/screens/mainScreen/tabs/profile` → 25 passed; `git diff --stat HEAD~1 -- lib` prints nothing; analyzer «47 issues found» (`ANALYZE_GATE_OK`).
- **Full suite (asked by the orchestrator before the gate):** `flutter test -r expanded` → **5489 passed**, no failure.

## What was built

- `QuestResultSheet`: `storyPageKey` (`questResult.storyPage`), `storyPageLine`; `_storyPageText()` returns the copy only for a served `true`; the «Guarite» line now reads `_result.healedOrRemovedInjuries` at its existing place (between the HP bar and the injuries added).
- Result sheet tests: story line present with the flag (and below the lore lines), absent without the key and with `false`; healed + removed in ONE widget, a wound in both lists listed once, removed only, nothing when both lists are empty. The learning-end and death cases are untouched and green.
- Sigil proofs (D-09):
  - cubit — an entry appended to a seen background is unseen and `hasUnseenIn(NewEntryCategory.profile)` is true (Journal stays quiet); the Profile visit highlights it and the store holds both entries; a second visit drops the highlight.
  - listener — a character update appending an entry marks that entry only and lights the Profile; the store is not rewritten until the visit.
  - Profile — three entries, only the appended line carries the sigil.
- «The first sync of a background marks nothing» (Pitfall 8) is already pinned by `new_entries_listener_test.dart` «records the character already loaded as the first sight» (background) and by `new_entries_cubit_test.dart` «what the character owns at the first launch is not new»: not duplicated.

## Deviations from Plan

None on the code. Two notes:

- The full suite was run once at the orchestrator's request (REPO-RULES reserves it to 24-01 and 24-10): 5489 green.
- The SUMMARY was written with a Bash heredoc (user's standing preference for planning documents in auto mode).

## Known limit (pre-existing, not changed here)

A background entry is identified by its text (`newEntryIdsOf`): an addition whose text is identical to an entry the character already has would not light the sigil. The result sheet's story line does not depend on it (served flag). To look at in the 24-11 UAT only if the case matters.

## Threat model

- T-24-37 mitigated: both lines come from served fields only (tests on absent and `false`, and on empty lists).
- T-24-39 mitigated: a result without the new keys draws the sheet as before (all earlier cases green).
- T-24-38 accepted as planned: no change to the device store.

## Known Stubs

None.

## For the next plans

- 24-10 selects `backgroundEntryAdded` and `injuriesRemoved` on the result documents; no widget change is needed for the sheet.
- Suite before the gate: 5489 green; analyzer 47.

## Self-Check: PASSED

- Files modified exist; commits 832b14dc, f8cca4d7, 776fee22 are in `git log`.
