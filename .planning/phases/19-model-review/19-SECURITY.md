---
phase: 19
slug: model-review
audited: 2026-11-11T11:58:00Z
status: secured
asvs_level: 1
block_on: high
threats_total: 56
threats_mitigated: 54
threats_accepted: 2
threats_transferred: 0
threats_open: 0
threats_open_blocking: 0
threats_deferred: 0
open_ids: []
deferred_ids: []
unregistered_flags: 3
updated: 2026-11-11T13:10:00Z
---

# Phase 19 - Security (Model Review, frontend companion)

Audit of the threat registers of plans 19-01..19-13 (56 rows, T-19-01..T-19-56) against the code tree of `c5df6ec3` on `feat/19-model-review` (base `88443fa`, 89 commits, review fixes of `19-REVIEW-FIX.md` included; HEAD `7897713c` adds only `19-HUMAN-UAT.md`). Evidence is the final code (read-only) and the tests named below, read and not run: a Gradle build was running on the tree, so `flutter test` / `flutter build` were not started; pass counts are those of `19-12-SUMMARY.md` (full suite 4216 green, analyzer 47 info / 0 warning / 0 error). Only `tool/hardening_check.sh` (greps, no Flutter) was executed. The BE repo was not read: the gate outputs are taken from `19-10/11/12-SUMMARY.md` and `19-HUMAN-UAT.md`. No command read `.env`, `google-services.json`, `key.properties`, `*.jks` or environment variables. The local modification of `pubspec.lock` is not ours and was ignored.

Status legend: CLOSED = mitigation found in code and pinned by a test (or accepted risk logged below); PENDING = the mitigation is an action of plan 19-13 (device E2E) not executed yet; OPEN = mitigation declared and not found. No `transfer` disposition is declared in this phase.

## Threat Register

| ID | STRIDE | Component | Disposition | Status | Evidence | Note |
|----|--------|-----------|-------------|--------|----------|------|
| T-19-01 | DoS | `PointOfInterest.fromJson` (`type`, `location`) | mitigate | CLOSED | `lib/models/enums/poi_type.dart:34-38` (`asNameMap`, non-list -> null); `lib/models/point_of_interest.dart:24,32-37`; `test/models/point_of_interest_test.dart:34,52,63,67,71` | unknown type name dropped, POI kept; device step 9 reads the real data |
| T-19-02 | DoS | `Enemy.fromJson` (weaknesses, `locations`) | mitigate | CLOSED | `lib/models/weaknesses.dart:10-21` (never throws); `lib/models/enemy.dart:37-38`; `test/models/weaknesses_test.dart:17,27`, `test/models/enemy_test.dart:26,43` | |
| T-19-03 | Tampering | hiding a broken POI location | accept | CLOSED | accepted risk AR-19-01; strict path kept at `point_of_interest.dart:34-36`, pinned by `point_of_interest_test.dart:84` | |
| T-19-04 | DoS | `Damages.fromJson` in the character payload | mitigate | CLOSED | `lib/models/damages.dart:11-19`; `lib/models/base_damage.dart:12-18`, `lib/models/energy_damage.dart:13-19`; `test/models/damages_test.dart:27,42,55,69,80` | |
| T-19-05 | DoS | `null` damage type reaching `type!` | mitigate | CLOSED | entry dropped when the type is unknown or missing (`base_damage.dart:15`, `energy_damage.dart:16`); `damages_test.dart:100` «every parsed entry has a non-null type (D-16)»; the strict `fromJson` factories are deleted (review IN-01) | |
| T-19-06 | DoS | `Spell.energyDamage.type`, `CharacterStatus.title` | mitigate | CLOSED | `lib/models/spell.dart:34`; `lib/models/character/character_status.dart:73`; `test/models/spell_test.dart:17,26`, `test/models/character/character_status_test.dart:594,604` | |
| T-19-07 | DoS | owned items / equipment | mitigate | CLOSED | `lib/models/asset_quantity.dart:18-25`; `lib/models/character/character_assets.dart:29-30,42-44`; `test/models/asset_quantity_test.dart:27,36,45,54`, `test/models/character/character_assets_test.dart:150,164,206` | |
| T-19-08 | DoS | shop pool (equipment, loot, pets) | mitigate | CLOSED | `lib/models/city_shop.dart:22-26,35-41`; `test/models/city_shop_test.dart:56,68,84,97` | pets through `Pet.tryFromEntryJson` (review WR-02) |
| T-19-09 | DoS | worn slots | mitigate | CLOSED | `lib/models/equipment.dart:27-37`; `lib/models/equipment_item.dart:58-65`; `test/models/equipment_test.dart:37,48,60` | |
| T-19-10 | DoS | every city of the Map at cold start | mitigate | CLOSED | `lib/models/city.dart:60-67`; `lib/repository/services/graphql/graphql.dart:318`; `test/models/city_test.dart:50,54`, `test/repository/services/graphql/graphql_get_cities_test.dart:33,81` | see unregistered flag UF-19-02 |
| T-19-11 | Tampering | lenient `null` enum moving the crash into a build | mitigate | CLOSED | strict `byName` kept: `lib/models/loot_item.dart:47,50`, `lib/models/equipment_item.dart:38,50`, `lib/models/city.dart:35`; `city_test.dart:60` «City.fromJson stays strict»; the nullable rarity the SDL allows is read null-safe (review WR-01): `equipment_item_card.dart:105`, `equipment_name.dart:35`, `equipment_info_sheet.dart:80`, each with «a null rarity falls back to the default ink (D-16)» | no `rarity!` left in `lib` |
| T-19-12 | Info disclosure | logging a dropped payload | mitigate | CLOSED | one log line added in the whole phase: `graphql.dart:320` `appLog('[Cities] skipped $skipped malformed cities')` (a count); `graphql_get_cities_test.dart:50,68`; check A/B | |
| T-19-13 | DoS | one malformed owned pet | mitigate | CLOSED | `lib/models/owned_pet.dart:15-22`; `character_assets.dart:38-40`; `test/models/owned_pet_test.dart:19,38,76,83`, `character_assets_test.dart:177` | |
| T-19-14 | Tampering | FE inventing the companion state | mitigate | CLOSED | `owned_pet.dart:18-21`: `xp` / `currentLifePoints` read from the entry only, an entry without numbers is dropped; the window branch (neutral zeros) is deleted: `owned_pet_test.dart:88` «a bare catalogue pet map is dropped (D-03, D-15)» | |
| T-19-15 | Tampering (stale contract) | window branch outliving the gate | mitigate | CLOSED | branch absent from `owned_pet.dart`; `owned_pet_test.dart:88`; check E | |
| T-19-55 | DoS | unknown pet rarity | mitigate | CLOSED | `lib/models/pet.dart:44` (`asNameMap`); `test/models/pet_test.dart:186,193` | |
| T-19-16 | Tampering | missed rebuild on pet xp | mitigate | CLOSED | `owned_pet.dart:35`, `character_assets.dart:55-61`; `owned_pet_test.dart:54`, `character_assets_test.dart:124` | |
| T-19-17 | Tampering | client cap / progress rule for companion xp | mitigate | CLOSED | `lib/utils/item_lines.dart:46-49` (two served numbers, no clamp, text only); single reader `owned_companion_row.dart:30`; `test/utils/item_lines_test.dart:130` «prints the served numbers without clamping (D-03)» | device steps 3, 7 |
| T-19-18 | Tampering | client sum / ranking of pet damages | mitigate | CLOSED | `item_lines.dart:58-72` (join in the served order, no arithmetic); `item_lines_test.dart:141,172` | |
| T-19-19 | Info disclosure | companion life shown | mitigate | CLOSED | no reader of `OwnedPet.currentLifePoints` outside `lib/models` (check C); `test/screens/mainScreen/tabs/journal/sections/companion_section_test.dart:367` | selected on the wire (`character_fragment.dart:96`), parsed, never drawn |
| T-19-56 | Tampering | new rarity presentation for pets | mitigate | CLOSED | `companion_card.dart:49`, `companion_row.dart:65-72`: only `RarityType.color`, no colour literal in the three widgets; `companion_card_test.dart:167,175,184`, `companion_row_test.dart:107,121` | |
| T-19-20 | DoS | layout overflow with four labels | mitigate | CLOSED | `lib/shared/components/cards/card_label.dart` (one auto-sized line); `companion_card_test.dart:150` | legibility of a long attack line is a device observation (review IN-08, steps 1 and 3) |
| T-19-21 | Tampering | FE computing the companion share or cap | mitigate | CLOSED | `lib/utils/quest_outcome_lines.dart:35-36`; `quest_result_sheet.dart:189-192`; no `maxXp` / enemy xp in either (check C); `test/utils/quest_outcome_lines_test.dart:72,76`, `quest_result_sheet_test.dart:1120,1144` | device steps 7, 8 |
| T-19-22 | DoS | malformed `petXpGained` | mitigate | CLOSED | `lib/models/quest_result/quest_result.dart:171,220-221`; `test/models/quest_result/quest_result_test.dart:665,672,681` | |
| T-19-23 | Tampering | missed rebuild of the sheet | mitigate | CLOSED | `quest_result.dart:293`; `quest_result_test.dart:695` | |
| T-19-24 | DoS | malformed spell state entry | mitigate | CLOSED | `lib/models/spell/spell_state.dart:29-36`; `character_status.dart:83-87`; `character_status_test.dart:110,118,145`, `test/models/spell/spell_state_test.dart:112` | |
| T-19-25 | DoS | window reader throwing in `Character.fromJson` | mitigate | CLOSED | component removed: `lib/models/character/legacy_spell_states.dart` and its test are deleted, `character.dart:23-37` calls `CharacterStatus.fromJson` directly; `test/models/character/character_test.dart:23,72` | |
| T-19-26 | Tampering | `active` invented by the FE | mitigate | CLOSED | `spell_state.dart:25` (`json['active'] == true`); `spell_state_test.dart:78,83` | |
| T-19-27 | Tampering (stale contract) | window file outliving the gate | mitigate | CLOSED | file deleted; check E | |
| T-19-28 | Tampering | `active` / slot count decided by the FE | mitigate | CLOSED | `lib/models/spell/spellbook.dart:77` (`maxActiveSpells` only), `:79-83` (pending overlay, else `state.active`); `spells_cubit.dart:228-239`; `test/models/spell/spellbook_test.dart:309,404,417` | device steps 4, 5 |
| T-19-29 | Tampering | optimistic order diverging | mitigate | CLOSED | one list order for server and overlay (`spellbook.dart:84-87`); `spellbook_test.dart:186,343,357` | |
| T-19-30 | DoS | window reader on a partial character | mitigate | CLOSED | component removed (see T-19-25); `character_test.dart:72` «a character with a status only, with assets only or with neither still parses» | |
| T-19-31 | Repudiation | pending operation never closed | mitigate | CLOSED | `spells_cubit.dart:79,152,228-239` (`_matches` on `state.active`); the 33 cases of `test/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit_test.dart` | |
| T-19-32 | Tampering (stale contract) | window wiring outliving the gate | mitigate | CLOSED | call site removed from `character.dart`; `character_test.dart:23` «a payload with the legacy spell lists is not translated (D-05, D-15)» | |
| T-19-33 | Tampering (stale contract) | second source of spells on the models | mitigate | CLOSED | `lib/models/active_spell.dart` deleted; no `status.spells` nor equipped list field in `lib` (check E); `character_assets_test.dart:28,35` | |
| T-19-34 | DoS | contraction breaking the window translation | mitigate | CLOSED | moot after the gate (reader deleted); recorded payload still parses: `test/graphql/character_fragment_test.dart:89,106` | |
| T-19-54 | Repudiation | fixture migration changing what a test proves | mitigate | CLOSED | `94667da0` is test-only (10 files, 0 under `lib`); counts 1487 -> 1482 with the five deleted cases named in `19-09-SUMMARY.md` | process evidence |
| T-19-35 | Tampering | BE working tree | mitigate | CLOSED | `19-10-SUMMARY.md:72,96` (read with `show`, never fetched; BE status empty before and after) | process evidence, not re-checked |
| T-19-36 | Info disclosure | `.env`, values in the handoff | mitigate | CLOSED | `19-10-SUMMARY.md` (no `.env` read, names only, SDL outside the repo); check G/H | process evidence |
| T-19-37 | DoS | documents / equip request ahead of the BE | mitigate | CLOSED | `19-10-SUMMARY.md:86` `GATE_OK` before the rename commit (BE `origin/develop` `48b20701`) | |
| T-19-38 | DoS | boots slot silently unequippable | mitigate | CLOSED | `lib/models/enums/slot_type.dart:93`, `lib/models/equipment.dart:32,44`, `equipment_fragment.dart:96`, `equip_item_request.dart:17`; `test/models/equipment_test.dart:85,93`, `test/models/request/equip_item_request_test.dart:6` | device step 6 |
| T-19-39 | Tampering | contract rename decided by an executor | mitigate | CLOSED | `19-10-SUMMARY.md:8` (names confirmed on the SDL, no deviation) | process evidence |
| T-19-40 | DoS | selection of a removed / missing field | mitigate | CLOSED | `19-11-SUMMARY.md:63,149` (`GATE_OK`, 46 x OK after the flip) | |
| T-19-41 | DoS | Journal with nameless spells | mitigate | CLOSED | `lib/graphql/fragments/character_fragment.dart:57-64` (`active` + full `SpellFragment.fields`, known list dropped in the same hunk); `character_fragment_test.dart:56` | device step 4 |
| T-19-42 | Tampering (stale contract) | window reader left in the tree | mitigate | CLOSED | check E prints nothing; `character_test.dart:23`, `owned_pet_test.dart:88` | |
| T-19-43 | Tampering | selecting more than the contract | mitigate | CLOSED | check D: no `weaknesses` in `lib/graphql`; `pet_fragment.dart` selects no `relatedLore`; `location_fragment.dart` = `id location`; `test/graphql/shop_documents_test.dart:84` pins the pet fields | |
| T-19-44 | Tampering | BE working tree / secrets | mitigate | CLOSED | `19-11-SUMMARY.md:63,151` (read-only `show`, BE status empty, scratch outside the repo) | process evidence |
| T-19-45 | DoS | documents ahead of / behind the BE | mitigate | CLOSED | `19-12-SUMMARY.md:8,48` (`GATE_OK`, 46/46) | |
| T-19-46 | Tampering (stale contract) | removed name / window reader left | mitigate | CLOSED | check E re-run in this audit: nothing | |
| T-19-47 | Tampering | rule, chrome, bar or extra selection slipping in | mitigate | CLOSED | `19-12-SUMMARY.md` product-rule greps (one explained hit); checks C and D re-run here | |
| T-19-48 | Tampering / Info disclosure | BE working tree, `.env` | mitigate | CLOSED | `19-12-SUMMARY.md:92` | process evidence |
| T-19-49 | Repudiation | forbidden trailers | mitigate | CLOSED | check I re-run here: 0 over the 89 commits | |
| T-19-50 | Info disclosure | `19-HUMAN-UAT.md`, `BACKEND-NOTES.md` | mitigate | CLOSED (after the device E2E) | both files written by 19-13 Task 3 (`f91b8d10`, `66ef3472`): the grep for a Mongo URI scheme, a query-string credential, a credential word or a numeric twitch id prints 0 on each; no 24-hex id in either | see «After the device E2E» |
| T-19-51 | Repudiation | requirement traceability | mitigate | CLOSED (after the device E2E) | `19-HUMAN-UAT.md` `status: complete`: steps 1–11 `pass` in the user's words before `mark-complete`; `REQUIREMENTS.md` MODEL-01..04 `[x]` / `Complete` in the same commit `f91b8d10` | see «After the device E2E» |
| T-19-52 | DoS | APK against a BE without Phase 19 / non-migrated DB | mitigate | CLOSED | `19-HUMAN-UAT.md:12` (gate re-checked, `GATE_OK` on `48b20701`), `:16,36` (boot runbook as a prerequisite owned by the orchestrator) | the «done» cells are filled at the device run |
| T-19-53 | Tampering | BE repo and DB seeds | accept | CLOSED | accepted risk AR-19-02 | |

## Accepted risks log

| ID | Threat | Risk accepted | Rationale | Owner |
|----|--------|---------------|-----------|-------|
| AR-19-01 | T-19-03 | a present but malformed POI location still throws in `PointOfInterest.fromJson` | D-17: a data defect on the map must surface instead of being hidden; the only tolerated shapes are absent / null / null first element (`point_of_interest.dart:32-37`) | plan 19-01 |
| AR-19-02 | T-19-53 | the device E2E needs seeds and time shortcuts on the development DB and a running BE | handled by the orchestrator outside the repo with the BE's own write shapes; the FE plans touch the BE only through read-only refs (`show`, `log`, `ls-tree`) | plan 19-13 |

## Cross-cutting checks

| Check | What | Result |
|-------|------|--------|
| A | `bash tool/hardening_check.sh` (no APK argument) | `hardening_check: OK` |
| B | log calls added in `git diff 88443fa..HEAD -- lib` | 1: `appLog('[Cities] skipped $skipped malformed cities')` — a count, no payload, id or token; no `print` / `debugPrint` added |
| C | backend as source of truth | `maxXp` read only by `companionXpLine` (`item_lines.dart:46-48`) from `owned_companion_row.dart:30`; `petXpGained` only printed (`quest_outcome_lines.dart:35-36`); no `clamp` / `min(` / `max(` in `item_lines.dart`, `quest_outcome_lines.dart`, `owned_pet.dart`, `pet.dart`, `owned_companion_row.dart`; `OwnedPet.currentLifePoints` has no reader outside `lib/models`; rarity only as `rarity?.color`; `active` read at `spell_state.dart:25`, `spellbook.dart:82`, `spells_cubit.dart:235`; slot count = `max(0, maxActiveSpells)` (`spellbook.dart:77`, pre-existing floor at zero) |
| D | wire | `git diff 88443fa..HEAD -- lib/graphql/mutations lib/graphql/subscriptions lib/models/request` is empty: no new variable; the only new value sent is the enum name `feet` (`equip_item_request.dart:17` + `slot_type.dart:93`). Selections added: `spellStates { active, spell full }`, `wornEquipment` / `feet`, `ownedPets { xp currentLifePoints pet }`, pet `maxXp attack defense rarity`, `petXpGained`, lore `imagePath`. Not selected: pet `relatedLore`, enemy `weaknesses`, POI `type` |
| E | leftovers: `grep -rnE "activeSpells\|wearedEquipment\|foots\|energyWeaknesses\|baseWeaknesses\|WearedEquipment\|legacy_spell_states\|statusJsonWithLegacySpellStates\|\bActiveSpell\b" lib test tool` | nothing; `lib/models/active_spell.dart`, `lib/models/character/legacy_spell_states.dart` and its test are absent; no `lore.image` reader left |
| F | catches added in the phase | 4, all `on Object` at declared entry boundaries: `asset_quantity.dart:22`, `equipment_item.dart:62`, `city.dart:64`, `pet.dart:73`. No catch added in widgets, cubits or the repository. They also swallow an `Error` raised inside the wrapped parser (same pattern as the pre-existing `SpellState`, `Quest`, `PendingRequest` boundaries); the strict parsers stay directly testable |
| G | `git diff --stat 88443fa..HEAD -- pubspec.yaml android ios assets env .github tool` | empty: no dependency, no asset, no CI change; no URL or Cloudinary id added in `lib` |
| H | secrets: changed file names matching `.env`, `key.properties`, `*.jks`, `google-services.json`; added lines with a Mongo URI scheme, a long bearer, `token=`, `password` in `lib test tool` | `0` / `0` |
| I | `git log 88443fa..HEAD --format=%B \| grep -ciE "co-authored-by\|generated with\|claude-session"` | `0` (89 commits) |

## Unregistered flags

The SUMMARYs of plans 01-12 raise no `## Threat Flags` entry. The review fixes (`19-REVIEW-FIX.md`) add three behaviours that no register row covers; none is a blocker (`block_on: high`).

| ID | From | STRIDE | Behaviour | Severity | Suggested disposition |
|----|------|--------|-----------|----------|-----------------------|
| UF-19-01 | WR-02 (`29819bb`) | Tampering (display) / Repudiation | `Pet.tryFromEntryJson` is also the reader of the EQUIPPED pet (`character_assets.dart:34`): a malformed `assets.pet` becomes `null` with no trace, so the Journal slot can look empty while the BE has a companion at the side (travel speed and companion xp stay BE-side). The catch is `on Object`, so a programming error inside `Pet.fromJson` is dropped the same way at the three call sites (owned, pool, equipped). Pinned by `character_assets_test.dart:189` | low | accept (the list boundaries are the declared rule D-16; the slot is an extension of it) or add a count-only `appLog` |
| UF-19-02 | IN-06 (`2a5520e`) | DoS (degraded) | `getCities` returns an EMPTY list when every city is dropped (a `null` payload still throws): the Map would open without cities and the only trace is the count line of check B. The log itself is safe (count only, test `graphql_get_cities_test.dart:50`) | low | accept; optionally throw when `cities.isEmpty && skipped > 0` |
| UF-19-03 | WR-01 (`26332e5`) | Tampering (display) | an equipment item without rarity is drawn in `KlimmeckGuideTheme.deepNight`, the same fallback as `loot_item_card.dart:52`: no rule, no new copy, but a rarity-less item is not distinguishable from the default ink | info | accept |

## Open

None.

## Pending the device E2E (plan 19-13) — closed, see «After the device E2E»

- T-19-50: Task 3 — after the results are recorded and `BACKEND-NOTES.md` is written, the grep for a Mongo URI scheme, `token=`, `password` must print 0 on both files (today 0 on `19-HUMAN-UAT.md`, the other file does not exist).
- T-19-51: Task 3 — `mark-complete` only for the MODEL ids whose mandatory steps passed in the user's words (MODEL-01: 9, 10, 11; MODEL-02: 1, 2, 3, 7, 8; MODEL-03: 4, 5, 6; MODEL-04: 9 + gates).

Closed threats that the device run also observes on the real wire (not a condition of their status): T-19-01 (step 9), T-19-17 / T-19-21 (steps 3, 7, 8), T-19-20 (steps 1, 3: legibility of a long attack line), T-19-28 / T-19-41 (steps 4, 5), T-19-38 (step 6).

## After the device E2E (2026-11-11)

Plan 19-13 Task 3 ran after the device run (`19-HUMAN-UAT.md`, `status: complete`). The two threats left pending are closed; totals **56 / 56 closed** (54 mitigated, 2 accepted, 0 open, 0 deferred).

| ID | Closing evidence |
|----|------------------|
| T-19-50 | `19-HUMAN-UAT.md` (results, findings, extra checks) and `BACKEND-NOTES.md` (FE handoff) re-checked after they were written: the acceptance grep (Mongo URI scheme, query-string credential, credential word, numeric twitch id) prints `0` on both; no 24-hex id; identities are described by role (innkeeper, non-innkeeper rookie) and by character name only, the identity switch by its mechanism only; seeds and DB readings are reported as outcomes (counts, field names), never as scripts or connection data |
| T-19-51 | `mark-complete` ran only after every mandatory step passed in the user's words: MODEL-01 (9, 10, 11), MODEL-02 (1, 2, 3, 7, 8 — step 7 on the second attempt, step 2 completed by check A), MODEL-03 (4, 5, 6), MODEL-04 (9 + the gates of 19-10 / 19-12); optional steps 12–14 are recorded as skipped and tick nothing |

Surface added after the audit: the quick task 261111-enm (`a29360bd`, `169daeda`) changes how the FE JUDGES an `enemy` quest (one rank-free seat, minimum rank as a display pre-check); it adds no selection, variable, log line or dependency, and the backend still decides the acceptance (BE twin on `fix/enemy-quests-single-player`). Gates after it: full suite 4239 green, analyzer 47 info / 0 warning / 0 error, `hardening_check: OK`.

Unregistered flags UF-19-01, UF-19-02, UF-19-03: accepted as they are at the close of the phase (none is a blocker under `block_on: high`); no code change.
