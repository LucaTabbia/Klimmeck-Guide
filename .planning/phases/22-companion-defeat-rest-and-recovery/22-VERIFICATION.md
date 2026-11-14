---
phase: 22-companion-defeat-rest-and-recovery
verified: 2026-11-14
status: passed_with_gaps
scope: pre-gate (plans 01-15)
score: 9/10 requirements verified pre-gate (PET-09 is the gated plans' own requirement, not yet executable); 4/5 roadmap success criteria met pre-gate (SC5 is gated)
head: fa8a698f
gaps:
  - id: V-01
    severity: low
    truth: "journal_companion_details_test pins the rename entry only with the switch on"
    reason: "In the test 'the details offer «Dai un nome» or «Cambia nome» only with the switch on' the second longPressWorg (after re-pumping with isCompanionNamingEnabled: true) misses its target (hit-test warning: Offset(395,522) outside the 780x360 surface). The assertion still holds because the Journal State keeps the sheet opened by the first half, so the test passes without the second gesture really happening."
    artifacts:
      - path: test/screens/mainScreen/tabs/journal/journal_companion_details_test.dart
        issue: "second longPressWorg at ~line 289 is a no-op; add tester.pageBack()/a fresh pump or pass warnIfMissed deliberately"
  - id: V-02
    severity: info
    truth: "REQUIREMENTS.md traceability"
    reason: "PET-01..PET-10 still read Pending and 22-16/22-17 are unchecked in ROADMAP: expected pre-gate, to be closed by the gated plans."
deferred_to_gate: [22-16, 22-17]
---

# Phase 22: Companion Defeat, Rest and Recovery — Verification Report (pre-gate)

**Phase goal:** companions can be defeated, rested and healed (potions), named; the BE is the source of truth, the app shows the state and drives the actions.
**Verified:** 2026-11-14 at HEAD `fa8a698f`, tree clean. Scope: plans 22-01..22-15 + code review fixes. Plans 22-16 (schema gate) and 22-17 (device E2E) wait for the BE Phase 23 merge.
**Status:** passed_with_gaps (one low test-hygiene gap, no functional gap).
**Re-verification:** No, initial.

Method: code read against the SUMMARYs' claims, greps of the readers of the switch and of the GraphQL documents, comparison with `origin/develop:src/schema.gql` of the BE, spot-reading of the fixer's retargeted tests, one targeted run (see Spot-checks). The full suite (5010 green) and analyzer (47 info / 0 warning / 0 error) were taken from the orchestrator's fixer and not rerun.

## Roadmap success criteria (pre-gate)

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Journal shows life rising live while resting; defeated companion faded with countdown, back by itself at full life | VERIFIED | `lib/models/companion/companion_vitality.dart:56-80` (Steady/Resting/Defeated from served dates; `now >= fullLifeAt` -> Steady at max, so the parchment re-enables itself); ticker `companionVitalityCubit/companion_vitality_cubit.dart`, provided by `CompanionVitalityScope` (`journal.dart:496`) and read by `companion_section.dart:62`, `items_section.dart:152`, `journal.dart:315`. Tests: `companion_vitality_test.dart` ("user's example reads 40 after 20 minutes", line ~59), `companion_vitality_cubit_test.dart:90,187,202,222`, `owned_companion_row_test.dart` (defeated not tappable, stale case). |
| 2 | Potion from the potion sheet to an eligible companion; refusals show the name | VERIFIED pre-gate, switch off | `potion_sheet.dart:179` (`PotionCubit.give`), eligibility `models/companion/companion_potion_target.dart`, targets cut by the switch `items_section.dart:186`; refusal mapping `repository/item_use_failure.dart:14-15`, `pet_defeated.dart:3`, notice in `potionCubit/potion_notice.dart`. Tests: `potion_sheet_test.dart`, `items_section_test.dart`, `potion_cubit_test.dart`, `item_use_failure_test.dart`, `potion_notice_test.dart`. Live only after 22-16 (UseItem target + switch). |
| 3 | Companions named at purchase, after a prize, from the details sheet; wordings use the name | VERIFIED pre-gate, switch off | Three entry points: `shop.dart:386-397` (after purchase, `_petsInFlight` captured at confirm), `quest_result_presenter.dart:243-252` (prize), `journal.dart:350-351` (details sheet, `_renameActionOf` null with switch off). Sheet `shared/components/popup/companion_name_sheet.dart`; rules `utils/name_rules.dart` shared with character creation; classifier `repository/pet_rename_failure.dart`; single name function `models/companion/companion_display_name.dart`; sell list names `CharacterAssets.chosenPetNames`. Tests: `companion_name_sheet_test.dart`, `companion_name_cubit_test.dart`, `pet_rename_failure_test.dart`, `shop_test.dart`, `quest_result_presenter_test.dart`, `companion_display_name_test.dart`. |
| 4 | Result sheet and ambush pages tell life, defeat, walk on foot; every ambush pushes; «in forze» pushes | VERIFIED pre-gate | `quest_result_sheet.dart:189-207` (life, defeat, xp lines; keys 52-61), `utils/quest_outcome_lines.dart:60,72-77` (defeat duration from `fullLifeAt - resolvedAt`, «Prosegui a piedi» from `AmbushReport.onFoot`, `ambush_report.dart:33`); categories `models/notification_category.dart:15-18` (`ambush` accepts `ambushDefeat`, storage key kept; `petRecovered`), settings labels «Imboscate» / «Compagno in forze» (`notification_preferences_section.dart:49,52`), banner suppression in `quest_result_presenter.dart`. Mid-travel opening is the existing mechanism, pinned by `quest_result_presenter_test.dart:594`. Tests: `quest_result_sheet_test.dart`, `ambush_report_carousel_test.dart`, `notification_category_test.dart`, `push_event_test.dart`, `data_message_handler_test.dart`. The BE sending the new push types is a gate matter. |
| 5 | Schema check green on merged BE Phase 23 SDL and device E2E | DEFERRED | Plans 22-16 / 22-17. |

## Requirements

| Req | Verdict | Delivered by (code) | Proved by (test) |
|-----|---------|---------------------|------------------|
| PET-01 lenient models, one display-name, vitality from served dates | SATISFIED | `owned_pet.dart:26-48` (tolerant parse, `effectiveMaxLifePoints`), `pet.dart:21-63` (`recoveryTime`, `maxLifePoints`, `imagePath`), `companion_display_name.dart`, `companion_vitality.dart` | `owned_pet_test.dart`, `pet_test.dart`, `companion_display_name_test.dart`, `companion_vitality_test.dart` |
| PET-02 Journal «Compagno» life/rest/defeat, slot life, name as title + species below | SATISFIED | `companion_content.dart`, `owned_companion_row.dart`, `companion_slot.dart`, `companion_section.dart:62` | `owned_companion_row_test.dart`, `companion_section_test.dart` (slot life ~line 520) |
| PET-03 cards with image, long press details sheet in Journal, shop list, basket, quest prize, innkeeper prize rows | SATISFIED | `companion_card.dart`, `companion_info_sheet.dart`, `companion_details_route.dart` (now on `Material`, A-01); long press: `companion_content.dart:56,85`, `shop_modal.dart:244`, `transaction_modal.dart:268` (basket and sell side, both given `shop.dart:228,297`), `quest_info_sheet.dart:478`, `prizes_step.dart:465`, `prize_catalogue_sheet.dart:113` | `companion_card_test.dart`, `companion_info_sheet_test.dart`, `companion_details_route_test.dart`, `journal_companion_details_test.dart`, `shop_modal_test.dart`, `transaction_modal_test.dart`, `quest_info_sheet_test.dart`, `prizes_step_test.dart`, `prize_catalogue_sheet_test.dart` |
| PET-04 potion targets, row tappable, `useItem` target, codes mapped, `equipPet` PET_DEFEATED | SATISFIED pre-gate (switch off); `useItem` target itself is a 22-16 item | `items_section.dart:176-230`, `potion_sheet.dart`, `potion_cubit.dart`, `item_use_failure.dart`, `pet_equip_failure.dart`, `pet_defeated.dart` | `items_section_test.dart`, `potion_sheet_test.dart`, `potion_cubit_test.dart`, `item_use_repository_test.dart`, `item_use_failure_test.dart`, `pet_equip_failure_test.dart`, `graphql_use_item_test.dart` |
| PET-05 name prompt x3, form rules, PET_NAME_INVALID, not locked by mission | SATISFIED pre-gate (switch off) | see SC3; `CompanionRepository.renamePet` (`companion_repository.dart:41`), `CompanionNameCubit` provided in `authenticated_shell.dart:279` | see SC3 + `companion_repository_test.dart`, `graphql_rename_pet_test.dart`, `rename_pet_document_test.dart`, `name_rules_test.dart` |
| PET-06 result sheet and ambush lines | SATISFIED | see SC4 | `quest_companion_outcome_test.dart`, `quest_outcome_lines_test.dart`, `quest_result_test.dart`, `quest_result_sheet_test.dart` |
| PET-07 ambush queue mid-travel, one «Imboscate» category, banner suppression, «Compagno in forze» | SATISFIED | see SC4 | `notification_category_test.dart`, `notification_preferences_store_test.dart`, `notification_intent_landing_test.dart`, `quest_result_presenter_test.dart` |
| PET-08 innkeeper companion slider, sent only with a companion | SATISFIED | `correction_section.dart:67,116` (LifeSlider, «Sconfitto» marker, «Vita prima dello scontro» label), `mission_draft_inputs.dart:115` (key only when set), `models/mission/mission_fight.dart` | `correction_section_test.dart`, `mission_draft_inputs_test.dart`, `mission_fight_test.dart` |
| PET-09 schema gate + device E2E | NOT YET EXECUTABLE (gated, not a gap) | plans 22-16 / 22-17; registry entry for `renamePet` already in `schema_check_documents.dart:85` | — |
| PET-10 levels from the wire, one max getter, «Livello N» | SATISFIED | `owned_pet.dart:50,79,118` (`level`, `ownMaxLifePoints`, `effectiveMaxLifePoints`), `companion_lines.dart:50-57`; getter used by vitality, potion targets, rows | `owned_pet_test.dart`, `companion_lines_test.dart`, `companion_vitality_test.dart` (levelled companion), cubit test line 136 |

No orphaned requirement: PET-01..PET-10 are all claimed by the plans.

## Checks asked by the orchestrator

1. **Wiring (no orphan).** `CompanionVitalityScope` wraps the Journal (`journal.dart:496`) and is read by the companion section, the items section and the details bookmark. Details sheet reachable from Journal (parchment and slot long press), shop list, basket/sell, quest-sheet prize, innkeeper prize rows and catalogue sheet. Potion targets, name sheet (three entries), result-sheet lines, notification categories and innkeeper slider all have a production reader. VERIFIED.
2. **Single switch.** `lib/config/companion_care.dart:3` is `false`, pinned by `test/config/companion_care_test.dart`. Readers: `items_section.dart:49,186` (potion targets: with `[]` the potion row falls back to today's), `journal.dart:46,350` (rename in details), `shop.dart:37,386` (purchase prompt), `quest_result_presenter.dart:30,243` (prize prompt). `showCompanionNameSheet` and `PotionCubit.give` have no other callers; shop and prize details routes pass no `onRename`. VERIFIED, nothing leaks with the switch off. **GraphQL:** against `origin/develop:src/schema.gql`, the only selection changes in `lib/graphql` are `imagePath` and `maxLifePoints` on `PetFragment` (both `Pet` fields exist, `imagePath: String!`, `maxLifePoints: Int!`) and `prizes.pet` now through `PetFragment` (`QuestRewards.pet: Pet`). No `defeated`, `lifeAsOf`, `fullLifeAt`, `onFoot`, `companionLifeAfter`, `Pet.recoveryTime` in any selection. One new operation document, `CharacterMutations.renamePet` (`character_mutations.dart:75`): not present on today's BE, only reachable through the switch, already registered for the schema check; the `companionLifeAfter` correction key can only be sent when the (unselected) companion outcome parsed, so it is unreachable pre-gate. Benign. VERIFIED.
3. **Rule 4.** `Pet.recoveryTime` is read only to print the recovery-time line in the details sheet (`companion_info.dart:77`). Vitality is interpolated between served `lifeAsOf`/`fullLifeAt` (`companion_vitality.dart:56-80`, integer rounding like the BE after A-04, capped at `max - 1`, never below the served life); no level, threshold, max, defeat or potion wait is computed from xp (grep for xp/level arithmetic in models, utils, screens, shared: none). Defeat is the served `defeated` flag or `fullLifeAt` in the future; potion wait is the served `potionRecoveryUntil`. The «Sconfitto» marker in the correction slider (life == floor 1) is a display reading of D-17/D-33, accepted (B-08). VERIFIED.
4. **Rules 1/2.** Added code uses `showModalBottomSheet`/`showGeneralDialog` with transparent barrier and parchment widgets (same as existing sheets); no `AlertDialog`, `AppBar`, `Scaffold`, spinner among the added lines (diff `8916a129..HEAD` grep). The name sheet disables actions while in flight with no indicator. The only `CircularProgressIndicator` in touched files (`shop.dart:458`) is pre-existing. `TextButton`s sit in the existing parchment-sheet style; the settings `SwitchListTile` is a settings screen (allowed). VERIFIED.
5. **Test quality.** Targeted run: 803 tests green (see below). Every new/modified test file has at least as many assertion/verify lines as tests (scripted check); sampled files assert behaviour (user's 40-life example, ticker stop/start, stale vitality never serves an older entry, single-flight potion, switch-off tests that assert absence of entry points). Fixer retargets judged:
   - `quest_result_test` missing-name case -> missing `lifeBefore`: sound, because blank/missing name now has its own positive tests (`quest_companion_outcome_test.dart` «Il tuo compagno» keeps defeat, life, max; `mission_fight_test.dart` «Compagno» keeps slider).
   - `pet_rename_failure_test` «unknown code -> unknown» replaced by FORBIDDEN -> forbidden, served unknown code (MISSION_IN_PROGRESS, PET_ALREADY_OWNED) -> refused, no code -> unknown: stronger, matches the no-retry ruling.
   - speed-line pins (`companion_row_test`, `companion_info_sheet_test`): now assert the line is absent from the row and appears exactly once, inside `CompanionCard`; tap/position/style/order pins moved to the card or the equipped mark with `isEquipped: true` fixtures. They still protect the behaviour. The old «lines sit between the speed and the equipped mark» became «above the equipped mark» (3 tops instead of 4): fine.
   One weakness (V-01, low): see gaps.
6. **Deferred review findings.** A-05 (refused `givePotion` closes the whole sheet): safe to leave; unreachable with the switch off, BE refusal plus banner naming the companion explain the failure; judge in UAT whether the sheet should stay open. A-09 (shop sell-side details show no level/xp/life): safe, cosmetic and out of D-35's list of required content. `deferred-items.md` (shop satchel `CoinsDisplay` overflows 6 px on the 780x360 test surface with coins): pre-existing, test-surface only; confirm no overflow on the device during 22-17. B-01 (`petRecovered` dedup key) is a BE contract item, ruled «no FE change».

## Anti-patterns

No TODO/FIXME/placeholder in the 69 touched lib files. No stub, empty handler or hollow prop found in the paths above. Data-flow: pre-gate the new wire fields are parsed leniently but not selected, so on a real server the new UI shows steady/unnamed companions and the switch hides the actions; this is the intended pre-gate state, not a hollow wiring (the parsers are covered by hand-written JSON fixtures, the live trace is a gate item).

## Spot-checks

| Behaviour | Command | Result |
|-----------|---------|--------|
| Models, vitality, quest results, mission fight, rename/useItem failures, Journal, details route, name sheet, switch, GraphQL documents, schema registry | `flutter test test/models/companion test/models/owned_pet_test.dart test/models/pet_test.dart test/models/quest_result test/models/mission/mission_fight_test.dart test/repository/pet_rename_failure_test.dart test/repository/item_use_failure_test.dart test/screens/mainScreen/tabs/journal test/shared/components/popup/companion_details_route_test.dart test/shared/components/popup/companion_name_sheet_test.dart test/config test/graphql test/tool` | +803 All tests passed |

## Deferred to the gated plans 22-16 / 22-17

**22-16 (schema gate, after the BE Phase 23 merge):**
- Re-read the merged `src/schema.gql`; check that `OwnedPet { name defeated lifeAsOf fullLifeAt potionRecoveryUntil level maxLifePoints }`, `Pet.recoveryTime`, `QuestResult.companion { defeated fullLifeAt lifeBefore lifePoints maxLifePoints name }`, `AmbushReport.onFoot`, `MissionFightOutcome.companion { pet name lifeBefore maxLifePoints }`, `MissionFightEffects.companionLifeAfter`, `ParticipantOverrideInput.companionLifeAfter`, `RenamePetRequest { id petId name }`, `renamePet`, `UseItem` target (pet id) and `PushEventType` `ambush` / `petRecovered` exist with the exact names/nullability the parsers assume (`MissionCompanion` and the push types were not in today's SDL).
- Add the gated selections to the fragments/documents (list in 22-REVIEW.md "Gate reminders"), add the `UseItem` target to `CharacterMutations.useItem`, `ItemUseRepository` and `PotionCubit.give`.
- Flip `companionCareEnabled` to `true` (update `companion_care_test.dart`), registry count 55, run the schema check against the merged SDL, full suite and analyzer.
- Confirm the codes `PET_DEFEATED`, `PET_POTION_RECOVERING` (`extensions.recoveryUntil`), `ITEM_NO_EFFECT`, `PET_NAME_INVALID`, `FORBIDDEN` are the ones the BE emits; confirm the `petRecovered` push id is the pet id (B-01).

**22-17 (device E2E, human):**
- Resting companion life rises live and matches the BE value on reopen (rounding parity, A-04); defeated parchment faded, countdown, back by itself and push «in forze».
- Potion on a companion (equipped and resting), refusals by name, row tappable during the character's wait.
- Names at purchase, after a prize, from the details sheet; `PET_NAME_INVALID` retry/skip; rename during «Missione in corso».
- Result sheet life/defeat/xp lines and ambush «Prosegui a piedi»; push per ambush and banner suppression; ambush parchments mid-travel.
- Innkeeper companion slider in the guided flow (A-02/B-05 behaviour on a real draft).
- Device-only judgements: A-05 (sheet after a refused potion), details sheet look with the Material fix (no underline), `deferred-items.md` satchel overflow, A-03 one-frame defeated tap on a real stream.

## Gaps summary

No functional gap. V-01 (low): `journal_companion_details_test.dart` second `longPressWorg` of the switch-on case misses its target and passes on the state left open by the first half; fix with a fresh pump or an explicit close before the second gesture. It can be fixed in the gate plan's commit. V-02 is bookkeeping for the gated plans.

---

_Verified: 2026-11-14_
_Verifier: Claude (gsd-verifier)_
