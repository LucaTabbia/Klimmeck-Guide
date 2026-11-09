---
phase: 16-travel-ambushes
fixed: 2026-11-06T18:55:26Z
source: 16-REVIEW.md
review_path: .planning/phases/16-travel-ambushes/16-REVIEW.md
rulings_path: .planning/phases/16-travel-ambushes/16-REVIEW-RULINGS.md
iteration: 1
fix_scope: all
findings_total: 3
findings_in_scope: 3
fixed_count: 1
skipped_count: 0
not_needed_count: 3
deferred_count: 0
status: all_fixed
---

# Phase 16: Code Review Fix Report

**Fixed at:** 2026-11-06T18:55:26Z
**Source review:** `.planning/phases/16-travel-ambushes/16-REVIEW.md`
**Rulings:** `.planning/phases/16-travel-ambushes/16-REVIEW-RULINGS.md`
**Iteration:** 1
**Branch:** `feat/16-travel-ambushes` (no push). Start `bc25966`, final code HEAD `c906db4`.

**Summary:**
- Findings in the review: 3 (0 critical, 0 warning, 3 info)
- Fixed: 1 (IN-02 part a)
- Not needed: 3 rulings (IN-01, IN-02 part b, IN-03), recorded with the orchestrator's reason, no code change
- Skipped: 0. Deferred: 0.

The not-needed count covers rulings, not whole findings: IN-02 has a FIX part (a) and a NOT_NEEDED part (b).

IN-02 (a) went Red → Green (`test(models)` then `fix(models)`). Commits use plain `git` with explicit paths, carry no trailers and rewrite no history. No GraphQL document changed, registry stays at 45, no new dependency, Cloudinary asset id or environment variable.

## Gate finale

| Check | Result |
|-------|--------|
| `flutter analyze` (repo-wide) | **50 issues found, all info, 0 errors / 0 warnings**: unchanged baseline |
| `flutter test` (full suite, foreground) | **`01:15 +3391: All tests passed!`** |
| `flutter test test/models/quest_result/` | RED `+56 -1` (only the new case), GREEN `+69: All tests passed!` |
| `dart format` on every touched file | each file formatted on its own, 0 changed |
| Trailers on `bc25966..HEAD` (`co-authored-by` / `generated with` / `claude-session`) | 0 |
| `git status --short` | empty before the report commit |

## Per-finding table

| ID | Severity | Outcome | Commits | Tests added / changed |
|----|----------|---------|---------|-----------------------|
| IN-01 | Info | not_needed | — | Orchestrator ruling: an ambush head waiting for any in-flight read is consistent with D-12 (every read merges the full unacknowledged batch); offline the wait is bounded by the `silentRetry` give-up, then the carousel opens with what is queued; no spinner, no data loss |
| IN-02 (a) | Info | fixed | `ad8a17f` → `c906db4` | `quest_result_test.dart` group «ambush reports (BE Phase 15)»: «an ambush ignores a malformed quest block (D-01)»; «parses a won ambush without a quest (D-01)» stays green |
| IN-02 (b) | Info | not_needed | — | Orchestrator ruling: an empty `nearCity.name` keeps throwing; the BE declares `name: String!`, an empty name is a contract violation handled by the Phase 9 boundary policy (item dropped, refetch keeps retrying); «Imboscata presso » with an empty name would be worse |
| IN-03 | Info | not_needed | — | Orchestrator ruling: «4 di 4» on a lone quest sheet after a carousel is the specified D-11 behaviour (`position` counts the whole group); added to the 16-08 UAT as something to look at, not as a failure |

## Details

### IN-02 (a): an ambush ignores its quest block

- RED `ad8a17f` `test(models): pin that an ambush ignores its quest block` — `ambushWonResultJson()` with `'quest': {'id': 'q-1'}` (no `type`/`title`) must parse with `isAmbush` true and `quest == null`; it failed because `_questOrNull` called `QuestResultQuest.fromJson` on the map and threw.
- GREEN `c906db4` `fix(models): ignore the quest block of an ambush result` — the ambush branch of `QuestResult.fromJson` sets `quest: null`; the helper `_questOrNull` became unused and was removed (`lib/models/quest_result/quest_result.dart`, 1 insertion, 4 deletions).

## Notes for the device UAT

- An ambush report whose `quest` field carries any object (well-formed or not) now shows exactly as before, with `quest == null`. With a BE that respects the contract (`quest` null on an ambush) nothing visible changes.
- IN-03 to look at in 16-08: after a carousel of N ambushes, the first quest sheet reads «N+1 di N+k» (e.g. «4 di 4» with one quest left). This is the specified D-11 behaviour, not a failure.
- IN-01 to look at in 16-08: offline, an ambush carousel already queued can wait up to the silent-retry give-up (about 2 minutes) before it opens. No spinner is shown.

---

_Fixed: 2026-11-06T18:55:26Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
