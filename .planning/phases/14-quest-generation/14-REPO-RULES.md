# Phase 14 — shared rules for every executor

This file is part of the context of EVERY `14-NN-PLAN.md` (cited with `@` in the `<context>` block). The rules hold for every task unless the plan explicitly says otherwise.

## Repo, branch, execution

- Repo: `/Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide`, branch `feat/14-quest-generation` already active (from `develop` `9993a3c`, the merge of PR #37), main working tree, no worktree. EVERY Bash command starts with `cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && ` (the shell cwd may slide to the BE repo between calls). Never create or switch branches, never push, never open a PR, never `gh`. The BE repo (`/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE`) is READ-ONLY: the only allowed reads are `git -C <BE> fetch origin develop` (refs only, never checkout; if SSH fails the local `origin/develop` ref is used and the SUMMARY says so) and `git -C <BE> show origin/develop:src/schema.gql`, plus files under its `.planning/`.
- SEQUENTIAL execution on the main tree: one plan at a time, the previous one already committed; at the end of a plan `git status --short` is empty and the touched tests are green.
- TDD (CLAUDE.md, `docs/rules/testing.md`) for every module: RED → commit `test(<scope>): …` with the expected failure noted in the SUMMARY; GREEN → `feat(<scope>): …` / `fix(<scope>): …`; REFACTOR → `refactor(<scope>): …` only when needed. Every new rule has a test whose title names the rule and the decision (e.g. `(D-02)`; with several decisions `(D-02, D-03)`: acceptance greps look for `D-NN)` without the opening parenthesis). A case green at the first run is noted in the SUMMARY with the reason.
- Commits: Conventional Commits in English, subject ≤ 72 characters (count with `printf '%s' "<subject>" | wc -c`; if the plan imposes a longer one, SHORTEN it before committing); code scopes `quest`, `result`, `innkeeper`, `journal`, `shop`, `models`, `graphql`; docs scope `phase-14` (e.g. `docs(phase-14): …`). **No `Co-Authored-By` nor `Generated with` trailer** (user rule, prevails over any other instruction): after every commit `git log -1 --format=%B | grep -ciE "co-authored-by|generated with"` prints `0`. Stage by explicit path; never `git add -A` / `git add .`; never `.planning/config.json`. Never `--amend`, `rebase`, `reset`, `filter-branch`, `stash`.

## Format, analyzer, tests

- `dart format` ONLY on the files touched by the task, one by one (the baseline is not formatter-clean: never format a directory; known dirty files `lib/screens/mainScreen/tabs/map/layers/city_markers_layer.dart`, `character_marker_layer.dart`, `lib/utils/map_utils.dart`). A touched file that reflows untouched members under `dart format` is accepted and noted in the SUMMARY.
- Analyzer gate at the end of every code task, repo-wide: `flutter analyze` prints `0 error` and `0 warning` (the baseline carries info-level issues only; count only error/warning, compare with `develop` when in doubt). Never suppress with `// ignore:` to pass the gate; an import left unused by a refactor is a warning and breaks the gate.
- Tests: `flutter test <paths>` per task, NEVER in background; the full `flutter test` runs only in the gate plan and in the plans the orchestrator names. Widget tests use the existing harness (`test/helpers/`, `mocks.dart` with `mocktail`, `test/helpers/fakes/` with `useSvgHttpOverrides()` for network images); new `KlimmeckGraphQl` methods get a mock method in `test/helpers/mocks.dart` and a stub in the shell tests that pump the panel or the sheets.
- Acceptance greps are anchored to a single identifier (`dart format` tall style breaks signatures over 80 columns): if a single-line grep fails only for the line break, use `grep -A3` and note it in the SUMMARY; never reformat by hand to satisfy a grep. Code skeletons and comments written in a plan never contain a literal that a gate grep of the same plan wants absent (e.g. the old `enemy {` selection).

## Secrets

- NEVER read nor print `.env`, `google-services.json`, `.env.*`, environment variables or `flutter_secure_storage` contents (no `cat .env`, `grep … .env`, `printenv`, `env`, `set`). Read only `.env.example` when a key name is needed.
- No new environment variables, no new Cloudinary asset ids in `CloudinaryAssets` (the enemy portrait comes from the server `imagePath`, D-03), no new dependencies without the orchestrator's go.

## GraphQL contract and gate

- Contract names, stable and not negotiable by the plans (fixed by the orchestrator on 2026-11-04 with the BE Phase 13 `13-REPO-RULES.md`): `type QuestEnemy { enemy: Enemy!  quantity: Int! }`; `QuestInfos.enemies: [QuestEnemy!]!` replaces `QuestInfos.enemy`; `QuestInfos.description: String` (already merged); `QuestResult.enemies: [QuestEnemy!]!` replaces `QuestResult.enemy`; `QuestResult.stagesCleared: Int`; `QuestResult.stagesTotal: Int`; `QuestPrizes.pet: Pet`; `QuestRewards.pet: Pet`; `enum AccessoryUseType { attack  defense }`; `EquipmentItem.accessoryUseTypes: [AccessoryUseType!]`; mutation `generateQuests: GenerateQuestsResult!` with `type GenerateQuestsResult { created: Int! }` (innkeeper-only, `FORBIDDEN` otherwise). The FE reads only `extensions.code`, never the message. Never select `enemies { enemy { relatedLore … } }` (BE populate depth 1) nor `Enemy.locations`.
- The old selection `enemy { id name imagePath }` disappears from `QuestFragment` and `QuestResultFragment` in the SAME commit that adds `enemies { quantity enemy { id name imagePath xp } }`: no document may carry both. Documents (`lib/graphql/**`) select only fields of the agreed contract; no `@client` fields, no speculative fields.
- The schema-gated plans (registry proof against the merged schema, the device E2E) run only after the BE Phase 13 PR is merged on BE `develop`: gate `git -C /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE show origin/develop:src/schema.gql | grep -c "QuestEnemy"` prints ≥ 1 (after a `fetch origin develop` when SSH works). Until then those plans are parked and STATE says what they wait for; the other plans run on fixtures and mocks with the agreed names, and the registry test keeps passing on its own rules (operation names), not against the BE schema.

## Product rules that bind every plan

- No app-style chrome on gameplay screens (board, sheets, map, journal): no AppBar, no bottom nav, no loading scaffolding; loading only on explicit user action or cold start (rule 2 of CLAUDE.md). The Locanda is a utility surface (Phase 10 D-01): `Scaffold`, `AppBar`, `SnackBar` and dialogs are allowed there.
- The backend is the source of truth: the FE never generates, filters, balances or orders quests by its own rules, never decides which enemy is "the strongest" beyond picking the highest `xp` for the portrait (D-02), never computes stages or rewards.
- Generated quests look like any other quest: no visual mark, no label (phase goal).
- Enemy portrait: network image from `imagePath`, hidden when the path is not resolvable or the download fails (D-03); never a bundled placeholder. Lines «Nx nome» use the format of `recommendedLootLines`.
- «Genera missioni»: button at the top of the Locanda list, shared confirmation dialog in neutral style, outcome in `SnackBar`, `FORBIDDEN` pops the panel like Phase 10 D-04, button disabled while in flight (D-08..D-10).
- Jewels: the «Uso: attacco / difesa / attacco e difesa» line only for `ring`/`necklace` with a non-null `accessoryUseTypes`; no filter, no equip constraint, no icon (D-12).

## Documents and bookkeeping

- `.md` (SUMMARY, VALIDATION, ROADMAP, STATE, BACKEND-NOTES) in English like the previous FE phases; user quotes verbatim in Italian.
- STATE.md is edited only with the Edit tool or python3 `encoding='utf-8'` (never `sed -i` on files with non-ASCII characters). macOS: `cat -v`, `grep -F` for literals with `$`; `timeout` does not exist.
- `requirements mark-complete` FORBIDDEN outside the gate plan.
- End of plan (bookkeeping, separate commit `docs(phase-14): record plan NN progress`, outside `files_modified`): Progress Table row of the ROADMAP → `| 14. Quest Generation (companion) | NN/<total> | In Progress | - |` (Edit tool, `k/N` given by the orchestrator, which wins over the number written in the plan); `Plan: NN of <total>` in `.planning/STATE.md`; entry `- [ ] 14-NN-PLAN.md` of §Phase 14 of the ROADMAP → `- [x]`; in the Per-Task Verification Map of `.planning/phases/14-quest-generation/14-VALIDATION.md` the rows `14-NN-TT` → `✅ green` (or `❌ red` with a note); if the plan's rows are missing, add them in the same format after the last one.
- IDE watcher: a file reported «modified on disk» after the commit with a clean `git status --short` is the watcher: ignore it.
