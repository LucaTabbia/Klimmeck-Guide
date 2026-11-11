---
phase: 18-heal-quests-by-size
plan: 02
subsystem: models
tags: [models, lenient-parsing, potions, recovery, use-item, lore, tdd]
requires: ["18-01"]
provides:
  - "LootRecovery model (lib/models/loot_recovery.dart) and LootItem.recovery (nullable, lenient)"
  - "CharacterStatus.potionRecoveryUntil (nullable UTC DateTime, lenient, carried by copyWith)"
  - "UseItemResult model (lib/models/use_item_result.dart): strict numbers/date, lenient lists"
  - "shared lenient lore-ref reader Lore.lenientRefsFrom(Object?) used by QuestResult and UseItemResult"
  - "fixtures lootRecoveryJson, healPotionJson, ownedHealPotionJson, useItemResultJson (test/helpers/fixtures/potion_fixtures.dart)"
affects: [18-06, 18-07, 18-08, 18-09, 18-12]
tech-stack:
  added: []
  patterns: ["static tryFromJson parsing boundary returning null on malformed input", "lenient reader moved onto the model it builds"]
key-files:
  created:
    - lib/models/loot_recovery.dart
    - lib/models/use_item_result.dart
    - test/models/loot_recovery_test.dart
    - test/models/use_item_result_test.dart
    - test/helpers/fixtures/potion_fixtures.dart
  modified:
    - lib/models/loot_item.dart
    - lib/models/character/character_status.dart
    - lib/models/lore.dart
    - lib/models/quest_result/quest_result.dart
    - test/models/loot_item_test.dart
    - test/models/character/character_status_test.dart
    - test/models/lore_test.dart
decisions:
  - "LootRecovery.tryFromJson: `recovery.time` that is not an int or is <= 0 reads as null (the item stays, the potion is not drinkable); `turns` missing or malformed (null, negative, string, double) reads as 0 and the recovery is kept (D-13, D-21)"
  - "CharacterStatus.potionRecoveryUntil read with `DateTime.tryParse` behind an `is String` check and converted to UTC; anything else is null and the status stays (D-12, T-18-04)"
  - "UseItemResult.fromJson throws on missing/malformed hpBefore, hpAfter, quantityLeft, recoveryUntil (the repository of 18-06 maps the throw to unknown, T-18-07); injuriesHealed and loreUnlocked are lenient (D-11)"
metrics:
  duration: "~12 min"
  completed: 2026-11-10
  tasks: 2
  files: 12
---

# Phase 18 Plan 02: Potion models Summary

Lenient `LootRecovery` on `LootItem`, UTC `CharacterStatus.potionRecoveryUntil`, the strict/lenient `UseItemResult` answer of `useItem`, the lore-ref reader moved onto `Lore.lenientRefsFrom`, and the shared potion fixtures — nothing selected on the wire (gated plan 18-12), so both new fields read `null` today.

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | LootRecovery on LootItem and CharacterStatus.potionRecoveryUntil | `021bd74` (test), `dea9ac6` (feat) |
| 2 | Lenient lore refs on Lore and the UseItemResult model | `70e6a2d` (test), `4efcca2` (feat) |

## Names and signatures created

- `lib/models/loot_recovery.dart`: `class LootRecovery extends Equatable` — `const LootRecovery({required this.time, required this.turns})`; `final int time` (ms); `final int turns`; `Duration get duration`; `static LootRecovery? tryFromJson(Object? json)`; `Map<String, dynamic> toJson()` (`{'time', 'turns'}`); props `[time, turns]`.
- `LootItem`: optional ctor param `this.recovery` (last); `final LootRecovery? recovery`; fromJson `LootRecovery.tryFromJson(json['recovery'])`; toJson `'recovery': recovery?.toJson()`; `copyWith(LootRecovery? recovery)`; props `[...super.props, power, effect, canHeal, recovery]`.
- `CharacterStatus`: optional ctor param `this.potionRecoveryUntil` (after `unlockedLore`); `final DateTime? potionRecoveryUntil`; private `static DateTime? _instantOrNull(Object? json)`; toJson `"potionRecoveryUntil": potionRecoveryUntil?.toUtc().toIso8601String()`; `copyWith` carries it by hand (no parameter); props end with `potionRecoveryUntil`.
- `lib/models/use_item_result.dart`: `class UseItemResult extends Equatable` — `const UseItemResult({required hpBefore, required hpAfter, required injuriesHealed, required quantityLeft, required recoveryUntil, required loreUnlocked})`; `factory UseItemResult.fromJson(Map<String, dynamic> json)`; `Map<String, dynamic> toJson()`.
- `Lore`: `static List<Lore> lenientRefsFrom(Object? json)` + private `_refOrNull`; `QuestResult._loreUnlockedFrom` / `_loreRefOrNull` deleted.
- Fixtures `test/helpers/fixtures/potion_fixtures.dart`: `lootRecoveryJson({Object? time = 1800000, Object? turns = 3})`, `healPotionJson({id = 'l-herb', name = 'Erbe da campo', power = 400, canHeal = const ['contusion'], Object? recovery = <default lootRecoveryJson()>})`, `ownedHealPotionJson({quantity = 2, item})`, `useItemResultJson({hpBefore = 4, hpAfter = 8, injuriesHealed = const ['contusion'], quantityLeft = 1, Object? recoveryUntil = '2026-10-27T10:30:00.000Z', loreUnlocked = const []})`.

Rule restated: `recovery.time` <= 0 (or not an int) reads as null; `turns` missing or malformed reads as 0 and the recovery is kept (D-21).

## RED failures observed

- Task 1: `test/models/loot_recovery_test.dart:2:8: Error: Error when reading 'lib/models/loot_recovery.dart': No such file or directory`; `loot_item_test.dart:4:8` same missing file; `character_status_test.dart:258:48: Error: The getter 'potionRecoveryUntil' isn't defined for the type 'CharacterStatus'.`
- Task 2: `lore_test.dart:62:25: Error: Member not found: 'Lore.lenientRefsFrom'.`; `use_item_result_test.dart:4:8: Error: Error when reading 'lib/models/use_item_result.dart': No such file or directory`.
- No case green at the first run (all RED were compile failures). The existing `loreUnlocked` group of `quest_result_test.dart` stayed green untouched (extraction guard; `git diff HEAD~2 -- test/models/quest_result/quest_result_test.dart` empty).

## Gates

- `flutter test test/models`: 730 tests, all passed (720 after Task 1; +27 new cases in the plan). `flutter test test/models test/shared/components/popup/quest_result_sheet_test.dart`: 784 passed. Consumers `flutter test test/graphql test/repository`: 1001 passed.
- `flutter analyze --no-fatal-infos`: `47 issues found.` (all info, 0 error, 0 warning — unchanged).
- `dart format` run file by file on every touched file; reflows only on new code (loot_item props list split over lines, test files). No formatter-dirty candidate touched.
- No change under `lib/graphql`; no Flutter import in the new/modified models.

## Deviations from Plan

None - plan executed exactly as written. (The plan's bookkeeping numbers `02/13` / `Plan: 02 of 13` were written as `2/13` / `Plan: 2 of 13` per the orchestrator.)

## Threat mitigations

T-18-04, T-18-05, T-18-06, T-18-07 covered by the tests named in the plan's threat register.

## Self-Check: PASSED

All created files exist; commits 021bd74, dea9ac6, 70e6a2d, 4efcca2 present in `git log`.
