---
phase: 12-hardening
plan: 17
subsystem: device UAT + BE handoff
tags: [hardening, uat, device, release, tls-tunnel, session, 4409, handoff]
requires: ["12-16"]
provides:
  - "12-HUMAN-UAT.md complete: steps 1-8, 10, 11 pass, optional step 9 skipped, DB-1 resolved, user verdict approved"
  - "HARDEN-01..HARDEN-10 ticked in REQUIREMENTS.md (each on passed evidence)"
  - "FE handoff BACKEND-NOTES.md for the BE Phase 17"
  - "Phase 12 closed in ROADMAP/STATE/VALIDATION: v1.0 Core Loop all 17 phases complete"
affects: [v1.0 milestone close, FE PR refactor/12-hardening -> develop]
tech-stack:
  added: []
  patterns:
    - "UAT results recorded only from the user's words and the orchestrator's evidence notes; no ids, no secrets, no tunnel host"
key-files:
  created:
    - .planning/phases/12-hardening/12-HUMAN-UAT.md
    - .planning/phases/12-hardening/BACKEND-NOTES.md
    - .planning/phases/12-hardening/12-17-SUMMARY.md
  modified:
    - .planning/phases/12-hardening/12-CONTEXT.md
    - .planning/phases/12-hardening/12-VALIDATION.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
decisions:
  - "D-13c amended by the UAT (DB-1, review C-IN-06): Ferrion and Necrorian are capitals BE-side (BE quick task 261109-cap, BE PR #28); Talmvere stays a village, always visible through the FE flag CityType.alwaysVisible (commits ee7db08/2bc4e7a)"
  - "Step 9 (account switch) skipped, not failed: the user has no second Twitch account; covered by identity_transitions_test.dart"
metrics:
  duration: "~2 sessions (Task 1 2026-11-09, checkpoint 2026-11-09 evening, Task 3 2026-11-10)"
  completed: 2026-11-10
---

# Phase 12 Plan 17: Device UAT and BE handoff Summary

The hardening was proven on a Samsung and an Android emulator against the merged BE Phase 17 (`8bfd1b3`). The checks covered:

- a release signed with the user's keystore, running through a TLS tunnel with a real Twitch login, with no app logs;
- the TLS fail-fast screen;
- the dev workflow, unchanged;
- a heap snapshot after logout identical to the one taken before login;
- «l'ultimo login caccia l'altro» in both directions, with the dedicated notice;
- the `roleChanged` notice;
- archiving a character while logged in, which leads to a fresh shell;
- CI green.

HARDEN-01..10 are ticked, and the FE handoff for the BE is written.

## Commits

- `84f7e6d` docs(phase-12): add the hardening device UAT (Task 1)
- `ee7db08` test(map) + `2bc4e7a` fix(map): Talmvere always visible (UAT fix by the orchestrator during the checkpoint, DB-1)
- `4cf6fa2` docs(phase-12): record the hardening device E2E (Task 3)
- (this SUMMARY + bookkeeping) docs(phase-12): record plan 17 progress

## UAT verdict per step (`12-HUMAN-UAT.md`)

| Step | Requirement | Result |
|------|-------------|--------|
| 1 Signing | HARDEN-08 | pass (orchestrator-verified: no WARNING line, certificate `CN=Luca Tabbia`, bundle guard OK) |
| 2 Release via tunnel | HARDEN-08 | pass — «pass» (0 app log lines; sessions `newLogin`/`userLogout` at DB) |
| 3 TLS fail-fast | HARDEN-08 | pass (orchestrator-verified, screenshot) |
| 4 Dev workflow | HARDEN-07 | pass (orchestrator-verified: instant dev login; «Run with --flavor dev» without the flavor) |
| 5 Heap snapshot | HARDEN-05 | pass (orchestrator-verified: snapshot B after logout = snapshot 0) |
| 6 Last login wins | HARDEN-06 | pass — «pass» |
| 7 Symmetry | HARDEN-06 | pass — «samsung dentro» |
| 8 Archive + recreate | HARDEN-06 | pass — «Poi lo rivolglio indietro, vai» then «creato» (character restored afterwards) |
| 9 Account switch (optional) | HARDEN-06 | skipped — no second Twitch account |
| 10 Role change (optional) | HARDEN-06 | pass (orchestrator-verified: `roleChanged` 6 ms after the update) |
| 11 CI | HARDEN-09 | pass (runs 42681645719 / 42683743398 / 42688698014 green) |
| DB-1 City sizes | D-13c | resolved — «Ad eccezione di Talmvere, il resto conta come capitale perché lo è» |

## Requirements ticked (with evidence)

| Requirement | Evidence |
|-------------|----------|
| HARDEN-01 | 12-16 gate (VALIDATION approved; `tool/hardening_check.sh` token/log greps); step 2 logcat clean |
| HARDEN-02 | BE matrix `test/authz/authorization-matrix.int-spec.ts` (89 cases) on BE `origin/develop` `8bfd1b3` |
| HARDEN-03 | 12-16 gate (`logout_flow_test.dart`) |
| HARDEN-04 | 12-16 gate (`concurrent_unauthorized_refresh_test.dart`) |
| HARDEN-05 | step 5 + leak test (12-16 gate) |
| HARDEN-06 | steps 6, 7, 8 (+ optional 10) + dual-session / identity tests |
| HARDEN-07 | step 4 + 12-16 bundle guard |
| HARDEN-08 | steps 1, 2, 3 |
| HARDEN-09 | step 11 |
| HARDEN-10 | 12-16 gate + `12-REVIEW.md` / `12-REVIEW-FIX.md` / `12-REVIEW-RULINGS.md` (21 fixed, 1 deferred: C-IN-06, closed by DB-1) |

`requirements mark-complete` ran once per id and ticked all ten checkboxes. It did not touch the grouped traceability row, which I updated by hand to `Complete (BE Phase 17 merged; Samsung + emulator device E2E 2026-11-09)`.

## Gaps

None. Session observations, not failures (recorded in the UAT «Session notes» and in BACKEND-NOTES §4.7):

1. graphql_flutter 5.2.1 `SocketClient` prints three lines per socket lifecycle in release, and Impeller logs validation messages. Both are third-party or engine output with no credential. Candidate deferred item.
2. The splash warm-up downloads every lore image on a fresh install (~150 MB). Deferred UX item.
3. Old system Chrome on the emulator is rejected by Twitch; `pm clear com.android.chrome` fixes it.
4. The first two CI runs were red; they were fixed before the UAT.

## Deviations from Plan

1. **[Rule 3 — gate literal]** Task 1: in step 11 the plan's verbatim `GH_TOKEN=$(gh auth token …)` matched the plan's own secret grep (`token=`). It was reworded to "with the personal account `LucaTabbia` selected per command".
2. **[Brief additions]** Task 1 added:
   - the AVD names (`Medium_Phone_API_36.1` / `Pixel_9`);
   - `tcp:3000 tcp:3001`;
   - `DEV_AUTH_TWITCH_ID` distinct from the real twitchId;
   - storePassword = keyPassword;
   - the warning about the debug-signed `.invalid` APK;
   - DB-1 as a separate «DB checks» table, which keeps the numbered rows at 11.
3. **[UAT fix outside this executor]** The commits `ee7db08`/`2bc4e7a` (Talmvere `CityType.alwaysVisible`) were made by the orchestrator during the checkpoint. Task 3 recorded them and added the D-13c amendment line to `12-CONTEXT.md` in the same commit as the UAT record.
4. **[Quote spelling]** The step 8 quote «Poi lo rivolglio indietro, vai» is kept exactly as the orchestrator relayed it, typo included. The orchestrator's notes spell it «rivoglio».
5. **[Out of scope, not fixed]** The REQUIREMENTS «Coverage» line still says 106 v1 requirements, without the four HARDEN-07..10 added in the discuss. Left for the milestone close.

## PR reminder

The orchestrator opens the PR from `refactor/12-hardening` to `develop` (never `main`): `GH_TOKEN=$(gh auth token --user LucaTabbia) gh pr create --base develop`. BE PR #28 (`fix/city-size-capitals`) merges on the BE side.

## Self-Check: PASSED

- FOUND: `.planning/phases/12-hardening/12-HUMAN-UAT.md`, `.planning/phases/12-hardening/BACKEND-NOTES.md`
- FOUND commits: `84f7e6d`, `ee7db08`, `2bc4e7a`, `4cf6fa2`
