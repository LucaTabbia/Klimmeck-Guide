---
phase: 22
slug: companion-defeat-rest-and-recovery
status: secured-pre-gate
audited: 2026-11-14
scope: pre-gate (plans 01-15)
asvs_level: 1
block_on: high
head: fa8a698f
threats_total: 60
threats_closed: 49
threats_open: 0
threats_gated: 11
unregistered_high: 0
---

# Phase 22 Security Audit (pre-gate, plans 01-15)

`tool/hardening_check.sh` run without an APK: `hardening_check: OK`. `companionCareEnabled = false` (`lib/config/companion_care.dart:3`, pinned by `test/config/companion_care_test.dart`).
Verdicts: CLOSED = mitigation found (or accepted/transferred as declared). GATED = belongs to plans 16-17, open until those plans run.

## Threat verification

| Threat | Disp. | Mitigation found | Evidence | Verdict |
|---|---|---|---|---|
| T-22-01 | mitigate | gated fields not selected | `grep lifeAsOf/fullLifeAt/recoveryTime lib/graphql` only hits `spell_fragment.dart` (spells, pre-existing); `pet_fragment.dart:9-30` has no gated field | CLOSED |
| T-22-02 | mitigate | lenient reads | `owned_pet.dart` (tryParse/== true); `test/models/owned_pet_test.dart`, `pet_test.dart` | CLOSED |
| T-22-03 | accept | display only | name rendered as plain Text; BE authority | CLOSED (accepted) |
| T-22-04 | mitigate | Pending rows only | no `mark-complete` before 22-17 (planning only) | CLOSED |
| T-22-05 | mitigate | rule reads served dates and `isDefeated` only | `companion_vitality.dart:56-85`, no `recoveryTime`; `companion_vitality_test.dart` | CLOSED |
| T-22-06 | accept | `name_rules` is UX only | `lib/utils/name_rules.dart:1-2`; BE `PET_NAME_INVALID` mapped `pet_rename_failure.dart:61` | CLOSED (accepted) |
| T-22-07 | mitigate | span<=0 and clamp | `companion_vitality.dart:105-112` (`spanMs <= 0`, `clamp`); edge-clock tests in `companion_vitality_test.dart` | CLOSED |
| T-22-08 | mitigate | character-name rules extracted unchanged | `name_rules.dart` shared by `character_draft.dart`; character-creation tests | CLOSED |
| T-22-09 | mitigate | only today's `Pet` names selected | `pet_fragment.dart`; no `recoveryTime` | CLOSED |
| T-22-10 | mitigate | scoped ticker, closes | `companion_vitality_cubit.dart:33,72,78-87` (`_timer ??=`, `_stopTimer`, `close()` cancels); cubit tests | CLOSED |
| T-22-11 | accept | display only | BE `PET_DEFEATED` mapped `pet_equip_failure.dart` | CLOSED (accepted) |
| T-22-12 | mitigate | https / `v<n>/` only | `lib/utils/enemy_portrait_url.dart:10-18` | CLOSED |
| T-22-13 | mitigate | no image on failure | `enemy_portrait.dart` (Phase 9 D-03) | CLOSED |
| T-22-14 | mitigate | spell sheet tests kept | `test/shared/components/spell_info_test.dart` | CLOSED |
| T-22-15 | mitigate | one switch off, route sheet no rename | `companion_care.dart:3`; `companion_care_test.dart`; `journal.dart:350` gate | CLOSED |
| T-22-16 | accept | plain `Text` | no `RichText/TextSpan/Html/Markdown` fed with a name in phase diff | CLOSED (accepted) |
| T-22-17 | accept | own data only | `companion_info.dart` renders served data | CLOSED (accepted) |
| T-22-18 | mitigate | defeated not tappable | `owned_companion_row.dart:40,45`; `journal.dart:318-320` `canToggle` | CLOSED |
| T-22-19 | mitigate | no toggle on mission | `journal.dart:319` (`!character.isOnMission`), `journal_companion_details_test.dart` | CLOSED |
| T-22-20 | accept | scoped BlocBuilder | `journal.dart:313-316` | CLOSED (accepted) |
| T-22-21 | mitigate | long press read-only | `companion_row.dart` / `shop.dart`, tap selects | CLOSED |
| T-22-22 | accept | own `ownedPets` only | `character_assets.dart` `chosenPetNames` | CLOSED (accepted) |
| T-22-23 | accept | decision in CONTEXT | BE judges the trade | CLOSED (accepted) |
| T-22-24 | mitigate | prize pet fields today only | `quest_fragment.dart` uses `PetFragment` (no gated names) | CLOSED |
| T-22-25 | mitigate | read-only sheet | `prizes_step.dart`, `prize_catalogue_sheet.dart` long press | CLOSED |
| T-22-26 | mitigate | `UseItem` does not declare `$petId` | `character_mutations.dart:85-87`; `test/graphql/use_item_document_test.dart:16` | CLOSED (see U-1) |
| T-22-27 | transfer | BE bearer-only; FE sends ids from `ownedPets` | `companion_potion_target.dart:17` `owned.pet.id`; `potion_cubit.dart:27-47` | CLOSED |
| T-22-28 | mitigate | single flight | `potion_cubit.dart:42` (`state is PotionDrinking` return) | CLOSED |
| T-22-29 | mitigate | banners and re-read | `item_use_failure.dart`, `potion_notice.dart`, `potion_outcome_listener.dart:23-27` (`petDefeated` re-reads) | CLOSED |
| T-22-30 | mitigate | targets empty with switch off | `items_section.dart:186`; test group `companion targets on the potion row` | CLOSED |
| T-22-31 | accept | display only | BE refusals mapped | CLOSED (accepted) |
| T-22-32 | mitigate | disabled while drinking | `potion_sheet.dart`, `potion_state.dart`; tests | CLOSED |
| T-22-33 | transfer | BE owner guard; FE sends shell character id and owned pet id | `companion_name_sheet.dart` args, `companion_repository.dart:41-43` | CLOSED |
| T-22-34 | transfer | BE rules + client check | `companion_name_sheet.dart:135-136,217` | CLOSED |
| T-22-35 | mitigate | entry points behind switch | `journal.dart:350`, `shop.dart:386`, `quest_result_presenter.dart:243` | CLOSED |
| T-22-36 | mitigate | no log of names | diff has zero `appLog/print/debugPrint` additions; `hardening_check.sh` OK | CLOSED |
| T-22-37 | mitigate | 2-20, charset, blocks confirm | `name_rules.dart:8-9,17-27`; `companion_name_sheet.dart:135-136` (`canConfirm`) | CLOSED |
| T-22-38 | mitigate | shell character only | `quest_result_presenter.dart:247` (`character.id != result.characterId`), ambush excluded `:245` | CLOSED |
| T-22-39 | mitigate | switch default off | see T-22-35 | CLOSED |
| T-22-40 | mitigate | disabled + pop blocked + single flight | `companion_name_sheet.dart:93-94,169`; `companion_name_cubit.dart:27` | CLOSED |
| T-22-41 | mitigate | malformed entry -> null | `quest_companion_outcome.dart:30-47` (`tryFromJson`) | CLOSED |
| T-22-42 | mitigate | duration from served dates | `quest_companion_outcome.dart` `fullLifeAt`, `quest_outcome_lines.dart` | CLOSED |
| T-22-43 | mitigate | no log added | as T-22-36 | CLOSED |
| T-22-44 | mitigate | storage key kept | `notification_category.dart:15` `'ambush_defeat'`; `notification_category_test.dart:25,33`; `notification_preferences_store_test.dart:70` | CLOSED |
| T-22-45 | mitigate | unknown types dropped | `notification_category.dart` `fromWireType` -> null; `push_event.dart:39` | CLOSED |
| T-22-46 | accept | ids validated | `push_event.dart:39` `validBackendIdentifier`; `notificationId = stableNotificationId(dedupKey)` (hash, not raw id) | CLOSED (accepted) |
| T-22-47 | accept | UX only | `push_event.dart:45` dedupKey | CLOSED (accepted) |
| T-22-48 | mitigate | slider bounded | `life_slider.dart:27-34` (`minLifeAfterFight..max`, clamp); BE re-validates | CLOSED |
| T-22-49 | mitigate | key only when non-null | `mission_draft_inputs.dart:115`; `mission_draft_inputs_test.dart` | CLOSED |
| T-22-50 | accept | unchanged Phase 21 | innkeeper panel | CLOSED (accepted) |
| T-22-51..55 | mitigate | plan 16 (schema gate) not executed | | GATED |
| T-22-56..60 | mitigate/accept | plan 17 (device E2E) not executed | | GATED |

Totals: 49 closed (of which accepted/transferred 19), 0 open, 11 gated.

## Unregistered findings

| ID | Severity | Finding | Recommendation |
|---|---|---|---|
| U-1 | low | `KlimmeckGraphQl.useItem` (`graphql.dart:893`) adds the `petId` variable whenever one is passed, while the document does not declare `$petId` yet. Unreachable today (switch off, targets empty `items_section.dart:186`); some servers reject undeclared variables. | 22-16 must declare `$petId: ID` in the same commit that turns the switch on; keep `use_item_document_test` in step. |
| U-2 | info | Name length is checked on UTF-16 units (`name_rules.dart:19-20`); an astral letter counts 2. UX only, BE is the authority. | None. |
| U-3 | info | Served names (`OwnedPet.name`, `QuestCompanionOutcome.name`) are trimmed but not re-validated; rendered only in plain `Text` and `giveToCompanionLabel`. No rich text, no logs. | None. |
| U-4 | info | Push: `petRecovered` and `ambush` ids pass `validBackendIdentifier`; notification id is a stable hash of `dedupKey`, banner suppression keyed on `wireType|id`. Legacy wire type `ambushDefeat` still accepted. | None. |
| U-5 | info | No secret, URL or token added in the phase diff (`git diff 8916a129..HEAD -- lib tool` grep clean). Ids in `RenamePetRequest`/`useItem` come only from `character.id` and `owned.pet.id`; no user-typed id. | None. |

No unregistered finding of severity high or medium. Rules owned by the backend (defeat, slope, eligibility) are display only on the client (`companion_vitality.dart`, `companion_potion_target.dart:30-33`).
