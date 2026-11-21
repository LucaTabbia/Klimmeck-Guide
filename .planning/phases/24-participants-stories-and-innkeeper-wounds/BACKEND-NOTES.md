# Phase 24 (FE) — Backend notes

Drafted by the planner on 2026-11-21, before the execution; §1 is confirmed and §2 filled by plan 24-11 (Task 1) after the gate of 24-10, §3 is completed by plan 24-11 (Task 3) after the device E2E.

Frontend companion of the BE Phase 25 («Storie dei partecipanti e ferite dell'oste»). FE branch `feat/24-participants-stories-and-innkeeper-wounds` (stacked on the local `fix/ui-layout-review`). English text, Italian UI copy verbatim. No ids of real users or characters, no secrets, no URIs, no environment values in this file. Decisions: `24-CONTEXT.md` D-01..D-18 (shared numbering with the BE `25-CONTEXT.md`).

## 1. Contract consumed by the FE

Names fixed by the orchestrator on 2026-11-21 (all additive on the SDL); the FE selects them only in its gate plan 24-10, after the BE Phase 25 merge, and re-checks each on the merged SDL. The registry of FE documents stays at **55**: no new query, no new mutation.

- **W-1** `CharacterStatus.innkeeperInjuries: [InjuryType!]!` (subset of `injuries`) — selected in `CharacterFragment.statusFields`, therefore in `character`, `me.currentCharacter` and `characterUpdated`. Read leniently (absent → empty). Used by: the Journal line «Troppo grave per essere curata», the quest sheet line «Cura le tue ferite: …» (the character's wounds minus these), the potion line «Cura: …» in the Journal and in the potion sheet, the key of the silent Board reread.
- **W-2** `ParticipantOverrideInput.injuriesRemoved: [InjuryType!]` — sent inside `SaveMissionDraftInput.fights[].corrections[]`, ALWAYS present on every correction of a saved fight once the FE gate has switched the feature on, as an explicit list — `[]` when nothing is removed — so that un-removing a removal already saved is sent as «none» (question 7); before the gate the key never leaves the app. The same wound may be in `injuriesRemoved` and in `injuries` (removed and added again = innkeeper wound, D-16). The app offers for removal only the wounds of the served `injuriesBefore`, and for addition only the wounds not carried or removed in the same correction.
- **W-3** `MissionFightOutcome.innkeeperInjuriesBefore: [InjuryType!]!` — marks «(dell'oste)» on the chips of the wounds carried at the start of a fight.
- **W-4** `MissionFightEffects.injuriesRemoved: [InjuryType!]!` and `MissionFightEffects.innkeeperInjuries: [InjuryType!]!` (selected on `simulated` and `corrected`) — the removals seed the correction when a fight is reopened and feed the recap line «Ferite tolte: …»; `innkeeperInjuries` marks the added wounds. The app never computes «corrected minus simulated».
- **W-5** Stories: the existing `character(id)` (open to the innkeeper) with `infos.background: [String!]!`, oldest entry first. Read once per participant when the wizard opens — BEFORE the draft exists, with the character ids of the pending request(s) of the card — and reused on the last page.
- **W-6** `MissionDraft.backgroundAdditions: [{ character: ID!, text: String! }!]!` — seeds the fields of the last page when the draft is reopened.
- **W-7** `SaveMissionDraftInput.backgroundAdditions: [{ characterId: ID!, text: String! }!]` — the app sends ONE entry per participant with the trimmed text, the empty ones included (empty = «no addition for this participant»), on «Concludi», on «Indietro» from the last page and when the innkeeper leaves the wizard from the last page with unsaved text. Section absent on every other save.
- **W-8** `MissionDraftStep.stories` — saved by «Avanti» on the recap and by «Concludi»; a draft served at this step reopens on the last page. (On the FE the page enum calls the last page `additions`; `stories` there is the reading page, which is never saved as a step.)
- **W-9** Refusal code `BACKGROUND_ADDITION_TOO_LONG` (only `extensions.code` is read) → wizard line «Un'aggiunta supera i 1000 caratteri». The app's counter (1000 grapheme clusters after trim) is UX only.
- **W-10** `completeGuidedMission(pendingQuestId: ID!): [QuestResult!]!` unchanged: «Concludi» calls `saveMissionDraft` (additions + step) and then `completeGuidedMission`, in this order, as one user action.
- **W-11** `QuestResult.backgroundEntryAdded: Boolean!` → result sheet line «La tua storia ha una nuova pagina». `QuestResult.injuriesRemoved: [InjuryType!]!` → shown inside the existing line «Guarite: …» after `injuriesHealed`, without repeating a wound (D-18). Both selected in `QuestResultFragment.fields` (`GetQuestResult`, `ListUnacknowledgedQuestResults`, `OnQuestResultReceived`, `CompleteGuidedMission`).
- **W-12** No FE change for cures: the app relies on `Quest.noEffect`, `QUEST_NO_EFFECT`, `ITEM_NO_EFFECT` and `injuriesHealed` ignoring innkeeper wounds on the BE (D-14).
- **W-13** `characterUpdated` for every participant at the completion — the new background entry (wax sigil on Profile and on the entry, device-side «seen» store) and the wounds with their origin — also when ONLY the origin of a wound changed.
- **Not consumed:** `completePendingRequest` (the FE has had no plain pending-request form since its plan 21-17: the wizard is the only correction surface); no `background` on the queue entries; no dedicated push.

## 2. FE behaviours proved by tests

Filled by plan 24-11 (Task 1) from the SUMMARYs of 24-01..24-10. Planned:

- Lenient parsing of every new field (absent → neutral value, unknown wound names dropped, a malformed addition dropped).
- Nothing of Phase 25 selected, and nothing new sent, before the gate (pins + one switch).
- Reading page before the draft: opening never calls `startMissionDraft`; the stories read once; a failed read never blocks the start.
- Corrections: removal only of carried wounds, re-adding only after removal, marks only from served lists, removals sent whole and listed in the recap.
- Last page: one optional addition per participant, 1000 grapheme clusters, save then complete in one action, additions kept after a refused completion, saved on back and on leave.
- Player: Journal line, cure lines without innkeeper wounds, Board reread on an origin flip, result sheet lines from served fields, wax sigil on an appended entry.

## 3. UAT outcome (FE Phase 24)

Filled by plan 24-11.

## 4. Questions and notes for the BE

1. **Additions on the save (W-7).** The FE follows the BE research (§Q4): each entry replaces the one of its character, the others stay, a text empty after trim removes the entry. Please confirm in the BE handoff, and confirm that an empty `text` is accepted on the wire (not refused by a `@IsNotEmpty` / min length) and that sending an entry for every participant at every save of the section is fine.
2. **`BACKGROUND_ADDITION_TOO_LONG` (W-9).** Raised at the save, at the completion, or both? Only `{ code }` in `extensions`? The FE shows one line in the wizard and stays on the page in both cases.
3. **Step value (W-8).** The FE uses `stories` (the BE research's name). If the merged SDL names it otherwise the FE gate reports a deviation: please keep the name or say the final one in the handoff.
4. **A simulated wound the character already owns.** The FE sends back the complete correction of a fight seeded from the served effect: if the simulation lists in `injuriesAdded` a wound that is also in `injuriesBefore`, the FE sends it unchanged in `injuries` without listing it in `injuriesRemoved` (the app never repairs served lists). Is that accepted at save and at completion (the BE spec «passes through a simulated injury the character already owns»)?
5. **`characterUpdated` on an origin flip (W-13).** A remove-and-re-add leaves `status.injuries` identical: the FE needs the event anyway (Journal line, cure lines, Board reread). Confirm it is published.
6. **`quests` for the viewer.** The FE rereads `quests` when `innkeeperInjuries` changes, expecting `noEffect` of a heal quest to follow the origin (a heal whose only matching wounds are the innkeeper's is `noEffect: true`). Confirm.
7. **Absent `injuriesRemoved` on a correction (W-2).** How does the BE read a correction WITHOUT the key: «no removal» or «removals unchanged»? The FE sends the complete correction of a fight at every save; to un-remove a removal already saved it sends `injuriesRemoved: []` explicitly (always present with the feature on). Confirm that an explicit empty list is accepted and means «none», and say how an absent key is read (the FE of before the gate never sends it). If `[]` is not acceptable the FE changes one function in its gate plan.
8. **`innkeeperInjuriesBefore` on drafts simulated before the deploy** reads empty (BE research, runtime state): the FE then shows no mark until the fight is simulated again. Fine for the FE; say it in the handoff if a note for the innkeeper is wanted.
9. **Old clients.** A draft left at the step `stories` and opened by an app without the value lands on «Luogo» (lenient parse): harmless, noted.
10. **Shop line.** The shop's potion line «Cura: …» still lists a wound the buyer carries as an innkeeper wound (catalogue line; user decision: to look at in the UAT). No BE work unless the user asks.
11. **Device «seen» store.** The wax sigil identifies a background entry by its text (layout review, pre-existing): an addition identical to an existing entry is not marked as new. No BE work; relevant only for the UAT script (use a fresh text).
