---
status: in-progress
phase: 23-spell-origins-void-and-shamanic-quests
device: Android (USB, adb reverse tcp:3000)
be_ref: "feat/24-origini-magie-quest-void-shamanic 3f82fa50 (BE PR #44, draft, not merged yet; stacked on BE PR #43, merged); SDL of 3f82fa50 identical to f3313bd2 read by the gate of 23-14"
date: 2026-11-16
verdict:
---

# Phase 23 — Device E2E (spell origins, void and shamanic quests, research and learning)

App on the Android phone (Samsung SM-S938B) against the local BE booted by the orchestrator from BE branch `feat/24-origini-magie-quest-void-shamanic` at `3f82fa50` (BE PR #44, draft: the UAT runs before its merge, as in Phases 19 and 22 and as ruled by the orchestrator for 23-07 and 23-14). Gate re-checked by plan 23-08 on that ref (read-only `git show`, never `fetch`): `Spell.origin: String!`, `Spell.minLevelToLearn: Int!`, `CityType.aarakocraCapital`, `Pet.known: Boolean!`, `PendingQuest.learningSpell: Spell`, `QuestPrizes.spellDraw: Boolean!`, `QuestResult.spellFound: Spell`, `QuestResult.spellResearchFailed: Boolean!` → `GATE_OK`; the SDL of `3f82fa50` is byte-identical to the BE working tree and has no diff against `f3313bd2` (gate of 23-14). The schema check must be repeated on BE `develop` after the merge of PR #44 (orchestrator's task). Results are recorded only from the tester's words as relayed by the orchestrator, who ran the session one step per message; DB readings and DB writes are the orchestrator's. No ids of real users, no secrets, no Mongo URIs, no identity values in this file (field names and city / quest / spell names only).

## Setup

Setup: BE `develop` with BE PR #43 and Phase 24 merged, booted by the orchestrator (the boot migrates the spells to origin + minimum level and the stored quest type `magic` to `arcane`); Samsung via USB with `adb reverse tcp:3000 tcp:3000` (or `tcp:3000 tcp:3001`); app of `feat/23-spell-origins-void-and-shamanic-quests` (never against a BE without Phase 24 and its research block). The reviewed world content is at DB (origins, levels, new spells, the three rites, the origin lore, the learn times of D-27). Every seed, character move, rank change and time shortening is the orchestrator's job, with DB scripts outside the repo and the BE's own write shapes. The Board and the shop are opened only in a city, never in travel.

**BE actually under test (recorded up front):** BE branch `feat/24-origini-magie-quest-void-shamanic` at `3f82fa50` = BE Phase 24 with its research block (BE plans 24-13..24-18) plus BE D-33 (study-lore draw in the school quests at 15 %, commits `a431033f` / `3f82fa50`, decided during this UAT), on top of BE PR #43 (merged). Not yet merged on BE `develop`.

## Prerequisites owned by the orchestrator

| Prerequisite | Done |
|--------------|------|
| BE Phase 24 (with the research block) booted by the orchestrator with its migration (origin + minimum level on every spell, stored quest type `magic` → `arcane`) | |
| Origins, minimum levels and the new `void` / `shamanic` spells at DB after the user's review (D-02, D-03, D-07) | |
| The three rites: one `void` rite in Necrorian, one `shamanic` rite in Murnborim and one in Thengran (D-11) | |
| The three origin lore entries and `Spell.relatedLore` on every spell (D-24) | |
| City lore of the changed cities (D-23) and city-tier heal quests and shops of the two capitals (D-22) | |
| Character moves (Murnborim / Thengran, Necrorian, Valantar) and rank changes (below mage, at mage) | |
| Shortened rite times | |
| A shop item with an infused spell | |
| A guided mission with a spell among the prize options | |
| Learn times at DB in ms (D-27) and shortened learn times on the spells of the draw | |
| A `study` quest with `prizes.spellDraw` and one without | |
| A character whose draw can give no spell (pool empty for its level) | |
| Push permission granted on the phone | |

## Session data

Field names only, from the BE handoff as copied in `23-07-SUMMARY.md` and `23-14-SUMMARY.md` (BE `BACKEND-NOTES.md` §8 for the research and learning); no ids, no values, no secrets.

- Spells, collection `spells`: `origin` (`void` / `arcane` / `shamanic`), `minLevelToLearn` (integer 1..20), `relatedLore` (list of lore ids), `name`, `description`, `useType`, `energyDamage { type, power }`, `requiredLearnTime` (ms; 0 or absent = immediate), `maxUsages`, `recoveryTime`.
- Characters: `status.unlockedLore`, `status.spellStates`.
- Quests: `infos.type`, `requirements.minTitle` (`mage` for the school quests), `prizes.spellDraw: true`, `prizes.spell`.
- Pending quests: `pendingquests.startDate`, `pendingquests.waitingTime`, `pendingquests.learningSpell`, `pendingquests.researchResult` (DB only, never on the wire).
- Results: `questresults.loreUnlocked`, `questresults.quest.type`, `questresults.spellFound`, `questresults.spellLearned`, `questresults.spellResearchFailed` (two documents for the same `quest.id` when a spell is found and then learned).
- BE log contexts: `SpellOriginsBoot`, `SpellCatalogueReporter`, `QuestResolutionService`, `SpellLearningService`.

## Copy and visuals to review

Provisional choices the user may amend (from the 23-06, 23-09, 23-11 and 23-13 SUMMARYs):

- Spell details: «Origine: Arcana» / «Origine: Sciamanica» / «Origine: Vuoto», with the origin icon before «Uso: …».
- Spell card: three icons (origin, use, energy) shrunk so the row never overflows.
- Learn line: «Per impararla: Livello N» (no learn time, D-28).
- Research part (Map paper, quest overlay, pawn for the school types or a board quest with the draw): `Ricercando…`.
- Learning part, Map paper: `Apprendimento…`.
- Learning line (pawn and overlay): `Imparando «Dardo»: 28 min` · `Imparando «Dardo»: 1 h 30 min` · `Imparando «Dardo»…` (no time left) · `Imparando una magia: 28 min` / `Imparando una magia…` (no readable name).
- `study` quest without a draw: `Studiando…` (unchanged).
- Result sheet, spell found: `Magia scoperta: Dardo` (no readable name: `Magia scoperta`); learning time: `Tempo di apprendimento: 30 min` · `Tempo di apprendimento: 12 h`.
- Result sheet, failed research: `La ricerca non ha rivelato alcuna magia`.
- Learning-end sheet: `Magia appresa: Dardo` + the lore lines (no life bar).
- Banner, spell found: title `Ricerca riuscita`, body `Hai scoperto «Dardo»: l'apprendimento dura 30 min.`; failed research: title `Ricerca conclusa`, body `Nessuna magia scoperta: scopri com'è andata la missione.`; any other result: `Missione conclusa` / `La tua missione è terminata: scopri com'è andata.`

## Steps

| Step | Requirements | Decisions | Expected | Result | Source | Note |
|------|--------------|-----------|----------|--------|--------|------|
| 1 | ORIGIN-04 | D-15, D-16, D-17, D-21 | City markers. On the Map at the widest zoom Murnborim and Thengran are visible with their new drawings at the size of Talmvere; Veg Faldir appears from the village zoom with its drawing; Balkuldir is drawn with the new aarakocra village file; no other city disappeared. | | user | |
| 2 | ORIGIN-01, ORIGIN-02, ORIGIN-05 | D-01, D-05, D-06, D-07, D-08, D-28 | Origin and level in the Journal. A known spell shows three icons — origin first, then use, then energy — without overflowing the card, in the slot and in the list; the long-press details read «Origine: Arcana» (or «Sciamanica» / «Vuoto») with the icon before «Uso: …», and «Per impararla: Livello N» with no learn time; «XP» appears nowhere on a spell. | | user | |
| 3 | ORIGIN-03 | D-09, D-10, D-11, D-13, D-14, D-26 | Shamanic rite. With the character in Murnborim below the rank mage the Board shows «Rito sciamanico» on the shamanic sheet, torn, with «Serve almeno il titolo Mago»; at rank mage the sheet is whole and acceptable without registration; after the accept the Map paper is the shamanic sheet with «Ricercando…» and the pawn reads «Ricercando…»; the result sheet at the end of the research reads the type «Rito sciamanico» and «Magia scoperta: …»; at the end of the learning (shortened by the orchestrator) the sheet reads «Magia appresa: …» and the learned spell is in the Journal with the shamanic icon; the same sheet is on the Board of Thengran. | | user | |
| 4 | ORIGIN-03 | D-09, D-10, D-11, D-12, D-13, D-14 | Void rite. The same in Necrorian for «Rito del Vuoto» on the void sheet: torn below mage, whole at mage, «Ricercando…», the spell learned at the end of the learning carries the void icon; no other city lists a void rite. | | user | |
| 5 | ORIGIN-03 | D-10, D-20 | Arcane quest. In Valantar «Iniziazione arcana a Valantar» still reads «Magia» on the magic sheet after the migration of its type, runs in two parts like the rites and teaches a spell with the arcane icon; an old result of that quest still opens with the type «Magia». | | user | |
| 6 | ORIGIN-06 | D-24 | Origin lore. The sheet at the end of the learning of the FIRST spell learned of an origin (steps 3 and 4) shows the lore-unlock line of that origin and the Library lists the lore without restarting the app; a second spell of the same origin unlocks nothing new. | | user | |
| 7 | ORIGIN-05 | D-05 | Origin on the other cards. The innkeeper's prize catalogue and prize rows (48 px cards) and a shop item with an infused spell («Magia infusa» in the equipment details) show the origin icon first, without overflow. | | user | |
| 8 | — (BE rules, observed) | D-18, D-22, D-23 | Home cities and city tier (BE rules, observed). A new dragonborn is born in Thengran and a new aarakocra in Murnborim; the heal quests and the shop of the two capitals are those of a city; the lore of the three cities reads the new text. | | user | |
| 9 | ORIGIN-07 | D-26 | Research part. A draw quest accepted and started (a school rite, and a `study` quest with the draw) reads «Ricercando…» on the Map paper, above the pawn and in the overlay opened from the paper; a `study` quest without the draw still reads «Studiando…»; no countdown on the paper. | | user | |
| 10 | ORIGIN-07, ORIGIN-08 | D-26, D-29, D-31 | Research succeeded. With the app in the background, at the end of the research the phone shows the push «Ricerca riuscita» with the name of the spell and how long the learning takes; its tap opens the result sheet, which reads the usual numbers, «Magia scoperta: …» and «Tempo di apprendimento: …» (no «Magia appresa»); after «Continua» the pawn reads «Imparando «…»: <tempo>» ticking down, the paper «Apprendimento…», the overlay the same line as the pawn; the xp is already on the character, the spell is NOT in the Journal yet and the Journal still reads «Missione in corso»; closing and reopening the app during the learning shows the same labels with no loader. The same end of research with the app open shows ONE banner «Ricerca riuscita» and the sheet, with no loader. | | user | |
| 11 | ORIGIN-08, ORIGIN-02 | D-26, D-28, D-31 | End of the learning. The push «Missione conclusa» arrives; the small sheet reads the quest, «Magia appresa: …» and, for the first spell of an origin, the lore line — no life bar, no experience, no «Ricompense»; the spell is in the Journal, its details read «Per impararla: Livello N» with no learn time, the lane is free and the pawn has no label. | | user | |
| 12 | ORIGIN-08 | D-29 | Research failed. With a character whose draw can give no spell, at the end of the research the push «Ricerca conclusa» arrives INSTEAD of «Missione conclusa»; its tap opens the sheet, which reads «La ricerca non ha rivelato alcuna magia» with the usual numbers; with the app open one banner only; the lane is free at once. | | user | |

## Requirement ↔ step map

Requirement ↔ step map: ORIGIN-01 (2), ORIGIN-02 (2, 11), ORIGIN-03 (3, 4, 5), ORIGIN-04 (1), ORIGIN-05 (2, 7), ORIGIN-07 (9, 10), ORIGIN-08 (10, 11, 12 and the gate of 23-14), ORIGIN-06 (the gates of 23-07 and 23-14 — schema gate, 55 × OK, full suite — and steps 1–7 and 9–12 all passed). Step 8 is recorded but gates no FE requirement. Not on the device, covered by tests: lenient parsing of origin, level, quest and city types (23-01..23-04), the legacy wire value `magic` (23-03), the learn line edge cases (23-02, 23-09), icon sizes at 48 px (23-06), lenient parsing of the research fields and the learning-end sheet (23-10, 23-13), the countdown on the server clock (23-11), the research pushes as quest ends and an unknown push type dropped (23-13).
