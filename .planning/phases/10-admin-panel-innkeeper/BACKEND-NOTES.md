# BACKEND-NOTES — FE Phase 10 Admin Panel (handoff for the BE Phase 10 rule BE-HARD-08 and record of the BE contract the panel consumes)

- **FE phase:** 10-admin-panel-innkeeper (ADMIN-01..08 as amended on 2026-10-29; decisions D-01..D-25 in `10-CONTEXT.md`)
- **Date:** 2026-10-29 — written in the Phase 10 discuss, in the same session in which the BE Phase 10 (hardening) was being planned; the BE side of §2 was added to `Klimmeck-Guide-BE/.planning/phases/10-hardening-trasversale/10-CONTEXT.md` (D-23/D-24, BE-HARD-08) in the same session. **Status: proposal.** The BE fixes the contract in its own `BACKEND-NOTES.md` of Phase 10; `src/schema.gql` on BE `develop` wins over this document.
- **Source of the consumed contract:** `Klimmeck-Guide-BE/.planning/phases/09-combat-result-admin-outcomes/BACKEND-NOTES.md` §9 (PR #13), `…/08-travel-lifecycle-travel-01/BACKEND-NOTES.md` §7 (PR #11), `…/03-autorizzazione-ownership-ruoli-audit/BACKEND-NOTES.md` (PR #5).

---

## 0. TL;DR for the BE

1. **Consumed as-is:** `pendingRequests`, `pendingRequestsUpdated` (snapshot + full list on PendingQuest insert/delete), `completePendingRequest(input)` with per-participant overrides, `teleportCharacter(request: { id, poiId })`, `character(id)` read by the innkeeper, the audit interceptor. Nothing in this handoff changes them.
2. **Requested for the BE Phase 10 (BE-HARD-08, user decision 2026-10-29):**
   - the additive field **`PendingRequestCharacter.pendingQuest: ID`** (id of the character's standard PendingQuest, `null` when the standard lane is free) — so the panel can hide a character busy with a standard quest (§2.1);
   - **`completePendingRequest` refuses with `QUEST_IN_PROGRESS`** while any registered active participant has the standard lane occupied, without writes (§2.2) — the same rule on both sides.
3. **FE behaviour the BE should know (§3):** cards grouped by quest, busy participants hidden, free travellers greyed until arrival, one `completePendingRequest` per card with the first entry's id and `outcomes` only for the changed participants, teleport from the Map by dragging the pawn to a city marker with no confirmation, refetch of `pendingRequests` on the FE's own triggers.

---

## 1. Contract consumed (BE `develop`, no change requested)

Documents the FE will register (names provisional):

```graphql
fragment PendingRequestEntry on PendingRequest {
  id
  startDate
  pointsSpent
  quest { id type title requiredAdventurers { title count } registeredAdventurers { character title registeredAt } }
  character {
    id name title location
    activeTravel { startTime endTime duration to }
    awaitingAid { quest aidQuest since }
    pendingQuest          # BE-HARD-08, §2.1 — selected only by the schema-gated plan
  }
  user { id twitchId }
}

subscription OnPendingRequestsUpdated { pendingRequestsUpdated { ...PendingRequestEntry } }
query GetPendingRequests { pendingRequests { ...PendingRequestEntry } }

mutation CompletePendingRequest($input: CompletePendingRequestInput!) {
  completePendingRequest(input: $input) { ...QuestResultSheet }   # fragment of FE Phase 9
}

mutation TeleportCharacter($request: TravelRequest!) {
  teleportCharacter(request: $request) { response successful }
}
```

Facts the FE relies on (BE Phase 9 §9, Phase 8 §7, Phase 3):

- `pendingRequestsUpdated` is innkeeper-only (`FORBIDDEN` at subscribe for anybody else), emits a snapshot at subscribe and the **full list** at every insert/delete of a PendingQuest (single-flight recomputation); it does **not** re-emit when a queued character's `status.location` or `status.activeTravel` changes.
- One entry per character and GM lane; `PendingRequest.id` is the PendingQuest id to pass as `pendingQuestId`; a worldMission with three registered characters is three entries with the same `quest.id`; **one call closes the request for every registered participant**.
- `startDate` is never null for story/worldMission in practice (no automatic travel for the GM lanes: `quest-acceptance.service.ts`, D-02 of BE Phase 8); `character.activeTravel` on a queued character is always a **free** travel.
- `completePendingRequest`: only positive outcome, no reject, no refund, no grade; `outcomes[]` optional per participant with `hpAfter` (1..maxLifePoints), `injuries` (added, deduplicated), `consumablesUsed` (within owned), `spellsUsed` (within remaining usages); one transaction; codes `NOT_FOUND`, `OUTCOME_NOT_PARTICIPANT`, `OUTCOME_OVERRIDE_INVALID`, `FORBIDDEN`; returns the created `[QuestResult!]!`.
- `teleportCharacter` accepts any existing POI, clears a free travel in the same operation, refuses `QUEST_IN_PROGRESS` only for an occupied standard lane, allows a character awaiting aid; audited automatically.

---

## 2. Requested for the BE Phase 10 (BE-HARD-08)

### 2.1 `PendingRequestCharacter.pendingQuest: ID` (additive)

User rule (verbatim, 2026-10-29): *«Nessun personaggio che ha accetato una quest, che sia in viaggio o in combattimento, non deve comparire nella lista dei pending che l'admin può gestire. Se sei in viaggio da una città all'altra invece questa regola non vale.»* Clarified with the user: the quest is the **standard-lane** one (`quests.pendingQuest`), whether the character is travelling to it or inside its waiting time; a free travel does not hide him.

- Field: `pendingQuest: ID` on `PendingRequestCharacter`, the id of the character's standard PendingQuest, `null` when `quests.pendingQuest` is unset. Projection next to `status.activeTravel` / `status.awaitingAid` in `pending-requests.service.ts` / `pending-requests.builder.ts`.
- Liveness: a standard-lane acceptance inserts a PendingQuest and its resolution deletes it, so the existing insert/delete trigger of `pendingRequestsUpdated` already re-emits the queue at both transitions (to confirm in the BE research: a lane cleared without deleting the document would need a trigger).
- Alternative accepted if cheaper: a boolean `standardLaneBusy: Boolean!`. The FE only needs «busy or not».

### 2.2 `completePendingRequest` refuses `QUEST_IN_PROGRESS` (user decision)

- While **any registered active participant** of the request (story: the owner; worldMission: every active character whose lane points to a PendingQuest of the same quest) has `quests.pendingQuest` set, the mutation responds `QUEST_IN_PROGRESS` (existing code, Italian message as today: «Non puoi muoverti durante una missione in corso» or a dedicated text) and **writes nothing**; pre-check plus re-assertion in the transaction filter (BE Phase 4 rule). Supersedes the BE Phase 9 note «Nessun blocco se il partecipante è in viaggio» for the busy-lane case only; a free travel still does not block the completion (the FE disables the button as UX).
- The audit record of the refused call keeps the outcome code as today.

### 2.3 Optional (question, not a request)

- Would the BE emit the queue also when a queued character's `status.location` or `status.activeTravel` changes (teleport, free travel start/end)? It would remove the FE refetches of §3.5. The FE does not depend on it.

---

## 3. FE behaviour the BE should know

1. **Cards by quest.** Entries are grouped by `quest.id`; a worldMission card lists its registered participants with «k/N» seats; the card's «Completa» sends `completePendingRequest(pendingQuestId = id of the first entry)` and `outcomes` **only for the participants the GM changed** (HP ≠ current, injuries added, consumables or spells used); untouched participants are omitted so the BE keeps their HP intact.
2. **Hidden and greyed participants.** A participant with `character.pendingQuest != null` is not listed (a story card disappears; a worldMission card shows «k presenti su N registrati» with «Completa» disabled); a participant with `activeTravel` is listed greyed with the remaining time from `endTime` against the server clock, and the card's «Completa» is disabled until nobody travels; `awaitingAid` is shown as «In attesa di soccorso» (the completion is still allowed, as today).
3. **Form data.** When the GM opens the completion form the FE reads `character(id)` of every listed participant (innkeeper read, Phase 3) to fill HP, injuries, owned loot and active spells with their usages; the override input mirrors `ParticipantOverrideInput`.
4. **Teleport.** From a row the GM drags the character's pawn on the game Map and drops it on a **city marker**: the FE calls `teleportCharacter({ id, poiId: city.markerLocation.id })` with no confirmation; inner POIs are not drop targets in this phase. A participant on a free travel can be teleported.
5. **Refetch triggers.** Because the queue does not re-emit on location/travel changes, the panel calls `pendingRequests` after an own teleport succeeds, when a listed travel's `endTime` passes, when the panel is (re)opened and on app resume. The subscription is opened when the panel opens and closed when it closes (not for the whole session).
6. **Codes mapped by the panel:** `FORBIDDEN` (panel closes), `NOT_FOUND` (card removed), `QUEST_IN_PROGRESS` (BE-HARD-08 on completion; race on teleport), `OUTCOME_OVERRIDE_INVALID`, `OUTCOME_NOT_PARTICIPANT`; everything else → «Riprova».
7. **Gate.** The plan that selects `character.pendingQuest` in the registered documents and the device E2E run after the BE Phase 10 PR is merged on BE `develop`; until then the FE codes the hiding rule against the proposed field with fakes and the schema check runs against the current `develop` without that selection.

---

## 4. Open questions for the BE

1. §2.3 — emission on location/travel change: yes/no (the FE refetches anyway).
2. Should `QUEST_IN_PROGRESS` on `completePendingRequest` carry a dedicated Italian message («Un partecipante è impegnato in una missione») or reuse the travel one? The FE maps the code, not the text.
3. Is there any case in which a story/worldMission entry has `startDate == null`? The FE treats `startDate` as informational only (order) and derives «In viaggio» from `activeTravel`.

---

## 5. UAT plan (device, after the BE Phase 10 merge)

Data per BE Phase 9 §12 (g), §13 items 8–10. **Identities (amended 2026-10-29, research C9):** the dev bypass is one cached identity per BE process whose role comes from the **BE** `.env` (the FE `DEV_AUTH_ROLE` is only the offline fallback), so the device runs the **real Twitch account promoted** with `db.users.updateOne({ twitchId: '<id>' }, { $set: { role: 'innkeeper' } })` followed by a re-login (the BE `RolesGuard` reads the JWT snapshot); the adventurers use the dev bypass with BE `DEV_AUTH_ROLE=adventurer` driven with `curl` (two identities for the worldMission: a second real account or sequential BE restarts with another `DEV_AUTH_TWITCH_ID`); the same adventurer bearer proves `FORBIDDEN` on `pendingRequests`.

1. Adventurer accepts a story and two adventurers register to a worldMission → the panel shows a story card (1) and a worldMission card (2/N) live, no restart.
2. One participant starts a free travel → greyed with the remaining time, «Completa» disabled; after arrival «Arrivato», button enabled (refetch by time).
3. One participant accepts a standard quest (hunt) → disappears from the card (BE-HARD-08 field); `completePendingRequest` from a stale client → `QUEST_IN_PROGRESS`.
4. Teleport from a row: Map opens with the character's pawn, drop on a city marker → moved, panel back with the row updated; `adventurer` calling `pendingRequests` → `FORBIDDEN`.
5. Completion of the story without changes → card gone, player receives `gmCompleted` with intact HP, title advances if it was the exact-title story; completion of the worldMission with different overrides per participant → results recap on the panel, two different `questEnd` on the players' devices.
6. Override errors: `hpAfter` 0 (slider cannot) → not reproducible; a participant deleted between form open and confirm → `OUTCOME_NOT_PARTICIPANT` inline.
