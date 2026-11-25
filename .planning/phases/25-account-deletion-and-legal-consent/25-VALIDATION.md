---
phase: 25
slug: account-deletion-and-legal-consent
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-11-24
---

# Phase 25 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` + `bloc_test` 10.0.0 + `mocktail` 1.0.5 (Flutter 3.35.5) |
| **Config file** | none (`analysis_options.yaml` with `flutter_lints`) |
| **Quick run command** | `flutter test <paths of the task>` (each task's `<verify>`) |
| **Full suite command** | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` — only in 25-01 (baseline) and 25-07 (gate), alone in its Bash call, timeout ≥ 300000 ms |
| **Analyzer gate** | `OUT=$(flutter analyze --no-fatal-infos 2>&1); echo "$OUT" \| tail -1; ! echo "$OUT" \| grep -qE '^ *(error\|warning) •' && echo "$OUT" \| grep -qE '^47 issues found' && echo ANALYZE_GATE_OK` |
| **Schema check** | `dart run tool/schema_check/dump_documents.dart <dir>` + `NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js <schema.gql> <dir>` on `origin/develop:src/schema.gql` (25-07, 25-08) |
| **Suite baseline** | **5549 green** (measured by 25-01 Task 1 on this branch on 2026-11-25, `01:52 +5549: All tests passed!`; 5535 at the close of Phase 24) |
| **Estimated runtime** | ~25 seconds per task command |

---

## Sampling Rate

- **After every task commit:** the task's `<verify>` command + the analyzer gate + the trailer check
- **After every plan wave:** the test directories named in the plan's `<verification>`
- **Before `/gsd-verify-work`:** schema check 57 × OK on the merged BE Phase 26 SDL, full suite green, analyzer at 47, `tool/hardening_check.sh` clean
- **Max feedback latency:** 25 seconds (loopback WS tests of `test/repository/services/auth` excepted)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 25-01-01 | 01 | 1 | CONSENT-01 | T-25-01, T-25-04 | only constant legal URIs; `LinkOpener` moved with imports only | unit | `flutter test test/config/legal_documents_test.dart test/repository/services/push test/screens/signIn` | ❌ W0 | ✅ green |
| 25-01-02 | 01 | 1 | CONSENT-02 | T-25-03 | version stored per device, no secret; store allowed by the hardening check | unit + bloc | `flutter test test/repository/storage/legal_consent_store_test.dart test/screens/signIn/consentCubit && bash tool/hardening_check.sh` | ❌ W0 | ✅ green |
| 25-01-03 | 01 | 1 | CONSENT-01, CONSENT-02 | T-25-01, T-25-02 | login disabled while unticked; links through the Cubit | widget | `flutter test test/screens/signIn test/screens/auth/auth_gate_test.dart test/screens/auth/auth_gate_dev_bypass_test.dart test/screens/auth/identity_transitions_test.dart test/screens/auth/authenticated_shell_leak_test.dart` | ✅ extend | ✅ green |
| 25-01-04 | 01 | 1 | — | — | bookkeeping | docs | `test -f .planning/phases/25-account-deletion-and-legal-consent/25-01-SUMMARY.md` | — | ✅ green |
| 25-02-01 | 02 | 2 | ACCOUNT-02 | T-25-10, T-25-11, T-25-13 | `accountDeleted` from HTTP refresh and WS 4409; unknown reason → `sessionExpired` | unit + loopback WS | `flutter test test/repository/services/auth` | ✅ extend | ✅ green |
| 25-02-02 | 02 | 2 | ACCOUNT-02, CONSENT-02 | T-25-12 | notice D-03; consent forgotten only on `accountDeleted` | widget + bloc | `flutter test test/screens/signIn test/screens/auth/auth_gate_test.dart` | ✅ extend | ✅ green |
| 25-02-03 | 02 | 2 | — | — | bookkeeping | docs | `test -f .planning/phases/25-account-deletion-and-legal-consent/25-02-SUMMARY.md` | — | ✅ green |
| 25-03-01 | 03 | 3 | ACCOUNT-01, ACCOUNT-02 | T-25-21, T-25-22, T-25-24, T-25-25 | no BE call after success; one terminal state under the race; codes only | unit + integration (fakes) | `flutter test test/repository/account_deletion_failure_test.dart test/repository/account_deletion_repository_test.dart test/repository/account_deletion_flow_test.dart` | ❌ W0 | ✅ green |
| 25-03-02 | 03 | 3 | ACCOUNT-01 | T-25-20, T-25-24 | double tap ignored; no endless spinner | bloc + unit | `flutter test test/screens/mainScreen/tabs/settings/accountDeletionCubit test/screens/mainScreen/tabs/settings/components/account_deletion_messages_test.dart` | ❌ W0 | ✅ green |
| 25-03-03 | 03 | 3 | ACCOUNT-01 | T-25-20, T-25-23, T-25-25 | button last, hidden for the innkeeper, behind the switch | widget | `flutter test test/config/account_deletion_test.dart test/screens/mainScreen/tabs/settings` | ✅ extend / ❌ W0 | ✅ green |
| 25-03-04 | 03 | 3 | — | — | bookkeeping | docs | `test -f .planning/phases/25-account-deletion-and-legal-consent/25-03-SUMMARY.md` | — | ✅ green |
| 25-04-01 | 04 | 4 | ACCOUNT-03 | T-25-31, T-25-32, T-25-33 | codes only; username never logged | unit + bloc | `flutter test test/repository/player_account_deletion_failure_test.dart test/repository/player_account_deletion_repository_test.dart test/screens/mainScreen/tabs/settings/playerDeletionCubit test/screens/mainScreen/tabs/settings/components/player_account_deletion_messages_test.dart` | ❌ W0 | ✅ green |
| 25-04-02 | 04 | 4 | ACCOUNT-03 | T-25-30, T-25-33, T-25-34 | confirmation names the username; field only in a dialog; landscape + keyboard | widget | `flutter test test/screens/mainScreen/tabs/settings` | ✅ extend / ❌ W0 | ✅ green |
| 25-04-03 | 04 | 4 | — | — | bookkeeping | docs | `test -f .planning/phases/25-account-deletion-and-legal-consent/25-04-SUMMARY.md` | — | ✅ green |
| 25-05-01 | 05 | 5 | CONSENT-03 | T-25-40, T-25-43 | `termsVersion` on the start URL; dev bypass exempt | unit + bloc + widget | `flutter test test/repository/services/auth test/screens/signIn test/screens/auth` | ✅ extend | ✅ green |
| 25-05-02 | 05 | 5 | CONSENT-03 | T-25-40, T-25-41 | `terms_not_accepted` → its own failure and line | unit + bloc + widget | `flutter test test/repository/services/auth test/screens/signIn` | ✅ extend | ✅ green |
| 25-05-03 | 05 | 5 | — | — | bookkeeping | docs | `test -f .planning/phases/25-account-deletion-and-legal-consent/25-05-SUMMARY.md` | — | ✅ green |
| 25-06-01 | 06 | 6 | ACCOUNT-04 | T-25-50 | served lane, place and refunds drawn, nothing computed | bloc + widget | `flutter test test/screens/mainScreen/characterCubit test/screens/mainScreen/tabs/map/quest_paper_layer_test.dart test/screens/mainScreen/tabs/map/character_marker_layer_test.dart test/screens/mainScreen/tabs/map/mapAvailabilityCubit test/screens/mainScreen/components/travel_outcome_listener_test.dart test/screens/mainScreen/components/quest_abandon_outcome_listener_test.dart test/screens/mainScreen/components/party_watch_listener_test.dart` | ✅ extend | ✅ green |
| 25-06-02 | 06 | 6 | ACCOUNT-04 | T-25-51, T-25-52 | Board reread; push body verbatim; no placeholder | unit + widget | `flutter test test/screens/mainScreen/components/quest_scope_listener_test.dart test/models/quest/quest_availability_test.dart test/repository/services/push/foreground_push_events_test.dart test/repository/services/push/notification_tap_router_test.dart test/screens/auth/inAppNotificationsCubit` | ✅ extend | ✅ green |
| 25-06-03 | 06 | 6 | — | — | bookkeeping | docs | `test -f .planning/phases/25-account-deletion-and-legal-consent/25-06-SUMMARY.md` | — | ✅ green |
| 25-07-01 | 07 | 7 | ACCOUNT-05 | T-25-60, T-25-61, T-25-62 | gate before any document; names confirmed on the merged BE | gate + unit | `flutter test test/graphql test/tool test/repository/services/account` (after `GATE_OK`) | ❌ W0 (gated) | ⬜ pending |
| 25-07-02 | 07 | 7 | ACCOUNT-01, ACCOUNT-03 | T-25-60 | providers + switch on only after the gate | widget | `flutter test test/screens/auth test/config test/screens/mainScreen/tabs/settings` | ✅ extend | ⬜ pending |
| 25-07-03 | 07 | 7 | ACCOUNT-05 | T-25-63 | 57 × OK, full suite, hardening; names only in the notes | gate | schema check block of 25-07 | ✅ tooling | ⬜ pending |
| 25-07-04 | 07 | 7 | — | — | bookkeeping | docs | `test -f .planning/phases/25-account-deletion-and-legal-consent/25-07-SUMMARY.md` | — | ⬜ pending |
| 25-08-01 | 08 | 8 | ACCOUNT-05 | T-25-70, T-25-73 | gate re-check; no secrets in the record | gate + docs | gate re-check block of 25-08 | — | ⬜ pending |
| 25-08-02 | 08 | 8 | all eight | T-25-72 | device, DB, legal repo are the orchestrator's | manual | device E2E (`25-HUMAN-UAT.md`) | — | ⬜ pending |
| 25-08-03 | 08 | 8 | all eight | T-25-71 | mark-complete only per passed steps | docs | `grep -q "^status: " .planning/phases/25-account-deletion-and-legal-consent/25-HUMAN-UAT.md` | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Each new test file is written RED-first inside the task that needs it (no separate scaffold plan):

- [x] `test/config/legal_documents_test.dart` (25-01-01)
- [x] `test/repository/storage/legal_consent_store_test.dart`, `test/screens/signIn/consentCubit/legal_consent_cubit_test.dart`, `test/helpers/fakes/in_memory_legal_consent_store.dart` (25-01-02)
- [x] `test/helpers/fakes/fake_account_deletion_api.dart`, `test/repository/account_deletion_failure_test.dart`, `test/repository/account_deletion_repository_test.dart`, `test/repository/account_deletion_flow_test.dart` (25-03-01)
- [x] `test/screens/mainScreen/tabs/settings/accountDeletionCubit/account_deletion_cubit_test.dart`, `test/screens/mainScreen/tabs/settings/components/account_deletion_messages_test.dart` (25-03-02)
- [x] `test/config/account_deletion_test.dart` (25-03-03)
- [x] `test/repository/player_account_deletion_failure_test.dart`, `test/repository/player_account_deletion_repository_test.dart`, `test/screens/mainScreen/tabs/settings/playerDeletionCubit/player_account_deletion_cubit_test.dart`, `test/screens/mainScreen/tabs/settings/components/player_account_deletion_messages_test.dart` (25-04-01)
- [x] `test/screens/mainScreen/tabs/settings/components/player_account_deletion_dialog_test.dart` (25-04-02)
- [ ] `test/graphql/account_documents_test.dart`, `test/repository/services/account/graphql_account_deletion_api_test.dart` (25-07-01, gated)
- [ ] mocks in `test/helpers/mocks.dart`: `MockAccountDeletionRepository`, `MockAccountDeletionCubit` (25-03), `MockPlayerAccountDeletionRepository`, `MockPlayerAccountDeletionCubit` (25-04)
- [x] suite baseline re-measured (25-01-01)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Links open the public pages in the external browser | CONSENT-01 | real browser and network | `25-HUMAN-UAT.md` step 2 |
| BE records version and date of the acceptance | CONSENT-03 | real Twitch login, DB read by the orchestrator | step 3 |
| Own deletion lands on the notice; the companion of a started quest goes back to the city refunded, the quest back on the Board | ACCOUNT-02, ACCOUNT-04 | real BE transaction, two devices/identities, push | step 7 |
| Same Twitch account starts from zero | ACCOUNT-02 | real BE (D-04) | step 8 |
| Innkeeper refusals and deletion of an online player | ACCOUNT-03, ACCOUNT-02 | real Twitch lookup, two devices | steps 9, 10 |
| Not-started quest keeps waiting with one seat less | ACCOUNT-04 | real BE | step 11 |
| Two privacy lines of D-22 in `privacy.md` | ACCOUNT-05 | public legal repo, orchestrator's personal identity; no executor touches it | orchestrator closing item, recorded in `25-HUMAN-UAT.md` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 25s (loopback WS auth tests excepted)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
