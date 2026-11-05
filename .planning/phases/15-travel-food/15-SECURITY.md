---
phase: 15
slug: travel-food
audited: 2026-11-05T21:55Z
status: secured
asvs_level: 1
block_on: high
threats_total: 29
threats_mitigated: 18
threats_accepted: 3
threats_transferred: 1
threats_open: 0
threats_open_blocking: 0
threats_deferred: 7
open_ids: []
deferred_ids: [T-15-22, T-15-23, T-15-24, T-15-25, T-15-26, T-15-27, T-15-28]
updated: 2026-11-05
---

# Phase 15 - Security (Travel Food, FE)

Audit of the threat registers of plans 15-01..15-09 (29 rows, T-15-01..T-15-29) against HEAD `f3c603b` of `feat/15-travel-food` (base `develop` `08bd1a1`, review fixes of `15-REVIEW-FIX.md` included). Plans 15-08 (schema gate vs merged BE Phase 14 SDL) and 15-09 (device E2E, handoff, traceability) are gated on the BE merge: their process threats are DEFERRED, not open. BE-side mitigations are TRANSFERRED with BE decision IDs (BE 14-CONTEXT D-04/D-05/D-06 food selection and consumption, D-08 owner-only preview, D-11 `TRAVEL_STARVING` before any write, D-12 transactional writes); the BE repo was not read or touched. No command read `.env`, `google-services.json` or environment variables. Implementation files read only.

Dispositions: mitigated / accepted / transferred / deferred.

## Threat Register

| ID | STRIDE | Component | Disposition | Evidence | Note |
|----|--------|-----------|-------------|----------|------|
| T-15-01 | DoS | `TravelFoodItem.listFrom` / `TravelPreview.fromJson` | mitigated | `lib/models/travel/travel_food_item.dart:35` (`listFrom` drops bad entries), `lib/models/travel/travel_preview.dart:36-39` (defaults 0/true/empty), `lib/repository/services/graphql/graphql.dart:800-806` (`_travelPreviewFrom` FormatException boundary); tests in 15-01 plan Tasks 1-2 | per-entry drop, core fields strict |
| T-15-02 | Tampering | `arrivesAlive` default `true` | accepted | 15-01 plan (accept); `travel_preview.dart:38` | UI gate is a convenience; BE D-11 refuses before any write and the refusal maps to the banner (T-15-09) |
| T-15-03 | Tampering | client food/HP arithmetic (model/text) | mitigated | `lib/models/travel/travel_cost_text.dart:29-31` only prints `hpLost` (`'−${preview.hpLost} HP'`), no arithmetic | cross-check 3 |
| T-15-04 | Info disclosure | `questTravelPreview` for another character | transferred | BE 14-CONTEXT D-08 (owner check, `FORBIDDEN`); FE sends only `viewer.characterId` (`board.dart:379`) | BE repo not read |
| T-15-05 | DoS | malformed/missing `questTravelPreview` | mitigated | `graphql.dart:660-664` (`containsKey` guard + `FormatException`), `travel_repository.dart` `previewQuest` through `_guard`; sheet hides the line on failure (`QuestTravelPreviewFailed`) | |
| T-15-06 | Tampering | over-selection beyond populate depth | mitigated | `lib/graphql/fragments/travel_preview_fragment.dart:11-17` (`food { quantity item { id name } }` only), `lib/graphql/queries/travel_queries.dart:19-24` reuses the fragment | final SDL proof is T-15-24 (deferred) |
| T-15-07 | Info disclosure | server message in the banner | mitigated | no `.message` in classifiers/repository (cross-check 2); `starvingPhrase` constant (`travel_cost_text.dart:7`) used by `travel_notice.dart:19` and `quest_acceptance_notice.dart:37` | classifiers read `extensions.code` only |
| T-15-08 | DoS | `previewQuest` hanging | mitigated | `travel_repository.dart:42-46,71-77` (`_guard`, 15 s, `TravelFailure.timedOut`); sheet hides the line on any failure | |
| T-15-09 | Tampering | swipe/«Parti» forced past the client gate | mitigated | `travel_failure.dart:70` and `quest_acceptance_failure.dart:73` map `TRAVEL_STARVING` to `starving` on both mutations; BE side transferred to BE D-11 | refusal always explained |
| T-15-10 | Tampering | «Parti» forced on a starving quote | mitigated | `travel_cubit.dart:99-117` requote from the BE (`TravelRequoting`), no food check in the cubit (`arrivesAlive` absent from `travelCubit/`, cross-check 3) | BE D-11 remains the defence |
| T-15-11 | DoS | late/superseded requote answers | mitigated | `travel_cubit.dart:42,53,102,110,140-142,176` (`_previewToken`, `_isStale` accepts Previewing/Requoting only) | |
| T-15-12 | DoS | banner spam on clock re-emit | mitigated | `lib/screens/mainScreen/components/travel_outcome_listener.dart:29-30` (`previous is! TravelRequoting && current is TravelRequoting`) | |
| T-15-13 | Tampering | «Parti» enabled on a starving trip | mitigated | `travel_confirmation_sheet.dart:192` (`state is TravelConfirming && state.preview.arrivesAlive`) | BE D-11 behind it |
| T-15-14 | DoS | long food list / phrase breaking layout | mitigated | `travel_confirmation_sheet.dart:46-47,107,112` (`_foodMaxLines = 3`, `_lifeMaxLines = 2`) | |
| T-15-15 | Tampering | client arithmetic in the sheet | mitigated | `travel_confirmation_sheet.dart:132` reads `arrivesAlive` only as flag; no `hpLost` in the widget (cross-check 3) | |
| T-15-16 | Tampering | client arithmetic in the line | mitigated | `lib/models/quest/quest_travel_line.dart:19-21` composes `foodText`/`lifeText`/`starvingPhrase`; `arrivesAlive` is the only starving signal | tests `test/models/quest/quest_travel_line_test.dart` |
| T-15-17 | Info disclosure | travel cost shown on a read-only sheet | mitigated | `quest_sheet_details.dart:118` (`QuestTravelLine.of(travelPreview)`, null preview gives null); tests `quest_sheet_details_test.dart:317`, `quest_info_sheet_test.dart:828` | overlay passes no preview |
| T-15-18 | EoP | preview for another character | mitigated | `board.dart:379` sends `widget.viewer.characterId` only; BE owner check (BE D-08) | |
| T-15-19 | DoS | request storms / late answers | mitigated | `board_policy.dart:49` (`needsTravelPreview`); `quest_travel_preview_cubit.dart:24,38,45-47` (`_requestToken`); cubit scoped to the keyed sheet subtree (`board.dart:280`) | |
| T-15-20 | Tampering | swipe forced on a starving quote | mitigated | `board.dart:315-317` (`canTear: ... && travelPreview?.arrivesAlive != false`); refusal recomposed and refreshed (`board.dart:285-291`) | no `isEnabled: false` use |
| T-15-21 | Repudiation | preview failure hiding a problem | accepted | 15-07 plan, CONTEXT D-04 | failed preview shows nothing; BE refusal + banner cover it |
| T-15-22 | Tampering | BE working tree during the gate | deferred | mitigation lives in 15-08 (read-only `fetch/show/log/ls-tree`) | verified when the gate runs |
| T-15-23 | Info disclosure | `.env` during the gate | deferred | 15-08 | |
| T-15-24 | DoS | documents ahead of the BE | deferred | 15-08 (45/45 on the merged SDL); registry already 45 (cross-check 5) | |
| T-15-25 | Tampering | arithmetic / stale swipe gate sanity greps | deferred | 15-08 Task 2; interim result in cross-checks 3 and 7 is clean | re-run at the gate |
| T-15-26 | Info disclosure | `15-HUMAN-UAT.md`, `BACKEND-NOTES.md` | deferred | 15-09 (grep `mongodb://`, `token=`, `password` = 0) | |
| T-15-27 | Repudiation | requirement traceability | deferred | 15-09 | |
| T-15-28 | Tampering | BE repo | deferred | 15-09 (read-only refs) | |
| T-15-29 | Tampering | DB seeds for the UAT | accepted | 15-09 plan (accept): dev DB, orchestrator seeds, outside the repo | |

## Cross-cutting checks

All run from the repo root, read-only.

1. `grep -rn "print(" lib/models/travel lib/models/quest lib/screens/mainScreen/travelCubit lib/screens/mainScreen/tabs/board lib/screens/mainScreen/tabs/map/components lib/repository/travel_repository.dart lib/repository/travel_failure.dart lib/repository/quest_acceptance_failure.dart` -> no output (none).
2. `grep -rn "\.message" lib/repository/travel_failure.dart lib/repository/quest_acceptance_failure.dart lib/repository/travel_repository.dart` -> no output: classifiers read `extensions.code` only.
3. `grep -rnE "hpLost|arrivesAlive" lib --include='*.dart'` outside models/graphql -> `board.dart:317` (`!= false` gate), `travel_confirmation_sheet.dart:132,192` (flag read). Inside models: `travel_cost_text.dart:29-31` (print `−${hpLost} HP`, `<= 0` text selector), `quest_travel_line.dart:19` (flag read). No arithmetic on `hpLost`, no own derivation of `arrivesAlive`; nothing in `travelCubit/`. Judged clean.
4. `grep -rn "food {" lib/graphql` -> one hit, `travel_preview_fragment.dart:11` (`food { quantity item { id name } }`); `grep -rn "questTravelPreview" lib/graphql` -> one hit, `travel_queries.dart:21`, document `GetQuestTravelPreview($request: AcceptQuestRequest!)`.
5. `grep -c "'" tool/schema_check/schema_check_documents.dart` -> 70 (quote characters, indicative); `test/tool/schema_check_documents_test.dart:32-33` -> «the registry lists 45 documents (D-12)», `expect(schemaCheckDocuments.length, 45)`.
6. `grep -rn "TRAVEL_STARVING" lib` -> one constant, `travel_failure.dart:12` (`travelStarvingCode`); used by `travel_failure.dart:70` and `quest_acceptance_failure.dart:6,73`.
7. `grep -rn "canTear: false\|isEnabled: false" lib/screens/mainScreen/tabs/board` -> no output; the starving swipe uses `canTear` at `board.dart:315-317`, `isEnabled` stays bound to `isIdle`.
8. `git log 08bd1a1..HEAD --format=%B | grep -ciE "co-authored-by|generated with"` -> 0.
9. `grep -rn "\.env\|google-services" lib` -> only pre-existing hits (main.dart, auth services, env_config); `git diff 08bd1a1..HEAD -- lib | grep -E "^\+" | grep -c "\.env\|google-services"` -> 0 (none new); `git diff 08bd1a1..HEAD -- pubspec.yaml` -> empty (no new dependency).

## Open

None.

## Deferred

- T-15-22..T-15-25: plan 15-08 (schema gate vs merged BE Phase 14 SDL, 45/45, sanity greps), gated on the BE merge.
- T-15-26..T-15-28: plan 15-09 (device E2E, UAT/handoff secret-free, traceability, BE read-only), gated on 15-08.

## Accepted risks

T-15-02 (default `arrivesAlive: true`, BE refuses), T-15-21 (silent preview failure, D-04), T-15-29 (dev DB seeds for the UAT).

## Unregistered flags

None (plans 15-01..15-07 SUMMARYs carry no unmapped threat flag beyond the register).
