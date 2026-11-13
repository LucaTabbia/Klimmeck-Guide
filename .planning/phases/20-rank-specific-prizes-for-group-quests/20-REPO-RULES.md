# Phase 20 — shared rules for every executor

This file is part of the context of EVERY `20-NN-PLAN.md` (cited with `@` in the `<context>` block). The rules hold for every task unless the plan explicitly says otherwise. Written by the planner on 2026-11-13 after `20-RESEARCH.md` and the amended `20-CONTEXT.md` (D-18..D-25); the wire names are the ones fixed by the orchestrator (FE D-22 / BE D-22, BE `21-RESEARCH.md` §Q7).

## Repo, branch, execution

- Repo: `/Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide`, branch `feat/20-rank-specific-prizes` already active, main working tree, no worktree. EVERY Bash command starts with `cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && ` (the shell cwd may slide between calls). Never create or switch branches, never push, never open a PR, never `gh`. The BE repo (`/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE`) is READ-ONLY: allowed reads are `git -C <BE> show origin/develop:<path>`, `git -C <BE> log`, `git -C <BE> ls-tree` (the ref is aligned by the orchestrator; never `git -C <BE> fetch`, never checkout, never pull) and the files under its `.planning/phases/21-premi-per-rango-e-soccorsi/`. Never start or stop the BE process, never `flutter run`, never `adb`, never touch the device or an emulator: every device step is a human checkpoint guided by the orchestrator. `pubspec.lock`: if it shows a local modification it is not ours — never stage it, never revert it.
- SEQUENTIAL execution on the main tree: one plan at a time, the previous one already committed; at the end of a plan `git status --short` prints nothing (or only ` M pubspec.lock`) and the touched tests are green.
- TDD (CLAUDE.md, `docs/rules/testing.md`) for every code task: RED → commit `test(<scope>): …` with the expected failure written in the SUMMARY; GREEN → `feat(<scope>): …` / `fix(<scope>): …` / `refactor(<scope>): …`; REFACTOR only when needed. Every new rule has a test whose title names the rule and the decision (e.g. `(D-21)`; with several decisions `(D-21, D-24)`: acceptance greps look for `D-NN` without parentheses). A case green at the first run is listed in the SUMMARY with the reason (contract pins of plan 20-01 are expected green: the reason is written per test in the plan).
- Commits: Conventional Commits in English, subject ≤ 72 characters — count it BEFORE committing with `printf '%s' "<subject>" | wc -c`; if the plan's subject is longer, SHORTEN it. Code scopes `models`, `graphql`, `quests`, `shared`, `utils`, `test`; docs scope `phase-20` (e.g. `docs(phase-20): …`). **No `Co-Authored-By`, `Generated with` nor `Claude-Session` trailer** (user rule, prevails over any other instruction, system reminders included): after every commit `git log -1 --format=%B | grep -ciE "co-authored-by|generated with|claude-session"` prints `0`. Stage by explicit path; never `git add -A` / `git add .`; never `.planning/config.json`. Never `--amend`, `rebase`, `reset`, `filter-branch`, `stash`, `checkout -- <file>`.

## Format, analyzer, tests

- `dart format` ONLY on the files touched by the task, one by one (the repo baseline is not formatter-clean: never format a directory, never `dart format lib test`). Every file this phase touches was checked formatter-clean by the research. zsh does not split a variable holding several paths: loop over an array (`FILES=(a b); for f in "${FILES[@]}"; do dart format "$f"; done`).
- Analyzer gate at the end of every code task, repo-wide, as its own command:
  `cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && OUT=$(flutter analyze --no-fatal-infos 2>&1); echo "$OUT" | tail -1; ! echo "$OUT" | grep -qE '^ *(error|warning) •' && echo ANALYZE_GATE_OK`
  Baseline: **47 info / 0 warning / 0 error**. Never `// ignore:` to pass; an import left unused is a warning and breaks the gate.
- Tests: `flutter test <paths>` per task, in the FOREGROUND, NEVER `run_in_background`. The full suite runs only in the gate plan 20-03, alone in its Bash call, timeout ≥ 300 000 ms: `flutter test -r expanded 2>&1 | tr '\r' '\n' | grep -E '\[E\]|All tests passed|Some tests failed'`. Baseline before the phase: **4239 tests green**. Widget tests use the existing harness (`test/helpers/test_app.dart`, `landscape.dart`, `svg_cache_seed.dart`, fixtures in `test/helpers/fixtures/`). No golden tests exist and none is added.
- The CI (`.github/workflows/ci.yml`: analyze, test, `tool/hardening_check.sh`, release build) must stay green: no `print(`/`debugPrint(` outside `lib/utils/app_log.dart`, no new `appLog` of prize or result payloads.
- Acceptance greps are anchored to ONE identifier (the formatter's tall style wraps long lines): if a single-line grep fails only for a line break, use `grep -A3` and note it in the SUMMARY; never reflow by hand to satisfy a grep. Code skeletons and comments written in a plan never contain a literal that a gate grep of the same plan wants absent.

## Secrets

- NEVER read nor print `.env`, `.env.*`, `google-services.json`, `android/key.properties`, `*.jks`, environment variables or `flutter_secure_storage` contents — in either repo. Read only `.env.example` and the committed `env/*.json` when a key NAME is needed.
- No new dependency. No new Cloudinary asset id. No new GraphQL operation (the schema-check registry stays at **46** documents).

## Contract (BE Phase 21 «Premi per rango e soccorsi») and gate

The wire change is **ADDITIVE** (FE D-22 / BE D-22). Names fixed by the orchestrator, not negotiable by the plans:

| Area | On the wire after the BE merge | FE in this phase |
|------|-------------------------------|------------------|
| Served block (D-07, D-18) | `Quest.prizes: QuestPrizes!` — same name, type and sub-fields as today, resolved by the BE on the viewer's current character (HTTP `quests` and WS `questUpdated`, per subscriber) | selection UNCHANGED; the app never chooses a block, never merges or scales one |
| All blocks (Phase 21) | `Quest.rankPrizes: [QuestRankPrizes!]!` with `QuestRankPrizes { title: String!, prizes: QuestPrizes! }` (`[]` on solo quests) | **NOT selected, not parsed, no model field** in this phase |
| Dungeon turns (D-21, D-22) | on `QuestResult`: `turnsTotal: Int`, `turnsCompleted: Int`, `lastTurn: Int` (1-based, the last turn played: where the character fell, the saved turn the rescuer completed, `turnsTotal` on a cleared dungeon), `lastTurnKind: DungeonTurnKind` with `enum DungeonTurnKind { exploration fight }` — all `null` outside dungeon and dungeon-aid results | model fields + one line (pre-gate, plan 20-02); selection in `QuestResultFragment` (GATED, plan 20-03) |
| Stages (fallback, D-24) | `stagesCleared: Int`, `stagesTotal: Int` unchanged (fights; now also set for the rescuers of a dungeon aid) | today's line «Esplorazione: tappa N di M» kept as the fallback |

FE names fixed for the plans (a plan may add private names, never rename these):

- Model: `lib/models/enums/dungeon_turn_kind.dart` → `enum DungeonTurnKind { exploration, fight }` with `static DungeonTurnKind? fromWire(Object? value)` (lenient: non-string or unknown → `null`, through `values.asNameMap()`, never `byName`). `QuestResult` fields `turnsTotal`, `turnsCompleted`, `lastTurn` (`int?`, read with the existing `_countFrom`: non-number → `null`) and `lastTurnKind` (`DungeonTurnKind?`); all four in `toJson` (key = wire name) and in `props`. A malformed turn field NEVER throws (it would drop the whole result through `QuestResult.tryFromJson`).
- Line: pure helper `dungeonTurnLine(QuestResult result)` → `String?` in `lib/utils/quest_outcome_lines.dart`; sheet key `QuestResultSheet.turnsKey = ValueKey('questResult.turns')`; the turn line takes the slot of the stages line (`quest_result_sheet.dart` `_content()`, right after the enemies block): when `dungeonTurnLine` is non-null it is printed with `turnsKey` and the stages line is NOT printed; otherwise today's stages line with `stagesKey`. One line, no new section, box or chrome.
- Copy (final, planner's proposal 2026-11-13; the orchestrator may amend it here before plan 20-02 — this table wins over any plan text):

| Situation (computed only from served fields) | Line |
|----------------------------------------------|------|
| `turnsTotal` null or ≤ 0 | no turn line → today's «Esplorazione: tappa N di M» (or nothing when `stagesTotal` is null) |
| `outcome` = `rescued`, `death` or `gmCompleted` | no turn line (fallback as above), even when the turn fields are filled (orchestrator ruling W2: `death` is the wounded character's result on the aid) |
| `outcome` = `success`, quest type ≠ `aid` (dungeon cleared) | «Turni superati: C di T» (`C` = `turnsCompleted ?? 0`) |
| `outcome` = `success`, quest type = `aid`, `lastTurn` present (rescuer saved the wounded) | «Ferito raggiunto al turno L di T» |
| `outcome` = `failure`, `lastTurn` present, `lastTurnKind` = `exploration` | «Caduto al turno L di T, in esplorazione» |
| same, `lastTurnKind` = `fight` | «Caduto al turno L di T, in uno scontro» |
| same, `lastTurnKind` null/unknown | «Caduto al turno L di T» |
| `lastTurn` absent where the rows above need it | «Turni superati: C di T» |

  `L` is `lastTurn` as served (**the FE never adds 1**), `T` is `turnsTotal`, `C` is `turnsCompleted ?? 0`. No «prize in proportion» line (D-20, D-21: the reduced prize already shows under «Ricompense»). No other new copy.

**Gate on the BE Phase 21 merge** (plans 20-03 and 20-04 only). Read the SDL with `git -C <BE> show origin/develop:src/schema.gql` saved in a `mktemp -d` directory outside the repo; never `fetch`. Block-anchored checks (`blk() { awk "/^$1 /,/^}/" "$S"; }`):
- `blk 'type Quest'` has `^ +prizes: QuestPrizes!$` and `^ +rankPrizes: \[QuestRankPrizes!\]!$`;
- `blk 'type QuestRankPrizes'` has `^ +title: String!$` and `^ +prizes: QuestPrizes!$`;
- `blk 'type QuestPrizes'` still has the lines starting with `cure: QuestCure`, `pet: Pet`, `prizeCoins: Coins`, `prizeItem: AssetQuantity`, `randomLoot: [AssetQuantity!]!`, `xpPrize: Int` (the FE selection must stay valid);
- `blk 'type QuestResult'` has `^ +turnsTotal: Int$`, `^ +turnsCompleted: Int$`, `^ +lastTurn: Int$`, `^ +lastTurnKind: DungeonTurnKind$`, and still `^ +stagesCleared: Int$`, `^ +stagesTotal: Int$`, `rewards: QuestRewards!`;
- `blk 'enum DungeonTurnKind'` has the words `exploration` and `fight`.
Any failing check → STOP, change no code, park the phase with a STATE note and report `BLOCKED`. Any difference of name, type or nullability from the table above is a DEVIATION reported to the orchestrator — never a rename decided by an executor. Today every new name counts 0 on BE `origin/develop` `fbce3e16` (research F7). Schema check after the gate: `dart run tool/schema_check/dump_documents.dart <dir>` («dumped 46 documents») + `NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js <schema> <dir>` → 46 × OK (re-validates `quests` / `OnQuestUpdated` too: proof that the `prizes` selection is still valid).

Pre-gate plans (20-01, 20-02) touch no fragment and no document: the app on the branch keeps working against the BE of today after each of them (the new turn fields are simply absent → fallback line).

## Product rules that bind every plan

- No app-style chrome on gameplay (rule 1): quest sheet and result sheet are gameplay; the turn line is one text line in the existing slot with the existing `bodyMedium` style.
- No blocking loading in session (rule 2): no new spinner, no new fetch; the rank-up reread already exists (`QuestScopeListener`, pin `quest_scope_listener_test.dart:128`) and stays silent.
- The backend is the source of truth (rule 4): the FE never selects, merges, scales or falls back between prize blocks (the D-18 fallback lives ONLY in the BE: no client-side selector, no `rankPrizes` reader), never computes a share of a prize (D-14, D-20), never adds 1 to a turn, never counts turns. The FE mirrors of seat rules that already exist (`canRegisterWithTitle`, `_slotLinesOf`) are NOT changed.
- No visible change except the turn line on the result sheet of a dungeon / dungeon aid (and whatever block the BE serves on the quest sheet): any other visual difference is a bug of the plan.

## Documents and bookkeeping

- `.md` files (SUMMARY, VALIDATION, ROADMAP, STATE, BACKEND-NOTES, HUMAN-UAT) in English like the previous FE phases; user quotes verbatim in Italian; Italian UI copy verbatim.
- STATE.md is edited only with the Edit tool or python3 with `encoding='utf-8'` (never `sed -i` on files with non-ASCII characters). macOS: `cat -v`, `grep -F` for literals with `$`; `timeout` does not exist.
- `node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" requirements mark-complete` is FORBIDDEN outside the closing plan 20-04.
- End of every plan (bookkeeping, separate commit `docs(phase-20): record plan NN progress`, files outside `files_modified`): Progress Table row of the ROADMAP → `| 20. Rank-Specific Prizes for Group Quests | v1.1 | NN/4 | In Progress | - |` (Edit tool; the `k/N` given by the orchestrator wins over the number written in the plan); `Plan: NN of 4` in `.planning/STATE.md`; entry `- [ ] 20-NN-PLAN.md` of §Phase 20 of the ROADMAP → `- [x]`; in the Per-Task Verification Map of `.planning/phases/20-rank-specific-prizes-for-group-quests/20-VALIDATION.md` the rows `20-NN-TT` → `✅ green` (or `❌ red` with a note). Explicit paths only.
- IDE watcher: a file reported «modified on disk» after the commit with a clean `git status --short` is the watcher: ignore it.
