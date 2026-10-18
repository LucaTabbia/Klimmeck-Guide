---
phase: 4
slug: settings-screen
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-10-16
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` + `bloc_test` 10.0.0 + `mocktail` 1.0.5 (+ `fake_async` 1.3.3 if timers appear) — all already in `pubspec.yaml` |
| **Config file** | none — shared mocks in `test/helpers/mocks.dart`, fakes in `test/helpers/fakes/`, fixtures in `test/helpers/fixtures/` |
| **Quick run command** | `flutter test <the task's test file(s)>` |
| **Full suite command** | `flutter test` (baseline 645 tests, ~19 s) + `flutter analyze` (baseline 57 issues: 0 errors, 4 warnings, 53 infos — must not grow) + `dart format --output=none --set-exit-if-changed <each touched file>` (single files only, never a directory) |
| **Estimated runtime** | quick ~3–8 s per file; full ~19 s |

---

## Sampling Rate

- **After every task commit:** run the task's `<verify><automated>` command (targeted test files) + `flutter analyze <touched files>` + `dart format --output=none --set-exit-if-changed <touched files>`
- **After every plan wave:** `flutter test test/screens/mainScreen test/repository test/graphql test/shared/components/modal test/theme test/tool test/screens/auth test/models`
- **Before `/gsd-verify-work`:** full `flutter test` green (> 645), `flutter analyze` total ≤ 57 with 0 errors, schema check green against the BE schema (plan 07), manual E2E checklist done — all before the PR is opened (BE PR 03.1 on `develop` first, D-20)
- **Max feedback latency:** ~10 s per task

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 1 | SET-01 | T-04-01-02 | one table drives pages; pageIndex 0..6 unique, no cell overlap | unit | `flutter test test/screens/mainScreen/components/satchel_layout_test.dart` | ✅ | ✅ green |
| 4-01-02 | 01 | 1 | SET-01 | T-04-01-01 | overlay fits 667x375 (adaptive cells) | widget | `flutter test test/screens/mainScreen/components/menu_background_test.dart test/screens/mainScreen/main_screen_test.dart` | ✅ | ✅ green |
| 4-01-03 | 01 | 1 | SET-01 | T-04-01-02 | items land on their own cell; tap → right page | widget | `flutter test test/screens/mainScreen` | ✅ | ✅ green |
| 4-02-01 | 02 | 1 | SET-02, SET-03, SET-05 | — | theme tokens only (no per-widget colours) | widget (theme) | `flutter test test/theme/kg_theme_test.dart` | ✅ | ✅ green |
| 4-02-02 | 02 | 1 | SET-03, SET-05 | T-04-02-01, T-04-02-02 | barrier non-dismissible; dialog returns bool, reads no cubit | widget | `flutter test test/shared/components/modal` | ✅ | ✅ green |
| 4-03-01 | 03 | 1 | SET-02, SET-04 | T-04-03-01, T-04-03-02, T-04-03-04, T-04-03-05 | per-user keys; no clear API; wrong type → error; Async API only | unit | `flutter test test/models/notification_category_test.dart test/repository/storage/notification_preferences_store_test.dart` | ✅ | ✅ green |
| 4-03-02 | 03 | 1 | SET-02, SET-04 | T-04-03-03 | revert only the failing category; logs runtimeType only | cubit (bloc_test) | `flutter test test/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit_test.dart` | ✅ | ✅ green |
| 4-04-01 | 04 | 1 | SET-05 | T-04-04-01, T-04-04-04, T-04-04-05 | argument-less document; malformed payload → FormatException; listed for schema check | unit (document + Link.function) | `flutter test test/graphql test/tool test/repository/services/graphql` | ✅ | ✅ green |
| 4-04-02 | 04 | 1 | SET-05 | T-04-04-02 | mapping by `extensions.code` only | unit | `flutter test test/repository/character_deletion_failure_test.dart test/repository/character_deletion_repository_test.dart` | ✅ | ✅ green |
| 4-04-03 | 04 | 1 | SET-05 | T-04-04-03, T-04-04-06 | single call in flight; never stuck deleting; NOT_FOUND → `me` | cubit (bloc_test) | `flutter test test/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit_test.dart` | ✅ | ✅ green |
| 4-05-01 | 05 | 2 | SET-05 | T-04-05-01 | adoptUser keeps the id guard and accepts `currentCharacter: null` | unit (characterization) | `flutter test test/repository/services/auth/session_auth_token_service_adopt_user_test.dart test/repository/services/auth/dev_auth_token_service_transitions_test.dart` | ✅ | ✅ green |
| 4-05-02 | 05 | 2 | SET-02, SET-04, SET-05 | T-04-05-01, T-04-05-02, T-04-05-03, T-04-05-04 | cubits closed with the shell; hand-over once; refusal → handoverRejected | widget | `flutter test test/screens/auth test/app` | ✅ | ✅ green |
| 4-06-01 | 06 | 3 | SET-02 | T-04-06-04 | switches inert, no spinner until loaded; no permission hint | widget | `flutter test test/screens/mainScreen/tabs/settings/components/notification_preferences_section_test.dart` | ✅ | ✅ green |
| 4-06-02 | 06 | 3 | SET-03, SET-05 | T-04-06-01, T-04-06-02, T-04-06-03 | confirm before delete; disabled in flight; domain copy by code; logout via confirmLogout | widget | `flutter test test/screens/mainScreen/tabs/settings/components/account_section_test.dart` | ✅ | ✅ green |
| 4-06-03 | 06 | 3 | SET-01, SET-02, SET-03, SET-05 | — | no AppBar/Scaffold in the tab; page 6 wired with length assert | widget | `flutter test test/screens/mainScreen` | ✅ | ✅ green |
| 4-07-01 | 07 | 4 | SET-01..SET-05 (D-20) | T-04-07-01, T-04-07-02 | every document validates against the BE schema; gates green | scripted gate | `flutter test` + `tool/schema_check` (dump + `validate_documents.js` against BE `origin/develop:src/schema.gql`) | ✅ tooling | ✅ green |
| 4-07-02 | 07 | 4 | SET-01..SET-05 | T-04-07-03, T-04-07-04 | E2E on device; same-name recreate; notes without secrets | manual (checkpoint) | `grep -c "result: \(pass\|fail\|skipped\)" .planning/phases/04-settings-screen/04-HUMAN-UAT.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*(Requirement → test mapping source: `04-RESEARCH.md` §Validation Architecture. Every task has an automated command; no 3 consecutive tasks lack one.)*

---

## Wave 0 Requirements

Created inside the plan that first needs them (each as the RED step of its task):

- [x] `test/helpers/fakes/fake_shared_preferences_async.dart` — in-memory `Fake implements SharedPreferencesAsync`, failure injection via final lists (plan 03, task 1)
- [x] `test/helpers/fakes/in_memory_notification_preferences_store.dart` — cubit/widget/shell fake with `failNextWrite` / `readFailure` / `readGate` (plan 03, task 2). Replaces the `MockNotificationPreferencesStore` suggested by research: a stateful fake covers every use.
- [x] `test/helpers/mocks.dart` — `MockCharacterDeletionRepository` (plan 04, task 2); `MockNotificationPreferencesCubit`, `MockCharacterDeletionCubit` (plan 06, task 1)
- [ ] Failing-first tests (Red) for every new unit in the map before its implementation (TDD, `docs/rules/testing.md`); 4-05-01 is a characterization test of existing behaviour (expected green at once)
- [x] `tool/schema_check/schema_check_documents.dart` — `DeleteCharacter` listed in the same commit as the document (plan 04, task 1)
- [x] `test/screens/auth/authenticated_shell_test.dart` — construction site updated for `notificationPreferencesStore` and `userId` (plan 05, task 2)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Settings is the 7th satchel entry with the real `settings_linee3.svg` icon and opens the tab on a real device (landscape) | SET-01 | real overlay geometry, flight animation and SVG rendering | 04-HUMAN-UAT steps 1–2 (step 12 optional for ~667 px wide screens) |
| Toggles survive app kill/relaunch and logout/login of the same user; a second account has its own | SET-02, SET-04 | real `shared_preferences` on device, process kill | 04-HUMAN-UAT steps 3–4 (step 11 optional) |
| Logout from Settings returns to sign-in | SET-03 | full session teardown on device | 04-HUMAN-UAT step 4 |
| Delete → creation page → create with the SAME name → game shell; archive fields in Mongo | SET-05 | needs the real BE (`deleteCharacter`, name release) | 04-HUMAN-UAT steps 5, 7–9, recorded in `BACKEND-NOTES.md` §6 |
| Airplane mode during delete; `userUpdated` backup path | SET-05 | real network timing and BE change stream | 04-HUMAN-UAT steps 6 and 10 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-10-16; manual E2E (row 4-07-02) recorded 2026-10-18
