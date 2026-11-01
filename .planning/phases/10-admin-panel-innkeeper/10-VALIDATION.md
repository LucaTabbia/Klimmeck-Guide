---
phase: 10
slug: admin-panel-innkeeper
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-10-29
updated: 2026-11-01
be_ref: 4dc7e89
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` + `bloc_test` ^10.0.0 + `mocktail` ^1.0.5 + `fake_async` ^1.3.3 |
| **Config file** | none — `pubspec.yaml` dev_dependencies, shared mocks in `test/helpers/mocks.dart`, fixtures in `test/helpers/fixtures/` |
| **Quick run command** | `flutter test <file>` (foreground) |
| **Full suite command** | `flutter test` (foreground, Bash timeout 600000 ms) |
| **Estimated runtime** | ~70 seconds (full suite, 2833 tests on 2026-11-01) |
| **Cross-repo gate** | `dart run tool/schema_check/dump_documents.dart <dir>` + `tool/schema_check/validate_documents.js` against BE `origin/develop:src/schema.gql` |
| **Analyzer gate** | repo-wide `flutter analyze`: ≤ 52 issues, no `error`/`warning` line |

---

## Sampling Rate

- **After every task commit:** the task's `<automated>` command (`flutter test <files>`)
- **After every plan wave:** `flutter test` + repo-wide analyzer gate
- **Before `/gsd-verify-work`:** full suite green, schema check 42/42 OK against the merged BE
- **Max feedback latency:** ~70 seconds (full suite); quick runs < 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | ADMIN-02 | T-10-01 / T-10-04 | one malformed entry is dropped, never the queue; no `user`/points held | unit | `flutter test test/models/pending_request/pending_request_test.dart` | ✅ | ✅ green |
| 10-01-02 | 01 | 1 | ADMIN-02, ADMIN-03 | T-10-02 | an unreadable travel is fail-closed (never «present») | unit | `flutter test test/models/pending_request` | ✅ | ✅ green |
| 10-01-03 | 01 | 1 | ADMIN-03, ADMIN-05, ADMIN-06 | T-10-03 | HP and quantities clamped; only changed participants in the input | unit | `flutter test test/models/request/participant_draft_test.dart test/models/request/participant_override_test.dart test/models/pending_request` | ✅ | ✅ green |
| 10-02-01 | 02 | 2 | ADMIN-02, ADMIN-03, ADMIN-04 | T-10-05 / T-10-06 | no gated or private field selected before the BE merge; 42 documents registered | unit (documents) | `flutter test test/graphql test/tool` | ✅ | ✅ green |
| 10-02-02 | 02 | 2 | ADMIN-03, ADMIN-04 | T-10-09 | typed service methods with bounded requests | unit | `flutter test test/repository/services/graphql` | ✅ | ✅ green |
| 10-02-03 | 02 | 2 | ADMIN-07 | T-10-07 / T-10-08 | `FORBIDDEN` and per-code failures classified; no raw message reaches the UI | unit | `flutter test test/repository/innkeeper_failure_test.dart test/repository/innkeeper_repository_test.dart` + analyzer gate | ✅ | ✅ green |
| 10-03-01 | 03 | 3 | ADMIN-02 | T-10-11 / T-10-12 | terminal `FORBIDDEN`, subscription closed with the route | bloc | `flutter test test/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit_test.dart` | ✅ | ✅ green |
| 10-03-02 | 03 | 3 | ADMIN-02 | T-10-10 / T-10-13 | bounded resubscribe backoff; arrival on the server clock | bloc (`fake_async`) | `flutter test test/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit_test.dart` + analyzer gate | ✅ | ✅ green |
| 10-04-01 | 04 | 4 | ADMIN-04 | T-10-14 / T-10-15 / T-10-16 | no drop on the current city, no double drop, late responses ignored | bloc | `flutter test test/models/travel/teleport_target_test.dart test/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit_test.dart` | ✅ | ✅ green |
| 10-04-02 | 04 | 4 | ADMIN-04 | T-10-17 | `isTeleportMode` holds the result sheets during the mode | bloc | `flutter test test/screens/mainScreen/tabs/map/mapAvailabilityCubit test/screens/mainScreen/components` | ✅ | ✅ green |
| 10-05-01 | 05 | 5 | ADMIN-02 | T-10-21 | cards show names only, no account identity | widget | `flutter test test/screens/innkeeper/components/presence_label_test.dart test/screens/innkeeper/innkeeper_panel_screen_test.dart` | ✅ | ✅ green |
| 10-05-02 | 05 | 5 | ADMIN-07 | T-10-20 / T-10-19 | `FORBIDDEN` or a lost role closes the root route | widget | `flutter test test/screens/innkeeper test/screens/auth/authenticated_shell_test.dart` | ✅ | ✅ green |
| 10-05-03 | 05 | 5 | ADMIN-01, ADMIN-07 | T-10-18 | «Locanda» shown only to the innkeeper role (BE guard authoritative) | widget | `flutter test test/screens/mainScreen/tabs/settings test/screens/innkeeper` + analyzer gate | ✅ | ✅ green |
| 10-06-01 | 06 | 6 | ADMIN-03, ADMIN-05, ADMIN-06 | T-10-24 | edits clamped to the BE limits | bloc | `flutter test test/screens/innkeeper/requestCompletionCubit/request_completion_cubit_test.dart` | ✅ | ✅ green |
| 10-06-02 | 06 | 6 | ADMIN-03 | T-10-22 / T-10-23 / T-10-25 | single-flight submit, typed failures, second GM gets `NOT_FOUND` | bloc + widget | `flutter test test/screens/innkeeper/requestCompletionCubit test/shared/components/modal` + analyzer gate | ✅ | ✅ green |
| 10-07-01 | 07 | 7 | ADMIN-05, ADMIN-06 | T-10-24 | sliders/steppers bounded by the participant read | widget | `flutter test test/screens/innkeeper/components/completion_form_test.dart` | ✅ | ✅ green |
| 10-07-02 | 07 | 7 | ADMIN-03 | T-10-26 / T-10-28 | neutral confirmation before an irreversible completion; per-code copy | widget | `flutter test test/screens/innkeeper/components/completion_recap_test.dart test/screens/innkeeper/request_completion_screen_test.dart` | ✅ | ✅ green |
| 10-07-03 | 07 | 7 | ADMIN-03 | T-10-27 / T-10-29 | «Completa» disabled while travelling or busy | widget | `flutter test test/screens/innkeeper` + analyzer gate | ✅ | ✅ green |
| 10-08-01 | 08 | 8 | ADMIN-04 | T-10-30 | drag extraction keeps the own-travel drop city and gate | widget (refactor) | `flutter test test/screens/mainScreen/tabs/map` + analyzer gate | ✅ | ✅ green |
| 10-08-02 | 08 | 8 | ADMIN-04 | T-10-31 / T-10-32 | drop resolved on map coordinates; no technical text on the Map | widget | `flutter test test/screens/mainScreen/tabs/map/teleport_pawn_layer_test.dart test/screens/mainScreen/tabs/map/components/teleport_mode_chip_test.dart` | ✅ | ✅ green |
| 10-09-01 | 09 | 9 | ADMIN-04 | T-10-35 | no lore over the teleport flow | widget | `flutter test test/screens/mainScreen/tabs/map test/screens/auth` | ✅ | ✅ green |
| 10-09-02 | 09 | 9 | ADMIN-04 | T-10-33 / T-10-34 | a teleport drop never starts the GM's own travel; flag cleared on dispose | widget | `flutter test test/screens/mainScreen/tabs/map` + analyzer gate | ✅ | ✅ green |
| 10-10-01 | 10 | 10 | ADMIN-04 | T-10-36 / T-10-37 | mode cancelled off the Map tab; single panel re-push | widget | `flutter test test/screens/mainScreen` | ✅ | ✅ green |
| 10-10-02 | 10 | 10 | ADMIN-04 | T-10-38 | «Teletrasporta» reads the row before the mode | widget | `flutter test test/screens/innkeeper test/screens/mainScreen` + analyzer gate | ✅ | ✅ green |
| 10-11-01 | 11 | 11 | ADMIN-02, ADMIN-03 | T-10-39 | `pendingQuest` selected only after the block-level BE gate; schema check 42/42 OK on `4dc7e89` | unit + cross-repo | `flutter test` + schema check of the plan `<interfaces>` | ✅ | ✅ green |
| 10-11-02 | 11 | 11 | ADMIN-01..08 | T-10-40 / T-10-41 / T-10-42 | device E2E on Android against BE `develop` | manual | `test -f .planning/phases/10-admin-panel-innkeeper/10-HUMAN-UAT.md` | ✅ | ✅ green (device E2E 2026-11-01, approved) |
| 10-11-03 | 11 | 11 | ADMIN-01..08 | T-10-42 / T-10-43 | requirements ticked only for passed steps | manual (record) | grep on `10-HUMAN-UAT.md`, `REQUIREMENTS.md`, `BACKEND-NOTES.md` (plan Task 3) | ✅ | ✅ green (device E2E 2026-11-01, approved) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

Gate outputs of 10-11 Task 1 (2026-11-01, BE `origin/develop` = `4dc7e89`): `pendingQuest: ID` inside `type PendingRequestCharacter`; `dumped 42 documents`, 42 `OK` / 0 failures; `flutter test` 2833 passed; analyzer 51 issues, 0 errors, 0 warnings.

---

## Wave 0 Requirements

- [x] `test/helpers/mocks.dart` — `MockInnkeeperRepository`, `MockTeleportModeCubit` and the queue/completion mocks shared by the phase
- [x] `test/helpers/fixtures/pending_request_fixtures.dart` — queue entries as the FE selects them, worldMission entries, participant reads, merged BE shape (`mergedPendingRequestJson`, 10-11)
- [x] `test/helpers/fixtures/travel_fixtures.dart` — `awaitingAidJson` re-exported for the queue
- [x] Settings harness — `AuthCubit` stubbed as adventurer so the pre-existing Settings tests stay green with the role gate (10-05)
- [x] Map/MainScreen harness — `TeleportModeCubit`/`AuthCubit` providers in `main_screen_test.dart` and the shared `WorldMap` harness (`world_map_travel_test.dart`) (10-09, 10-10)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `pendingRequests` as an adventurer answers `FORBIDDEN` | ADMIN-07 | the role guard lives in the BE; needs a real adventurer bearer | curl with the dev-bypass adventurer bearer (placeholders), `10-HUMAN-UAT.md` step 8 |
| completions and teleports leave audit rows | ADMIN-08 | written server-side in `admin_audit_logs` | mongosh `admin_audit_logs` query of `10-HUMAN-UAT.md` step 9 (user's own shell) |
| full panel flow on the device | ADMIN-01..08 | live BE, real role promotion, push sheets on other devices | `10-HUMAN-UAT.md` steps 1–10 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [ ] Feedback latency < 10s (quick runs yes; the full suite takes ~70 s)
- [x] `nyquist_compliant: true` set in frontmatter (after the device E2E, plan 10-11 Task 3)

**Approval:** approved 2026-11-01 (device E2E 10/10 pass, `10-HUMAN-UAT.md`; after the UAT fixes `flutter test` 2852 passed, analyzer 51 issues / 0 errors / 0 warnings)
