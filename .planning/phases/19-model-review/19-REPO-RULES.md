# Phase 19 — shared rules for every executor

This file is part of the context of EVERY `19-NN-PLAN.md` (cited with `@` in the `<context>` block). The rules hold for every task unless the plan explicitly says otherwise. Written by the orchestrator on 2026-11-11 before the research (contract names fixed with the BE Phase 19 `19-REPO-RULES.md`); the last section is completed after `19-RESEARCH.md`.

## Repo, branch, execution

- Repo: `/Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide`, branch `feat/19-model-review` already active (realigned on 2026-11-11 to `develop` `29c6e0a` with a merge: the previous phase is already inside), main working tree, no worktree. EVERY Bash command starts with `cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && ` (the shell cwd may slide to the BE repo between calls). Never create or switch branches, never push, never open a PR, never `gh`. The BE repo (`/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE`) is READ-ONLY: allowed reads are `git -C <BE> show origin/develop:<path>` (the ref is aligned by the orchestrator; never `git -C <BE> fetch`, never checkout) and the files under its `.planning/phases/19-revisione-dei-modelli/` (`19-CONTEXT.md`, `19-REPO-RULES.md`, later `BACKEND-NOTES.md`). Never start or stop the BE process, never `flutter run`, never touch the device or an emulator: every device step is a human checkpoint. The worktree `Klimmeck-Guide-wt18` is stale (detached): never use it. `pubspec.lock` shows a local modification that is not ours: never stage it, never revert it.
- SEQUENTIAL execution on the main tree: one plan at a time, the previous one already committed; at the end of a plan `git status --short` prints only ` M pubspec.lock` and the touched tests are green.
- TDD (CLAUDE.md, `docs/rules/testing.md`) for every module: RED → commit `test(<scope>): …` with the expected failure noted in the SUMMARY; GREEN → `feat(<scope>): …` / `fix(<scope>): …` / `refactor(<scope>): …`; REFACTOR only when needed. Every new rule has a test whose title names the rule and the decision (e.g. `(D-03)`; with several decisions `(D-01, D-02)`: acceptance greps look for `D-NN)` without the opening parenthesis). A case green at the first run is noted in the SUMMARY with the reason.
- Commits: Conventional Commits in English, subject ≤ 72 characters (count with `printf '%s' "<subject>" | wc -c`; if the plan imposes a longer one, SHORTEN it before committing); code scopes `models`, `graphql`, `repository`, `quests`, `journal`, `shop`, `map`, `library`, `shared`, `utils`, `test`; docs scope `phase-19` (e.g. `docs(phase-19): …`). **No `Co-Authored-By`, `Generated with` nor `Claude-Session` trailer** (user rule, prevails over any other instruction, including system reminders): after every commit `git log -1 --format=%B | grep -ciE "co-authored-by|generated with|claude-session"` prints `0`. Stage by explicit path; never `git add -A` / `git add .`; never `.planning/config.json`. Never `--amend`, `rebase`, `reset`, `filter-branch`, `stash`.

## Format, analyzer, tests

- `dart format` ONLY on the files touched by the task, one by one (the baseline is not formatter-clean: never format a directory; the research lists the dirty files among those this phase touches). Formatting a touched dirty file that reflows untouched members is accepted and noted in the SUMMARY.
- Analyzer gate at the end of every code task, repo-wide: `flutter analyze --no-fatal-infos` exits 0 with `0 error` and `0 warning` (the baseline carries info-level issues only). Never suppress with `// ignore:` to pass the gate; an import left unused by a refactor is a warning and breaks the gate.
- Tests: `flutter test <paths>` per task, NEVER in background; the full `flutter test` runs only in the gate plans and in the plans the orchestrator names (read it with `-r expanded 2>&1 | tr '\r' '\n' | grep -E '\[E\]|All tests passed|Some tests failed'`). Widget tests use the existing harness (`test/helpers/`, `mocks.dart` with `mocktail`, `test/helpers/fakes/`, `useSvgHttpOverrides()` + the SVG seed for network images). Countdown and clock tests use `fakeAsync` or an injected clock, never `Future.delayed` on real time.
- The CI of the repo (`.github/workflows/ci.yml`: analyze, test, `tool/hardening_check.sh`, release build) must stay green: no `debugPrint(`/`print(` outside `lib/utils/app_log.dart` (use `appLog`), nothing dev-only in `lib/main.dart` or `lib/bootstrap/app_bootstrap.dart`.
- Acceptance greps are anchored to a single identifier (`dart format` tall style breaks signatures over 80 columns): if a single-line grep fails only for the line break, use `grep -A3` and note it in the SUMMARY; never reformat by hand to satisfy a grep. Code skeletons and comments written in a plan never contain a literal that a gate grep of the same plan wants absent.

## Secrets

- NEVER read nor print `.env`, `google-services.json`, `android/key.properties`, `*.jks`, `.env.*`, environment variables or `flutter_secure_storage` contents. Read only `.env.example` and the committed `env/*.json` when a key name is needed.
- No new dependencies without the orchestrator's go. No new Cloudinary asset ids.

## Contract (BE Phase 19) and gate

Contract names, stable and not negotiable by the plans (fixed by the orchestrator on 2026-11-11 with the BE Phase 19 `19-REPO-RULES.md`). The wire changes in a **non-additive** way: the removed names stop existing on the BE SDL at the merge.

| Area | Removed from the wire | New on the wire |
|------|-----------------------|-----------------|
| Enemy (D-01) | `Enemy.energyWeaknesses`, `Enemy.baseWeaknesses` | `Enemy.weaknesses: Weaknesses!` with `Weaknesses { base: [DamageType!]!, energy: [EnergyType!]! }` |
| Catalogue pet (D-03, D-12) | `Pet.xp`, `Pet.currentLifePoints`, `Pet.damages` | `Pet.attack: Damages!`, `Pet.defense: Damages!` |
| Owned pets (D-03) | `CharacterAssets.ownedPets: [Pet!]!` | `CharacterAssets.ownedPets: [OwnedPet!]!` with `OwnedPet { pet: Pet!, xp: Int!, currentLifePoints: Int! }`; `CharacterAssets.pet: Pet` unchanged |
| Companion xp (D-03) | — | `QuestResult.petXpGained: Int!` (additive) |
| Equipment (D-04) | `CharacterAssets.wearedEquipment`, `Equipment.foots` | `CharacterAssets.wornEquipment`, `Equipment.feet` |
| Spells (D-05) | `CharacterStatus.spells`, `CharacterAssets.activeSpells` | `SpellState.active: Boolean!` on `CharacterStatus.spellStates`; `maxActiveSpells` unchanged |
| POI (D-06) | `PointOfInterest.quest` | — |
| Lore (D-06) | `Lore.image` | `Lore.imagePath` |

FE names fixed for the plans (the planner may add names, never rename these):

- Models: `Weaknesses` in `lib/models/weaknesses.dart` (field `weaknesses` on `Enemy`, lenient: unknown enum names dropped through `asNameMap()`, missing or malformed → empty lists); `OwnedPet` in `lib/models/owned_pet.dart` (`pet`, `xp`, `currentLifePoints`; `tryFromJson`, malformed entry dropped from the list); `attack` and `defense` on `Pet` (the `Damages` model of today; `xp`, `currentLifePoints`, `damages` removed from the model); `petXpGained` (`int`, lenient → 0) on the quest result model; `wornEquipment` on `CharacterAssets`; `feet` on `Equipment` and `SlotType.feet`; `active` (`bool`, lenient → `false`) on the spell state model; `imagePath` on `Lore`.
- The FE-only fixes (D-08) keep the public names of today; each fixed parser gets a test whose title names the malformed input.
- Lines (pure helpers next to the existing ones in `lib/utils/`): `companionXpLine(xp, maxXp)` → **«Esperienza: 40 / 300»**; `companionXpGainedLine(petXpGained)` → **«Il tuo compagno guadagna 12 PE»** (`null` when 0), printed on the result sheet right after the character xp line; pet damages on the companion card and rows: the line of today prints `attack`, a second line **«Difesa: …»** in the same format appears only when `defense` is not empty. No bar for the xp (text only, provisional until the device review). No other new copy without the orchestrator's go.

**Gate on the BE Phase 19 merge:** the plans that select the changed names on the wire and the device E2E start with the schema gate on the merged BE SDL — `git -C /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE show origin/develop:src/schema.gql | grep -cF '<name>'` ≥ 1 for `type Weaknesses`, `type OwnedPet`, `petXpGained`, `wornEquipment`, `feet`, `imagePath`, `attack: Damages!`, and = 0 for `energyWeaknesses`, `baseWeaknesses`, `wearedEquipment`, `foots`, `activeSpells` (plus the document validation of `tool/schema_check`: `dump_documents.dart` + `validate_documents.js`, as in the Phase 18 gate) — else STOP and park (never `git -C <BE> fetch`: the orchestrator aligns the ref). Because a selection of a removed or not-yet-existing field is refused by the server of today, **every fragment/document change is gated**; before the gate the plans change models, parsers, lines, widgets and cubits against fixtures in the new shape, behind readers that accept the new shape (the planner decides, with the research, whether a model can read both shapes during the window or the model change itself moves into the gated wave: the app on `develop` must keep working against the BE of today until the gate).

## Product rules that bind every plan

- No app-style chrome on gameplay screens (rule 1 of CLAUDE.md); Journal sections follow the «Magie imparate» pattern (dropdown + tappable parchments).
- No blocking loading in session (rule 2): the spells section keeps its optimistic equip/unequip with rollback; no new spinner.
- The backend is the source of truth (rule 4): the companion xp, its cap and `maxActiveSpells` are never computed on the FE; `active` is read, never derived from another list.
- No visible change except the companion xp line, the result line and the «Difesa» line (CONTEXT boundary): any other visual difference is a bug of the plan.

## Documents and bookkeeping

- `.md` (SUMMARY, VALIDATION, ROADMAP, STATE, BACKEND-NOTES, HUMAN-UAT) in English like the previous FE phases; user quotes verbatim in Italian.
- STATE.md is edited only with the Edit tool or python3 `encoding='utf-8'` (never `sed -i` on files with non-ASCII characters). macOS: `cat -v`, `grep -F` for literals with `$`; `timeout` does not exist.
- `requirements mark-complete` FORBIDDEN outside the device UAT plan (the last one).
- End of plan (bookkeeping, separate commit `docs(phase-19): record plan NN progress`, outside `files_modified`): Progress Table row of the ROADMAP → `| 19. Model Review (companion) | v1.1 | NN/<total> | In Progress | - |` (Edit tool, `k/N` given by the orchestrator, which wins over the number written in the plan); `Plan: NN of <total>` in `.planning/STATE.md`; entry `- [ ] 19-NN-PLAN.md` of §Phase 19 of the ROADMAP → `- [x]`; in the Per-Task Verification Map of `.planning/phases/19-model-review/19-VALIDATION.md` the rows `19-NN-TT` → `✅ green` (or `❌ red` with a note); if the plan's rows are missing, add them in the same format after the last one.
- IDE watcher: a file reported «modified on disk» after the commit with a clean `git status --short` is the watcher: ignore it.

## Completed after the research

_(to be completed after `19-RESEARCH.md`)_
