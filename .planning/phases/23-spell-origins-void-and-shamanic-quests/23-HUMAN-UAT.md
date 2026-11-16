---
status: complete
phase: 23-spell-origins-void-and-shamanic-quests
device: Android (USB, adb reverse tcp:3000)
be_ref: "feat/24-origini-magie-quest-void-shamanic 3f82fa50 (BE PR #44, draft, not merged yet; stacked on BE PR #43, merged); SDL of 3f82fa50 identical to f3313bd2 read by the gate of 23-14"
date: 2026-11-16
verdict: "Steps 1-12 passed on the device in their observed parts; step 7 failed on the infused spell card (20 px overflow), fixed in TDD during the UAT and re-checked pass; parts not run on the device by user decision or not observed are listed in «Not run on the device» and are covered by tests"
completed: 2026-11-16
---

# Phase 23 — Device E2E (spell origins, void and shamanic quests, research and learning)

App on the Android phone (Samsung SM-S938B) against the local BE booted by the orchestrator from BE branch `feat/24-origini-magie-quest-void-shamanic` at `3f82fa50` (BE PR #44, draft: the UAT runs before its merge, as in Phases 19 and 22 and as ruled by the orchestrator for 23-07 and 23-14). Gate re-checked by plan 23-08 on that ref (read-only `git show`, never `fetch`): `Spell.origin: String!`, `Spell.minLevelToLearn: Int!`, `CityType.aarakocraCapital`, `Pet.known: Boolean!`, `PendingQuest.learningSpell: Spell`, `QuestPrizes.spellDraw: Boolean!`, `QuestResult.spellFound: Spell`, `QuestResult.spellResearchFailed: Boolean!` → `GATE_OK`; the SDL of `3f82fa50` is byte-identical to the BE working tree and has no diff against `f3313bd2` (gate of 23-14). The schema check must be repeated on BE `develop` after the merge of PR #44 (orchestrator's task). Results are recorded only from the tester's words as relayed by the orchestrator, who ran the session one step per message; DB readings and DB writes are the orchestrator's. No ids of real users, no secrets, no Mongo URIs, no identity values in this file (field names and city / quest / spell names only).

## Setup

Setup: BE `develop` with BE PR #43 and Phase 24 merged, booted by the orchestrator (the boot migrates the spells to origin + minimum level and the stored quest type `magic` to `arcane`); Samsung via USB with `adb reverse tcp:3000 tcp:3000` (or `tcp:3000 tcp:3001`); app of `feat/23-spell-origins-void-and-shamanic-quests` (never against a BE without Phase 24 and its research block). The reviewed world content is at DB (origins, levels, new spells, the three rites, the origin lore, the learn times of D-27). Every seed, character move, rank change and time shortening is the orchestrator's job, with DB scripts outside the repo and the BE's own write shapes. The Board and the shop are opened only in a city, never in travel.

**BE actually under test (recorded up front):** BE branch `feat/24-origini-magie-quest-void-shamanic` at `3f82fa50` = BE Phase 24 with its research block (BE plans 24-13..24-18) plus BE D-33 (study-lore draw in the school quests at 15 %, commits `a431033f` / `3f82fa50`, decided during this UAT), on top of BE PR #43 (merged). Not yet merged on BE `develop`.

## Prerequisites owned by the orchestrator

| Prerequisite | Done |
|--------------|------|
| BE Phase 24 (with the research block) booted by the orchestrator with its migration (origin + minimum level on every spell, stored quest type `magic` → `arcane`) || done — booted from `feat/24-origini-magie-quest-void-shamanic` (`3f82fa50` at the end of the session) |
| Origins, minimum levels and the new `void` / `shamanic` spells at DB after the user's review (D-02, D-03, D-07) || done (orchestrator) |
| The three rites: one `void` rite in Necrorian, one `shamanic` rite in Murnborim and one in Thengran (D-11) || done (orchestrator) |
| The three origin lore entries and `Spell.relatedLore` on every spell (D-24) || done (orchestrator) |
| City lore of the changed cities (D-23) and city-tier heal quests and shops of the two capitals (D-22) || done (orchestrator); lore images realigned and Thengran / Balkuldir swapped during step 1 |
| Character moves (Murnborim / Thengran, Necrorian, Valantar) and rank changes (below mage, at mage) || done (orchestrator) |
| Shortened rite times || done — research duration of the four school quests set to 4 h at DB (decision of the UAT) |
| A shop item with an infused spell || done (orchestrator) |
| A guided mission with a spell among the prize options || not done — no story / worldMission request available; step 7 innkeeper part not run by user decision |
| Learn times at DB in ms (D-27) and shortened learn times on the spells of the draw || done — 30 min (L6) → 12 h (L20) at DB (decision of the UAT) |
| A `study` quest with `prizes.spellDraw` and one without || not exercised on the device (step 9 `study` cases not observed) |
| A character whose draw can give no spell (pool empty for its level) || done (step 12) |
| Push permission granted on the phone || done |

## Session data

Field names only, from the BE handoff as copied in `23-07-SUMMARY.md` and `23-14-SUMMARY.md` (BE `BACKEND-NOTES.md` §8 for the research and learning); no ids, no values, no secrets.

- Spells, collection `spells`: `origin` (`void` / `arcane` / `shamanic`), `minLevelToLearn` (integer 1..20), `relatedLore` (list of lore ids), `name`, `description`, `useType`, `energyDamage { type, power }`, `requiredLearnTime` (ms; 0 or absent = immediate), `maxUsages`, `recoveryTime`.
- Characters: `status.unlockedLore`, `status.spellStates`.
- Quests: `infos.type`, `requirements.minTitle` (`mage` for the school quests), `prizes.spellDraw: true`, `prizes.spell`.
- Pending quests: `pendingquests.startDate`, `pendingquests.waitingTime`, `pendingquests.learningSpell`, `pendingquests.researchResult` (DB only, never on the wire).
- Results: `questresults.loreUnlocked`, `questresults.quest.type`, `questresults.spellFound`, `questresults.spellLearned`, `questresults.spellResearchFailed` (two documents for the same `quest.id` when a spell is found and then learned).
- BE log contexts: `SpellOriginsBoot`, `SpellCatalogueReporter`, `QuestResolutionService`, `SpellLearningService`.

## Copy and visuals to review

Outcome: no copy amended by the user; one visual amended and fixed during the UAT (capital markers 39 → 46, `a1df181d`); one visual bug fixed (infused spell card overflow, `776a8303`). No open copy gap. Layout rework deferred by the user to a later dedicated phase.

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
| 1 | ORIGIN-04 | D-15, D-16, D-17, D-21 | City markers. On the Map at the widest zoom Murnborim and Thengran are visible with their new drawings at the size of Talmvere; Veg Faldir appears from the village zoom with its drawing; Balkuldir is drawn with the new aarakocra village file; no other city disappeared. | pass | user (relayed by the orchestrator) | City markers as expected. During the step the user asked for three changes: (a) the lore images of the changed cities (Thengran, Murnborim, Veg Faldir, Balkuldir) realigned at DB; (b) the two new capitals a little larger than Talmvere: `CityType.aarakocraCapital` / `dragonbornCapital` marker 39 → 46 (`a1df181d`, test first; amends D-16); (c) Thengran and Balkuldir swapped position at DB (areas, city POI coordinates, surrounding POIs reassigned, four quest texts renamed). DB work by the orchestrator. |
| 2 | ORIGIN-01, ORIGIN-02, ORIGIN-05 | D-01, D-05, D-06, D-07, D-08, D-28 | Origin and level in the Journal. A known spell shows three icons — origin first, then use, then energy — without overflowing the card, in the slot and in the list; the long-press details read «Origine: Arcana» (or «Sciamanica» / «Vuoto») with the icon before «Uso: …», and «Per impararla: Livello N» with no learn time; «XP» appears nowhere on a spell. | pass | user (relayed by the orchestrator) | Origin icon first, «Origine: …», «Per impararla: Livello N», no «XP». |
| 3 | ORIGIN-03 | D-09, D-10, D-11, D-13, D-14, D-26 | Shamanic rite. With the character in Murnborim below the rank mage the Board shows «Rito sciamanico» on the shamanic sheet, torn, with «Serve almeno il titolo Mago»; at rank mage the sheet is whole and acceptable without registration; after the accept the Map paper is the shamanic sheet with «Ricercando…» and the pawn reads «Ricercando…»; the result sheet at the end of the research reads the type «Rito sciamanico» and «Magia scoperta: …»; at the end of the learning (shortened by the orchestrator) the sheet reads «Magia appresa: …» and the learned spell is in the Journal with the shamanic icon; the same sheet is on the Board of Thengran. | pass | user (relayed by the orchestrator) | Run in Thengran: two failed researches, then a spell found, the learning part and the second sheet. |
| 4 | ORIGIN-03 | D-09, D-10, D-11, D-12, D-13, D-14 | Void rite. The same in Necrorian for «Rito del Vuoto» on the void sheet: torn below mage, whole at mage, «Ricercando…», the spell learned at the end of the learning carries the void icon; no other city lists a void rite. | pass | user (relayed by the orchestrator) | Necrorian, «Memorie di un mago»; the BE was restarted during the learning part and the missions sweep closed the expired learning at boot. |
| 5 | ORIGIN-03 | D-10, D-20 | Arcane quest. In Valantar «Iniziazione arcana a Valantar» still reads «Magia» on the magic sheet after the migration of its type, runs in two parts like the rites and teaches a spell with the arcane icon; an old result of that quest still opens with the type «Magia». | pass | user (relayed by the orchestrator) | Arcane quest at Valantar after the rename. |
| 6 | ORIGIN-06 | D-24 | Origin lore. The sheet at the end of the learning of the FIRST spell learned of an origin (steps 3 and 4) shows the lore-unlock line of that origin and the Library lists the lore without restarting the app; a second spell of the same origin unlocks nothing new. | pass | user (relayed by the orchestrator) | The first void spell unlocked «Il Vuoto e l'Abisso dei Diavoli» on the learning-end sheet. |
| 7 | ORIGIN-05 | D-05 | Origin on the other cards. The innkeeper's prize catalogue and prize rows (48 px cards) and a shop item with an infused spell («Magia infusa» in the equipment details) show the origin icon first, without overflow. | pass after fix (shop part); innkeeper part not run on the device | user (relayed by the orchestrator) | Equipment «Magia infusa»: FAIL first — the infused spell card was drawn 20 px wider than its room — fixed in TDD during the UAT (`4bcd0d9c` test, `776a8303` fix), re-checked pass. Innkeeper prize cards: NOT RUN on the device by user decision (no story / worldMission request available), covered by the 48 px no-overflow widget test in `test/shared/components/cards/spell_card_test.dart`. User note: the UI layouts will be reworked in a dedicated later phase. |
| 8 | — (BE rules, observed) | D-18, D-22, D-23 | Home cities and city tier (BE rules, observed). A new dragonborn is born in Thengran and a new aarakocra in Murnborim; the heal quests and the shop of the two capitals are those of a city; the lore of the three cities reads the new text. | pass (heal, shop, city lore); birth cities not run on the device | user (relayed by the orchestrator) | Heal quests, shop and city lore of the capitals: pass. Birth cities of dragonborn / aarakocra: NOT RUN on the device by user decision, covered by the BE integration specs `character-creation.resolver.int-spec.ts` and `starting-location.service.int-spec.ts`. Gates no FE requirement. |
| 9 | ORIGIN-07 | D-26 | Research part. A draw quest accepted and started (a school rite, and a `study` quest with the draw) reads «Ricercando…» on the Map paper, above the pawn and in the overlay opened from the paper; a `study` quest without the draw still reads «Studiando…»; no countdown on the paper. | pass (school rites); `study` cases not observed | user (relayed by the orchestrator) | «Ricercando…» on the pawn and in the overlay for the three school rites (D-32). A `study` quest WITH the draw and «Studiando…» for a study without it: NOT OBSERVED on the device, covered by the unit / widget tests of 23-11 and 23-12. |
| 10 | ORIGIN-07, ORIGIN-08 | D-26, D-29, D-31 | Research succeeded. With the app in the background, at the end of the research the phone shows the push «Ricerca riuscita» with the name of the spell and how long the learning takes; its tap opens the result sheet, which reads the usual numbers, «Magia scoperta: …» and «Tempo di apprendimento: …» (no «Magia appresa»); after «Continua» the pawn reads «Imparando «…»: <tempo>» ticking down, the paper «Apprendimento…», the overlay the same line as the pawn; the xp is already on the character, the spell is NOT in the Journal yet and the Journal still reads «Missione in corso»; closing and reopening the app during the learning shows the same labels with no loader. The same end of research with the app open shows ONE banner «Ricerca riuscita» and the sheet, with no loader. | pass with the app open; background push not observed | user (relayed by the orchestrator) | Sheet with «Magia scoperta» + «Tempo di apprendimento», then «Imparando «…»: …» ticking: pass with the app open. No banner on the Map because the sheet opens directly: accepted by the user as correct. The push «Ricerca riuscita» with the app in background: NOT OBSERVED (covered by the push tests of 23-13). |
| 11 | ORIGIN-08, ORIGIN-02 | D-26, D-28, D-31 | End of the learning. The push «Missione conclusa» arrives; the small sheet reads the quest, «Magia appresa: …» and, for the first spell of an origin, the lore line — no life bar, no experience, no «Ricompense»; the spell is in the Journal, its details read «Per impararla: Livello N» with no learn time, the lane is free and the pawn has no label. | pass; background push not observed | user (relayed by the orchestrator) | Small sheet, spell in the Journal, lane free. The push «Missione conclusa» with the app in background: NOT OBSERVED (covered by the push tests of 23-13). |
| 12 | ORIGIN-08 | D-29 | Research failed. With a character whose draw can give no spell, at the end of the research the push «Ricerca conclusa» arrives INSTEAD of «Missione conclusa»; its tap opens the sheet, which reads «La ricerca non ha rivelato alcuna magia» with the usual numbers; with the app open one banner only; the lane is free at once. | pass | user (relayed by the orchestrator) | Including the push «Ricerca conclusa» with the app in background, received INSTEAD of the quest-end push. |

## Not run on the device (honest list, covered by tests)

| Step | Part | Why | Covered by |
|------|------|-----|------------|
| 7 | Innkeeper prize catalogue and prize rows (48 px cards) | user decision: no story / worldMission request available | 48 px no-overflow widget test, `test/shared/components/cards/spell_card_test.dart` |
| 8 | Birth cities of a new dragonborn / aarakocra | user decision | BE integration specs `character-creation.resolver.int-spec.ts`, `starting-location.service.int-spec.ts` |
| 9 | A `study` quest with the draw («Ricercando…») and a `study` without it («Studiando…») | not observed | unit / widget tests of 23-11 (`quest_state_label_test`, `mission_lines_test`) and 23-12 (`character_marker_layer_test`) |
| 10 | The push «Ricerca riuscita» with the app in background | not observed | 23-13 (`notification_category_test`, `push_event_test`, `data_message_handler_test`) |
| 11 | The push «Missione conclusa» with the app in background after the learning | not observed | 23-13 push tests (questEnd path unchanged) |

## Changes made during the UAT

- FE `a1df181d` `feat(map): draw the two new capitals a little larger than Talmvere` — `aarakocraCapital` / `dragonbornCapital` marker 39 → 46 (test first; amends D-16).
- FE `4bcd0d9c` `test(shared): expect the infused spell card to keep its icons on the card` + `776a8303` `fix(shared): size the infused spell card to the room it has` — the infused spell card of the equipment details was 20 px wider than its room (step 7).
- BE `a431033f` / `3f82fa50` — BE D-33: study-lore draw in the school quests at 15 % (study quests keep the configured chance).
- DB (orchestrator, scripts outside the repo): lore images of Thengran, Murnborim, Veg Faldir, Balkuldir realigned; Thengran and Balkuldir swapped (areas, city POI coordinates, surrounding POIs reassigned, four quest texts renamed); research duration of the four school quests 20 h → 4 h; learn times 30 min (L6) → 12 h (L20); recovery times 15 min (L6) → 8 h (L20).

## Decisions taken during the UAT (user)

- Research duration of the four school quests 4 h at DB (was 20 h); learn times 30 min (L6) → 12 h (L20); recovery times 15 min (L6) → 8 h (L20). DB content, no code.
- BE D-33: study-lore draw in the school quests at 15 %.
- The two new capitals drawn at 46 instead of 39 (amends D-16).
- No Journal line for the spell being learned (user: fine as is).
- No banner on the Map at the end of a research with the app open, because the result sheet opens directly: accepted as correct.
- Research pushes follow the «Fine quest» toggle (the user did not object).
- UI layouts (spell cards included) will be reworked in a dedicated later phase.

## Requirement ↔ step map

Requirement ↔ step map: ORIGIN-01 (2), ORIGIN-02 (2, 11), ORIGIN-03 (3, 4, 5), ORIGIN-04 (1), ORIGIN-05 (2, 7), ORIGIN-07 (9, 10), ORIGIN-08 (10, 11, 12 and the gate of 23-14), ORIGIN-06 (the gates of 23-07 and 23-14 — schema gate, 55 × OK, full suite — and steps 1–7 and 9–12 all passed). Step 8 is recorded but gates no FE requirement. Not on the device, covered by tests: lenient parsing of origin, level, quest and city types (23-01..23-04), the legacy wire value `magic` (23-03), the learn line edge cases (23-02, 23-09), icon sizes at 48 px (23-06), lenient parsing of the research fields and the learning-end sheet (23-10, 23-13), the countdown on the server clock (23-11), the research pushes as quest ends and an unknown push type dropped (23-13).
