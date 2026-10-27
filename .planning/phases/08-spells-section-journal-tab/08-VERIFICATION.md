---
phase: 08-spells-section-journal-tab
verified: 2026-10-27T00:00:00Z
status: passed
score: 5/5 success criteria and 12/12 requirement IDs verified (code, tests, device UAT 12/12)
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 4/4 success criteria in code, device E2E pending
  gaps_closed:
    - "Device E2E of SC1-SC4 (08-HUMAN-UAT.md, 12/12 pass)"
    - "Plan 08-12: spellStates in CharacterFragment, schema gate 34 OK"
  gaps_remaining: []
  regressions: []
gaps: []
---

# Phase 8: Spells Section (Journal Tab) - Verification Report

**Phase Goal:** The partial Spells section in the Journal tab is completed: users can view owned spells, tap to equip/disequip into backend-driven active slots, and see remaining usages and recovery per active spell, all with optimistic UI and rollback.
**Branch:** feat/08-spells-section-journal-tab @ 4f69586 (86 files changed vs 0bc37b8)
**Re-verification:** Yes, 2026-10-27 (see the section at the end); first pass was human_needed.
**Scope note:** by CONTEXT D-03 plan 08-12 (schema-gated close) runs only after the BE Phase 9.1 PR is merged on BE `develop`. Its must-haves are deferred, not gaps.

## Evidence gathered (run by the verifier)

| Check | Result |
|-------|--------|
| `flutter test` (full, foreground) | 2079 passed, 0 failed ("All tests passed!") |
| `flutter analyze` | 53 issues, 0 errors (baseline matched, none new) |
| `gsd-tools verify artifacts` on plans 01..11 | all_passed for every plan (01: 4/4, 02: 3/3, 03: 3/3, 04: 2/2, 05: 1/1, 06: 2/2, 07: 2/2, 08: 2/2, 09: 3/3, 10: 2/2, 11: 2/2) |
| `grep DateTime.now` in `lib/models/spell`, journal tab, `game_duration_format`, spell info files | none (time goes through `ServerClockService`) |
| `grep package:flutter/ lib/models` | none (models stay Flutter-free) |
| `usages` in `EquipSpellRequest` and the equip/unequip documents | not sent (D-06) |
| Trailers `Co-Authored-By` / `Generated with` in `git log 0bc37b8..HEAD` | 0 |
| `SpellRow` remnants in lib/test | none (removed, D-21) |
| Backend repo | not consulted: the contract check belongs to plan 08-12 |

## Success criteria (ROADMAP as amended)

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | List of owned spells with name, description, maxUsages, recoveryTime, energyDamage summary | VERIFIED (code and tests); device pending | `Spellbook.of` builds entries from `status.spells` in delivered order (D-15); `KnownSpellRow` + `spell_lines.dart` produce the compact line; tests in `known_spell_row_test`, `spell_lines_test`, `spellbook_test` |
| 2 | Tap assigns to a slot, tap on active slot disequips, optimistic with rollback | VERIFIED (code and tests); device pending | `SpellsCubit.toggle` computes the intent on the optimistic view, pending overlay keyed by spell id, tokens ignore stale responses, 15 s timeout, `_fail` drops the overlay and emits an outcome; `SpellsRepository` maps `OperationException` to `SpellEquipFailure` by `extensions.code` only; `SpellOutcomeListener` publishes the banner and calls `CharacterCubit.refreshCharacter()` for stale-view failures. State never built from `CommonResponse` (repository returns `void`) |
| 3 | Every known spell below max shows usages + live «prossimo tra X» from `status.spellStates[].recoveries` against server time; static «in recupero» without an instant; slot card shows usages only | VERIFIED in code and tests; live data pending 08-12 and device | `spellRecoveryStatusOf` pure function (`recoveries[0] - serverNow`, sealed statuses Full/Countdown/Arriving/Unknown), `SpellRecoveryCubit` ticker on `ServerClockService`, section owns it; `CharacterStatus.spellStates` optional (null today → `SpellRecoveryUnknown` fallback, by design D-03) |
| 4 | Slot availability follows `maxActiveSpells` from the subscription, no FE slot logic | VERIFIED (code and tests); device pending | `slotCount = max(0, maxActiveSpells)`, `List.generate(slotCount, slotAt)`, never indexes past actives (D-10); `maxActiveSpells == 0` → copy line, no slot row (D-11); no title or threshold logic present |

## Decisions honoured (08-CONTEXT)

D-01/D-02 (recovery never stops, contract read from `spellStates`): model and join in `Spellbook`, no FE recovery rule. D-03 (develop against the proposed contract, fragment untouched): `CharacterFragment` has no `spellStates`, parser optional. D-04 (server clock anchor, past instant → arriving, legacy empty → unknown): `SpellRecoveryStatus` variants. D-05/D-13 (countdown in the row, card keeps only the counter): `KnownSpellRow`, `usages_pencil_counter`. D-06/D-08 (tap toggles, no `usages` sent, light haptic): `toggleSpellWithFeedback`. D-07/D-11 (block on optimistic full count, no BE call, selectionClick, banners): `SpellToggleIntent.blocked*`, `spell_notice.dart`. D-09 (long-press sheet in the journal Stack with live toggle): `journal.dart` `_buildSpellSheet`, `SpellDetailsSheet`. D-10 (exact slot count, null spell skipped): `Spellbook`. D-12 (section hidden without spells and slots): `isVisible`, section returns `SizedBox.shrink`. D-14 (red bookmark, one shared widget, every copy replaced): `BookmarkRibbon`/`CardBookmark` used by `EquipmentItemCard`, `EquipmentInfoSheet`, `SpellCard`, `SpellInfoSheet`; no other copy in lib except the unrelated library page asset. D-16 (cubit provided by `AuthenticatedShell`, listener in `MainScreen`, ticker owned by the section): confirmed at `authenticated_shell.dart:196` and `main_screen.dart:103`. D-17 (classifier by code, silent refetch for ALREADY_ACTIVE/NOT_ACTIVE and after NOT_KNOWN/SLOTS_FULL/NOT_FOUND banners, UNAUTHENTICATED silent): `spell_equip_failure.dart`, `spell_outcome_listener.dart`. D-20 (TDD tests exist for classifier, cubit, countdown, join, section, sheet, long-press): see test list in the diff. D-21 (section extracted to `tabs/journal/sections/`, operations renamed `EquipSpell`/`UnequipSpell` including the schema_check registry keys, `SpellRow` removed): confirmed.

## Requirements traceability

| ID | Plans | Status | Evidence |
|----|-------|--------|----------|
| SPELL-01 | declared in plan frontmatters (5 plans) | SATISFIED in code; device pending | Criterion 1 |
| SPELL-02 | 6 plans | SATISFIED in code; device pending | Criterion 1 |
| SPELL-03 | 5 plans | SATISFIED in code; device pending | Criterion 2 |
| SPELL-04 | 6 plans | SATISFIED in code; device pending | Criterion 2 |
| SPELL-05 | 6 plans | SATISFIED in code against fixtures; live data pending 08-12 | Criterion 3 |
| SPELL-06 | 5 plans | SATISFIED in code; device pending | Criterion 2 |
| SPELL-07 | 4 plans | SATISFIED in code; device pending | Criterion 4 |

All seven IDs from the PLAN frontmatters exist in REQUIREMENTS.md (lines 119-128); no orphaned requirement. The checkboxes and the traceability row (`SPELL-01 through SPELL-07 | Phase 8 | Pending`) are intentionally still open: plan 08-12 ticks them after the device UAT. Expected, not a gap.

## Deferred to 08-12 (gated by the BE 9.1 PR)

Not failures; plan 08-12 has not run by design (CONTEXT D-03).

| # | Must-have of 08-12 | State today |
|---|--------------------|-------------|
| 1 | BE gate: `spellStates` present in `origin/develop:src/schema.gql` as first step | Not run |
| 2 | `CharacterFragment` selects `spellStates { usages recoveries spell { id } }`; all 34 documents validate with `tool/schema_check` against BE `origin/develop` | Fragment has no `spellStates`; `CharacterStatus.spellStates` is `null` in real payloads, fallback «in recupero» by design |
| 3 | Final gates (tests, analyze ≤ 53, format-clean, no trailer) | Already green on the current HEAD (above); to be re-run after the fragment change |
| 4 | Device E2E with the BE 9.1 UAT data (see human_verification) | Pending, human checkpoint |
| 5 | SPELL-01..07 ticked, roadmap row closed, `08-HUMAN-UAT.md` and validation sign-off, handoff update | Pending (checkboxes unticked as expected) |

## Anti-patterns

No blocker found. No `DateTime.now` in the time-sensitive code, no `package:flutter` in models, no state built from the mutation response, no `usages` sent. The `spellStates == null` fallback is a documented design (D-03/D-04), not a stub: it is replaced as soon as the fragment selects the field.

## Human verification required

See the `human_verification` frontmatter (8 items): live countdown, never-stopping recovery, optimistic equip/unequip, rollback, full/zero slots, slot unlock, long-press sheet, tab/clock change. All need the real backend and a device and belong to the 08-12 checkpoint.

## Gaps Summary

No gaps in plans 08-01..08-11. The remaining work is the schema-gated plan 08-12 and the device UAT, both waiting for the BE Phase 9.1 PR.

## Re-verification 2026-10-27

**Status: passed. Score 5/5 success criteria, 12/12 requirement IDs.** The eight `human_verification` items of the first report are closed by `08-HUMAN-UAT.md` (12/12 pass, Samsung SM-S938B, BE `develop` 10e5f43 with 9.1). Plans 08-13 and 08-14 (extension, success criterion 5) verified on the code, not on the summaries.

### Evidence run by the verifier

| Check | Result |
|-------|--------|
| `flutter test` (full, foreground) | 2134 passed, 0 failed ("All tests passed!"), baseline matched |
| `flutter analyze` | 53 issues, 0 errors (baseline, none new) |
| `dart format` | not run (rule) |
| `spellStates {` in `lib/graphql/fragments/character_fragment.dart`; `CharacterStatus.spellStates` parser | present (`character_status.dart:24,42,67`) |
| `ItemsFilter` single copy | `lib/shared/components/items_filter.dart`; no import of the old shop path remains in lib/test |

### Success criteria 1-4 (device-proven)

| # | Verdict | Device UAT rows | Code |
|---|---------|-----------------|------|
| 1 | VERIFIED | Step 1 pass | `Spellbook.of`, `KnownSpellRow`, `spell_lines.dart` |
| 2 | VERIFIED | Steps 3, 4, 5, 8, 9, 12B pass (optimistic toggle, full slots, rollback by tunnel removal, race branch A, timeout banner on the Map) | `SpellsCubit`, `SpellsRepository`, `SpellOutcomeListener` |
| 3 | VERIFIED | Steps 2, 3, 11 pass (countdown, use credited by the BE sweep +28 s, recovery while unequipped, server-time not device clock) | `spellRecoveryStatusOf`, `SpellRecoveryCubit`; fragment now selects `spellStates` |
| 4 | VERIFIED | Steps 1, 6, 7, 12A pass (slot count follows `maxActiveSpells`, zero slots, no spells, live unlock) | `Spellbook` slot generation, no title logic |

Step 10 (long-press sheet) pass covers D-09. UAT adaptations (single character in two roles, tunnel removal instead of airplane mode, live DB seeds) do not change what a step proves.

### Success criterion 5 (extension, code and tests)

VERIFIED. The known-spell list and the Journal «Oggetti» section filter by use type / effect type with the shop's icon chips limited to present types; the shop follows the same rule; the spell line reads «Attacco: Fuoco 12» and loot rows «Cura: 12».

**08-13 must_haves**

| Truth | Evidence |
|-------|----------|
| Chips «Tutti» + present use types in enum order between slot row and known rows | `spellbook_content.dart:43,62-68,75-78` (`presentFilterValues(UseType.values, …)`); test `spellbook_content_test` «shows one chip per present use type, in enum order» |
| Selected type hides other rows, slot row untouched | `spellbook_content.dart:57-83` (`SpellSlotRow` outside `_entriesOf`); tests «a selected type hides the other rows, never the slots», `spells_section_test` «a chip filters the known rows, «Tutti» restores them» |
| Null `useType` only under «Tutti», no empty chip | `filter_values.dart:7-10` (`whereType<T>`); tests «known spells without use type: no chips», «keeps the enum order and drops duplicates and nulls» |
| Vanished selection falls back to «Tutti» | `spellbook_content.dart:44` + `spells_section.dart:98-111` (`_dropVanishedUseTypeFilter`); tests «a type not present falls back to «Tutti»», `spells_section_test` «a vanished type drops the selection for good», `filter_values_test` «a vanished selection falls back to «Tutti»» |
| Line «Attacco: Fuoco 12», «Attacco: Fuoco» power 0/null, «Danno: Fuoco 12» when null; sheet keeps «Uso: Attacco» | `spell_lines.dart` `spellDamageLabel` (prefix `useType?.label ?? 'Danno'`); `spell_info.dart:52` passes `useType`; tests `spell_lines_test.dart:26-53,73-74,116-154`, `spell_info_test.dart:63-64` |
| Shop chips only present `EquipType`/`EffectType`, fallback to «Tutti» | `shop_modal.dart:61-70,103-108,146-151` (`presentEquipTypes`/`presentEffectTypes`/`retainedFilterSelection`); helpers tested in `filter_values_test.dart:91,104` |
| Local view state only | `_useTypeFilter` in `_SpellsSectionState` (`spells_section.dart:79`), shop `setState` fields; no cubit/repository/network |

**08-14 must_haves**

| Truth | Evidence |
|-------|----------|
| `EffectType` labels (Nessun effetto, Cura, Sazietà, Danno, Esplorazione) | `effect_type.dart:4-10`; test «effects have an Italian label» |
| Loot rows «Cura: 12», power null/0 → «Cura», null effect → no line, equipment none | `item_lines.dart` `itemEffectLabel`; `item_row.dart:35-36` (loot only); tests `item_lines_test.dart:19-50`, `item_row_test.dart:56,70,76,83` |
| «Oggetti» chips present effects, filter, «Tutti» restores, null effect only under «Tutti» | `journal.dart:226-245` (`ItemsFilter<EffectType>`, `shownItems`); tests `journal_items_test.dart:129,142` |
| Vanished effect falls back to «Tutti» | `journal.dart:231` (`retainedFilterSelection`); test `journal_items_test.dart:156` |
| No owned items with effect → no chip row; other sections unchanged | `journal.dart:238` (`if (effectTypes.isNotEmpty)`); test `journal_items_test.dart:175` |

### Requirements traceability (SPELL-01..09, ITEM-01, ITEM-02, SHOP-01)

| ID | Verdict | Evidence |
|----|---------|----------|
| SPELL-01 | SATISFIED | `Spellbook.of`; UAT step 1; `spellbook_test` |
| SPELL-02 | SATISFIED | `spell_lines.dart`, `KnownSpellRow`; UAT step 1; `spell_lines_test` |
| SPELL-03 | SATISFIED | `SpellsCubit.toggle`; UAT steps 4, 5; cubit tests |
| SPELL-04 | SATISFIED | tap on slot card / active row; UAT steps 4, 10 |
| SPELL-05 | SATISFIED | `spellRecoveryStatusOf`, `SpellRecoveryCubit`, `spellStates` fragment; UAT steps 2, 3, 11 |
| SPELL-06 | SATISFIED | pending overlay + rollback; UAT steps 8, 9, 12B |
| SPELL-07 | SATISFIED | `maxActiveSpells` slot count; UAT steps 1, 6, 12A |
| SPELL-08 | SATISFIED in code and tests (no device row) | `spellbook_content.dart:43-83`, `spells_section.dart:79-111`; `spellbook_content_test.dart:269-329`, `spells_section_test.dart:433,456` |
| SPELL-09 | SATISFIED in code and tests (no device row) | `spell_lines.dart` `spellDamageLabel`, `spell_info.dart:52`; `spell_lines_test.dart:116-154`, `spell_info_test.dart:63-64` |
| ITEM-01 | SATISFIED in code and tests | `effect_type.dart`, `item_lines.dart`, `item_row.dart:36`; `item_lines_test`, `item_row_test` |
| ITEM-02 | SATISFIED in code and tests | `journal.dart:226-245`; `journal_items_test.dart:129-175` |
| SHOP-01 | SATISFIED in code, helper-level tests only | `shop_modal.dart:61-70,103,146`; `filter_values_test.dart:91,104` |

### Notes (no gap, informational)

- `REQUIREMENTS.md` still shows SPELL-08, SPELL-09, ITEM-01, ITEM-02, SHOP-01 unticked and `Pending` in the traceability table (lines 131-138, 234-235), while the roadmap plans 08-13/08-14 are ticked. Housekeeping for the orchestrator at phase close, not a code gap.
- No widget test covers `ShopModal` itself (SHOP-01 wiring is verified by reading `shop_modal.dart:61-151` and by the unit tests of the shared helpers). Warning, non-blocking.
- The extension (SC5, SPELL-08/09, ITEM-01/02, SHOP-01) has no device UAT row; the visual result of the chips and the new lines is provisional per D-19. Not blocking: the user asked for the extension after the device UAT and success criterion 5 is observable in code and widget tests.
- No gaps, no anti-pattern blockers in the files touched by 08-13/08-14.

---

_Verified: 2026-10-27 (re-verification)_
_Verifier: Claude (gsd-verifier)_
