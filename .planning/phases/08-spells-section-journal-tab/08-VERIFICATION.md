---
phase: 08-spells-section-journal-tab
verified: 2026-10-27T00:00:00Z
status: human_needed
score: 4/4 success criteria verified in code and tests (plans 08-01..08-11); 7/7 requirement IDs accounted for; device E2E and plan 08-12 pending
overrides_applied: 0
re_verification: null
gaps: []
human_verification:
  - test: "SC3 / SPELL-05 live countdown. With BE 9.1 merged and the fragment selecting spellStates, use a spell so usages < max. Open Journal > Magie imparate."
    expected: "The row shows «Usi: n/max · prossimo tra X min», X counts down on its own against server time; at the recovery instant the label goes to the «in arrivo» wording until characterUpdated restores the use; at max usages no recovery text is shown; the slot card shows only the usages counter."
    why_human: "Needs the real BE 9.1 payload, real Bull recovery jobs and wall-clock time; the code is tested only against fixtures and a fixed server clock."
  - test: "D-01 recovery never stops. Unequip a spell that has a pending recovery, wait for its instant, then re-equip."
    expected: "The use is recovered at the original instant regardless of the equip state; equipping does not reset usages."
    why_human: "Backend behaviour (BE 9.1) observable only end to end on device."
  - test: "SC2 / SPELL-03, SPELL-04, SPELL-06 optimistic equip/unequip with the real backend. Tap an inactive spell with a free slot; tap an active row; tap a card in a slot."
    expected: "The card enters or leaves the slot at once with the attenuated «ink still wet» look, becomes full when characterUpdated arrives; the red bookmark appears on the row and the row keeps its place; light haptic at the tap. No UI chrome, no blocking loader."
    why_human: "Visual feel, haptics and subscription timing on a physical device."
  - test: "SC2 rollback. Provoke a rejection (e.g. equip from a second client to create a race, or MAX_ACTIVE_SPELLS_REACHED / SPELL_ALREADY_ACTIVE)."
    expected: "The card springs back; banner «Magia non equipaggiata» / «Magia non tolta» with domain copy for real errors; ALREADY_ACTIVE and NOT_ACTIVE give no banner and a silent refetch that realigns the view; UNAUTHENTICATED silent."
    why_human: "Needs a real rejection from the backend and visual check of the spring-back and banner."
  - test: "D-07 / D-11 full and zero slots. Fill every slot and tap another inactive spell; then (title below mage) maxActiveSpells == 0."
    expected: "No BE call, the card resists, selectionClick haptic, banner «Slot pieni: disequipaggia una magia»; with zero slots the slot row is replaced by «Nessuno slot per le magie: cresci di rango» and a tap gives «Nessuno slot disponibile»; the list stays visible."
    why_human: "Haptic and animation feel, and real maxActiveSpells values."
  - test: "SC4 / SPELL-07 slot unlock. While the Journal is open, change the character's title (or maxActiveSpells) from the admin side."
    expected: "The slot row re-renders to exactly the new maxActiveSpells boxes via characterUpdated, no frontend threshold or title logic."
    why_human: "Needs a live subscription event from the real backend."
  - test: "D-09 long-press sheet. Long-press a row and a slot card."
    expected: "The detail sheet rises on the right side of the journal page with name, description, element and power, use type, max usages, recovery time, learn requirements, current usages and next recovery, plus the equip/disequip toggle; a tap outside dismisses it."
    why_human: "Layout and gesture feel; every visual is provisional."
  - test: "Tab change and clock change. Switch tab while an equip is pending; change the device clock."
    expected: "Pending state and banner survive the tab switch (SpellsCubit provided by the shell); the countdown follows server time, not the device clock."
    why_human: "Depends on the PageView lifecycle and device settings on a real device."
---

# Phase 8: Spells Section (Journal Tab) - Verification Report

**Phase Goal:** The partial Spells section in the Journal tab is completed: users can view owned spells, tap to equip/disequip into backend-driven active slots, and see remaining usages and recovery per active spell, all with optimistic UI and rollback.
**Branch:** feat/08-spells-section-journal-tab @ 4f69586 (86 files changed vs 0bc37b8)
**Re-verification:** No, initial verification.
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

---

_Verified: 2026-10-27_
_Verifier: Claude (gsd-verifier)_
