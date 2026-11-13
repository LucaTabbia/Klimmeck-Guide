# Phase 20 — UAT fix 02: the dungeon turn line names the floor reached

**Found:** device UAT of FE Phase 20, 2026-11-13.
**Branch:** `feat/20-rank-specific-prizes`.

## What the user asked

User, 2026-11-13 (verbatim): «invece di scrivere "«Ferito raggiunto al turno 2 di 8" scriviamo "Soccorso effettuato al raggiungimento del 2° piano su 8"»

Asked by the orchestrator whether the other two turn lines should use the word «piano» too, the user picked the proposed option «Sì, tutte con «piano»» (an option written by the orchestrator, not the user's own sentence).

## Change

Copy only, in one place (`dungeonTurnLine` in `lib/utils/quest_outcome_lines.dart`): no logic, no branch order, no new line. `L` = `lastTurn` exactly as served (never +1), written as the number followed by `°`; `T` = `turnsTotal`; `C` = `turnsCompleted ?? 0`.

| Case | Old | New |
|------|-----|-----|
| Rescuer wins a dungeon aid | «Ferito raggiunto al turno L di T» | «Soccorso effettuato al raggiungimento del L° piano su T» |
| Defeat (`failure`), kind exploration | «Caduto al turno L di T, in esplorazione» | «Caduto al L° piano su T, in esplorazione» |
| Defeat (`failure`), kind fight | «Caduto al turno L di T, in uno scontro» | «Caduto al L° piano su T, in uno scontro» |
| Defeat (`failure`), kind unknown | «Caduto al turno L di T» | «Caduto al L° piano su T» |
| Dungeon cleared, and every case where `lastTurn` is missing where needed | «Turni superati: C di T» | «Piani superati: C su T» |
| No turn fields | «Esplorazione: tappa N di M» | unchanged |

`rescued`, `death` and `gmCompleted` still print no turn line.

Documents updated: the copy table of `20-REPO-RULES.md`, the device steps, the `<what-built>` and the acceptance greps of `20-04-PLAN.md` (the greps now look for «Soccorso effettuato al raggiungimento del», «piano su M, in uno scontro» and «Piani superati:»), the manual-verification row of `20-VALIDATION.md`. Earlier records (`20-CONTEXT.md`, `20-RESEARCH.md`, `20-02-PLAN.md`, `20-REVIEW*.md`, `BACKEND-NOTES.md`, SUMMARY files) keep the old copy as history.

## Tests

Expected strings updated in `test/utils/quest_outcome_lines_test.dart` (the D-22 «never adds one» case now checks `4° piano` / not `5° piano`) and `test/shared/components/popup/quest_result_sheet_test.dart`; the fixture comment of `aidDungeonResultJson` follows the new wording. No case added or removed.

RED: 12 failures (10 unit in the `dungeonTurnLine (Phase 20)` group, 2 widget in `dungeon turns (Phase 20)`), each on the old copy.

After the fix: `flutter test test/utils test/shared/components/popup test/models/quest_result test/screens` → 2121 green; `flutter analyze` → 47 info / 0 warning / 0 error. Full suite expected total unchanged: 4312.

## Commits

- `2f619639` test(utils): expect the dungeon turn line to name the floor reached
- `b42e4f11` fix(utils): name the floor reached in the dungeon turn line
