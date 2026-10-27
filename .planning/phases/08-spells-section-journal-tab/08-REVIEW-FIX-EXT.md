---
phase: 08-spells-section-journal-tab
fixed: 2026-10-27T16:00:00Z
source: 08-REVIEW-EXT.md
review_path: .planning/phases/08-spells-section-journal-tab/08-REVIEW-EXT.md
iteration: 1
fix_scope: all
findings_total: 5
findings_in_scope: 5
fixed_count: 3
skipped_count: 0
not_needed_count: 2
status: all_fixed
---

# Phase 8 (extension 08-13 / 08-14): Code Review Fix Report

**Fixed at:** 2026-10-27T16:00:00Z
**Source review:** `.planning/phases/08-spells-section-journal-tab/08-REVIEW-EXT.md`
**Iteration:** 1
**Branch:** `feat/08-spells-section-journal-tab` (no push)

**Summary:**
- Findings in the review: 5 (0 critical, 2 warnings, 3 info)
- Findings in scope: 5 (the orchestrator ruled on every Info item)
- Fixed: 3 (WR-01, WR-02, IN-01)
- Not needed: 2 (IN-02 and IN-03, both settled by user decisions D-25 and D-26)
- Skipped: 0

Both behaviour fixes went Red → Green: a failing-test commit, then the fix commit. IN-01 is a layout-only wrap with no behaviour change, so it has no Red commit (testing.md exception). Commits use Conventional Commits and plain `git`, with explicit paths, no trailers and no history rewriting. CONTEXT D-22..D-28 still hold: the selection is local view state, chips list only the present types, and a vanished type falls back to «Tutti» for good.

## Gate after the fixes

| Check | Result |
|-------|--------|
| Full `flutter test` (foreground) | **2137 passed, 0 failed** (2134 before, +3 new tests) |
| `flutter analyze` | **53 issues, 0 errors**: unchanged baseline, none in a touched file |
| `dart format` | `shop_modal.dart` was formatter-clean before the edit and was formatted by path after it. `journal.dart` is not formatter-clean, so it was edited by hand only. The two test files are clean. No directory format |
| `tool/schema_check` | not run: no GraphQL document touched |

## Per-finding table

| ID | Outcome | Commits (test → fix) | Note |
|----|---------|----------------------|------|
| WR-01 | fixed | `7e34e8a` → `c34ca9f` | The Journal resets `_selectedEffect` in the `BlocConsumer` listener with `setState`. The build path reads locals only |
| WR-02 | fixed | `bfc3b8c` → `5fddf67` | `ShopModal.didUpdateWidget` drops a vanished type for good. The render-time guard stays. New `shop_modal_test.dart` |
| IN-01 | fixed | — → `797a80c` | The 84-column `where` line is wrapped by hand |
| IN-02 | not_needed | — | `none` → «Nessun effetto» line and chip is the user's decision D-25 |
| IN-03 | not_needed | — | D-26 builds the line like the spell line, and `KnownSpellRow` uses `bodyMedium` for both texts |

## Fixed Issues

### WR-01: `_selectedEffect` written inside the build path

**Files modified:** `lib/screens/mainScreen/tabs/journal/journal.dart`

**Test:** `journal_items_test.dart`: "an effect gone between two frames still falls back (WR-01)". It selects «Sazietà», then emits two characters back to back before a frame: one without the bread and one with it again. It expects «Tutti» selected (`current == null`), every row shown, and no exception (no "setState() called during build").

The existing "a vanished effect falls back to «Tutti» for good" test already passed with the old code, because the render-time write is correct whenever every state gets rendered. The new test makes the reviewer's fragility point 2 observable. `BlocBuilder` renders only the last of the two states, so the old build-time reset never saw the vanish, and «Sazietà» survived. A listener sees every state. Red output: `Expected: null, Actual: EffectType:<EffectType.hunger>`.

**Commits:** `7e34e8a` (test), `c34ca9f` (fix)

**Applied fix:**
- The Journal's existing `BlocBuilder<CharacterCubit, CharacterState>` is now a `BlocConsumer` with one added `listener:` line. This was the least invasive hook: no re-indentation, same builder. The listener calls `_dropVanishedEffectFilter(state)`. On a `CharacterLoaded` state, it computes `retainedFilterSelection(_selectedEffect, presentEffectTypes(...))` and calls `setState` only when the value changes. This is the same shape as `SpellsSection._dropVanishedUseTypeFilter`.
- `_buildOwnedItemsSection` no longer assigns the field. It reads a local, `final selectedEffect = retainedFilterSelection(_selectedEffect, effectTypes)`, and uses it for `ItemsFilter.current` and for the `where` closure. So the lazy `Iterable` no longer closes over the mutable field. The local still guards the frame between a character change and the listener's `setState`, the same as `SpellbookContent`.
- Boy Scout, in scope: a private `_ownedItemsOf(character)` holds the `?? const <AssetQuantity>[]` fallback, which the listener and the section both use.
- The stale comment that pointed to the `_filteredItems` re-sync is gone. The new doc comment on the method is under 80 columns.

### WR-02: Shop keeps a stale filter selection that resurfaces

**Files modified:** `lib/screens/mainScreen/tabs/shop/components/shop_modal.dart`
**File created:** `test/screens/mainScreen/tabs/shop/components/shop_modal_test.dart` (asked for by the review and the ruling)

**Tests:** `shop_modal_test.dart` pumps `ShopModal` with only `buildTestApp` (a `MaterialApp` with the real theme), a `Scaffold` and `useLandscapePhone`. It needs no providers. The test seeds the SVGs with `seedSvgCache`: arrow, card sheet, coins (the shop rows show prices), heal/hunger effects and helm/boots types. There are two cases:
- "a vanished effect falls back to «Tutti» for good (WR-02)": open «Oggetti», tap «Sazietà», rebuild the widget without the bread. «Tutti» is selected. Rebuild with the bread again. «Tutti» is still selected and both rows are shown.
- "a vanished equip type falls back to «Tutti» for good (WR-02)": the same steps on «Armatura» with helm/boots.

Red output: the return step fails with `Expected: null, Actual: EffectType:<EffectType.hunger>` and `Actual: EquipType:<EquipType.boots>`. The vanish step already passed thanks to the render-time guard.

**Commits:** `bfc3b8c` (test), `5fddf67` (fix)

**Applied fix:** `didUpdateWidget(ShopModal oldWidget)` resets `selectedEquipFilter` with `presentEquipTypes(widget.equipments)` and `selectedEffectFilter` with `presentEffectTypes(widget.items)`, both through `retainedFilterSelection`. Assigning in `didUpdateWidget` is allowed with no `setState`, because a build always follows. The render-time `retainedFilterSelection` guard in `build` is unchanged. The file was formatter-clean before the edit (`--set-exit-if-changed` returned 0), and it was formatted by path after it (0 changed).

### IN-01: Line over 80 columns

**Files modified:** `lib/screens/mainScreen/tabs/journal/journal.dart`
**Commit:** `797a80c` (refactor)
**Applied fix:** after WR-01, the line `: ownedItems.where((owned) => owned.item?.asLoot?.effect == selectedEffect);` (84+ columns) is wrapped by hand into a `where(` call with the closure on its own line. Every line that the extension added to `journal.dart` is now 80 columns or fewer. The lines still over 80 are pre-existing and untouched: two imports, the life-points URL and a `debugPrint`. The 87-column doc comment in `item_lines.dart` that the review mentions was out of scope for this ruling and was left alone.

## Not needed

### IN-02: `EffectType.none` produces a visible «Nessun effetto» line and a chip

**File:** `lib/utils/item_lines.dart:9-12`, `lib/models/enums/effect_type.dart`
**Reason:** this is the user's decision D-25: `none` → «Nessun effetto», verbatim set chosen on 2026-10-27. D-26 drops the line only for a null effect, so a `none` effect renders its line and is a valid chip under D-23. No code change.

### IN-03: Effect line uses the same style as the description

**File:** `lib/shared/components/item_row.dart:84-91`
**Reason:** D-26 says the line is "built like the spell line", and `KnownSpellRow` uses `bodyMedium` for both its description and its compact line. The item row matches that, so it already follows the reference. No code change.

---

_Fixed: 2026-10-27T16:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
