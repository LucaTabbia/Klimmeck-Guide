---
phase: 21-innkeeper-mission-completion-flow
audited: 2026-11-14
scope: plans 21-01..21-15 plus review fixes (diff 5e1d77e2..HEAD of lib, test, tool); 21-16..21-18 not executed
asvs_level: 1
threats_total_in_scope: 55
status: secured_with_partials
---

# Phase 21 Security Audit

Method: each threat of the 21-01..21-15 `<threat_model>` blocks was checked against the committed code (file:line) and against a test (file plus title). Implementation files were not touched. No `.env`, Firebase file, `key.properties` or environment variable was read.

## Cross-cutting checks requested

| Check | Result | Evidence |
|-------|--------|----------|
| Innkeeper-only operations only through the innkeeper repository and Locanda route | OK | Mission/teleport documents are called only from `lib/repository/innkeeper_repository.dart` and `lib/repository/services/graphql/graphql.dart`; consumers are the wizard cubits (`missionCompletion/*`), `TeleportModeCubit`, `request_completion_cubit`, `quest_generation_cubit`. `openMissionCompletion` (`mission_completion_route.dart:15`) has no caller in `lib` (only its test): the wizard is unreachable until 21-16. BE `@Roles(innkeeper)` stays the authority. |
| No draft / simulation / prize / result payload in logs | OK | `git diff` of `lib` adds zero `appLog`, `print`, `debugPrint`; two `appLog('JournalCubit error: ...')` removed (`journal_cubit.dart`). `tool/hardening_check.sh` (unchanged) fails on any `print`/`debugPrint` outside `app_log.dart` and on credential interpolation in log calls. |
| Lock and bounds from served fields only | OK | `character_status.dart:92-93` (`== true`), `character.dart:25` (`isOnMission`), `quest_viewer.dart:30`, `character_marker_layer.dart` label bound to `guidedMissionInProgress`; bounds, verdicts and `isSimulated` read from the served draft; `mission_limits.dart` holds only the UI caps the BE also enforces. |
| Gated fields not selected before the gate | OK | `grep missionInProgress\|guidedMissionInProgress\|missionDraftStartedAt lib/graphql` is empty. Mission documents exist (`mission_queries.dart`, `mission_mutations.dart`, `mission_draft_fragment.dart`) but are reachable only from the unwired wizard. |
| Lenient parsing | OK | `utcInstantOrNull` (`utc_instant.dart`), `MissionDraft.tryFromJson`, per-entry `whereType` (`graphql.dart:239`), `FormatException` -> `InnkeeperFailure.malformed` (`innkeeper_repository.dart`), `poiTypesFrom` drops only the unknown name. |
| Refusals never swallowed | OK | `MISSION_IN_PROGRESS` is absent from the three `_staleViewFailures` sets (`spell_/companion_/potion_outcome_listener.dart`); equip now emits `JournalEquipRefused`; wizard failures reach a SnackBar or an exit (`mission_completion_screen.dart:221-223`). |
| Players' travel drop rule unchanged | OK | `pawn_dragging.dart` default `resolvePawnDrop` is the former body verbatim; only `TeleportPawnLayer` overrides it; `character_marker_layer.dart` change is limited to the served-flag travel precheck and the guided label. |
| No secret / token / id in UI error copy | OK | All failure copy is constants (`mission_lines.dart`, `equipment_notice.dart`, `MissionCompletionScreen.failureLineOf`); classifiers read `extensions.code` only; no `toString()`/`.message`/`runtimeType` of an error reaches a widget in the new code. |
| No new dependency | OK | `git diff 5e1d77e2..HEAD -- pubspec.yaml pubspec.lock` is empty. |

## Threat table (plans 01-15)

Verdicts: MITIGATED, PARTIAL (code present, automated test evidence incomplete), MISSING, ACCEPTED.

| Threat | Plan | Mitigation | Evidence code | Evidence test | Verdict |
|--------|------|------------|---------------|---------------|---------|
| T-21-01 | 01 | gated flags modelled only, never selected | `lib/graphql` has no occurrence; `character_status.dart:92` | `mission_documents_test.dart` «no mission document selects missionInProgress» (covers mission documents only; no test pins the character / pending-request fragments) | PARTIAL |
| T-21-02 | 01 | `== true` lenient read | `character_status.dart:92-93` | `character_status_test.dart` «absent or malformed flags read false (D-16)» | MITIGATED |
| T-21-03 | 01 | failure is a banner, not stale-view | `mission_in_progress.dart`, `*_failure.dart` mapping | `*_notice_test.dart` (transaction, travel, quest acceptance, spell, companion, potion, equipment) | MITIGATED |
| T-21-04 | 01 | accept: BE guard authoritative | flags only read | n/a | ACCEPTED |
| T-21-05 | 02 | value outside the stale-view sets | `spell_outcome_listener.dart:19`, `companion_outcome_listener.dart:19`, `potion_outcome_listener.dart:21` | `transaction_notice_test.dart`, `spell_notice_test.dart`, `companion_notice_test.dart` | MITIGATED |
| T-21-06 | 02 | only `extensions.code`, shared copy | `equipment_failure.dart:35-50`, `missionInProgressRefusalLine` | `*_failure_test.dart` (shop, spell, pet, travel, quest, item), `mission_lines_test.dart` | MITIGATED |
| T-21-07 | 02 | accept: BE refuses | n/a | n/a | ACCEPTED |
| T-21-08 | 03 | `JournalEquipRefused` + notice | `journal_cubit.dart` (`equipItem`), `equipment_notice.dart` | `journal_cubit_test.dart` «a refusal emits JournalEquipRefused with the failure (LB-1)», `equipment_notice_test.dart`, `journal_equip_refusal_test.dart` | MITIGATED |
| T-21-09 | 03 | no raw message / log in equip | `appLog` and `e.toString()` removed from `journal_cubit.dart`; `equipment_repository.dart` | `equipment_failure_test.dart`, `equipment_repository_test.dart` | MITIGATED |
| T-21-10 | 03 | every `Object` -> `unknown` | `equipment_repository.dart` `_guard` (`on Object`) | `equipment_repository_test.dart:106` «any other error becomes unknown» | MITIGATED |
| T-21-11 | 04 | `QuestViewer.of` reads the served flag | `quest_viewer.dart:30`, `quest_availability.dart:138` | `quest_availability_test.dart:796` «QuestViewer.of reads the served flag, never the lanes (D-16)» | MITIGATED |
| T-21-12 | 04 | label bound to `guidedMissionInProgress` | `character_marker_layer.dart` (missionLabelKey block) | `character_marker_layer_test.dart:350` «a normal mission shows no pawn label (D-16)» | MITIGATED |
| T-21-13 | 04 | in-world label, no dialog/spinner | `PawnLabel` marker, no overlay | same file (label tests) | MITIGATED |
| T-21-14 | 04 | accept: `_isPageDisabled` + BE | `main_screen.dart:279-290` | `satchel_availability_test.dart` | ACCEPTED |
| T-21-15 | 05 | UI gates on served flag + `_equipItem` guard | `journal.dart:168,207,255,343` | `journal_mission_lock_test.dart:108` `verifyNever(repository.equip)`, `items_section_test.dart`, `spells_section_test.dart`, `companion_section_test.dart` | MITIGATED |
| T-21-16 | 05 | potion refusal visible | `potion_outcome_listener.dart:21` (set excludes the code) | `potion_notice_test.dart`, `item_use_failure_test.dart` | MITIGATED |
| T-21-17 | 05 | plain line, no dialog | `mission_locked_section.dart`, `ItemRow.statusLine` | `journal_mission_lock_test.dart`, `spells_section_test.dart` | MITIGATED |
| T-21-18 | 06 | drop only the unknown POI type | `poiTypesFrom`, `demonicPortal` | `poi_type_test.dart:18,25` | MITIGATED |
| T-21-19 | 06 | accept: world data | n/a | n/a | ACCEPTED |
| T-21-20 | 06 | schema-check registry | `schema_check_documents.dart` (+10 documents) | `schema_check_documents_test.dart:32` «the registry lists 55 documents», `mission_documents_test.dart:95` «$name is named and registered» | MITIGATED |
| T-21-21 | 07 | teleport only via `TeleportModeCubit` from the Locanda | `teleport_mode_cubit.dart:135` (FORBIDDEN leaves mode), `InnkeeperRepository.teleport` | `teleport_mode_cubit_test.dart:424` (forbidden), `innkeeper_repository_test.dart:88` | MITIGATED |
| T-21-22 | 07 | per-entry parse, `places: []` fallback | `graphql.dart:236-239`, `teleport_mode_cubit.dart:73` | `graphql_points_of_interest_test.dart:56` «a malformed place is dropped…», `teleport_mode_cubit_test.dart:145` «a failed places read leaves the city teleport working (D-29)» | MITIGATED |
| T-21-23 | 07 | travel drop rule untouched | `pawn_dragging.dart:42-50`, `character_marker_layer.dart` | `world_map_travel_test.dart` (minimal diff), `character_marker_layer_test.dart` | MITIGATED |
| T-21-24 | 08 | default `resolvePawnDrop` = player rule | `pawn_dragging.dart:48-51`, override only in `teleport_pawn_layer.dart` | `teleport_pawn_layer_test.dart`, `teleport_drop_test.dart` «below the city zoom a drop near a hidden place resolves to the city (D-29)» | MITIGATED |
| T-21-25 | 08 | POI layer only in teleport mode | `world_map.dart:257,300-304` | `world_map_teleport_test.dart:265` (present in teleport), `:307` (absent otherwise) | MITIGATED |
| T-21-26 | 08 | passive dot, no gesture | `teleport_poi_layer.dart` has no `GestureDetector`/`onTap` | `teleport_poi_layer_test.dart` | MITIGATED |
| T-21-27 | 09 | `missionDraftStartedAt` modelled, not selected | `lib/graphql` has no occurrence; `pending_request.dart:126` | no test pins `pending_request_fragment.dart` (acceptance grep only) | PARTIAL |
| T-21-28 | 09 | card rebuilt from fresh snapshot | `innkeeper_panel_screen.dart` (`requestCardsOf(state.requests)`) | `innkeeper_panel_screen_test.dart` resume group | MITIGATED |
| T-21-29 | 09 | one-shot open, gone message | `innkeeper_panel_screen.dart` `listenWhen` | `innkeeper_panel_screen_test.dart:659` «opens it only once across later snapshots (D-28)», `:699` «a card gone from the queue shows…» | MITIGATED |
| T-21-30 | 09 | lenient `tryParse` | `utc_instant.dart` | `pending_request_test.dart:146` «absent or malformed missionDraftStartedAt is null and the entry…» | MITIGATED |
| T-21-31 | 10 | per-entry `tryFromJson`, `asNameMap` | `mission_draft.dart:32-43,107-117` | `mission_draft_test.dart:75,127`, `mission_prize_test.dart:63,173`, `mission_fight_test.dart` | MITIGATED |
| T-21-32 | 10 | accept: BE revalidates; client clamps | `mission_limits.dart` (1..99, 7 digits) | prizes step test «coins and xp take digits only, at most 7» | ACCEPTED |
| T-21-33 | 10 | served fields only | `mission_draft.dart` (`allFightsSimulated`, verdicts); `mission_draft_inputs.dart` | `mission_draft_inputs_test.dart` (B-01/B-02 payload tests) | MITIGATED |
| T-21-34 | 10 | models have no logging | no log call in `lib/models/mission`, `mission_draft_inputs.dart` | `hardening_check.sh` guards print/debugPrint and credentials only, not appLog payload content | PARTIAL |
| T-21-35 | 11 | operations only in `InnkeeperRepository`; FORBIDDEN -> forbidden | `innkeeper_repository.dart` `_guard` | `innkeeper_repository_test.dart:88,149`, `mission_completion_screen_test.dart:393` | MITIGATED |
| T-21-36 | 11 | no `appLog` in new code | zero added log calls in the diff | none dedicated (see T-21-34) | PARTIAL |
| T-21-37 | 11 | gated documents unreachable before the gate | `openMissionCompletion` has no production caller; `grep` of the gated fields empty | `mission_documents_test.dart:189`; no test pins the panel as not opening the wizard | MITIGATED |
| T-21-38 | 11 | `FormatException` -> `malformed`, null draft -> start | `innkeeper_repository.dart` `_guard` | `innkeeper_repository_test.dart:97,279,325,367`, `graphql_mission_test.dart:61,67,90` | MITIGATED |
| T-21-39 | 12 | served data replaces state | cubits assign served drafts | `mission_draft_cubit_test.dart:396` «the served draft replaces the state, nothing is merged locally (D-09)», `mission_enemies_cubit_test.dart`, `mission_prize_options_cubit_test.dart` | MITIGATED |
| T-21-40 | 12 | `isSubmitting` guard | `mission_draft_cubit.dart:163-164` | `mission_draft_cubit_test.dart:412` «a second action while submitting is ignored» | MITIGATED |
| T-21-41 | 12 | failure + serial in state | `mission_draft_state.dart`, `mission_completion_screen.dart:221-223` | `mission_draft_cubit_test.dart:460` «a refused save keeps the old draft with the failure and a new serial…» | MITIGATED |
| T-21-42 | 12 | no `appLog` | zero added log calls | none dedicated (see T-21-34) | PARTIAL |
| T-21-43 | 13 | wizard only from the panel; FORBIDDEN closes | `mission_completion_route.dart`, `mission_completion_screen.dart:231-235` | `mission_completion_screen_test.dart:393,432` | MITIGATED |
| T-21-44 | 13 | no draft on open, explicit start | `start_step.dart`, `MissionDraftAbsent` | `mission_completion_screen_test.dart` start group, `mission_completion_route_test.dart:28` (loads draft only, no start) | MITIGATED |
| T-21-45 | 13 | raw-queue listener + NOT_FOUND | `mission_completion_screen.dart:102,231` | `mission_completion_screen_test.dart:409,439` | MITIGATED |
| T-21-46 | 13 | `_runThenOpen` same serial + SnackBar | `mission_completion_screen.dart:223,245` | `mission_completion_screen_test.dart` (refusal group, B-09 test) | MITIGATED |
| T-21-47 | 14 | bounds/verdict from draft | `fight_step.dart` | `fight_step_test.dart`, `mission_completion_screen_test.dart` | MITIGATED |
| T-21-48 | 14 | locked injury chips; BE refuses | `injury_chips` component | `injury_chips_test.dart` | MITIGATED |
| T-21-49 | 14 | Simula disabled until k-1 served | `fight_step.dart` | `fight_step_test.dart` | MITIGATED |
| T-21-50 | 14 | lazy list | `enemy_picker.dart:66` `ListView.builder` | `enemy_picker_test.dart:96` «only the visible enemies are listed (D-03)» | MITIGATED |
| T-21-65 | 14 | UI caps | `mission_limits.dart:2-5` | encounters step tests (10 fights, 10 entries, quantity 20) | MITIGATED |
| T-21-51 | 15 | catalogue-only prizes, 1..99, digits | `prize_catalogue_sheet.dart`, `mission_limits.dart:8-9,16` | `prize_catalogue_sheet_test.dart`, `prizes_step_test.dart` (7-digit test) | MITIGATED |
| T-21-52 | 15 | no local filtering by rank/rarity/xp | served `blockCure`, catalogue as served | `mission_prize_options_cubit_test.dart`, `mission_prize_test.dart` | MITIGATED |
| T-21-53 | 15 | explicit confirmation with recap | `recap_step.dart` | `recap_step_test.dart` | MITIGATED |
| T-21-54 | 15 | no `appLog` | zero added log calls | none dedicated (see T-21-34) | PARTIAL |

Counts (55 threats, T-21-01..54 plus T-21-65): MITIGATED 44, ACCEPTED 5 (T-21-04, 07, 14, 19, 32), PARTIAL 6 (T-21-01, 27, 34, 36, 42, 54), MISSING 0.

## Unregistered flags

| Flag | Observation | Severity |
|------|-------------|----------|
| UF-21-01 | `InnkeeperRepository` and `TeleportModeCubit` are provided to every authenticated session in `authenticated_shell.dart:248-252`, not only to innkeepers. Reachability is gated by the Locanda entry plus BE `@Roles(innkeeper)`; pre-existing from Phase 10, now carrying more operations. Informational. | info |
| UF-21-02 | No automated test asserts that the character and pending-request fragments stay free of `missionInProgress`, `guidedMissionInProgress` and `missionDraftStartedAt`; only a plan-time grep did. A later edit before the 21-16 gate could silently break the character parse against today's BE. | low |
| UF-21-03 | No automated test asserts that `InnkeeperPanelScreen` does not yet open the wizard (gated documents unreachable). Today true by absence of a caller. | low |
| UF-21-04 | `character_marker_layer.dart` `_canStartTravel` now also blocks on `isOnMission` for players: a client pre-check only (BE stays judge, D-14), the drop rule is unchanged. Informational. | info |
| UF-21-05 | `JournalEquipRefused` for `unknown`/`timedOut` shows the generic banner only: acceptable disclosure-wise, but no silent re-read, so a timed-out equip that the server applied is reconciled only by `characterUpdated`. Informational. | info |

## Threats pending the gate (21-16..21-18, not executed)

T-21-55, T-21-56, T-21-57, T-21-66 (plan 21-16); T-21-58, T-21-59, T-21-67, T-21-68 (plan 21-17); T-21-60, T-21-61, T-21-62, T-21-63, T-21-64 (plan 21-18, T-21-64 accepted). All pending the gate: not auditable until the schema gate, the wiring of the wizard from the panel (T-21-66 and T-21-43 reachability) and the deletion of the Phase 10 override form (T-21-59) exist. Re-audit after those plans.

## Overall verdict

No MISSING mitigation, no exploitable gap found in the code that exists. Counts for plans 01-15 (55 threats): MITIGATED 44, ACCEPTED 5, PARTIAL 6 (T-21-01, T-21-27, T-21-34, T-21-36, T-21-42, T-21-54), MISSING 0. The PARTIALs are test-evidence gaps (no automated pin on gated-field absence in the character/pending fragments; no automated pin that new code does not log payloads, beyond the pre-existing `hardening_check.sh` which covers print/debugPrint and credentials), not code gaps.

Status: `secured_with_partials` for the executed scope; 13 threats open pending the gate (21-16..21-18).
