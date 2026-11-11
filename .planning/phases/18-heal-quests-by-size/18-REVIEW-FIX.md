---
phase: 18-heal-quests-by-size
fixed_at: 2026-11-10
review_path: .planning/phases/18-heal-quests-by-size/18-REVIEW-A.md, .planning/phases/18-heal-quests-by-size/18-REVIEW-B.md
rulings_path: .planning/phases/18-heal-quests-by-size/18-REVIEW-RULINGS.md
iteration: 1
findings_in_scope: 12
fixed: 9
skipped: 3
status: partial
---

# Phase 18: Code Review Fix Report

**Fixed at:** 2026-11-10
**Source review:** `18-REVIEW-A.md` (5 info) and `18-REVIEW-B.md` (1 warning, 6 info), with the binding rulings in `18-REVIEW-RULINGS.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 12. The rulings give 9 FIX and 3 NOT NEEDED.
- Fixed: 9, all of the FIX rulings.
- Skipped: 3, all NOT NEEDED by ruling. No code was touched for them.

`status: partial` only reflects the three NOT NEEDED findings. Every FIX ruling is applied. Each fix follows TDD: a RED `test(...)` commit, then a GREEN `fix(...)`/`refactor(...)` commit. A test-only finding is a single `test(...)` commit. The finding ID is in every commit body. No commit has a trailer.

## Outcome per finding

| ID | Outcome | Commits | Note |
|----|---------|---------|------|
| A-IN-01 | fixed | `48fcd84` | I grepped `lib/`, `test/` and `tool/`: nothing reads `QuestResultSheet.bestiaryPagePrefix` or `knowledgePrefix`, so both aliases are deleted. The `lore_lines.dart` import stays (it is still used by `loreUnlockedLine`). There is no RED commit: no behaviour changes, and `lore_lines_test.dart` / `quest_result_sheet_test.dart` already pin the strings and stay green. |
| A-IN-02 | fixed | `729e459` (RED), `cd28d63` | RED: `['contusion','deepCut']` followed by `['deepCut','contusion']` triggered `refreshQuests(cityId: city-1)`. GREEN: `QuestScopeListener` now sorts the injury names before it joins them (`_injurySetOf`). |
| A-IN-03 | fixed | `d535dfc` (RED), `80b407e` | RED: the line was «Vita: almeno il 1%». GREEN: `_elidesArticle` also covers 1, so the line is «Vita: almeno l'1%». No other copy changed. |
| A-IN-04 | skipped (NOT NEEDED) | — | Per the ruling, the backend sets `noEffect` only on a heal (BE D-25, `Quest.noEffect` is false for the other types), and the FE does not second-guess the type (D-05/D-10). **For the 18-12 gate:** confirm in the BE handoff that `noEffect` stays heal-only. |
| A-IN-05 | fixed (test only) | `b9b7020` | The new test: a story quest with a long lore, a cure, a cost line and a required title, on the landscape phone harness. It checks no overflow, that the life row is reached by scrolling the lore region (inner scroll offset > 0, row overlaps the region), and that the cost and title lines keep their offset in the family and stay inside it. It was green at the first run. **Not vacuous:** I moved the cure rows back among the pinned rows (the pre-18-04 layout) locally, and the test failed with a 146 px overflow (not committed). **Found while writing it (pre-existing, not fixed):** with the Paladin title, the pinned cost and title rows overflow by 22 px on the landscape harness when the quest has any prizes. This happens even with **no lore and no cure** (`prizes: {'xpPrize': 10}`), so it does not come from the 18-04 layout. The test font draws every glyph one em wide, so both pinned lines wrap and leave the scroll region about 9 px tall. Whether this happens on a device with Cormorant Garamond is not proven. Fixing it would mean re-laying out the pinned rows, which goes against «stay pinned» and is out of scope here. The test uses the Hero title instead. Left to the orchestrator: decide, or check on the device. |
| B-WR-01 | fixed (test only) | `2257680` | New group `drag to dismiss (D-18)` in `items_section_test.dart`, with the drag from `world_map_travel_test.dart`. While `PotionDrinking`, a drag to the minimum extent leaves the sheet open, and the `PotionDrunk` that lands next shows the outcome face (HP bar, «Continua»). The opposite case: in `PotionIdle` the same drag dismisses the sheet. It was green at the first run. **Not vacuous:** I made the `DraggableScrollableNotification` swallow return `false` locally, and the in-flight case failed because the sheet was gone (not committed). |
| B-IN-01 | fixed (test only) | `90ca9f0` | `pumpJournalPage` now mounts the Journal under `PotionOutcomeListener`, with an `InAppNotificationsCubit` provider (optional `notices`, a mock by default), as production does. Two tests run the real `PotionCubit` on a `MockItemUseRepository`. First: drink → outcome → «Continua» → reopening the same potion shows «Bevi Erbe da campo?» and no HP bar, with one call. Second: a `noEffect` refusal pops the sheet and publishes one banner «Pozione non bevuta». Both were green at the first run. **Not vacuous:** three local breaks, none committed. Without `reset()` before the sheet opens, the reopen case fails. With the refusal close of `PotionSheet` disabled, the sheet stays. With the listener disabled, no banner is published. All 216 Journal tests stay green with the extended harness. |
| B-IN-02 | fixed (test only) | `20ac1ec` | The timeout case of `item_use_repository_test.dart` now runs on `fakeAsync` against the default 15 s timeout. No failure at 15 s − 1 ms, `timedOut` at 15 s, and no real timer is used. It was green at the first run. **Not vacuous:** I removed `.timeout(timeout)` from the repository locally, and the test failed with a null failure (not committed). `quest_abandon_repository_test.dart` is not touched (out of scope per the ruling). |
| B-IN-03 | skipped (NOT NEEDED) | — | Per the ruling, `graphQlErrorExtension` reads the extension of the same error whose `code` is mapped, by design. The backend returns one error per refusal. |
| B-IN-04 | skipped (NOT NEEDED) | — | Per the ruling, `quantityLeft` is a contract field and is parsed strictly on purpose. The quantity on screen comes from the character stream, and `toJson` follows the convention of the other models. |
| B-IN-05 | fixed | `56cb109` (RED), `d3281be` | RED: with `maxLifePoints: 0`, the outcome face drew `HpDeltaBar` with max 0. GREEN: `PotionSheet.maxLifePoints` is now `int?`, and `_hpBar` returns null (null-aware element) when the value is null or not positive. `ItemsSection` passes `character.status?.maxLifePoints` without the `?? 0`. The GREEN commit also extends the sheet test to the `null` maximum, because that case needs the new signature. |
| B-IN-06 | fixed | `5fdfa65` (RED), `7171498` | RED: an `unknown` refusal did not call `refreshCharacter()`. GREEN: `_staleViewFailures` of `PotionOutcomeListener` is now `{notOwned, timedOut, unknown}`. The test also checks that the banner stays the generic one: «Pozione non bevuta / Qualcosa è andato storto, riprova». |

## Rules respected

- I ran `dart format` only on the touched files, one at a time. It reflowed one untouched expression in `potion_sheet.dart` (the `HpDeltaBar` builder, now on one line) and the `journal_harness.dart` listener child. Both are inside the fix scope.
- No fragment under `lib/graphql/fragments` selects `cure`, `injuriesHealed`, `noEffect`, `recovery` or `potionRecoveryUntil`. The only grep hit is the pre-existing `recoveryTime` of `spell_fragment.dart`.
- No new user-visible copy beyond A-IN-03. No new dependency (`fake_async` was already a dev dependency). No `debugPrint(`/`print(` in `lib/`. No `AlertDialog`/`SnackBar`. No `// ignore:`.
- `pubspec.lock` is never staged or reverted. After every commit, `git status --short` printed only ` M pubspec.lock`.

## Final gates

- `flutter test` (full suite, foreground): **3913 tests, all passed**. That is 3904 before the fixes, plus 9 new cases: A-IN-02 1, A-IN-03 1, A-IN-05 1, B-WR-01 2, B-IN-01 2, B-IN-05 1, B-IN-06 1. B-IN-02 replaced its case in place.
- `flutter analyze --no-fatal-infos`: **47 issues, all info, 0 error, 0 warning** (baseline unchanged).
- `bash tool/hardening_check.sh`: **OK**.

---

_Fixed: 2026-11-10_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
