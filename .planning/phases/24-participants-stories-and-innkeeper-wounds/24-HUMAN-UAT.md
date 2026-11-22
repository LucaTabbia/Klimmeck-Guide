---
status: pending
phase: 24-participants-stories-and-innkeeper-wounds
device: Android (Samsung, USB, adb reverse tcp:3000 tcp:3001 — BE on port 3001)
be_ref: "origin/develop 95582457 (merge of BE PR #49, BE Phase 25 «Storie dei partecipanti e ferite dell'oste»)"
fe_ref: "feat/24-participants-stories-and-innkeeper-wounds 48d2c43a (code at ba2bfa21)"
gate: "GATE_OK — re-checked by plan 24-11 Task 1 on 2026-11-22"
---

# Phase 24 — Device E2E (participants' stories and innkeeper wounds)

App of `feat/24-participants-stories-and-innkeeper-wounds` on the Android phone against the local BE booted by the orchestrator from BE `develop` at `95582457` (BE Phase 25 merged). Gate re-checked by plan 24-11 on `origin/develop` of the BE repo (read-only `git show`, never `fetch`): `CharacterStatus.innkeeperInjuries: [InjuryType!]!`, `QuestResult.backgroundEntryAdded: Boolean!`, `QuestResult.injuriesRemoved: [InjuryType!]!`, `MissionDraftStep.stories`, `ParticipantOverrideInput.injuriesRemoved: [InjuryType!]`, `MissionFightOutcome.innkeeperInjuriesBefore: [InjuryType!]!` → `GATE_OK`. Results are recorded only from the tester's words as relayed by the orchestrator, who runs the session one step per message; DB readings and DB writes are the orchestrator's. No ids of real users or characters, no secrets, no URIs, no identity values in this file (field names and city / quest / wound names only); the stories typed during the session are not transcribed.

## Setup

Setup: BE with Phase 25 booted by the orchestrator; Samsung via USB with `adb reverse tcp:3000 tcp:3000` (or `tcp:3000 tcp:3001`); app of `feat/24-participants-stories-and-innkeeper-wounds`. An innkeeper identity and a participant identity (two devices, or one device switching identity as in the Phase 21 UAT). In the queue: one `story` request of a character with at least two background entries and two ordinary wounds, one `worldMission` request with two participants (one of them with an empty background). Every seed, character move and wound write is the orchestrator's job, with DB scripts outside the repo and the BE's own write shapes. The Board and the shop are opened only in a city, never in travel.

**This session:** the BE runs on port 3001, so the reverse is `adb reverse tcp:3000 tcp:3001`. The app selects `innkeeperInjuries`, `backgroundAdditions`, `injuriesRemoved` and `backgroundEntryAdded`: never against a BE without Phase 25.

Device notes: `adb reverse` is lost at every USB reconnection; port 3000 busy → `PORT=3001` + `adb reverse tcp:3000 tcp:3001`; screen off → `adb shell svc power stayon usb`. These commands are run by the user or the orchestrator, never by the executor.

## Prerequisites owned by the orchestrator

| Prerequisite | Done |
|--------------|------|
| BE `develop` with Phase 25 booted (no migrator: every new field has a neutral value) | pending |
| `adb reverse tcp:3000 tcp:3001` and the app of the FE branch on the phone | pending |
| An innkeeper identity and a participant identity | pending |
| One `story` request in the queue: a character with at least two background entries and two ordinary wounds | pending |
| One `worldMission` request in the queue with two participants, one of them with an empty background | pending |
| Open guided drafts checked at the boot (a draft simulated before Phase 25 serves empty lists on the new fields until the fight is simulated again) | pending |
| The participant's device has already opened the Profile once (step 7) | pending |
| An ordinary wound seeded on the participant (step 8) | pending |
| A city with a heal quest whose cure lists an innkeeper wound and the ordinary one; a heal quest that would cure only innkeeper wounds, life full; a potion whose `canHeal` lists the innkeeper wound (step 9) | pending |
| A later mission of the same character, and a torn heal quest on the Board of the city where the character is (step 10) | pending |

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
| 1 | Reading page. The innkeeper opens the story request from the Locanda: the wizard opens on «Passo 1 di 7 · Storie» with one closed dropdown «<nome> · <rango>»; a tap opens it and shows the background entries, oldest first; the start note and «Inizia la missione» are at the bottom; no popup anywhere. While the page is open the participant is still free (can open the Board, is not «Missione in corso») (STORY-01; D-01, D-02, D-02a, D-03). | STORY-01 | pending | — |
| 2 | Start and way back. «Inizia la missione» lands on «Passo 2 di 7 · Luogo» and the participant is now locked; «Indietro» shows the stories again with «Avanti», which returns to «Luogo»; in the worldMission request the participant with no background reads «Di questo avventuriero non si sa ancora nulla» (STORY-01; D-02, D-03). | STORY-01 | pending | — |
| 3 | Removing and re-adding wounds. In a simulated fight the participant's section shows «Ferite presenti» with the two wounds carried; a tap removes one (ordinary → gone); the other is removed and then tapped again under «Ferite da aggiungere» (ordinary → innkeeper wound); a third wound is added by hand; the note under the chips reads «Una ferita aggiunta a mano è dell'oste: nessuna cura la toglie»; a wound carried and not removed cannot be added; after «Avanti» and «Indietro» the fight reopens with the same choices and the hand-added wounds marked «(dell'oste)» (WOUND-01; D-12, D-13, D-16). | WOUND-01 | pending | — |
| 4 | Recap and last page. The recap lists «Ferite tolte: …» and shows «Avanti» (no «Completa»); the last page «Passo 7 di 7 · Aggiunte alle storie» shows per participant the story dropdown and one field with the counter «0/1000»; a text over 1000 characters shows «Massimo 1000 caratteri» and disables «Concludi»; the keyboard in landscape leaves the field visible (STORY-02; D-04, D-05, D-07, D-08). | STORY-02 | pending | — |
| 5 | Leaving and coming back. With a text typed, leave the wizard (back) and reopen the request from the Locanda: the wizard reopens on the last page with the text; «Indietro» to the recap and «Avanti» again keeps it (STORY-02; D-05). | STORY-02 | pending | — |
| 6 | «Concludi». The confirmation lists the recap lines and «Storia di <nome>: una nuova pagina»; after the confirmation the results recap shows and the request leaves the queue. In the worldMission: one participant gets an addition, the other field is left empty (STORY-02; D-05, D-06). | STORY-02 | pending | — |
| 7 | Participant's result sheet and sigil. The participant's result sheet reads «La tua storia ha una nuova pagina» and ONE line «Guarite: …» with the wound the innkeeper took off; the participant of the worldMission with the empty field reads no story line; the Profile entry of the menu carries the wax sigil, and in the Profile the new entry (last of the background) carries the sigil, the older ones do not; reopening the Profile clears it (STORY-03, WOUND-03; D-08, D-09, D-18). Use a text never used before, on a device that has already opened the Profile once. | STORY-03, WOUND-03 | pending | — |
| 8 | Journal. In the participant's Journal «Ferite» the two innkeeper wounds read «Troppo grave per essere curata» under their name; an ordinary wound (seeded by the orchestrator) reads no such line; the removed wound is gone (WOUND-02; D-15). | WOUND-02 | pending | — |
| 9 | Heal quests and potions. In a city with a heal quest whose cure lists both an innkeeper wound and the ordinary one: the sheet reads «Cura le tue ferite: …» with the ordinary wound only; a heal quest that would cure only the innkeeper wounds (life full) is drawn torn and not acceptable; in the Journal «Oggetti» a potion whose `canHeal` lists the innkeeper wound shows «Cura: …» without it, and so does the potion sheet; drinking a potion whose only useful effect would be that wound shows the «nessun effetto» notice and consumes nothing; after a heal of the ordinary wound the result reads «Guarite: …» with that wound only and the innkeeper wounds stay. The shop line of the same potion is looked at by the user as it is (WOUND-02; D-11, D-14, D-15; ruling 4). | WOUND-02 | pending | — |
| 10 | The innkeeper takes his wound off. In a later mission of the same character the fight section shows the innkeeper wounds under «Ferite presenti» marked «(dell'oste)»; removing one and concluding makes it disappear from the Journal and appear under «Guarite: …» on the result sheet; the Board, open in a city during the completion, turns a torn heal quest whole again without restarting the app when the origin flip makes it useful (WOUND-01, WOUND-02, WOUND-03; D-13, D-18, Pitfall 4). | WOUND-01, WOUND-02, WOUND-03 | pending | — |

Result values: `pass`, `fail`, `pass after fix`, `not run`. The user's words are written as relayed by the orchestrator.

## Not run on the device

Filled at the end of the session (part, why, covered by).

## Changes made during the UAT

Filled at the end of the session (FE commits, BE commits, DB content written by the orchestrator).

## Decisions taken during the UAT (user)

Filled at the end of the session.

## Requirement ↔ step map

Requirement ↔ step map: STORY-01 (1, 2), STORY-02 (4, 5, 6), STORY-03 (7), WOUND-01 (3, 10), WOUND-02 (8, 9, 10), WOUND-03 (7, 10), STORY-04 (the gate of 24-10 — schema gate, 55 × OK, full suite — and steps 1–10 all passed or explicitly waived by the user). Not on the device, covered by tests: lenient parsing of every new field (24-01, 24-02), the grapheme count (24-05), the save refused on leave (24-06), the switch-off behaviour (24-06, 24-07), the «not selected before the gate» pins flipped (24-10).

A requirement is marked complete only by plan 24-11 Task 3 and only when all its mandatory steps passed; a failing step leaves it `In Progress (gaps: steps …)`.
