---
phase: 17
slug: unlockable-lore
audited: 2026-11-07T14:00:00Z
status: secured
asvs_level: 1
block_on: high
threats_total: 32
threats_mitigated: 21
threats_accepted: 5
threats_transferred: 0
threats_open: 0
threats_open_blocking: 0
threats_deferred: 6
open_ids: []
deferred_ids: [T-17-25, T-17-26, T-17-27, T-17-29, T-17-30, T-17-31]
updated: 2026-11-07
---

# Phase 17 - Security (Unlockable Lore, FE)

Audit of the threat registers of plans 17-01..17-10 (32 rows, T-17-01..T-17-32) against HEAD `ab8a7e7` of `feat/17-unlockable-lore` (base `develop` `f560d1d`, review fixes of `17-REVIEW-FIX.md` included). Plans 17-09 (schema gate vs merged BE Phase 16 SDL) and 17-10 (device E2E, handoff, traceability) are gated on the BE merge and not yet executed: their process threats are DEFERRED, not open. BE-side guarantees that the FE mitigations lean on are owned by the BE (BE 16-CONTEXT D-01/D-02 sets on the character, D-03/D-04 geography at birth and arrival, D-05/D-06 filtered queries and `known` per viewer, D-07 study roll, D-08 `loreUnlocked`, D-10 backfill); the BE repo was not read or touched. No command read `.env`, `google-services.json` or environment variables. Implementation files read only.

## Threat register

| ID | STRIDE | Component | Disposition | Evidence | Note |
|----|--------|-----------|-------------|----------|------|
| T-17-01 | DoS | `Lore.fromJson` type parsing | mitigated | `lib/models/lore.dart:35` (`wire is String ? asNameMap()[wire] : null`); `test/models/lore_test.dart` | unknown type keeps the entry |
| T-17-02 | DoS | `CharacterStatus.fromJson` `unlockedLore` | mitigated | `lib/models/character/character_status.dart:79,89-92,137` (non-list -> `[]`, strings only, unmodifiable, carried by `copyWith`); `test/models/character/` | |
| T-17-03 | DoS | `statusFields` ahead of the BE | accepted | CONTEXT D-13/D-14; fragment `character_fragment.dart:65` | proven in 17-09 before any device run |
| T-17-04 | DoS | `QuestEnemy.fromJson` | mitigated | `lib/models/quest/quest_enemy.dart:28-29` (`known is! bool` -> `FormatException`); `test/models/quest/` | no default `true` |
| T-17-05 | Info disclosure | FE inferring knowledge | mitigated | `quest_enemy.dart:14,38,88,92` (field, strict parse, `toJson`, `props`); `quest_info_sheet.dart:222`; `quest_result_sheet.dart:257` | `known` read as received; `?? true` only when no strongest entry exists |
| T-17-06 | DoS | fragments ahead of the BE | accepted | CONTEXT D-13/D-14; `quest_fragment.dart:23`, `quest_result_fragment.dart:95` | proven in 17-09 |
| T-17-07 | DoS | `QuestResult._loreUnlockedFrom` | mitigated | `lib/models/quest_result/quest_result.dart:125,168-182` (non-list -> `[]`, per-entry try/catch, no name -> dropped); `test/models/quest_result/` | |
| T-17-08 | Tampering | lore names on the sheet | mitigated | `lib/shared/components/popup/quest_result_sheet.dart:58,164-189` plain `Text` via `_line` | no markup, no links |
| T-17-09 | Repudiation | client deciding what was learned | mitigated | lines built only from `loreUnlocked` (`quest_result.dart:125`, sheet); `test/shared/components/popup/quest_result_sheet_test.dart` | no outcome-based lore branch |
| T-17-10 | Info disclosure | `EnemyPortrait` unknown enemy | mitigated | `lib/shared/components/enemy_portrait.dart:30,69` (`BlendMode.srcIn` ColorFiltered); `test/shared/components/enemy_portrait_test.dart` | image file still downloaded (cosmetic, noted in plan) |
| T-17-11 | Repudiation | knowledge from `outcome` | mitigated | `grep outcome enemy_portrait.dart` = 0; sheets pass `known` as received; `quest_result_sheet_test.dart`, `quest_info_sheet_test.dart` | |
| T-17-12 | Tampering | `klimmeck.library.*` keys | accepted | CONTEXT D-07; `library_bookmarks_store.dart:25` | cosmetic, never sent to the BE |
| T-17-13 | Info disclosure | baselines of two characters | mitigated | `keyFor(characterId, book)` in `library_bookmarks_store.dart`; `test/repository/storage/library_bookmarks_store_test.dart` | BE decides what `lores` returns (BE D-05) |
| T-17-14 | Tampering | session namespace | mitigated | `keyPrefix = 'klimmeck.library'` (`:25`); `grep klimmeck.session` in the store = 0; store test | |
| T-17-15 | DoS | `syncUnlockedLore` refetch storm | mitigated | `library_cubit.dart:68` (`setEquals`), `:69` skip, `:78` `_isRefreshing`, `:58` one trailing refresh; `test/screens/mainScreen/tabs/library/cubit/` | |
| T-17-16 | Tampering | stale completion reopening a book | mitigated | `library_cubit.dart:27,35,47,57` generation counter; review fix `9964450`; cubit tests | |
| T-17-17 | DoS | blocking UI mid-session | mitigated | `LibraryLoading` only at `library_cubit.dart:36` (`openBook`), `LibraryError` only at `:42`; refresh path `:69-130` never emits them | rule 2 |
| T-17-18 | Elev. of privilege | FE deciding visibility | mitigated | cubit filters by book type only; no `knownEnemies` (0 hits); BE-filtered `lores` | BE 16 D-05/D-06 |
| T-17-19 | Info disclosure | locked lore on the page | mitigated | page renders `state.lore`; `test/screens/mainScreen/tabs/library/library_data_page_test.dart` | BE 16 D-05 |
| T-17-20 | DoS | lore without name/description | mitigated | `LoreCard` null-safe; `test/screens/mainScreen/tabs/library/components/` | |
| T-17-21 | Tampering | edited device baseline | accepted | CONTEXT D-07 | at worst wrong «Nuovo» ribbons |
| T-17-22 | DoS | `_openCityLore` null lore | mitigated | `lib/screens/mainScreen/tabs/map/world_map.dart:445-447` null check -> `UnknownCityModal`; `grep "relatedLore!" lib` = 0 | |
| T-17-23 | Info disclosure | probing a locked city lore | mitigated | no `lore(id)` call on the null branch (`world_map.dart:447`); `world_map_*_test.dart` `verifyNever` | BE 16 D-02/D-06 |
| T-17-24 | DoS | mid-session cold-start screen | mitigated | `main_screen_cubit.dart:33-53` (`refreshCities`, no `MainScreenLoading`, `_isRefreshing`), `MainScreenLoading` only at `:20` (`loadData`); `main_screen_cubit_test.dart` | |
| T-17-25 | Tampering | BE working tree (17-09) | deferred | plan 17-09 not executed | read-only refs only |
| T-17-26 | Info disclosure | `.env` / identity values (17-09) | deferred | plan 17-09 not executed | audit itself read no `.env` |
| T-17-27 | DoS | documents ahead of the BE | deferred | plan 17-09 schema gate (45/45) | registry unchanged at 45 |
| T-17-28 | Tampering | client unlock logic / cubit wiring | mitigated | sanity greps of this audit (below) all clean: no `knownEnemies`, `.stream.listen`, `relatedLore!`, `outcome` in portrait; lore queries unchanged | 17-09 will repeat them |
| T-17-29 | Info disclosure | `17-HUMAN-UAT.md`, BACKEND-NOTES | deferred | plan 17-10 not executed | |
| T-17-30 | Repudiation | requirement traceability | deferred | plan 17-10 not executed | |
| T-17-31 | Spoofing | UAT as innkeeper | deferred | plan 17-10 not executed | player identity required |
| T-17-32 | Tampering | BE repo and DB seeds | accepted | plan 17-10 | handled by user/orchestrator outside repo |

## Cross-cutting checks

All run from the repo root, read-only.

- `grep -rn "print(" <models, storage, library, cubit, unknown_city_modal, enemy_portrait>`: no `print(`. `debugPrint` hits: `library_cubit.dart:41,102,121,130` and `main_screen_cubit.dart:65`; each prints a fixed label plus the caught `$e`, never a response body or lore content. Note: `library_cubit.dart:42` puts `e.toString()` into `LibraryError` state (pre-existing pattern).
- `git diff f560d1d..HEAD --name-only -- lib/graphql`: `character_fragment.dart`, `quest_fragment.dart`, `quest_result_fragment.dart` only. `unlockedLore` once (`character_fragment.dart:65`); `known` once each under `enemies` (`quest_fragment.dart:23`, `quest_result_fragment.dart:95`, other hits are comments); `loreUnlocked {` once (`quest_result_fragment.dart:88`); `unlocked` in `lore_queries.dart` = 0; `git diff -- lib/graphql/queries` = empty.
- Registry: `test/tool/schema_check_documents_test.dart:32-33` still expects 45; `git diff --name-only -- tool` empty.
- `relatedLore!` in lib = 0; `outcome` in `enemy_portrait.dart` = 0; `known` in `quest_enemy.dart`: field, strict parse, `toJson`, `props`, no default.
- `LibraryLoading`/`LibraryError` emitted only in `openBook` (`library_cubit.dart:36,42`); `MainScreenLoading` emitted only at `main_screen_cubit.dart:20`.
- `klimmeck.library` only at `library_bookmarks_store.dart:25`; `klimmeck.session` in the store = 0; `writeSeen` stores only a sorted list of lore ids under a per-character/book key.
- Copy constants: `Nuova pagina del Bestiario` 1, `Non conosci ancora questa città` 1, `Le pagine di questo libro sono ancora bianche` 1, `Sagoma del nemico` 1; `Conoscenza appresa` 3 (constant `quest_result_sheet.dart:58`, plus two doc comments in `lore.dart:33` and `lore_type.dart:48`): one constant, no divergence.
- `.stream.listen` in library tab and `main_screen.dart` = 0.
- `git log f560d1d..HEAD --format=%B | grep -ciE "co-authored-by|generated with|claude-session"` = 0.
- `.env`/`google-services` hits in lib are all pre-existing (`main.dart`, auth services, `env_config.dart`); added lines in the diff matching them = 0. `git diff -- pubspec.yaml` empty; `--name-only -- lib/config` empty.

## Open

None.

## Deferred

- T-17-25, T-17-26, T-17-27: plan 17-09 (schema gate of the 45 documents against the merged BE Phase 16 SDL, read-only BE refs, no `.env` reads); also proves the accepted T-17-03 / T-17-06.
- T-17-29, T-17-30, T-17-31: plan 17-10 (device E2E with a player identity, no secrets in `17-HUMAN-UAT.md`/BACKEND-NOTES, requirements ticked only for passed steps).
