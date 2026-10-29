---
phase: 09
slug: combat-result-sheet
audited: 2026-10-28
status: secured
asvs_level: 1
block_on: high
threats_total: 51
threats_mitigated: 37
threats_accepted: 3
threats_transferred: 1
threats_open: 0
threats_open_blocking: 0
threats_deferred: 10
open_ids: []
deferred_ids: [T-9-42, T-9-43, T-9-44, T-9-45, T-9-46, T-9-47, T-9-48, T-9-49, T-9-50, T-9-51]
updated: 2026-10-28
---

# Phase 09 - Security (Combat Result Sheet, FE)

Audit of the `<threat_model>` blocks of plans 09-01..09-13 (51 rows) against HEAD `9cde871` of `feat/09-combat-result-sheet` (base `origin/develop` `6d8f4b9`, review fixes WR-01..WR-04 and IN-01..IN-05 of `09-REVIEW-FIX.md` included). Evidence is the final code. Plans 09-12 (BE 9.2 documents, `acknowledgeQuestResult`, `unacknowledgedQuestResults`, `acknowledgedAt`) and 09-13 (schema check, device E2E, requirements closure) are deliberately not executed: they are gated by the merge of the BE 9.2 PR (CONTEXT D-21). Their ten threats (T-9-42..T-9-51) are DEFERRED and are not counted as open.

Runs of this audit: `flutter test` over the 47 test files added or changed by the phase (`git diff --name-only --diff-filter=AM origin/develop..HEAD -- test`, `*_test.dart`) = 641 passed, 0 failed (foreground). The full suite (2452 passed, 0 failed) and `flutter analyze` (52 issues, 0 errors, unchanged baseline) are taken from `09-REVIEW-FIX.md` and were not re-run. `.env` is untracked (`git ls-files` lists only `.env.example`); no command of this audit read it or `Platform.environment`. BE repo not touched. Implementation files were read only.

Disposition: M = mitigate (verified in code + test), A = accept (logged below), T = transfer (BE, documented below).

## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| BE `questResultReceived` / `questResult(id)` -> `QuestResult` | Server data parsed on the device. `QuestResult.tryFromJson` (`quest_result.dart:119-126`) is the boundary: null on any malformed payload, never an exception. Unknown outcome, malformed scalars and a missing required object fail the whole result; unknown injury, title and quest type, orphan items and a missing `acknowledgedAt` are tolerated per entry. |
| BE `characterUpdated` / `character` -> `CharacterStatus.awaitingAid` | Absent, null or malformed value parses to null through `AwaitingAid.tryFromJson` (`awaiting_aid.dart:23-30`); the rest of the status survives (`character_status.dart:73`). |
| push `data.id` / banner tap -> `QuestResultsCubit.requestFromTap` | Only the id crosses, filtered by `validBackendIdentifier` (`quest_results_cubit.dart:103`, `backend_identifier.dart:1-6`); the result is always read back through `questResult(id)`, nothing is rebuilt from the payload. |
| BE error answers -> domain failure -> banner | Classified by `extensions.code` only (`quest_result_failure.dart:28-39`, `transaction_failure.dart:33-52`, `travel_failure.dart:61-64`, `quest_acceptance_failure.dart:68`), `unknown` default; banners carry fixed Italian copy. |
| WS socket / subscription -> session | Terminal access-denied stops the stream for good (`quest_results_cubit.dart:270-277`); transient errors resubscribe with exponential backoff capped by `WsReconnectPolicy.maxReconnectDelay` (60 s, `ws_reconnect_policy.dart:31`); `FormatException` is skipped. |
| acknowledgement -> BE state | Serialised chain with a 15 s timeout per call (`quest_results_cubit.dart:318-324`); the death ack is awaited before the route pops (`quest_result_presenter.dart:214-254`). The real port is the gated 09-12; until then `NoQuestResultAcknowledger` (`authenticated_shell.dart`) is a no-op. |
| queue state -> root Navigator | Results become dialog routes above the app: non-dismissible barrier, `PopScope(canPop: false)`, button-only close (`quest_result_presenter.dart:176-192`). |
| widget lifecycle -> shell-wide availability flags | `MapAvailabilityCubit` is written by `MainScreen`, `QuestResultPresenter` and `WorldMap`; every writer resets on dispose. |
| session lifetime -> cubit lifetime | `QuestResultsCubit` and `MapAvailabilityCubit` are provided by the keyed `AuthenticatedShell` and closed with it (`authenticated_shell.dart`). |
| FE documents <-> BE 9.2 schema | NOT audited here: DEFERRED to 09-12/09-13 (gate on BE 9.2). `lib/graphql/` has no `acknowledg*`/`unacknowledged*` selection (grep = 0). |

## Threat Verification

| Threat | Cat. | Component | Disp | Status | Evidence (file:line) | Test |
|--------|------|-----------|------|--------|----------------------|------|
| T-9-01 | DoS | `QuestResult.fromJson` | M | CLOSED | `quest_result.dart:119-126` `tryFromJson` (non-map -> null, `on Object` -> null); `:139-144` unknown injury skipped; `:108-109` unknown title -> null; `:129-137` orphan items dropped; `quest_result_quest.dart:21` unknown type -> null; `graphql.dart:188-195` null -> `FormatException` | `quest_result_test.dart:137` group `tolerance`, `:219` group `tryFromJson` |
| T-9-02 | DoS | enemy parsing | M | CLOSED | `quest_result.dart:151-158` forwards only `id/name/imagePath` to `Enemy.fromJson`; `grep locations lib/graphql` = comment only (`quest_result_fragment.dart:7`) | `quest_result_test.dart:208` "an enemy with locations never reaches Enemy.fromJson"; `quest_result_documents_test.dart:58` "never selects enemy locations nor acknowledgedAt" |
| T-9-03 | Tampering | equipment rewards | M | CLOSED | `quest_result_fragment.dart:29-33,55-59` ItemUnion branches select the equipment/loot details (`equipType` via `equipment_fragment.dart:14,35`) | `quest_result_test.dart:37` `isEquipment` true; `quest_result_documents_test.dart:32` "selects equipType on equipment and the loot details" |
| T-9-04 | Info disc. | `questEndEventOf` | A | CLOSED | Accepted, see log. `quest_end_event.dart:7-18` fixed copy, id = result id, no payload content | `quest_end_event_test.dart:13` |
| T-9-05 | DoS | `CharacterStatus.fromJson` | M | CLOSED | `awaiting_aid.dart:23-30` `tryFromJson`; `character_status.dart:73` | `awaiting_aid_test.dart:32` group `tryFromJson`; `character_status_test.dart` group `awaitingAid` |
| T-9-06 | DoS | `CharacterFragment` | M | CLOSED | `character_fragment.dart:49-53` selects only `awaitingAid { quest aidQuest since }`; no 9.2 field in the fragment | `character_fragment_test.dart`; schema registry check recorded in `09-03-SUMMARY.md` (full re-check deferred to 09-13) |
| T-9-07 | EoP | Board aid family | A | CLOSED | Accepted, see log. BE stays judge: `quest_acceptance_failure.dart:68` maps `AWAITING_AID`, `QUEST_FULL` mapped in the same switch | `quest_acceptance_failure_test.dart:26`; `quest_info_sheet_test.dart` |
| T-9-08 | Tampering / Spoofing | failure classifiers | M | CLOSED | `quest_result_failure.dart:28-39`, `transaction_failure.dart:33-52`, `travel_failure.dart:61-64`, `quest_acceptance_failure.dart:68`: `switch` on `graphQlErrorCode` only, `_ => unknown`; no `.message` read | `quest_result_failure_test.dart:44`, `transaction_failure_test.dart:52`, `travel_failure_test.dart:47,60` "ignores the message text and relies on the code only" |
| T-9-09 | Info disc. | `TransactionCubit` | M | CLOSED | `transaction_cubit.dart:25-37` no log; failure enum only (grep `debugPrint\|print(` over the phase files = 0) | `transaction_cubit_test.dart` |
| T-9-10 | DoS | `TransactionCubit` reset | M | CLOSED | `transaction_cubit.dart:23,26,40-43,45-49` single `Timer`, cancelled on a new transaction and on `close`; `isClosed` guard | `transaction_cubit_test.dart:111` "close leaves no reset timer pending", `:126` "a new transaction replaces the pending reset" |
| T-9-11 | EoP | shop / travel while wounded | A | CLOSED | Accepted, see log. BE codes classified: `transaction_failure.dart:6,39` `SHOP_NOT_IN_CITY`; `travel_failure.dart:11,64`, `quest_acceptance_failure.dart:68` `AWAITING_AID` | `transaction_failure_test.dart:16`, `travel_failure_test.dart:21`, `quest_acceptance_failure_test.dart:26` |
| T-9-12 | DoS | `ConnectionRestoredBus` | M | CLOSED | `session_sync_cubit.dart` `_onConnection` (diff `+112-121`): `notifyRestored` only on `isConnected && _hasConnected && !_isConnected`; `connection_restored_events.dart:10-22`; consumer single-flight `quest_results_cubit.dart:96-97` | `session_sync_cubit_test.dart:505-545` group `connection restored` (first connection, repeats, drop+connect); `quest_results_delivery_test.dart:160` "triggers during a read join the read in flight" |
| T-9-13 | Spoofing | banner dedup | M | CLOSED | `in_app_notifications_cubit.dart:78-87` `suppress`: marks the key for `personalDedupWindow`, drops queued copies, replaces the current one; scoped to the exact `dedupKey` (`PushEvent`s only) | `in_app_notifications_cubit_test.dart:416-490` group `suppress` (incl. "an unrelated key leaves the banner and the queue untouched") |
| T-9-14 | DoS | `MapAvailabilityCubit` | M | CLOSED | `world_map.dart` `dispose` resets `questSheetChanged(false)` and `pawnDragChanged(false)` via the cached cubit (`_availability`, set in `initState`); `_endPawnDrag` on release and when the dragged pawn is replaced by a travel (IN-02); `main_screen.dart` `dispose` -> `pageChanged(isMapPage: false)`; `quest_result_presenter.dart:64-68` `routeCoveredChanged(false)` on dispose; equality-filtered writes (Equatable state, `map_availability_cubit.dart:15-25`); death bypasses page/overlay/drag (`quest_result_presenter.dart:160`) | `map_availability_cubit_test.dart:76` "repeating a write with the same value emits nothing"; `world_map_availability_test.dart:118-160` (IN-02), `:161-190` group `unmount (T-9-14)`; `authenticated_shell_test.dart:242`; `quest_result_presenter_death_test.dart:197` |
| T-9-15 | DoS | `subscribeToQuestResults` | M | CLOSED | `graphql.dart:137-145` per-event `_questResultFrom`, malformed -> `FormatException` on the stream (not fatal); `:158-165` `_throwIfStreamFailed`; consumer skips it `quest_results_cubit.dart:271` | `graphql_quest_result_test.dart:65` "keeps delivering after a malformed event"; `quest_results_delivery_test.dart:401` "a malformed event is skipped without resubscribing" |
| T-9-16 | Spoofing | `getQuestResult(id)` | T | CLOSED | Transferred to BE ownership guard (`FORBIDDEN`), see log. FE side: `quest_result_failure.dart:35` maps `forbidden`, `quest_result_notice.dart:26-37` shows fixed copy and no data; id filtered at `quest_results_cubit.dart:103` | `quest_result_failure_test.dart:22`, `quest_result_repository_test.dart:53`; `quest_results_delivery_test.dart:484` notice |
| T-9-17 | Tampering | documents | M | CLOSED | `grep -rniE "locations\|acknowledg\|unacknowledged" lib/graphql` = one doc comment (`quest_result_fragment.dart:7`), no selection; `git diff ffb4dec..HEAD -- lib/graphql tool` empty (`09-REVIEW-FIX.md`) | `quest_result_documents_test.dart:58` (no `acknowledgedAt`), `:84,:107` registered in the schema check; schema check 36/36 in `09-03-SUMMARY.md` |
| T-9-18 | Info disc. | logs | M | CLOSED | grep `debugPrint\|print(\|log(` over `lib/models/quest_result`, `quest_result_*.dart` repository files, `questResultsCubit`, `quest_result_presenter.dart`, `quest_result_sheet.dart`, `hp_delta_bar.dart`, `lib/graphql`, `mapAvailabilityCubit` = 0; `QuestResultException.toString` prints the enum name only (`quest_result_failure.dart:24`) | `quest_result_failure_test.dart` |
| T-9-19 | DoS | `fetch` | M | CLOSED | `quest_result_repository.dart:17,32,35-36` 15 s `timeout` -> `timedOut` (silent: not notice-worthy, `quest_results_cubit.dart:251-253`) | `quest_result_repository_test.dart:33,80` (fake_async) |
| T-9-20 | DoS | `HpDeltaBar` / sheet | M | CLOSED | `hp_delta_bar.dart:25` `max <= 0 ? 0 : (hp/max).clamp(0.0, 1.0)`; the continue button is independent from the animation (`quest_result_sheet.dart:420-422`) | `hp_delta_bar_test.dart:69` zero maximum, `:76` clamps both ways |
| T-9-21 | Repudiation | dismissal | M | CLOSED | One explicit button (`quest_result_sheet.dart:420`); the only other `GestureDetector` (`:260-263`) skips the HP animation, it does not close; scrim/back handled in the presenter (T-9-32) | `quest_result_sheet_test.dart` "tapping anywhere else calls nothing" |
| T-9-22 | Tampering | game state | M | CLOSED | `quest_result_sheet.dart` imports no `flutter_bloc` (grep = 0) and no `DateTime.now`; it renders `hpBefore/hpAfter/xpBefore/xpAfter/levelBefore/levelAfter/titleBefore/titleAfter` as received (`:205-206,253-254,372-384`); no field is computed except display deltas of BE numbers | `quest_result_sheet_test.dart` (renders BE numbers); `hp_delta_bar_test.dart:38` |
| T-9-23 | DoS | `CharacterCubit` | M | CLOSED | `character_cubit.dart:77-80` access-denied on load -> `_markCharacterGone` + `CharacterUnavailable`; `:90` `refreshCharacter` returns when `_isCharacterGone`; `:96-98`, `:123-144` stream/refetch denial -> gone; `:147-151` one user refresh per cubit lifetime | `character_cubit_test.dart:186-262` group `character gone (D-13)` (cold start quiet, resumes no-op, refetch NOT_FOUND keeps Loaded, stream NOT_FOUND) |
| T-9-24 | Repudiation / UX | cold start after death | M | CLOSED | `character_state.dart` `CharacterUnavailable` (no error text); `main_screen.dart` `_ColdStart` keeps the loader (allowed at cold start) and shows the retry screen only when `isUnavailable && isSettledWithoutSheets` (`quest_results_state.dart:51-56`); `QuestResultPresenter` wraps the loader (`main_screen.dart:88`) so the death sheet opens over it | `main_screen_test.dart:127-240` group `unavailable character at cold start (WR-03)` (loader while inFlight, retry only when done/failed, death ack keeps the loader); `main_screen_quest_results_test.dart:309` |
| T-9-25 | EoP | wounded actions | M | CLOSED | `character_marker_layer.dart` `_canStartTravel` includes `awaitingAid == null`; `satchel_availability.dart:15-16` Board/Shop disabled with `isAwaitingAid`; `main_screen.dart` `_isPageDisabled` honours it; BE refusals still classified (T-9-11) | `character_marker_layer_test.dart:194`, `satchel_availability_test.dart:66,78`, `main_screen_test.dart:538,554,579`, `world_map_availability_test.dart:137` |
| T-9-26 | Spoofing | `requestFromTap` | M | CLOSED | `quest_results_cubit.dart:102-119` `validBackendIdentifier(id)` (`^[A-Za-z0-9._-]{1,128}$`), known ids ignored (`:339-344`), result read with `_repository.fetch(resultId)`; `quest_end_event.dart` / popup `notification_popup_registry.dart` forward `intent.id` only | `quest_results_delivery_test.dart:414-480` ("ignores the id null / bad id!", queued, showing, closed, pending-ack ids not read again, unknown id read once); `backend_identifier_test.dart`; `notification_intent_landing_test.dart:183` |
| T-9-27 | Tampering / Repudiation | dedup | M | CLOSED | `quest_results_cubit.dart:224-231` batch dedup, `:327-344` `_accept`/`_isKnown` (closed, pending-ack, acknowledged, showing, queued) and `acknowledgedAt != null` ignored | `quest_results_queue_test.dart:99,106`; `quest_results_delivery_test.dart:215,426-465` |
| T-9-28 | DoS | refetch / resubscribe | M | CLOSED | Single-flight `quest_results_cubit.dart:96-97`; `silentRetry` bounded (8 attempts, 60 s cap, `silent_retry.dart:5,20-21`) with deterministic failures not retried (`:242-249`, IN-04); resubscribe `exponentialBackoff(..., max: WsReconnectPolicy.maxReconnectDelay)` (`:294-306`), one timer (`:295`); terminal access-denied stops (`:272-275`, `:284-289`); WR-01 refetch after resubscribe (`:303`) | `quest_results_delivery_test.dart:160,234,253,309,345,357,373,392`; `backoff_test.dart`, `ws_reconnect_policy_test.dart:200` (cap); see O-3 |
| T-9-29 | EoP | death ack | M | CLOSED | `quest_results_cubit.dart:164-181` `acknowledgeDeath` awaited (`inFlight -> done/failed`), repeated calls ignored, `:318-324` serialised chain with `portTimeout` 15 s, `:45-49`; `quest_results_state.dart:45-46` no sheet after `done`; one user refresh after `done` (`:186-190`) | `quest_results_queue_test.dart:266-375` (in-flight ignore, failed keeps the sheet, done stops offering, one refresh); `quest_results_delivery_test.dart:327`. Device order and BE release deferred to 09-13 (see O-1) |
| T-9-30 | Repudiation | external pop | M | CLOSED | `quest_results_cubit.dart:151-160` `dismissedExternally` requeues without ack; presenter routes a non-`true` pop result there (`quest_result_presenter.dart:195-199`) | `quest_results_queue_test.dart:240-266`; `quest_result_presenter_test.dart:377` "an external pop requeues without acknowledging" |
| T-9-31 | Info disc. | logs | M | CLOSED | Same grep as T-9-18 = 0 in the delivery files; `character_cubit.dart:143` logs the error code only | `quest_result_failure_test.dart` |
| T-9-32 | Repudiation | dialog route | M | CLOSED | `quest_result_presenter.dart:176-192` `useRootNavigator: true`, `barrierDismissible: false`, `PopScope(canPop: false)`; `_onContinue` is the only `pop(true)` source (`:248-254`); external pop -> requeue | `quest_result_presenter_test.dart:342` "scrim, back and drag do nothing", `:377`; `quest_result_presenter_death_test.dart:300` same for death |
| T-9-33 | EoP | death flow | M | CLOSED | `quest_result_presenter.dart:222-227` the route pops only on `DeathAcknowledgement.done`; the death button calls `acknowledgeDeath` (`:253`), disabled while in flight (`quest_result_sheet.dart:422`) | `quest_result_presenter_death_test.dart:235` "the death button awaits the acknowledgement", `:255`, `:287` |
| T-9-34 | DoS | gating | M | CLOSED | `quest_result_presenter.dart:56-62` route-covered signal recomputed on every dependency change (post-frame, `mounted` guard); `:155-163` death bypasses page/overlay/drag; `:200` re-attempt after a close; resets on dispose (T-9-14) | `quest_result_presenter_test.dart:225,247,274`; `quest_result_presenter_death_test.dart:197,211` |
| T-9-35 | Spoofing | banner | M | CLOSED | `quest_result_presenter.dart:111-123` `suppress(event.dedupKey)` on sheet ground (free Map or death in queue, IN-03), `publish` otherwise honouring the `questEnd` toggle (`:125-128`); dedup by key in `InAppNotificationsCubit` (`:55-59`) | `quest_result_presenter_test.dart:178,190,207,291,306,320` |
| T-9-36 | Info disc. | death name | M | CLOSED | `quest_result_presenter.dart:205-209` name only when `character?.id == result.characterId` | `quest_result_presenter_death_test.dart:172,186` ("a death of another character shows no name line") |
| T-9-37 | DoS | `WorldMap` writers | M | CLOSED | `world_map.dart` `_availability` cached in `initState`, `dispose` resets `questSheetChanged(false)` and `pawnDragChanged(false)`; `_clearSelection` resets the sheet flag; equality-filtered writes | `world_map_availability_test.dart:161-190` unmount cases (quest sheet and mid-drag), `:60,:74,:92,:105` |
| T-9-38 | Repudiation / UX | `MainScreen` page writer | M | CLOSED | `MapAvailabilityState.isMapPage` defaults false (`map_availability_state.dart:8`); `main_screen.dart` `_reportMapPage` runs on `onPageChanged` and when `MainScreenLoadData` first appears (listener), never from the loader; `dispose` resets | `main_screen_test.dart:425` "the cold-start loader is never the map page"; `quest_result_presenter_test.dart:178` |
| T-9-39 | Spoofing | `requestQuestResult` popup | M | CLOSED | `notification_popup_registry.dart` `requestQuestResult` forwards `intent.id` only to `requestFromTap`, which re-validates and re-reads (T-9-26) | `notification_intent_landing_test.dart:183` "a questEnd tap lands on the map and asks the queue for it" |
| T-9-40 | Info disc. / DoS | shell teardown | M | CLOSED | `authenticated_shell.dart` `BlocProvider<QuestResultsCubit>` inside the keyed shell; `quest_results_cubit.dart:356-365` `close` cancels the stream, lifecycle and restored subscriptions and the resubscribe timer; `_scheduleResubscribe` and `_performRefetch` check `isClosed` | `authenticated_shell_test.dart:264` "provides the quest results cubit started for the character and closes it on removal"; `quest_results_delivery_test.dart:525,540` group `close` |
| T-9-41 | EoP | cold start after death | M | CLOSED | `main_screen.dart:88` presenter wraps the loader; `quest_result_presenter.dart:88-93` refetch when the character becomes unavailable; `quest_results_state.dart:39,51-56`; no routing hold (D-13: BE keeps `currentCharacter` until the ack) | `main_screen_quest_results_test.dart:309` "a dead current character gets its death sheet over the loader"; `main_screen_test.dart:223`; BE half and device order deferred to 09-13 (see O-1) |

## Deferred to Plans 09-12/09-13 (gated by the BE 9.2 PR, CONTEXT D-21)

DEFERRED (09-12 and 09-13, gated by the BE 9.2 PR). Not counted as OPEN, not blocking.

| Threat | Cat. | Component | Disp | Status | What closes it |
|--------|------|-----------|------|--------|----------------|
| T-9-42 | DoS | result fragment (`acknowledgedAt`) | M | DEFERRED | BE gate first step; schema check 38/38 against `origin/develop` before commit. Interim state verified here: no `acknowledgedAt` selection in `lib/graphql/` (grep), parser already tolerant (`quest_result.dart:115,160-161`; `quest_result_test.dart:199`). |
| T-9-43 | Tampering | 9.2 contract drift | M | DEFERRED | Handoff + schema read before editing; parse aligned under TDD. |
| T-9-44 | EoP | `acknowledgeQuestResult` | T | DEFERRED | BE ownership guard (`FORBIDDEN`); FE acks only ids it displayed (queue). Interim: the real port does not exist (`NoQuestResultAcknowledger`), the FE logic already acks only `state.showing`/`_pendingAcks` ids (`quest_results_cubit.dart:136-147,164-181`). |
| T-9-45 | DoS | `getUnacknowledgedQuestResults` | M | DEFERRED | Per-entry `tryFromJson`, malformed skipped, in the 09-12 service. Interim: `QuestResult.assetQuantitiesFrom`/`tryFromJson` boundary exists (T-9-01); IN-04 stops retrying a `malformed` list (`quest_results_cubit.dart:242-249`). |
| T-9-46 | Info disc. | BE access while checking the schema | M | DEFERRED | `git fetch/show/ls-tree` of tracked files only, no `.env` (to be verified when 09-12 runs). |
| T-9-47 | DoS | shipped documents vs merged BE | M | DEFERRED | BE gate + schema check 38/38 before the device run. |
| T-9-48 | Info disc. | E2E session secrets | M | DEFERRED | No command reads `.env`; UAT notes without ids/tokens (to be verified when 09-13 runs). |
| T-9-49 | EoP | death flow on device | M | DEFERRED | E2E steps 8/9 observe the order; FE logic CLOSED under T-9-29/T-9-33/T-9-41. |
| T-9-50 | Repudiation | REQUIREMENTS traceability | M | DEFERRED | Ticks only for steps passed and recorded from the user's words. |
| T-9-51 | Tampering | BE working tree | M | DEFERRED | BE accessed with `fetch`/`show`/`ls-tree` only. Observed in this audit: no BE path in `git diff --name-only origin/develop..HEAD`. |

## Accepted Risks Log

| Threat | Risk | Rationale | Bound |
|--------|------|-----------|-------|
| T-9-04 | The `questEnd` banner is built from the result (`questEndEventOf`) and could in principle carry game data. | The copy is the same generic BE string (`quest_end_event.dart:7-8`), the id is the result id, no payload content is rendered (`:12-18`). | `quest_end_event_test.dart:13` |
| T-9-07 | The FE may present a Board aid quest as acceptable while the BE refuses it. | The aid family only changes the layout; the BE stays the judge and its refusals (`QUEST_FULL`, `AWAITING_AID`) are mapped to domain failures (`quest_acceptance_failure.dart:68`). | `quest_acceptance_failure_test.dart:26`, `quest_info_sheet_test.dart` |
| T-9-11 | A wounded character could still attempt shop or travel if the client gate is bypassed. | Client gating (drag, Board, Shop: `character_marker_layer.dart`, `satchel_availability.dart:15-16`) is a first filter only; the BE refuses with `AWAITING_AID` / `SHOP_NOT_IN_CITY`, both classified (`travel_failure.dart:64`, `quest_acceptance_failure.dart:68`, `transaction_failure.dart:39`) and shown as banners (`transaction_notice.dart`, `TransactionOutcomeListener` mounted in `MainScreen`, IN-05). | Tests listed under T-9-11 and T-9-25 |

Also documented, not a register entry: `CharacterCubit._isCharacterGone` lasts for the cubit lifetime by design (`character_cubit.dart` class doc, 09-REVIEW IN-06); the app is landscape-locked (`lib/main.dart:76-79`) so the sheet clamp (WR-02) is defensive.

## Transferred Risks

| Threat | Transferred to | Documentation |
|--------|----------------|---------------|
| T-9-16 | BE ownership check on `questResult(id)` (`FORBIDDEN`, innkeeper included), BE Phase 9 handoff | `BACKEND-NOTES.md`; the FE sends only a validated id (`quest_results_cubit.dart:103`), maps `FORBIDDEN` to `forbidden` and `NOT_FOUND` to `notFound` (`quest_result_failure.dart:35-36`) and shows fixed copy without data (`quest_result_notice.dart:26-37`) |
| T-9-44 (deferred) | BE ownership guard on `acknowledgeQuestResult` (BE 9.2) | To be documented with 09-12; see Deferred table |

## Unregistered Flags

None. Only `09-04-SUMMARY.md` (lines 131-133), `09-10-SUMMARY.md` (123-125) and `09-11-SUMMARY.md` (130-132) carry a `## Threat Flags` section; all three report "None" and name registered ids (T-9-08..T-9-11, T-9-32..T-9-36, T-9-39..T-9-41). The other SUMMARYs have no such section and flag nothing.

## Observations (no threat id)

- O-1: Until plan 09-12 the ports are placeholders (`NoPendingQuestResults`, `NoQuestResultAcknowledger` in `authenticated_shell.dart`). The FE half of the death flow (T-9-29/33/41) is proven by tests, but the BE half (the ack releasing `currentCharacter`, the unacknowledged list feeding the cold-start death sheet) and the on-device order are only provable after the BE 9.2 merge (09-13; `09-VERIFICATION.md` is `human_needed` for this reason). With the placeholders the retry screen can appear at once on an unavailable cold start (known, accepted).
- O-2: Pre-existing logging outside the phase diff, none with result payloads: `shop_cubit.dart:25` `print(e.toString())` and `graphql.dart:228` `debugPrint` of a quest id on a skipped quest. Not part of any Phase 9 threat; candidates for a later Boy Scout pass.
- O-3: The 60 s backoff cap is tested at the policy level (`ws_reconnect_policy_test.dart:200`, `backoff_test.dart`); the cubit tests assert the first backoff step and the resubscribe, not the cap on the cubit's own timer. The cubit passes the same constant (`quest_results_cubit.dart:298`), so the evidence is by construction.
- O-4: The dispose reset of the route-covered flag (`quest_result_presenter.dart:64-68`) has no dedicated widget test; it is covered by the cubit tests and by the shell-teardown test for the cubit itself. The other writers (WorldMap, MainScreen) have explicit tests.
- O-5: `QuestResult.fromJson` is intentionally strict on required scalars and the outcome (`:83-116`); the safety comes from `tryFromJson` being the only entry used by the services (`graphql.dart:188-195`), so a strict `fromJson` never reaches a stream mapper.
- O-6: The sheet's HP `GestureDetector` (`quest_result_sheet.dart:260-263`) only skips the animation; it is not a dismissal path (T-9-21).

## Audit Trail

| Date | Event |
|------|-------|
| 2026-10-28 | Audit of plans 09-01..09-11 at HEAD `9cde871` (review fixes WR-01..WR-04, IN-01..IN-05 included): 41 threats verified (37 mitigate, 3 accept, 1 transfer), all CLOSED; 10 threats of 09-12/09-13 DEFERRED; 641 targeted tests green over 47 files; no unregistered flags; `.env` untracked and not read; BE repo untouched; `lib/graphql/` has no 9.2 selection. |
