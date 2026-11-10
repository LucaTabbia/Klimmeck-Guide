# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — Core Loop

**Shipped:** 2026-11-10
**Phases:** 17 | **Plans:** 180 | **Tasks:** 131 | **Quick tasks:** 10 (+2 inline) | **Sessions:** not counted (roughly one orchestrator session per phase or phase pair, 2026-10-06 → 2026-11-10)

### What Was Built
- A real Twitch session mediated by the backend, with silent refresh, WebSocket re-authentication, atomic logout and «l'ultimo login caccia l'altro».
- The core loop on the Map: character creation, quest board with the tear gesture, travel on the server clock with food and ambushes, combat result sheets never lost, spells with backend-driven slots.
- The world as data: city shops by size, server-generated quests, ambush reports in a carousel, unlockable lore with silhouettes and «Nuovo» bookmarks.
- The innkeeper's Locanda (live queue, completion form with overrides, teleport, «Genera missioni»).
- Release readiness: split entry points, release bundle without the dev bypass, signing, TLS-only, CI with guard greps and the release build, leak-tracking and concurrency harnesses.

### What Worked
- **One device E2E per phase, approved by the user**, with the orchestrator reading DB, logcat and screenshots before answering: every product rule found on the device became a D-NN and a TDD fix on the same branch.
- **Companion phases across two repos** with the contract names fixed in `REPO-RULES.md` before the planners, a `tool/schema_check` gate on the merged BE SDL, and `BACKEND-NOTES.md` handoffs per phase.
- **Review by area → rulings → fixer → verifier → security** before every PR kept the PRs mergeable at the first review; the Rule 4 ruling via SendMessage avoided a library swap (`graphql_flutter` 5.2.1).
- **Sequential opus executors with briefs as scratchpad files**, cumulative notes and spot-check scripts instead of trusting the summaries.
- **Parking a phase at N/M** when the BE companion was not merged, then resuming with a SendMessage to the same executor.

### What Was Inefficient
- The `.env` placeholder and the Android SDK licences cost three CI runs on the first workflow; a dry run of the workflow locally would have caught both.
- Quick tasks executed on stacked branches to dodge `STATE.md` conflicts (261105-lgd/scp) — a sign that `STATE.md` is too chatty for parallel work.
- The REQUIREMENTS «Coverage» line drifted twice (counted 95, then 106 against 111 real requirements): bookkeeping lines that restate a count should be generated, not typed.
- Several device UAT steps were slowed by the device setup (adb reverse lost on USB reconnection, Doze with the screen off, emulator Chrome too old for Twitch) rather than by the app.
- `state begin-phase` rewrote `stopped_at` with stale text more than once; a restore script was needed every time.

### Patterns Established
- Backend as the only source of truth; the FE maps `extensions.code` to Italian banners and never computes a rule.
- RED commit before GREEN for every plan task; one commit per task; no `Co-Authored-By`/`Generated with` trailers; commit scope `phase-N`.
- No app chrome outside the utility screens; no blocking loading in session; Dropdown + touchable parchments for Journal sections.
- Server time (`serverTime` offset) for every countdown and interpolation.
- Branch per phase from `develop`, PR to `develop`, `docs/` branch for milestone closes; the orchestrator opens PRs with the personal `GH_TOKEN`.

### Key Lessons
1. Ask the user the product rules with the data inside the question (counts, ids, names) and fix them in TDD during the UAT, not after it.
2. Gate every FE plan that selects a new BE field on the merged BE SDL — never on a branch — and prove the names with `grep -cF` on the schema.
3. Keep one-off migrations and seeders out of the repo after the real boot; the DB is the world.
4. Treat `STATE.md` as an index, not a log: long prose there causes conflicts between parallel branches and breaks the GSD tools' field updates.
5. Run the CI workflow's steps locally (or on a draft PR) before the real PR of a phase that changes the build.

### Cost Observations
- Model mix: executors, reviewers, verifiers and security auditors on opus (GSD `quality` profile); orchestration in the main session; no haiku/sonnet in the pipeline.
- Sessions: not measured (one or two per phase pair, FE + BE in the same session from the FE repo).
- Notable: the BE `test:cov` gate (≈630 s) had to run in the background; FE full suite ≈3 700 tests in a few minutes; UAT sessions dominated wall-clock time, not execution.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | n/a | 17 (+21 BE) | GSD orchestration across two repos with companion phases, device UAT per phase, review-by-area pipeline before each PR |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | 3 704 (FE) / 4 872 (BE) | FE not gated; BE per-folder thresholds (auth 99,86 % lines at Phase 17) | FE: `flutter_dotenv` moved to the dev entry point only; no new runtime dependency in Phases 12–17 beyond `leak_tracker` (dev) |

### Top Lessons (Verified Across Milestones)

1. The device UAT with the user is the real verification gate; automated verification finds structure, the device finds product rules.
2. Contracts first (REPO-RULES, schema gate), code second — every cross-repo defect of v1.0 came from a name or a shape assumed before the merge.
