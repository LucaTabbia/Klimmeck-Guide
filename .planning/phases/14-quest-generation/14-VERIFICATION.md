---
phase: 14-quest-generation
verified: 2026-11-04T19:22:00Z
status: human_needed
score: "6/6 success criteria verified in code and tests for plans 14-01..14-09; QGEN-01..06 accounted for; schema-gated plan 14-10 and device E2E plan 14-11 deferred"
overrides_applied: 0
re_verification:
  previous_status: none
  note: "Initial verification. No previous VERIFICATION.md existed."
gaps: []
deferred:
  - truth: "14-10: contract names (type QuestEnemy, QuestInfos.enemies/description, QuestResult.enemies/stagesCleared/stagesTotal, QuestPrizes.pet, QuestRewards.pet, enum AccessoryUseType, EquipmentItem.accessoryUseTypes, generateQuests: GenerateQuestsResult!) proved on the merged BE `origin/develop:src/schema.gql`, and the 44 registry documents validated against it (44/44 OK)"
    addressed_in: "Plan 14-10 (gated on the BE Phase 13 PR merge, CONTEXT D-13)"
    evidence: "14-10-PLAN.md; the FE registry holds 44 documents and its test passes, but the names come from 14-REPO-RULES / BE 13-CONTEXT, not yet proved on the merged SDL (RESEARCH §Schema gate procedure: `grep -c QuestEnemy` on BE develop must be >= 1, today 0)."
  - truth: "14-10: full-suite and analyzer gate in the gate plan, new Dart files format-clean, 14-VALIDATION.md filled and signed off"
    addressed_in: "Plan 14-10"
    evidence: "Sign-off of 14-VALIDATION.md is a 14-10 task; this verification ran the relevant directories and the analyzer, not the plan's final gate."
  - truth: "14-11: `14-HUMAN-UAT.md`, `BACKEND-NOTES.md`, device E2E (9 steps), QGEN-01..06 ticked in REQUIREMENTS.md, ROADMAP/STATE closure (14-10 and 14-11 left `[ ]` in ROADMAP by design), ROADMAP SC1 wording «3 × Goblin» to «3x Goblin»"
    addressed_in: "Plan 14-11 (human checkpoint, gated on 14-10 and the device run)"
    evidence: "14-11-PLAN.md; `ls .planning/phases/14-quest-generation/` has no 14-HUMAN-UAT.md, no BACKEND-NOTES.md, no 14-10/14-11 SUMMARY; REQUIREMENTS.md keeps QGEN-01..06 as `[ ]` / Pending by design."
human_verification:
  - test: "1. Settings > Locanda: «Genera missioni» is visible at the top, above the queue (also with «Nessuna richiesta in attesa»). Tap, dialog «Generare nuove missioni nel mondo?», «Annulla»: nothing happens. Tap again, «Genera»: the button is disabled while the call runs, then SnackBar «Generate N missioni» / «Generata 1 missione» / «Nessuna missione da generare» (QGEN-03; D-08, D-09)"
    expected: "Button visible, Annulla makes no call, Genera shows the disabled state and the correct SnackBar"
    why_human: "device E2E of the gated plan 14-11; needs the BE Phase 13 `generateQuests` live and an innkeeper account"
  - test: "2. Board (reopen the tab, BE D-18), a generated `enemy` quest (QGEN-01, QGEN-05; D-02, D-04, D-05)"
    expected: "Announcement under the title (italic), portrait only if the enemy has a Cloudinary path, «Nx nome» lines (e.g. «3x Goblin», «1x Capo goblin») in the order of the title, «Consigliati» when the quest has recommended loot, one slot line of the rank; nothing marks it as generated"
    why_human: "needs generated quests served by the BE and the visual layout reviewed by the user"
  - test: "3. A generated `boss` quest; optional «Compagno in premio» when the user set `prizes.pet` at DB (QGEN-01; D-06)"
    expected: "Enemy name (bare, quantity 1), party slot lines (2-6 seats of the rank); optional «Compagno in premio: <nome>»"
    why_human: "BE data and visual review; the pet part needs a DB edit by the user (optional, never blocks)"
  - test: "4. A fixed dungeon (enriched, 2-4 stages) (QGEN-01, QGEN-04)"
    expected: "Combat family, lines in stage order, «Consigliati»"
    why_human: "needs the BE-seeded dungeon on the device"
  - test: "5. Resolve that dungeon (accept + resolution, or GM completion from the Locanda) (QGEN-02; D-07)"
    expected: "Result sheet lists the enemies fought («Nx nome») and «Esplorazione: tappa k di N»; a victory shows all the stages"
    why_human: "real resolution against the BE `stagesCleared`/`stagesTotal`"
  - test: "6. A fixed `crime` or `guard` quest sheet (QGEN-04, QGEN-05; D-11)"
    expected: "Service family (no enemy column) with its announcement; no alignment anywhere"
    why_human: "needs the BE Phase 11 fixed quests on the device and visual review"
  - test: "7. Journal, tap a ring and a necklace (owned or worn); the same in the shop item sheet if a jewel is on sale (QGEN-06; D-12)"
    expected: "«Uso: attacco» / «Uso: difesa» / «Uso: attacco e difesa»; a helm shows no «Uso» line"
    why_human: "needs jewels with `accessoryUseTypes` served by the BE (BE Phase 13 data)"
  - test: "8. Portrait: an enemy whose `imagePath` the user set to a Cloudinary path/URL (QGEN-01; D-03)"
    expected: "Portrait on the quest sheet; an enemy still on the placeholder `assets/images/...` shows only the name"
    why_human: "needs a DB edit by the user and a visual check"
  - test: "9. Optional: a result with `rewards.pet` (QGEN-02; D-07)"
    expected: "«Compagno ottenuto: <nome>» on the result sheet"
    why_human: "needs a DB edit by the user; optional, covered by the 14-06 widget test, never blocks a requirement"
---

# Phase 14: Quest Generation (frontend companion) - Verification Report

**Phase Goal:** The board and the result sheet speak the new multi-enemy contract (`infos.enemies: [{ enemy, quantity }]` replaces `infos.enemy`, BE Phase 13) and the innkeeper can force the generator from the «Locanda»; generated quests look like any other quest and the frontend never generates anything itself.
**Branch:** feat/14-quest-generation @ a4ad08f (base develop 9993a3c)
**Verified:** 2026-11-04T19:22:00Z
**Status:** human_needed
**Re-verification:** No, initial verification.
**Scope note:** plans 14-10 (schema gate vs merged BE Phase 13) and 14-11 (device E2E, handoff, closure) are gated on the BE Phase 13 merge (CONTEXT D-13). Their must-haves are deferred, not gaps. REQUIREMENTS.md keeps QGEN-01..06 as `[ ]` / Pending by design.

## Evidence gathered (run by the verifier)

| Check | Result |
|-------|--------|
| `flutter test test/models test/repository test/graphql test/tool` | 1448 passed, "All tests passed!" |
| `flutter test test/screens/innkeeper` | 173 passed, "All tests passed!" |
| `flutter test test/screens/mainScreen` | 896 passed, "All tests passed!" |
| `flutter test test/shared test/utils` | 309 passed, "All tests passed!" |
| `flutter analyze` | 50 issues, all info (0 error, 0 warning); baseline 50 held |
| Schema-check registry (`tool/schema_check/schema_check_documents.dart`) | 44 entries incl. `GenerateQuests`; registry test green |
| Single `enemy` selection at quest level | gone: `enemy {` now only nested inside `enemies { quantity enemy {...} }` in `quest_fragment.dart` and `quest_result_fragment.dart` |
| TODO/FIXME/`print(` in innkeeper screens, `enemy_portrait*`, `models/quest` | none |
| `git status --short` before writing this report | clean |

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Combat sheets list every enemy with quantity; eligibility/loot unchanged; single `enemy` gone from every document and model | VERIFIED (code + tests; schema proof deferred) | `QuestEnemy` + `QuestInfos.enemies`, fragment selects `enemies { quantity enemy { id name imagePath xp } }`, `QuestSheetDetails` enemy lines; models/graphql/quest sheet tests green. Registry green; "green against the BE schema" is plan 14-10 |
| 2 | Result sheet shows the enemies fought (standard and ambush) | VERIFIED | `QuestResult.enemies`, `stagesCleared/stagesTotal` in `quest_result_fragment.dart`; `quest_result_sheet.dart` renders the list and «Esplorazione: tappa k di N» (line 387); tests green. Live outcome is step 5 |
| 3 | «Genera missioni» from the Locanda with confirmation, outcome shown, `FORBIDDEN` mapped inline | VERIFIED | `QuestMutations.generateQuests`, `InnkeeperRepository.generateQuests`, `QuestGenerationCubit` provided in `innkeeper_panel_route.dart`, `GenerateQuestsButton` in `innkeeper_panel_screen.dart` with `BlocListener<QuestGenerationCubit,...>`; `FORBIDDEN` -> `_closeUnavailable`; 173 innkeeper tests green. Live run is step 1 |
| 4 | Fixed `crime`/`guard` render with the service layout, `dungeon` as combat, no alignment | VERIFIED | `questSheetFamilyOf`: `dungeon` in combat, crime/guard fall to service; `quest_info_sheet_test` asserts `'crime': 'service'`, `'guard': 'service'` and the dedicated crime/guard test (D-11, D-16). Live steps 4, 6 |
| 5 | Announcement under the title in every family; «Consigliati» in combat body; portrait from the network, hidden when missing | VERIFIED | `quest_info_sheet.dart`: `descriptionKey`, `recommendedLootTitle = 'Consigliati'`, `EnemyPortrait.canShow` gate; `enemy_portrait_url.dart` + shared `EnemyPortrait` (also used in the result sheet); tests green. Live steps 2, 8 |
| 6 | «Uso: ...» on rings/necklaces from `accessoryUseTypes`; companion prize and reward lines | VERIFIED | `AccessoryUseType`, `EquipmentItem.accessoryUseTypes`, fragment selects it in both equipment fragments (`equipment_fragment.dart:37,84`), `item_lines.dart` builds «Uso: ...», `equipment_info_sheet.dart` renders it; `petPrizeKey` «Compagno in premio» (quest sheet) and «Compagno ottenuto» (result sheet, line 394). Live steps 3, 7, 9 |

**Score:** 6/6 success criteria verified in code and tests for 14-01..14-09 (live behaviour is the deferred device E2E).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/models/quest/{quest_enemy,quest_infos,quest_prizes,quest_sheet_details}.dart`, `lib/models/quest_result/{quest_result,quest_rewards}.dart` | models of 14-01/14-02 | VERIFIED | exist, tested (`test/models/**`) |
| `lib/graphql/fragments/{quest_fragment,quest_result_fragment,equipment_fragment}.dart` | documents of 14-03/14-09 | VERIFIED | contain `enemies`, `description`, `stagesCleared`, `pet`, `accessoryUseTypes` |
| `lib/utils/enemy_portrait_url.dart`, `lib/shared/components/enemy_portrait.dart` | 14-04 | VERIFIED | used by quest and result sheets |
| `lib/shared/components/popup/{quest_info_sheet,quest_result_sheet,equipment_info_sheet}.dart`, `lib/utils/item_lines.dart` | 14-05/14-06/14-09 | VERIFIED | tested |
| `lib/graphql/mutations/quest_mutations.dart`, `lib/repository/{innkeeper_repository,services/graphql/graphql}.dart`, `innkeeper/questGenerationCubit/*` | 14-07 | VERIFIED | registry entry `GenerateQuests` present |
| `lib/screens/innkeeper/components/generate_quests_button.dart`, `innkeeper_panel_{route,screen}.dart` | 14-08 | VERIFIED | provider and listener wired |
| `lib/models/enums/accessory_use_type.dart` | 14-09 | VERIFIED | |
| `14-HUMAN-UAT.md`, `BACKEND-NOTES.md`, `14-10/14-11-SUMMARY.md` | 14-10/14-11 | DEFERRED | absent by design |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `QuestFragment` / `QuestResultFragment` | `QuestInfos.enemies` / `QuestResult.enemies` models | selection `enemies { quantity enemy {...} }` | WIRED | model + graphql tests green |
| `QuestInfoSheet` / `QuestResultSheet` | `EnemyPortrait` -> `enemyPortraitUrl` | `EnemyPortrait.canShow(path)` | WIRED | `quest_info_sheet.dart:203`, `quest_result_sheet.dart:240` |
| `GenerateQuestsButton` | `QuestGenerationCubit` -> `InnkeeperRepository.generateQuests` -> `KlimmeckGraphQl.generateQuests` | cubit + repository | WIRED | innkeeper screen/cubit tests green |
| `InnkeeperPanelRoute` | `QuestGenerationCubit` provider | `BlocProvider` (line 36) | WIRED | |
| `InnkeeperPanelScreen` | `FORBIDDEN` -> close panel | `BlocListener` + `_closeUnavailable` | WIRED | |
| `EquipmentFragment` | `EquipmentItem.accessoryUseTypes` -> `item_lines` -> `EquipmentInfoSheet` | fragment + model + sheet | WIRED | tests green |

### Behavioral Spot-Checks

Test suites above are the behavioural evidence; no server was started. Live behaviour against the BE is the device E2E.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| QGEN-01 | 14-01, 03, 04, 05 | enemies with quantities, portrait of the strongest, «Consigliati», `enemy` removed | SATISFIED in code and tests; device steps 2, 3, 4, 8 and schema proof pending | truths 1, 5 |
| QGEN-02 | 14-02, 03, 06 | result sheet with enemies, stages, companion reward | SATISFIED in code and tests; device steps 5, 9 pending | truth 2 |
| QGEN-03 | 14-07, 08 | «Genera missioni» with confirmation, outcome, FORBIDDEN | SATISFIED in code and tests; device step 1 pending | truth 3 |
| QGEN-04 | 14-05, 06 | crime/guard service family, dungeon combat | SATISFIED in code and tests; device steps 4, 6 pending | truth 4 |
| QGEN-05 | 14-01, 05 | announcement under the title in every family | SATISFIED in code and tests; device steps 2, 6 pending | truth 5 |
| QGEN-06 | 14-09 | «Uso» line from `accessoryUseTypes` | SATISFIED in code and tests; device step 7 pending | truth 6 |

No orphaned requirements: ROADMAP maps only QGEN-01..06 to Phase 14. Boxes stay unticked until 14-11.

### Anti-Patterns Found

None blocking. No TODO/FIXME, no `print(` in the touched innkeeper, portrait and quest-model code. The `enemy {` match in the fragments is the nested selection inside `enemies`, not the removed top-level one.

### Human Verification Required

The 9 device steps of `14-11-PLAN.md` / `14-RESEARCH.md` §Manual-only, listed in the frontmatter. Setup: BE `develop` with Phase 13 merged running locally, Android via USB with `adb reverse tcp:3000 tcp:3000`, innkeeper device account; optional DB edits by the user for step 3 (`prizes.pet`), step 8 (Cloudinary `imagePath`) and step 9 (`rewards.pet`). Gate re-check first: `grep -c "QuestEnemy"` on `origin/develop:src/schema.gql` must be >= 1.

### Gaps Summary

No gaps. Everything plans 14-01..14-09 promised exists, is wired and is covered by passing tests (2826 tests across the requested directories, 0 failures; analyzer 0 error / 0 warning, 50 info). Remaining work is the gated plan 14-10 (schema proof against the merged BE Phase 13, 44/44 documents) and 14-11 (device E2E, handoff, closure).

---

_Verified: 2026-11-04T19:22:00Z_
_Verifier: Claude (gsd-verifier)_
