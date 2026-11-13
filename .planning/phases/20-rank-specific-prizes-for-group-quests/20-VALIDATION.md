---
phase: 20
slug: rank-specific-prizes-for-group-quests
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-11-13
---

# Phase 20 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: `20-RESEARCH.md` §Validation Architecture, aligned with the amended `20-CONTEXT.md` (D-18..D-25) and the wire shape fixed by the orchestrator (FE D-22 / BE D-22).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter 3.35.5) + `bloc_test ^10.0.0` + `mocktail ^1.0.5` + `fake_async` |
| **Config file** | none beyond `pubspec.yaml` / `analysis_options.yaml`; helpers in `test/helpers/` (`test_app.dart`, `landscape.dart`, `svg_cache_seed.dart`, `fixtures/quest_fixtures.dart`, `fixtures/quest_result_fixtures.dart`) |
| **Quick run command** | `flutter test <touched test files>` |
| **Full suite command** | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (foreground, only in the gate plan 20-03, alone in its Bash call, timeout ≥ 300 000 ms) |
| **Analyzer gate** | `flutter analyze --no-fatal-infos` → 0 error / 0 warning (baseline 47 info) |
| **Schema gate** | block-anchored `awk` checks of `20-REPO-RULES.md` on `git -C <BE> show origin/develop:src/schema.gql` (plans 20-03, 20-04); `dart run tool/schema_check/dump_documents.dart <dir>` + `node tool/schema_check/validate_documents.js <schema> <dir>` → 46 × OK (plan 20-03) |
| **Estimated runtime** | quick runs 5–60 s; full suite ~100 s (4239 tests before the phase) |

---

## Sampling Rate

- **After every task commit:** the touched test files + the repo-wide analyzer gate + the trailer check
- **After every plan:** the test directories named in the plan's `<verification>`
- **Pre-gate plans (20-01, 20-02):** no fragment or document change; the app keeps working against the BE of today (the new turn fields are absent → fallback stages line)
- **Phase gate (20-03):** schema gate, schema check 46 × OK, full suite in foreground, analyzer, format of the phase's files one by one, trailer and subject-length checks over the plan commits, product-rule greps, `hardening_check.sh`
- **Before `/gsd-verify-work`:** full suite green
- **Max feedback latency:** 60 seconds per task (quick runs)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 20-01-01 | 01 | 1 | RANKP-01 | T-20-01, T-20-02, T-20-04 | the sheet prints the served block on Board and Map whatever the viewer's title; `rankPrizes` ignored and never read in `lib`; no spell row; parse never dropped (D-07, D-18, D-22, D-23) | unit + widget (contract pins, green at first run) | `flutter test test/models/quest/quest_test.dart test/shared/components/popup/quest_info_sheet_test.dart test/screens/mainScreen/tabs/map/quest_info_overlay_test.dart` | ✅ (add groups) | ✅ green |
| 20-01-02 | 01 | 1 | RANKP-02 | T-20-03 | mixed boss: one line per seat title in wire order, viewer highlight, no any-rank line, minimum = lowest seat, registration / fullness per title, party counter on every seat (D-02, D-03, D-25); title change rereads (D-04, existing pin) | unit (contract pins, green at first run) | `flutter test test/models/quest test/screens/mainScreen/components/quest_scope_listener_test.dart` | ✅ (add groups) / ❌ W0 (`mixedBossJson`) | ✅ green |
| 20-02-01 | 02 | 2 | RANKP-03 | T-20-05, T-20-09 | four turn fields lenient (unknown kind / non-number → null, result kept), in `toJson` and `props`; enum via `asNameMap()` (D-22) | unit | `flutter test test/models/quest_result test/shared/components/popup/quest_result_sheet_test.dart test/screens/mainScreen/main_screen_quest_results_test.dart` | ✅ (add group) / ❌ W0 (turn params, `aidDungeonResultJson`) | ✅ green |
| 20-02-02 | 02 | 2 | RANKP-03 | T-20-06, T-20-07, T-20-09 | one turn line in the stages slot with the REPO-RULES copy; fallback «Esplorazione: tappa N di M»; served numbers only (no +1, no share, no proportion line); no turn line for `rescued`, `death`, `gmCompleted` (D-14, D-20, D-21, D-22, D-24) | unit + widget | `flutter test test/utils test/shared/components/popup test/models/quest_result test/screens/mainScreen/main_screen_quest_results_test.dart` | ✅ (add groups) | ✅ green |
| 20-02-03 | 02 | 2 | RANKP-03 | T-20-08 | FE handoff: contract consumed, behaviours proved, questions; no ids or secrets | docs | `grep` checks of the task on `BACKEND-NOTES.md` | ❌ (created) | ✅ green |
| 20-03-01 | 03 | 3 | RANKP-04 | T-20-10, T-20-11, T-20-12, T-20-13 | BE read-only; gate stops and parks; no rename by the executor | gate | block-anchored `awk` checks on `origin/develop:src/schema.gql` (`GATE_OK`) | ✅ | ⬜ pending |
| 20-03-02 | 03 | 3 | RANKP-03, RANKP-04 | T-20-10, T-20-14 | the four turn fields selected after `stagesTotal` in the three result documents; `QuestFragment` unchanged, `rankPrizes` not selected; 46 × OK (D-22) | unit (document) + gate | `flutter test test/graphql test/tool test/models/quest_result test/shared/components/popup test/screens/mainScreen/main_screen_quest_results_test.dart` + `dump_documents.dart` / `validate_documents.js` | ✅ (add pins) | ⬜ pending |
| 20-03-03 | 03 | 3 | RANKP-04 | T-20-14 | full suite, analyzer, format, trailers, subject length, product-rule greps, `hardening_check.sh` | gate | `flutter test` (full, foreground) + greps | ✅ | ⬜ pending |
| 20-04-01 | 04 | 4 | RANKP-04 | T-20-15, T-20-17 | gate re-checked; UAT record with 13 steps, no ids / tokens / URIs | docs | `test -f …/20-HUMAN-UAT.md` + row count 13 | ❌ (created) | ⬜ pending |
| 20-04-02 | 04 | 4 | RANKP-01..04 | T-20-18, T-20-19 | seeds outside the repo; outcomes only from the user's words | manual (device checkpoint) | `20-HUMAN-UAT.md` steps 1–13 | — | ⬜ pending |
| 20-04-03 | 04 | 4 | RANKP-01..04 | T-20-15, T-20-16 | requirements ticked only on passed steps; BE handoff §3 written | docs | `grep` checks of the task on UAT / BACKEND-NOTES / STATE | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Test helpers that do not exist yet; each is created in the RED step of the task that needs it (no separate Wave 0 plan: every task is TDD or a contract pin).

- [x] `mixedBossJson` / `buildMixedBoss` in `test/helpers/fixtures/quest_fixtures.dart` (seats paladin ×2 + adventurer ×1, `minTitle` adventurer) — RANKP-02 (20-01)
- [x] `turnsTotal` / `turnsCompleted` / `lastTurn` / `lastTurnKind` params of `questResultJson` and `dungeonResultJson`, new `aidDungeonResultJson` in `test/helpers/fixtures/quest_result_fixtures.dart` — RANKP-03 (20-02)
- No separate `dungeon_turn_kind_test.dart`: the enum has only `fromWire`, exercised through the `QuestResult` cases (planner's choice, 20-02).
- No framework install, no new mock, no harness provider.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Each viewer sees the block of their own rank, the sheet switches silently on a title change, the D-18 fallback for a hero | RANKP-01 | per-viewer resolution on HTTP and per subscriber on WS is a BE rule the FE cannot detect (research Pitfall 1) | `20-HUMAN-UAT.md` steps 1–4 |
| Mixed boss seats and minimum title on real generated / seeded content | RANKP-02 | BE D-23 writes `minTitle` and the seat order | `20-HUMAN-UAT.md` steps 1, 2 |
| Turn line on a real dungeon defeat, on a cleared dungeon and on the rescuer's result; the aid's share on the sheet; the wounded freed | RANKP-03 | turn counters, the saved turn and the share are BE rules on a real resolution | `20-HUMAN-UAT.md` steps 5–9 |
| Lost fight in a quest that opens no rescue: 1 HP, in town, lane free, no aid | RANKP-04 | BE rule D-19 on a real resolution | `20-HUMAN-UAT.md` step 10 |
| Boss win by block, archiver release push (D-16, covered by the BE suite), non-caster spell | — (optional) | BE-only rules (D-08, D-16, D-05b) needing a full party or extra seeds | `20-HUMAN-UAT.md` steps 11–13 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s for the per-task runs
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending (automated gates of plan 20-03 and the device E2E of plan 20-04)
