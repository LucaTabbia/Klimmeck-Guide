---
phase: 20-rank-specific-prizes-for-group-quests
reviewed: 2026-11-13
depth: standard
scope: pre-gate plans 20-01 and 20-02 (diff c7c0cd88..99c43e0a, lib and test)
status: issues_found
findings:
  critical: 0
  warning: 2
  info: 6
  total: 8
---

---
phase: 20-rank-specific-prizes-for-group-quests
reviewed: 2026-11-13T00:00:00Z
depth: standard
scope: git diff c7c0cd88..HEAD -- lib test (pre-gate plans 20-01, 20-02)
files_reviewed: 16
files_reviewed_list:
  - lib/models/enums/dungeon_turn_kind.dart
  - lib/models/quest_result/quest_result.dart
  - lib/shared/components/popup/quest_result_sheet.dart
  - lib/utils/quest_outcome_lines.dart
  - test/helpers/fixtures/quest_fixtures.dart
  - test/helpers/fixtures/quest_result_fixtures.dart
  - test/models/quest/quest_availability_test.dart
  - test/models/quest/quest_capacity_test.dart
  - test/models/quest/quest_sheet_details_test.dart
  - test/models/quest/quest_state_label_test.dart
  - test/models/quest/quest_test.dart
  - test/models/quest_result/quest_result_test.dart
  - test/screens/mainScreen/tabs/map/quest_info_overlay_test.dart
  - test/shared/components/popup/quest_info_sheet_test.dart
  - test/shared/components/popup/quest_result_sheet_test.dart
  - test/utils/quest_outcome_lines_test.dart
findings:
  critical: 0
  warning: 2
  info: 6
  total: 8
status: issues_found
---

# FE Phase 20 (pre-gate): Code Review Report

**Depth:** standard, read-only. Nothing was run (no `flutter test`, `flutter analyze`, `dart format`, build); every statement below comes from reading the code, the diff and the phase documents. `.env` not read. Repo not modified.

## Summary

The production code (4 files, ~76 lines) matches the copy table of `20-REPO-RULES.md` row by row, parses leniently, and adds no chrome and no client-side game rule. **No bug was found in the production code.** The two warnings are both about tests that leave a rule of the table, or the claim in their own title, unproven: a broken implementation would stay green. The info items are robustness on out-of-range values (hypothetical, needs a ruling), a pre-existing parsing edge, fixture realism, and small Clean Code points.

Reading of "verified" vs "hypothetical" below:
- **VERIFIED** = established by reading the code/tests (the mutant described would compile and leave the cited tests green by inspection; tests were not executed).
- **HYPOTHETICAL** = depends on a backend value that the documented contract says it will not send.

## Warnings

### WR-01: Three behaviours of `dungeonTurnLine` required by the copy table have no test (mutants survive)

**File:** `test/utils/quest_outcome_lines_test.dart:128-192` (code under test: `lib/utils/quest_outcome_lines.dart:45-51`)

**Issue (VERIFIED by reading):** the group has 13 cases, but these three guards of the helper are not exercised by any of them, nor by the sheet tests:

1. `QuestOutcome.success when _isAid(result) && last != null` (line 49) — table row «`lastTurn` absent where the rows above need it → Turni superati: C di T» is tested only for `failure` (line 173). No case builds a won aid without `lastTurn`.
2. `result.turnsCompleted ?? 0` (line 47) — every case that reaches «Turni superati» passes `turnsCompleted`.
3. `total <= 0` (line 45) — only `turnsTotal: 0` is tested (line 185); a negative total is not.

**Failure scenario:** someone simplifies line 49 to `QuestOutcome.success when _isAid(result) =>`. Dart interpolates a null `int?` without error, so a won dungeon aid whose `lastTurn` is missing prints «Ferito raggiunto al turno null di 8» on the sheet and the whole suite stays green. Same for dropping `?? 0` («Turni superati: null di 8») and for changing `<= 0` to `== 0` («Caduto al turno 4 di -1»).

**Fix:** three more cases in the same group (the fixture already allows an explicit null because the parameters are `Object?` with defaults):

```dart
test('a won rescue without the last turn reads the completed turns (D-21)', () {
  expect(
    lineOf(aidDungeonResultJson(lastTurn: null)),
    'Turni superati: 4 di 8',
  );
});

test('missing completed turns read as zero (D-21)', () {
  expect(lineOf(dungeonResultJson(turnsTotal: 8)), 'Turni superati: 0 di 8');
});

test('no turn line with a negative total (D-24)', () {
  expect(lineOf(dungeonResultJson(turnsTotal: -1, lastTurn: 1)), isNull);
});
```

### WR-02: «the turn fields are part of the props» proves one field out of four; no round-trip payload carries turns

**File:** `test/models/quest_result/quest_result_test.dart:726-731` and `:773-806` (code under test: `lib/models/quest_result/quest_result.dart:324-327`)

**Issue (VERIFIED by reading):** the test compares two results that differ only by `lastTurn` (4 vs 5). `turnsTotal`, `turnsCompleted` and `lastTurnKind` could be removed from `props` and no test in the diff would fail: the other model cases assert through `toJson()`, the helper and sheet cases never compare two `QuestResult`s, and none of the 14 payloads of the `round trip` group (`:774-806`) carries a turn field, so `fromJson(toJson()) == result` is not exercised for them either (the two `dungeon` payloads are built without turns).

**Failure scenario:** `lastTurnKind` dropped from `props` in a later edit. A result refreshed from the BE that differs only by the kind compares equal to the stale one; an Equatable-based state holding it does not re-emit, and the sheet keeps «Caduto al turno 4 di 8» without the kind. Suite green.

**Fix:** make the title true, one field at a time, and add a turn payload to the round trip:

```dart
test('the turn fields are part of the props (D-22)', () {
  Map<String, dynamic> turns({
    Object total = 8,
    Object completed = 3,
    Object last = 4,
    Object kind = 'fight',
  }) => dungeonResultJson(
    turnsTotal: total,
    turnsCompleted: completed,
    lastTurn: last,
    lastTurnKind: kind,
  );
  final base = questResult(turns());

  expect(questResult(turns(total: 9)), isNot(base));
  expect(questResult(turns(completed: 2)), isNot(base));
  expect(questResult(turns(last: 5)), isNot(base));
  expect(questResult(turns(kind: 'exploration')), isNot(base));
});
```

and in the `round trip` map: `'dungeon aid with turns': aidDungeonResultJson(),`.

## Info

### IN-01: `lastTurn` / `turnsCompleted` out of range are printed as served (asymmetric with the `turnsTotal ≤ 0` guard) — needs a ruling, not a silent fix

**File:** `lib/utils/quest_outcome_lines.dart:46-53`

**Issue (code path VERIFIED, trigger HYPOTHETICAL):** `turnsTotal ≤ 0` is treated as absent ("display guard, not a game rule", plan 20-02 choice c), but `lastTurn` is only null-checked. `lastTurn: 0` prints «Caduto al turno 0 di 8», `lastTurn: 9` with total 8 prints «Caduto al turno 9 di 8», a negative `turnsCompleted` prints «Turni superati: -1 di 8». The table of `20-REPO-RULES.md` says only «`lastTurn` present», so the code is compliant as written.

**Why it is worth a decision:** `BACKEND-NOTES.md` §4 states that the BE works with 0-based indices `i`, `s`, `f` and serves `i+1`. The one BE mistake this makes likely (serving `i` instead of `i+1`) yields `lastTurn: 0` for a fall at the first turn, the only off-by-one the FE can recognise, since the field is 1-based by contract.

**Fix (if the orchestrator agrees it is a display guard like the one on the total):** treat a non-positive `lastTurn` as absent, so the existing row «`lastTurn` absent → Turni superati: C di T» applies; no arithmetic is added.

```dart
final served = result.lastTurn;
final last = served != null && served > 0 ? served : null;
```

Do not clamp against `turnsTotal` on the device: that would be the FE correcting the BE.

### IN-02: `_countFrom` can still throw on a non-finite number (pre-existing helper, now on three more fields)

**File:** `lib/models/quest_result/quest_result.dart:235` (used at `:194-196`)

**Issue (HYPOTHETICAL, not executed):** `json is num ? json.toInt() : null` throws `UnsupportedError` for `NaN` / `Infinity`; `tryFromJson` catches `Object` and drops the whole result. A JSON literal such as `1e400` decodes to an infinite double in Dart. A GraphQL `Int` field cannot carry it (the server serialises a 32-bit integer), so this is not reachable through the declared schema; it is only the one remaining way the "a malformed turn field NEVER throws" rule of `20-REPO-RULES.md` is not literally true. Also by reading: a fractional value (`4.7`) is truncated to 4 rather than refused; same origin, same reachability.

**Fix:** `json is num && json.isFinite ? json.toInt() : null` (or `json is int ? json : null` if a fractional count should read as malformed); one line, covers stages and turns.

### IN-03: The sheet test «one turn line in the stages slot» only bounds the position from above

**File:** `test/shared/components/popup/quest_result_sheet_test.dart:1196-1201`

**Issue (VERIFIED by reading):** the assertion is `turnsKey.top >= enemyKey.bottom`. Moving `..._turnsOrStages()` anywhere further down `_content()` (after the HP bar, at the end of the sheet) keeps it green, while the title claims the stages slot. Same weakness as the pre-existing stages pin at `:319-320`, which the plan asked to copy. The dungeon failure fixture renders the HP bar (outcome `failure`), so an upper neighbour is available.

**Fix:** add `expect(tester.getBottomLeft(find.byKey(turnsKey)).dy, lessThanOrEqualTo(tester.getTopLeft(find.byKey(QuestResultSheet.hpKey)).dy));`.

Related, same file `:1220-1228`: «no prize-share line» searches the literal `'proporzione'`, a word that exists nowhere in `lib`; the test is a pin by design (declared green-at-first-run in the SUMMARY) and cannot fail unless a future line happens to use that exact word. No change requested; it should not be counted as evidence for D-20.

### IN-04: The outcome gate (no turn line on `rescued` / `death` / `gmCompleted`) is proven on the helper only, never on the sheet together with the fallback

**File:** `test/shared/components/popup/quest_result_sheet_test.dart:1166-1247`

**Issue (VERIFIED by reading):** the rule has two halves: no turn line, and the stages line when `stagesTotal` is set. The helper cases (`quest_outcome_lines_test.dart:194-228`) prove the first; the sheet case «without turns the stages line stays» proves the fallback only when the turn fields are absent. No widget case pumps a result with turn fields filled and one of the three outcomes. Today the composition in `_turnsOrStages()` (`quest_result_sheet.dart:461-466`) makes it correct by construction; the gap matters only if the gate is ever moved. `BACKEND-NOTES.md` §4 says the BE WILL fill the turn fields on the wounded character's `death` result, so this is the one combination that will occur on a device.

**Fix:** one widget case: `aidDungeonResultJson(outcome: 'death')` → `turnsKey` finds nothing and `stagesKey` reads «Esplorazione: tappa 2 di 4».

### IN-05: Fixture values the BE would not send (no effect on the assertions)

**File:** `test/helpers/fixtures/quest_result_fixtures.dart:211-268`, `test/utils/quest_outcome_lines_test.dart:135-146`

**Issue (VERIFIED against `BACKEND-NOTES.md` §4, lines 73-78):** the keys are right (the four wire names, written only when set, so every older payload is byte-identical). Some value combinations are not what the documented BE produces:

- «a lost rescue reads like a fall» (`:135`): `aidDungeonResultJson(outcome: 'failure', lastTurn: 3, …)` keeps the defaults `turnsCompleted: 4` and `stagesCleared: 2`. The BE row is «rescuer who loses at turn f: T, f, f+1», i.e. `turnsCompleted: 2` for `lastTurn: 3`. The line does not print `C`, so the assertion is unaffected.
- `dungeonResultJson(turnsTotal: 8, …)` keeps `stagesTotal: 3` with three enemy entries; with the rhythm of D-12 (exploration → fight → …) three fights are six turns, and a 1-based turn 4 is a fight, while several cases label it `exploration`. The aid fixture (turn 4 = fight, stages 2 of 4, total 8) is consistent. HYPOTHETICAL as a defect: the turn engine is a placeholder (D-13) and the FE prints, it does not check.
- After plan 20-03 the BE will send the four keys with an explicit `null` on every non-dungeon result, while the fixtures omit them. By reading, `json['k']` is null in both cases, so the parse is identical; no test is needed, noted only because the review brief asked.

**Fix:** pass `turnsCompleted: 2, stagesCleared: 1` in the lost-rescue case; optionally let `dungeonResultJson` cases use `turnsTotal: 6`. Cosmetic.

### IN-06: Small Clean Code points in the touched files (Boy Scout)

**Issue (VERIFIED by reading):**

- `lib/utils/quest_outcome_lines.dart:47` — the local `cleared` holds «Turni superati: C di T», which is also what a `failure` without `lastTurn` prints (line 54): the name says "cleared" on a lost dungeon. `completedLine` (or a private `_completedTurnsLine(result, total)`) says what it is; as a function it would also not be built for the three outcomes that return null.
- `lib/models/quest_result/quest_result.dart:119` — the doc of `stagesCleared` / `stagesTotal` still reads «Solo per una dungeon (BE D-12)»; per D-22 they are now also set for the rescuers of a dungeon aid, and the new comment four lines below already says «una dungeon o un'aid di dungeon». The same stale wording is on `_stagesText()` at `quest_result_sheet.dart:468`.
- `test/models/quest_result/quest_result_test.dart:704-770` — the seven model cases read the fields through `toJson()` (a trick so the RED commit compiled, plan 20-02 choice b). Now that the fields exist this couples each parsing assertion to the serialiser: «absent turn fields read as null» (`:733`) would also pass if `toJson` simply did not write the keys. Reading `result.turnsTotal` etc. directly, as the stages cases at `:113-130` do, proves parsing alone; «reads the four turn fields» can keep one `toJson` assertion for the key names. In the same group, «a non-number turn count» (`:751`) asserts `turnsCompleted` null although it was never passed malformed (the plan's `turnsCompleted: null` is simply an absent key in this fixture).

## Checked and found correct

**Helper `dungeonTurnLine` (`lib/utils/quest_outcome_lines.dart:43-67`) against the table of `20-REPO-RULES.md`, row by row:**

| Row | Code | Result |
| --- | --- | --- |
| `turnsTotal` null or ≤ 0 → no line | line 45, before any outcome branch | correct |
| `rescued`, `death`, `gmCompleted` → no line even with fields filled | lines 55-57, explicit arms | correct |
| `success`, type ≠ aid → «Turni superati: C di T» | line 51 | correct, exact copy |
| `success`, type = aid, `lastTurn` present → «Ferito raggiunto al turno L di T» | lines 49-50 | correct, exact copy |
| `failure`, `lastTurn`, `exploration` → «…, in esplorazione» | lines 52-53, 64 | correct, exact copy |
| `failure`, `lastTurn`, `fight` → «…, in uno scontro» | line 65 | correct, exact copy |
| `failure`, kind null/unknown → «Caduto al turno L di T» | line 66 (`''`) | correct |
| `lastTurn` absent → «Turni superati: C di T» | lines 51 and 54 | correct for both `success`+aid and `failure` |

- Branch order is right: the guarded `success`/`failure` arms precede the unguarded ones; the switch is exhaustive over the five `QuestOutcome` values with no `default`, so a sixth outcome is a compile error rather than a silent line.
- «Caduto…» is reachable from `failure` only. A lost rescue (aid + `failure`) reads as a fall, as the BE row «rescuer who loses at turn f» expects.
- No arithmetic anywhere: no `+ 1`, no share, no comparison between `lastTurn` and `turnsCompleted`; `L`, `T`, `C` are interpolated as served. `C` uses `?? 0` exactly as the table states.
- `_isAid` reads `result.quest?.type`: null-safe for an ambush report (`quest == null`) and for an unknown quest type (`QuestResultQuest.type` is null through `asNameMap`), both fall to «Turni superati».
- `_turnKindSuffix` is exhaustive over `DungeonTurnKind?` (two values + null).

**Sheet (`lib/shared/components/popup/quest_result_sheet.dart:172, 459-473`):**
- Exactly one of the two lines can be built: `turns != null ? turnsKey : stagesKey`. Never both. "Neither" happens only when the turn line is null and `stagesTotal` is null, which is the documented «or nothing».
- When the helper returns null because of the outcome, the stages fallback applies, as the table requires.
- Same slot (right after `_enemies()`), same `_line` helper, same `bodyMedium`, same top padding: no new section, box, chrome, loading or route. `_stagesText()` is untouched, so against today's BE (fields not selected) the sheet is identical.
- No other place in `lib` renders stages or turns (searched `stagesTotal|stagesCleared|turnsTotal|lastTurn`): the result sheet is the only consumer.

**Model (`lib/models/quest_result/quest_result.dart`, `lib/models/enums/dungeon_turn_kind.dart`):**
- The four fields are optional constructor parameters without defaults, so no existing constructor call changes.
- Parsing cannot throw on absent / null / string / bool / list values: the three counts go through `_countFrom` (`is num` test, no cast), the kind through `fromWire` (`is String` test, then `asNameMap()` lookup; no `byName`, no `as`). An unknown or non-string kind is null and the result is kept. Only residue: IN-02.
- All four are in `toJson` with the wire names (`lastTurnKind?.name` matches the wire values `exploration` / `fight`) and in `props`; `fromJson(toJson())` is symmetric by reading (not covered by a test: WR-02).
- `QuestResult` has no `copyWith`, so there is nothing to omit there.
- `QuestResult.toJson` has no caller in `lib` (test support only), so there is no persisted cache of older results that the new keys could invalidate.
- `dungeon_turn_kind.dart` has no Flutter import (model layer rule).

**Contract and scope:**
- The diff under `lib` is exactly the four files; `lib/graphql/fragments/quest_result_fragment.dart` is not in the diff and still selects only `stagesCleared` / `stagesTotal` (the selection is the gated plan 20-03).
- No secret, no hardcoded credential, no `print`/debug artifact, no commented-out code, no TODO in the changed lines.
- Doc comments on the new members state the origin and the reason (decision ids), in the style of the neighbouring ones; none restates what the code does.

**Tests of plan 20-01 (mixed boss, served prize block):** read in full. They are contract pins on existing behaviour (`availabilityOf`, `canRegisterWithTitle`, `isFullFor`, `QuestSheetDetails`, `questStateLabel`, `QuestInfoSheet`) with exact expected values and no production change behind them; the fixture `mixedBossJson` writes seats «own rank first, then the lower rank» with `minTitle` = the lowest seat title, as BE D-23 / FE D-25 state. `rankPrizes` is added only as an extra key that the parser must ignore, which is what the BE will send (`Quest.rankPrizes`, not selected in this phase). No finding.

**Helper cases that do prove their title:** the three «Caduto…» variants, the reached-turn line, the cleared dungeon, the zero total, and the three no-line outcomes all assert the exact string or null against fixtures that reach the intended branch.

---

_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard, read-only; nothing executed_


## Orchestrator rulings (2026-11-13)

| Id | Ruling |
|----|--------|
| WR-01 | **FIX (tests).** One titled case per uncovered behaviour of `dungeonTurnLine`: won aid without `lastTurn`, `turnsCompleted` absent read as 0, negative `turnsTotal`. Verify each new case goes red with the matching branch broken. |
| WR-02 | **FIX (tests).** The props case proves all four fields; one round-trip payload carries the four turn fields. |
| IN-01 | `not_needed`. The app prints `lastTurn` / `turnsCompleted` as served: the backend is the source of truth and a range guard would be a game rule on the device. The `turnsTotal` ≤ 0 guard stays as a display guard. |
| IN-02 | `not_needed` (pre-existing helper, unreachable with a GraphQL `Int`). |
| IN-03 | **FIX (test).** Pin the slot position from both sides. |
| IN-04 | **FIX (tests).** On the sheet: `rescued`, `death` and `gmCompleted` with the turn fields filled show no turn line; state in the test what the stages slot shows in that case, as the code does today. |
| IN-05 | **FIX** if it stays inside the fixtures and no assertion changes meaning; otherwise `skipped` with the reason. |
| IN-06 | **FIX** (Boy Scout): rename the misleading local, drop or update the comment made stale by D-22; model tests read the fields directly where a getter exists. |
