---
phase: 19-model-review
plan: 08
subsystem: journal
tags: [spells, spellbook, spells-cubit, window, legacy-reader, order, tdd]
requires: ["19-07"]
provides:
  - "Spellbook.of reads ONLY status.spellStates: known = first state per spell id in list order, equipped = active, usages and recoveries from the same entry; public API unchanged"
  - "One order rule (D-14): slots and activeSpellIds follow the list of states, server and optimistic overlay alike"
  - "SpellsCubit._matches closes a pending operation on the state's active flag"
  - "Character.fromJson passes a map status through statusJsonWithLegacySpellStates (the only call site, removed in 19-11)"
affects: [19-09, 19-11, 19-12]
tech-stack:
  added: []
  patterns: ["window reader wired at the parsing boundary with a switch on the raw status (null / map / anything else as before)"]
key-files:
  created:
    - test/models/character/character_test.dart
  modified:
    - lib/models/spell/spellbook.dart
    - lib/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart
    - lib/models/character/character.dart
    - test/models/spell/spellbook_test.dart
    - test/models/character/character_status_test.dart
decisions:
  - "A duplicated state of the same spell keeps the first entry (same rule as the window reader)"
  - "A non-map, non-null status still reaches CharacterStatus.fromJson and throws as before; only a Map<String, dynamic> goes through the window reader"
  - "character_status_test pin of the old-shape fixture moved to «one inactive state built by the window reader» (orchestrator ruling)"
metrics:
  duration: "~35 min (one stop for a ruling)"
  completed: 2026-11-11
  tasks: 1
  files: 6
---

# Phase 19 Plan 08: Spellbook and SpellsCubit on the single state list, window reader wired — Summary

The spell view and the cubit now read one list — `status.spellStates`, equipped = `active`, slots in the order of the list — and `Character.fromJson` translates today's three wire lists into it, so the Journal keeps working against the BE of today and every old-shape fixture still feeds the new view.

**Visible difference ruled by the user: equipped slots in learning order** (D-14, «Ordine di apprendimento») — a spell equipped later no longer goes to the last slot, it takes the place its state has in the list, during the optimistic overlay and after the confirmation alike.

## Commits

| # | Hash | Subject |
|---|------|---------|
| 1 | `5232e99` | test(journal): expect the spell view on the single state list |
| 2 | `7fa7b92` | feat(journal): read spells from the single state list |

Trailer check after every commit: `0`.

## RED evidence

`flutter test test/models/spell/spellbook_test.dart test/models/character/character_test.dart` → `+32 -13: Some tests failed.`

Failing (13):

- `character_test.dart`: «a payload of the BE of today yields states with their spells and active flags (D-15)»; «a character with a status only, with assets only or with neither still parses (D-15)» (its assertion on the built state of the status-only character).
- `spellbook_test.dart`, old group `overlay`: «pending equips follow the list order, not the tap order (D-14)».
- `spellbook_test.dart`, new group `single state list (BE Phase 19)`: «known spells are all the states in list order (D-05)», «equipped spells are the states with active (D-05)», «usages and recoveries come from the same entry (D-05)», «the slots follow the order of the states, not an equip order (D-14)», «a pending equip takes its place in the list order (D-14)», «a pending unequip frees its slot and the others keep their order (D-05, D-14)», «a pending operation marks the entry and its slot as pending (D-05)», «more active states than slots fill only the slots (D-05)», «a pending equip of an unknown spell changes nothing (D-05)», «a duplicated state of the same spell is listed once (D-05)».

Green at the first run, by construction: «a payload in the Phase 19 shape is read as served (D-05)» (the model of 19-07 already parses the new shape), «the section is hidden without states and without slots (D-05)» and «a null character gives an empty hidden view (D-05)» (an empty view is the same under both readings).

## Expectations moved

| File | Case | From → to | Reason |
|------|------|-----------|--------|
| `test/models/spell/spellbook_test.dart` | «pending equips are appended in tap order» → «pending equips follow the list order, not the tap order (D-14)» | `[_a, _c, _b]` → `[_a, _b, _c]` | equip order → list order (D-14), allowed by the plan |
| `test/models/character/character_status_test.dart` | «spellbookCharacter has one known spell, none active, no states» → «… none active, one inactive state built by the window reader (D-15)» | `spellStates` `isEmpty` → `.single.active` `isFalse` | see Deviations 1 |

The other candidates named by the plan (`:79`, `:103`, `:116`, `:198`) did not pin an equip order that differs from the list order: they pass unchanged. No expectation moved from `null` to `0` usages (no existing case had a spell without state, equipped usages and catalogue maximum). No widget or cubit test outside the model tests needed a change.

## Tests and gates

| Command | Result |
|---------|--------|
| `flutter test test/models test/screens/mainScreen/tabs/journal test/screens/mainScreen/components test/screens/innkeeper test/graphql/character_fragment_test.dart` (first run after GREEN) | `+1486 -1` — the one case of Deviations 1 |
| same command after the approved change (plan `<verify>` / `<verification>`) | `+1487: All tests passed!` |
| `flutter analyze --no-fatal-infos` | `47 issues found.` — info only, `ANALYZE_GATE_OK` |
| `sh tool/hardening_check.sh` | exit 0 |

The full `flutter test` was not run (orchestrator instruction).

## Acceptance results

`spellStates` in `spellbook.dart` 1 (≥ 1) · `_serverActiveById|_optimisticActiveById|_usagesOf|active_spell.dart` 0 · `status?.spells\b` 0 · `state.active` in `spells_cubit.dart` 1 · `assets` inside `_matches` 0 · `statusJsonWithLegacySpellStates(` in `character.dart` 1 · `git diff HEAD~2 --stat` on the section widgets, `spellRecoveryCubit`, `lib/models/request`, `lib/graphql` empty · `git diff HEAD~2 --stat -- test/helpers` empty · `D-14)` 4 (≥ 3) · `D-05` 10 (≥ 9) · `D-15)` in `character_test.dart` 2 (≥ 2) · rule 4 grep on `maxActiveSpells` 0 · trailer check 0 · `git status --short` → ` M pubspec.lock` only.

## What was built

- `spellbook.dart`: `Spellbook.of` takes the first state per spell id of `character?.status?.spellStates` (`_firstStatePerSpell`), computes the active rule once (`pending` equip → true, unequip → false, otherwise `state.active`) and derives slots, entries and `activeSpellIds` from that single ordered list. `_serverActiveById`, `_optimisticActiveById`, `_usagesOf` and the import of the equipped-spell model are gone. `SpellSlot`, `SpellbookEntry` (still `int? usages`), `entryFor`, `intentFor` and `props` are unchanged. A pending equip of a spell without a state changes nothing (no state, no slot, no entry).
- `spells_cubit.dart`: `_matches` reads `character.status?.spellStates.any((state) => state.spellId == spellId && state.active) ?? false`; nothing else in the cubit changes.
- `character.dart`: `status` is a switch on `json['status']` — `null` → `null`; `Map<String, dynamic>` → `CharacterStatus.fromJson(statusJsonWithLegacySpellStates(status, json['assets']))` with the window comment naming plan 19-11; anything else → `CharacterStatus.fromJson(status)` as before (a non-map status still throws; no test pins it).

## Files formatted

`dart format` one by one on the six touched files. Reflowed: `spellbook.dart` and `spellbook_test.dart` (added code only); the others were already clean.

## Deviations from Plan

**1. [Rule 1 - Bug, approved by the orchestrator] `test/models/character/character_status_test.dart` outside `files_modified`**
- **Found during:** GREEN, first run of the neighbourhood.
- **Issue:** the last case of the file pinned `spellbookCharacter().status!.spellStates` as empty. With the reader wired, an old-shape character with one known spell carries one built, inactive state — exactly the plan's must-have. Not one of the two fallouts the plan allows, and not fixable in `lib` without undoing the wiring.
- **Handling:** execution was stopped and reported; the orchestrator approved the change. Only that case: expectation → `spellStates.single.active` `isFalse`, title → «spellbookCharacter has one known spell, none active, one inactive state built by the window reader (D-15)».
- **Commit:** `7fa7b92`.

Notes (not deviations):

- The wiring keeps a third branch for a non-null, non-map status so that today's behaviour (a throw inside `CharacterStatus.fromJson`) is preserved, as the plan asked.
- 19-07 leniency note: the reader is left as it is (orchestrator ruling).

## Notes for the next plans

- **19-09 (fixture migration):** the old groups of `spellbook_test.dart` (`join`, `overlay`, `intentFor`) still run on old-shape fixtures through the reader. The title «a pending equip is appended to the slots and marked pending» still passes (the pending spell happens to follow the active one in the list) but its wording is stale. The usages-fallback cases («without spell states an active spell uses ActiveSpell.usages», «an inactive spell without state uses the catalog maxUsages», «spell states without the spell fall back to the active usages», «a pending equip slot without state uses the catalog maxUsages») now test the window reader, not the view: they belong to `legacy_spell_states_test.dart` and can leave `spellbook_test.dart` when the fixtures move to the new shape.
- **19-09:** the case of `character_status_test.dart` changed here pins the reader through the old-shape fixture; it changes again when `spellbookCharacter` moves to the new shape.
- **Still open from 19-07:** `CharacterStatus.toJson` writes `'spells'` as a list of id strings and `CharacterStatus.spells` / the equipped list of `CharacterAssets` are still on the models (`character_status.dart` and `character_assets.dart` were not in this plan's files). No `lib` code outside the models reads them any more for the spell view; they leave with the fragment in the gated wave.
- **19-11 / 19-12:** remove the wiring RED-first: the switch in `character.dart` (back to a plain null check), the import of `legacy_spell_states.dart`, the «BE of today» and «status only» cases of `character_test.dart`.
- `SpellbookEntry.usages` and `SpellSlot.usages` are still `int?` (public API unchanged) although the view now always supplies a value.

## Known Stubs

None.

## Threat Flags

None — no new surface. T-19-28 (the view reads `state.active` and `maxActiveSpells`, rule 4 grep 0), T-19-29 (one order rule, D-14 cases), T-19-30 («a character with a status only, with assets only or with neither still parses (D-15)»), T-19-31 (the 33 cases of `spells_cubit_test` green unchanged), T-19-32 (one commented call site, grep = 1) are covered above.

## Self-Check: PASSED

- `test/models/character/character_test.dart` and the five modified files exist.
- Commits `5232e99` and `7fa7b92` are in `git log`.
