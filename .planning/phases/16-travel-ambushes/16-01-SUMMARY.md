---
phase: 16-travel-ambushes
plan: 01
subsystem: models
tags: [flutter, dart, graphql, equatable, quest-result, ambush]

requires: []
provides:
  - QuestResultKind { quest, ambush } with tolerant fromWire (missing/unknown/non-string -> quest)
  - AmbushCity { id, name } (strict: empty name throws FormatException)
  - AmbushReport { at (UTC), nearCity, reachedCity? } (strict inside, reachedCity optional)
  - QuestResult.kind / ambush / isAmbush with nullable quest
  - QuestResultFragment selects kind and ambush { at nearCity { id name } reachedCity { id name } }
  - fixtures ambushCityJson, ambushReportJson, ambushWonResultJson, ambushLostResultJson
affects: [16-02, 16-03, 16-04, 16-05, 16-06, 16-07, 16-08]

tech-stack:
  added: []
  patterns:
    - "Tolerant enum on the wire with a non-null default (fromWire ?? quest)"
    - "Kind-gated nested block: ambush parsed only when kind == ambush, quest required only when kind == quest"

key-files:
  created:
    - lib/models/quest_result/quest_result_kind.dart
    - lib/models/quest_result/ambush_city.dart
    - lib/models/quest_result/ambush_report.dart
    - test/models/quest_result/quest_result_kind_test.dart
    - test/models/quest_result/ambush_report_test.dart
  modified:
    - lib/models/quest_result/quest_result.dart
    - lib/graphql/fragments/quest_result_fragment.dart
    - lib/shared/components/popup/quest_result_sheet.dart
    - test/models/quest_result/quest_result_test.dart
    - test/graphql/quest_result_documents_test.dart
    - test/helpers/fixtures/quest_result_fixtures.dart

key-decisions:
  - "An ambush payload may still carry a quest map (parsed if a Map, else null); a quest result without quest is dropped (D-01)"
  - "An ambush block on a kind == quest result is ignored (ambush stays null) (D-01)"

requirements-completed: []

duration: 6min
completed: 2026-11-06
---

# Phase 16 Plan 01: Ambush result models Summary

**`QuestResultKind` (tolerant), `AmbushCity`, `AmbushReport` and `QuestResult.kind/ambush/isAmbush` with a nullable `quest`, the `QuestResultFragment` selection and the null-safe sheet header landed in one commit; registry still 45 documents.**

## Performance

- Duration: ~6 min
- Completed: 2026-11-06
- Tasks: 2 (4 commits, TDD red/green each)
- Files: 5 created, 6 modified

## Accomplishments

- `lib/models/quest_result/quest_result_kind.dart`: `enum QuestResultKind { quest, ambush; static QuestResultKind fromWire(Object? value) }` — missing, unknown or non-string reads as `quest`.
- `lib/models/quest_result/ambush_city.dart`: `class AmbushCity extends Equatable { const AmbushCity({required String id, required String name}); factory AmbushCity.fromJson(Map<String, dynamic>); Map<String, dynamic> toJson(); }` — empty `name` throws `FormatException('ambush city without a name')`.
- `lib/models/quest_result/ambush_report.dart`: `class AmbushReport extends Equatable { const AmbushReport({required DateTime at, required AmbushCity nearCity, AmbushCity? reachedCity}); factory AmbushReport.fromJson(...); toJson(); }` — `at` parsed `.toUtc()`.
- `QuestResult`: constructor gains optional `kind = QuestResultKind.quest` and `ambush`; `final QuestResultQuest? quest`; `final QuestResultKind kind`; `final AmbushReport? ambush`; `bool get isAmbush`; private `_questOrNull`; `toJson` writes `'kind'`, `'quest': quest?.toJson()`, `'ambush': ambush?.toJson()`; `props` gain `kind` (after `outcome`) and `ambush` (before `acknowledgedAt`).
- `QuestResultFragment.fields`: `kind` right after `outcome`; `ambush { at nearCity { id name } reachedCity { id name } }` after `rescuedCharacters`. The four documents interpolating it follow; `tool/schema_check/schema_check_documents.dart` and its count test untouched (45).
- `QuestResultSheet._header()` now spreads `_questTitle()` (empty for a null quest); no `_result.quest.` read left. The ambush header itself is 16-03.

## Task Commits

1. Task 1 RED — `a1fd31c` test(models): expect the ambush report and the result kind
2. Task 1 GREEN — `b2d580a` feat(models): parse ambush reports and the result kind
3. Task 2 RED — `88b6ab6` test(models): expect ambush results with a nullable quest
4. Task 2 GREEN — `000b0eb` feat(models): read ambush results with a nullable quest (model + fragment + sheet header + 8 null-aware test reads, same commit, D-14)

## RED failures observed

- Task 1: compile failure — `ambush_report_test.dart: Error: Undefined name 'AmbushReport'` (and the missing `quest_result_kind.dart` / `ambush_city.dart` imports); `Some tests failed`.
- Task 2: `quest_result_test.dart:375:21: Error: The getter 'kind' isn't defined for the type 'QuestResult'` (plus `isAmbush`, `ambush`); `quest_result_documents_test.dart`: «selects the result kind right after the outcome (D-01)» `Expected: contains 'outcome kind resolvedAt acknowledgedAt'` and «selects the ambush report with its two cities (D-01)» `Expected: contains 'ambush { at nearCity { id name } reachedCity { id name } }'` both failed on the actual selection.
- Green-at-first-run in substance (RED only by compilation of the file): «drops a quest result without its quest (D-01)» — the old `json['quest'] as Map` cast already threw inside `tryFromJson`; the test pins it now that `quest` is nullable.

## Tests

- `flutter test test/models/quest_result` → 58 passed after Task 1.
- `flutter test test/models test/graphql test/tool test/shared/components/popup/quest_result_sheet_test.dart test/screens/mainScreen/questResultsCubit test/screens/mainScreen/components/quest_result_presenter_test.dart test/repository` → `+1652: All tests passed!` after Task 2.
- New tests: 2 (kind) + 5 (ambush report) + 8 (ambush group) + 2 round-trip entries + 2 fragment = 19.

## Gates

- `flutter analyze` → `50 issues found.` (all info; error/warning count 0) after each GREEN.
- `dart format` run file by file on every touched file; only `lib/models/quest_result/quest_result.dart` and `test/graphql/quest_result_documents_test.dart` changed under the formatter (re-indentation of the new block body / the new test line), no untouched member reflowed.
- `grep -rn "package:flutter/" lib/models/quest_result` → nothing.
- Trailer check → `0` on all commits.

## Deviations from Plan

None - plan executed exactly as written. (The «throws on a missing instant or near city» test uses `..['nearCity'] = {'id': 'city-andogan'}` for «nearCity without name» and `ambushCityJson(name: '')` for the empty name, as `<behavior>` lists.)

## Pitfall 7 / D-15 note

From this plan on, the app selects `kind` and `ambush { … }`, fields that exist only on a BE with Phase 15. The branch must never run against an older BE (the running BE on port 3001 is built from `develop` without Phase 15: every `QuestResultFragment` document would fail validation there). The schema proof is 16-07 (gated on the BE merge).

## Known Stubs

None.

## Next Phase Readiness

- 16-02+ can branch on `result.isAmbush` and read `result.ambush!.nearCity.name` / `reachedCity?.name`; fixtures `ambushWonResultJson()` (id `ambush-won`, resolvedAt `2026-10-27T11:20:00.000Z`, Bandito x2, xpGained 35, coins 1 silver 40 copper) and `ambushLostResultJson()` (id `ambush-lost`, resolvedAt `2026-10-27T11:40:00.000Z`, outcome failure, hpAfter 1, injury deepCut, Orco, reachedCity `city-bosa`/Bosa).

## Self-Check: PASSED
