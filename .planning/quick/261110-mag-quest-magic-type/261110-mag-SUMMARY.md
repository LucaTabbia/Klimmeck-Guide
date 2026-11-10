---
quick: 261110-mag
title: Quest type magic and the general torn-sheet rule
date: 2026-11-10
branch: feat/18-heal-quests-by-size
commits: [6546d9d, f9b742e, cc13a1d, a0c870b]
status: complete
---

# Quick task 261110-mag — magic quest and torn sheets

**Trigger (user, 2026-11-10), verbatim:**

- «Ho aggiunto questi due asset: […]/v1794317365/magicSheet_i7xslb.svg […]/v1794317370/tornMagicSheet_tmjghe.svg che sono specifici per una quest study. […] Creiamone una nuova, ovvero quella che userà questi asset, che ti permette di imparare la magia. Il rango richiesto minimo è mago, quindi prima di allora la vedi strappata. […] Potrebbe valer la pena aggiungere la entry "magic" al tipo di quest […]. Per il resto la quest è uguale ad una quest study normale. Non è posizionata su un POI diverso da quello della città ed è ripetibile.»
- «è una regola generale, ti darò i nuovi asset strappati a breve. Vale lo stesso anche per le quest non piene, ma prive di uno slot dove possa entrare il personaggio. Insomma, tutte le quest non accettabili hanno il foglio strappato.»
- «L'unico caso in cui non si strappano è se hai la coda standard piena. Però se non rispetti i requisiti della quest si.»

BE twin: same id on the BE repo (not touched from here).

## A. Quest type `magic`

- `lib/models/enums/quest_type.dart`: `QuestType.magic` (wire name `magic`, parsed by the existing `byName` / `asNameMap` readers), label **«Magia»** (the only new string). `dart format` reflowed the untouched `imagePath` getter (over 80 columns): accepted.
- Treated exactly like `study`:
  - lane: `laneOf` falls to `QuestLane.standard` through its `_` arm; `magic` is in neither `registeredQuestTypes` nor `nonRepeatableQuestTypes` (repeatable, no registration) — `lib/models/quest/quest_lane.dart`, unchanged, pinned by a new test;
  - state label: `lib/models/quest/quest_state_label.dart` `QuestType.study || QuestType.magic => 'Studiando…'`;
  - sheet family: `questSheetFamilyOf` falls to `service` through its `_` arm (`lib/models/quest/quest_sheet_details.dart`, unchanged), pinned in the test list.
  - No other switch on `QuestType` names `study` (`grep -rn "QuestType\." lib`); the analyzer found no exhaustive switch to complete besides `label` and `questPaperAssetIds`.
- `lib/config/cloudinary_assets.dart`: `magicSheet = 'v1794317365/magicSheet_i7xslb.svg'`, `magicTornSheet = 'v1794317370/tornMagicSheet_tmjghe.svg'`.
- `lib/models/quest/quest_paper_asset.dart`: `QuestType.magic` → `[magicSheet]` whole, `[magicTornSheet]` torn.
- The minimum rank (mage) is quest data (`requirements.minTitle`), handled by `isTitleEligible`; the spell draw is server-side. No fragment change.

## B. General torn rule

`lib/models/quest/quest_availability.dart`: `availability` values and the precedence of `_availabilityOf` are unchanged; only `isTorn` changes.

```dart
bool isSheetTorn(
  QuestAvailability availability, {
  required bool failsOwnRequirements,
}) => switch (availability) {
  QuestAvailability.available => false,
  QuestAvailability.laneBusy => failsOwnRequirements,
  QuestAvailability.tornForOwner ||
  QuestAvailability.notAcceptable ||
  QuestAvailability.alreadyDone ||
  QuestAvailability.titleMismatch ||
  QuestAvailability.full ||
  QuestAvailability.notInCity ||
  QuestAvailability.insufficientPoints ||
  QuestAvailability.noEffect => true,
};

bool _failsOwnRequirements(Quest quest, QuestViewer viewer) =>
    quest.noEffect ||
    _isFullForViewer(quest, viewer) ||
    _lacksPoints(quest, viewer);
```

- The switch has no `_` arm: a new `QuestAvailability` value is a compile error until it gets a decision, and the table-driven test also checks that its table covers `QuestAvailability.values`.
- `_lacksPoints` (new) is the old inline points check (story/worldMission lanes only, unknown balance never blocks), now shared by `_availabilityOf` and the busy-lane case: a busy lane with too few points for the quest's own cost is torn. Title mismatch and already-done precede `laneBusy`, so they are always torn.
- The Board swipe is unchanged: `Sheet` only draws `isTorn`; tearing/accepting is still gated by `QuestStanding.canAccept` (`availability == available`), and the reason line (`quest_blocked_reason.dart`) is unchanged.

### What the user now sees torn that was whole before, per screen

- **Board** (`board.dart` → `standingOf(quest, viewer).isTorn`):
  - quests above the viewer's title (`titleMismatch`), e.g. a magic quest with `minTitle: mage` for a paladin — the user's «prima di allora la vedi strappata». Story is listed only for the exact title, so this concerns the other types;
  - story/worldMission over the balance (`insufficientPoints`), and with their lane busy when the balance is below the cost;
  - catalogue defects (`notAcceptable`: story/worldMission without points, rank-shape boss without slots);
  - `alreadyDone` for a registered-type quest the viewer is registered on without holding it in the lane (completed non-repeatable quests are filtered out of the Board and never drawn).
  - Still whole: an acceptable quest, and every quest whose only obstacle is a busy lane.
- **`notInCity`: no visible change anywhere.** On the Board `boardQuestsFor` lists a non-story quest only when its marker is among the city POIs, story skips the city check, and the viewer's own lane quest resolves to `tornForOwner` first, so a listed quest never reaches `notInCity`. Off a city marker the Board shows no papers. The Map (`quest_paper_layer.dart`) draws only the viewer's own standard-lane quest and always with `isTorn: false`, so it does not read the rule.
- **Map / quest info sheet:** unchanged (they never draw a torn asset).

### Families still waiting for torn assets

`crime`, `guard` / `hunt` / `job` and `study` return their whole sheets for `isTorn: true` — no placeholder, no borrowed asset. The plug-in point is the switch of `lib/models/quest/quest_paper_asset.dart`, marked by the comment above the `crime` arm. Torn variants exist for hunt-family (boss/enemy), story/worldMission, heal, magic, dungeon/aid/null.

## Pinned tests updated

- `test/models/quest/quest_lane_test.dart` «every other type is standard»: `hasLength(10)` → `hasLength(11)` (one more standard-lane type). Updated in the GREEN commit `f9b742e`, not RED-first (see deviations).
- `test/models/quest/quest_paper_asset_test.dart` «job, study and crime sheets are never torn» → «job, study and crime have no torn sheet yet (quick 261110-mag)»: title only, assertions unchanged (still true until the assets arrive).
- `test/models/quest/quest_sheet_details_test.dart`: `QuestType.magic` added to the service-family list (RED commit).
- No existing test pinned the old rule for a non-acceptable whole sheet: the suite had no title-mismatch/insufficient-points/not-acceptable Board case asserting `isTorn: false`; the existing torn cases (own lane, full, noEffect, full worldMission with busy lane) stay green under the new expression.

## New tests (14, all titled `(quick 261110-mag)`)

- Part A (6): `QuestType.magic` label «Magia» and wire name; state label equals study's «Studiando…»; magic whole/torn assets; magic asset ids pinned; magic is a repeatable standard-lane type (completed magic still available); `Sheet` widget draws the magic whole and torn SVG (both ids seeded in `sheet_test.dart`).
- Part B (8): table over every `QuestAvailability` value × requirements met/failing; magic above the title torn; same quest whole at mage; alreadyDone/notAcceptable/notInCity/insufficientPoints torn; busy lane alone whole; busy lane with too few points torn (and whole with enough); Board: magic above the title torn; Board with a busy standard lane: hunt and in-rank magic whole, above-rank magic torn (magic ids seeded in `board_test.dart`).

## TDD

- RED `6546d9d`: compile failures `Member not found: 'magic'` / `'magicSheet'` / `'magicTornSheet'` in quest_type, quest_sheet_details, quest_paper_asset tests; 3 failures in `quest_state_label_test.dart` and the availability/sheet tests (`QuestType.values.byName('magic')` throws on the fixture). GREEN `f9b742e`.
- RED `cc13a1d`: `Method not found: 'isSheetTorn'` (availability test file), and the two Board tests failing (title-mismatch magic drawn whole). GREEN `a0c870b`.

## Gates

- Full suite: **3928 tests, all passed** (3914 before + 14 new).
- `flutter analyze --no-fatal-infos`: 47 info, 0 error, 0 warning (baseline).
- `bash tool/hardening_check.sh`: OK.
- `git status --short` after each commit: only ` M pubspec.lock`.

## Deviations

- `quest_lane_test.dart` count pin (10 → 11) was found by the post-GREEN run of `test/models` and updated in the GREEN commit instead of RED-first.
- The rename of the «never torn» test title rode with the GREEN commit of part B (title only, no assertion change).
- Cloudinary URLs of the two magic assets not probed with curl from here (the base URL comes from the env config); the ids are copied verbatim from the user's links.
