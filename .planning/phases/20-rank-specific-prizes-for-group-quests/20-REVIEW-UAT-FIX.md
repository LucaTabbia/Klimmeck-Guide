---
phase: 20-rank-specific-prizes-for-group-quests
fixed_at: 2026-11-13
review_path: .planning/phases/20-rank-specific-prizes-for-group-quests/20-REVIEW-UAT.md
iteration: 1
starting_head: 222314ce
findings_in_scope: 8
fixed: 6
not_needed: 2
skipped: 0
status: all_fixed
---

# FE Phase 20 — fix report of the review of the UAT fixes and quick 261113-aql

Every finding was handled as the orchestrator rulings at the bottom of `20-REVIEW-UAT.md` decide. TDD for every code fix (RED commit with the failure verified, then GREEN); copy, comment and test-only changes in their own commits. Every new or strengthened test was proved to bite by a mutation of the matching production branch (red seen, mutation reverted, never committed). No commit carries a `Co-Authored-By` / `Generated with` / `Claude-Session` trailer (checked after each commit: `0`).

## Outcomes

| Id | Outcome | Commits | Proof |
|----|---------|---------|-------|
| WR-01 | fixed: (a) done; (b) verified, not wired (limit below) | `6596807b` test, `5e8536b4` fix, `fee3690a` test, `f13a542e` docs | RED: `refreshQuests` never called (`No matching calls`). Mutation: dropping `!selected.awaitingRescue` from `isEnabled` turns the new Board case red (`Expected: false, Actual: true`) |
| WR-02 | not_needed | — | Ruling: merge-order gate handled by the orchestrator (BE quick PR first, then schema check and full suite) |
| WR-03 | fixed: requires human verification (logic) | `1e665ade` test, `a7d2a27c` fix | RED: first legend `[false, true]` instead of `[true, false]`; stored-title case `[true, false]` instead of `[false, true]`. Mutations: «others» instead of «before» → two-legend case red; current title instead of the stored one → stored-title case red |
| WR-04 | fixed | `4dd1d4af` test, `331cf53c` fix, `0af419f7` docs | RED: 6 of 7 new cases fail on the truncated minutes (3 600 s green: whole hour) |
| IN-01 | not_needed | — | Ruling: hypothetical trigger; the next gesture or state settles the sheet |
| IN-02 | fixed (test) | `9c10ff00` | Green at first run (test-only). Mutations: lock check moved after `insufficientPoints` → red (`laneBusy`); moved right after `titleMismatch` → red (`titleMismatch`) |
| IN-03 | fixed (copy) | `2c1e0714` test, `a30195c1` fix, `f13a542e` docs | RED: 2 failures on the old text (reason test, Board open-sheet test) |
| IN-04 | fixed (comment) | `c0ebdd4b` | Comment only; `flutter test test/models/quest` green |

## WR-01 — the rescue lock on an open Board

**(a) done.** `QuestAcceptanceFailure.notAcceptable` joins `_staleListFailures` in `lib/screens/mainScreen/components/quest_acceptance_outcome_listener.dart`: after a refusal with `QUEST_NOT_ACCEPTABLE` the session listener calls the existing silent `QuestCubit.refreshQuests` (never `QuestLoading`, previous data kept on error, no spinner), so the open sheet turns torn with «Soccorso in corso…» on the spot instead of staying whole and swipeable. The reread also fires for the catalogue-defect `notAcceptable` (harmless: silent and one call). Tests: new listener case «a not-acceptable refusal rereads the list so a sheet locked by a rescue turns torn (WR-01, quick 261113-aql)»; the main screen banner test for `notAcceptable` now stubs and verifies the reread away from the Board.

**(b) verified, not wired.** BE `src/schema.gql` on `feat/quick-aid-locks-source-quest`: `questUpdated(questId: String!): Quest!` — one subscription per quest id, there is no list-level event. In the app the only caller of `QuestCubit.watchQuest` is `PartyWatchListener` (the viewer's own lane quest while travelling or waiting for its party), and `QuestCubit` holds one watch at a time («Una sola quest seguita alla volta»). Covering the listed quests means one subscription per listed hunt/dungeon; covering even only the open sheet needs a second watch slot in `QuestCubit` (or a new Board-level watcher) that would contend with the party watch. Both are a new mechanism, which the ruling excludes. So (a) only.

**Remaining limit.** A lock that starts or ends while the Board is open shows at the next list read: Board opening (`board.dart` `initState`), a scope change of the viewer (`QuestScopeListener`), the map reread, or a refused swipe (new). Scenario 1 of the review closes after one refusal; scenario 2 (lock released with the Board open) shows when the Board is reopened. The refusal banner still reads «Missione non disponibile, avvisa il locandiere» (shared with the catalogue defect): changing it is a copy/product decision, not taken here.

**Test renamed.** The Board test «when questUpdated clears the lock…» is now «when a reread list drops the lock the sheet is whole and tearable again (WR-01, quick 261113-aql)», paired with the new «when a reread list brings the lock the open sheet tears and says why (WR-01, quick 261113-aql)».

## WR-03 — the seat a registered viewer holds

The order is on the wire: the BE appends with `$push` in `registrationUpdate` (`src/quests/acceptance/quest-acceptance.updates.ts`), serves `registeredAdventurers` as stored (no field resolver reorders them), and `RegisteredAdventurer.listFrom` keeps the list order. `registeredAt` is not selected by the FE (no new selection added). `_viewerSeatTitleOf` (`lib/models/quest/quest_sheet_details.dart`) now judges a registered viewer against the registrations before its own, with the title stored on its registration (fallback: the current title for a legacy registration without one); a viewer not registered is judged after every registration with its current title, as before. Counts and acceptance unchanged. New tests in the group `legend on hero seats`: «with two legends the first registered holds the legend seat and the second the hero seat (WR-03, …)» (both orders) and «a registered viewer is highlighted on the seat of its stored registration title (WR-03, …)». Marked for human verification as a logic change.

## WR-04 — duration rounding

`formatQuestDuration` (`lib/utils/game_duration_format.dart`): from one minute up it rounds the milliseconds up to the whole minute (`(ms / millisecondsPerMinute).ceil()`), under one minute it stays in seconds rounded up. New group «formatQuestDuration rounds up to the whole minute from one minute on and never reads less than the real time (WR-04)»: 61 s, 90 s, 119 s → «2 minuti»; 3 600 s → «1 ora»; 3 601 s → «1 ora, 1 minuto»; 1 h 15 min 30 s → «1 ora, 16 minuti» (moved from the old group, where it read «1 ora, 15 minuti»); 22 min 30 s → «23 minuti». Unchanged: 7.5 s → «8 secondi», 59.5 s → «1 minuto». Rule and examples of `20-UAT-FIX-03.md` updated.

## IN-02, IN-03, IN-04

- IN-02: in «the lock wins over the viewer-dependent refusals… (IN-02, quick 261113-aql)» each viewer first asserts the refusal it gets without the lock (busy lane → `laneBusy`, other city and unknown city → `notInCity`, a rookie on a hero dungeon and a viewer without title → `titleMismatch`), then the lock. The no-points viewer is gone (hunt and dungeon pay no points).
- IN-03: `questAwaitingRescueLine` = «Soccorso in corso: la missione riapre quando il soccorso si conclude.»; tests and the quick plan updated.
- IN-04: `anyRankOverflowOf` says it mirrors BE `overflowOf` on the folded counts and that counting unknown-rank registrations on the any-rank seats is FE-only tolerance (BE `registeredCountsOf` skips them); same note on `isFullForEveryone`.

## Left to the orchestrator

- `261113-aql-SUMMARY.md` is not touched (SUMMARY files are out of this fixer's scope): it still says the lock appears and disappears live through `questUpdated`, still quotes the old reason line and the «no points» viewer. The amendments are recorded at the end of `261113-aql-PLAN.md`.
- The device step «the lock disappears live» can only pass by reopening the Board (WR-01 limit).

## Gates

- `flutter test test/models/quest test/repository test/shared/components/popup test/screens test/utils test/graphql` (foreground): **+3373: All tests passed!**
- `flutter analyze --no-fatal-infos`: 47 issues (info), 0 warning, 0 error — `ANALYZE_GATE_OK`.
- `sh tool/hardening_check.sh`: OK.
- New tests: +10 (listener 1, Board 1, sheet details 2, duration 7 new − 1 moved). Full suite expected total: **4329 + 10 = 4339** (not run here).
- No new dependency, GraphQL operation or selection; `dart format` only on touched files.

---

_Fixed: 2026-11-13_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
