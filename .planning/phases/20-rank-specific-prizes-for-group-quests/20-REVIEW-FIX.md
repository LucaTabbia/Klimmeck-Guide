---
phase: 20-rank-specific-prizes-for-group-quests
fixed_at: 2026-11-13
review_path: .planning/phases/20-rank-specific-prizes-for-group-quests/20-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 6
not_needed: 2
skipped: 0
status: all_fixed
---

# Phase 20: Code Review Fix Report

**Fixed at:** 2026-11-13
**Source review:** `20-REVIEW.md` (pre-gate, plans 20-01 and 20-02), applied as the orchestrator rulings decide
**Starting HEAD:** `32cc1d42`

**Summary:** 8 findings: 6 fixed, 2 `not_needed` by ruling (IN-01, IN-02), 0 skipped. No production behaviour change: the copy and the branches of `dungeonTurnLine` are unchanged. IN-06 renames a local and updates two doc comments. No new test revealed a production bug.

| Id | Outcome | Commit | Proof (mutation probe, reverted with `git checkout -- <file>` or a scratchpad copy, never committed) |
|----|---------|--------|------|
| WR-01 | fixed (+3 tests) | `d19b27d1` | `&& last != null` dropped → only «a won rescue without the last turn…» red; `?? 0` dropped → only «missing completed turns read as zero» red; `<= 0` → `== 0` → only «no turn line with a negative total» red |
| WR-02 | fixed (props case strengthened, +1 round-trip payload) | `a5676e25` | each of the four props entries removed one at a time → «the turn fields are part of the props» red each time; `toJson` key `lastTurnKind` or `turnsTotal` removed → round trip «dungeon aid with turns» red |
| IN-01 | not_needed (ruling: the backend is the source of truth; no range guard on `lastTurn` / `turnsCompleted`) | — | — |
| IN-02 | not_needed (ruling: pre-existing helper, a GraphQL `Int` cannot carry it) | — | — |
| IN-03 | fixed (stages-slot case strengthened) | `93eea0e8` | `..._turnsOrStages()` moved below `..._hp()` in `_content()` → «a dungeon with turns shows one turn line in the stages slot» red |
| IN-04 | fixed (+3 widget tests) | `0fd930b3` | helper outcome gate turned into the completed-turns line → the 3 new cases red; sheet stages fallback replaced by `const <Widget>[]` → the 3 new cases red (plus 3 existing stages cases) |
| IN-05 | fixed (lost-rescue case only; assertion unchanged) | `41de682e` | not a new assertion, so no probe; case still green with the BE-shaped counters |
| IN-06 | fixed (Boy Scout refactor + model tests read the getters) | `a00835d9` | parse of `turnsTotal` forced to null → «reads the four turn fields» red; absent `turnsTotal` read as `?? 0` → «absent turn fields read as null» red; `turnsCompleted` read with `as int?` → «a non-number turn count…» red (it now feeds a malformed `turnsCompleted`); `toJson` key `lastTurn` renamed → «reads the four turn fields» red |

## Fixed Issues

### WR-01: Three behaviours of `dungeonTurnLine` had no test

**Files modified:** `test/utils/quest_outcome_lines_test.dart`
**Commit:** `d19b27d1`
**Applied fix:** three titled cases in the `dungeonTurnLine (Phase 20)` group: a won rescue without `lastTurn` reads «Turni superati: 4 di 8»; a dungeon without `turnsCompleted` reads «Turni superati: 0 di 8»; a negative `turnsTotal` gives no line.

### WR-02: The props case proved one turn field out of four

**Files modified:** `test/models/quest_result/quest_result_test.dart`
**Commit:** `a5676e25`
**Applied fix:** the props case builds a base result and varies `turnsTotal`, `turnsCompleted`, `lastTurn`, `lastTurnKind` one at a time (each `isNot(base)`, plus `turns() == base`); the `round trip` map gains `'dungeon aid with turns': aidDungeonResultJson()`.

### IN-03: The slot position was bounded from one side only

**Files modified:** `test/shared/components/popup/quest_result_sheet_test.dart`
**Commit:** `93eea0e8`
**Applied fix:** the bottom of the turn line must also be at or above the top of `QuestResultSheet.hpKey`. The «proporzione» pin stays as it is (no change requested).

### IN-04: The outcome gate was proven on the helper only

**Files modified:** `test/shared/components/popup/quest_result_sheet_test.dart`
**Commit:** `0fd930b3`
**Applied fix:** three widget cases (`rescued`, `death` from `aidDungeonResultJson`, `gmCompleted` from `dungeonResultJson`, all with turn fields filled). Each finds no turn line and states what the stages slot shows today: «Esplorazione: tappa 2 di 4» for the two aid outcomes, «Esplorazione: tappa 3 di 3» for `gmCompleted`.

### IN-05: Fixture values the BE would not send

**Files modified:** `test/utils/quest_outcome_lines_test.dart`
**Commit:** `41de682e`
**Applied fix:** «a lost rescue reads like a fall» now passes `turnsCompleted: 2, stagesCleared: 1` for `lastTurn: 3` (BE row «rescuer who loses at turn f: T, f, f+1»). The asserted line is the same. Not applied: the optional `turnsTotal: 6` for the `dungeonResultJson` cases, because it would rewrite the expected strings («… di 8») of the `dungeonResultJson` cases in the helper and sheet tests and the review rates it cosmetic and hypothetical (placeholder turn engine, D-13). The third bullet needed no change.

### IN-06: Small Clean Code points

**Files modified:** `lib/utils/quest_outcome_lines.dart`, `lib/models/quest_result/quest_result.dart`, `lib/shared/components/popup/quest_result_sheet.dart`, `test/models/quest_result/quest_result_test.dart`
**Commit:** `a00835d9`
**Applied fix:** the local `cleared` is now the private `_completedTurnsLine(result, total)`, called only from the `success` and `failure` arms. The copy and the switch arms are unchanged. The `stagesCleared` / `stagesTotal` doc and the `_stagesText()` doc now say «una dungeon o un'aid di dungeon (BE D-12, D-22)». The seven model cases read `result.turnsTotal` etc. directly. «reads the four turn fields» keeps one `toJson` `containsPair` assertion for the wire key names. The malformed-count case now also feeds `turnsCompleted: [3]`.

## Not needed (rulings)

- **IN-01:** `lastTurn` / `turnsCompleted` stay printed as served. The `turnsTotal ≤ 0` display guard stays as it is.
- **IN-02:** `_countFrom` left unchanged.

## Verification

- Tests added: 7 (WR-01 +3, WR-02 +1 round-trip payload, IN-04 +3). Two cases were strengthened without changing the count (WR-02 props, IN-03 slot).
- `flutter test test/models/quest_result test/utils test/shared/components/popup` → **434 passed**.
- `flutter analyze --no-fatal-infos` → **47 issues (info only), 0 warning, 0 error**, ANALYZE_GATE_OK.
- `dart format` was run only on the touched files, one at a time.
- Expected full suite: 4281 + 7 = **4288** (not run here; plan 20-03 runs it).
- Each commit was checked for trailers with `git log -1 --format=%B | grep -ciE "co-authored-by|generated with|claude-session"` → 0.

---

_Fixed: 2026-11-13_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
