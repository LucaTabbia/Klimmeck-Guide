# Phase 24 (FE) — Backend notes

Drafted by the planner on 2026-11-21, before the execution. §1 confirmed and §2 filled by plan 24-11 (Task 1) on 2026-11-22, after the gate of 24-10; §4 updated with the answers of the BE handoff; §3 completed by plan 24-11 (Task 3) on 2026-11-22 after the device E2E, with §4 updated (Q10 closed, Q13 closed, Q15 added).

Frontend companion of the BE Phase 25 («Storie dei partecipanti e ferite dell'oste»). FE branch `feat/24-participants-stories-and-innkeeper-wounds` (stacked on the local `fix/ui-layout-review`). English text, Italian UI copy verbatim. No ids of real users or characters, no secrets, no URIs, no environment values in this file. Decisions: `24-CONTEXT.md` D-01..D-18 (shared numbering with the BE `25-CONTEXT.md`), plus the BE's D-19 and the FE-only D-20..D-23 born at the device UAT.

## 1. Contract consumed by the FE

**CONFIRMED by the gate of plan 24-10 and re-checked by plan 24-11** on the merged SDL of BE `origin/develop` `95582457` (merge of BE PR #49): every name, type and nullability below matches `src/schema.gql`, no rename, no deviation. All 55 FE documents validate against that SDL (55 × OK); the registry stays at **55**: no new query, no new mutation. The fields are selected in exactly three fragments (`MissionDraftFragment`, `CharacterFragment.statusFields`, `QuestResultFragment`) and the feature switch is on: **from plan 24-10 on the app needs a BE with Phase 25.**

- **W-1** `CharacterStatus.innkeeperInjuries: [InjuryType!]!` (subset of `injuries`) — selected in `CharacterFragment.statusFields`, therefore in `character`, `me.currentCharacter` and `characterUpdated`. Read leniently (absent → empty). Used by: the Journal line «Troppo grave per essere curata», the quest sheet line «Cura le tue ferite: …» (the character's wounds minus these), the potion line «Cura: …» in the Journal and in the potion sheet (since D-20 / D-21 of the UAT: listed there, written in red, no longer left out), the key of the silent Board reread.
- **W-2** `ParticipantOverrideInput.injuriesRemoved: [InjuryType!]` — sent inside `SaveMissionDraftInput.fights[].corrections[]`, ALWAYS present on every correction of a saved fight, as an explicit list — `[]` when nothing is removed — so that un-removing a removal already saved is sent as «none». The same wound may be in `injuriesRemoved` and in `injuries` (removed and added again = innkeeper wound, D-16). The app offers for removal only the wounds of the served `injuriesBefore`, and for addition only the wounds not carried, or carried and removed in the same correction.
- **W-3** `MissionFightOutcome.innkeeperInjuriesBefore: [InjuryType!]!` — marks «(dell'oste)» on the chips of the wounds carried at the start of a fight.
- **W-4** `MissionFightEffects.injuriesRemoved: [InjuryType!]!` and `MissionFightEffects.innkeeperInjuries: [InjuryType!]!` (selected on `simulated` and `corrected`) — the removals seed the correction when a fight is reopened and feed the recap line «Ferite tolte: …»; `innkeeperInjuries` marks the added wounds. The app never computes «corrected minus simulated».
- **W-5** Stories: the existing `character(id)` (open to the innkeeper) with `infos.background: [String!]!`, oldest entry first. Read once per set of participants when the wizard opens — BEFORE the draft exists, with the character ids of the pending request(s) of the card — and reused on the last page.
- **W-6** `MissionDraft.backgroundAdditions: [MissionBackgroundAddition!]!` (`{ character: ID!, text: String! }`) — seeds the fields of the last page when the draft is reopened.
- **W-7** `SaveMissionDraftInput.backgroundAdditions: [MissionBackgroundAdditionInput!]` (`{ characterId: ID!, text: String! }`) — the app sends ONE entry per participant with the trimmed text, the empty ones included, on «Concludi», on «Indietro» from the last page and when the innkeeper leaves the wizard from the last page with unsaved text. Section absent on every other save. The BE merges the section per character (an empty text clears that character's saved addition): with one entry per participant the result is the same as a whole replacement.
- **W-8** `MissionDraftStep.stories` — saved by «Avanti» on the recap and by «Concludi»; a draft served at this step reopens on the last page. (On the FE the page enum calls the last page `additions`; `stories` there is the reading page, which is never saved as a step.)
- **W-9** Refusal code `BACKGROUND_ADDITION_TOO_LONG` (only `extensions.code` is read) → wizard line «Un'aggiunta supera i 1000 caratteri». The app's counter (1000 grapheme clusters after trim) is UX only.
- **W-10** `completeGuidedMission(pendingQuestId: ID!): [QuestResult!]!` unchanged: «Concludi» calls `saveMissionDraft` (additions + step) and then `completeGuidedMission`, in this order, as one user action.
- **W-11** `QuestResult.backgroundEntryAdded: Boolean!` → result sheet line «La tua storia ha una nuova pagina». `QuestResult.injuriesRemoved: [InjuryType!]!` → shown inside the existing line «Guarite: …» after `injuriesHealed`, without repeating a wound (D-18). Both selected in `QuestResultFragment.fields` (`GetQuestResult`, `ListUnacknowledgedQuestResults`, `OnQuestResultReceived`, `CompleteGuidedMission`).
- **W-12** No FE change for cures: the app relies on `Quest.noEffect`, `QUEST_NO_EFFECT`, `ITEM_NO_EFFECT` and `injuriesHealed` ignoring innkeeper wounds on the BE (D-14).
- **W-13** `characterUpdated` for every participant at the completion — the new background entry (wax sigil on Profile and on the entry, device-side «seen» store) and the wounds with their origin — also when ONLY the origin of a wound changed.
- **Not consumed:** `completePendingRequest` (the FE has had no plain pending-request form since its plan 21-17: the wizard is the only correction surface); no `background` on the queue entries; no dedicated push.

## 2. FE behaviours proved by tests

From the SUMMARYs of 24-01..24-10. Final tree of 24-10: full suite 5495 green, analyzer at its baseline (47 infos), `tool/hardening_check.sh` OK, 55 documents OK against the merged SDL.

**Parsing (24-01, 24-02)**

- Every new field is read leniently: absent → neutral value (empty list, `false`), unknown wound names dropped, a malformed addition dropped. `backgroundEntryAdded` is true only for a served `true`.
- A draft served at the step `stories` by an app that knows the value reopens on the last page.

**Reading page before the draft (24-03, 24-04)**

- Opening the wizard on a request without a draft never calls `startMissionDraft`: the first page «Storie» reads the participants of the card with `character(id)` and the draft is started only by «Inizia la missione».
- The stories are read once per set of participant ids (the order of the ids does not trigger a second read); a second request while a read is running is dropped; «Riprova» is the only forced reread.
- A failed read never blocks the start: «Inizia la missione» does not depend on the stories.
- Each participant is one closed dropdown «<nome> · <rango>»; entries oldest first as served; a loaded character with no background reads «Di questo avventuriero non si sa ancora nulla».

**Corrections (24-01, 24-07)**

- The chips draw two groups, «Ferite presenti» (the served `injuriesBefore`) and «Ferite da aggiungere». Only a carried wound can be removed; a carried wound that is not removed cannot be added; a removed one can be added again (D-16).
- The mark «(dell'oste)» comes only from served lists: `innkeeperInjuriesBefore` for the carried wounds, the effective `innkeeperInjuries` for the added ones. A wound just added by hand stays unmarked until the BE serves it back.
- With the switch on every correction of a saved fight carries `injuriesRemoved` as an explicit list (`[]` when empty); with the switch off the key never leaves the app.
- The app sends the served lists back unrepaired (no filter on a simulated wound already carried).
- The recap and both confirmations list «Ferite tolte: …» = the union of the served effective `injuriesRemoved` over the fights, in served order.

**Last page (24-05, 24-06)**

- The recap shows «Avanti» (no completion there) and the last page «Aggiunte alle storie» shows per participant the story dropdown and one optional field, seeded from `MissionDraft.backgroundAdditions`.
- The counter counts grapheme clusters after trim; over 1000 the field reads «Massimo 1000 caratteri» and «Concludi» is disabled.
- The save sends one entry per participant, trimmed, the empty ones included; a text keyed by a non-participant is ignored.
- «Concludi» is one guarded action: `saveMissionDraft` (additions + step `stories`) and then `completeGuidedMission`; after a refused completion the SAVED draft is re-emitted, so the typed additions are kept.
- The additions are saved on «Indietro» from the last page and on leaving the wizard with unsaved text (unsaved = the trimmed text differs from the served addition); a save refused on leave is handled without losing the page.
- `BACKGROUND_ADDITION_TOO_LONG` → «Un'aggiunta supera i 1000 caratteri», the wizard stays on the page.
- The confirmation of «Concludi» lists the recap lines and «Storia di <nome>: una nuova pagina» for each non-empty addition.

**Player (24-02, 24-08, 24-09)**

- Journal «Ferite»: an innkeeper wound reads «Troppo grave per essere curata» under its name; the section follows an origin flip with identical `status.injuries`.
- Cure lines without innkeeper wounds: the quest sheet «Cura le tue ferite: …» and the potion line «Cura: …» in the Journal «Oggetti» and in the potion sheet. The shop line is unchanged (catalogue line). **Amended at the UAT (D-20, D-21, §3):** the potion line now lists every wound of `canHeal`, the reader's innkeeper wounds in red; the quest sheet line stays filtered.
- The Board is reread silently when `innkeeperInjuries` changes, in a city only.
- Result sheet: «La tua storia ha una nuova pagina» only for a served `backgroundEntryAdded: true`; ONE line «Guarite: …» with `injuriesHealed` as served followed by the wounds of `injuriesRemoved` not already listed. The potion sheet keeps `injuriesHealed` only.
- Wax sigil: an appended background entry lights the sigil on the Profile entry of the menu and on the new entry; opening the Profile clears it (proved without production changes; the entry is identified by its text).

**Gate (24-10)**

- Before the gate nothing of Phase 25 was selected and nothing new was sent (pins + one switch); the pins were flipped at the gate together with the switch. The switch constant stays in the code.

## 3. UAT outcome (FE Phase 24, 2026-11-22)

BE under test: BE `develop` at `a5b140a6` = merge of BE PR #50 «fix(quests): let a story quest live without a place» (quick task 261122-snp) on top of the Phase 25 merge `95582457` (BE PR #49), booted locally by the orchestrator; device Samsung SM-S938B over USB, one phone, identity switched by restarting the BE with the dev identity of the innkeeper's user or of the participant's user. Full record: `24-HUMAN-UAT.md` (`status: complete`). Every step passed in the user's words; STORY-01..STORY-04 and WOUND-01..WOUND-03 are complete on the FE.

Closing gates on the final FE tree (`639a24b8` + the closing documents): gate re-check `GATE_OK` and schema check 55 × OK on the SDL of `a5b140a6`, analyzer «47 issues found», full suite 5535 green, hardening check OK.

**Story quests without a place (born in the session, BE PR #50).**

- `QuestInfos.markerLocation: PointOfInterest` is nullable on the SDL (one line); only story quests may have no place. The gate of 24-10 ran on `95582457`; the FE already parsed the field as nullable, and now pins it: a story quest served without a place is parsed, and the map draws a quest marker only for a place with a location (FE `5a0c5891`, `fb02b89c`, `525f318e`). The 55 documents validate on the new SDL.
- DB content decided by the user: four permanent rank `story` quests, one per rank, empty (no place, no prizes, no enemies), acceptable from any city, once per character; the completion raises the rank — rookie 5000 points «Inizia l'avventura!», adventurer 7000 «Qualcuno su cui fare affidamento», paladin 10000 «La prova del proprio valore», mage 15000 «Un atto eroico!». They stay in the DB.
- On the device (extra step 0): the Board of the participant shows only the story of the character's rank, with description and cost; accepted from the city with no travel — «pass su tutto». DB: story lane taken, no travel, no draft. After the completion the rank rose (rookie → adventurer, later adventurer → paladin), the story quest stays open for the others, and the participant then saw only the story of the new rank.
- No worldMission content exists in the DB: the two-participant part ran on an improvised `[UAT]` worldMission, removed afterwards.

**Outcome of the steps that touch the BE** (user's words relayed by the orchestrator; DB readings and writes are the orchestrator's):

- **Reading page, no draft before the start (step 1):** «Tutto perfetto, pass» (after a layout retouch, FE only). DB: no draft while the page is open.
- **Start and lock (step 2):** «pass». DB: the draft is created only by «Inizia la missione», the participant is locked.
- **Removals and remove-and-re-add (step 3):** «Ho rimosso tutte le ferite, aggiungendo come ferita dell'oste solo assideramento» — «pass su tutto». Draft at DB: `corrected.injuriesRemoved` [deepCut, hypothermia], `corrected.injuriesAdded` [hypothermia]. The third hand-added wound was not run on the device (FE tests).
- **Last page, leave and come back (steps 4, 5):** «pass su tutto», «pass». The paste over 1000 characters was not run on the device (FE tests): `BACKGROUND_ADDITION_TOO_LONG` was not provoked there.
- **«Concludi» (step 6):** «C'è scritto completa. Pass». DB: deepCut removed, hypothermia now an innkeeper wound, background 2 → 3 entries; result `injuriesRemoved` [deepCut], `backgroundEntryAdded` true; the remove-and-re-add leaves no trace on the result; no draft, no pending request.
- **Result sheet and sigil (step 7):** «pass su tutto» — «La tua storia ha una nuova pagina», one line «Guarite: …», sigil on the menu entry and on the new entry.
- **Journal (step 8):** «pass» — «Troppo grave per essere curata» under the innkeeper wound only.
- **Potions (step 9a):** the BE behaviour passed («Tutto ha funzionato comunque»: no effect on the innkeeper wound). The DISPLAY rule of the item line was reversed by the user (D-20, D-21 below).
- **Heal quest (steps 9b, 9c):** the line «Cura le tue ferite: …» with the ordinary wound only — «Qua è corretto»; result `injuriesHealed` [brokenRightLeg], the innkeeper wound stays; the heal quest is torn at full life with only the innkeeper wound — «pass».
- **Board reread on an origin flip (step 10a):** with the Board open the origin was flipped at DB (innkeeper → ordinary): the heal quest turned whole by itself — «confirmo»; flipped back, torn again — «pass su tutto». `noEffect` follows the origin at every read, as the BE handoff says (Q6).
- **The innkeeper takes his wound off (steps 10b, 10c):** «pass», «pass». DB: no wounds left, background unchanged, result `injuriesRemoved` [hypothermia], `backgroundEntryAdded` false; the sheet reads «Guarite: …» with that wound and no story line.
- **Two participants (extra step 11, improvised worldMission):** «pass e accettata», «pass su tutto», «pass». An addition for one participant only: `backgroundEntryAdded` true for that participant, false for the other; quest concluded; no draft, no pending request. The participant with no background reads «Di questo avventuriero non si sa ancora nulla».

**Decisions of the user during the UAT (FE only, no BE work):**

- **D-20:** «Le ferite devono comparire tutte nella lista di ferite curate. C'è già il segnalino che indica che una ferita non può essere curata, non diamo mezze informazioni agli utenti.» The line «Cura: …» of a heal item lists the whole `canHeal`, the reader's innkeeper wounds included. Behaviour unchanged: the BE still refuses with `ITEM_NO_EFFECT` (D-14).
- **D-21:** «Facciamo che ferite che una pozione non può curare perché sono date dall'oste sono scritte in rosso». In the Journal item row and in the potion sheet the reader's `status.innkeeperInjuries` are written in red inside that line; the rows that do not know the reader (shop, prizes, the innkeeper's catalogue) stay uncoloured.
- The heal quest line «Cura le tue ferite: …» stays filtered («Qua è corretto»).
- **D-22** («Ferite» of the Journal as a dropdown, absent without wounds) and **D-23** (recap and additions in one dropdown per participant; nothing changes in what is saved or sent) are layout only.
- Layout retouches of steps 1 and 7 (start note beside its button, separator between background entries, sigil on the right, rank medal on the portrait): FE only.

**Copy:** no change. Confirmed by the user's passes: «La tua storia ha una nuova pagina», «Di questo avventuriero non si sa ancora nulla», «Storie», «Aggiunte alle storie», the note under the chips, «(dell'oste)», «Troppo grave per essere curata». The confirm button of the «Concludi» dialog keeps «Completa».

**Clean-up:** every seed of the session was restored from a backup at the end; the result sheets born in the UAT and the `[UAT]` worldMission were deleted; the four rank stories stay.

## 4. Questions and notes for the BE

Answers from the BE handoff on `origin/develop` `95582457` (`.planning/phases/25-storie-dei-partecipanti-e-ferite-dell-oste/BACKEND-NOTES.md`, §5 «Risposte al handoff della FE»), in the numbering of the planner's draft.

1. **Additions on the save (W-7) — ANSWERED, closed.** The section is MERGED per character (decided after the FE plans were written): absent or `null` = untouched; each entry replaces only its character's addition; an omitted participant keeps theirs; a text empty after trim is accepted on the wire and clears that character's saved addition; cap of 50 entries per call. The FE sends one entry per participant, the empty ones included: no FE change.
2. **`BACKGROUND_ADDITION_TOO_LONG` (W-9) — ANSWERED, closed.** Raised at the save (normal case) and, in defence, at the completion (the whole completion refused, nothing written); `extensions` carries only `code`. The FE shows the same line in both cases. Other refusals of the section (`OUTCOME_NOT_PARTICIPANT`, `OUTCOME_OVERRIDE_INVALID`, `BAD_USER_INPUT`) fall on the FE's generic mapping: the app never builds such a section.
3. **Step value (W-8) — ANSWERED, closed.** `stories`, final.
4. **A wound already carried proposed again — ANSWERED, closed by the BE's D-19.** Ignored by the BE, always: not added, no refusal, no error, no change of origin, at the save and at the completion; the simulation leaves it out of `simulated.injuriesAdded`. The FE sends the served effect back unchanged and filters nothing; its chips do not offer a carried wound for addition unless it is removed first (the only way to make it an innkeeper wound, D-16). No FE change.
5. **`characterUpdated` on an origin flip (W-13) — ANSWERED, closed.** Published with identical `status.injuries` and updated `status.innkeeperInjuries`.
6. **`quests` for the viewer — ANSWERED, closed.** A heal's `noEffect` follows the origin and is computed at every read; the FE's reread on a change of `innkeeperInjuries` gets the new value.
7. **Absent `injuriesRemoved` on a correction (W-2) — ANSWERED, closed.** Absent, `null` and `[]` all mean «no removal»; the explicit empty list is accepted. The FE keeps sending `[]` explicitly. Consequence known to the FE: a correction changing only the removals resets the following fights.
8. **Drafts simulated before the deploy — ANSWERED, noted.** The three new draft fields read empty until the fight is simulated again; the FE shows no mark until then. No note for the innkeeper on either side.
9. **Old clients — noted.** A draft left at the step `stories` and opened by an app without the value lands on «Luogo» (lenient parse): harmless.
10. **Shop line — CLOSED by D-20 / D-21 (user, device UAT step 9, 2026-11-22).** Every item line «Cura: …» lists the whole `canHeal`; the Journal row and the potion sheet write the reader's innkeeper wounds in red; the shop line stays unfiltered and uncoloured. No BE work.
11. **Device «seen» store — noted.** The wax sigil identifies a background entry by its text, and the BE appends an addition identical to an existing entry anyway: such an addition is not marked as new. No BE work; the UAT uses a fresh text.

Notes added by plan 24-11:

12. **Raw `innkeeperInjuries` and legacy data — OPEN on the BE side (its «Punti aperti»).** The list is served raw and the invariant «subset of `injuries`» is kept only by the BE's writes; a completion without corrections does not clean a dirty list. The FE draws what it receives: its tests cover the served subset, not specifically an `innkeeperInjuries` entry absent from `injuries`. DB scripts must write the two lists in the same update. Question for the BE: is a clean-up of legacy duplicates / dirty lists planned, or is the DB-script rule enough?
13. **A remove-and-re-add leaves no trace on the result sheet** (neither `injuriesAdded` nor `injuriesRemoved`): the player learns of the origin change only from the Journal line. Accepted as designed by the BE. **CLOSED at the UAT:** seen at step 6 (the remove-and-re-add left no trace on the result) and passed by the user with no line asked.
14. **Audit log.** The addition texts end up in the BE audit log of `saveMissionDraft` (declared by the BE handoff): noted, no FE work.
15. **Story quests without a place (BE PR #50) — noted, closed.** `QuestInfos.markerLocation` is nullable and only story quests may have no place; the FE parses it, draws no marker for it and accepts the quest from the city with no travel (§3). The four rank stories are DB content. No open point for the BE.

Still open after the UAT: only Q12 (raw / dirty `innkeeperInjuries`). It was not exercised on the device: every DB write of the session kept the two lists together.
