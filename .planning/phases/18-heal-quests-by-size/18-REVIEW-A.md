---
phase: 18-heal-quests-by-size
group: A
reviewed: 2026-11-10T11:46:00Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - lib/models/enums/injury_type.dart
  - lib/models/quest/quest.dart
  - lib/models/quest/quest_cure.dart
  - lib/models/quest/quest_prizes.dart
  - lib/models/quest/quest_availability.dart
  - lib/models/quest/quest_blocked_reason.dart
  - lib/models/quest/quest_paper_asset.dart
  - lib/models/quest_result/quest_result.dart
  - lib/models/lore.dart
  - lib/utils/item_lines.dart
  - lib/utils/lore_lines.dart
  - lib/shared/components/popup/quest_info_sheet.dart
  - lib/shared/components/popup/quest_result_sheet.dart
  - lib/screens/mainScreen/characterCubit/character_selectors.dart
  - lib/screens/mainScreen/tabs/board/board.dart
  - lib/screens/mainScreen/tabs/map/layers/quest_info_overlay.dart
  - lib/screens/mainScreen/tabs/map/world_map.dart
  - lib/screens/mainScreen/components/quest_scope_listener.dart
  - lib/screens/mainScreen/components/quest_acceptance_outcome_listener.dart
  - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart
  - lib/repository/quest_acceptance_failure.dart
findings:
  critical: 0
  warning: 0
  info: 5
  total: 5
status: issues_found
---

## Summary

Group A (quest cure rows, healed line, heal with no effect) reviewed at standard depth against the 18-CONTEXT decisions (D-01..D-06, D-19..D-21) and the 18-REPO-RULES copy. The implementation is sound. Checked and found correct:

- **Cure rows keyed by `cure` (D-05):** they appear in the combat, narrative and service families, and never depend on `QuestType.heal`.
- **Cure line (D-03):** viewer-filtered, in character order, with no count, hidden when injuries are unknown or empty.
- **Life row (D-04, D-21):** share 1 gives «al massimo», share 0 hides the row, and the elided article is correct for 8, 11 and 80–89.
- **Lenient parsing:**
  - `Quest.noEffect` is `== true`.
  - `QuestCure.tryFromJson` rejects NaN, infinite and out-of-range shares, and a non-list `canHeal`.
  - A malformed cure becomes `null` and the quest stays.
- **`noEffect` precedence:** own lane (`tornForOwner`) first, then the catalogue defect, already done, title, lane busy, full, not in city and points, and `noEffect` last. The sheet is torn in every case. `needsTravelPreview` correctly asks for no preview. The Board sheet is inert through `isEnabled: isIdle && !selected.noEffect`. It comes back whole on the next list because `selected` is re-derived from `listed` on every build, so there is no stale selection.
- **`QUEST_NO_EFFECT` refusal:** `noEffect` failure, one banner with the `quest-acceptance|noEffect|<id>` dedup key, one silent reread through `_staleListFailures`, then `reset()`.
- **`QuestScopeListener`:** vitals are compared only in a city. A city→travel transition was already a scope change through `locationId`, so no new storm appears. `refreshQuests` is last-call-wins with equality-gated emission, so a burst of emissions costs network calls but never wrong state.
- **Shared readers:** `injuryTypesFrom` and `Lore.lenientRefsFrom` are line-for-line equivalent to the removed private readers. The `as List` cast of `injuriesAdded` is kept, so Phase 17 behaviour is unchanged.
- **Narrative layout:** cure rows now scroll together with the lore, so no extra fixed height is added and nothing new can overflow.
- **Rules:** no `debugPrint`, no `AlertDialog`/`SnackBar`, no new user-visible copy beyond the REPO-RULES strings, and no game logic on the FE.

Only quality-level points remain. The gated selections (`cure`, `injuriesHealed`, `noEffect` not yet in the fragments) were treated as deferred and are not findings.

## Critical

None.

## Warning

None.

## Info

### A-IN-01: Dead public constants left by the lore-line extraction

**File:** `lib/shared/components/popup/quest_result_sheet.dart:61-62`
**Issue:** `QuestResultSheet.bestiaryPagePrefix` and `QuestResultSheet.knowledgePrefix` are now aliases of `bestiaryPageLinePrefix` and `knowledgeLinePrefix`. A grep over `lib/` and `test/` finds no reader of either alias, so the extraction left two dead public statics.
**Why it matters:** Dead code and a duplicated name for the same literal; a future edit may change one and not the other. This is the Boy Scout case the project asks to fix in the same commit.
**Suggested fix:** Delete the two statics. Nothing needs a RED test, since the existing `lore_lines_test.dart` and `quest_result_sheet_test.dart` already pin the strings.

### A-IN-02: Injury comparison in `QuestScopeListener` is order-sensitive

**File:** `lib/screens/mainScreen/components/quest_scope_listener.dart:75-77`
**Issue:** The injuries are joined in wire order, so the same set arriving in a different order is a scope change. The list-order case is not covered by the new tests (they test add and replace only). The brief asks for an order-insensitive comparison.
**Why it matters:** If the backend re-emits `characterUpdated` with the injuries reordered, which the contract does not forbid, the Board gets a needless reread, i.e. two network calls. It is harmless to state, so this is info.
**Suggested fix:** Compare as a set. A string needs no extra import: `(status?.injuries?.map((i) => i.name).toList()?..sort())?.join(',')`. RED first in `quest_scope_listener_test.dart`: emit `['contusion','deepCut']` then `['deepCut','contusion']` and `verifyNoReread()`.

### A-IN-03: `lifeShareLine` uses «il» before 1 (and not «l'»)

**File:** `lib/utils/item_lines.dart:906-919`
**Issue:** `_elidesArticle` follows D-21 (8, 11, 80–89) literally. A share of 0.01 prints «Vita: almeno il 1%». In Italian this is read «l'uno per cento» and is written «l'1%». The edge texts in (0, 0.005) and [0.995, 1) are declared and out of scope, but the 1% case is not among them.
**Why it matters:** No such tier exists in the BE (50/80/100), so it is not reachable today. It is a one-token fix that completes the rule while the helper is fresh.
**Suggested fix:** Add `percent == 1` to `_elidesArticle` with a test next to the D-21 case: `expect(lifeShareLine(_cure(share: 0.01)), "Vita: almeno l'1%")`. If the orchestrator prefers to keep D-21 verbatim, close this finding as wontfix.

### A-IN-04: A flag read for «any type» is torn in logic but drawn whole for types without a torn asset

**File:** `lib/models/quest/quest_paper_asset.dart:32-50` (with `quest_availability.dart:58-62`)
**Issue:** `standingOf` marks any quest with `noEffect` as torn (the test «the flag is read for any type» pins this for `job`). `questPaperAssetIds` has a torn variant only for boss/enemy, story/worldMission, heal (borrowed) and dungeon/aid. For job, guard, hunt, crime and study, `isTorn: true` still returns the whole sheet. The BE only sets `noEffect` on `heal` (D-20), so this is not reachable now.
**Why it matters:** If the BE ever widens the flag, the Board would show a whole-looking sheet that silently refuses the swipe. The user would get no visual cue beyond the red line on the open sheet.
**Suggested fix:** Either document in `questPaperAssetIds` that the flag is heal-only, or give those types the generic torn pair the way heal does. A RED test would be `questPaperAssetIds(QuestType.job, isTorn: true)` expecting the torn pair, if the second option is chosen.

### A-IN-05: Test gap — narrative sheet with lore AND cure rows together

**File:** `test/shared/components/popup/quest_info_sheet_test.dart:355-395` and the group `cure rows (BE Phase 18)` (~897-1085)
**Issue:** The 18-04 deviation moved the cure rows into the scroll region with the lore. The narrative cure test uses `buildQuest(type: 'story', prizes: …)` with no lore, i.e. the «no lore» branch only. The branch where the lore, the cure lines and the fixed cost, title and slot rows share the region is not exercised. Nothing proves that a long lore plus the two rows plus a title line produces no overflow exception, or that the rows are reachable by scrolling.
**Why it matters:** The sheet is the layout most exposed to small screens, and a regression there would show only on the device.
**Suggested fix:** Add one widget test with `type: 'story'`, a multi-paragraph `lore`, a cure, a `minTitle` and the landscape phone helper. Assert `tester.takeException()` is null and that `tester.ensureVisible(find.byKey(QuestInfoSheet.lifeLineKey))` succeeds (it scrolls the `SingleChildScrollView`).

---

_Reviewed: 2026-11-10T11:46:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
