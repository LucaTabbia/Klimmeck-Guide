---
phase: 22
slug: companion-defeat-rest-and-recovery
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-11-14
---

# Phase 22 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + bloc_test + mocktail + fake_async (existing harness `test/helpers/`) |
| **Config file** | none — no install |
| **Quick run command** | `flutter test <touched test paths>` |
| **Full suite command** | `flutter test -r expanded 2>&1 | tr '\r' '\n' | grep -E '\[E\]|All tests passed|Some tests failed'` |
| **Estimated runtime** | ~120 seconds per targeted run; full suite only in 22-16 (timeout ≥ 300000 ms) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test <touched test paths>`
- **After every plan wave:** Run the test directories named in the plan's `<verification>` (the full suite runs only in the gate plan 22-16, REPO-RULES)
- **Before `/gsd-verify-work`:** Full suite green and schema check 55 × OK (22-16), device E2E (22-17)
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 22-01-01 | 01 | 1 | PET-01..PET-09 | T-22-04 | requirements Pending only; no mark-complete | docs | `grep -cE '^\| PET-0[1-9] \| Phase 22 \| Pending \|$' .planning/REQUIREMENTS.md (= 9)` | ✅ | ✅ green |
| 22-01-02 | 01 | 1 | PET-01 | T-22-01, T-22-02 | new fields lenient, nothing selected | unit | `flutter test test/models test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/shop` | ✅ extend | ✅ green |
| 22-01-03 | 01 | 1 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 01 of 17" .planning/STATE.md` | — | ✅ green |
| 22-02-01 | 02 | 2 | PET-01 | T-22-05, T-22-07 | vitality only from served dates, never recoveryTime | unit | `flutter test test/models/companion` | ✅ | ✅ green |
| 22-02-02 | 02 | 2 | PET-05 | T-22-06, T-22-08 | character-name rules unchanged after extraction | unit | `flutter test test/utils test/screens/characterCreation` | ✅ | ✅ green |
| 22-02-03 | 02 | 2 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 02 of 17" .planning/STATE.md` | — | ✅ green |
| 22-03-01 | 03 | 3 | PET-10 | T-22-04 | requirement Pending only | docs | `grep -q "^| PET-10 | Phase 22 | Pending |$" .planning/REQUIREMENTS.md` | ✅ | ✅ green |
| 22-03-02 | 03 | 3 | PET-01, PET-10 | T-22-09 | only today's SDL fields selected; level and own max lenient, unselected | unit + document pin | `flutter test test/graphql test/models test/utils` | ✅ extend | ✅ green |
| 22-03-03 | 03 | 3 | PET-02 | T-22-10, T-22-11 | timer only while needed, cancelled on close | bloc + widget | `flutter test test/screens/mainScreen/tabs/journal` | ✅ | ✅ green |
| 22-03-04 | 03 | 3 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 3 of 17" .planning/STATE.md` | — | ✅ green |
| 22-04-01 | 04 | 4 | PET-03 | T-22-14 | spell sheet unchanged | widget | `flutter test test/shared/components/popup test/screens/mainScreen/tabs/journal` | ❌ W0 | ✅ green |
| 22-04-02 | 04 | 4 | PET-03, PET-10 | T-22-12, T-22-13 | only https / Cloudinary-relative images | widget | `flutter test test/shared test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/shop` | ✅ extend | ✅ green |
| 22-04-03 | 04 | 4 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 04 of 17" .planning/STATE.md` | — | ✅ green |
| 22-05-01 | 05 | 5 | PET-03, PET-10 | T-22-15, T-22-16 | switch off pinned; plain-text rendering | unit + widget | `flutter test test/config test/shared/components/popup` | ❌ W0 | ✅ green |
| 22-05-02 | 05 | 5 | PET-03 | T-22-17 | route sheet read-only, no rename | widget | `flutter test test/shared/components/popup` | ❌ W0 | ✅ green |
| 22-05-03 | 05 | 5 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 05 of 17" .planning/STATE.md` | — | ✅ green |
| 22-06-01 | 06 | 6 | PET-02, PET-10 | T-22-18, T-22-20 | defeated parchment not tappable | widget | `flutter test test/screens/mainScreen/tabs/journal` | ❌ W0 + ✅ extend | ✅ green |
| 22-06-02 | 06 | 6 | PET-03 | T-22-19 | bookmark off on mission and when defeated | widget | `flutter test test/screens/mainScreen/tabs/journal` | ❌ W0 | ✅ green |
| 22-06-03 | 06 | 6 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 06 of 17" .planning/STATE.md` | — | ✅ green |
| 22-07-01 | 07 | 7 | PET-03 | T-22-21 | long press read-only | widget | `flutter test test/shared test/screens/mainScreen/tabs/shop test/screens/innkeeper` | ✅ extend | ✅ green |
| 22-07-02 | 07 | 7 | PET-03, PET-05 | T-22-22, T-22-23 | names only from own ownedPets | widget | `flutter test test/screens/mainScreen/tabs/shop` | ✅ extend | ✅ green |
| 22-07-03 | 07 | 7 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 07 of 17" .planning/STATE.md` | — | ✅ green |
| 22-08-01 | 08 | 8 | PET-03 | T-22-24 | prize pet selection live-safe | document pin + widget | `flutter test test/graphql test/models/quest test/shared/components/popup test/screens/mainScreen/tabs/board` | ✅ extend | ✅ green |
| 22-08-02 | 08 | 8 | PET-03 | T-22-25 | prize rows unchanged by long press | widget | `flutter test test/screens/innkeeper` | ✅ extend | ✅ green |
| 22-08-03 | 08 | 8 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 08 of 17" .planning/STATE.md` | — | ✅ green |
| 22-09-01 | 09 | 9 | PET-04 | T-22-29 | every new code has a banner | unit | `flutter test test/repository test/screens/mainScreen/tabs/journal test/screens/mainScreen/components` | ✅ extend | ✅ green |
| 22-09-02 | 09 | 9 | PET-04 | T-22-26, T-22-27, T-22-28 | UseItem document unchanged; single-flight | unit + bloc | `flutter test test/repository test/graphql test/screens/mainScreen` | ✅ extend | ✅ green |
| 22-09-03 | 09 | 9 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 09 of 17" .planning/STATE.md` | — | ✅ green |
| 22-10-01 | 10 | 10 | PET-04, PET-10 | T-22-30, T-22-31 | no target with the switch off | unit + widget | `flutter test test/models/companion test/screens/mainScreen/tabs/journal` | ❌ W0 + ✅ extend | ✅ green |
| 22-10-02 | 10 | 10 | PET-04 | T-22-32 | targets disabled in flight | widget | `flutter test test/screens/mainScreen/tabs/journal` | ✅ extend | ✅ green |
| 22-10-03 | 10 | 10 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 10 of 17" .planning/STATE.md` | — | ✅ green |
| 22-11-01 | 11 | 11 | PET-05 | T-22-35 | RenamePet registered, never sent pre-gate | document pin | `flutter test test/graphql test/models/request test/repository/services/graphql test/tool` | ✅ | ✅ green |
| 22-11-02 | 11 | 11 | PET-05 | T-22-33, T-22-34, T-22-36 | classifier per code; no name logs | unit + bloc | `flutter test test/repository test/screens/mainScreen/tabs/journal test/screens/auth` | ✅ | ✅ green |
| 22-11-03 | 11 | 11 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 11 of 17" .planning/STATE.md` | — | ✅ green |
| 22-12-01 | 12 | 12 | PET-05 | T-22-37, T-22-40 | form rules block confirm; single-flight | widget | `flutter test test/shared/components/popup` | ✅ | ✅ green |
| 22-12-02 | 12 | 12 | PET-05 | T-22-38, T-22-39 | prompts behind the switch, own character only | widget | `flutter test test/screens/mainScreen` | ✅ extend | ✅ green |
| 22-12-03 | 12 | 12 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 12 of 17" .planning/STATE.md` | — | ✅ green |
| 22-13-01 | 13 | 13 | PET-06 | T-22-41 | malformed companion keeps the result | unit | `flutter test test/models test/shared/components/popup test/screens/mainScreen/questResultsCubit` | ❌ W0 + ✅ extend | ✅ green |
| 22-13-02 | 13 | 13 | PET-06 | T-22-42, T-22-43 | defeat duration from resolvedAt, no clock | unit + widget | `flutter test test/utils test/shared/components/popup test/screens/mainScreen/components` | ✅ extend | ✅ green |
| 22-13-03 | 13 | 13 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 13 of 17" .planning/STATE.md` | — | ✅ green |
| 22-14-01 | 14 | 14 | PET-07 | T-22-44, T-22-45, T-22-46 | ambush toggle keeps its storage key | unit + widget | `flutter test test/models test/repository/storage test/repository/services/push test/screens/mainScreen/tabs/settings test/screens/mainScreen/components` | ✅ extend | ✅ green |
| 22-14-02 | 14 | 14 | PET-07 | T-22-47 | no double notice | widget | `flutter test test/screens/mainScreen` | ✅ extend | ✅ green |
| 22-14-03 | 14 | 14 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 14 of 17" .planning/STATE.md` | — | ✅ green |
| 22-15-01 | 15 | 15 | PET-08 | T-22-49 | companionLifeAfter sent only when set | unit | `flutter test test/models test/screens/innkeeper` | ✅ extend | ✅ green |
| 22-15-02 | 15 | 15 | PET-08 | T-22-48, T-22-50 | slider within served bounds | widget | `flutter test test/screens/innkeeper` | ✅ extend | ✅ green |
| 22-15-03 | 15 | 15 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 15 of 17" .planning/STATE.md` | — | ✅ green |
| 22-16-01 | 16 | 16 | PET-09, PET-10 | T-22-51, T-22-52, T-22-53, T-22-55 | gate before any selection; BE read-only | gate + document pin | `schema gate block of 22-16 + flutter test test/graphql` | ✅ | ⬜ pending |
| 22-16-02 | 16 | 16 | PET-09 | T-22-54 | switch flipped only after the SDL proof | gate | `flutter test test/graphql test/config + schema check 55 × OK + full suite` | ✅ | ⬜ pending |
| 22-16-03 | 16 | 16 | — | — | N/A (bookkeeping) | docs | `grep -q "Plan: 16 of 17" .planning/STATE.md` | — | ⬜ pending |
| 22-17-01 | 17 | 17 | PET-09 | T-22-56, T-22-58 | names only, no secrets | docs | `gate re-check of 22-17 + secrets grep = 0` | ❌ (created in Task 1) | ⬜ pending |
| 22-17-02 | 17 | 17 | PET-01..PET-08, PET-10 | T-22-59, T-22-60 | refusal probes on device | manual | `22-HUMAN-UAT.md steps 1–9` | ❌ (created in 22-17) | ⬜ pending |
| 22-17-03 | 17 | 17 | PET-01..PET-10 | T-22-57 | mark-complete only for passed steps | docs | `grep -q "^status: \(complete\|partial\)" 22-HUMAN-UAT.md` | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Each new test file is created RED-first by the task that needs it (no separate Wave 0 plan):

- [x] `test/helpers/fixtures/shop_fixtures.dart` — `petJson` (+ `maxLifePoints`, `recoveryTime`, `imagePath`) and `ownedPetJson` (+ `name`, `defeated`, `lifeAsOf`, `fullLifeAt`, `potionRecoveryUntil`), keys only when non-null — 22-01-02
- [x] `test/models/companion/companion_vitality_test.dart`, `companion_display_name_test.dart` — 22-02-01
- [x] `test/utils/name_rules_test.dart`, `test/utils/companion_lines_test.dart` — 22-02-02
- [x] `test/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_cubit_test.dart`, `companion_vitality_scope_test.dart`; `MockCompanionVitalityCubit` — 22-03-03
- [x] `ownedPetJson` gains `level` / `maxLifePoints` (keys only when non-null) — 22-03-02
- [x] `test/shared/components/popup/details_sheet_frame_test.dart` — 22-04-01
- [x] `test/config/companion_care_test.dart`, `test/shared/components/popup/companion_info_sheet_test.dart` — 22-05-01; `companion_details_route_test.dart` — 22-05-02
- [x] `test/screens/mainScreen/tabs/journal/components/owned_companion_row_test.dart` — 22-06-01; `test/screens/mainScreen/tabs/journal/journal_companion_details_test.dart` — 22-06-02
- [x] `test/models/companion/companion_potion_target_test.dart` — 22-10-01
- [x] `test/graphql/rename_pet_document_test.dart`, `test/models/request/rename_pet_request_test.dart`, `test/repository/services/graphql/graphql_rename_pet_test.dart` — 22-11-01
- [x] `test/repository/pet_rename_failure_test.dart`, `test/screens/mainScreen/tabs/journal/companionNameCubit/companion_name_cubit_test.dart`, `companion_name_notice_test.dart`; `MockCompanionNameCubit` — 22-11-02
- [x] `test/shared/components/popup/companion_name_sheet_test.dart` — 22-12-01
- [x] `test/models/quest_result/quest_companion_outcome_test.dart`; `companionOutcomeJson` and the optional `companion` / `onFoot` fixture keys — 22-13-01
- [x] `missionCompanionJson` and the optional `companion` / `companionLifeAfter` fixture keys — 22-15-01
- No framework install, no golden test (none exist).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Defeat in a fight: defeat line, empty slot, faded parchment with countdown, `PET_DEFEATED` on equip | PET-02, PET-06 | real BE combat + DB state + sweeper | `22-HUMAN-UAT.md` step 1 |
| Rest: life rising live, re-equip keeps the life | PET-01, PET-02 | real server clock and served anchors | step 2 |
| Potion on a companion, its own wait, refusals | PET-04 | real `useItem(petId)` and BE waits | step 3 |
| Names at purchase, after a prize, rename, refusal | PET-05 | real `renamePet` and shop/prize flows | step 4 |
| Ambush mid-travel with a mount: push, carousel before arrival, «Prosegui a piedi», no backward pawn, redirection | PET-06, PET-07 | BE travel recomputation and FCM | step 5 |
| «In forze» push and its toggle; «Imboscate» kept its choice | PET-07 | FCM + sweeper timing | step 6 |
| Innkeeper companion slider to the floor | PET-08 | real guided completion | step 7 |
| Long-press details in every list | PET-03 | device gesture and image loading | step 8 |
| A companion levels up: max life grows, current life unchanged, «Livello N» | PET-10 | BE level rule + live `characterUpdated` | step 9 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending (set by 22-17 after the device E2E)
