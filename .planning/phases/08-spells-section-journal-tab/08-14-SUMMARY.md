---
phase: 08-spells-section-journal-tab
plan: 14
subsystem: ui
tags: [flutter, dart, items, journal, filter, tdd]

# Dependency graph
requires:
  - phase: 08-13
    provides: "`filter_values.dart` (`presentEffectTypes`, `retainedFilterSelection`) and the shared `ItemsFilter<T>`"
provides:
  - "`EffectType.label`: «Nessun effetto», «Cura», «Sazietà», «Danno», «Esplorazione»"
  - "`lib/utils/item_lines.dart`: `itemEffectLabel(LootItem)` → «Cura: 12» / «Cura» (power null or 0) / null (no effect)"
  - "Effect line under the description of every loot row in the shared `ItemRow` (Journal and shop), keyed `item-effect-<id>`"
  - "`ItemsFilter<EffectType>` on the Journal «Oggetti» section (local `setState` selection, vanished effect → «Tutti»)"
  - "`test/helpers/journal_harness.dart`: `journalCharacter`, `seedJournalSvgs`, `pumpJournalPage` shared by the Journal page tests"
affects: [phase-8-verification]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Present-values filter reused for the owned items: chips from `presentEffectTypes(ownedItems)`, selection re-validated at every build with `retainedFilterSelection`"
    - "Item copy in `lib/utils/item_lines.dart`, beside `spell_lines.dart` (D-28)"

key-files:
  created:
    - lib/utils/item_lines.dart
    - test/models/enums/effect_type_test.dart
    - test/utils/item_lines_test.dart
    - test/shared/components/item_row_test.dart
    - test/helpers/journal_harness.dart
    - test/screens/mainScreen/tabs/journal/journal_items_test.dart
    - .planning/phases/08-spells-section-journal-tab/08-14-SUMMARY.md
  modified:
    - lib/models/enums/effect_type.dart
    - lib/shared/components/item_row.dart
    - lib/screens/mainScreen/tabs/journal/journal.dart
    - test/screens/mainScreen/tabs/journal/journal_spells_test.dart
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "The text column of `ItemRow` was extracted into `_buildTexts(String? effectLine)` (the plan's Clean Code option): `build` was already ~40 lines before the change"
  - "The vanished-effect fallback is normalized inside `_buildOwnedItemsSection` without `setState`, mirroring how `_filteredItems`/`_selectedSlot` are realigned in `build`; the dropped selection is not resurrected when the effect comes back (tested)"
  - "The harness keeps the private `_spellJson` and the A/B spell data in `journal_spells_test.dart`; only the Journal-wide fixtures moved"

patterns-established:
  - "Journal page tests pump through `pumpJournalPage(tester, characterCubit:, spellsCubit:)` with a `journalCharacter(spellbook:, ownedItems:)` fixture"

requirements-completed: [ITEM-01, ITEM-02]

# Metrics
duration: ~25 min
completed: 2026-10-27
---

# Phase 8 Plan 14: Effect Labels, Item Effect Line and Journal Effect Chips Summary

**`EffectType` carries Italian labels, every loot row of the shared `ItemRow` shows «Cura: 12» under its description (Journal and shop alike), and the Journal «Oggetti» section gets `EffectType` chips limited to the effects owned, falling back to «Tutti» when the selected effect disappears.**

## Performance

- **Completed:** 2026-10-27
- **Tasks:** 3 (all auto, TDD)
- **Files modified:** 4 lib (1 created) + 6 test (5 created) + 3 planning documents

## Accomplishments

- **Labels (ITEM-01, D-25):** `EffectType(label:, imageId:)` with `final String label;` — none «Nessun effetto», heal «Cura», hunger «Sazietà», munition «Danno», exploration «Esplorazione»; order and `byName` unchanged.
- **Effect line (ITEM-01, D-26, D-28):** `itemEffectLabel(LootItem)` in the pure util `item_lines.dart` (no Flutter import); `ItemRow` computes it from `assetItem.asLoot` and renders it under the description in a `Column`; equipment rows and effect-less loot render no line (T-8-47).
- **Journal chips (ITEM-02, D-27, D-23, D-28):** `_JournalState._selectedEffect` (`setState` only, never persisted or sent — T-8-48); `ItemsFilter<EffectType>` shown above the rows only when an effect is present; items with a null effect listed only under «Tutti»; the old `!` reads on `ownedItems`/`item`/`quantity` replaced with null-safe reads (T-8-46).
- **Harness:** the Journal-wide fixtures of `journal_spells_test.dart` moved to `test/helpers/journal_harness.dart` (also seeding the five effect SVGs), the spells test unchanged in behavior (5/5).

## Task Commits

1. **Task 1 RED** — `15a6fc6` `test(items): add failing tests for effect labels and lines`
2. **Task 1 GREEN** — `e6cfbb1` `feat(items): label the effect types and build the effect line`
3. **Task 2 RED** — `6067004` `test(items): add failing tests for the item row effect line`
4. **Task 2 GREEN** — `c822449` `feat(items): show the effect line under loot descriptions`
5. **Task 3 REFACTOR** — `a833a79` `refactor(journal): share the journal test harness`
6. **Task 3 RED** — `570b11c` `test(journal): add failing tests for the items effect filter`
7. **Task 3 GREEN** — `ca1079c` `feat(journal): filter the owned items by effect`
8. **Docs** — `docs(phase-8): complete the 08-14 effect labels and filter plan` (this commit)

## RED evidence

- **Task 1:** `effect_type_test.dart:6:28: Error: The getter 'label' isn't defined for the type 'EffectType'.` (5 sites); `item_lines_test.dart:4:8: Error: Error when reading 'lib/utils/item_lines.dart': No such file or directory` / `Method not found: 'itemEffectLabel'.` — run `+0 -2: Some tests failed.`
- **Task 2:** `Expected: exactly one matching candidate / Actual: _TextWidgetFinder:<Found 0 widgets with text "Cura: 12": []>` (and `"Cura"`) — run `+2 -2: Some tests failed.` (the two "no line" tests already passed, as expected for absence checks).
- **Task 3:** `Actual: _TypeWidgetFinder:<Found 0 widgets with type "ItemsFilter<EffectType>": []>` on the three chip tests — run `+1 -3: Some tests failed.` (the empty-list test passes by absence).

## Verification

- Task 1 verify: `flutter test test/models/enums/effect_type_test.dart test/utils/item_lines_test.dart test/models` → `+353: All tests passed!`; scoped analyze `No issues found!`.
- Task 2 verify: `flutter test test/shared` → `+142: All tests passed!`; scoped analyze `No issues found!`.
- Task 3: `journal_spells_test.dart` after the harness extraction `+5: All tests passed!`; verify `flutter test test/screens/mainScreen/tabs/journal test/shared test/utils test/models` → `+692: All tests passed!`; scoped analyze 2 pre-existing infos (`avoid_print` in `journal_cubit.dart`).
- Full suite: `flutter test` → `00:53 +2134: All tests passed!` (2119 + 15 new).
- `flutter analyze`: 53 issues (all info), 0 errors.
- `dart format --output=none --set-exit-if-changed` on the 9 formatter-clean code/test files of the plan → exit 0 (0 changed); `journal.dart` never formatted.
- Acceptance greps: `final String label;` = 1, five labels = 5, `String? itemEffectLabel(LootItem item)` = 1, no Flutter import in `item_lines.dart`; `itemEffectLabel(` in `item_row.dart` = 1, `assetItem.asLoot` = 2; `ItemsFilter<EffectType>(` = 1, `EffectType? _selectedEffect;` = 1, `presentEffectTypes(ownedItems)` = 1, `retainedFilterSelection(_selectedEffect, effectTypes)` = 1, `ownedItems!` = 0, chrome/loader/`SharedPreferences` = 0; `_journalCharacter|_seedJournalSvgs` in the spells test = 0, `Character journalCharacter(` = 1.
- Commit messages: no trailer of any kind (`git log 315ae8f..HEAD --format=%B | grep -ci "co-authored\|generated"` = 0); subjects 47–61 characters.

### `journal.dart` diff (`git diff --stat HEAD~1` after `ca1079c`: 27 insertions, 8 deletions)

Only three hunks: the four `package:` imports (`asset_quantity`, `enums/effect_type`, `shared/components/items_filter`, `utils/filter_values`), the `EffectType? _selectedEffect;` field after `_selectedSlot`, and the body of `_buildOwnedItemsSection` (present effects, retained selection, `ItemsFilter<EffectType>` when effects exist, `for … if (owned.item case final item?) ItemRow(...)` with `quantity: owned.quantity`). No other line of the file changed.

## Decisions Made

See frontmatter `key-decisions`.

## Deviations from Plan

### Notes against the acceptance criteria

**1. `ValueKey('item-effect-${assetItem.id}')` grep** — with the plan's `grep -c` (basic regex) the `${` sequence does not match literally and the count is 0; `grep -cF` gives 1. The key is present as prescribed.

**2. Formatter on `effect_type.dart`** — `dart format` wrapped the `exploration(...)` constant (over 80 columns) onto three lines; content identical to the plan's code.

**3. Equipment fixture in `item_row_test.dart`** — the equipment item is built with `AssetItem.fromJson` plus `'rarity': 'common'`, because `EquipmentItemCard` reads `rarity!`; the seeded SVGs are `emptyCardSheet`, `healEffect`, `munitionEffect`, `helmetType`.

**4. Extra assertions** — the Journal tests also assert `current` after each tap and after the vanished-effect emission, and that the dropped selection stays `null` when Pane comes back.

---

**Total deviations:** 0 auto-fixes; 4 notes (1 acceptance-grep wording, 1 formatter wrap, 2 test details).

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None — no network, GraphQL, repository, cubit or BE change; the filter is `setState` view state. T-8-46 (null-safe reads, empty-list test), T-8-47 (no «null» line), T-8-49 (shared chip widget, existing SVGs and theme tokens; chrome/loader grep = 0) mitigated; T-8-48/T-8-50 accepted as planned.

## Next

Phase 8 has all 14 plans executed: review → verify → fix → security → device check on `feat/08-spells-section-journal-tab`, then the FE PR `feat/08-spells-section-journal-tab` → `develop`. REQUIREMENTS ITEM-01/ITEM-02 left to the orchestrator after verification.

## Self-Check: PASSED

- FOUND: lib/utils/item_lines.dart, test/models/enums/effect_type_test.dart, test/utils/item_lines_test.dart, test/shared/components/item_row_test.dart, test/helpers/journal_harness.dart, test/screens/mainScreen/tabs/journal/journal_items_test.dart
- FOUND commits: 15a6fc6, e6cfbb1, 6067004, c822449, a833a79, 570b11c, ca1079c

---
*Phase: 08-spells-section-journal-tab*
*Completed: 2026-10-27*
