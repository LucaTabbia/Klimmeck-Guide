---
phase: 18-heal-quests-by-size
plan: 01
subsystem: models
tags: [models, lenient-parsing, quest-cure, injuries, tdd]
requires: []
provides:
  - "QuestCure model (lib/models/quest/quest_cure.dart)"
  - "QuestPrizes.cure (nullable, lenient)"
  - "QuestResult.injuriesHealed (List<InjuryType>, lenient, default empty)"
  - "shared top-level reader injuryTypesFrom(Object?) in lib/models/enums/injury_type.dart"
  - "fixtures questCureJson, healResultJson; questResultJson(injuriesHealed:)"
affects: [18-04, 18-05, 18-12]
tech-stack:
  added: []
  patterns: ["additive lenient field on QuestPrizes (precedent: pet)", "one shared lenient enum-list reader"]
key-files:
  created:
    - lib/models/quest/quest_cure.dart
    - test/models/quest/quest_cure_test.dart
  modified:
    - lib/models/enums/injury_type.dart
    - lib/models/quest/quest_prizes.dart
    - lib/models/loot_item.dart
    - lib/models/character/character_status.dart
    - lib/models/quest_result/quest_result.dart
    - test/models/enums/injury_type_test.dart
    - test/models/quest/quest_test.dart
    - test/models/quest_result/quest_result_test.dart
    - test/helpers/fixtures/quest_fixtures.dart
    - test/helpers/fixtures/quest_result_fixtures.dart
decisions:
  - "QuestCure.tryFromJson rejects (null) a non-map, a share that is not a finite num in [0, 1], a canHeal that is not a list; unknown injury names are dropped and the cure stays (D-01)"
  - "injuriesHealed is read without cast (lenient), unlike injuriesAdded whose strict `as List` cast is kept (D-02)"
metrics:
  duration: "~20 min"
  completed: 2026-11-10
  tasks: 2
  files: 12
---

# Phase 18 Plan 01: Quest cure models Summary

Lenient `QuestCure` (`lifePointsShare` double 0..1 + `canHeal` injuries) on `QuestPrizes.cure`, `QuestResult.injuriesHealed`, and one shared `injuryTypesFrom` reader replacing three private copies — no wire selection (gated plan 18-12).

## What was built

- `lib/models/enums/injury_type.dart`: top-level `List<InjuryType> injuryTypesFrom(Object? json)` (non-list → `const []`, unknown names/non-strings dropped, unmodifiable result, wire order kept).
- `lib/models/quest/quest_cure.dart`: `class QuestCure extends Equatable` — `const QuestCure({required double lifePointsShare, required List<InjuryType> canHeal})`, `static QuestCure? tryFromJson(Object? json)`, `Map<String, dynamic> toJson()` (`canHeal` as names), `copyWith({double? lifePointsShare, List<InjuryType>? canHeal})`, `props [lifePointsShare, canHeal]`. No Flutter import.
- `QuestPrizes`: optional ctor param `this.cure` (after `pet`), `fromJson` `cure: QuestCure.tryFromJson(json['cure'])`, `toJson` `"cure": cure?.toJson()`, `copyWith(QuestCure? cure)`, `props` include `cure`.
- `QuestResult`: optional ctor param `this.injuriesHealed = const []` (last in the optional tail), `fromJson` `injuryTypesFrom(json['injuriesHealed'])`, `toJson` after `injuriesAdded`, `props` after `injuriesAdded`.
- Boy Scout: `loot_item.dart` `_canHealFrom`, `character_status.dart` `_injuriesFrom`, `quest_result.dart` `_injuriesFrom` deleted; all call `injuryTypesFrom` (the strict `json['injuriesAdded'] as List` cast stays).
- Fixtures: `questCureJson({Object? share = 0.5, Object? canHeal = const ['contusion', 'deepCut']})` in `quest_fixtures.dart`; `questResultJson` gains `List<Object?> injuriesHealed = const []` (written right after `injuriesAdded`); `healResultJson({int hpBefore = 3, int hpAfter = 6, List<Object?> injuriesHealed = const ['contusion']})` = `questResultJson(questType: 'heal', injuriesAdded: const [], enemies: const [], …)`.

## TDD record

- Task 1 RED (`422d153`): compile failures — `Method not found: 'injuryTypesFrom'` (injury_type_test), `Error when reading 'lib/models/quest/quest_cure.dart': No such file or directory` / `Undefined name 'QuestCure'` (quest_cure_test), `The getter 'cure' isn't defined for the type 'QuestPrizes'` (quest_test). GREEN (`7423e97`): 41 tests passed across the three files. REFACTOR (`b5be04f`): `flutter test test/models` 696 passed.
- Task 2 RED (`f37bd6f`): `The getter 'injuriesHealed' isn't defined for the type 'QuestResult'`. GREEN (`05dc5c7`): `flutter test test/models test/shared/components/popup/quest_result_sheet_test.dart test/screens/mainScreen/questResultsCubit test/graphql test/repository` → 1846 passed.
- No case green at first run (all RED were compile failures).

## Gates

- `flutter analyze --no-fatal-infos`: last line `47 issues found.` (all info, 0 error, 0 warning — baseline unchanged), after each code task.
- `dart format` run one by one on every touched file; only `quest_cure_test.dart` and `quest_test.dart` were reflowed (new code only); no formatter-dirty candidate touched.
- `git diff f8d0929 --stat -- lib/graphql`: empty (no selection in this plan).

## Deviations from Plan

- `healResultJson` also passes `questType: 'heal'`, `injuriesAdded: const []` and `enemies: const []` (the plan allowed passing the quest type; the empty injuries/enemies make the doc «nessun nemico» true). No existing helper signature changed beyond the added `injuriesHealed` parameter.
- The test «QuestPrizes writes, copies and compares its cure» compares a prizes with cure vs one built from `{}` (both differ only by cure, all other fields null).

Otherwise plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Files: `lib/models/quest/quest_cure.dart`, `test/models/quest/quest_cure_test.dart` exist.
- Commits: 422d153, 7423e97, b5be04f, f37bd6f, 05dc5c7 present in `git log`.
