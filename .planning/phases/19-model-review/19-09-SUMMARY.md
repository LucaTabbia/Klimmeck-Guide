---
phase: 19-model-review
plan: 09
subsystem: models
tags: [spells, fixtures, single-list, contraction, window, tdd]
requires: ["19-08"]
provides:
  - "spellbookCharacterJson / spellbookCharacter({id, maxActiveSpells, spellStates}) in the single-list shape of the BE Phase 19; default = one known spell, full usages, not equipped"
  - "CharacterStatus without the known-spell list; CharacterAssets without the equipped-spell list; spellStates is the only spell list of the FE models"
  - "lib/models/active_spell.dart deleted"
affects: [19-10, 19-11, 19-12, 19-13]
tech-stack:
  added: []
  patterns: ["absence assertion on a removed wire key built from two adjacent string literals, so the leftover grep of the gated wave stays clean"]
key-files:
  created: []
  deleted:
    - lib/models/active_spell.dart
  modified:
    - lib/models/character/character_status.dart
    - lib/models/character/character_assets.dart
    - test/helpers/fixtures/spell_fixtures.dart
    - test/helpers/fixtures/pending_request_fixtures.dart
    - test/models/character/character_status_test.dart
    - test/models/character/character_assets_test.dart
    - test/models/spell/spellbook_test.dart
    - test/screens/mainScreen/components/spell_outcome_listener_test.dart
    - test/screens/mainScreen/tabs/journal/components/spellbook_content_test.dart
    - test/screens/mainScreen/tabs/journal/journal_spells_test.dart
    - test/screens/mainScreen/tabs/journal/sections/spells_section_test.dart
    - test/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_cubit_test.dart
    - test/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit_test.dart
decisions:
  - "Only the five cases of spellbook_test that pinned the three-list join or the usages fallback were deleted; every other old case was rebuilt on the new funnel with its expectation unchanged (narrower than the line range of the plan, more coverage kept)"
  - "CharacterStatus.toJson drops the 'spells' key in the same commit that removes the field (trap noted in 19-07)"
metrics:
  duration: "~25 min"
  completed: 2026-11-11
  tasks: 2
  files: 14
---

# Phase 19 Plan 09: Spell fixtures on the single state list, model contraction — Summary

Every spell fixture and its callers now speak the single-list shape of the BE Phase 19 (known spell = a state, equipped = `active: true`), and the FE character models carry one spell list only: the known-spell list of `CharacterStatus`, the equipped-spell list of `CharacterAssets` and the `ActiveSpell` model are gone. The wired window reader still translates today's wire, so the branch keeps working against the BE of today.

**End of the pre-gate wave: the branch works against the BE of today; plans 19-10..19-13 wait for the BE Phase 19 merge.**

## Commits

| # | Hash | Subject |
|---|------|---------|
| 1 | `94667da` | test(journal): move the spell fixtures to the single state list |
| 2 | `f3b60d2` | test(models): expect one spell list on the character models |
| 3 | `8c1f11b` | refactor(models): drop the legacy spell lists from the character |

Trailer check after every commit: `0`.

## Task 1 — fixture migration (test-only)

Verify command: `flutter test test/models test/screens/mainScreen/tabs/journal test/screens/mainScreen/components test/screens/innkeeper test/graphql/character_fragment_test.dart`.

| Moment | Result |
|--------|--------|
| Baseline (`c303708`) | `+1487: All tests passed!` |
| After the migration (`94667da`) | `+1482: All tests passed!` |

Difference −5 = exactly the five deleted cases of `test/models/spell/spellbook_test.dart` (three-list join and usages fallback, now a concern of the window reader only and covered by `legacy_spell_states_test.dart`):

1. «an active entry with a null spell is skipped»
2. «without spell states an active spell uses ActiveSpell.usages»
3. «an inactive spell without state uses the catalog maxUsages»
4. «spell states without the spell fall back to the active usages»
5. «a pending equip slot without state uses the catalog maxUsages»

`git diff HEAD~1 --stat -- lib` at `94667da`: empty.

Extra guard (callers of the fixtures outside the verify set): `flutter test test/repository/innkeeper_repository_test.dart test/repository/services/graphql/graphql_pending_requests_test.dart test/utils/spell_lines_test.dart test/shared/components test/screens/mainScreen/tabs/map/teleportModeCubit test/screens/mainScreen/prisonCubit` → `+416: All tests passed!`.

### Files migrated (10)

| File | Change |
|------|--------|
| `test/helpers/fixtures/spell_fixtures.dart` | funnel as in the plan (`spellStates` only, default `spellStateJson(usages: 3, recoveries: const [])`); the equipped-spell builder deleted; stale «pre-9.1» doc comment replaced |
| `test/helpers/fixtures/pending_request_fixtures.dart` | innkeeper character: one state (fireball, usages 2, `active: true`); known list and equipped list removed |
| `test/models/spell/spellbook_test.dart` | `_character(known:, active:)` builds states (full usages, no recoveries); `_single` goes through the funnel; `_active` helper removed; five cases deleted (above); group `join` → `view` |
| `test/models/character/character_status_test.dart` | last case → «spellbookCharacter has one known spell as a single inactive state at full usages (D-05)» (it no longer goes through the window reader; no read of the two model lists) |
| `test/screens/mainScreen/components/spell_outcome_listener_test.dart` | `equipped` = the default state with `active: true` |
| `test/screens/mainScreen/tabs/journal/components/spellbook_content_test.dart` | local `_fullState(spell, usages:, active:)`; the two spellbooks and four inline characters as states |
| `test/screens/mainScreen/tabs/journal/journal_spells_test.dart` | two states (A active with the default recoveries, B full) |
| `test/screens/mainScreen/tabs/journal/sections/spells_section_test.dart` | `_character` builds states; the boolean `withSpellStates` is gone (see titles below); local `_fullState` |
| `test/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_cubit_test.dart` | the two spells that had no state get one with the usages the case expected (3 and 0) |
| `test/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit_test.dart` | `_character(active:)` through `spellStateJson(active:)`; the 33 cases untouched |

In the plan's list but needing no edit (already compatible with the new signatures, analyzer proves it): `test/helpers/journal_harness.dart` (spreads `status` / `assets` of the funnel; its equipment key untouched — gated, 19-10), `test/models/spell/spell_state_test.dart` (`spellStateJson` only), `journal_items_test.dart` and `items_section_test.dart` (`spellbookCharacterJson()` without arguments), `test/screens/innkeeper/components/completion_form_test.dart` (its matches of the grep are the `ParticipantDraft.spells` parameter and a group name, not a wire key; it gets the new shape through `participantCharacterJson`).

### Titles reworded (expectations unchanged)

| File | From → to |
|------|-----------|
| `spellbook_test.dart` | «entries keep the order of status.spells» → «entries keep the order of the states» |
| `spellbook_test.dart` | «a pending equip is appended to the slots and marked pending» → «a pending equip takes the next slot in list order and is marked pending» (stale wording noted in 19-08) |
| `spells_section_test.dart` | «a pre-9.1 payload falls back to «in recupero»» → «a used spell without recovery dates falls back to «in recupero»» (same line expected; the fixture is now a state with usages 1 and no recoveries instead of a payload without states) |

## Task 2 — RED evidence

`flutter test test/models/character/character_status_test.dart test/models/character/character_assets_test.dart` at `f3b60d2` → `+62 -3: Some tests failed.`

- «toJson writes the spell states and no separate list of known spells (D-05)» — `Expected: not contains 'spells'`
- «toJson writes no equipped spell list (D-05)» — `Expected: not contains 'activeSpells'` (the key is built in the test as `'active' 'Spells'`)
- «the assets parse without the equipped spell list (D-05)» — the payload that still carries the list is not equal to the one without it (`Actual: … [ActiveSpell(3, Spell(spell-1, …))] …`)

Green at the first run, by construction: «a served list of known spells beside the states is ignored by the status (D-05)» (the status has read its states from `spellStates` only since 19-07; the case pins it).

The plan expected two failing `toJson` cases; the assets parse case fails too because it asserts «exposes nothing of it» through equality with the payload without the list.

## Task 2 — GREEN

- `character_status.dart`: known-spell list removed (ctor parameter, field, parse, `toJson` key `"spells"`, `copyWith` parameter, `props`) and the now unused import of `spell.dart`.
- `character_assets.dart`: equipped-spell list removed (ctor parameter, field, parse, `toJson` key, `props`) and the import of `active_spell.dart`.
- `git rm lib/models/active_spell.dart`.
- Direct constructions fixed: none — `CharacterStatus(` / `CharacterAssets(` are constructed only inside their own `fromJson` / `copyWith` (lib) and nowhere in `test`.

## Tests and gates

| Command | Result |
|---------|--------|
| Task 2 `<verify>` (`test/models`, journal, shop, components, innkeeper, `character_fragment_test.dart`) at `8c1f11b` | `+1543: All tests passed!` |
| `flutter analyze --no-fatal-infos` after `94667da` and after `8c1f11b` | `47 issues found.` — info only, `ANALYZE_GATE_OK` |
| `sh tool/hardening_check.sh` | exit 0 |

The full `flutter test` was not run (orchestrator instruction).

## Acceptance results

Task 1: `'spells'` in `spell_fixtures.dart` 0 · `activeSpellJson` in `test` nothing · old named arguments in `journal_items_test` / `items_section_test` / `character_status_test` nothing · `D-14)` in `spellbook_test.dart` 4 (≥ 3) · `git diff HEAD~1 --stat -- lib` empty.

Task 2: `lib/models/active_spell.dart` absent · `ActiveSpell\b` in `lib test` nothing · `List<Spell>\? spells|json\['spells'\]` in `character_status.dart` 0 · `D-05)` 9 (status test, ≥ 8) / 2 (assets test, ≥ 2) · `git diff HEAD~3 --stat -- lib/graphql lib/screens lib/models/spell` empty (three commits in this plan, so `HEAD~3` instead of the plan's `HEAD~2`) · `git status --short` → ` M pubspec.lock` only.

Leftover greps:

```
$ grep -rl "activeSpells" lib
lib/models/character/legacy_spell_states.dart
lib/graphql/fragments/character_fragment.dart
$ grep -rl "activeSpells" test
test/models/character/character_test.dart
test/models/character/legacy_spell_states_test.dart
test/graphql/character_fragment_test.dart
```

## Files formatted

`dart format` one by one on every touched file. Reflowed (edited code only): `spellbook_test.dart`, `spellbook_content_test.dart`, `spells_section_test.dart`, `character_assets_test.dart`; the others were already clean.

## Deviations from Plan

None under Rules 1–4. Choices inside the plan's latitude:

- **Narrower deletion in `spellbook_test.dart`:** the plan named line ranges of the pre-19-08 file; only the five cases that test the join / fallback were deleted, the generic cases of the same range (slot row, overflow, order, `entryFor`, equality, pending equip usages from the state) were rebuilt on the new funnel with unchanged expectations.
- **Fewer files edited than listed:** five files of `files_modified` needed no edit (listed above).
- **RED had three failing cases, not two** (above).

## State at the park (9/13)

The branch is parked here until the BE Phase 19 merge reaches BE `origin/develop`. Against the BE of today the app parses the character through the two window readers; nothing under `lib/graphql` changed in 19-01..19-09.

### What the gated plans still have to do

- **19-10:** schema gate on the merged BE SDL (greps + block-anchored checks of D-19 / D-20, else STOP); atomic rename `wearedEquipment` → `wornEquipment` and `foots` → `feet` (model, `SlotType`, `EquipItemRequest` wire value, mannequin, `journal.dart`, fragment slot list, `journal_harness.dart`) in one commit; atomic `Lore.image` → `Lore.imagePath` (model, `lore_queries.dart`, `city_queries.dart`, readers, fixtures) in one commit.
- **19-11:** fragment flip — `character_fragment.dart` drops `spells { … }` and the equipped list and selects `spellStates { usages recoveries active spell { ${SpellFragment.fields} } }`; `ownedPets` as `OwnedPet`; `PetFragment` with `attack` / `defense` / `rarity`; `petXpGained` in `quest_result_fragment.dart`; 46 documents OK; then the two window readers deleted RED-first: `lib/models/character/legacy_spell_states.dart` + its test, the switch and import in `lib/models/character/character.dart` (back to a plain null check), the «BE of today» and «status only» cases of `test/models/character/character_test.dart`, the bare-pet branch of `OwnedPet.tryFromJson`, and the pinned selections / recorded payload of `test/graphql/character_fragment_test.dart`.
- **19-12:** `tool/schema_check` (46 × OK), full suite, analyzer, leftover grep `activeSpells|wearedEquipment|foots|energyWeaknesses|baseWeaknesses` on `lib test tool` empty, validation.
- **19-13:** device E2E (a pet must be bought or seeded), requirements closed, closing docs.

### Residues of the old names left on purpose

| Old name | Files | Leaves in |
|----------|-------|-----------|
| equipped-spell list (`activeSpells`) | `lib/graphql/fragments/character_fragment.dart` (selection), `lib/models/character/legacy_spell_states.dart` (window reader), `test/models/character/legacy_spell_states_test.dart`, `test/models/character/character_test.dart` («BE of today» / «status only» cases), `test/graphql/character_fragment_test.dart` (pins + recorded payload) | 19-11 |
| known-spell list (`'spells'` of the status) | `lib/graphql/fragments/character_fragment.dart` (selection `spells { … }`), `lib/models/character/legacy_spell_states.dart`, the same three test files, plus `test/models/character/character_status_test.dart` (two D-05 cases of this plan that assert the key is NOT written / NOT read — they stay; `Enemy.spells` in `lib/models/enemy.dart` is another field and is not a residue) | 19-11 |
| window wiring `statusJsonWithLegacySpellStates` | `lib/models/character/character.dart` (switch on `json['status']` + import) | 19-11 |
| bare pet map in the owned list | `lib/models/owned_pet.dart` (`tryFromJson` branch commented «Ramo cancellato al gate (piano 19-11)») and its test | 19-11 |
| `wearedEquipment` | `lib/models/character/character_assets.dart`, `lib/screens/mainScreen/tabs/journal/journal.dart`, `lib/graphql/fragments/character_fragment.dart`, `test/helpers/journal_harness.dart` | 19-10 |
| `foots` | `lib/models/equipment.dart`, `lib/models/enums/slot_type.dart`, `lib/screens/mainScreen/tabs/journal/components/equipment_mannequin.dart`, `lib/graphql/fragments/equipment_fragment.dart` | 19-10 |
| `Lore.image` | model, `lore_queries.dart`, `city_queries.dart`, readers (`splash_cubit.dart`, `lore_card.dart`, `city_modal.dart`) and the lore / travel fixtures and document tests | 19-10 |

`energyWeaknesses` / `baseWeaknesses`: already absent from `lib test tool`.

## Notes for the next plans

- **19-11:** when the reader goes, the absence assertion of `character_assets_test.dart` (key built as `'active' 'Spells'`, constant `_equippedListKey`) keeps the leftover grep clean and can stay as a regression pin.
- **19-11:** `spellStateJson()` and the funnel are already the post-merge wire shape: flipping the fragment needs no fixture change for the spells, only the pins of `character_fragment_test.dart`.
- `CharacterStatus.copyWith` still does not take `spellStates` (carried as is), as before.
- `SpellbookEntry.usages` / `SpellSlot.usages` are still `int?` (public API unchanged since 19-08).

## Known Stubs

None.

## Threat Flags

None — no new surface. T-19-33 (fields and model removed, analyzer clean, leftover greps above), T-19-34 (`character_test.dart`, `legacy_spell_states_test.dart` and the recorded payload green in the verify command), T-19-54 (test-only commit with empty `lib` diff, 1487 → 1482 with the five deleted cases named) are covered above.

## Self-Check: PASSED

- `lib/models/active_spell.dart` is absent; the thirteen modified files exist.
- Commits `94667da`, `f3b60d2`, `8c1f11b` are in `git log`.
