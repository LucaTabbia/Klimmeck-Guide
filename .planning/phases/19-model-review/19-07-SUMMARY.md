---
phase: 19-model-review
plan: 07
subsystem: models
tags: [spells, spell-state, window, legacy-reader, lenient-parse, tdd]
requires: ["19-06"]
provides:
  - "SpellState { spell (full catalogue Spell), usages, recoveries, active (bool, lenient → false) }; spellId is a getter on spell.id; spell and active in toJson and props"
  - "CharacterStatus.spellStates non-null (const [] when absent or not a list)"
  - "statusJsonWithLegacySpellStates(status, assets) in lib/models/character/legacy_spell_states.dart — pure, window-only, NOT wired"
  - "spellStateJson(active: …, spell: …) in test/helpers/fixtures/spell_fixtures.dart (writes the full spell and 'active')"
affects: [19-08, 19-11, 19-12]
tech-stack:
  added: []
  patterns: ["window reader as a pure JSON → JSON function on Object? with `is` checks only, in a file of its own deleted at the gate"]
key-files:
  created:
    - lib/models/character/legacy_spell_states.dart
    - test/models/character/legacy_spell_states_test.dart
  modified:
    - lib/models/spell/spell_state.dart
    - lib/models/character/character_status.dart
    - test/helpers/fixtures/spell_fixtures.dart
    - test/models/spell/spell_state_test.dart
    - test/models/character/character_status_test.dart
    - test/graphql/character_fragment_test.dart
decisions:
  - "Usages fallback of the window reader (orchestrator ruling): legacy state usages → equipped-list usages → catalogue maxUsages → 0, each step taken only when it is a number"
  - "Duplicate ids in the legacy states or in the equipped list: the first entry wins in both (one helper); today's Spellbook lets the last state win — not reachable with real payloads"
metrics:
  duration: "~20 min"
  completed: 2026-11-11
  tasks: 2
  files: 8
---

# Phase 19 Plan 07: SpellState with its spell and active; the window reader of the legacy spell lists — Summary

`SpellState` now carries the full catalogue `Spell` and the `active` flag read from the entry, `CharacterStatus.spellStates` is a non-null list, and a pure function that turns today's three wire lists into that single list exists and is tested — but nothing calls it yet, so the app behaves exactly as before against the BE of today.

## Commits

| # | Hash | Subject |
|---|------|---------|
| 1 | `a6154a4` | test(models): expect the spell state with its spell and active |
| 2 | `ed1fe11` | feat(models): carry the spell and active on the spell state |
| 3 | `5e6c3d7` | test(models): pin the window reader of the legacy spell lists |
| 4 | `bbb371a` | feat(models): add the window reader of the legacy spell lists |

Trailer check after every commit: `0`.

## RED evidence

**Task 1** — `flutter test test/models/spell/spell_state_test.dart test/models/character/character_status_test.dart` → `+0 -2: Some tests failed.`, compile failure of both files, as the plan expected:

- `test/models/spell/spell_state_test.dart:74:20: Error: The getter 'spell' isn't defined for the type 'SpellState'.` (also :106, :107, :130)
- `test/models/spell/spell_state_test.dart:79:64: Error: The getter 'active' isn't defined for the type 'SpellState'.` (also :80, :85, :91, :109)
- `test/models/character/character_status_test.dart:181:33: Error: Method 'map' cannot be called on 'List<SpellState>?' because it is potentially null.` (also :182, :183)
- `test/models/character/character_status_test.dart:227:31: Error: Property 'single' cannot be accessed on 'List<SpellState>?' because it is potentially null.`

The new cases were not observed individually in RED (compile failure of the files). «an entry whose spell has no id is null (D-05)» and «an empty spellStates is an empty list» would be green before the implementation by construction.

**Task 2** — `flutter test test/models/character/legacy_spell_states_test.dart` → compile failure:

- `test/models/character/legacy_spell_states_test.dart:37:17: Error: Method not found: 'statusJsonWithLegacySpellStates'.` (also :138, :146, :158, :242)

All eight cases were green at the first run of the implementation.

## Tests and gates

| Command | Result |
|---------|--------|
| `flutter test test/models test/screens/mainScreen/tabs/journal test/screens/innkeeper test/graphql/character_fragment_test.dart` (Task 1, after GREEN) | `+1297: All tests passed!` |
| `flutter test test/models` (Task 2 `<verify>`) | `+892: All tests passed!` |
| `flutter test test/models test/screens/mainScreen/tabs/journal test/screens/innkeeper` (plan `<verification>`, after the last commit) | `+1287: All tests passed!` |
| `flutter analyze --no-fatal-infos` (after each GREEN) | `47 issues found.` — info only, `ANALYZE_GATE_OK` (baseline 47 info / 0 warning / 0 error); no issue in `legacy_spell_states.dart` |
| `sh tool/hardening_check.sh` | exit 0 |

The full `flutter test` was not run (orchestrator instruction).

## Acceptance results

Task 1: `final bool active` 1 · `final Spell spell` 1 · `String get spellId => spell.id` 1 · `json['active'] == true` 1 · `final List<SpellState> spellStates` 1 · `List<SpellState>?` 0 · `D-05)` 7 (spell state test, ≥ 7) / 6 (status test, ≥ 6) · `git diff HEAD~2 --stat -- lib/graphql lib/models/spell/spellbook.dart lib/screens` empty.

Task 2: `Map<String, dynamic> statusJsonWithLegacySpellStates(` 1 · references in `lib` outside the file 0 (not wired) · throwing casts ` as (Map|List|String|num|int)` 0 · `package:flutter/` 0 · `D-15)` 8 (≥ 8).

Plan-wide: `git diff 6f00943 --stat -- lib/graphql lib/screens lib/models/spell/spellbook.dart` empty (window rule D-15; the three-list join and its tests untouched). `git status --short` → ` M pubspec.lock` only.

## What was built

- `spell_state.dart`: `spell` (`Spell.fromJson(json['spell'] as Map<String, dynamic>)` — an entry whose spell carries only `{id}`, the payload of the BE of today, still parses; a spell without id throws inside `fromJson` and `tryFromJson` turns it into `null`), `active: json['active'] == true` (absent, `'yes'`, `1`, `null` → `false`), `spellId` getter, `toJson` with `spell.toJson()` and `active`, `props => [spell, usages, recoveries, active]` (Pitfall 8).
- `character_status.dart`: `this.spellStates = const []`, non-null field, `_spellStatesFrom` returns `const []` for a non-list, `toJson` without `?.`; `copyWith` still carries the list by hand. `CharacterStatus.spells` and the equipped list of `CharacterAssets` are untouched.
- `legacy_spell_states.dart` (header comment names plan 19-11): triggers only when `status['spells'] is List`, otherwise returns the SAME map (`identical`). For every known entry that is a `Map<String, dynamic>` with a string `id`, in the order of the known list: `spell` = the full known map, `usages` by the fallback below, `recoveries` = the legacy state's list or `[]`, `active` = the id is in the equipped list of the assets. Returns a copy `{...status, 'spellStates': built}`; inputs are not mutated. `is` checks only, no model import.
- **Usages fallback restated:** legacy state (`status.spellStates`, matched by `spell.id`) `usages` if it is a number → else the equipped entry's `usages` if it is a number → else the spell's `maxUsages` if it is a number → else `0`.
- Fixture: `spellStateJson` takes `bool active = false` and `Map<String, dynamic>? spell`; it now writes the full `spellJson(id: spellId)` under `'spell'` and always writes `'active'`. Source-compatible for the 36 existing call sites (states are still matched by id).

## Files formatted

`dart format` one by one on the eight touched files. Reflowed by the formatter: `spell_state_test.dart`, `character_status_test.dart`, `legacy_spell_states_test.dart` (the added code only); the others were already clean after the edit.

## Deviations from Plan

**1. [Rule 3 - Blocking] `test/graphql/character_fragment_test.dart:72` outside `files_modified`**
- **Found during:** Task 1 GREEN.
- **Issue:** `character.status!.spellStates!` — a `!` on the now non-null field is an analyzer warning and would break the gate (the plan expected «nothing outside the model»).
- **Fix:** removed the `!` (one token). The pins of that file (:54-68, :109-114, recorded payload) are untouched.
- **Commit:** `ed1fe11`.

Notes (not deviations):

- `character_status_test.dart`: the old «an empty spellStates is an empty list, not null» is kept as «an empty spellStates is an empty list»; «props include spellStates» kept and extended with a pair differing only by `active`; the last pin of the file (`spellbookCharacter … no states`) moved from `isNull` to `isEmpty`.
- `spell_state_test.dart`: the old `:72` case is split into «toJson writes the full spell and active (D-05)» and «writes UTC instants».

## Notes for the next plans

- **19-08 (wiring):** call `statusJsonWithLegacySpellStates(json['status'], json['assets'])` at `Character.fromJson` only when `json['status']` is a `Map<String, dynamic>`. The function returns the input itself when `status['spells']` is not a list.
- **19-08, trap:** `CharacterStatus.toJson` still writes `'spells'` as a list of id strings. If a `toJson` → `fromJson` round trip of a character ever reaches the reader, the list triggers it, every entry is skipped (not a map) and `spellStates` becomes `[]`. Today that round trip already throws in `Spell.fromJson`, so nothing regresses, but once `spells` leaves the model in 19-08 the key should leave `toJson` in the same commit.
- **19-08, leniency difference:** the reader copies the legacy `recoveries` list as it is. A legacy state with an unparsable recovery makes `SpellState.tryFromJson` drop the built entry, so that known spell would disappear from the Journal; today the malformed state is dropped and the spell stays with the fallback usages. Not reachable with the BE of today (ISO dates); say so if a stricter copy is wanted.
- Duplicate ids: first entry wins for both legacy states and equipped entries (today's `Spellbook` lets the last state win).
- `spellStateJson()` now carries a full spell named «Dardo di fuoco» with `maxUsages` 3: once `Spellbook` reads the spell from the state (19-08), a test passing `spells: [spellJson(id: x, name: …)]` together with `spellStateJson(spellId: x)` must pass the same spell through `spell:`.
- The equipped-spell builder and `spellbookCharacterJson`/`spellbookCharacter` are unchanged (19-08 changes them with their callers). The doc comment of `spellbookCharacterJson` («`spellStates == null` = payload pre-9.1») is stale from this plan and goes with that change.
- **19-11 / 19-12:** delete `lib/models/character/legacy_spell_states.dart` and `test/models/character/legacy_spell_states_test.dart` RED-first; the file holds the only `activeSpells` literal added by this plan.

## Known Stubs

None. The reader is unwired by design (wiring is 19-08), not a stub.

## Threat Flags

None — no new surface. T-19-24 (per-entry `tryFromJson`, non-null list, tests «a malformed state entry is dropped…»), T-19-25 («never throws on a partial or malformed payload (D-15)», no throwing cast), T-19-26 (`json['active'] == true`; the reader copies the membership the BE serves), T-19-27 (header comment naming 19-11) are covered above.

## Self-Check: PASSED

- The two created files and the six modified files exist.
- Commits `a6154a4`, `ed1fe11`, `5e6c3d7`, `bbb371a` are in `git log`.
