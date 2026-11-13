# Phase 20 — UAT fix 03: the quest duration has no stray commas

**Found:** device UAT of FE Phase 20, 2026-11-13.
**Branch:** `feat/20-rank-specific-prizes`.

## What the user reported

User, 2026-11-13 (verbatim): «Su Tempo richiesto vedo ",7" secondi»

## Cause

`getStringToShowFromDuration` in `lib/utils/utils.dart` (used only by the «Tempo richiesto: …» line of `lib/shared/components/popup/quest_info_sheet.dart`) concatenated the parts with hard-coded leading commas and spaces: a duration with no hours printed « , 15 minuti », one under a minute printed «  , 7 secondi». It never showed before because every quest lasted whole hours; since quick 261113-aql the BE writes on a dungeon aid a share of the dungeon time (e.g. 1 h → 15 min), so sub-hour durations are now real. The aid of the UAT lasts 7 500 ms.

## Rule

New `formatQuestDuration(Duration)` in `lib/utils/game_duration_format.dart`, next to `formatGameDuration` (unchanged, with its callers). It keeps the wording style of this line (words, not the «h/min» abbreviations):

- only the non-zero parts, joined with «, »; no leading or trailing separator or space;
- singular/plural: `1 ora` / `2 ore`, `1 minuto` / `2 minuti`, `1 secondo` / `2 secondi`;
- seconds are printed ONLY when the whole duration is under one minute;
- fractional seconds are rounded up to the whole second (a positive duration never reads empty or zero);
- from one minute up the duration is rounded UP to the whole minute, so the line never reads less than the real time (amended by the orchestrator ruling on WR-04 of `20-REVIEW-UAT.md`, 2026-11-13; the first version truncated the minutes);
- zero or negative reads «0 minuti»;
- hours are not folded into days (today's behaviour).

The old `getStringToShowFromDuration` is removed from `utils.dart`; the quest sheet imports the new helper.

## Examples

| Duration | Line |
|----------|------|
| 3 h | «Tempo richiesto: 3 ore» |
| 15 min | «Tempo richiesto: 15 minuti» |
| 1 h 15 min | «Tempo richiesto: 1 ora, 15 minuti» |
| 1 h 15 min 30 s | «Tempo richiesto: 1 ora, 16 minuti» (WR-04) |
| 61 s | «Tempo richiesto: 2 minuti» (WR-04) |
| 119 s | «Tempo richiesto: 2 minuti» (WR-04) |
| 3 600 s | «Tempo richiesto: 1 ora» (WR-04) |
| 3 601 s | «Tempo richiesto: 1 ora, 1 minuto» (WR-04) |
| 7 500 ms | «Tempo richiesto: 8 secondi» |
| 30 s | «Tempo richiesto: 30 secondi» |
| 300 ms | «Tempo richiesto: 1 secondo» |
| 59.5 s | «Tempo richiesto: 1 minuto» |
| 25 h | «Tempo richiesto: 25 ore» |
| 0 or negative | «Tempo richiesto: 0 minuti» |

## Tests

- `test/utils/game_duration_format_test.dart`: new group `formatQuestDuration` (titles cite quick 261113-aql and the user's sentence) — 15 example cases + 1 «no leading comma nor stray space» case.
- `test/shared/components/popup/quest_info_sheet_test.dart`: new group `time line` — a quest lasting 900 000 ms prints exactly «Tempo richiesto: 15 minuti».
- Existing tests only match `textContaining('Tempo richiesto')`: none pinned the old strings, none changed.

RED: the unit file failed to compile (`Method not found: 'formatQuestDuration'`, 16 cases), the widget case failed with 0 widgets for «Tempo richiesto: 15 minuti».

After the fix: `flutter test test/utils test/shared/components/popup test/screens` → 2035 green; `flutter analyze` → 47 info / 0 warning / 0 error. Full suite expected total: 4312 + 17 = 4329.

WR-04 amendment (`20-REVIEW-UAT-FIX.md`): new group «formatQuestDuration rounds up to the whole minute from one minute on and never reads less than the real time (WR-04)» with 7 cases; the old «1 h 15 min 30 s → 1 ora, 15 minuti» case moved there as «1 ora, 16 minuti» (net +6 tests). Commits `4dd1d4af` (RED), `331cf53c` (GREEN).

## Commits

- `2d3ceb9c` test(utils): pin the quest duration wording without stray commas
- `bf1d2e78` fix(utils): word the quest duration without stray commas
