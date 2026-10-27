---
phase: 08-spells-section-journal-tab
plan: 13
subsystem: ui
tags: [flutter, dart, spells, shop, filter, journal, tdd]

# Dependency graph
requires:
  - phase: 08-11
    provides: "`SpellsSection` (`_SpellsSectionBodyState` with `_follow`) and `SpellbookContent` (slot row + known rows)"
  - phase: 08-12
    provides: "Device UAT 12/12 that triggered the extension (08-CONTEXT D-22..D-28)"
provides:
  - "`lib/utils/filter_values.dart`: `presentFilterValues`, `retainedFilterSelection`, `presentEquipTypes`, `presentEffectTypes` (pure, enum order, nulls dropped)"
  - "`ItemsFilter<T>` promoted to `lib/shared/components/items_filter.dart` with a typed `ValueChanged<T?> onTap`"
  - "`spellDamageLabel(EnergyDamage?, {UseType? useType})`: «Attacco: Fuoco 12» in the row line and the detail sheet, «Danno: …» without use type"
  - "`UseType` chips between the slot row and the known rows of «Magie imparate» (local `setState` selection, vanished type → «Tutti»)"
  - "Shop chips limited to the `EquipType`/`EffectType` of the listed goods; chip row hidden when no type is present"
affects: [08-14]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Present-values filter: chips computed from the listed data (`presentFilterValues`) and the selection re-validated at every build (`retainedFilterSelection`), so no chip ever yields an empty list"
    - "Filter state owned by the stateful section body, pushed down to a stateless content widget as `value + ValueChanged`"

key-files:
  created:
    - lib/utils/filter_values.dart
    - test/utils/filter_values_test.dart
    - test/shared/components/items_filter_test.dart
    - .planning/phases/08-spells-section-journal-tab/08-13-SUMMARY.md
  modified:
    - lib/shared/components/items_filter.dart (moved from lib/screens/mainScreen/tabs/shop/components/items_filter.dart)
    - lib/screens/mainScreen/tabs/shop/components/shop_modal.dart
    - lib/utils/spell_lines.dart
    - lib/shared/components/spell_info.dart
    - lib/screens/mainScreen/tabs/journal/components/spellbook_content.dart
    - lib/screens/mainScreen/tabs/journal/sections/spells_section.dart
    - test/utils/spell_lines_test.dart
    - test/shared/components/spell_info_test.dart
    - test/screens/mainScreen/tabs/journal/components/known_spell_row_test.dart
    - test/screens/mainScreen/tabs/journal/components/spellbook_content_test.dart
    - test/screens/mainScreen/tabs/journal/sections/spells_section_test.dart
    - test/helpers/spells_harness.dart
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "The vanished-selection fallback lives in two places by design: `SpellbookContent` re-validates the incoming filter at build (stateless correctness), `_SpellsSectionBodyState` drops it from its own state on a new character so it is not resurrected when the type comes back"
  - "The listener became `_onCharacter(state)` (follow the countdown + drop a vanished filter) instead of an inline lambda"
  - "`SpellbookContent` computation extracted into `_presentUseTypes()` and `_entriesOf(filter)` to keep `build` short"

patterns-established:
  - "Chip finders in widget tests are scoped to `ItemsFilter<UseType>` because `SpellCard`s draw the same use-type SVG"

requirements-completed: [SPELL-08, SPELL-09, SHOP-01]

# Metrics
duration: ~35 min
completed: 2026-10-27
---

# Phase 8 Plan 13: Present-Types Filter, Use-Type Spell Line and Shop Chips Summary

**A pure present-values helper drives `UseType` chips on the known spells (slot row untouched, vanished type → «Tutti») and the shop chips (only the types on sale); `ItemsFilter` is now shared, and the spell line reads «Attacco: Fuoco 12» with «Danno» kept for spells without use type.**

## Performance

- **Completed:** 2026-10-27
- **Tasks:** 3 (all auto, TDD)
- **Files modified:** 7 lib (1 created, 1 moved) + 8 test (2 created) + 3 planning documents

## Accomplishments

- **Helper (`filter_values.dart`):** `presentFilterValues<T extends Enum>` keeps enum order and drops nulls/duplicates; `retainedFilterSelection` returns null for a vanished selection; `presentEquipTypes`/`presentEffectTypes` read `item?.asEquipment?.equipType` / `item?.asLoot?.effect` null-safely (T-8-41).
- **Shared widget:** `ItemsFilter<T>` moved with `git mv` to `lib/shared/components/`, relative imports fixed, callback typed `ValueChanged<T?>`, doc comment added; layout/sizes/colors unchanged (D-19).
- **Shop (SHOP-01):** both chip rows fed with the present types, selection re-validated, the `!`/`as` casts on the filter lines replaced with null-safe reads; a chip row with no type present is hidden.
- **Spell line (SPELL-09, D-24):** `spellDamageLabel(damage, useType:)` prefixes the use-type label (`useType?.label ?? 'Danno'`); used by `spellSummaryLine` and `SpellInfo._detailLines`; the sheet keeps «Uso: Attacco» with its icon.
- **Spells filter (SPELL-08, D-22, D-23, D-28):** `SpellbookContent` takes `useTypeFilter` + `onUseTypeFilterChanged`, shows `ItemsFilter<UseType>` between the slot row and the known rows only when a use type is present, filters only the known rows (T-8-42); `_SpellsSectionBodyState` owns `_useTypeFilter` (`setState`, never persisted or sent, T-8-43) and drops it when the type disappears from a new character.

## Task Commits

1. **Task 1 RED** — `d751fca` `test(filters): add failing tests for the present filter values`
2. **Task 1 REFACTOR** — `b5415e4` `refactor(shop): move ItemsFilter to the shared components`
3. **Task 1 GREEN** — `e52a805` `feat(filters): limit the filter chips to the present types`
4. **Task 2 RED** — `a0d0a35` `test(spells): expect the use-type label in the spell line`
5. **Task 2 GREEN** — `3bf05fe` `feat(spells): introduce the spell energy with its use type`
6. **Task 3 RED** — `cd553d7` `test(spells): add failing tests for the use-type filter`
7. **Task 3 GREEN** — `4e3f273` `feat(spells): filter the known spells by use type`
8. **Docs** — `docs(phase-8): complete the 08-13 filter and spell line plan` (this commit)

## RED evidence

- **Task 1:** `items_filter_test.dart` — `Error when reading 'lib/shared/components/items_filter.dart': No such file or directory` / `Method not found: 'ItemsFilter'`; `filter_values_test.dart` — missing `lib/utils/filter_values.dart` (compile failure). After the move commit `items_filter_test.dart` passed (3/3) as the plan anticipated; `filter_values_test.dart` stayed red until `e52a805`.
- **Task 2:** `spell_lines_test.dart:116:34: Error: No named parameter with the name 'useType'.` (6 sites); widget tests `Expected: exactly one matching candidate / Actual: _TextWidgetFinder:<Found 0 widgets with text "Attacco: Fuoco 12": []>` — run `+116 -9: Some tests failed.`
- **Task 3:** `spellbook_content_test.dart:76:7: Error: No named parameter with the name 'useTypeFilter'.`; `spells_section_test.dart` `use-type filter a chip filters the known rows, «Tutti» restores them [E]` and `… a vanished type drops the selection for good [E]` — run `+114 -3: Some tests failed.`

## Verification

- Task 1 verify: `flutter test test/utils/filter_values_test.dart test/shared/components/items_filter_test.dart` → `+10: All tests passed!`; old path gone; no `shop/components/items_filter.dart` import left.
- Task 2 verify: `flutter test test/utils/spell_lines_test.dart test/shared/components/spell_info_test.dart test/shared/components/popup test/screens/mainScreen/tabs/journal` → `+190: All tests passed!`; no `Danno: Fuoco` left in `test/screens`/`test/shared`; scoped analyze `No issues found!`.
- Task 3 verify: `flutter test test/screens/mainScreen/tabs/journal test/shared test/utils` → `+331: All tests passed!`; scoped analyze 2 pre-existing infos (`avoid_print` in `journal_cubit.dart`).
- Full suite: `flutter test` → `00:51 +2119: All tests passed!`
- `flutter analyze`: 53 issues (all info), 0 errors.
- `dart format --output=none --set-exit-if-changed` on the 15 code/test files of `files_modified` → exit 0 (0 changed); no other file formatted.
- Commit messages: no trailer of any kind (`git log 36fd7c8..HEAD --format=%B | grep -ci "co-authored\|generated"` = 0).

## Decisions Made

See frontmatter `key-decisions`.

## Deviations from Plan

### Notes against the acceptance criteria

**1. `'Danno: ` grep on lib** — the criterion "`grep -rn "'Danno: \|\"Danno: " lib` lists only `lib/utils/spell_lines.dart`" now yields zero hits everywhere: with the D-24 code given by the plan the literal is `'Danno'` (as `useType?.label ?? 'Danno'`) and the `: ` is in the interpolation `'$prefix: …'`. The intent (no other file builds the string; `equipment_info_sheet.dart` untouched) holds; `grep -c "useType?.label ?? 'Danno'" lib/utils/spell_lines.dart` = 1.

**2. `ItemsFilter` doc comment line length** — the one-line doc comment prescribed by the plan is longer than 80 columns; `dart format` does not wrap comments and the analyzer has no `lines_longer_than_80_chars` rule, so it was kept verbatim.

**3. Listener refactor** — the plan offered either an inline listener body or a `_onCharacter(CharacterState)` method; the method was chosen (named, single call site). `_dropVanishedUseTypeFilter` is not called from `initState`, as prescribed.

**4. Extra test in `spellbook_content_test.dart`** — the chip-tap test also asserts `gestures.toggles` stays empty (a chip tap never toggles a spell), alongside the `verifyNever(spellsCubit.toggle)` checks in `spells_section_test.dart`.

---

**Total deviations:** 0 auto-fixes; 4 notes (1 acceptance-grep wording, 3 choices within the plan's options).

## Issues Encountered

- `flutter test test/screens/mainScreen/tabs/shop` reports a load failure because the directory does not exist (there are no shop widget tests); the shop change is covered by the helper unit tests and the analyzer.

## Known Stubs

None.

## Threat Flags

None — no network, GraphQL, repository, cubit or BE change; the filter is `setState` view state. T-8-41 (null-safe reads, nulls dropped), T-8-42 (slot row always fed with `spellbook.slots`, `_slot('b')` found under «Attacco»), T-8-44 (no chrome/loader, existing SVGs and theme tokens) mitigated; T-8-43/T-8-45 accepted as planned (grep on `SharedPreferences` = 0; «Danno» kept without use type).

## Next

Plan 08-14 (effect labels + filter for the items) on `feat/08-spells-section-journal-tab`, reusing `filter_values.dart` and the shared `ItemsFilter`; REQUIREMENTS SPELL-08/SPELL-09/SHOP-01 left to the orchestrator after verification.

## Self-Check: PASSED

- FOUND: lib/utils/filter_values.dart, lib/shared/components/items_filter.dart, test/utils/filter_values_test.dart, test/shared/components/items_filter_test.dart; MISSING as intended: lib/screens/mainScreen/tabs/shop/components/items_filter.dart
- FOUND commits: d751fca, b5415e4, e52a805, a0d0a35, 3bf05fe, cd553d7, 4e3f273

---
*Phase: 08-spells-section-journal-tab*
*Completed: 2026-10-27*
