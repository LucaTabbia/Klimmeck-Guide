# Phase 23 — common rules for the executors

Part of the context of EVERY `23-NN-PLAN.md` (cited with `@`). Written by the orchestrator on 2026-11-15 after the research.

## Inherited rules

The general sections of `.planning/phases/22-companion-defeat-rest-and-recovery/22-REPO-RULES.md` (repo, sequential execution, TDD, commits, analyzer, format only on touched files, secrets, no real database, no BE edits) apply verbatim (read them), with these differences:

- Branch `feat/23-spell-origins-void-and-shamanic-quests` already checked out, stacked on `feat/22-companion-defeat-rest-and-recovery`.
- Docs scope `docs(phase-23)`. No attribution trailers (`Co-Authored-By`, `Generated with`, `Claude-Session`), ever.
- Requirements `ORIGIN-01..06`, added to `REQUIREMENTS.md` by the first plan.
- Baselines: analyzer 47 info / 0 warnings / 0 errors; suite 5041 green.

## Contract and names (orchestrator rulings, 2026-11-15)

| What | Name | Notes |
|------|------|-------|
| Wire boundary for reserved words | `wireName` / `fromWire` on `QuestType` (and on `SpellOrigin`); Dart name `theVoid` for wire `void` | `void` is reserved in Dart; `QuestType` crosses the wire by Dart name in six places: all go through the boundary (first plan) |
| Origin (D-01) | enum `SpellOrigin { theVoid, arcane, shamanic }`, wire `void` / `arcane` / `shamanic`; BE field `Spell.origin: String!` | labels «Vuoto», «Arcana», «Sciamanica»; lenient parsing (absent or unknown → null, nothing drawn) |
| Minimum level (D-07) | BE `Spell.minLevelToLearn: Int!`; model field `minLevelToLearn` (nullable) | pre-gate plan removes `minXpToLearn` from the selection and the model (valid on both SDLs) and deletes the dead `SpellFragment.definition`; the gate plan adds `origin` and `minLevelToLearn` to the selection; the learn line reads «Livello N» only when the level is present. The app never computes a level |
| Quest types (D-09, D-13) | `QuestType.shamanic`, `QuestType.theVoid`; labels «Rito sciamanico», «Rito del Vuoto» | exactly like `magic` at every site of research F-3, including `quest_state_label.dart` («Studiando…» for both) |
| Sheets (D-14) | `CloudinaryAssets.shamanicSheet`, `shamanicTornSheet`, `voidSheet`, `voidTornSheet` | same use as `magicSheet` / `magicTornSheet` |
| City types (D-15..D-17) | `CityType.aarakocraCapital` (39), `dragonbornCapital` (39), `dragonbornVillage` (30); `aarakocraVillage` id replaced | no `alwaysVisible` |
| Asset ids | stand-in ids for the seven new sheet and city constants until the user gives the real ones, with a «no stand-in left» guard test that the ids plan turns green; origin icons get no stand-in | the user owes eleven ids (eight of D-19, three origin icons) |
| Origin icon (D-05) | drawn before use and energy in `SpellCard` and `SpellInfo`; the three icons shrink so the row never overflows | no origin filter in the Journal in this phase |
| Schema gate | SDL with both BE PR #43 and BE Phase 24 | `tool/schema_check/`, 55 documents |

Plans: 23-01 wire boundary + requirements → 23-02 spell model → 23-03 quest types → 23-04 city types → 23-05 asset ids (user) → 23-06 origin drawing (icon ids) → 23-07 schema gate + selections (after the BE Phase 24 merge) → 23-08 device E2E + closing (human).
