# Phase 20 — UAT fix 01: legend on a hero seat drawn as «Eroe 0 / 1»

**Found:** device UAT of FE Phase 20, 2026-11-13.
**Branch:** `feat/20-rank-specific-prizes`.

## What the user saw

Boss with seats `[hero ×1, mage ×1]`, a legend registered (the BE stores the registration with `title: "legend"`). On the quest sheet the user reported: «vedo Eroe 0/1».

## Cause

BE rule 13.1 D-08: a legend beyond the legend seats occupies a hero seat. `canRegisterWithTitle` (`lib/models/quest/quest_capacity.dart`) already mirrored it through the private helpers `_foldedCountsOf` / `_seatTitleOf`, so acceptance was judged correctly. `_slotLinesOf` (`lib/models/quest/quest_sheet_details.dart`) instead counted the registrations by exact title, so the legend counted on no line (it only leaked into the «Qualsiasi rango» overflow when there was one). The viewer highlight had the same flaw: `isViewerRank: title == viewerTitle` never marked the hero line for a legend viewer who sits, or would sit, on a hero seat.

## Fix

One single source of the folding rule, in `quest_capacity.dart` (mirrors of the BE `quest-capacity.ts` helpers, no new rule):

- `exactSeatsOf(slots, title)` — exact seats per title (`null` = any rank);
- `foldedCountsOf(slots, registered)` — registered per seat title, extra legends folded onto hero (was `_foldedCountsOf`);
- `seatTitleOf(slots, registered, title)` — the seat title a character title takes (was `_seatTitleOf`);
- `anyRankOverflowOf(slots, registered)` — exact-seat overflow on the folded counts plus unknown-rank registrations.

`canRegisterWithTitle` is rewritten on top of them with the same behaviour (its tests unchanged and green). `_slotLinesOf` now counts every line and the any-rank overflow on the folded counts, and marks as viewer rank the line of `seatTitleOf` evaluated on the other registered adventurers (the viewer's own registration excluded, matched by `characterId`): a legend viewer reads the legend line while a legend seat is free or is its own, the hero line otherwise. Non-legend titles are unchanged.

Deviation from `20-REPO-RULES.md` («the FE mirrors of seat rules … are NOT changed»): authorised by the orchestrator for this UAT bug; the acceptance rule itself is unchanged.

## Tests

`test/models/quest/quest_sheet_details_test.dart`, group `legend on hero seats (BE 13.1 D-08, D-25)`, 6 new cases:

| Case | RED |
|------|-----|
| hero 1 + mage 1, one legend → «Eroe: 1 / 1», «Mago: 0 / 1» | failed (`Eroe: 0 / 1`) |
| same quest, legend viewer not registered → hero line is the viewer's | failed (`[false, false]`) |
| legend 1 + hero 1, one legend → legend 1 / 1, hero 0 / 1; two legends → legend 1 / 1, hero 1 / 1 | failed (`Eroe: 0 / 1` with two legends) |
| legend viewer, legend seat free or its own → legend line | green at first run (guard: the old exact-title match already gave it; the fix must keep it) |
| hero 1 + any 1, hero + legend → «Eroe: 1 / 1», «Qualsiasi rango: 1 / 1» | green at first run (guard: the old overflow already pushed the legend onto the any-rank line) |
| non-legend titles keep exact lines and highlight | green at first run (guard) |

After the fix: `flutter test test/models/quest test/shared/components/popup test/screens` → 2116 green; `flutter analyze` → 47 info / 0 warning / 0 error. Full suite expected total: 4291 + 6 = 4297.

## Commits

- `42883521` test(quests): expect legends folded onto the hero seat lines
- `baae07b8` fix(quests): fold legends onto the hero seat lines of the sheet
