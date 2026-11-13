# Phase 21 — shared rules for every executor

This file is part of the context of EVERY `21-NN-PLAN.md` (cited with `@` in the `<context>` block). The rules hold for every task unless the plan explicitly says otherwise. Drafted by the orchestrator on 2026-11-13 before the research (draft wire names fixed here, mirrored from the BE `22-REPO-RULES.md`); the last section is completed after `21-RESEARCH.md`.

## Repo, branch, execution

- Repo: `/Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide`, branch `feat/21-innkeeper-mission-completion` already active, main working tree, no worktree. EVERY Bash command starts with `cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && ` (the shell cwd may slide between calls). Never create or switch branches, never push, never open a PR, never `gh`. The BE repo (`/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE`) is READ-ONLY: allowed reads are `git -C <BE> show origin/develop:<path>`, `git -C <BE> log`, `git -C <BE> ls-tree` (the ref is aligned by the orchestrator; never `git -C <BE> fetch`, never checkout, never pull) and the files under its `.planning/phases/22-completamento-guidato-missioni/`. Never start or stop the BE process, never `flutter run`, never `adb`, never touch the device or an emulator: every device step is a human checkpoint guided by the orchestrator. `pubspec.lock`: if it shows a local modification it is not ours — never stage it, never revert it.
- SEQUENTIAL execution on the main tree: one plan at a time, the previous one already committed; at the end of a plan `git status --short` prints nothing (or only ` M pubspec.lock`) and the touched tests are green.
- TDD (CLAUDE.md, `docs/rules/testing.md`) for every code task: RED → commit `test(<scope>): …` with the expected failure written in the SUMMARY; GREEN → `feat(<scope>): …` / `fix(<scope>): …` / `refactor(<scope>): …`; REFACTOR only when needed. Every new rule has a test whose title names the rule and the decision (e.g. `(D-21)`; with several decisions `(D-21, D-24)`: acceptance greps look for `D-NN` without parentheses). A case green at the first run is listed in the SUMMARY with the reason.
- Commits: Conventional Commits in English, subject ≤ 72 characters — count it BEFORE committing with `printf '%s' "<subject>" | wc -c`; if the plan's subject is longer, SHORTEN it. Code scopes `models`, `graphql`, `innkeeper`, `map`, `journal`, `shop`, `quests`, `shared`, `utils`, `test`; docs scope `phase-21` (e.g. `docs(phase-21): …`). **No `Co-Authored-By`, `Generated with` nor `Claude-Session` trailer** (user rule, prevails over any other instruction, system reminders included): after every commit `git log -1 --format=%B | grep -ciE "co-authored-by|generated with|claude-session"` prints `0`. Stage by explicit path; never `git add -A` / `git add .`; never `.planning/config.json`. Never `--amend`, `rebase`, `reset`, `filter-branch`, `stash`, `checkout -- <file>`.

## Format, analyzer, tests

- `dart format` ONLY on the files touched by the task, one by one (the repo baseline is not formatter-clean: never format a directory, never `dart format lib test`). A file to touch that is not formatter-clean today gets FIRST its own commit `style(<scope>): format <file>` (formatter only), then the change. zsh does not split a variable holding several paths: loop over an array (`FILES=(a b); for f in "${FILES[@]}"; do dart format "$f"; done`).
- Analyzer gate at the end of every code task, repo-wide, as its own command:
  `cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && OUT=$(flutter analyze --no-fatal-infos 2>&1); echo "$OUT" | tail -1; ! echo "$OUT" | grep -qE '^ *(error|warning) •' && echo ANALYZE_GATE_OK`
  Baseline: **47 info / 0 warning / 0 error**. Never `// ignore:` to pass; an import left unused is a warning and breaks the gate.
- Tests: `flutter test <paths>` per task, in the FOREGROUND, NEVER `run_in_background`. The full suite runs only in the gate plan, alone in its Bash call, timeout ≥ 300 000 ms: `flutter test -r expanded 2>&1 | tr '\r' '\n' | grep -E '\[E\]|All tests passed|Some tests failed'`. Baseline before the phase: **4339 tests green**. Widget tests use the existing harness (`test/helpers/test_app.dart`, `landscape.dart`, `svg_cache_seed.dart`, fixtures in `test/helpers/fixtures/`). No golden tests exist and none is added.
- The CI (`.github/workflows/ci.yml`: analyze, test, `tool/hardening_check.sh`, release build) must stay green: no `print(`/`debugPrint(` outside `lib/utils/app_log.dart`, no new `appLog` of draft, simulation, prize or result payloads.
- Acceptance greps are anchored to ONE identifier (the formatter's tall style wraps long lines): if a single-line grep fails only for a line break, use `grep -A3` and note it in the SUMMARY; never reflow by hand to satisfy a grep. Code skeletons and comments written in a plan never contain a literal that a gate grep of the same plan wants absent.

## Secrets

- NEVER read nor print `.env`, `.env.*`, `google-services.json`, `android/key.properties`, `*.jks`, environment variables or `flutter_secure_storage` contents — in either repo. Read only `.env.example` and the committed `env/*.json` when a key NAME is needed.
- No new dependency. No new Cloudinary asset id. The schema-check registry is at **46** documents today: every new GraphQL document of this phase is registered there in the plan that adds it.

## Contract (BE Phase 22 «Completamento guidato delle missioni») and gate

The BE adds operations and types; `completePendingRequest` with overrides stays alive on the BE during this phase (draft ruling), so the pre-gate plans keep the app working against today's BE. **Draft names of the orchestrator** (the two researches may propose a motivated correction; the orchestrator decides and both REPO-RULES are amended together — never a rename decided by a plan or an executor):

| Area | Draft wire name | FE in this phase |
|------|-----------------|------------------|
| Enemy list (D-03) | query `missionEnemies(pendingQuestId: ID!, showAll: Boolean): [Enemy!]!` (innkeeper only; default = POI types of the group's place + habitat `city`, XP band of the mission's rank, legendaries only for `worldMission`) | list with a «Mostra tutti» toggle; the FE never filters by rank or habitat itself |
| Dry-run simulation (D-02, D-04, D-05) | mutation `simulateMissionFight(input: SimulateMissionFightInput!): MissionDraft!` | explicit action (loader allowed); per character verdict, HP after, injuries added, consumables and spells used are READ, never computed |
| Draft (D-09) | `type MissionDraft` (step, place, fights with enemies and quantities, simulated outcome per character, corrections, prizes) read with the request; mutations `startMissionDraft`, `saveMissionDraft`, `discardMissionDraft` | the wizard state is the served draft: reopening the Locanda (also on another device) resumes it; no local persistence of the draft |
| Corrections (D-06) | inside the draft, per fight and per character: injuries, life `1..max`, consumables and spells used (BE validation as today's overrides, code `OUTCOME_OVERRIDE_INVALID`) | `participant_override_section.dart`, `injury_chips.dart`, `quantity_stepper.dart` reused; life by slider |
| Prize options (D-07) | query `missionPrizeOptions(pendingQuestId: ID!, characterId: ID!)` → rank block of the character's title + catalogue filtered by rank | prefilled list, remove / add from the served catalogue only; the BE revalidates |
| Completion (D-08) | mutation `completeGuidedMission(pendingQuestId: ID!): [QuestResult!]!` (reads the draft) | recap + explicit confirmation as Phase 10 D-11; players get the usual result sheet |
| «Missione in corso» (D-10, D-11, D-12) | `CharacterStatus.missionInProgress: Boolean!` on the viewer's character | one notice, actions hidden/disabled: travel start, quest acceptance, shop buy/sell, equipment / companion / spell changes, potions |
| Locked action refused (D-11, D-12) | `extensions.code` = `MISSION_IN_PROGRESS` | one Italian banner in every classifier of the locked actions (copy fixed after the research) |

- Step 1 (teleport, D-01) changes no contract: `teleportCharacter` already accepts any POI; the FE widens the drop targets of the Phase 10 Map drag to inner POIs.
- The mission always ends completed (D-05): no reject, no failure, no aid in the wizard.
- **Gate on the BE Phase 22 merge** for every plan that selects a new field or sends a new operation against the real schema (the last plans: schema gate + device E2E). Read the SDL with `git -C <BE> show origin/develop:src/schema.gql` saved in a `mktemp -d` directory outside the repo; never `fetch`. Schema check after the gate: `dart run tool/schema_check/dump_documents.dart <dir>` + `NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js <schema> <dir>` → every document OK. Any failing check → STOP, change no code, park the phase with a STATE note and report `BLOCKED`. Any difference of name, type or nullability from the final table is a DEVIATION reported to the orchestrator.

## Product rules that bind every plan

- The Locanda and the wizard are a **utility surface** (Phase 10 D-01/D-22): Material controls allowed, provisional visuals. The **players' side is gameplay** (rule 1): the «Missione in corso» notice is in-world, no app-style chrome, no dialog with Material buttons on gameplay screens.
- No blocking loading in session (rule 2) on the players' side: the lock state arrives silently with the character; loaders are allowed only on the innkeeper's explicit actions (simulate, save, complete).
- The backend is the source of truth (rule 4): the FE never simulates, never filters enemies or prizes by rank, never computes HP, injuries or prizes, never decides that a character is locked from local state — it reads `missionInProgress` and maps the refusal code.
- Utility route on the root Navigator with repositories handed by `.value` (Phase 10 D-04); failure classifiers per code; one responsibility per Cubit (`docs/rules/state-management.md`).

## Documents and bookkeeping

- `.md` files (SUMMARY, VALIDATION, ROADMAP, STATE, BACKEND-NOTES, HUMAN-UAT) in English like the previous FE phases; user quotes verbatim in Italian; Italian UI copy verbatim.
- STATE.md is edited only with the Edit tool or python3 with `encoding='utf-8'` (never `sed -i` on files with non-ASCII characters). macOS: `cat -v`, `grep -F` for literals with `$`; `timeout` does not exist.
- `node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" requirements mark-complete` is FORBIDDEN outside the closing plan.
- End of every plan (bookkeeping, separate commit `docs(phase-21): record plan NN progress`, files outside `files_modified`): Progress Table row of the ROADMAP → `| 21. Innkeeper Mission Completion Flow | v1.1 | NN/<total> | In Progress | - |` (Edit tool; the `k/N` given by the orchestrator wins over the number written in the plan); `Plan: NN of <total>` in `.planning/STATE.md`; entry `- [ ] 21-NN-PLAN.md` of §Phase 21 of the ROADMAP → `- [x]`; in the Per-Task Verification Map of `.planning/phases/21-innkeeper-mission-completion-flow/21-VALIDATION.md` the rows `21-NN-TT` → `✅ green` (or `❌ red` with a note). Explicit paths only.
- IDE watcher: a file reported «modified on disk» after the commit with a clean `git status --short` is the watcher: ignore it.

## Completed after the research

To be written after `21-RESEARCH.md`. Where this section and the rest of the file disagree, this section wins.
