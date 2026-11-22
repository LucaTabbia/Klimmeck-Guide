---
status: complete
phase: 24-participants-stories-and-innkeeper-wounds
device: Android (Samsung SM-S938B, USB, adb reverse tcp:3000 tcp:3001 — BE on port 3001)
be_ref: "BE develop a5b140a6 (merge of BE PR #50 «fix(quests): let a story quest live without a place», quick task 261122-snp, on top of the Phase 25 merge 95582457, BE PR #49)"
fe_ref: "feat/24-participants-stories-and-innkeeper-wounds 639a24b8 at the end of the session (48d2c43a, code at ba2bfa21, when the script was written)"
gate: "GATE_OK — re-checked by plan 24-11 Task 1 on 95582457 and again by Task 3 on a5b140a6 (origin/develop), 2026-11-22"
date: 2026-11-22
verdict: "Steps 1-10 and the two extra steps 0 and 11 passed in the user's words; steps 1 and 9 passed after a change asked by the user and made in TDD during the session; the worldMission halves of steps 2 and 6 were judged on an improvised worldMission (step 11); two points were not run on the device and are covered by tests (see «Not run on the device»)"
completed: 2026-11-22
---

# Phase 24 — Device E2E (participants' stories and innkeeper wounds)

App of `feat/24-participants-stories-and-innkeeper-wounds` on the Android phone against the local BE booted by the orchestrator from BE `develop` at `95582457` (BE Phase 25 merged). Gate re-checked by plan 24-11 on `origin/develop` of the BE repo (read-only `git show`, never `fetch`): `CharacterStatus.innkeeperInjuries: [InjuryType!]!`, `QuestResult.backgroundEntryAdded: Boolean!`, `QuestResult.injuriesRemoved: [InjuryType!]!`, `MissionDraftStep.stories`, `ParticipantOverrideInput.injuriesRemoved: [InjuryType!]`, `MissionFightOutcome.innkeeperInjuriesBefore: [InjuryType!]!` → `GATE_OK`. Results are recorded only from the tester's words as relayed by the orchestrator, who runs the session one step per message; DB readings and DB writes are the orchestrator's. No ids of real users or characters, no secrets, no URIs, no identity values in this file (field names and city / quest / wound names only); the stories typed during the session are not transcribed.

## Setup

Setup: BE with Phase 25 booted by the orchestrator; Samsung via USB with `adb reverse tcp:3000 tcp:3000` (or `tcp:3000 tcp:3001`); app of `feat/24-participants-stories-and-innkeeper-wounds`. An innkeeper identity and a participant identity (two devices, or one device switching identity as in the Phase 21 UAT). In the queue: one `story` request of a character with at least two background entries and two ordinary wounds, one `worldMission` request with two participants (one of them with an empty background). Every seed, character move and wound write is the orchestrator's job, with DB scripts outside the repo and the BE's own write shapes. The Board and the shop are opened only in a city, never in travel.

**As run (2026-11-22):** one phone (Samsung SM-S938B); the identity was switched by restarting the local BE with the dev identity of the innkeeper's user or of the participant's user and hot-restarting the app. The BE under test was BE `develop` at `a5b140a6`: BE PR #50 (one SDL line, `QuestInfos.markerLocation: PointOfInterest` now nullable; only story quests may have no place) on top of the Phase 25 merge `95582457`, on which the gate of 24-10 ran. The app already parsed that field as nullable (FE tests and one map fix added: `5a0c5891`, `fb02b89c`, `525f318e`). Characters: a test participant (rookie at the start, two ordinary wounds) and the innkeeper's character. No worldMission content exists in the DB: the two-participant part ran on an improvised `[UAT]` worldMission (step 11), removed afterwards.

**This session:** the BE runs on port 3001, so the reverse is `adb reverse tcp:3000 tcp:3001`. The app selects `innkeeperInjuries`, `backgroundAdditions`, `injuriesRemoved` and `backgroundEntryAdded`: never against a BE without Phase 25.

Device notes: `adb reverse` is lost at every USB reconnection; port 3000 busy → `PORT=3001` + `adb reverse tcp:3000 tcp:3001`; screen off → `adb shell svc power stayon usb`. These commands are run by the user or the orchestrator, never by the executor.

## Prerequisites owned by the orchestrator

| Prerequisite | Done |
|--------------|------|
| BE `develop` with Phase 25 booted (no migrator: every new field has a neutral value) | done — `a5b140a6` (Phase 25 + BE PR #50) |
| `adb reverse tcp:3000 tcp:3001` and the app of the FE branch on the phone | done |
| An innkeeper identity and a participant identity | done — one phone, identity switched by a BE restart and a hot restart of the app |
| One `story` request in the queue: a character with at least two background entries and two ordinary wounds | done — the rookie rank story accepted by the participant at step 0; two `[UAT]` background entries and two ordinary wounds seeded |
| One `worldMission` request in the queue with two participants, one of them with an empty background | done at step 11 — improvised `[UAT]` worldMission (no worldMission content exists), the participant's background emptied for it |
| Open guided drafts checked at the boot (a draft simulated before Phase 25 serves empty lists on the new fields until the fight is simulated again) | done |
| The participant's device has already opened the Profile once (step 7) | done |
| An ordinary wound seeded on the participant (step 8) | done |
| A city with a heal quest whose cure lists an innkeeper wound and the ordinary one; a heal quest that would cure only innkeeper wounds, life full; a potion whose `canHeal` lists the innkeeper wound (step 9) | done — one potion seeded; the wait of the heal shortened at DB |
| A later mission of the same character, and a torn heal quest on the Board of the city where the character is (step 10) | done — the later mission was the adventurer rank story; the origin flip of 10a was written at DB with the Board open |

## Session data

Field names only, from the BE handoff as copied in `24-10-SUMMARY.md`; no ids, no values, no secrets.

- Characters: `characters.status.injuries`, `characters.status.innkeeperInjuries`, `characters.infos.background` (oldest entry first).
- Drafts: `missiondrafts.backgroundAdditions`, `missiondrafts.fights.outcomes` (`innkeeperInjuriesBefore`, `corrected.injuriesRemoved`; `corrected.innkeeperInjuries` is derived, not stored).
- Results: `questresults` (`injuriesRemoved`, `backgroundEntryAdded`).
- **Trap for the DB scripts:** `innkeeperInjuries` is served raw (no resolver). A script that removes a wound from `status.injuries` must remove it from `status.innkeeperInjuries` in the same update; to seed an innkeeper wound, `$set` both lists together.
- The pending `story` / `worldMission` requests have the shape they had before Phase 25 (the BE handoff adds nothing to it): they are created by registering through the app or with the orchestrator's scripts of the earlier UATs. No field name is written here for them.

## Facts to keep in mind while reading the steps

BE facts decided after the plan was written (BE handoff, answers Q1 and Q4):

- **Additions merged per character.** A saved section replaces only the addition of each listed character; an omitted participant keeps theirs; a text empty after trim clears that character's saved addition; an absent section leaves everything as it is. The app sends one entry per participant, the empty ones included, so emptying a field in step 5 or 6 clears that row at DB.
- **D-19: a wound already carried and proposed again is ignored by the BE** — not added, not refused, no change of origin, at the save and at the completion. Step 3 («a wound carried and not removed cannot be added») describes the app's chips and stays as written; remove-and-re-add in the same correction is the way to make a wound an innkeeper wound (D-16).

Notes from plans 24-07..24-10:

- The draft is born with the rank prize, cure included: check or remove the cure in the wound steps (3, 7, 10), otherwise it heals the ordinary wounds and confuses the reading.
- A wound added by hand stays unmarked on its chip until the BE serves it back in the effect; the mark «(dell'oste)» is expected after the save (step 3: after «Avanti» and «Indietro»).
- A correction that changes only the removals resets the following fights.
- A remove-and-re-add leaves no trace on the result sheet (neither added nor removed): only the origin changes, visible in the Journal (step 8).
- A draft simulated before the BE restart shows no «(dell'oste)» mark until the fight is simulated again.
- The wax sigil identifies a background entry by its text: use a text never used before (step 7).
- The confirmation of «Concludi» keeps the confirm label «Completa» (one shared dialog, no new copy).

## Copy to confirm with the user

Provisional copy (REPO-RULES «Copy»), confirmed or changed by the user during the session; a change is fixed in TDD in its own commit and recorded below.

- «La tua storia ha una nuova pagina» (result sheet)
- «Di questo avventuriero non si sa ancora nulla» (empty background)
- «Storie» (first page) and «Aggiunte alle storie» (last page)
- «Una ferita aggiunta a mano è dell'oste: nessuna cura la toglie» (note under the chips)
- «(dell'oste)» (mark on the chips)

Also as built, shown to the user as they are: «Ferite presenti», «Ferite da aggiungere», «Ferite tolte: …», «Troppo grave per essere curata», «Storia di <nome>: una nuova pagina», «Massimo 1000 caratteri», «Un'aggiunta supera i 1000 caratteri».

## Steps

| N | step | requirement | result | user's words |
|---|------|-------------|--------|--------------|
| 0 | (extra, not in the script) Rank story on the Board. As the participant, the Board shows only the story of the character's rank (rookie) with its description and cost; it is accepted from the city with no travel. Born in the session: the four permanent rank `story` quests have no place (BE PR #50). | STORY-04 (content) | pass | «pass su tutto». DB: story lane taken, no travel, no draft. |
| 1 | Reading page. The innkeeper opens the story request from the Locanda: the wizard opens on «Passo 1 di 7 · Storie» with one closed dropdown «<nome> · <rango>»; a tap opens it and shows the background entries, oldest first; the start note and «Inizia la missione» are at the bottom; no popup anywhere. While the page is open the participant is still free (can open the Board, is not «Missione in corso») (STORY-01; D-01, D-02, D-02a, D-03). | STORY-01 | pass after fix | First a layout change: «L'avviso "Da ora i..." mettilo accanto al pulsante, così c'è più spazio per leggere» — fixed in TDD (`bb6968be`, `618a3093`: the note beside «Inizia la missione», «Riprova» beside the failure line at the top). Then: «Tutto perfetto, pass». DB: no draft while the page is open. |
| 2 | Start and way back. «Inizia la missione» lands on «Passo 2 di 7 · Luogo» and the participant is now locked; «Indietro» shows the stories again with «Avanti», which returns to «Luogo»; in the worldMission request the participant with no background reads «Di questo avventuriero non si sa ancora nulla» (STORY-01; D-02, D-03). | STORY-01 | pass | Story part: «pass». DB: the draft is created only by «Inizia la missione», the participant is locked. The line «Di questo avventuriero non si sa ancora nulla» was judged on the improvised worldMission at step 11b: «pass su tutto». |
| 3 | Removing and re-adding wounds. In a simulated fight the participant's section shows «Ferite presenti» with the two wounds carried; a tap removes one (ordinary → gone); the other is removed and then tapped again under «Ferite da aggiungere» (ordinary → innkeeper wound); a third wound is added by hand; the note under the chips reads «Una ferita aggiunta a mano è dell'oste: nessuna cura la toglie»; a wound carried and not removed cannot be added; after «Avanti» and «Indietro» the fight reopens with the same choices and the hand-added wounds marked «(dell'oste)» (WOUND-01; D-12, D-13, D-16). | WOUND-01 | pass (the third hand-added wound not run) | «Ho rimosso tutte le ferite, aggiungendo come ferita dell'oste solo assideramento»; the note under the chips and the mark «(dell'oste)» after «Avanti» / «Indietro»: «pass su tutto». Both carried wounds removed, one re-added; no third wound added by hand in this run (covered by the tests of 24-07). DB draft: `corrected.injuriesRemoved` [deepCut, hypothermia], `corrected.injuriesAdded` [hypothermia]. |
| 4 | Recap and last page. The recap lists «Ferite tolte: …» and shows «Avanti» (no «Completa»); the last page «Passo 7 di 7 · Aggiunte alle storie» shows per participant the story dropdown and one field with the counter «0/1000»; a text over 1000 characters shows «Massimo 1000 caratteri» and disables «Concludi»; the keyboard in landscape leaves the field visible (STORY-02; D-04, D-05, D-07, D-08). | STORY-02 | pass (the over-1000 paste not run) | «pass su tutto». The paste of a text over 1000 characters was optional and was not confirmed separately (covered by the tests of 24-05). |
| 5 | Leaving and coming back. With a text typed, leave the wizard (back) and reopen the request from the Locanda: the wizard reopens on the last page with the text; «Indietro» to the recap and «Avanti» again keeps it (STORY-02; D-05). | STORY-02 | pass | «pass» |
| 6 | «Concludi». The confirmation lists the recap lines and «Storia di <nome>: una nuova pagina»; after the confirmation the results recap shows and the request leaves the queue. In the worldMission: one participant gets an addition, the other field is left empty (STORY-02; D-05, D-06). | STORY-02 | pass | Story part: «C'è scritto completa. Pass» — the confirm button inside the «Concludi» dialog reads «Completa», accepted as it is. DB: rank rookie → adventurer, the story quest stays open for the others, deepCut removed, hypothermia now an innkeeper wound, background 2 → 3 entries; result `injuriesRemoved` [deepCut], `backgroundEntryAdded` true, the remove-and-re-add leaves no trace on the sheet; no draft, no pending request. WorldMission part (one addition, the other field empty) at step 11c on the improvised worldMission: «pass». |
| 7 | Participant's result sheet and sigil. The participant's result sheet reads «La tua storia ha una nuova pagina» and ONE line «Guarite: …» with the wound the innkeeper took off; the participant of the worldMission with the empty field reads no story line; the Profile entry of the menu carries the wax sigil, and in the Profile the new entry (last of the background) carries the sigil, the older ones do not; reopening the Profile clears it (STORY-03, WOUND-03; D-08, D-09, D-18). Use a text never used before, on a device that has already opened the Profile once. | STORY-03, WOUND-03 | pass | Three retouches asked during the step and made in TDD: «Dividi ogni voce della storia con un piccolo separatore (linea) centrale e che non raggiunge i bordi del foglio» (`90ca2749`, `0c8ad5b2`); «Metti anche il sigillo sul lato destro, piuttosto che sul sinistro, così il testo resta allineato» (`c0811a6c`, `e72cb247`); «Poi metti la medaglia del rango sopra l'immagine del personaggio, nell'angolo in alto a destra» (`9fcde1ca`, `a7cc8517`). Then: «pass su tutto» (result sheet lines, sigil on the menu entry and on the new entry, medal size and position; copy «La tua storia ha una nuova pagina» confirmed). The participant with the empty field: DB `backgroundEntryAdded` false at step 11c (and no story line on the sheet at step 10c). |
| 8 | Journal. In the participant's Journal «Ferite» the two innkeeper wounds read «Troppo grave per essere curata» under their name; an ordinary wound (seeded by the orchestrator) reads no such line; the removed wound is gone (WOUND-02; D-15). | WOUND-02 | pass | «pass» (an ordinary wound seeded beside the innkeeper wound). |
| 9 | Heal quests and potions. In a city with a heal quest whose cure lists both an innkeeper wound and the ordinary one: the sheet reads «Cura le tue ferite: …» with the ordinary wound only; a heal quest that would cure only the innkeeper wounds (life full) is drawn torn and not acceptable; in the Journal «Oggetti» a potion whose `canHeal` lists the innkeeper wound shows «Cura: …» without it, and so does the potion sheet; drinking a potion whose only useful effect would be that wound shows the «nessun effetto» notice and consumes nothing; after a heal of the ordinary wound the result reads «Guarite: …» with that wound only and the innkeeper wounds stay. The shop line of the same potion is looked at by the user as it is (WOUND-02; D-11, D-14, D-15; ruling 4). | WOUND-02 | pass after fix (potion lines changed by D-20 / D-21) | 9a potions: behaviour passed («Tutto ha funzionato comunque»), but the user reversed the display filter of the script: «Le ferite devono comparire tutte nella lista di ferite curate. C'è già il segnalino che indica che una ferita non può essere curata, non diamo mezze informazioni agli utenti.» → D-20 (`703bcb82`, `586be663`). Later: «Facciamo che ferite che una pozione non può curare perché sono date dall'oste sono scritte in rosso» → D-21 (`d6353fcd`, `adb02382`), seen on the device at step 11a: «pass». The shop line stays unfiltered and uncoloured. 9b heal quest sheet: the personal line «Cura le tue ferite: …» with the ordinary wound only: «Qua è corretto» (the quest line stays filtered); heal accepted, result `injuriesHealed` [brokenRightLeg], the innkeeper wound stays. 9c result sheet «Guarite», wound still in the Journal, heal quest torn at full life with only the innkeeper wound: «pass». |
| 10 | The innkeeper takes his wound off. In a later mission of the same character the fight section shows the innkeeper wounds under «Ferite presenti» marked «(dell'oste)»; removing one and concluding makes it disappear from the Journal and appear under «Guarite: …» on the result sheet; the Board, open in a city during the completion, turns a torn heal quest whole again without restarting the app when the origin flip makes it useful (WOUND-01, WOUND-02, WOUND-03; D-13, D-18, Pitfall 4). | WOUND-01, WOUND-02, WOUND-03 | pass | 10a Board reread (Pitfall 4): with the Board open the origin of the wound was flipped at DB (innkeeper → ordinary) and the heal quest turned whole by itself: «confirmo»; flipped back, torn again: «pass su tutto». 10b: the participant (now adventurer) saw only the adventurer story and accepted it; the innkeeper removed the «(dell'oste)» wound inside the mission, the addition field left empty: «pass». DB: no wounds left, rank adventurer → paladin, background unchanged, result `injuriesRemoved` [hypothermia], `backgroundEntryAdded` false. 10c: result sheet «Guarite: …» with the removed innkeeper wound and no story line, Journal without the wound, paladin medal: «pass». During 10c: «Quando la sezione ferite è vuota non mostriamo la sezione. Rendi anche quella una dropdown» → D-22 (`ef74a3e7`, `b6e29d00`, `b0483a95`), «pass su tutto» at step 11b. |
| 11 | (extra, not in the script) Two participants on an improvised `[UAT]` worldMission; covers the worldMission halves of steps 2 and 6. 11a accepted as the participant; 11b accepted as the innkeeper's character, «Storie» with two dropdowns, one participant with no background; 11c recap, additions and «Concludi» with an addition for one participant only. | STORY-01, STORY-02, STORY-03 | pass (11c after D-23) | 11a: «pass e accettata». 11b: «pass su tutto» (the participant with no background reads «Di questo avventuriero non si sa ancora nulla»). 11c: «Dentro la pagina di riepilogo puoi separare i risultati per personaggio e mettere le solite tendine? Metti anche il campo di testo per la nuova aggiunta dentro alla tendina» → D-23 (`fc7eae17`, `465dd928`, `97d65962`, `6aa7695b`), with the header summary «aggiunta N/1000» proposed by the orchestrator: «Mi va bene la tua aggiunta, è una buona idea». Then the mission concluded with an addition for one participant only: «pass». DB: `backgroundEntryAdded` true for that participant only, false for the other; quest concluded; no draft, no pending request. |

Result values: `pass`, `fail`, `pass after fix`, `not run`. The user's words are written as relayed by the orchestrator. Steps 0 and 11 are extra steps of the session, not part of the ten of the plan. The story texts typed during the session are not transcribed.

## Not run on the device

| Part | Why | Covered by |
|------|-----|------------|
| Step 4: the paste of a text over 1000 characters («Massimo 1000 caratteri», «Concludi» disabled) | optional in the session, not confirmed separately by the user | tests of plan 24-05 (grapheme count, the line and the disabled button) |
| Step 3: the third wound added by hand | the user removed both carried wounds and re-added one; no third wound in this run | tests of plan 24-07 (hand-added wound, mark served back) |

Run differently from the script, recorded as run:

- The worldMission halves of steps 2 and 6 were judged on an improvised `[UAT]` worldMission (step 11), because no worldMission content exists in the DB; it was removed afterwards.
- Step 8 was judged with one innkeeper wound (not two) beside one ordinary wound.
- Step 10: the Board reread was proved by flipping the origin at DB with the Board open (10a), not during the completion; the removal of the innkeeper wound and its result were judged in 10b / 10c.
- Step 9: the potion lines no longer leave the innkeeper wound out (D-20, D-21); the script row keeps its original text.

Not on the device by design, covered by tests (plan): lenient parsing of every new field (24-01, 24-02), the grapheme count (24-05), the save refused on leave (24-06), the switch-off behaviour (24-06, 24-07), the «not selected before the gate» pins flipped (24-10).

## Changes made during the UAT

FE commits (each change test-first, in its own commits):

| Change | Asked at | Commits |
|--------|----------|---------|
| A story quest served without a place: parsing pinned, no quest marker for a place without a location (BE PR #50) | with BE PR #50 | `5a0c5891`, `fb02b89c`, `525f318e` |
| Start note beside «Inizia la missione»; «Riprova» beside the failure line at the top | step 1 | `bb6968be`, `618a3093` |
| A short centred line between the background entries | step 7 | `90ca2749`, `0c8ad5b2` |
| The sigil of a new background entry on the right | step 7 | `c0811a6c`, `e72cb247` |
| The rank medal on the top right corner of the portrait | step 7 | `9fcde1ca`, `a7cc8517` |
| D-20: a heal item lists every wound it cures, innkeeper wounds included | step 9a | `703bcb82`, `586be663` (record `1354f2b2`) |
| D-21: the reader's innkeeper wounds in red in the line «Cura: …» | step 9a | `d6353fcd`, `adb02382` (record `e96618a2`) |
| D-22: «Ferite» as a dropdown, hidden without wounds | step 10c | `ef74a3e7`, `b6e29d00`, `b0483a95` (record `c2f7e31e`) |
| D-23: recap and additions in one dropdown per participant, header summary «aggiunta N/1000» | step 11c | `fc7eae17`, `465dd928`, `97d65962`, `6aa7695b` (record `639a24b8`) |

BE: PR #50 «fix(quests): let a story quest live without a place» (quick task 261122-snp), merged on BE `develop` as `a5b140a6`: one SDL line, `QuestInfos.markerLocation` nullable; only story quests may have no place.

DB content written by the orchestrator: four permanent rank `story` quests (see the decisions below), which stay. Every seed of the session (two `[UAT]` background entries, channel points, wounds, one potion, the move to the innkeeper's city, the emptied background) was restored from an EJSON backup at the end; the five result sheets born in the UAT and the `[UAT]` worldMission were deleted.

## Decisions taken during the UAT (user)

- **Rank stories (DB content).** Four permanent rank `story` quests, one per rank, empty (no place, no prizes, no enemies), acceptable from any city, once per character; the completion raises the rank: rookie 5000 points «Inizia l'avventura!», adventurer 7000 «Qualcuno su cui fare affidamento», paladin 10000 «La prova del proprio valore», mage 15000 «Un atto eroico!».
- **D-20** (amends D-15 for the item lines): «Le ferite devono comparire tutte nella lista di ferite curate. C'è già il segnalino che indica che una ferita non può essere curata, non diamo mezze informazioni agli utenti.»
- **D-21** (refines D-20): «Facciamo che ferite che una pozione non può curare perché sono date dall'oste sono scritte in rosso». The heal quest line «Cura le tue ferite: …» stays filtered: «Qua è corretto». The shop line stays unfiltered and uncoloured: Q10 of the BE notes is closed.
- **D-22:** «Quando la sezione ferite è vuota non mostriamo la sezione. Rendi anche quella una dropdown».
- **D-23:** «Dentro la pagina di riepilogo puoi separare i risultati per personaggio e mettere le solite tendine? Metti anche il campo di testo per la nuova aggiunta dentro alla tendina»; the header summary «aggiunta N/1000» proposed by the orchestrator: «Mi va bene la tua aggiunta, è una buona idea».
- **Layout retouches** (steps 1 and 7): the start note beside its button, the separator between the background entries, the sigil on the right, the rank medal on the portrait corner (words in the step rows).
- **«Completa» inside the «Concludi» dialog** accepted as it is: «C'è scritto completa. Pass».
- **Copy confirmed by the user's passes:** «La tua storia ha una nuova pagina», «Di questo avventuriero non si sa ancora nulla», «Storie», «Aggiunte alle storie», the note under the chips, «(dell'oste)», «Troppo grave per essere curata». No copy changed.

## Closing gates (plan 24-11 Task 3, final tree, 2026-11-22)

- Gate re-check on BE `origin/develop` `a5b140a6` (read-only `git show`): `GATE_OK`.
- Schema check of the registered documents against that SDL (`QuestInfos.markerLocation` nullable there): «dumped 55 documents», 55 × OK.
- `flutter analyze`: «47 issues found» (the baseline).
- Full suite (`flutter test -r failures-only`): `+5535: All tests passed!`.
- `tool/hardening_check.sh`: `hardening_check: OK`.

## Requirement ↔ step map

Requirement ↔ step map: STORY-01 (1, 2), STORY-02 (4, 5, 6), STORY-03 (7), WOUND-01 (3, 10), WOUND-02 (8, 9, 10), WOUND-03 (7, 10), STORY-04 (the gate of 24-10 — schema gate, 55 × OK, full suite — and steps 1–10 all passed or explicitly waived by the user). Not on the device, covered by tests: lenient parsing of every new field (24-01, 24-02), the grapheme count (24-05), the save refused on leave (24-06), the switch-off behaviour (24-06, 24-07), the «not selected before the gate» pins flipped (24-10).

A requirement is marked complete only by plan 24-11 Task 3 and only when all its mandatory steps passed; a failing step leaves it `In Progress (gaps: steps …)`.

**Outcome (2026-11-22):** every mandatory step passed in the user's words, so STORY-01, STORY-02, STORY-03, STORY-04, WOUND-01, WOUND-02 and WOUND-03 are marked complete. WOUND-02 is complete as amended by D-20 / D-21 (the potion lines list the innkeeper wound, in red for the reader; the heal quest line still leaves it out).
