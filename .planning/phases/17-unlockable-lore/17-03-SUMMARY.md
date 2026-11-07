---
phase: 17-unlockable-lore
plan: 03
subsystem: results
tags: [flutter, dart, graphql, equatable, quest-results, lore]

requires:
  - 17-01 (Lore.fromJson tolerant type, LoreType.isBestiary, loreRefJson fixture)
  - 17-02 (QuestEnemy.known, QuestResultFragment enemies selection)
provides:
  - QuestResult.loreUnlocked (List<Lore>, lenient per entry, const [] when absent/non-list, round trips)
  - QuestResultFragment selects `loreUnlocked { id name type }` right after `spellLearned { id name }`
  - questResultJson(loreUnlocked: const [] by default, always written)
  - QuestResultSheet.loreUnlockedKeyOf(id), bestiaryPagePrefix, knowledgePrefix and the lines after «Magia appresa»
affects: [17-09, 17-10]

tech-stack:
  added: []
  patterns:
    - "Lenient list of BE refs: whereType<Map> + try/catch per entry + nonNulls, unmodifiable"

key-files:
  created: []
  modified:
    - lib/models/quest_result/quest_result.dart
    - lib/graphql/fragments/quest_result_fragment.dart
    - lib/shared/components/popup/quest_result_sheet.dart
    - test/helpers/fixtures/quest_result_fixtures.dart
    - test/models/quest_result/quest_result_test.dart
    - test/graphql/quest_result_documents_test.dart
    - test/shared/components/popup/quest_result_sheet_test.dart

key-decisions:
  - "QuestResult.loreUnlocked reuses Lore (no LoreRef model): an entry without id, without name or with an empty name is dropped, the result stays (D-04)"
  - "Result lines: isBestiary -> «Nuova pagina del Bestiario: », any other or null type -> «Conoscenza appresa: », BE order, no outcome branch (D-10, D-16)"

requirements-completed: []

duration: 4min
completed: 2026-11-07
---

# Phase 17 Plan 03: Lore unlocked on the quest result Summary

**`QuestResult.loreUnlocked` parsed leniently from `loreUnlocked { id name type }` and rendered as «Nuova pagina del Bestiario» / «Conoscenza appresa» lines after «Magia appresa», in BE order.**

## Performance

- Duration: ~4 min (2026-11-07T12:04Z – 12:08Z)
- Tasks: 2/2, 4 code commits + 1 docs commit

## Accomplishments

- `lib/models/quest_result/quest_result.dart`: optional named ctor param `this.loreUnlocked = const []` (last, after `acknowledgedAt`); field `final List<Lore> loreUnlocked` after `spellLearned`; `fromJson` reads `_loreUnlockedFrom(json['loreUnlocked'])` right after `spellLearned`; `static List<Lore> _loreUnlockedFrom(Object? json)` (non-list → `const []`, `whereType<Map<String, dynamic>>().map(_loreRefOrNull).nonNulls`, unmodifiable); `static Lore? _loreRefOrNull(Map<String, dynamic> json)` (try/catch on `Lore.fromJson`, null/empty name → null); `toJson` writes `'loreUnlocked': [{id, name, type: type?.name}]` after `spellLearned`; `props` after `spellLearned`.
- `lib/graphql/fragments/quest_result_fragment.dart`: `loreUnlocked { id name type }` between `spellLearned { id name }` and `enemies { … }`; doc line «`loreUnlocked` è della BE Phase 16 (17-CONTEXT D-04): solo le novità dell'esito.» Registry still 45.
- `lib/shared/components/popup/quest_result_sheet.dart`: `static Key loreUnlockedKeyOf(String loreId) => ValueKey('questResult.loreUnlocked.$loreId')`, `static const String bestiaryPagePrefix = 'Nuova pagina del Bestiario: '`, `static const String knowledgePrefix = 'Conoscenza appresa: '`; `_content()` spreads `..._loreUnlockedLines()` right after the spell-learned line; `_loreUnlockedLines()` / `_loreUnlockedText(Lore)` reuse `_line` (plain `Text`, `bodyMedium`).
- Fixture `questResultJson` gains `List<Object?> loreUnlocked = const []` and always writes `'loreUnlocked'` after `'spellLearned'`.

## Task Commits

1. Task 1 RED — `ed38c85` test(models): expect the lore unlocked by a quest result
2. Task 1 GREEN — `be45cf0` feat(models): read the lore unlocked by a quest result (model + fragment in one commit)
3. Task 2 RED — `ef1784f` test(results): expect the lore unlocked lines on the sheet
4. Task 2 GREEN — `9ec247b` feat(results): list the lore unlocked by the outcome

## RED failures observed

- Task 1: `quest_result_test.dart` compile error «The getter 'loreUnlocked' isn't defined for the type 'QuestResult'»; `quest_result_documents_test.dart` «selects the lore unlocked by the outcome (D-04)» failed with `does not contain 'spellLearned { id name } loreUnlocked { id name type }'` (other 18 cases green).
- Task 2: `quest_result_sheet_test.dart` compile error «Member not found: 'QuestResultSheet.loreUnlockedKeyOf'».
- No case was green at the first run.

## Tests and gates

- Task 1 verify (`test/models test/graphql test/tool test/shared/components/popup test/screens/mainScreen/questResultsCubit test/screens/mainScreen/components`): +1091 all passed.
- Task 2 verify (`test/shared/components/popup test/screens/mainScreen/components`): +246 all passed.
- Plan verification (`test/models test/graphql test/tool test/shared test/screens/mainScreen/questResultsCubit test/screens/mainScreen/components`): +1223 all passed.
- `flutter analyze`: «50 issues found.» (all info), 0 error, 0 warning after each code task.
- `dart format` run one by one on the 7 touched files; only new lines reflowed (test files and `quest_result.dart` had their new lines reflowed, the fragment and the sheet were already clean).
- `git diff a954c6d -- tool/schema_check/schema_check_documents.dart test/tool/schema_check_documents_test.dart` empty; no `package:flutter/` import in `lib/models/quest_result`.

## Deviations from Plan

- Acceptance grep `grep -c "'loreUnlocked'" lib/models/quest_result/quest_result.dart` = 1 in the plan prints **2**: the plan's own skeleton writes the literal twice (`json['loreUnlocked']` in `fromJson` and the `'loreUnlocked':` key in `toJson`). Code follows the skeleton; the grep expectation was a planning slip (REPO-RULES «skeleton literals» trap). No code change.
- Otherwise none — plan executed as written.

## Shared files with the parked FE Phase 16 (CONTEXT D-18)

`quest_result.dart`, `quest_result_fragment.dart`, `quest_result_sheet.dart`, `quest_result_fixtures.dart`, `quest_result_test.dart`, `quest_result_documents_test.dart`, `quest_result_sheet_test.dart` are shared with `feat/16-travel-ambushes`: every edit is additive and local (new field/param/selection/fixture key after `spellLearned`, lines after «Magia appresa», a new test group in each test file, one new import per file).

## D-14 note

`QuestResultFragment` now selects `loreUnlocked`, a BE Phase 16 field: GetQuestResult, ListUnacknowledgedQuestResults and OnQuestResultReceived fail validation against a BE without Phase 16 (port 3001 runs develop `9103440`). The branch must not run against it until the BE merge (Pitfall 9).

## Known Stubs

None.

## Threat Flags

None — T-17-07 (per-entry drop, «drops malformed entries and keeps the result (D-04)»), T-17-08 (plain `Text` via `_line`), T-17-09 (no `outcome` branch: `grep -c outcome` on the sheet stays 5) mitigated as planned.

## Self-Check: PASSED
