---
phase: 23-spell-origins-void-and-shamanic-quests
plan: 06
subsystem: shared
tags: [spell, origin, cloudinary, spell-card, spell-info]
requires: ["23-05"]
provides:
  - "CloudinaryAssets.arcaneOrigin / shamanicOrigin / voidOrigin (D-21 ids) and SpellOrigin.imagePath"
  - "SpellCard draws origin → use → energy; three icons at size / 3.2, one or two at size / 2.5"
  - "SpellInfo row «Origine: <label>» with the origin icon between the title row and the use row"
affects: [23-07, 23-08]
tech-stack:
  added: []
  patterns: ["icon size chosen by icon count, divisors as named private constants"]
key-files:
  created: []
  modified:
    - lib/config/cloudinary_assets.dart
    - lib/models/enums/spell_origin.dart
    - lib/shared/components/cards/spell_card.dart
    - lib/shared/components/spell_info.dart
    - test/models/enums/spell_origin_test.dart
    - test/shared/components/cards/spell_card_test.dart
    - test/shared/components/spell_info_test.dart
    - test/shared/components/popup/spell_info_sheet_test.dart
decisions:
  - "Card icon size depends on the icon count: three icons size / 3.2, one or two keep size / 2.5 (provisional, settled on the device in 23-08)"
  - "The «Origine: …» row of SpellInfo reuses _iconRow and _line: no new widget, no new TextStyle (provisional, settled on the device in 23-08)"
metrics:
  duration: "~15 min"
  completed: 2026-11-15
---

# Phase 23 Plan 06: Origin icon first on the spell card and in the details Summary

The three origin icons of D-21 are now constants of `cloudinary_assets.dart`, and `SpellOrigin.imagePath` builds their URLs. `SpellCard` draws its icons in the order origin, use, energy. With three icons each one is `size / 3.2`; with one or two icons each keeps today's `size / 2.5`. Both divisors are now named private constants. `SpellInfo` shows «Origine: Arcana / Sciamanica / Vuoto» with its icon between the title and the use row. A spell without an origin is drawn exactly as before, and today every spell has none because no document selects the field until 23-07.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect the spell origin icons | 35ef2d7d |
| 1 GREEN | Give every spell origin its icon | 27d2fe3f |
| 2 RED | Expect the spell origin icon first | 52dd2d27 |
| 2 GREEN | Draw the spell origin before use and energy | 32e48e74 |
| 3 | Bookkeeping | (this docs commit) |

## TDD

- **Task 1 RED (35ef2d7d):** compile failure, as expected. `CloudinaryAssets.arcaneOrigin`, `shamanicOrigin` and `voidOrigin` and the getter `SpellOrigin.imagePath` were all undefined, so the file failed to load: `+0 -1`.
- **Task 1 GREEN (27d2fe3f):** `flutter test test/models test/utils` → **1343 passed**. The verify command (`test/models/enums test/models/spell_test.dart`) → **66 passed**.
- **Task 2 RED (52dd2d27):** five failures, as expected: `+22 -5`. The failing cases were «the origin icon is drawn first, before use and energy», «three icons shrink to fit the card», «an origin with one other icon keeps today's size», «the origin row sits before the use row with its icon» and «the details sheet draws the origin on the card and in the details». The card drew no origin icon, and the details had no origin row.
- **Green at the first run (guards on today's behaviour):**
  - «three icons never overflow the smallest card in use (D-05, Pitfall 5)»: before the change the card drew only two icons, so nothing could overflow.
  - «a spell without origin keeps its two icons at today's size (D-05)»
  - «a spell without origin shows no origin row (D-05)»

  The last two describe today's rendering and must stay true once the change lands.
- **Task 2 GREEN (32e48e74):** `flutter test test/shared test/screens/mainScreen/tabs/journal test/screens/innkeeper test/screens/mainScreen/tabs/shop test/models` → **2293 passed**. The verify command (`test/shared test/screens/mainScreen/tabs/journal test/screens/innkeeper`) → **1082 passed**. The three touched test files → **27 passed**.

## Verification

- Whole suite, run once (last pre-gate plan): `flutter test -r expanded` → **5102 passed** (`02:03 +5102: All tests passed!`). The baseline was 5041.
- Each of the three origin ids appears 1 time in `cloudinary_assets.dart`. `String get imagePath` appears 1 time in `spell_origin.dart`.
- `_crowdedIconDivisor` appears 2 times in `spell_card.dart`; `size / 2.5` appears 0 times. `spellOriginLabel` appears 1 time in `spell_info.dart`.
- Outside `spell_lines.dart`, `'Origine` appears nowhere in `lib/`. `spell_info.dart` and `spell_card.dart` contain no `TextStyle(`.
- `Pitfall 5` appears 2 times in `spell_card_test.dart`; `D-05` appears 2 or more times in `spell_info_test.dart`.
- `origin` does not appear in `spell_fragment.dart` or `equipment_fragment.dart`, and nothing under `lib/graphql` changed. The registry is untouched (55).
- No acceptance grep needed `grep -A3`.
- Formatter: `dart format` ran one file at a time on all 8 touched files. The four lib files were already formatter-clean after the edits (0 changed). The four test files were reflowed by the formatter after the new cases were written.
- Analyzer: `47 issues found. (ran in 5.9s)`, which is 47 info / 0 warning / 0 error → `ANALYZE_GATE_OK`.

## Provisional visuals

The icon divisor 3.2 for three icons and the «Origine: …» row are provisional: they get settled on the device in 23-08.

## Deviations from Plan

None. The plan ran as written.

## Notes for 23-07

- The origin is drawn only once `Spell.origin` is served. 23-07 adds `origin` (and `minLevelToLearn`) to `SpellFragment`, and nothing else is needed for the card and the details to show it. It also flips the «origin and minLevelToLearn are not selected before the gate» pin of 23-02.
- `SpellCard` callers and the card size contract are unchanged.

## Self-Check: PASSED
