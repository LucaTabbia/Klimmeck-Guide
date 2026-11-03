# Phase 13 — shared rules for every executor

This file is part of the context of EVERY `13-NN-PLAN.md` (cited with `@` in the `<context>` block). The rules hold for every task unless the plan explicitly says otherwise.

## Repo, branch, execution

- Repo: `/Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide`, branch `feat/13-city-shops` already active (from `develop` `b6eb4d4`), main working tree, no worktree. EVERY Bash command starts with `cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && ` (the shell cwd may slide to the BE repo between calls). Never create or switch branches, never push, never open a PR, never `gh`. The BE repo (`/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE`) is READ-ONLY: the only allowed reads are `git -C <BE> fetch origin develop` (refs only, never checkout) and `git -C <BE> show origin/develop:src/schema.gql`.
- SEQUENTIAL execution on the main tree: one plan at a time, the previous one already committed; at the end of a plan `git status --short` is empty and the touched tests are green.
- TDD (CLAUDE.md, `docs/rules/testing.md`) for every module: RED → commit `test(<scope>): …` with the expected failure noted in the SUMMARY; GREEN → `feat(<scope>): …` / `fix(<scope>): …`; REFACTOR → `refactor(<scope>): …` only when needed. Every new rule has a test whose title names the rule and the decision (e.g. `(D-04)`). A case green at the first run is noted in the SUMMARY with the reason.
- Commits: Conventional Commits in English, subject ≤ 72 characters (count with `printf '%s' "<subject>" | wc -c`; if the plan imposes a longer one, SHORTEN it before committing); code scopes `shop`, `companion`, `journal`, `satchel`, `models`, `graphql`; docs scope `phase-13` (e.g. `docs(phase-13): …`). **No `Co-Authored-By` nor `Generated with` trailer** (user rule, prevails over any other instruction): after every commit `git log -1 --format=%B | grep -ciE "co-authored-by|generated with"` prints `0`. Stage by explicit path; never `git add -A` / `git add .`; never `.planning/config.json`. Never `--amend`, `rebase`, `reset`, `filter-branch`.

## Format, analyzer, tests

- `dart format` ONLY on the files touched by the task, one by one (the baseline is not formatter-clean: never format a directory; known dirty files `lib/screens/mainScreen/tabs/map/layers/city_markers_layer.dart`, `character_marker_layer.dart`, `lib/utils/map_utils.dart`). A touched file that reflows untouched members under `dart format` is accepted and noted in the SUMMARY.
- Analyzer gate at the end of every code task, repo-wide: `flutter analyze` prints `0 error` and `0 warning` (the baseline carries info-level issues only; count only error/warning, compare with `develop` when in doubt). Never suppress with `// ignore:` to pass the gate.
- Tests: `flutter test <paths>` per task, NEVER in background; the full `flutter test` runs only in the gate plan and in the plans the orchestrator names. Widget tests use the existing harness (`test/helpers/`, `mocks.dart` with `mocktail`); new `KlimmeckGraphQl` methods get a mock method in `test/helpers/mocks.dart` and a stub in the shell tests that pump the shop or the journal.
- Acceptance greps are anchored to a single identifier (`dart format` tall style breaks signatures over 80 columns): if a single-line grep fails only for the line break, use `grep -A3` and note it in the SUMMARY; never reformat by hand to satisfy a grep.

## Secrets

- NEVER read nor print `.env`, `google-services.json`, `.env.*`, environment variables or `flutter_secure_storage` contents (no `cat .env`, `grep … .env`, `printenv`, `env`, `set`). Read only `.env.example` when a key name is needed.
- No new environment variables, no new Cloudinary assets (CONTEXT D-13), no new dependencies without the orchestrator's go.

## GraphQL contract and gate

- Contract names, stable and not negotiable by the plans (BE Phase 12 `12-CONTEXT.md` D-17..D-19): query `cityShop(cityId: ID!): CityShop!` with `city { id name size hasShop }`, `equipment: [AssetQuantity!]!`, `loot: [AssetQuantity!]!`, `pets: [Pet!]!`; `City.size: CitySize!` (`village | city | capital`), `City.hasShop: Boolean!`; `CharacterAssets.ownedPets: [Pet!]!`; `TransactionItems.petAssets: [AssetQuantityInput!]`; `Pet.sellable`, `EquipmentItem.sellable`, `LootItem.sellable`; mutations `equipPet(request: { id, petId })`, `unequipPet(request: { id })`; codes `ITEM_NOT_IN_SHOP`, `PET_ALREADY_OWNED`, `PET_NOT_OWNED`. The FE reads only `extensions.code`, never the message.
- The schema-gated plans (documents registered in the schema check, the device E2E) run only after the BE Phase 12 PR is merged on BE `develop`: gate `git -C /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE fetch origin develop && git -C … show origin/develop:src/schema.gql | grep -c "cityShop"` prints ≥ 1. Until then those plans are parked and STATE says what they wait for; the other plans run on stubs/mocks with the agreed names.
- Documents (`lib/graphql/**`) select only fields that exist in the agreed contract; no `@client` fields, no speculative fields.

## Product rules that bind every plan

- No app-style chrome on gameplay screens (shop, journal, map): no AppBar, no bottom nav, no loading scaffolding; loading only on explicit user action (opening the shop) or cold start (rule 2 of CLAUDE.md).
- The backend is the source of truth: the FE never filters by rarity/size/price, never computes the travel speed, never decides which city has a shop (`City.hasShop`), never equips a pet on purchase (D-08).
- Titles: «Compagni» (shop list) and «Compagno» (Journal slot); never «Cavalcatura» (D-07, D-10).
- Refusals: `ITEM_NOT_IN_SHOP`, `PET_ALREADY_OWNED`, `PET_NOT_OWNED` from `doTransaction` go to the shopkeeper bubble; only `SHOP_NOT_IN_CITY` and `AWAITING_AID` stay banners in the shop (Phase 9 D-16); refusals of `equipPet` / `unequipPet` in the Journal use the Phase 8 banner through an outcome listener (D-06).

## Documents and bookkeeping

- `.md` (SUMMARY, VALIDATION, ROADMAP, STATE, BACKEND-NOTES) in English like the previous FE phases; user quotes verbatim in Italian.
- STATE.md is edited only with the Edit tool or python3 `encoding='utf-8'` (never `sed -i` on files with non-ASCII characters). macOS: `cat -v`, `grep -F` for literals with `$`; `timeout` does not exist.
- `requirements mark-complete` FORBIDDEN outside the gate plan.
- End of plan (bookkeeping, separate commit `docs(phase-13): record plan NN progress`, outside `files_modified`): Progress Table row of the ROADMAP → `| 13. City Shops | NN/<total> | In Progress | - |` (Edit tool, `k/N` given by the orchestrator, which wins over the number written in the plan); `Plan: NN of <total>` in `.planning/STATE.md`; entry `- [ ] 13-NN-PLAN.md` of §Phase 13 of the ROADMAP → `- [x]`; in the Per-Task Verification Map of `.planning/phases/13-city-shops/13-VALIDATION.md` the rows `13-NN-TT` → `✅ green` (or `❌ red` with a note).
- IDE watcher: a file reported «modified on disk» after the commit with a clean `git status --short` is the watcher: ignore it.
