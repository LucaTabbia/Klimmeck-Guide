---
phase: 17-unlockable-lore
plan: 01
subsystem: models
tags: [flutter, dart, graphql, equatable, lore, library]

requires: []
provides:
  - LoreType.label (Italian text, renamed from the shadowing extension getter `name`) and LoreType.isBestiary
  - tolerant Lore.type (unknown / missing / non-string wire type -> null, entry kept) and a Lore round trip of the wire type
  - shared lore fixtures loreJson / loreRefJson
  - LibraryDataPage widget test harness (pumpDataPage) pinning the Italian section titles
  - CharacterStatus.unlockedLore (List<String>) + CharacterFragment.statusFields selecting unlockedLore
affects: [17-02, 17-03, 17-04, 17-05, 17-06, 17-07, 17-08, 17-09, 17-10]

tech-stack:
  added: []
  patterns:
    - "Enum wire name via Enum.name + Italian text via a `label` extension getter (like QuestType.label)"
    - "Tolerant enum parsing with `values.asNameMap()[wire]`"

key-files:
  created:
    - test/models/enums/lore_type_test.dart
    - test/helpers/fixtures/lore_fixtures.dart
    - test/screens/mainScreen/tabs/library/library_data_page_test.dart
  modified:
    - lib/models/enums/lore_type.dart
    - lib/models/lore.dart
    - lib/screens/mainScreen/tabs/library/statesPages/library_data_page.dart
    - lib/models/character/character_status.dart
    - lib/graphql/fragments/character_fragment.dart
    - test/models/lore_test.dart
    - test/models/character/character_status_test.dart
    - test/graphql/character_fragment_test.dart

key-decisions:
  - "LoreTypeExtension.name renamed to label: Lore.toJson now writes the wire name and round trips (D-15)"
  - "Lore.fromJson reads type tolerantly via asNameMap: unknown/missing/non-string -> null, entry kept (D-16)"
  - "CharacterStatus.unlockedLore is const [] when absent or not a list, non-strings dropped, unmodifiable, carried by copyWith (D-01, D-19)"

requirements-completed: []

duration: ~15min
completed: 2026-11-07
---

# Phase 17 Plan 01: Lore type label, tolerant lore type and unlocked lore ids Summary

**`LoreType.label` + `isBestiary` replace the getter that shadowed `Enum.name` (so `Lore` round trips its wire type), `Lore.type` parses tolerantly, and `CharacterStatus.unlockedLore` is read from the `unlockedLore` field that `statusFields` now selects.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-11-07
- **Tasks:** 2/2
- **Files modified:** 11 (3 created, 8 modified)

## Accomplishments

- `LoreType.label` returns the Italian text, and `LoreType.name` gives the wire name again. `LoreType.isBestiary` is true only for `enemy`, `animal` and `plant`.
- `Lore.fromJson` reads the type through `LoreType.values.asNameMap()`. An unknown, missing or non-string type becomes `null` and the entry is kept. `Lore.fromJson(lore.toJson()) == lore`.
- The Library section titles read `.label`. A widget test pins «Mostri», «Animali», «Piante», «Città», «Regioni» and «Stati», and checks that «enemy» never appears.
- `CharacterStatus.unlockedLore` is parsed, serialised, copied and compared. `CharacterFragment.statusFields` selects `unlockedLore`, and that change landed in the same commit as the model (registry still 45).

## Task Commits

1. **Task 1 RED:** `49e5e13` test(models): expect the lore type label and its wire name
2. **Task 1 GREEN:** `9d1c4da` refactor(models): rename the lore type label and read types tolerantly
3. **Task 2 RED:** `624bd76` test(models): expect the unlocked lore ids on the status
4. **Task 2 GREEN:** `9462a3e` feat(models): read the unlocked lore ids of the character

## RED failures observed

- Task 1: `lore_type_test.dart` failed to compile (`The getter 'label' isn't defined for the type 'LoreType'` ×12, `The getter 'isBestiary' isn't defined`). The lore_test case «round trips its wire type (D-15)» failed with `Expected: 'enemy' Actual: 'Mostri'`. The case «reads an unknown or missing type as null and keeps the entry (D-16)» failed with `Invalid argument (name): No enum value with that name: "dragon"`.
- **Green on the first run:** library_data_page_test «titles the sections in Italian (D-15)». The shadowing getter `name` already returned the Italian text before the rename. The test exists to guard the rename (Pitfall 1): if a reader is left on `.name`, it still compiles but renders «enemy», and this test catches that.
- Task 2: `character_status_test.dart` failed to compile (`The getter 'unlockedLore' isn't defined for the type 'CharacterStatus'`). character_fragment_test «statusFields selects unlockedLore (D-01)» failed with `Expected: contains 'spellStates { usages recoveries spell { id } } unlockedLore }'`.

## Readers of `.name` on a LoreType (Task 1 grep)

`grep -rnE "LoreType|\.type\b" lib | grep "\.name"` → no output, both before and after the edit. A wider check, `grep -rn "type?\.name\|type!\.name\|types\[.*\]\.name" lib`, found only wire-name writers: `city.dart:60`, `base_damage.dart`, `energy_damage.dart`, `quest_infos.dart:49` and `quest_result_quest.dart:28`, which are other enums, plus `lore.dart:39` (`Lore.toJson`, which should write the wire name). The only reader that wanted the Italian text was `library_data_page.dart:68`, and it now reads `.label`.

## Files Created/Modified

- `lib/models/enums/lore_type.dart`: the extension getter is now `label`, plus `isBestiary`.
- `lib/models/lore.dart`: `static LoreType? _typeFrom(Object? wire)`.
- `lib/screens/mainScreen/tabs/library/statesPages/library_data_page.dart`: `sectionName: widget.types[typesIndex].label`.
- `lib/models/character/character_status.dart`: `this.unlockedLore = const []`, `final List<String> unlockedLore`, `static List<String> _unlockedLoreFrom(Object? json)`; also added to toJson, copyWith and props.
- `lib/graphql/fragments/character_fragment.dart`: `unlockedLore` placed after the `spellStates { … }` block, still inside `status { }`.
- `test/helpers/fixtures/lore_fixtures.dart`: `loreJson({id = 'lore-1', type = 'city', name = 'Talmvere', description = 'Un villaggio', image})` and `loreRefJson({id = 'lore-goblin', name = 'Goblin', type = 'enemy'})`.
- `test/screens/mainScreen/tabs/library/library_data_page_test.dart`: `pumpDataPage(tester, {required types, required title, lore = const []})`.

## Decisions Made

All taken from the plan: D-01, D-10, D-15, D-16 and D-19. No new decisions.

## Deviations from Plan

- **`pumpDataPage` passes `key: ValueKey(title)` to `LibraryDataPage`.** Reason: the test pumps the page twice in one run (Bestiario, then Luoghi). `LibraryDataPage` builds its lists in `initState`, so without a key the second pump would reuse the first state. The key forces a fresh state for each book. This only affects the test harness. Plan 17-07 rewrites this helper anyway.

Otherwise the plan was executed as written.

## Gates

- `flutter analyze`: `50 issues found.` (all info), 0 error, 0 warning → ANALYZE_GATE_OK after both tasks.
- Task 1 verify (4 files): 16 tests, all passed.
- Task 2 verify (`test/models test/graphql test/tool test/screens/mainScreen/characterCubit`): 787 tests, all passed. `test/screens/mainScreen/tabs/library`: 1 test, passed.
- `dart format` was run file by file on the 11 touched files, all of which were clean at baseline. It reflowed only `test/models/lore_test.dart` (one of my new lines) and `lib/models/enums/lore_type.dart` (the new `isBestiary` line). No untouched members were reflowed.
- Registry: `git diff HEAD~2 -- tool/schema_check/schema_check_documents.dart test/tool/schema_check_documents_test.dart` is empty (still 45 documents).

## Shared result files (D-18)

Not touched by this plan.

## Note: Pitfall 9 / D-14

From this plan on, the app selects `CharacterStatus.unlockedLore`. That field exists only on a BE that has Phase 16. This branch must never run against an older BE. The schema proof is plan 17-09, which is gated on the BE Phase 16 merge.

## Known Stubs

None.

## Threat Flags

None. T-17-01 is mitigated by the D-16 test and T-17-02 by the unlockedLore group. T-17-03 is accepted as planned.

## Self-Check: PASSED

- All 3 created files exist, and commits 49e5e13, 9d1c4da, 624bd76 and 9462a3e are in `git log`.
