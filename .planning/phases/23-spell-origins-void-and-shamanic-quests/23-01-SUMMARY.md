---
phase: 23-spell-origins-void-and-shamanic-quests
plan: 01
subsystem: models
tags: [quest-type, wire-boundary, requirements, refactor]
requires: []
provides:
  - "QuestType.wireName / QuestType.fromWire: the only wire boundary of the quest type"
  - "ORIGIN-01..ORIGIN-06 in REQUIREMENTS with Pending traceability rows"
affects: [23-02, 23-03]
tech-stack:
  added: []
  patterns: ["enum wire boundary: wireName getter + static fromWire linear scan (null on unknown / non-string)"]
key-files:
  created: []
  modified:
    - .planning/REQUIREMENTS.md
    - lib/models/enums/quest_type.dart
    - lib/models/quest/quest_infos.dart
    - lib/models/pending_request/pending_request.dart
    - lib/models/mission/mission_draft.dart
    - lib/models/quest_result/quest_result_quest.dart
    - test/models/enums/quest_type_test.dart
    - test/models/quest/quest_test.dart
    - test/models/pending_request/pending_request_test.dart
    - test/models/mission/mission_draft_test.dart
    - test/models/quest_result/quest_result_test.dart
    - test/models/quest/quest_state_label_test.dart
    - test/models/quest/quest_availability_test.dart
decisions:
  - "wireName is a plain getter (=> name) with no constructor parameter in this plan; 23-03 adds the explicit wire name together with theVoid and the legacy magic -> arcane read"
  - "QuestInfos keeps its strictness through the private _typeOf helper (ArgumentError.value on a non-null unknown wire value), so Quest.tryFromJson still drops only that quest"
metrics:
  duration: "~20 min"
  completed: 2026-11-15
---

# Phase 23 Plan 01: Requirements and the quest type wire boundary Summary

ORIGIN-01..ORIGIN-06 written into REQUIREMENTS, and `QuestType` now crosses the wire only through `wireName` (write) and `QuestType.fromWire` (read) in all four parsers and both writers. Behaviour is unchanged, which clears the way for the reserved-word wire value `void` in 23-03.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 | Write ORIGIN-01..ORIGIN-06 into REQUIREMENTS | 4ae4a94e |
| 2 RED | Expect the quest type wire boundary | b9655ebe |
| 2 GREEN | Cross the wire through quest type wire names | 0848704b |
| 3 | Bookkeeping | (this docs commit) |

## TDD

- **RED (b9655ebe):** compile failure, as expected. `quest_type_test.dart`: `QuestType.fromWire` does not exist (the compiler reads `QuestType.fromWire(...)` as a constructor call, hence «Enums can't be instantiated»). `quest_type_test.dart`, `quest_state_label_test.dart:22/:114` and `quest_availability_test.dart:669/:672`: «The getter 'wireName' isn't defined for the type 'QuestType'». Run: `+397 -3`, three files failed to load.
- **Green at the first run** (reason: refactor, behaviour pinned before the move):
  - quest_test «QuestInfos stays strict on an unknown type and null on an absent one (D-09, Pitfall 4)»: `byName` already threw an `ArgumentError`
  - quest_test «QuestInfos writes the wire name of its type (D-09)»
  - pending_request_test and mission_draft_test «the quest type is read through its wire name (D-09)»
  - quest_result_test «a non-string quest type reads null (D-09)» and «the result snapshot writes the wire name of its type (D-09)»
- **GREEN (0848704b):** `flutter test test/models test/utils test/screens/mainScreen/tabs/board test/screens/innkeeper` → **1700 tests, all passed**. The narrower RED scope → 479 passed.

## Verification

- `grep -rnE "QuestType\.values\.(byName|asNameMap)" lib test` → nothing
- `fromWire` = 1 in quest_type.dart; `type?.wireName` = 1 in each writer, `type?.name` = 0; `QuestType.fromWire` = 1 in pending_request.dart and mission_draft.dart; `type: type.name` = 0 in both test files; `D-09` = 3 in quest_type_test.dart
- `lib/graphql` untouched (registry still 55); `character_quests.dart` untouched
- Formatter: all 12 touched files were clean before editing; `dart format` run one file at a time, 0 changed
- Analyzer: `47 issues found. (ran in 5.8s)`, which is 47 info / 0 warning / 0 error → `ANALYZE_GATE_OK`

## Deviations from Plan

One addition: quest_result_test got a separate case «a non-string quest type reads null (D-09)», because the plan asked for the non-string case without naming it. Otherwise the plan was executed exactly as written.

## Notes for 23-03

- `wireName` is still `=> name`. 23-03 adds the explicit wire name (constructor parameter) together with `theVoid` (wire `void`), `shamanic`, and the rename `magic` → `arcane`. It must also make `fromWire('magic')` read `arcane` (D-20). The tests that pin `'magic'` now are the existing quest_type_test «labelled Magia» case, the wire-name list test, the pending_request / mission_draft «read through its wire name» cases and the quest_result «writes the wire name» case: 23-03 updates them RED-first.

## Self-Check: PASSED
