---
phase: 4
slug: settings-screen
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-16
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` + `bloc_test` 10.0.0 + `mocktail` 1.0.5 (+ `fake_async` 1.3.3 if timers appear) — all already in `pubspec.yaml` |
| **Config file** | none — shared mocks in `test/helpers/mocks.dart`, fakes in `test/helpers/fakes/`, fixtures in `test/helpers/fixtures/` (Wave 0 adds the `SharedPreferencesAsync` fake and the notification-preferences store fake) |
| **Quick run command** | `flutter test <the task's test file(s)>` |
| **Full suite command** | `flutter test` (baseline 645 tests, ~19 s) + `flutter analyze` (baseline 57 issues: 0 errors, 4 warnings, 53 infos — must not grow) + `dart format --output=none --set-exit-if-changed <each touched file>` (single files only, never a directory) |
| **Estimated runtime** | quick ~3–8 s per file; full ~19 s |

---

## Sampling Rate

- **After every task commit:** run the task's `<verify><automated>` command (targeted test files) + `flutter analyze <touched files>` + `dart format --output=none --set-exit-if-changed <touched files>`
- **After every plan wave:** `flutter test test/screens/mainScreen test/repository/storage test/repository/services/graphql test/graphql test/shared/components/modal test/theme test/tool test/screens/auth`
- **Before `/gsd-verify-work`:** full `flutter test` green (≥ 645 + new tests), `flutter analyze` total ≤ 57 with 0 errors, schema check green against `Klimmeck-Guide-BE/src/schema.gql` (last plan), manual E2E checklist done — all before the PR is opened (BE PR 03.1 already merged, D-20)
- **Max feedback latency:** ~10 s per task

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 1 | SET-01 | — | N/A | unit | `flutter test test/screens/mainScreen/components/satchel_layout_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*(The planner fills this map from the plans' tasks; the requirement → test mapping is in `04-RESEARCH.md` §Validation Architecture.)*

---

## Wave 0 Requirements

- [ ] `test/helpers/fakes/fake_shared_preferences_async.dart` — in-memory `Fake implements SharedPreferencesAsync` with failure injection
- [ ] `test/helpers/fakes/in_memory_notification_preferences_store.dart` — cubit/widget-level fake with `failNextWrite` / `readFailure` (pattern of `in_memory_session_store.dart`)
- [ ] `test/helpers/mocks.dart` — `MockCharacterDeletionRepository`, `MockCharacterDeletionCubit`, `MockNotificationPreferencesCubit`, `MockNotificationPreferencesStore`
- [ ] Failing-first tests (Red) for every new unit in the map before its implementation (TDD, `docs/rules/testing.md`)
- [ ] `tool/schema_check/schema_check_documents.dart` — list `DeleteCharacter` in the same commit as the document

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Settings is the 7th satchel entry and opens the tab on a real device (landscape, both widths) | SET-01 | real overlay geometry and SVG rendering | open the satchel, tap "Impostazioni" |
| Toggles survive app kill/relaunch and logout/login of the same user | SET-04 | real `shared_preferences` on device, process kill | toggle, kill, relaunch, verify; logout, login, verify |
| Delete → creation page → create a character with the SAME name → game shell | SET-05 | needs the real BE (`deleteCharacter`, name release) | last plan's E2E checklist, recorded in `BACKEND-NOTES.md` |
| Double tap / stale state / airplane mode during delete | SET-05 | real network timing and BE concurrency | last plan's E2E checklist |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
