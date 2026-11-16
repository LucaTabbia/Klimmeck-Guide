---
phase: 23-spell-origins-void-and-shamanic-quests
plan: 03
subsystem: models
tags: [quest-type, wire-boundary, rites, sheets, cloudinary]
requires: ["23-01", "23-02"]
provides:
  - "QuestType.arcane (wire arcane, label Magia, magic sheets); fromWire('magic') still reads arcane, nothing writes magic"
  - "QuestType.shamanic (wire shamanic, «Rito sciamanico») and QuestType.theVoid (wire void, «Rito del Vuoto»)"
  - "CloudinaryAssets.shamanicSheet / shamanicTornSheet / voidSheet / voidTornSheet with the real ids of D-21"
  - "«Studiando…» for the three school types above the pawn and on the Map sheet state label"
affects: [23-07, 23-08]
tech-stack:
  added: []
  patterns: ["enum wire boundary with optional wireName constructor parameter (reserved word void) and one legacy-read line"]
key-files:
  created: []
  modified:
    - lib/models/enums/quest_type.dart
    - lib/config/cloudinary_assets.dart
    - lib/models/quest/quest_paper_asset.dart
    - lib/utils/mission_lines.dart
    - lib/models/quest/quest_state_label.dart
    - test/models/enums/quest_type_test.dart
    - test/models/quest/quest_test.dart
    - test/models/quest/quest_paper_asset_test.dart
    - test/models/quest/quest_state_label_test.dart
    - test/models/quest/quest_availability_test.dart
    - test/models/quest/quest_sheet_details_test.dart
    - test/models/quest/quest_lane_test.dart
    - test/models/pending_request/pending_request_test.dart
    - test/models/mission/mission_draft_test.dart
    - test/models/quest_result/quest_result_test.dart
    - test/utils/mission_lines_test.dart
    - test/screens/mainScreen/tabs/board/sheet_test.dart
    - test/screens/mainScreen/tabs/board/board_test.dart
    - test/screens/mainScreen/tabs/map/quest_paper_layer_test.dart
decisions:
  - "The legacy wire value magic is read by ONE line at the top of QuestType.fromWire on the private constant _legacyArcaneWireName; the orchestrator decides after the BE Phase 24 boot whether to drop that line"
  - "theVoid is the only value passing wireName ('void'); wireName is _wireName ?? name"
  - "The rites have no pawn (imageId '' like arcane) and one sheet per state, like the arcane quest"
metrics:
  duration: "~25 min"
  completed: 2026-11-15
---

# Phase 23 Plan 03: Quest types arcane, shamanic and theVoid Summary

`QuestType.magic` is now `QuestType.arcane` (wire `arcane`, label «Magia», sheets `magicSheet` / `magicTornSheet` unchanged), and `fromWire` still reads the stored legacy value `magic` as `arcane` while nothing writes it. The two rites `shamanic` and `theVoid` (wire `void`) behave like the arcane quest at every site, and each draws its own whole and torn sheet from the real Cloudinary ids of D-21.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect the arcane quest type | 328f26d4 |
| 1 GREEN | Rename the magic quest type to arcane | 54855ed9 |
| 2 RED | Expect the shamanic and void rites | 492286f6 |
| 2 GREEN | Add the shamanic and void rites with their sheets | c7738457 |
| 3 RED | Expect the rites to read Studiando on the map sheet | d7245a78 |
| 3 GREEN | Read Studiando on the map sheet of a rite | 8c30df47 |
| 4 | Bookkeeping | (this docs commit) |

## TDD

- **Task 1 RED (328f26d4):** compile failure, as expected. «Member not found: 'arcane'» in quest_type_test, quest_availability_test, quest_paper_asset_test and mission_lines_test. Run: `+328 -13`.
- **Task 1 GREEN (54855ed9):** `flutter test test/models test/utils test/screens/mainScreen/tabs/board test/screens/mainScreen/tabs/map test/screens/innkeeper` → **2030 passed**.
- **Task 2 RED (492286f6):** compile failure, as expected. «Member not found» for `shamanic`, `theVoid`, `shamanicSheet`, `shamanicTornSheet`, `voidSheet` and `voidTornSheet` in quest_type_test, quest_test, quest_paper_asset_test, mission_lines_test, board/sheet_test, board/board_test and map/quest_paper_layer_test. quest_lane_test failed at runtime instead: `Expected: an object with length of <13>`, the actual list had 11. The `ArgumentError` that `buildQuest(type: 'void')` would raise once the code compiles was never reached on its own, because the values and the constants landed together in GREEN.
- **Task 2 GREEN (c7738457):** `flutter test test/models test/utils test/screens/mainScreen/tabs/board test/screens/mainScreen/tabs/map` → **1711 passed**.
- **Task 3 RED (d7245a78):** two failures, as expected (Pitfall 3, the defaulted switch). quest_state_label_test «a started rite reads like a study (D-09, Pitfall 3)» got `Actual: 'In corso…'`; quest_paper_layer_test «a started void rite draws the void sheet on the Map paper and reads Studiando (D-14, Pitfall 3)» found 0 widgets with text «Studiando…». Run: `+293 -2`.
- **Green at the first run** (the code at these sites defaults, so it needed no change):
  - quest_availability_test «the rites are repeatable standard-lane quests without registration (D-09)»: `laneOf` maps every type except story and worldMission to standard; `nonRepeatableQuestTypes` / `registeredQuestTypes` are closed sets that do not list the rites
  - quest_availability_test «a rite above the viewer title is torn and whole once the rank is reached (D-11)»: the title rule reads `minTitle`, whatever the type
  - quest_sheet_details_test service family list: `questSheetFamilyOf` falls back to service
  - board_test «a rite above the title is torn until the rank (D-11)»: it was RED in Task 2 only because the seeded constants did not compile yet
- **Task 3 GREEN (8c30df47):** `flutter test test/models test/utils test/screens/mainScreen/tabs/board test/screens/mainScreen/tabs/map test/shared/components/popup` → **1943 passed**.

## Verification

- `grep -rn "QuestType\.magic" lib test` → nothing. `'magic'` appears in `quest_type.dart` once (the legacy constant) and nowhere else in `lib/`
- `QuestType.arcane => 'Magia'` = 1; `theVoid(imageId: '', wireName: 'void')` = 1; the four ids each appear once in `cloudinary_assets.dart` and in no other `lib/` file; `CloudinaryAssets.voidTornSheet|shamanicTornSheet` = 2 in `quest_paper_asset.dart`
- The formatter wraps the study arm in `quest_state_label.dart` and `mission_lines.dart` to one type per line, so the single-line grep `QuestType.shamanic || QuestType.theVoid` is checked with `grep -A3 "QuestType.study"` instead: both files list `study`, `arcane`, `shamanic`, `theVoid`
- `lib/graphql` untouched across the six code commits (registry still 55)
- Formatter: `dart format` was run one file at a time on every touched file. Only my longer test titles were reflowed
- Analyzer: `47 issues found`, which is 47 info / 0 warning / 0 error → `ANALYZE_GATE_OK` after every code task

## Deviations from Plan

- **[Rule 3 - Blocking] Three test files outside `files_modified` changed in Task 1 RED:** `pending_request_test.dart`, `mission_draft_test.dart` and `quest_result_test.dart` pinned `QuestType.magic` or wrote `'magic'`. As 23-01 had noted, they now use `'arcane'` / `QuestType.arcane`. Commit 328f26d4.
- `quest_test.dart` gained the `quest_type.dart` import, which its new cases need.

## Notes for the next plans

- The legacy wire value `magic` is still read. The orchestrator decides after the BE Phase 24 boot whether to drop that line, which is `_legacyArcaneWireName` plus the first line of `fromWire`, along with its two tests.
- No DB quest serves `shamanic` or `void` yet. The Board and the Map draw them as soon as the BE serves them, with no selection change (`QuestInfos.type` is a plain String).

## Self-Check: PASSED
