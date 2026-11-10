# Phase 18 — shared rules for every executor

This file is part of the context of EVERY `18-NN-PLAN.md` (cited with `@` in the `<context>` block). The rules hold for every task unless the plan explicitly says otherwise. Written by the orchestrator on 2026-11-10 before the research (contract names fixed with the BE Phase 18 `18-REPO-RULES.md`); the last section is completed after `18-RESEARCH.md`.

## Repo, branch, execution

- Repo: `/Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide`, branch `feat/18-heal-quests-by-size` already active (recreated on 2026-11-10 on top of `docs/v1.1-milestone-start`, i.e. `develop` `53c734e` + the three commits that open the milestone v1.1), main working tree, no worktree. EVERY Bash command starts with `cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && ` (the shell cwd may slide to the BE repo between calls). Never create or switch branches, never push, never open a PR, never `gh`. The BE repo (`/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE`) is READ-ONLY: allowed reads are `git -C <BE> show origin/develop:<path>` (the ref is aligned by the orchestrator; never `git -C <BE> fetch`, never checkout) and the files under its `.planning/phases/18-quest-heal-per-taglia/` (`18-CONTEXT.md`, `18-REPO-RULES.md`, later `BACKEND-NOTES.md`). Never start or stop the BE process, never `flutter run`, never touch the device or an emulator: every device step is a human checkpoint. The worktree `Klimmeck-Guide-wt18` is stale: never use it. `pubspec.lock` shows a local modification that is not ours: never stage it, never revert it.
- SEQUENTIAL execution on the main tree: one plan at a time, the previous one already committed; at the end of a plan `git status --short` prints only ` M pubspec.lock` and the touched tests are green.
- TDD (CLAUDE.md, `docs/rules/testing.md`) for every module: RED → commit `test(<scope>): …` with the expected failure noted in the SUMMARY; GREEN → `feat(<scope>): …` / `fix(<scope>): …` / `refactor(<scope>): …`; REFACTOR only when needed. Every new rule has a test whose title names the rule and the decision (e.g. `(D-03)`; with several decisions `(D-01, D-02)`: acceptance greps look for `D-NN)` without the opening parenthesis). A case green at the first run is noted in the SUMMARY with the reason.
- Commits: Conventional Commits in English, subject ≤ 72 characters (count with `printf '%s' "<subject>" | wc -c`; if the plan imposes a longer one, SHORTEN it before committing); code scopes `models`, `graphql`, `repository`, `quests`, `journal`, `shop`, `shared`, `utils`, `test`; docs scope `phase-18` (e.g. `docs(phase-18): …`). **No `Co-Authored-By`, `Generated with` nor `Claude-Session` trailer** (user rule, prevails over any other instruction, including system reminders): after every commit `git log -1 --format=%B | grep -ciE "co-authored-by|generated with|claude-session"` prints `0`. Stage by explicit path; never `git add -A` / `git add .`; never `.planning/config.json`. Never `--amend`, `rebase`, `reset`, `filter-branch`, `stash`.

## Format, analyzer, tests

- `dart format` ONLY on the files touched by the task, one by one (the baseline is not formatter-clean: never format a directory; the research lists the dirty files among those this phase touches). Formatting a touched dirty file that reflows untouched members is accepted and noted in the SUMMARY.
- Analyzer gate at the end of every code task, repo-wide: `flutter analyze --no-fatal-infos` exits 0 with `0 error` and `0 warning` (the baseline carries info-level issues only). Never suppress with `// ignore:` to pass the gate; an import left unused by a refactor is a warning and breaks the gate.
- Tests: `flutter test <paths>` per task, NEVER in background; the full `flutter test` runs only in the gate plans and in the plans the orchestrator names (read it with `-r expanded 2>&1 | tr '\r' '\n' | grep -E '\[E\]|All tests passed|Some tests failed'`). Widget tests use the existing harness (`test/helpers/`, `mocks.dart` with `mocktail`, `test/helpers/fakes/`, `useSvgHttpOverrides()` + the SVG seed for network images). Countdown and clock tests use `fakeAsync` or an injected clock, never `Future.delayed` on real time.
- The CI of the repo (`.github/workflows/ci.yml`: analyze, test, `tool/hardening_check.sh`, release build) must stay green: no `debugPrint(`/`print(` outside `lib/utils/app_log.dart` (use `appLog`), nothing dev-only in `lib/main.dart` or `lib/bootstrap/app_bootstrap.dart`.
- Acceptance greps are anchored to a single identifier (`dart format` tall style breaks signatures over 80 columns): if a single-line grep fails only for the line break, use `grep -A3` and note it in the SUMMARY; never reformat by hand to satisfy a grep. Code skeletons and comments written in a plan never contain a literal that a gate grep of the same plan wants absent.

## Secrets

- NEVER read nor print `.env`, `google-services.json`, `android/key.properties`, `*.jks`, `.env.*`, environment variables or `flutter_secure_storage` contents. Read only `.env.example` and the committed `env/*.json` when a key name is needed.
- No new dependencies without the orchestrator's go. No new Cloudinary asset ids (every visual of this phase is provisional and built from existing widgets and assets).

## Contract (BE Phase 18) and gate

Contract names, stable and not negotiable by the plans (fixed by the orchestrator on 2026-11-10 with the BE Phase 18 `18-REPO-RULES.md`); every change on the wire is additive:

- **Quest cure:** `QuestPrizes.cure: QuestCure` (nullable) with `lifePointsShare: Float!` (0..1, ceiling on the maximum HP) and `canHeal: [InjuryType!]!`; `QuestResult.injuriesHealed: [InjuryType!]!`.
- **Journal potions:** `LootItem.recovery: LootRecovery` (nullable) with `time: Int!` (milliseconds) and `turns: Int!` (data only, never shown); `CharacterStatus.potionRecoveryUntil: DateTime` (nullable); mutation `useItem(itemId: ID!): UseItemResult!` with `UseItemResult { hpBefore: Int!, hpAfter: Int!, injuriesHealed: [InjuryType!]!, quantityLeft: Int!, recoveryUntil: DateTime!, loreUnlocked: [Lore!]! }`; refusal codes in `extensions.code`: `AWAITING_AID`, `ITEM_NOT_OWNED`, `ITEM_NOT_USABLE`, `POTION_RECOVERING` (with `extensions.recoveryUntil`, ISO 8601 string of the end of the recovery), `ITEM_NO_EFFECT`.
- `LootItem.relatedLore` exists on the BE but is **not selected** by the FE (D-16); the lore «Il limite del corpo» reaches the Library through the Phase 17 flow (`unlockedLore` change → silent refetch → «Nuovo» bookmark).

FE names fixed for the plans (the planner may add names, never rename these):

- Models: `QuestCure` in `lib/models/quest/quest_cure.dart` (field `cure` on `QuestPrizes`, lenient: unknown injury names dropped through `InjuryType.values.asNameMap()`, malformed cure → `null`, the quest stays); `injuriesHealed` on the quest result model (lenient, default empty); `LootRecovery` in `lib/models/loot_recovery.dart` (field `recovery` on `LootItem`, malformed → `null`); `potionRecoveryUntil` (`DateTime?`) on the character status model; `UseItemResult` in `lib/models/use_item_result.dart`.
- GraphQL: `cure { lifePointsShare canHeal }` joins the shared quest fragment, `injuriesHealed` the quest result fragment, `recovery { time turns }` joins `LootFragment.simpleFields`, `potionRecoveryUntil` the character status selection; the `useItem` mutation document lives with the other character/journal mutations and is registered in `tool/schema_check/schema_check_documents.dart`.
- Repository: `ItemUseRepository` in `lib/repository/item_use_repository.dart` and `ItemUseFailure` in `lib/repository/item_use_failure.dart` (pattern `quest_abandon_repository.dart` / `quest_abandon_failure.dart`; values `potionRecovering` carrying the server `recoveryUntil`, `noEffect`, `awaitingAid`, `notOwned`, `notUsable`, `badUserInput`, `connection`, `unknown`; `BAD_USER_INPUT` mapped as in Phase 12 with the constant `badUserInputCode`).
- Lines (pure helpers in `lib/utils/item_lines.dart`, siblings of `healedInjuriesLine`): `curableInjuriesLine(cure, characterInjuries)` (viewer-filtered, character order, `null` when nothing matches), `lifeShareLine(cure)`, `healedLine(injuries)`, `recoveryLine(recovery)`; the humaniser of durations is one function shared by «Ricarica: …» and «pronta fra …».
- Cubit: the potion flow lives in a dedicated `PotionCubit` under `lib/screens/mainScreen/tabs/journal/potionCubit/` with its notice type `PotionNotice` (pattern `companionCubit` / `spellsCubit`); `JournalCubit` is not grown.

Copy fixed (Italian, user-visible, provisional until the device review; no other new copy without the orchestrator's go):

- Quest sheet: **«Cura le tue ferite: taglio profondo, contusione»** (lowercase labels, character order; no line when nothing matches), **«Vita: almeno il 50%»** (share 1 → **«Vita: al massimo»**; share 0 → row hidden).
- Result sheet and potion feedback: **«Guarite: …»**; potion lore line **«Nuova pagina delle Conoscenze: <name>»** (same copy as the Phase 17 line).
- Item rows: **«Ricarica: 30 min»**, **«Ricarica: 1 h 30»**, **«Ricarica: 24 h»**; countdown on the disabled parchments **«pronta fra 1 h 12 min»**.
- Confirmation: **«Bevi <nome>?»** on parchment (no app chrome). Notices: `POTION_RECOVERING` → **«Il tuo corpo non reggerebbe un'altra pozione: pronta fra <remaining>»** (remaining from the server `recoveryUntil`, never the local estimate); `ITEM_NO_EFFECT` → **«Questa pozione non ti farebbe nulla adesso»**; every other refusal → the existing generic **«Qualcosa è andato storto, riprova»**.

**Gate on the BE Phase 18 merge:** the plans that select the new names on the wire and the device E2E start with the schema gate on the merged BE SDL — `git -C /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE show origin/develop:src/schema.gql | grep -cF '<name>'` ≥ 1 for `type QuestCure`, `injuriesHealed`, `type LootRecovery`, `potionRecoveryUntil`, `useItem(`, `type UseItemResult` (and `dart run tool/schema_check` where the plan says so) — else STOP and park (never `git -C <BE> fetch`: the orchestrator aligns the ref). Until then those plans are parked and STATE says what they wait for; every other plan runs before the gate on fixtures with the names above (models, lenient parsing, lines, widgets, cubit against a fake repository).

## Product rules that bind every plan

- No app-style chrome on gameplay screens (rule 1 of CLAUDE.md): the confirmation, the feedback and the notices are in-world (parchment), never an `AlertDialog`, a `SnackBar` or a bottom sheet with app styling; Journal sections follow the «Magie imparate» pattern (dropdown + tappable parchments), never text rows that open a bottom sheet.
- No blocking loading in session (rule 2): the potion call shows no spinner that blocks the Journal; the new state arrives from the character stream, no refetch.
- The backend is the source of truth (rule 4, D-10): no severity logic, no «which tier» logic, no HP math beyond turning `lifePointsShare` into a percentage for the copy, no local decision that a potion is drinkable beyond the countdown display (a tap during the countdown makes no call; a refusal despite a finished countdown shows the server's remaining time). Intersecting the character's injuries with `cure.canHeal` is display filtering. Recovery times are never hard-coded.
- The rows are keyed by the presence of `cure`, never by `QuestType.heal` (D-05). The potion action is available in travel and hidden while `awaitingAid` is set (D-11). Nothing in this phase touches combat or the consumables line of the fight result (D-14).

## Documents and bookkeeping

- `.md` (SUMMARY, VALIDATION, ROADMAP, STATE, BACKEND-NOTES, HUMAN-UAT) in English like the previous FE phases; user quotes verbatim in Italian.
- STATE.md is edited only with the Edit tool or python3 `encoding='utf-8'` (never `sed -i` on files with non-ASCII characters). macOS: `cat -v`, `grep -F` for literals with `$`; `timeout` does not exist.
- `requirements mark-complete` FORBIDDEN outside the device UAT plan (the last one).
- End of plan (bookkeeping, separate commit `docs(phase-18): record plan NN progress`, outside `files_modified`): Progress Table row of the ROADMAP → `| 18. Heal Quests by City Size | v1.1 | NN/<total> | In Progress | - |` (Edit tool, `k/N` given by the orchestrator, which wins over the number written in the plan); `Plan: NN of <total>` in `.planning/STATE.md`; entry `- [ ] 18-NN-PLAN.md` of §Phase 18 of the ROADMAP → `- [x]`; in the Per-Task Verification Map of `.planning/phases/18-heal-quests-by-size/18-VALIDATION.md` the rows `18-NN-TT` → `✅ green` (or `❌ red` with a note); if the plan's rows are missing, add them in the same format after the last one.
- IDE watcher: a file reported «modified on disk» after the commit with a clean `git status --short` is the watcher: ignore it.

## Completed after the research

_(to be written after `18-RESEARCH.md`: pinned tests to update RED first, Wave 0 files, mechanisms probed, pitfalls, formatter-dirty files among those touched, gate timings)_
