---
phase: 15-travel-food
verified: 2026-11-05T21:44:20Z
status: passed
score: "4/4 success criteria verified in code, tests and the device E2E of 2026-11-06 (steps 1–8 passed)"
overrides_applied: 0
re_verification:
  previous_status: none
  note: "Initial verification. No previous VERIFICATION.md existed."
gaps: []
deferred: []
closed_note: "Closed on 2026-11-06: 15-08 proved the contract names on the merged BE SDL b492a46 and validated 45/45 documents; 15-08 ran the full suite, analyzer/format/trailer gates and signed 15-VALIDATION.md; 15-09 wrote 15-HUMAN-UAT.md and BACKEND-NOTES.md and closed FOOD-01..04 after the device E2E."
human_verification:
  - test: "1. Trip fully covered: enough food, drag the pawn to a near city -> the sheet shows «Cibo: 1x <nome>» (BE order, «Nx nome») and «Vita: nessuna perdita»; «Parti» -> the pawn leaves; Journal «Oggetti» shows the food decreased and «Punti vita» unchanged; no banner after the departure (FOOD-01, FOOD-04; D-02, D-07)"
    expected: "Rows as described, food decreased and HP unchanged only via characterUpdated, no banner"
    why_human: "device E2E of the gated plan 15-09; needs BE Phase 14 live and food seeded at DB by the orchestrator"
    outcome: "«pass» (2026-11-06): 2x Manzo Essiccato eaten Chargate → Voxhold, HP 38 700 unchanged"
  - test: "2. Trip partially covered: little food, a farther city -> «Vita: −N HP» (minus sign) and the food it will eat; «Parti» -> Journal: that food gone and «Punti vita» reduced by N; no banner (FOOD-01, FOOD-04; D-02, D-11)"
    expected: "Minus sign U+2212, food gone and HP reduced by N in the Journal"
    why_human: "needs real BE preview/departure numbers and the Journal updated by the live subscription"
    outcome: "«pass» (2026-11-06): «Vita: −45 HP», Cosciotto di pollo eaten, HP 38 700 → 38 655"
  - test: "3. Trip refused at the preview: no food (or low HP), a far city -> the «Vita» row is red «Non hai cibo a sufficienza per il viaggio» (no number), «Cibo» still lists what would be eaten (or «nessuno»), «Parti» disabled; «Resta» closes the sheet (FOOD-01; D-02, D-10)"
    expected: "Red phrase, «Parti» disabled, «Resta» closes"
    why_human: "needs BE `arrivesAlive: false` on a real character and visual review of the red row"
    outcome: "«pass» (2026-11-06): Murnborim, red phrase, «Cibo: nessuno», «Parti» disabled"
  - test: "4. Starving refusal at the departure: open the sheet with enough food, then (orchestrator) remove the food / lower the HP at DB, tap «Parti» -> banner «Viaggio non partito» / «Non hai cibo a sufficienza per il viaggio»; the sheet stays open, the dashed route stays, the rows refresh to the red phrase with «Parti» disabled; «Resta» closes it (FOOD-03; D-03, D-06)"
    expected: "Banner, sheet kept open through the requote, rows refreshed red, route kept"
    why_human: "needs the live `TRAVEL_STARVING` refusal produced by the BE after a DB change"
    outcome: "«foglio aperto» then «pass» (2026-11-06): banner, sheet kept open with the route, rows red; nothing written at DB"
  - test: "5. Quest line: a combat quest and a service quest whose marker is not the character's position, opened from the Board with the swipe available -> one line «Viaggio: <cibo> · <vita>» in the costs block; a story sheet, a non-acceptable quest and the map overlay show no «Viaggio» line (FOOD-02; D-04)"
    expected: "One «Viaggio» line on combat/service sheets only"
    why_human: "needs the BE owner-only `questTravelPreview` live and visual review of the costs block"
    outcome: "«Non è accettabile ( sono di rango troppo alto) e l'unico slot presente è da avventuriero», then «pass» (2026-11-06): combat line and the «no line» cases on the device; service-with-line and story halves skipped (not reproducible on this DB; covered by tests)"
  - test: "6. Quest starving: with no food (or low HP) the «Viaggio» line is red «Viaggio: Non hai cibo a sufficienza per il viaggio» and the paper resists the swipe; then with food at the sheet opening, remove it at DB and tear the sheet -> banner «Missione non accettata» / «Non hai cibo a sufficienza per il viaggio», the sheet recomposes and its line turns red (FOOD-02, FOOD-03; D-04, D-05, D-06)"
    expected: "Red line, swipe blocked; acceptance refusal banner, recomposed sheet with red line"
    why_human: "needs live `TRAVEL_STARVING` on acceptance and a physical swipe gesture"
    outcome: "«resiste», «foglio aperto», then «pass» (2026-11-06): red line and swipe resisted; acceptance refusal banner, sheet recomposed, line red"
  - test: "7. Teleport unaffected: the innkeeper teleports the test character (Locanda -> queue -> Map) -> Journal «Oggetti» and «Punti vita» unchanged (FOOD-04, ROADMAP criterion 4; BE D-13)"
    expected: "Inventory and HP unchanged after the teleport"
    why_human: "needs an innkeeper account and the live BE"
    outcome: "«Non posso sportarlo così. Avrei bisogno di una missione story da accettare. a quel punto sarei in coda e potrei spostarmi.», then «pass» (2026-11-06): teleport through the BE `teleportCharacter` mutation, Journal food and HP unchanged"
---

# Phase 15: Travel Food (frontend companion) - Verification Report

**Phase Goal:** Travelling costs food: before «Parti» (and on the quest sheet for the automatic travel) the player sees the food the backend will consume and the life lost on the uncovered part of the road; a departure refused for lack of food is explained on the banner; inventory and HP change only through the subscription.
**Branch:** feat/15-travel-food @ 9ae4281 (base develop 08bd1a1)
**Verified:** 2026-11-05T21:44:20Z
**Status:** passed (updated 2026-11-06 after the device E2E)
**Re-verification:** No, initial verification.
**Scope note:** plans 15-08 (schema gate vs merged BE Phase 14) and 15-09 (device E2E, handoff, closure) were gated on the BE Phase 14 merge (CONTEXT D-09); both ran on 2026-11-06 against BE `b492a46`: 45/45 documents OK, device E2E steps 1–8 passed (`15-HUMAN-UAT.md`), FOOD-01..04 ticked in REQUIREMENTS.md.

## Evidence gathered (run by the verifier)

| Check | Result |
|-------|--------|
| `flutter test test/models test/repository test/graphql test/tool` | 1515 passed, "All tests passed!" |
| `flutter test test/screens/mainScreen` | 953 passed, "All tests passed!" |
| `flutter test test/screens/auth test/shared test/utils` | 481 passed, "All tests passed!" |
| `flutter analyze` | 50 issues, all info (0 error, 0 warning); baseline 50 held |
| Schema-check registry | 45 documents (`the registry lists 45 documents (D-12)`), `GetQuestTravelPreview` present |
| `git status --short` before writing this report | clean |

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Confirmation sheet shows food and HP lost from `travelPreview`; red «Vita» phrase and «Parti» disabled on `arrivesAlive: false`; nothing computed on the client | VERIFIED (code + tests; device E2E 2026-11-06 passed) | `TravelPreview.food/hpLost/arrivesAlive`, `TravelFoodItem`, `TravelPreviewFragment`; `travel_cost_text.dart` (`foodText`, `lifeText`, `starvingPhrase`, U+2212, `noLifeLostText`); `travel_confirmation_sheet.dart` rows «Cibo»/«Vita», `isStarving: !preview.arrivesAlive`, «Parti» enabled only when `arrivesAlive`. Live: steps 1-3 |
| 2 | Combat/service quest sheets show a «Viaggio» line from an owner-only preview; red and swipe disabled when starving | VERIFIED (code + tests; device E2E 2026-11-06 passed) | `GetQuestTravelPreview` + `previewQuestTravel` + `TravelRepository.previewQuest`; `QuestTravelLine` ('Viaggio: ' prefix, starving phrase); `QuestSheetDetails.travelLine` rendered in both bodies of `quest_info_sheet.dart`; `QuestTravelPreviewCubit` per sheet in `board.dart`, `canTear` also requires `travelPreview?.arrivesAlive != false`. Live: steps 5-6 |
| 3 | `startTravel` starving refusal -> banner and sheet kept open with refreshed preview; `acceptQuest` refusal -> banner, sheet recomposed; Journal updates via `characterUpdated` | VERIFIED (code + tests; device E2E 2026-11-06 passed) | `travelStarvingCode` -> `TravelFailure.starving` / `QuestAcceptanceFailure.starving`, both notices map to `starvingPhrase`; `TravelRequoting` state in `travel_cubit.dart`, route/pawn layers keep it, `travel_outcome_listener.dart` one banner without reset; `board.dart` listener refreshes the preview on a starving acceptance refusal; no inventory/HP write in the FE (grep). Live: steps 4, 6 |
| 4 | Teleport and instant jump unaffected; device UAT | VERIFIED in code and on the device E2E 2026-11-06 passed (no FE change to the teleport path; null preview handled by tests; step 7 through the BE mutation) | `previewQuest` returns null when no travel (15-02/15-07 tests); the device UAT is plan 15-09 (step 7 for the teleport) |

**Score:** 4/4 success criteria verified in code, tests and the device E2E of 2026-11-06 (steps 1–8 passed).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/models/travel/{travel_food_item,travel_preview,travel_cost_text}.dart`, `lib/models/quantity_line.dart` | models/helpers of 15-01 | VERIFIED | exist, tested (`test/models/**`) |
| `lib/graphql/fragments/travel_preview_fragment.dart`, `lib/graphql/queries/travel_queries.dart`, `fragments.dart` | documents of 15-01/15-02 | VERIFIED | shared fragment, `GetQuestTravelPreview` |
| `tool/schema_check/schema_check_documents.dart` | registry 45 | VERIFIED | count test green |
| `lib/repository/{travel_failure,quest_acceptance_failure,travel_repository}.dart`, `services/graphql/graphql.dart` | 15-02/15-03 | VERIFIED | `previewQuestTravel`, `previewQuest`, `starving` |
| `travelCubit/{travel_cubit,travel_state,travel_notice}.dart`, `components/travel_outcome_listener.dart`, map layers | 15-04 | VERIFIED | `TravelRequoting` wired in cubit, listener, route and pawn layers |
| `travel_confirmation_sheet.dart`, `world_map.dart` | 15-05 | VERIFIED | rows and gating |
| `lib/models/quest/{quest_travel_line,quest_sheet_details}.dart`, `quest_info_sheet.dart` | 15-06 | VERIFIED | line in both bodies |
| `questTravelPreviewCubit/*`, `board.dart`, `authenticated_shell.dart` | 15-07 | VERIFIED | shell `RepositoryProvider<TravelRepository>`, cubit created per sheet |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| Board sheet | `QuestTravelPreviewCubit` | `needsTravelPreview` -> `load` | WIRED | `board.dart:283` |
| Preview cubit | `TravelRepository.previewQuest` | shell provider | WIRED | `authenticated_shell.dart:232` |
| Starving acceptance failure | preview refresh | `BlocListener` on `QuestAcceptanceFailed` | WIRED | `board.dart` |
| `TRAVEL_STARVING` | banner phrase | classifiers + notices | WIRED | `travel_notice.dart:19`, `quest_acceptance_notice.dart:37` |
| `TravelRequoting` | open sheet + route | listener, layers | WIRED | by hand (the plan regexes may print False for escaping) |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| Confirmation sheet | `preview.food/hpLost/arrivesAlive` | `GetTravelPreview` via shared fragment | Yes (BE server data; shape proved in 15-08, 45/45) | FLOWING |
| Quest sheet | `travelPreview` | `questTravelPreview` query via cubit | Yes (nullable, absent without travel) | FLOWING |

### Behavioral Spot-Checks

Step 7b: covered by the test runs above (no runnable server in the sandbox).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| FOOD-01 | 15-01, 15-05 | Rows «Cibo»/«Vita», red phrase, «Parti» disabled | SATISFIED (code + device steps 1-3 pass) | truth 1 |
| FOOD-02 | 15-02, 15-06, 15-07 | «Viaggio» line, red, swipe disabled | SATISFIED (code + device steps 5-6 pass; two halves of step 5 covered by tests) | truth 2 |
| FOOD-03 | 15-03, 15-04, 15-07 | Starvation banner, sheet kept open, recompose | SATISFIED (code + device steps 4, 6 pass) | truth 3 |
| FOOD-04 | 15-01..15-07 | Inventory/HP only via `characterUpdated`, nothing computed | SATISFIED (code + device steps 1, 2, 7 pass) | no client computation found |

No orphaned requirements: REQUIREMENTS maps only FOOD-01..04 to Phase 15.

### Anti-Patterns Found

None: no TODO/FIXME in the new travel models, repository, cubits and preview cubit; no empty-data stubs on the rendered paths.

### Human Verification Required

The 7 device steps in the frontmatter, run on 2026-11-06 (plan 15-09): all passed, outcomes in the frontmatter and in `15-HUMAN-UAT.md`.

### Gaps Summary

No gaps. Plans 15-08 and 15-09 ran on 2026-11-06 after the BE Phase 14 merge; the device E2E passed, so the status is `passed`.

---

_Verified: 2026-11-05T21:44:20Z_
_Verifier: Claude (gsd-verifier)_
