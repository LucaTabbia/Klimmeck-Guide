---
phase: 23-spell-origins-void-and-shamanic-quests
plan: 05
subsystem: map
tags: [cloudinary, asset-ids, city-markers, audit]
requires: ["23-04"]
provides:
  - "CloudinaryAssets.aarakocraVillage = v1794764202/aarakocraVillage_z7n1rz.svg (old v1761435120 id gone from lib/)"
  - "Audit: the eight sheet and city ids of D-21 each appear once in cloudinary_assets.dart and nowhere else in lib/"
affects: [23-06, 23-08]
tech-stack:
  added: []
  patterns: ["re-pointing an asset id in two commits: a test pinning the new literal, then the constant (SVG cache keyed by URL, no invalidation)"]
key-files:
  created: []
  modified:
    - lib/config/cloudinary_assets.dart
    - test/models/enums/city_type_test.dart
decisions:
  - "The new aarakocraVillage literal is pinned beside its consumer in city_type_test.dart, as quest_paper_asset_test.dart does for the sheets"
  - "No Cloudinary URL fetched (the base URL comes from the environment); the drawings are checked on the device in 23-08 step 1"
metrics:
  duration: "~5 min"
  completed: 2026-11-15
---

# Phase 23 Plan 05: Aarakocra village redrawn, eight D-21 ids audited Summary

`CloudinaryAssets.aarakocraVillage` now points to `v1794764202/aarakocraVillage_z7n1rz.svg`. Balkuldir stays `CityType.aarakocraVillage` with marker size 30, and `city_type.dart` was not touched. The audit shows that each of the eight sheet and city ids of D-21 appears exactly once in the constants file and nowhere else in `lib/`.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect the new aarakocra village marker | 1561d516 |
| 1 GREEN | Draw the aarakocra village with its new file | f33aa96b |
| 2 | Bookkeeping | (this docs commit) |

## TDD

- **RED (1561d516):** one failure, as expected. «the aarakocra village is drawn with its new file (D-17, D-21)» failed with `Expected: 'v1794764202/aarakocraVillage_z7n1rz.svg'`, `Actual: 'v1761435120/aarakocraVillage_mykdhv.svg'`. Run: `+5 -1`.
- **Green at the first run:** «the village and the capital of the aarakocra are two different drawings (D-17)». The old village id already differed from the `aarakocraCapital` id that 23-04 added, so the case passed before the change, as the plan expected. It guards against the two constants ever sharing a file.
- **GREEN (f33aa96b):** `flutter test test/models test/screens/mainScreen/tabs/map` → **1456 passed**. The verify trio (city_type, city, city_markers_layer) passed with **26**.

## Audit (D-21, run after GREEN)

```
1 v1794764202/aarakocraVillage_z7n1rz.svg
1 v1794764350/shamanicSheet_ytxu1n.svg
1 v1794764330/tornShamanicSheet_exdyou.svg
1 v1794764361/voidSheet_iyocqb.svg
1 v1794764340/tornVoidSheet_h4sp3g.svg
1 v1794764223/aarakocraCapital_affl5r.svg
1 v1794764233/dragonbornCapital_uyedhh.svg
1 v1794764212/dragonbornVillage_doclsu.svg
```

## Verification

- `aarakocraVillage_mykdhv` appears nowhere in `lib/`
- `grep -rnF "v17947642" lib` and `grep -rnF "v17947643" lib`, with `cloudinary_assets.dart` excluded, both print nothing
- `D-21` appears 2 times in city_type_test
- Formatter: `dart format` ran one file at a time on both touched files and changed nothing (0 changed)
- Analyzer: `47 issues found`, which is 47 info / 0 warning / 0 error → `ANALYZE_GATE_OK`

## Deviations from Plan

None. The plan ran as written.

## Notes for 23-06

- The three origin icon ids (`arcaneOrigin`, `shamanicOrigin`, `voidOrigin`) are not in `cloudinary_assets.dart` yet; 23-06 adds them from the REPO-RULES amendment table. Every D-21 sheet and city id is now wired.

## Self-Check: PASSED
