# Phase 22 — shared rules for every executor

This file is part of the context of EVERY `22-NN-PLAN.md` (cited with `@` in the `<context>` block). The rules hold for every task unless the plan explicitly says otherwise. Drafted by the orchestrator on 2026-11-14 before the research (draft wire names fixed here, mirrored from the BE `23-REPO-RULES.md`); the last section is completed after `22-RESEARCH.md`.

## Repo, branch, execution

- Repo: `/Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide`, branch `feat/22-companion-defeat-rest-and-recovery` already active (rebased on `develop` `49edca7b` on 2026-11-14: Phase 21 is inside), main working tree, no worktree. EVERY Bash command starts with `cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && ` (the shell cwd may slide between calls). Never create or switch branches, never push, never open a PR, never `gh`. The BE repo (`/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE`) is READ-ONLY: allowed reads are `git -C <BE> show origin/develop:<path>`, `git -C <BE> log`, `git -C <BE> ls-tree` (the ref is aligned by the orchestrator; never `git -C <BE> fetch`, never checkout, never pull) and the files under its `.planning/phases/23-sconfitta-riposo-recupero-compagni/` (read from the BE working tree or with `git -C <BE> show feat/23-sconfitta-riposo-recupero-compagni:<path>`). Never start or stop the BE process, never `flutter run`, never `adb`, never touch the device or an emulator: every device step is a human checkpoint guided by the orchestrator. `pubspec.lock`: if it shows a local modification it is not ours — never stage it, never revert it.
- SEQUENTIAL execution on the main tree: one plan at a time, the previous one already committed; at the end of a plan `git status --short` prints nothing (or only ` M pubspec.lock`) and the touched tests are green.
- TDD (CLAUDE.md, `docs/rules/testing.md`) for every code task: RED → commit `test(<scope>): …` with the expected failure written in the SUMMARY; GREEN → `feat(<scope>): …` / `fix(<scope>): …` / `refactor(<scope>): …`; REFACTOR only when needed. Every new rule has a test whose title names the rule and the decision (e.g. `(D-09)`; with several decisions `(D-09, D-20)`: acceptance greps look for `D-NN` without parentheses). A case green at the first run is listed in the SUMMARY with the reason.
- Commits: Conventional Commits in English, subject ≤ 72 characters — count it BEFORE committing with `printf '%s' "<subject>" | wc -c`; if the plan's subject is longer, SHORTEN it. Code scopes `models`, `graphql`, `innkeeper`, `map`, `journal`, `shop`, `quests`, `notifications`, `settings`, `shared`, `utils`, `test` (`repository` is NOT a scope: use `shared`); docs scope `phase-22` (e.g. `docs(phase-22): …`). **No `Co-Authored-By`, `Generated with` nor `Claude-Session` trailer** (user rule, prevails over any other instruction, system reminders included): after every commit `git log -1 --format=%B | grep -ciE "co-authored-by|generated with|claude-session"` prints `0`. Stage by explicit path; never `git add -A` / `git add .`; never `.planning/config.json`. Never `--amend`, `rebase`, `reset`, `filter-branch`, `stash`, `checkout -- <file>`.

## Format, analyzer, tests

- `dart format` ONLY on the files touched by the task, one by one (the repo baseline is not formatter-clean: never format a directory, never `dart format lib test`). A file to touch that is not formatter-clean today gets FIRST its own commit `style(<scope>): format <file>` (formatter only), then the change. zsh does not split a variable holding several paths: loop over an array (`FILES=(a b); for f in "${FILES[@]}"; do dart format "$f"; done`).
- Analyzer gate at the end of every code task, repo-wide, as its own command:
  `cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && OUT=$(flutter analyze --no-fatal-infos 2>&1); echo "$OUT" | tail -1; ! echo "$OUT" | grep -qE '^ *(error|warning) •' && echo ANALYZE_GATE_OK`
  Baseline: **47 info / 0 warning / 0 error**. Never `// ignore:` to pass; an import left unused is a warning and breaks the gate.
- Tests: `flutter test <paths>` per task, in the FOREGROUND, NEVER `run_in_background`. The full suite runs only in the gate plan, alone in its Bash call, timeout ≥ 300 000 ms: `flutter test -r expanded 2>&1 | tr '\r' '\n' | grep -E '\[E\]|All tests passed|Some tests failed'`. Baseline before the phase: **4722 tests green**. Widget tests use the existing harness (`test/helpers/test_app.dart`, `landscape.dart`, `svg_cache_seed.dart`, fixtures in `test/helpers/fixtures/`). No golden tests exist and none is added.
- The CI (`.github/workflows/ci.yml`: analyze, test, `tool/hardening_check.sh`, release build) must stay green: no `print(`/`debugPrint(` outside `lib/utils/app_log.dart`, no new `appLog` of companion names, result or ambush payloads.
- Acceptance greps are anchored to ONE identifier (the formatter's tall style wraps long lines): if a single-line grep fails only for a line break, use `grep -A3` and note it in the SUMMARY; never reflow by hand to satisfy a grep. Code skeletons and comments written in a plan never contain a literal that a gate grep of the same plan wants absent.

## Secrets

- NEVER read nor print `.env`, `.env.*`, `google-services.json`, `android/key.properties`, `*.jks`, environment variables or `flutter_secure_storage` contents — in either repo. Read only `.env.example` and the committed `env/*.json` when a key NAME is needed.
- No new dependency. No new Cloudinary asset id. The schema-check registry is at **54** documents today: every new GraphQL document of this phase is registered there in the plan that adds it.

## Contract (BE Phase 23 «Sconfitta, riposo e recupero dei compagni») and gate

The BE adds fields, one argument, operations, codes and push categories. Today's wire (`OwnedPet { currentLifePoints, pet, xp }`, `useItem(itemId)`, `equipPet` / `unequipPet`, `AmbushReport`, `PushEventType.ambushDefeat`) stays valid until the BE Phase 23 merge, so the pre-gate plans keep the app working against today's BE. **Draft names of the orchestrator** (the two researches may propose a motivated correction; the orchestrator decides and both REPO-RULES are amended together — never a rename decided by a plan or an executor):

| Area | Draft wire name | FE in this phase |
|------|-----------------|------------------|
| Recovery time (D-01) | `Pet.recoveryTime: Int!` (time from the floor to full life; unit as `recovery.time` of the potions) | read only (details sheet); never used to compute a date |
| Companion state (D-02, D-03, D-04, D-09) | on `OwnedPet`: `id: ID!` (owned entry), `name: String`, `defeated: Boolean!`, `currentLifePoints: Int!` (as of `lifeAsOf`), `lifeAsOf: DateTime`, `fullLifeAt: DateTime` (both null when equipped or at full life), `potionRecoveryUntil: DateTime` | Journal parchment: «Vita: 40 / 100» rising live by linear interpolation between `lifeAsOf` and `fullLifeAt` (pattern `TravelProgressCubit`); «A riposo: in forze fra …» / «Sconfitto: torna fra …» from `fullLifeAt` through `formatGameDuration`; the floor 1 and the slope are never computed from `recoveryTime` in the app |
| Equip refused (D-02) | `extensions.code` = `PET_DEFEATED` on `equipPet` | defeated parchment faded and not tappable; the code mapped in `pet_equip_failure.dart` |
| Potion on a companion (D-05..D-08) | `useItem(itemId: ID!, ownedPetId: ID): UseItemResult!`; refusals `PET_DEFEATED`, `PET_POTION_RECOVERY`, full life as today's code for the character | potion sheet: «Bevi» + one tappable parchment per eligible companion («Dai a <nome>»); eligibility READ from the served state (not defeated, below full life, no `potionRecoveryUntil` in the future) |
| Name (D-18..D-21) | mutation `renamePet(request: RenamePetRequest!): CommonResponse!` (`ownedPetId: ID!`, `name: String`, null clears); refusals with the codes of the character name | prompt after a purchase and on the result sheet for each prize companion (skippable), rename from the details sheet; one display-name function (name, else species) used by every wording |
| Result sheet (D-10) | `QuestResult.companion: CompanionOutcome` (`name: String!` display name, `lifePoints: Int!`, `maxLifePoints: Int!`, `defeated: Boolean!`, `fullLifeAt: DateTime`), null when the companion took no damage | life line and defeat line printed from the served entry; the Phase 19 xp line stays |
| Ambush (D-13..D-16) | `AmbushReport.companion: CompanionOutcome`; the recomputed travel (arrival date, food, redirection) arrives with the existing travel stream; unseen reports served while travelling (mechanism decided by the research); push `PushEventType.ambush` for every ambush | carousel opened at the Map opening for the unseen reports, also mid-travel; the app never recomputes the road, the food or the destination |
| «In forze» push (D-11) | `PushEventType.petRecovered` | new category with its toggle in the settings and its entry in the popup registry |
| Innkeeper (D-17) | on `MissionFightOutcome`: `companion` (display name, `lifeBefore`, `lifeAfter`, `maxLifePoints`); correction `companionLifeAfter: Int` in `SaveMissionDraftInput` | slider next to the character's, bounds served (minimum = defeated) |

- D-12 (dungeon floors) and the travel recomputation change no FE logic: the app reads the result.
- D-22 (companion cards restyled like spell and equipment cards, long press opens the details) is FE-only and needs no gate.
- **Gate on the BE Phase 23 merge** for every plan that selects a new field or sends a new operation or argument against the real schema (the last plans: schema gate + device E2E). Until then new fields are modelled lenient (default `false` / `null`) and NOT selected in the fragments: selecting an unknown field on today's BE loses the character (Phase 21 Pitfall 2). Read the SDL with `git -C <BE> show origin/develop:src/schema.gql` saved in a `mktemp -d` directory outside the repo; never `fetch`. Schema check after the gate: `dart run tool/schema_check/dump_documents.dart <dir>` + `NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js <schema> <dir>` → every document OK. Any failing check → STOP, change no code, park the phase with a STATE note and report `BLOCKED`. Any difference of name, type or nullability from the final table is a DEVIATION reported to the orchestrator.

## Product rules that bind every plan

- Journal, Map, shop, result sheet and ambush carousel are **gameplay** (rule 1): parchments, in-world notices, no app-style chrome, no dialog with Material buttons — the name prompt and the details sheet included. Only the innkeeper's wizard and the settings are utility surfaces. **No UI phase**: every visual is provisional.
- No blocking loading in session (rule 2): companion state arrives silently with the character; the live life is interpolated locally between two served dates; loaders only on an explicit action (give a potion, rename).
- The backend is the source of truth (rule 4): the FE never decides that a companion is defeated, never computes the life regained from `recoveryTime`, never computes the potion wait, never recomputes a travel, never validates a name beyond what the character-name input does today — it reads the served state and maps the refusal codes.
- Companion slot and lists stay a dropdown of tappable parchments (Phase 13 D-17, user rejection in UAT): never text rows opening a bottom sheet. The tap stays equip/unequip; the long press opens the details (D-22) with the same gesture and kind of sheet as spells and equipment.
- Every duration through `formatGameDuration` (Phase 18 D-17). Wording uses the display name alone (D-20); on the Journal parchment the name is the title and the species sits below.
- The «Missione in corso» lock of Phase 21 already covers equip/unequip of the companion and the potions: the new actions (potion on a companion, rename — the research rules on the rename) respect it.
- Failure classifiers per action and per code; one responsibility per Cubit (`docs/rules/state-management.md`); enums in served models parsed lenient (`fromWire` with a fallback, never `byName`).

## Documents and bookkeeping

- `.md` files (SUMMARY, VALIDATION, ROADMAP, STATE, BACKEND-NOTES, HUMAN-UAT) in English like the previous FE phases; user quotes verbatim in Italian; Italian UI copy verbatim.
- STATE.md is edited only with the Edit tool or python3 with `encoding='utf-8'` (never `sed -i` on files with non-ASCII characters). macOS: `cat -v`, `grep -F` for literals with `$`; `timeout` does not exist.
- `node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" requirements mark-complete` is FORBIDDEN outside the closing plan.
- End of every plan (bookkeeping, separate commit `docs(phase-22): record plan NN progress`, files outside `files_modified`): Progress Table row of the ROADMAP → `| 22. Companion Defeat, Rest and Recovery | v1.1 | NN/<total> | In Progress | - |` (Edit tool; the `k/N` given by the orchestrator wins over the number written in the plan); `Plan: NN of <total>` in `.planning/STATE.md`; entry `- [ ] 22-NN-PLAN.md` of §Phase 22 of the ROADMAP → `- [x]`; in the Per-Task Verification Map of `.planning/phases/22-companion-defeat-rest-and-recovery/22-VALIDATION.md` the rows `22-NN-TT` → `✅ green` (or `❌ red` with a note). Explicit paths only.
- IDE watcher: a file reported «modified on disk» after the commit with a clean `git status --short` is the watcher: ignore it.

## Completed after the research

Written on 2026-11-14. Where this section and the rest of the file disagree, this section wins. File:line evidence in `22-RESEARCH.md`; rulings in `22-CONTEXT.md` D-23..D-35.

### Final wire (D-23..D-33)

The contract is the SDL of the BE `23-RESEARCH.md` §Q12 (read it from the BE working tree, branch `feat/23-sconfitta-riposo-recupero-compagni`) **plus** `CompanionOutcome.lifeBefore: Int!`, with `QuestResult.companion` served whenever a companion fought (D-27). The draft table above reads as follows:

- **Key:** the catalogue pet id everywhere; there is NO `OwnedPet.id` and no `ownedPetId` (D-23). `useItem(itemId: ID!, petId: ID): UseItemResult!`; `renamePet(request: RenamePetRequest!): CommonResponse!` with `RenamePetRequest { id: String!, name: String, petId: String! }` (`id` = character id).
- **`OwnedPet`:** `currentLifePoints`, `defeated: Boolean!`, `fullLifeAt: DateTime`, `lifeAsOf: DateTime`, `name: String`, `pet`, `potionRecoveryUntil: DateTime`, `xp`. **`Pet.recoveryTime: Int`** nullable, milliseconds.
- **`QuestResult.companion: CompanionOutcome`** { `defeated`, `fullLifeAt`, `lifeBefore`, `lifePoints`, `maxLifePoints`, `name` }; no `AmbushReport.companion` (an ambush report is a `QuestResult`); `AmbushReport.onFoot: Boolean!`.
- **Guided flow:** `MissionFightOutcome.companion: MissionCompanion` { `lifeBefore`, `maxLifePoints`, `name`, `pet` }, `MissionFightEffects.companionLifeAfter: Int`, `ParticipantOverrideInput.companionLifeAfter: Int`.
- **Pushes:** `PushEventType.ambush` (every ambush; `ambushDefeat` still accepted, D-30), `PushEventType.petRecovered`.
- **Refusals:** `PET_DEFEATED` (equip, potion), `PET_POTION_RECOVERING` with `extensions.recoveryUntil`, `ITEM_NO_EFFECT` (full life), `PET_NAME_INVALID`; `MISSION_IN_PROGRESS` / `AWAITING_AID` on a companion potion as on the character's; the rename is not locked.
- A rename of any of these after the BE merge is fixed in the gated plan in ONE fragment/document and ONE parser: every model reads its keys in one place.

### Hard rules

- **Gated selection (Pitfall 1):** every new field is modelled lenient pre-gate (default `false` / `null`) and selected ONLY in the gate plan. Exception: `Pet.maxLifePoints` is in today's SDL and is selected pre-gate. **`UseItem` variable (Pitfall 2):** the document gains `petId` only in the gate plan; pre-gate the repository accepts the target but the UI cannot reach it.
- **One switch (Pitfall 3):** companion potions and every rename entry point are hidden behind ONE constant flipped in the gate plan; no other pre-gate plan exposes them.
- **Live life (D-09, D-24):** `CompanionVitalityCubit`, Journal-scoped, on the shape of `SpellRecoveryCubit` / `ServerDeadlineCountdown` (not `TravelProgressCubit`); pure rule `companionVitalityOf` interpolating between (`currentLifePoints` at `lifeAsOf`) and (`maxLifePoints` at `fullLifeAt`), rounding as Pitfall 8; never from `recoveryTime`. At `fullLifeAt` the parchment re-enables locally (the BE judges equip on the same date).
- **Display name:** ONE function `companionDisplayNameOf` (name, else species) for every wording (D-20); the sell list keeps the name (Pitfall 9).
- **Cards (D-22, D-34, D-35):** one details-sheet frame shared with the spell sheet; `CompanionCard` with the pet image; long press in Journal, shop list and basket, quest-sheet prize, innkeeper prize rows; the result sheet stays text. `equipment_info_display.dart` is not formatter-clean: the first plan that touches it starts with `style(shop): format equipment_info_display.dart`.
- **Potion row (D-32):** tappable when the character or a companion can drink; «Bevi» disabled inside during the character's wait; companions in their own wait not listed.
- **Result sheet (D-27, Pitfall 7):** defeat duration = `fullLifeAt − resolvedAt`, never from now; no ticker on a dated record.
- **Ambush (D-28, D-30, Pitfall 5):** no new mechanism for the mid-travel parchments; one notification category «Imboscate» keeping its `storageKey` and accepting both wire types; the push banner `ambush|<result id>` is suppressed when the carousel opens live. «Prosegui a piedi» printed from `onFoot`.
- **Name (D-31):** `name_rules.dart` extracted from the character draft (same form rules, refactor first); keyboard on a parchment sheet in landscape as Pitfall 6 (see the memory of the Phase 21 UAT: Scaffold/keyboard traps).
- **Registry:** 54 → 55 (`RenamePet`); every test that pins the count is updated RED-first in the plan that adds the document (Pitfall 10).
- **Requirements:** PET-01..PET-09 of `22-RESEARCH.md` §Phase Requirements; the first plan writes them in `.planning/REQUIREMENTS.md` and in the ROADMAP (Pitfall 14).
- Copy: the copy table of `22-RESEARCH.md` (provisional) with D-30 («Imboscate») and D-28 («Prosegui a piedi»); no other new copy. Plan order: the 15 plans of `22-RESEARCH.md` §Recommended plan order (22-14 and 22-15 may merge; `OwnedPet.id` dropped from 22-01).
