---
phase: 23-spell-origins-void-and-shamanic-quests
plan: 09
subsystem: utils
tags: [requirements, spell, learn-line, research, learning]
requires: ["23-07"]
provides:
  - "ORIGIN-07 and ORIGIN-08 in REQUIREMENTS.md (Pending), ORIGIN-02 / ORIGIN-03 reworded for D-28 / D-26 / D-32"
  - "spellLearnLabel by level only: «Per impararla: Livello N», no learn time (D-28)"
  - "Validation rows 23-09-01 .. 23-14-03; nyquist_compliant back to false until 23-14"
  - "D-32 appended to 23-CONTEXT.md; «Ricercando…» written in the texts of 23-11, 23-12, 23-08"
affects: [23-10, 23-11, 23-12, 23-13, 23-14, 23-08]
tech-stack:
  added: []
  patterns: []
key-files:
  created: []
  modified:
    - lib/utils/spell_lines.dart
    - test/utils/spell_lines_test.dart
    - test/shared/components/spell_info_test.dart
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/phases/23-spell-origins-void-and-shamanic-quests/23-VALIDATION.md
    - .planning/phases/23-spell-origins-void-and-shamanic-quests/23-CONTEXT.md
decisions:
  - "Spell.requiredLearnTime stays in the model and in SpellFragment.fields (23-13 reads it on QuestResult.spellFound)"
  - "A spell without a served level (or level <= 0) prints no learn line at all"
  - "D-32 (user, relayed mid-plan): the on-screen label of the research part is «Ricercando…»; «Fase di ricerca» stays the name of the part"
metrics:
  duration: "~25 min"
  completed: 2026-11-16
---

# Phase 23 Plan 09: Research and learning requirements, learn line by level only Summary

First plan of the research and learning block (D-26..D-31, plus D-32). ORIGIN-07 and ORIGIN-08 are registered as Pending, ORIGIN-02 and ORIGIN-03 reworded, the ROADMAP gains success criterion 6, and the spell details now read «Per impararla: Livello N» only (D-28).

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 | Register ORIGIN-07 / ORIGIN-08, reword ORIGIN-02 / ORIGIN-03, validation rows | 8e60835a |
| 2 RED | Expect the learn line without the learn time | 0cee3fb8 |
| 2 GREEN | Drop the learn time from the spell details | 571992e1 |
| 3 | Bookkeeping, D-32 in the context and in the plan texts | (this docs commit) |

## RED failures (verbatim)

- `the learn line reads the level only, never the learn time (D-28)` — `Actual: 'Per impararla: Livello 6 · 1 h di studio'`
- `a spell without a level has no learn line even with a learn time (D-28)` — `Actual: 'Per impararla: 1 h di studio'`
- `a zero or negative level prints no learn line (D-08, D-28)` — `Actual: 'Per impararla: 1 h di studio'`
- `shows every detail of a recovering spell, no learn time (D-28)` — `Found 0 widgets with text "Per impararla: Livello 6"`

Green at the first run: `spellLearnLabel with the level and no learn time (D-07, D-28)` (the level-only copy already existed) and `spellLearnLabel without requirements` (no level, no line: unchanged).

## Copy

- `Per impararla: Livello N` (the only learn line; no learn time anywhere on a spell).

## Verification

- `flutter test test/utils/spell_lines_test.dart test/shared/components/spell_info_test.dart` green.
- Analyzer `47 issues found`, `ANALYZE_GATE_OK` (47 info / 0 warning / 0 error).
- Full suite: `+5107: All tests passed!`.
- `grep -c "di studio\|requiredLearnTime" lib/utils/spell_lines.dart` = 0; `requiredLearnTime` still in `lib/models/spell.dart` (7) and `spell_fragment.dart` (1).

## Deviations from Plan

1. **[Rule 2 - Correctness] Coverage line of REQUIREMENTS.md** updated to `40 / 40 v1.1` and `8 ORIGIN → Phase 23` (it still counted 38 / 6 after the two new requirements). Commit 8e60835a.
2. **D-32 (orchestrator message during the plan, user copy decision):** the label of the research part is «Ricercando…» (U+2026, like «Studiando…»), not «Fase di ricerca». Applied in this docs commit: D-32 appended to the 2026-11-16 amendments of `23-CONTEXT.md`; ORIGIN-03 and ORIGIN-07 read «Ricercando…» (ORIGIN-07 names the part «Fase di ricerca» once); ROADMAP success criteria 2 and 6 and the 23-11 plan line; every on-screen occurrence in the texts of `23-11-PLAN.md`, `23-12-PLAN.md`, `23-08-PLAN.md` rewritten (literals `'Ricercando…'`, `«Ricercando…»`, the acceptance grep of 23-11 now looks for `'Ricercando…'`). Kept as the name of the part: the user quote of D-26 and the doc comment of `isSpellResearchQuest` in 23-11. No code with «Fase di ricerca» had been committed, so no RED/GREEN pair was needed.
3. `nyquist_compliant: false` set as the plan asked (back to `true` in 23-14).

## Known Stubs

None.

## Self-Check: PASSED

- Commits 8e60835a, 0cee3fb8, 571992e1 present in `git log`.
- `lib/utils/spell_lines.dart` and the two test files modified as listed.
