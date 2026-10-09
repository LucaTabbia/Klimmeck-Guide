---
phase: 2
slug: character-creation
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-10-09
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Flutter 3.35.5) + bloc_test 10.0.0 + mocktail 1.0.5 |
| **Config file** | none (`analysis_options.yaml` for lints) |
| **Quick run command** | `flutter test <test files touched by the task>` (each task's `<verify>`) |
| **Full suite command** | `flutter test` (baseline 283 tests, all green) |
| **Lint gate** | `flutter analyze lib test` — baseline 12 pre-existing issues, must not grow (D-34) |
| **Format gate** | `dart format --output=none --set-exit-if-changed <touched files>` — never on directories (D-25) |
| **Estimated runtime** | quick ~2–5 s; full ~15–20 s |

---

## Sampling Rate

- **After every task commit:** the task's `<verify>` command + format check on touched files
- **After every plan wave:** `flutter test` (full) + `flutter analyze lib test`
- **Before `/gsd-verify-work`:** full suite green, analyze ≤ 12, manual UAT (02-11 Task 2) approved
- **Max feedback latency:** ~20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 1 | CHAR-06 | T-02-01-04 | Deferral recorded, not silently dropped | doc check | `grep -n "CHAR-06" .planning/REQUIREMENTS.md .planning/ROADMAP.md` | ✅ | ⬜ pending |
| 2-01-02 | 01 | 1 | CHAR-05 | T-02-01-01..03 | No secrets; single-purpose permissions; pinned dependency | config | `grep -A3 "^  image_picker:" pubspec.lock && plutil -lint ios/Runner/Info.plist && flutter test` | ✅ | ⬜ pending |
| 2-01-03 | 01 | 1 | CHAR-05 | — | N/A (test infra) | unit | `flutter test test/helpers/fakes/scripted_http_client_adapter_test.dart` | ❌ W0 | ⬜ pending |
| 2-02-01 | 02 | 1 | CHAR-07 | T-02-02-01/02 | adoptUser only for same authenticated id, token unchanged | unit + bloc | `flutter test test/repository/services/auth/ test/screens/auth/cubit/auth_cubit_test.dart` | ✅ extend + ❌ new | ⬜ pending |
| 2-02-02 | 02 | 1 | CHAR-01, CHAR-07 | T-02-02-03 | Gate never strands the user after creation | widget | `flutter test test/screens/auth/auth_gate_test.dart` | ✅ extend | ⬜ pending |
| 2-03-01 | 03 | 1 | CHAR-03 | T-02-03-01/04 | Variables map only; no race table in lib/ | unit | `flutter test test/models` | ❌ new | ⬜ pending |
| 2-03-02 | 03 | 1 | CHAR-02, CHAR-03, CHAR-04 | T-02-03-03 | Lengths counted in UTF-16 like the backend | unit | `flutter test test/screens/characterCreation/cubit/character_draft_test.dart` | ❌ new | ⬜ pending |
| 2-04-01 | 04 | 1 | CHAR-09 | — | Inline errors use errorText (no technical UI) | unit | `flutter test test/theme/kg_theme_test.dart` | ❌ new | ⬜ pending |
| 2-04-02 | 04 | 1 | CHAR-05 | T-02-04-01/02 | Silent silhouette fallback on decode failure | widget | `flutter test test/shared/components/character_portrait_test.dart` | ❌ new | ⬜ pending |
| 2-05-01 | 05 | 2 | CHAR-05 | T-02-05-01/04/05/06 | Bearer on upload; url required; 30 s timeouts; no logging | unit (fake dio) | `flutter test test/repository/services/rest/rest_upload_test.dart` | ❌ new | ⬜ pending |
| 2-05-02 | 05 | 2 | CHAR-05 | T-02-05-02/03 | Downscale 1024/q85; no full metadata | unit | `flutter test test/repository/services/image/image_picker_portrait_picker_test.dart` | ❌ new | ⬜ pending |
| 2-06-01 | 06 | 2 | CHAR-07, CHAR-03 | T-02-06-01 | Named static documents, variables only | unit | `flutter test test/graphql test/repository/services/auth` | ❌ new | ⬜ pending |
| 2-06-02 | 06 | 2 | CHAR-09 | T-02-06-02 | Codes only, never messages; HTTP 400 path read | unit | `flutter test test/repository/character_creation_failure_test.dart` | ❌ new | ⬜ pending |
| 2-06-03 | 06 | 2 | CHAR-07, CHAR-03 | T-02-06-03/04 | No userId in input; unknown races skipped | unit (Link.function) | `flutter test test/repository/services/graphql/graphql_character_creation_test.dart` | ❌ new | ⬜ pending |
| 2-07-01 | 07 | 3 | CHAR-05, CHAR-09 | T-02-07-01 | Only domain failures leave the repository | unit | `flutter test test/repository/character_creation_repository_test.dart` | ❌ new | ⬜ pending |
| 2-07-02 | 07 | 3 | CHAR-02, CHAR-03, CHAR-04, CHAR-05, CHAR-08 | T-02-07-02/03 | No stuck loading; no upload at pick time | bloc_test | `flutter test test/screens/characterCreation/cubit/` | ❌ new | ⬜ pending |
| 2-08-01 | 08 | 4 | CHAR-05, CHAR-07, CHAR-09 | T-02-08-02/04/05 | URL reuse keyed by file; no double submit | bloc_test | `flutter test test/screens/characterCreation/cubit/character_creation_cubit_test.dart` | ✅ extend | ⬜ pending |
| 2-08-02 | 08 | 4 | CHAR-07, CHAR-09 | T-02-08-01 | CHARACTER_ALREADY_EXISTS never strands the user | bloc_test | `flutter test test/screens/characterCreation/cubit/` | ✅ extend | ⬜ pending |
| 2-09-01 | 09 | 5 | CHAR-02, CHAR-04, CHAR-09 | T-02-09-01 | Italian domain copy only | unit + widget | `flutter test test/screens/characterCreation/components/character_creation_messages_test.dart test/screens/characterCreation/components/sheet_components_test.dart` | ❌ new | ⬜ pending |
| 2-09-02 | 09 | 5 | CHAR-05, CHAR-09 | T-02-09-03 | Progress only inside Crea | widget | `flutter test test/screens/characterCreation/components/portrait_column_test.dart test/screens/characterCreation/components/submit_bar_test.dart` | ❌ new | ⬜ pending |
| 2-09-03 | 09 | 5 | CHAR-02..05, CHAR-07..09 | T-02-09-02/04 | adoptUser once; Esci needs confirmation; no overflow in landscape | widget | `flutter test test/screens/characterCreation/` | ❌ new | ⬜ pending |
| 2-10-01 | 10 | 6 | CHAR-01 | T-02-10-03 | Branch re-evaluated on every gate rebuild | widget | `flutter test test/screens/auth/session_home_test.dart` | ❌ new | ⬜ pending |
| 2-10-02 | 10 | 6 | CHAR-01, CHAR-07 | T-02-10-01 | No hardcoded character id | widget | `flutter test test/screens/auth test/screens/mainScreen && ! grep -rn "68c191de541d89c481b8322b" lib` | ✅ extend + ❌ new | ⬜ pending |
| 2-10-03 | 10 | 6 | CHAR-05, CHAR-07 | T-02-10-05 | Profile portrait only via CharacterPortrait; silhouette when imagePath is null | widget | `flutter test test/screens/mainScreen/tabs/profile/components/profile_image_test.dart && ! grep -rn "silhouette.jpeg" lib/screens/mainScreen/tabs/profile` | ❌ new | ⬜ pending |
| 2-11-01 | 11 | 7 | CHAR-03, CHAR-07, CHAR-09 | T-02-11-01/02 | Contract names equal to the BE schema | schema check | `grep -q "createCharacter(input: CreateCharacterInput!): User!" ../../Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/schema.gql && flutter test` | ✅ | ⬜ pending |
| 2-11-02 | 11 | 7 | CHAR-01, CHAR-05, CHAR-07 | T-02-11-03/04 | Manual E2E against BE 02.1 | manual | see Manual-Only below | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `pubspec.yaml` / `pubspec.lock` — image_picker 1.2.2 (02-01 Task 2)
- [ ] `.fvmrc` 3.35.5; Android `minSdk = flutter.minSdkVersion`; iOS 13.0 + usage descriptions (02-01 Task 2)
- [ ] `test/helpers/landscape.dart` — `useLandscapePhone` (02-01 Task 3)
- [ ] `test/helpers/fakes/scripted_http_client_adapter.dart` — dio adapter with JSON bodies (02-01 Task 3)
- [ ] `test/helpers/auth_fixtures.dart` — `buildTestUserWithCharacter`, `testCharacterId` (02-01 Task 3)
- [ ] Feature-specific mocks are added by the plan that creates each type (never redefined per file): `MockImagePicker`, `MockPortraitPicker` (02-05), `MockCharacterCreationRepository` (02-07), `MockCharacterCreationCubit`, `MockAuthCubit` (02-09), `MockCharacterCubit`, `MockQuestCubit`, `MockMainScreenCubit` (02-10); race fixture `test/helpers/fixtures/race_traits_fixture.dart` (02-03)

*RED tests are written as the first step of every TDD task (committed failing), so the suite never carries non-compiling stubs between plans.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cold start with `currentCharacter: null` lands on the sheet; "Crea" enters the shell showing the new character | CHAR-01, CHAR-07 | Needs the running BE 02.1 + dev Mongo state | 02-11 Task 2 steps 1, 6 |
| Portrait upload reaches Cloudinary and is shown in the shell | CHAR-05 | Needs real Cloudinary keys in the BE `.env` | 02-11 Task 2 steps 5–6 |
| "Nome già in uso" from the real backend with data preserved | CHAR-09 | Needs a second character in the DB | 02-11 Task 2 step 7 |
| Gallery/camera pickers and permission denial on a real device | CHAR-05 | Native OS UI | 02-11 Task 2 step 9 (optional) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 20s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
