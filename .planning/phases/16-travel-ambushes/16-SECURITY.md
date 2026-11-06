---
phase: 16
slug: travel-ambushes
audited: 2026-11-06T18:57:00Z
status: secured
asvs_level: 1
block_on: high
threats_total: 24
threats_mitigated: 11
threats_accepted: 6
threats_transferred: 0
threats_open: 0
threats_open_blocking: 0
threats_deferred: 7
open_ids: []
deferred_ids: [T-16-17, T-16-18, T-16-19, T-16-20, T-16-21, T-16-22, T-16-23]
updated: 2026-11-06
---

# Phase 16 - Security (Travel Ambushes, FE)

Audit of the threat registers of plans 16-01..16-08 (24 rows, T-16-01..T-16-24) against HEAD `dffd883` of `feat/16-travel-ambushes` (base `develop` `f560d1d`, review fixes of `16-REVIEW-FIX.md` included). Plans 16-07 (schema gate vs merged BE Phase 15 SDL) and 16-08 (device E2E, handoff, traceability) are gated on the BE merge: their process threats are DEFERRED, not open. BE-side behaviour is NOT a FE threat row here and is owned by the BE (BE 15-CONTEXT: D-01..D-03 draw and probability, D-06..D-08 enemies, D-09/D-10 resolution and rewards, D-11/D-12 defeat, detour and push composition, D-13 reports held until arrival/teleport, D-14 SDL, D-18 fail-open); the BE repo was not read or touched. No command read `.env`, `google-services.json` or environment variables. Implementation files read only.

Dispositions: mitigated / accepted / transferred / deferred / open.

## Threat Register

| ID | STRIDE | Component | Disposition | Evidence | Note |
|----|--------|-----------|-------------|----------|------|
| T-16-01 | DoS | `QuestResult.fromJson` / `AmbushReport.fromJson` | mitigated | `lib/models/quest_result/quest_result.dart:154` (`tryFromJson` boundary); tests `quest_result_test.dart:419` «drops an ambush without its report», `:430` «drops a quest result without its quest», `:354`, `ambush_report_test.dart:54` «throws on a malformed reached city» | one bad report never empties the queue |
| T-16-02 | Tampering | unknown `kind` | mitigated | `lib/models/quest_result/quest_result_kind.dart:9` (`fromWire`), `quest_result.dart:108` uses it; tests `quest_result_kind_test.dart:10`, `quest_result_test.dart:381` | missing/unknown reads as `quest` (older BE safe); post-review fix: an ambush ignores a malformed quest block (`quest_result_test.dart:400`) |
| T-16-03 | DoS | FE documents ahead of the BE | accepted | 16-01 plan (accept, D-09/D-15) | proof is the 16-07 gate (T-16-19) |
| T-16-04 | Spoofing | `ambushDefeat` push `id` | mitigated | `lib/models/push_event.dart:39` (`validBackendIdentifier` for personal categories; file unchanged vs `f560d1d`); `notification_popup_registry.dart:20` maps to `focusCharacterOnMap`; test `notification_popup_registry_test` «an ambushDefeat tap only latches the camera focus on the pawn» | no state read from the payload |
| T-16-05 | Tampering | push title/body rendering | accepted | 16-02 plan (accept) | plain `Text`; router opens only `TwitchChannel.uri` |
| T-16-06 | Repudiation | toggle gating the wrong surface | mitigated | `data_message_handler.dart:9` (`acceptPushEvent` is the only filter); tests «the ambush toggle off never hides the carousel (D-10)» (main_screen_quest_results_test) and the 16-02 toggle tests | presenter and carousel have no `ambushDefeat`/preference read of their own (check 6) |
| T-16-07 | Tampering | client deciding rewards on a loss | mitigated | `lib/shared/components/popup/quest_result_sheet.dart:177,221,278` only prints `_result.outcome`/BE values; no reward arithmetic | rule 4 |
| T-16-08 | Tampering | city names in `Text` | accepted | 16-03 plan (accept); `quest_result_sheet.dart:197` plain `Text('Imboscata presso ${ambush.nearCity.name}')` | no links, no markup |
| T-16-09 | Tampering | double ack / reopened page | mitigated | `quest_results_cubit.dart:367` `_isKnown`, used at `:122,:252,:354`; `_acknowledgedIds` `:66`; test `quest_results_queue_test.dart:114` | BE ack idempotent (9.2 D-03) |
| T-16-10 | Repudiation | report acknowledged without being shown | mitigated | acks only from the `closed` path (`quest_results_cubit.dart:189-222`); tests `main_screen_quest_results_test` «an external pop requeues without acknowledging» (:388) and «an external pop requeues the whole carousel unacknowledged» (:547) | |
| T-16-11 | DoS | settling read retried in silence | accepted | 16-04 plan (accept) | read gives up into `failed`; no spinner |
| T-16-12 | Repudiation | reports acked from page 1 | accepted | 16-05 plan, user decision D-05 (veto 2026-11-06) | counter «1 di N» shows more pages; check 5 confirms no programmatic paging |
| T-16-13 | DoS | carousel blocking the session | mitigated | `quest_result_presenter.dart:154` (waits `isSettlingAmbushes`), `:188-196` (`showGeneralDialog`, `PopScope`, same gates as Phase 9); test «a live ambush waits for the settling read and opens with its…» (:473) | no spinner |
| T-16-14 | Tampering | wrong banner for an ambush arrival | mitigated | `quest_result_presenter.dart:118` `if (arrival.isAmbush) return;` before `questEndEventOf` (:119); test «an ambush arrival publishes no quest-end banner off the map» (:498) | |
| T-16-15 | Tampering | client-side reroute guessing | mitigated | `git diff f560d1d..HEAD --name-only` shows no file under map/travel/repository in `lib` | pawn follows BE travel only |
| T-16-16 | Info disclosure | ambush revealed before departure | mitigated | `grep "Imbosc" lib` hits only `quest_result_sheet.dart:197` (post-arrival sheet); pin tests in `travel_confirmation_sheet_test.dart` and `quest_travel_line_test.dart` | |
| T-16-17 | Tampering | BE working tree during the gate | deferred | 16-07 plan | gate not run yet |
| T-16-18 | Info disclosure | `.env` during the gate | deferred | 16-07 plan | |
| T-16-19 | DoS | documents ahead of the BE | deferred | 16-07 plan (45/45 on merged SDL) | registry unchanged at 45 meanwhile (check 4) |
| T-16-20 | Tampering | FE copy / second reroute / gated carousel | deferred | 16-07 plan sanity greps | the same greps pass now at HEAD (checks 2, 5, 6) |
| T-16-21 | Info disclosure | `16-HUMAN-UAT.md`, `BACKEND-NOTES.md` | deferred | 16-08 plan | files not yet written |
| T-16-22 | Repudiation | requirement traceability | deferred | 16-08 plan | |
| T-16-23 | Tampering | BE repo | deferred | 16-08 plan | |
| T-16-24 | Tampering | DB seeds for the UAT | accepted | 16-08 plan (accept) | dev DB, seeded outside the repo |

## Cross-cutting checks (run at HEAD `dffd883`)

1. `grep -rn "print(" <ambush/result files>` -> no output (rc 1). PASS.
2. `grep -rn "Sei stato sconfitto\|Imboscata!" lib` -> no output; `git diff f560d1d..HEAD --stat -- lib/models/push_event.dart` -> empty. PASS (FE never composes the defeat notice, D-10).
3. `grep -rn "ambush {" lib/graphql` -> one hit `quest_result_fragment.dart:101`, selection `at`, `nearCity {id name}`, `reachedCity {id name}`; `grep kind` -> single field `quest_result_fragment.dart:18`; `git diff --name-only -- lib/graphql` -> only `lib/graphql/fragments/quest_result_fragment.dart`. PASS.
4. `grep 45 test/tool/schema_check_documents_test.dart` -> `:32-33` «the registry lists 45 documents (D-12)», `length, 45`; `git diff --name-only -- tool` -> empty. PASS.
5. `grep "animateToPage\|nextPage\|PageController" ambush_report_carousel.dart` -> 0 (rc 1). PASS (D-05 veto).
6. `grep "ambushDefeat\|NotificationPreferences"` on presenter and carousel -> only `quest_result_presenter.dart:130` `NotificationPreferencesCubit` (questEnd banner), present also at `f560d1d` line 126; nothing in the carousel. PASS.
7. `grep -rn "quest!\." lib` -> 5 hits, all in `lib/shared/components/popup/quest_info_sheet.dart` (a different, pre-existing nullable `Quest`; file not in the phase diff); zero on the `QuestResult.quest` block. PASS.
8. `fromWire` at `quest_result_kind.dart:9`; tests `quest_result_kind_test.dart:10` and `quest_result_test.dart:381`: unknown/missing -> `quest`. PASS.
9. `git log f560d1d..HEAD --format=%B | grep -ciE "co-authored-by|generated with|claude-session"` -> 0. PASS.
10. `grep -rn "\.env\|google-services" lib` -> only pre-existing hits (`main.dart`, `config/env_config.dart`, auth services); `git diff f560d1d..HEAD` added-lines filter for `.env|google-services|quest!.` -> none; `git diff f560d1d..HEAD --stat -- pubspec.yaml` -> empty. PASS.

## Unregistered flags

SUMMARY.md `## Threat Flags` of 16-01..16-06 were not found to add attack surface beyond the register; none logged.

## Open

None.

## Deferred

- T-16-17..T-16-20: plan 16-07 (schema gate on merged BE Phase 15 SDL: read-only BE refs, no `.env`, 45/45 documents, sanity greps).
- T-16-21..T-16-23: plan 16-08 (device E2E, handoff secret-free, traceability only for steps that passed, BE untouched).
