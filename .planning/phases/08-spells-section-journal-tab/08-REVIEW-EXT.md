---
phase: 08-spells-section-journal-tab
reviewed: 2026-10-27T15:00:00Z
depth: standard
scope: extension plans 08-13 and 08-14 (commits 36fd7c8..HEAD)
files_reviewed: 25
files_reviewed_list:
  - lib/models/enums/effect_type.dart
  - lib/screens/mainScreen/tabs/journal/components/spellbook_content.dart
  - lib/screens/mainScreen/tabs/journal/journal.dart
  - lib/screens/mainScreen/tabs/journal/sections/spells_section.dart
  - lib/screens/mainScreen/tabs/shop/components/shop_modal.dart
  - lib/shared/components/item_row.dart
  - lib/shared/components/items_filter.dart
  - lib/shared/components/spell_info.dart
  - lib/utils/filter_values.dart
  - lib/utils/item_lines.dart
  - lib/utils/spell_lines.dart
  - test/helpers/journal_harness.dart
  - test/helpers/spells_harness.dart
  - test/models/enums/effect_type_test.dart
  - test/screens/mainScreen/tabs/journal/components/known_spell_row_test.dart
  - test/screens/mainScreen/tabs/journal/components/spellbook_content_test.dart
  - test/screens/mainScreen/tabs/journal/journal_items_test.dart
  - test/screens/mainScreen/tabs/journal/journal_spells_test.dart
  - test/screens/mainScreen/tabs/journal/sections/spells_section_test.dart
  - test/shared/components/item_row_test.dart
  - test/shared/components/items_filter_test.dart
  - test/shared/components/spell_info_test.dart
  - test/utils/filter_values_test.dart
  - test/utils/item_lines_test.dart
  - test/utils/spell_lines_test.dart
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 8 (extension 08-13 / 08-14): Code Review Report

**Depth:** standard. `flutter analyze` on the touched dirs: no new issues (only pre-existing infos). `flutter test test/utils test/shared test/models test/screens/mainScreen/tabs/journal`: 692 passed, 0 failed.

## Summary

The extension is clean and faithful to D-22..D-28. No critical issues. Verified OK:

- **Spells filter (D-22/D-23):** `SpellbookContent` filters only the entries list. `SpellSlotRow` is rendered before and independent of the filter. Chip taps go through `ItemsFilter` `GestureDetector`s, outside `KnownSpellRow`, so they never reach `onToggle` (asserted by `gestures.toggles, isEmpty` and `verifyNever(spellsCubit.toggle)`). Haptics (`toggleSpellWithFeedback`) are untouched. No chrome added.
- **Stale frame in spells:** between a character change and the `BlocListener` reset, `SpellbookContent` already applies `retainedFilterSelection`, so no frame renders a vanished filter. The listener then drops the field for good.
- **`spellDamageLabel` (D-24):** `Attacco: Fuoco 12`, power null or 0 gives `Attacco: Fuoco`, null `useType` gives `Danno: ...`. `spell_info.dart` still has the `Uso: Attacco` line (the line list keeps `spellUseTypeLabel`; only the damage call changed).
- **`filter_values.dart`:** generic, enum order kept, nulls dropped. `retainedFilterSelection` is null-safe (`present.contains(null)` is false).
- **`ItemRow`/`item_lines`/`EffectType`:** the line appears only for `asLoot != null` with a non-null effect, key `item-effect-<id>`, and equipment rows keep the same widgets (description now sits in a `Column(mainAxisSize.min)`, which is layout-neutral). Labels match D-25.
- **Shop:** casts replaced by `asEquipment`/`asLoot` (null-safe, a real improvement); chips limited to present types. Behaviour is otherwise unchanged.
- **Tests:** the red/green pairs are meaningful, not tautological. The vanish-and-return tests (spells section, Journal items) would fail if the reset were removed. The harness extraction keeps every `journal_spells_test` assertion; it only moves setup and seeds more SVGs (harmless).
- **Repo rules:** `git diff --stat` shows only the 25 scoped files plus `.planning/*`, so no `dart format` footprint. All 16 commit subjects are 72 characters or fewer. There are no trailers.

## Warnings

### WR-01: `_selectedEffect` written inside the build path (works, but fragile and inconsistent)

**File:** `lib/screens/mainScreen/tabs/journal/journal.dart:226-236`
**Issue:** `_buildOwnedItemsSection` runs inside `BlocBuilder.builder` and assigns `_selectedEffect = retainedFilterSelection(...)` without `setState`.

- Safe today. There is no `setState` during build and no stale frame, because the field is reassigned before the same build reads it. It mirrors the existing `_filteredItems` re-sync.
- Fragile in three ways:
  1. `shownItems` is a lazy `Iterable` whose `where` closure reads the field `_selectedEffect`, not a local. It is only correct because it is consumed in the same build.
  2. The reset is a side effect of rendering. If the section is ever skipped for a build (for example an early return when not loaded), the stale value survives until the next build, which is harder to reason about.
  3. It diverges from `SpellsSection`, which resets in a `BlocListener` and uses `setState` legitimately.

  The listener pattern is the better one to align to, but the cost here is moderate (see Fix).

**Fix:** use a local for rendering and keep the field as the only mutable state.
```dart
final effectFilter = retainedFilterSelection(_selectedEffect, effectTypes);
_selectedEffect = effectFilter; // or drop this and reset in a listener
final shownItems = effectFilter == null
    ? ownedItems
    : ownedItems.where((o) => o.item?.asLoot?.effect == effectFilter);
```
For strict alignment with `SpellsSection`, wrap in a `BlocListener<CharacterCubit,...>` in `_JournalState` that calls `setState` when the effect vanishes. At minimum, use the local in the closure and the `ItemsFilter.current`.

### WR-02: Shop keeps a stale filter selection that resurfaces (D-23 not applied "for good") and the shop has no tests

**File:** `lib/screens/mainScreen/tabs/shop/components/shop_modal.dart:61-70` (fields at 42-43)
**Issue:** `equipFilter`/`effectFilter` are computed per build with `retainedFilterSelection`, but `selectedEquipFilter`/`selectedEffectFilter` are never reset.

- If the selected type disappears from `widget.equipments`/`widget.items` (for example the sell list changes after a transaction), the UI falls back to «Tutti». If that type later reappears, the old selection silently returns. The Journal and Spells sections reset for good, so behaviour differs across the three uses of the same helper.
- `ShopModal` has no widget tests, so the new behaviour (chips limited to present types, filter by `asLoot`/`asEquipment`) is unverified.

**Fix:** assign the retained values back (as Journal does) or reset in `didUpdateWidget`:
```dart
@override
void didUpdateWidget(ShopModal old) {
  super.didUpdateWidget(old);
  selectedEquipFilter = retainedFilterSelection(
      selectedEquipFilter, presentEquipTypes(widget.equipments));
  selectedEffectFilter = retainedFilterSelection(
      selectedEffectFilter, presentEffectTypes(widget.items));
}
```
Add a small `ShopModal` widget test (chips limited to present types, filter applies, vanished type falls back).

## Info

### IN-01: Line over 80 columns, not formatter-clean

**File:** `lib/screens/mainScreen/tabs/journal/journal.dart:235`
**Issue:** `: ownedItems.where((owned) => owned.item?.asLoot?.effect == _selectedEffect);` is 84 columns, so `dart format` would reflow it. Also `lib/utils/item_lines.dart` has a doc comment line of 87 columns (harmless for the formatter). Per the baseline rule, run the formatter on the touched files only, never on a directory.
**Fix:** wrap manually, or fold into the local in WR-01.

### IN-02: `EffectType.none` produces a visible «Nessun effetto» line and a chip

**File:** `lib/utils/item_lines.dart:9-12`, `lib/models/enums/effect_type.dart`
**Issue:** D-26 says a null effect gives no line. An item with `effect == none` (and `power` set) renders `Nessun effetto: 3` (power null or 0 renders `Nessun effetto`), and `none` is a valid chip via `presentEffectTypes`. This matches the letter of D-25/D-26 but may be noisy.
**Fix:** decide whether `none` should be treated like null in `itemEffectLabel`, and add a test pinning the choice either way.

### IN-03: Effect line uses the same style as the description

**File:** `lib/shared/components/item_row.dart:84-91`
**Issue:** both texts use `bodyMedium`, so the effect line is visually indistinguishable from the description. Spell rows may use a distinct style for the summary line.
**Fix:** consider the style used by `KnownSpellRow` for its summary line, for consistency (cosmetic, not blocking).

---

| ID | Severity | File | Topic |
|----|----------|------|-------|
| WR-01 | Warning | journal.dart:226-236 | state written in build path, lazy closure over field |
| WR-02 | Warning | shop_modal.dart:61-70 | stale shop selection resurfaces, no shop tests |
| IN-01 | Info | journal.dart:235 | 84-column line |
| IN-02 | Info | item_lines.dart | `none` effect renders a line/chip |
| IN-03 | Info | item_row.dart:84 | effect line style |

Totals: critical 0, warning 2, info 3.

_Reviewed: 2026-10-27T15:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
