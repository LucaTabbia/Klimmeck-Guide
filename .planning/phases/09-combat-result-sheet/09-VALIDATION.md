---
phase: 9
slug: combat-result-sheet
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-27
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (SDK 3.35.5 via fvm) + bloc_test 10.0.0 + mocktail 1.0.5 + fake_async 1.3.3 |
| **Config file** | none (`analysis_options.yaml` with flutter_lints); shared mocks `test/helpers/mocks.dart`, fixtures `test/helpers/fixtures/`, fakes `test/helpers/fakes/` |
| **Quick run command** | `flutter test test/models test/utils test/graphql test/repository test/tool test/shared test/screens` |
| **Full suite command** | `flutter test` + `flutter analyze` (≤ 53 issues, 0 errors) |
| **Estimated runtime** | ~45 s quick / ~65 s full (baseline 2139 tests in ~60 s) |

---

## Sampling Rate

- **After every task commit:** the task's `<automated>` command (single files, < 15 s)
- **After every plan wave:** the quick run command + `flutter analyze`
- **Before `/gsd-verify-work`:** full suite green, analyzer ≤ 53 / 0 errors, schema check 38/38 OK against BE `origin/develop` (after the BE 9.2 merge)
- **Max feedback latency:** ~15 s per task, ~65 s per wave

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 9-01-01 | 01 | 1 | COMBAT-03, COMBAT-05 | T-9-01, T-9-02, T-9-03 | malformed results → null, never throw; no `enemy.locations`; equipment rewards keep `equipType` | unit | `flutter test test/models/quest_result` | ✅ | ✅ green |
| 9-01-02 | 01 | 1 | COMBAT-04, COMBAT-05 | T-9-04 | generic BE copy only in the banner | unit | `flutter test test/models/enums test/models/quest_result` | ✅ | ✅ green |
| 9-02-01 | 02 | 1 | COMBAT-08 | T-9-05, T-9-06 | malformed `awaitingAid` → null, status survives; only BE-develop fields selected | unit | `flutter test test/models/character test/graphql test/tool` | ✅ (extend) | ✅ green |
| 9-02-02 | 02 | 1 | COMBAT-10 | T-9-07 | aid only changes the layout; BE stays the judge | unit + widget | `flutter test test/models/quest test/shared/components/popup/quest_info_sheet_test.dart test/screens/mainScreen/tabs/board` | ✅ (invert) | ✅ green |
| 9-03-01 | 03 | 2 | COMBAT-01, COMBAT-09 | T-9-17 | no 9.2 field/operation before the merge; 36/36 vs BE develop | unit + schema check | `flutter test test/graphql test/tool` | ❌ W0 | ⬜ pending |
| 9-03-02 | 03 | 2 | COMBAT-01, COMBAT-09 | T-9-15, T-9-16, T-9-18, T-9-19 | malformed event does not close the stream; failures by code; 15 s timeout | unit | `flutter test test/repository/quest_result_failure_test.dart test/repository/quest_result_repository_test.dart test/repository/quest_result_delivery_ports_test.dart test/repository/services/graphql` | ❌ W0 | ⬜ pending |
| 9-04-01 | 04 | 1 | COMBAT-08 | T-9-08 | `AWAITING_AID` mapped by code only | unit | `flutter test test/repository/travel_failure_test.dart test/repository/quest_acceptance_failure_test.dart test/screens/mainScreen/travelCubit test/screens/mainScreen/questAcceptanceCubit test/screens/mainScreen/components` | ✅ (extend) | ✅ green |
| 9-04-02 | 04 | 1 | COMBAT-08 | T-9-08, T-9-09, T-9-10 | `doTransaction` rethrows the coded `OperationException` (failing-first service test); shop codes by `extensions.code`; no payload logging; cancellable reset | unit + bloc | `flutter test test/repository/services/graphql/graphql_transaction_test.dart test/repository/transaction_failure_test.dart test/screens/mainScreen/tabs/shop` | ✅ | ✅ green |
| 9-04-03 | 04 | 1 | COMBAT-08 | T-9-11 | `SHOP_NOT_IN_CITY` → banner | widget | `flutter test test/screens/mainScreen/tabs/shop test/screens/mainScreen/components` | ✅ | ✅ green |
| 9-05-01 | 05 | 1 | COMBAT-07 | T-9-14 | Map-free state Flutter-free, equality-filtered | bloc | `flutter test test/screens/mainScreen/tabs/map/mapAvailabilityCubit` | ❌ W0 | ⬜ pending |
| 9-05-02 | 05 | 1 | COMBAT-09 | T-9-12 | one restore event per false→true transition | unit + bloc + widget | `flutter test test/repository/services/sync test/screens/auth/syncCubit test/screens/auth/session_sync_scope_test.dart test/screens/auth/auth_gate_test.dart` | ❌ W0 | ⬜ pending |
| 9-05-03 | 05 | 1 | COMBAT-01 | T-9-13 | `suppress` drops queued/current banner of the key | unit | `flutter test test/screens/auth/inAppNotificationsCubit` | ✅ (extend) | ⬜ pending |
| 9-06-01 | 06 | 3 | COMBAT-07, COMBAT-09, COMBAT-08 | T-9-27, T-9-29, T-9-30 | dedup by id; external pop requeues without ack; death ack awaited, then exactly one `requestUserRefresh` | bloc | `flutter test test/screens/mainScreen/questResultsCubit/quest_results_queue_test.dart` | ❌ W0 | ⬜ pending |
| 9-06-02 | 06 | 3 | COMBAT-01, COMBAT-09 | T-9-26, T-9-28, T-9-31 | tap id validated, re-read from BE; bounded retries; terminal codes stop and trigger one refetch | bloc (fake_async) | `flutter test test/screens/mainScreen/questResultsCubit` | ❌ W0 | ⬜ pending |
| 9-07-01 | 07 | 2 | COMBAT-02 | T-9-20 | HP fraction clamped, `max` 0 safe | widget + unit | `flutter test test/theme test/shared/components/hp_delta_bar_test.dart` | ❌ W0 | ⬜ pending |
| 9-07-02 | 07 | 2 | COMBAT-02, COMBAT-03, COMBAT-04, COMBAT-05, COMBAT-06 | T-9-21, T-9-22 | button-only dismissal; pure widget, no state source; tap skips the HP animation via a keyed rebuild | widget | `flutter test test/shared/components/popup` | ❌ W0 | ⬜ pending |
| 9-08-01 | 08 | 2 | COMBAT-09, COMBAT-08 | T-9-23, T-9-24 | one user refresh, no refetch loop for a dead current character | bloc (fake_async) | `flutter test test/screens/mainScreen/characterCubit test/screens/mainScreen/main_screen_test.dart test/screens/auth` | ✅ (extend) | ⬜ pending |
| 9-08-02 | 08 | 2 | COMBAT-08 | T-9-25 | Board/Shop gated while awaiting aid | unit + widget | `flutter test test/screens/mainScreen/components/satchel_availability_test.dart test/screens/mainScreen/main_screen_test.dart` | ✅ (extend) | ⬜ pending |
| 9-08-03 | 08 | 2 | COMBAT-08 | T-9-25 | wounded pawn not draggable | widget | `flutter test test/screens/mainScreen/tabs/map` | ✅ (extend) | ⬜ pending |
| 9-09-01 | 09 | 3 | COMBAT-07 | T-9-38 | no sheet over the cold-start loader | widget | `flutter test test/screens/auth/authenticated_shell_test.dart test/screens/mainScreen/main_screen_test.dart` | ✅ (extend) | ⬜ pending |
| 9-09-02 | 09 | 3 | COMBAT-07 | T-9-37 | writers reset on dispose | widget | `flutter test test/screens/mainScreen/tabs/map` | ❌ W0 | ⬜ pending |
| 9-10-01 | 10 | 4 | COMBAT-01, COMBAT-06, COMBAT-07 | T-9-32, T-9-34, T-9-35 | scrim/back/swipe ignored; external pop requeues; suppress only for the arriving result that opens now, banner otherwise; `CharacterUnavailable` triggers a refetch | widget | `flutter test test/screens/mainScreen/components/quest_result_presenter_test.dart test/screens/mainScreen/questResultsCubit` | ❌ W0 | ⬜ pending |
| 9-10-02 | 10 | 4 | COMBAT-08, COMBAT-09 | T-9-33, T-9-36 | death sheet first, ack awaited before closing, one user refresh after it | widget | `flutter test test/screens/mainScreen/components/quest_result_presenter_death_test.dart test/screens/mainScreen/components/quest_result_presenter_test.dart` | ❌ W0 | ⬜ pending |
| 9-11-01 | 11 | 5 | COMBAT-01, COMBAT-09 | T-9-39, T-9-40 | tap forwards only the validated id; stream closed with the shell | widget | `flutter test test/screens/auth test/screens/mainScreen/components/notification_intent_landing_test.dart` | ✅ (amend :177) | ⬜ pending |
| 9-11-02 | 11 | 5 | COMBAT-01, COMBAT-07, COMBAT-08, COMBAT-09 | T-9-41 | death sheet over the loader at cold start | widget + full suite | `flutter test test/screens/mainScreen/main_screen_quest_results_test.dart test/screens/mainScreen/main_screen_test.dart && flutter test` | ❌ W0 | ⬜ pending |
| 9-12-01 | 12 | 6 (gated) | COMBAT-09 | T-9-42, T-9-43, T-9-46 | BE gate first; 38/38 vs BE develop | unit + schema check | `flutter test test/graphql test/tool test/models/quest_result` | ✅ (extend) | ⬜ pending |
| 9-12-02 | 12 | 6 (gated) | COMBAT-09 | T-9-44, T-9-45 | ack only displayed ids; malformed list entries skipped | unit + widget | `flutter test test/repository test/screens/auth test/screens/mainScreen` | ✅ (extend) | ⬜ pending |
| 9-13-01 | 13 | 7 (gated) | COMBAT-01..10 | T-9-47 | full gates against the merged BE | full suite + analyze + schema check | `flutter test && flutter analyze` | ✅ | ⬜ pending |
| 9-13-02 | 13 | 7 (gated) | COMBAT-01..10 | T-9-48, T-9-49 | device E2E, no secrets printed, death order observed | manual (human-verify) | `test -f .planning/phases/09-combat-result-sheet/09-HUMAN-UAT.md` | ❌ (created by the task) | ⬜ pending |
| 9-13-03 | 13 | 7 (gated) | COMBAT-01..10 | T-9-50, T-9-51 | ticks only for passed steps | docs | `grep -q "^status: \(complete\|partial\)" .planning/phases/09-combat-result-sheet/09-HUMAN-UAT.md` | ❌ (created by 9-13-02) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/helpers/fixtures/quest_result_fixtures.dart` — one recorded payload per outcome, null enemy/spell, orphan item, with/without `acknowledgedAt` (plan 09-01)
- [x] `test/helpers/fixtures/travel_fixtures.dart` — `awaitingAidJson` + `travellingCharacterJson(awaitingAid:)` (plan 09-02)
- [ ] `test/helpers/mocks.dart` — `MockTransactionCubit` (09-04 ✅), `MockQuestResultRepository` (09-03), `MockQuestResultsCubit` (09-11)
- [ ] `test/helpers/fakes/fake_pending_quest_results.dart`, `test/helpers/fakes/recording_quest_result_acknowledger.dart` (plan 09-06)
- [ ] `test/screens/auth/authenticated_shell_test.dart` — stub `subscribeToQuestResults` (09-11) and `getUnacknowledgedQuestResults` (09-12), provide `ConnectionRestoredEvents`

---

## Manual-Only Verifications

All run in plan 09-13 Task 2, on the Android device, **after the BE 9.2 PR is merged on BE `develop`** (steps of BE Phase 9 handoff §13 + FE BACKEND-NOTES §4).

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Foreground result on the Map: sheet at once, no banner, animations, no re-show after restart | COMBAT-01, 02, 05, 09 | real WS + BE resolution timing + ack persisted on the BE | 09-13 step 1 |
| Banner gateway from another tab | COMBAT-01, 07 | real banner/tap router with live events | 09-13 step 2 |
| Push tap from background; acknowledged id → Map only; foreign id → notice | COMBAT-01 | real FCM delivery and OS notification tap | 09-13 step 3 |
| Result produced with notifications off and app force-stopped appears at cold start; toggle off silences banner only | COMBAT-09 | needs OS settings, force-stop and the BE 9.2 list | 09-13 step 4 |
| FIFO queue, overlays/drag/travel sheet delay, scrim/back/swipe ignored on device | COMBAT-06, 07 | real gestures and back button | 09-13 step 5 |
| Failure: injuries labels, wounded label, drag/Board/Shop disabled, aid combat family | COMBAT-03, 04, 08, 10 | real combat engine output | 09-13 step 6 |
| Rescue: rescuer count, «Sei stato salvato», pawn in city | COMBAT-05, 08 | two real characters | 09-13 step 7 |
| Death live on any tab, creation only after the ack | COMBAT-08, 09 | BE timeout sweep + `userUpdated` ordering (BE 9.2 D-12) | 09-13 step 8 |
| Death at cold start (app killed) | COMBAT-09 | process death + BE state | 09-13 step 9 |
| Spell learned, GM completion title change | COMBAT-05 | real catalog data | 09-13 step 10 |
| Started boss stays torn after a participant deletion | COMBAT-10 | BE 9.2 seat rule on real data | 09-13 step 11 |
| Settings deletion of a wounded character routes at once | COMBAT-08 | real deletion flow | 09-13 step 12 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15 s per task
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
</content>
</invoke>
