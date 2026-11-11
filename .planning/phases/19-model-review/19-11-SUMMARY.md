---
phase: 19-model-review
plan: 11
subsystem: graphql
tags: [schema-gate, fragments, owned-pets, spells, window-removal, tdd]
requires: ["19-10"]
provides:
  - "Character documents in the Phase 19 shape: spellStates { usages recoveries active spell { full } }, ownedPets { xp currentLifePoints pet { PetFragment } }, no known-spell list, no equipped-spell list"
  - "PetFragment with maxXp, attack, defense, rarity; QuestResultFragment with petXpGained after xpAfter"
  - "No window reader left: OwnedPet.tryFromJson reads entries only, Character.fromJson reads the served status as it is"
affects: [19-12, 19-13]
tech-stack:
  added: []
  patterns: ["removed wire name in a test built from two adjacent string literals"]
key-files:
  created: []
  modified:
    - lib/graphql/fragments/character_fragment.dart
    - lib/graphql/fragments/pet_fragment.dart
    - lib/graphql/fragments/quest_result_fragment.dart
    - lib/models/owned_pet.dart
    - lib/models/character/character.dart
    - test/graphql/character_fragment_test.dart
    - test/graphql/shop_documents_test.dart
    - test/graphql/quest_result_documents_test.dart
    - test/models/owned_pet_test.dart
    - test/models/character/character_assets_test.dart
    - test/models/character/character_test.dart
  deleted:
    - lib/models/character/legacy_spell_states.dart
    - test/models/character/legacy_spell_states_test.dart
decisions:
  - "OwnedPet.tryFromJson keeps the Pet.tryFromEntryJson boundary of the review fix (WR-02); only the bare-pet branch is gone"
  - "The recorded characterUpdated payload mirrors the pet content at DB (maxXp, attack, defense, rarity ultrarare)"
metrics:
  duration: "~15 min"
  completed: 2026-11-12
  tasks: 3
  files: 13
---

# Phase 19 Plan 11: Fragment flip and deletion of the two window readers — Summary

The three fragments now select the Phase 19 shapes and the 46 documents validate on the merged BE SDL; the bare-pet branch of `OwnedPet.tryFromJson` and the legacy spell reader (file, tests, wiring) are deleted RED-first, and no removed wire name is left in `lib`, `test`, `tool`.

**The companion lines (xp, attack, defense) and the result line now have data from the wire.** The rarity colour of the companion name too (`rarity` selected, nullable).

## Commits

| # | Hash | Subject |
|---|------|---------|
| 1 | `4f10cafe` | test(graphql): expect the model review selections |
| 2 | `0daa2990` | feat(graphql): select the model review shapes |
| 3 | `8f34effe` | test(models): expect bare pet maps to be dropped |
| 4 | `26172e44` | refactor(models): drop the bare pet window reader |
| 5 | `e00d1d75` | test(models): expect no legacy spell translation |
| 6 | `37bc2254` | refactor(models): drop the legacy spell window reader |

Trailer check after every commit: `0`.

## Task 1 — gate re-check and fragment flip

Gate (BE `origin/develop` = `48b20701`, read with `git -C <BE> show`, never fetched; SDL saved in the session scratchpad): `GATE_OK`.

RED (`4f10cafe`): `flutter test test/graphql` → `+169 -7: Some tests failed.` Red (7):
- «PetFragment selects id, name, speed, sellable, both prices, maxXp, attack, defense and rarity (D-12, D-20)»
- «QuestResultFragment selects petXpGained after xpAfter (D-03)»
- «statusFields selects spellStates with usages, recoveries, active and the full spell (D-05)»
- «statusFields no longer selects a separate list of known spells (D-05)»
- «assetsFields no longer selects the equipped spell list (D-05)»
- «statusFields selects unlockedLore (D-01)» (re-anchored)
- «selects the equipped pet with PetFragment and the owned pets as entries (D-03, D-18)»

The recorded-payload tests stayed green (window readers still in place), as the plan predicted.

GREEN (`0daa2990`, one commit): `statusFields` loses the known-spell block and `spellStates` selects `usages recoveries active spell { SpellFragment.fields }` in the same commit (Pitfall 3); `assetsFields` loses the equipped-spell block and `ownedPets` selects `xp currentLifePoints pet { PetFragment.fields }`; `PetFragment.fields` gains `maxXp`, `attack { DamagesFragment.fields }`, `defense { DamagesFragment.fields }`, `rarity`; `petXpGained` right after `xpAfter`. `relatedLore` of `Pet` is NOT selected. `damage_fragment.dart` only imported, not edited.

`flutter test test/graphql test/tool test/models test/repository` → `+1987: All tests passed!` (registry still 46).

Schema check on the merged SDL:

```
dumped 46 documents
grep -c OK   -> 46
grep -vc OK  -> 0
```

Run again after the last commit of the plan: `dumped 46 documents`, `grep -vc OK` → `0`.

Acceptance: `^ +active$` 1 · `^ +spells \{` 0 · equipped-list name 0 · `ownedPets {` + 3 lines → 3 · `^ +maxXp$` 1 · `attack {` 1 · `defense {` 1 · `^ +rarity$` 1 · `^ +petXpGained$` 1 · `grep -rn "weaknesses" lib/graphql` nothing · `D-05)` 3 · `D-12` 1 · `D-20)` 1 · `D-03)` 2.

Rarity enum: `lib/models/enums/rarity_type.dart` has the member `ultrarare` and `Pet.fromJson` reads `RarityType.values.asNameMap()[json['rarity']]` — the wire value `ultrarare` is read (pinned by the recorded payload case below), `null` and unknown names give `null`.

## Task 2 — bare-pet window branch

RED (`8f34effe`): `flutter test test/models/owned_pet_test.dart test/models/character/character_assets_test.dart test/graphql/character_fragment_test.dart` → `+50 -2: Some tests failed.`

```
a bare catalogue pet map is dropped (D-03, D-15) [E]
  Expected: null
    Actual: OwnedPet:<OwnedPet(Pet(null, pet-travel-horse, Cavallo da viaggio, …), 0, 0)>
CharacterAssets a bare pet in the owned list is dropped and the entries stay (D-03, D-15) [E]
  Expected: ['pet-travel-horse']
    Actual: MappedListIterable<OwnedPet, String>:['pet-travel-horse', 'pet-bare']
```

Green at the first run, with the reason: the recorded `characterUpdated` payload rewritten in the Phase 19 shape, its two existing tests and the new «a recorded characterUpdated payload parses its active states and owned entries (D-03, D-05)» — the new shape bypasses both window readers (green before and after, as the plan says). The payload mirrors the DB content: full spells, `active` true/false, one owned entry with `xp` 40, `maxXp` 300, `attack`, non-empty `defense`, `rarity: ultrarare`; the new case also asserts `RarityType.ultrarare`.

GREEN (`26172e44`): `OwnedPet.tryFromJson` returns `null` for anything that is not `{ pet, xp, currentLifePoints }` (early return, doc comment added, window comment gone). The existing case «a bare pet with a malformed name is null (D-15, D-16)» is still true and was left.

`flutter test test/models test/graphql test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/shop test/screens/mainScreen/components` → `+1548: All tests passed!` No fixture still writes bare pets in `ownedPets` (every caller uses `ownedPetJson`).

Acceptance: `Pet.tryFromJson(json)` 0 · `finestra|window` 0 · `D-15)` 1 / 1. **Differs from the plan's literal grep:** `Pet.tryFromJson(json['pet'])` is 0 because the review fix (WR-02) made the entry read `Pet.tryFromEntryJson(json['pet'])` — count 1 for that form; the boundary is kept on the orchestrator's instruction.

## Task 3 — legacy spell reader

RED (`e00d1d75`): `flutter test test/models/character/character_test.dart` → `+2 -1: Some tests failed.`

```
Character.fromJson spells a payload with the legacy spell lists is not translated (D-05, D-15) [E]
  Bad state: Too many elements
  dart:core  _Array.single
  test/models/character/character_test.dart 48:51
```

(the window reader still rebuilt two full states from the list of known spells; the case expects the single served id-only state, not active, usages 1, nameless spell). The two kept cases were green; the «status only / assets only / neither» case is retitled `(D-05)` and no longer writes legacy lists.

GREEN (`37bc2254`, one commit): `Character.fromJson` back to `json['status'] != null ? CharacterStatus.fromJson(json['status']) : null` (call, comment, import and the three-branch switch gone — closes review IN-03); `git rm` of `lib/models/character/legacy_spell_states.dart` and `test/models/character/legacy_spell_states_test.dart`; one stale comment fixed in `character_assets_test.dart` («la BE di oggi serve ancora» → «prima della BE Phase 19»).

Leftover proof:

```
$ grep -rnE "activeSpells|wearedEquipment|foots|energyWeaknesses|baseWeaknesses" lib test tool
$ grep -rn "statusJsonWithLegacySpellStates\|legacy_spell_states" lib test
$
```

(both empty). `D-15)` in `character_test.dart`: 1. Both files gone.

## Tests and gates

| Command | Result |
|---------|--------|
| `flutter test test/graphql test/tool test/models test/repository` at `0daa2990` | `+1987: All tests passed!` |
| Task 2 verify set at `26172e44` | `+1548: All tests passed!` |
| Plan `<verification>` set (`test/models test/graphql test/tool test/repository test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/shop test/screens/mainScreen/components test/screens/innkeeper`) on the final tree | `+2600: All tests passed!` |
| `flutter analyze --no-fatal-infos` after each code task | `47 issues found.` — info only, `ANALYZE_GATE_OK` |
| `sh tool/hardening_check.sh` | `hardening_check: OK` |
| Schema check on the final tree | `dumped 46 documents`, 46 × OK |

The full `flutter test` was not run (gate of 19-12). BE `git status --short`: empty.

## Files formatted

`dart format` one by one on every touched file; only `test/graphql/character_fragment_test.dart` (new cases) and `lib/models/owned_pet.dart` (the edited method) were rewritten; no untouched member moved.

## Deviations from Plan

None under Rules 1–4. Inside the plan's latitude:

- **SDL and dumped documents in the session scratchpad** instead of `mktemp -d` (same «outside the repo» rule, survives between Bash calls).
- **Acceptance grep of Task 2** reads `Pet.tryFromEntryJson(json['pet'])` (review fix WR-02), see above.
- **Extra assertion** `owned.pet.rarity == RarityType.ultrarare` in the recorded-payload case (orchestrator's check on the FE rarity enum).
- **Bookkeeping in a commit separate from the SUMMARY commit** (orchestrator brief wins over the plan's `<output>` step 3).

## Notes for the next plans

- **19-12:** the suite lost the whole `legacy_spell_states_test.dart` and the window group of `owned_pet_test.dart`, and gained a few pins (fragments, recorded payload, bare pet in the owned list): the total is below `+4207` plus the 19-10 additions — do not compare against a fixed number.
- **19-12:** two test titles outside this plan's files still say «as the BE of today serves it (D-15)» (`test/shared/components/cards/companion_card_test.dart:139`, `test/shared/components/companion_row_test.dart:194`): the cases are still true (a pet without attack / defense prints neither line) but the wording is of the window; retitle if the gate plan wants no window wording left.
- **19-12:** review IN-07 (`CharacterAssets.toJson` asymmetric) was «touched at the gate» by ruling: not in this plan's actions, untouched.
- **19-13:** from `0daa2990` every character read asks for `spellStates.active`, the full spell, `ownedPets` entries and the new pet fields: the device needs a BE with Phase 19 (already the case on this machine per the handoff).
- `.planning/STATE.md`: only `Plan: 11 of 13` and the «Last activity» line were updated; frontmatter and the «Status» / «Next step» lines are left to the orchestrator.

## Known Stubs

None.

## Threat Flags

None — no new surface. T-19-40 (gate before any edit, 46 × OK after the flip), T-19-41 (full spell selected in the commit that drops the known list, pins RED first), T-19-42 (both readers deleted RED-first, leftover grep empty), T-19-43 (`weaknesses` absent from `lib/graphql`, `relatedLore` of the pet not selected), T-19-44 (BE read-only, status empty, no `.env*` read, scratch outside the repo) are covered above.

## Self-Check: PASSED

- The 11 modified files exist; the 2 deleted files do not.
- Commits `4f10cafe`, `0daa2990`, `8f34effe`, `26172e44`, `e00d1d75`, `37bc2254` are in `git log`.
