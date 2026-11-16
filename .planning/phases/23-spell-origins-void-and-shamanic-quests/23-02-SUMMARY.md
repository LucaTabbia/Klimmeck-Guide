---
phase: 23-spell-origins-void-and-shamanic-quests
plan: 02
subsystem: models
tags: [spell, origin, minimum-level, graphql, lenient-parsing]
requires: ["23-01"]
provides:
  - "SpellOrigin { theVoid, arcane, shamanic } with wireName / fromWire (wire void / arcane / shamanic), labels Vuoto / Arcana / Sciamanica"
  - "Spell.origin and Spell.minLevelToLearn, read leniently and selected by no document"
  - "spellOriginLabel and spellLearnLabel by level («Per impararla: Livello N · … di studio»)"
  - "SpellFragment without minXpToLearn and without the dead name / definition"
affects: [23-06, 23-07]
tech-stack:
  added: []
  patterns: ["enum wire boundary with explicit wireName constructor parameter (reserved word void)"]
key-files:
  created:
    - lib/models/enums/spell_origin.dart
    - test/models/enums/spell_origin_test.dart
  modified:
    - lib/models/spell.dart
    - lib/utils/spell_lines.dart
    - lib/graphql/fragments/spell_fragment.dart
    - test/models/spell_test.dart
    - test/utils/spell_lines_test.dart
    - test/shared/components/spell_info_test.dart
    - test/helpers/fixtures/spell_fixtures.dart
    - test/graphql/character_fragment_test.dart
decisions:
  - "SpellOrigin has no image id yet: the three icon ids are wired RED-first by 23-06 with the widgets that draw them"
  - "Spell.minLevelToLearn is read with value is num ? value.toInt() : null, so a malformed value never throws"
  - "spellJson emits origin / minLevelToLearn only when non-null, so every existing card test keeps its payload"
metrics:
  duration: "~20 min"
  completed: 2026-11-15
---

# Phase 23 Plan 02: Spell model, origin and minimum level Summary

`SpellOrigin` (wire `void` / `arcane` / `shamanic`) and `Spell.minLevelToLearn` are now modelled leniently and selected by no document. `minXpToLearn` is gone from the model, the fixture, the copy and `SpellFragment`, so the spell selection is valid on today's SDL and on the BE Phase 24 one. The learn line prints «Livello N» only for a positive served level and never compares it with anything.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect the spell origin and the minimum level | 6ccfbeb7 |
| 1 GREEN | Read the spell origin and the minimum level | 37359339 |
| 2 style | Format spell_fragment.dart (formatter only) | 3d0bd7db |
| 2 RED | Expect no minXpToLearn in the spell selection | 4b37e58b |
| 2 GREEN | Stop selecting minXpToLearn on spells | e9be09ab |
| 3 | Bookkeeping | (this docs commit) |

## TDD

- **Task 1 RED (6ccfbeb7):** compile failure, as expected. `spell_origin_test.dart`, `spell_test.dart` and `spell_lines_test.dart` could not read `lib/models/enums/spell_origin.dart` (file missing), so `SpellOrigin`, `Spell.origin`, `Spell.minLevelToLearn` and `spellOriginLabel` were all undefined. `spell_info_test.dart` failed with «No named parameter with the name 'origin'». Run: `+29 -4`. character_fragment_test, with the two raw `minXpToLearn` keys removed, stayed green.
- **Task 1 GREEN (37359339):** `flutter test test/models test/utils test/shared test/graphql test/screens/mainScreen/tabs/journal` → **2287 passed**.
- **Task 2 RED (4b37e58b):** «SpellFragment.fields no longer selects minXpToLearn (D-07, Pitfall 2)» failed with `Expected: not contains 'minXpToLearn'`. Run: `+30 -1`.
- **Green at the first run:** «origin and minLevelToLearn are not selected before the gate (D-01, D-07, Pitfall 2)». Plan 23-07 flips this pin when it adds the two fields to the selection.
- **Task 2 GREEN (e9be09ab):** `flutter test test/graphql test/tool test/models` → **1346 passed** (registry untouched, 55).

## Verification

- `grep -rn "minXpToLearn" lib` → nothing. In `test/` the literal is left only in the «never minXpToLearn» pin of `spell_test.dart` and the new pin of `character_fragment_test.dart`
- `SpellOrigin.fromWire` = 1 and `minLevelToLearn` = 7 in spell.dart; `spellOriginLabel` = 1 and `XP` = 0 in spell_lines.dart; no level comparison grep hit; `origin` / `minLevelToLearn` absent from `lib/graphql`; `definition|SpellFields|damage_fragment` = 0 in spell_fragment.dart; `D-01` = 5 in spell_origin_test.dart and `D-07` = 3 in spell_lines_test.dart
- Formatter: `spell_fragment.dart` was not formatter-clean, so it got its own style commit first. The other touched files were clean. `dart format` was run one file at a time; `spell_info_test.dart` and `spell_test.dart` were reflowed by the formatter after the edits.
- Analyzer: `47 issues found. (ran in 6.3s)`, which is 47 info / 0 warning / 0 error → `ANALYZE_GATE_OK`

## Deviations from Plan

None. The plan was executed as written.

## Notes for the next plans

- Before the gate the learn line shows only the study time: no document selects `minLevelToLearn`, so the level appears from 23-07 onward. `spellOriginLabel` exists but nothing draws it yet (23-06).
- `SpellOrigin` has no `imageId` / `imagePath`. 23-06 adds them, using the three ids of D-21.
- `DamageFragment` is no longer imported by `spell_fragment.dart`. It is still a class of its own; nothing else was touched.

## Self-Check: PASSED
