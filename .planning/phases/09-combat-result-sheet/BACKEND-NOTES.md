# BACKEND-NOTES — FE Phase 9 Combat Result Sheet (handoff for the BE Phase 9.2 and record of the BE Phase 9 contract the FE consumes)

- **FE phase:** 09-combat-result-sheet (COMBAT-01..10; decisions D-01..D-22 in `09-CONTEXT.md`)
- **Date:** 2026-10-27 — written in the Phase 9 discuss, in the same session in which the BE Phase 9.2 was inserted. **Status: proposal.** The BE fixes the contract in `Klimmeck-Guide-BE/.planning/phases/09.2-quest-result-delivery-contract/09.2-CONTEXT.md` and returns it in its own `BACKEND-NOTES.md`; `src/schema.gql` on BE `develop` wins over this document.
- **Source of the consumed contract:** `Klimmeck-Guide-BE/.planning/phases/09-combat-result-admin-outcomes/BACKEND-NOTES.md` (BE Phase 9, PR #13 merged 2026-10-26) and the 9.1 amendments (PR #14).

---

## 0. TL;DR for the BE

1. **Consumed as-is from BE Phase 9:** `questResultReceived(characterId)` (full payload, no snapshot), `questResult(id)`, push `questEnd` with `data.id` = result id, the five `outcome` values, `status.awaitingAid`, `AWAITING_AID` / `SHOP_NOT_IN_CITY`, the `aid` quest on the board. Nothing in this handoff changes them.
2. **Requested for BE Phase 9.2 (user decisions 2026-10-27):**
   - a query of the **unacknowledged results of the authenticated user** (§2.1) and a mutation that **acknowledges** one result (§2.2), plus the additive field `QuestResult.acknowledgedAt` (§2.3) — so that no result sheet is ever lost (push lost, notifications disabled, force stop, death);
   - **seats of a started quest are no longer freed by the archive** (§2.4) — so that a started quest stays torn on the board until it concludes, as the user specified;
   - **the death no longer unlinks `User.currentCharacter`: the acknowledgement of the `death` result does** (§2.2, user decision 2026-10-27) — so that the death sheet always precedes the creation page, cold start included.
3. **FE behaviour the BE should know (§3):** the sheet is shown only on the Map tab (banner elsewhere), the death sheet anywhere, the creation page only after the acknowledgement (the BE keeps `currentCharacter` until then, no FE hold); the acknowledgement is sent when the player closes the sheet; the FE publishes the in-app banner itself from the subscription with the generic BE copy; several results are queued by `resolvedAt`.

---

## 1. Contract consumed (BE Phase 9)

Fragment the FE will register (name provisional):

```graphql
fragment QuestResultSheet on QuestResult {
  id
  outcome
  resolvedAt
  acknowledgedAt        # BE 9.2, §2.3 — selected only by the schema-gated plan
  character
  user
  quest { id type title }
  hpBefore
  hpAfter
  maxLifePoints
  injuriesAdded
  consumablesUsed { quantity item { ... on LootItem { id name rarity } ... on EquipmentItem { id name rarity } } }
  spellsUsed { usages spell { id name } }
  rewards { coins { gold silver copper } items { quantity item { ... on LootItem { id name rarity } ... on EquipmentItem { id name rarity } } } }
  xpBefore
  xpGained
  xpAfter
  levelBefore
  levelAfter
  titleBefore
  titleAfter
  spellLearned { id name }
  enemy { id name imagePath }
  rescuedCharacters
}

subscription OnQuestResultReceived($characterId: String!) {
  questResultReceived(characterId: $characterId) { ...QuestResultSheet }
}

query GetQuestResult($id: String!) {
  questResult(id: $id) { ...QuestResultSheet }
}
```

- `enemy.locations` is never selected (BE §14 model bug); `relatedLore`/`spells` are not populated on the result and are not needed.
- `awaitingAid { quest aidQuest since }` joins `CharacterFragment` (`status`), additive.
- Codes mapped by the FE: `NOT_FOUND` «Risultato non trovato» and `FORBIDDEN` «Questo risultato non ti appartiene» on `questResult`; `NOT_FOUND` «Personaggio non trovato» / `FORBIDDEN` on `questResultReceived` (terminal: the FE stops resubscribing); `AWAITING_AID` on `startTravel`/`travelPreview`/`acceptQuest`; `SHOP_NOT_IN_CITY` on `doTransaction`.

---

## 2. Proposal for the BE Phase 9.2

Names are proposals; the BE picks the final ones (the FE mirrors them in the schema-gated plan).

### 2.1 Unacknowledged results

```graphql
type Query {
  unacknowledgedQuestResults: [QuestResult!]!
}
```

- Results whose `user` is the **authenticated user** (not the character: a `death` result must survive the archive of its character and be readable after the new character is created) and whose `acknowledgedAt` is `null`, ordered by `resolvedAt` **ascending** (the FE queues them in that order), with a cap chosen by the BE (50 is enough).
- Any authenticated role; no innkeeper bypass (everyone sees only their own, like `questResult`).
- Called by the FE at cold start (after `me`), on every resume and after a WS reconnection. The FE deduplicates by `id` against what the subscription and the push already delivered.

### 2.2 Acknowledge

```graphql
type Mutation {
  acknowledgeQuestResult(id: String!): CommonResponse!
}
```

- Sets `acknowledgedAt = now` **only if null** (conditional update): a second call is a no-op that still answers `successful: true` (idempotent, the FE retries best-effort after a network failure).
- `NOT_FOUND` «Risultato non trovato» for a malformed or unknown id (no DB access when malformed); `FORBIDDEN` «Questo risultato non ti appartiene» for another user's result, **innkeeper included** (same policy as `questResult`).
- Not an admin action: no audit log. Called when the player presses the sheet's button (never on display, never on reception).
- **Death (user decision 2026-10-27, BE 9.2 D-12):** for a result with `outcome: death` the acknowledgement also unlinks `User.currentCharacter` (conditional: only if it still points to `result.character`) in the same transaction; the death itself no longer unlinks it. `me` / `userUpdated` keep returning the dead character's id as `currentCharacter` until the ack (the archived character stays invisible everywhere else: `character(id)`, `characterUpdated`, owner-only mutations answer `NOT_FOUND`); `createCharacter` stays refused until then. The FE awaits this acknowledgement before routing.

### 2.3 `QuestResult.acknowledgedAt`

```graphql
type QuestResult {
  acknowledgedAt: DateTime
  # … unchanged fields
}
```

- Additive, nullable, `null` at insert for every writer (outcome writer, GM completion, rescue, death, timeout). `questResultReceived` and `questResult` return it like any other field.
- Documents created before the deploy have no field: the FE asks that they do **not** flood the first cold start — the BE decides between a one-time backfill at boot (`acknowledgedAt = resolvedAt` for pre-deploy results) and a bounded list; the FE handles either.

### 2.4 Started quests keep their seats (user rule)

User, 2026-10-27: *«finché una missione non è conclusa il foglio resta strappato sulla board una volta che i posti sono pieni (e che quindi la quest è cominciata)»* and, on the edge case of a seat freed after the start, **«Il BE non libera i posti delle quest avviate»**.

- Today (BE Phase 8 D-30, plan 08-07): the archive of a character (`deleteCharacter`, death) does `$pull` of its registration on every quest; after the start (plan 09-19) the quest goes on with who remains and takes no new registration (`QUEST_FULL`). The board then shows a free seat, the FE un-tears the paper (the torn rule is «full for everyone / for rank», Phase 6 D-08) and an acceptance answers `QUEST_FULL`.
- Requested: after the start (`startedAt` set) the archive **keeps the registration as a placeholder** until the quest concludes or returns to not-started; before the start the current rule stays (seat freed, counter k/N down). Consequences the BE owns: the resolution keeps dropping archived registrants (plan 09-13 already does); when **no real participant remains**, the quest returns to not-started (the 09-19 «empty roster resets `startedAt`» rule extended to a placeholder-only roster) so a new party can form; rescuer rosters follow the same rule; `rescue.characters` (the wounded) is unchanged.
- FE: **no change** — the Phase 6 torn rule keeps the paper torn because the seats stay full; the live counter k/N (`questUpdated`) may show the placeholder seat.

### 2.5 Open questions for the BE

1. Cap and ordering of `unacknowledgedQuestResults` (ascending `resolvedAt` requested); whether an index on `questresults { user, acknowledgedAt, resolvedAt }` is added in this phase.
2. Pre-deploy results: backfill at boot or not (§2.3).
3. Whether `acknowledgeQuestResult` returns `CommonResponse` (proposed, like `abandonQuest`) or the updated `QuestResult`.
4. Whether `Quest.startedAt` should also go on the wire (not needed by the FE with §2.4; the BE may expose it for the UAT).
5. The populate of `User.currentCharacter` for an archived character: `me` and `userUpdated` must still return at least `{ id }` of the dead character until the acknowledgement (§2.2), otherwise the FE cannot tell «dead, result pending» from «no character».

---

## 3. FE behaviour the BE should know

- **Map-only presentation (D-06):** the sheet is shown only while the Map tab is visible and free (no sheet/dialog open, no pawn drag); elsewhere the player gets the in-app banner and its tap lands on the Map and opens the sheet. Results wait in a FIFO queue by `resolvedAt`.
- **Banner source (D-12):** the FE publishes the banner from the subscription event with the dedup key `questEnd|<resultId>` and the **generic BE copy** («Missione conclusa» / «La tua missione è terminata: scopri com'è andata.»); the foreground push with the same type and id is deduplicated. The «fine quest» toggle silences notification and banner, never the sheet.
- **Death (D-13/D-14):** the death sheet is shown anywhere (and unlocks the queue ahead of it); the FE acknowledges from the sheet's button and then routes to the creation page on `userUpdated(null)`, which the BE emits only at the acknowledgement (§2.2) — no FE hold. At a cold start after a death the shell boots with the dead id as current and tolerates `NOT_FOUND` on `character(id)` and the subscriptions until the unacknowledged query delivers the death sheet.
- **Push tap (D-11):** `questResult(id)` only for ids unknown locally; an acknowledged id → Map only. `NOT_FOUND`/`FORBIDDEN` → domain banner, no retry.
- **Wounded state (D-16):** `status.awaitingAid != null` → label on the pawn, pawn drag / Board / Shop disabled client-side; `AWAITING_AID` and `SHOP_NOT_IN_CITY` still mapped to a banner.
- **Aid on the board (D-17):** rendered with the combat sheet family (enemy, time, rank slots, k/N); free (`requiredPoints: null`).

---

## 4. UAT data the FE will need (after both PRs)

BE Phase 9 handoff §12 (a)–(j) as they are, plus: one result per outcome for the dev character (job → `success`; lost fight → `failure` with the aid on the board; aid won by a second character → `rescued` + `success` with `rescuedCharacters`; aid timeout → `death`; GM completion → `gmCompleted`); a result created while the app is force-stopped with push disabled (to prove §2.1); a started boss with a participant deleted (to prove §2.4 on the board). `sendTestPush(input: { type: questEnd, id: "<questResultId>" })` for the tap path.

---

## 5. Esito (FE Phase 9, 2026-10-29)

Device E2E of plan 09-13 on Android (Samsung SM S938B, USB, `adb reverse tcp:3000 tcp:3000`), app at FE `e930d4c`, against the BE run locally from `develop` **`8f30d1d`** (Phase 9 + 9.2, PR #15 merged) on `/api/graphql`, development DB, Redis in Docker. Record: `09-HUMAN-UAT.md` (12/12 pass; step 7 on the redo, step 8 observed on the Map). Session 2026-10-29 08:14–09:30 UTC.

### 5.1 What the BE delivered right

- **Boot backfill:** the first start marked the 3 legacy results as acknowledged; the first cold start of the FE was not flooded.
- **`unacknowledgedQuestResults` at cold start:** a result produced with notifications revoked (`pm revoke`) and the app force-stopped (guard, resolved 08:27:29Z) opened on the Map at the next start (step 4a); two pending results (story `gmCompleted` 08:39:45Z via `completePendingRequest`, study `success` 08:40:29Z) came back in ascending `resolvedAt` order — «1 di 2» then «2 di 2» (step 5A).
- **`acknowledgeQuestResult`:** every closed sheet was acknowledged (`acknowledgedAt` set by the button, e.g. 08:15:43Z for the 08:15:29Z job) and never reappeared after a kill + restart (step 1: 0 unacknowledged).
- **Death unlink only at the ack (BE 9.2 D-12):** live death 08:57:34Z → `currentCharacter` unlinked only at the ack 09:00:39Z (step 8); cold-start death 09:27:34Z → ack 09:29:21Z, unlink only then (step 9). The creation page never preceded «Riposa in pace»; at the cold start no error screen, the death sheet opened over the loader. After a DB revive and relink the FE re-entered the game live through `userUpdated`, without a restart.
- **Seats kept on a started quest (§2.4):** started 2-seat boss «Il Cuore della Caverna» (registrations 09:06:49Z and 09:07:57Z, started 09:08:40Z on arrival); after `deleteCharacter` of the second participant the quest stayed started with a placeholder seat (2/2 on the FE); the resolution at 09:17:34Z dropped the placeholder (`WARN … senza missione in attesa coerente: rimosso`) and produced one result for the remaining participant (step 11).
- **Push `questEnd` with the result id:** the background notification tap opened the sheet through `questResult(id)` (step 3a); `sendTestPush(questEnd, <acknowledged id>)` → Map only; `sendTestPush(questEnd, <unknown id>)` → Map + «Risultato non disponibile» (`NOT_FOUND` mapped); `sendTestPush` answered `targeted 1 sent 1` both times.
- **Outcomes end to end:** `success` (job, crime, hunt, guard, study with `spellLearned` «Scudo di Cristallo»), `gmCompleted` (story), `failure` (08:54:29Z, `awaitingAid` set, aid «Soccorso: Battuta di caccia nel Bosco di Talmvere» with 1 seat created), rescue (aid resolved 09:05:34Z → rescuer `success` with `rescuedCharacters` = 1, HP 40000 → 39950; wounded `rescued`, HP 900 → 900, no rewards — the wounded side checked in the DB only), `death` (aid lost by the rescuer, 08:57:34Z; aid timeout, 09:27:34Z).
- **Deletion while wounded:** `deleteCharacter` from Impostazioni archived with `user_request`, unlinked at once (no death result, no hold) and concluded the pending aid (step 12).

### 5.2 Rule change requested to the BE (F2)

User, 2026-10-29, on step 11 (verbatim): *«Il nemico dovrebbe venir combattuto come se ci fossero ancora entrambi i personaggi, non solo Reavor. Altrimenti se tutti se ne andassero da una missione con un mostro forte sarebbe sconfitta automatica per chi resta. Per quello lasciamo il posto pieno»*.

- **Observed today (BE 9.2 D-07):** the started 2-seat boss whose second participant deleted the character was fought at 09:17:34Z by the remaining member only; the placeholder registration was dropped at the resolution (`WARN … senza missione in attesa coerente: rimosso`).
- **Requested:** the combat of a started quest counts the archived participant's seat as if it were still there (the placeholder kept by §2.4 also takes part in the fight, with the BE choosing how its contribution is computed — e.g. a snapshot of the character at the start), so that the participants who remain are not left to an automatic defeat.
- **Routing:** BE Phase 10 or a 9.3 companion — decided 2026-10-29: BE Phase 10, requirement BE-HARD-07 / CONTEXT D-21 (the user decides with the BE side). No FE change is expected: the FE only renders the result.

### 5.3 FE items found (no BE change)

- **F1 (FE, FIXED on `feat/09-combat-result-sheet` on 2026-10-29, commits `06b9c26`..`8481cb3`):** the party counter / torn state of the own quest did not update during the own automatic travel; it read 2/2 only on arrival. User, 2026-10-29: *«Una missione risulta al completo non appena l'ultimo avventuriero la accetta, non all'arrivo sul marker»*. If the fix needs a BE event (e.g. `questUpdated` while the lane is travelling), the FE will say so in a follow-up note.
- **F3 (FE side FIXED on 2026-10-29, `3a9e6db`/`5eb3250`: a solo quest on the marker reads as started; BE side → BE Phase 10 BE-HARD-07 D-22: write the pending `startDate` atomically with the arrival and emit `characterUpdated` — or an equivalent event — when the lane changes, otherwise a party quest that starts on the last arrival keeps «In attesa del gruppo k/N» on the FE until the result):** on a solo quest the Map state label read «In attesa del gruppo» between the deadline (artificially backdated) and the resolution by the 60 s sweep; live the window is near zero.
- **Product decision (step 5B):** a banner «Missione conclusa» while the Map is busy is intended (user, 2026-10-29: «Sì: banner finché la Mappa non è libera»).

### 5.4 Notes for the BE UAT

- `teleportCharacter` is refused with `QUEST_IN_PROGRESS` while the character is in an own started quest: the Board is not reachable then, so the torn 2/2 check of step 11 was done on the Map quest sheet.
- The step-12 deletion of the wounded character concluded its pending aid; step 9 needed the aid reopened in the DB.
- UAT data actually used: a real Twitch account on the device (character `legend`, XP at the cap) and a second account through the dev bypass (a rookie created with `createCharacter`, moved with `teleportCharacter`, deleted with `deleteCharacter`); deadlines and travels shortened by backdating `startDate` / `startTime`–`endTime`; `awaitingAid.since` backdated 8 days for the timeout; the enemy «Arbusto Maligno» rescaled for the defeats and restored at the end (100 HP / 25 xp); the boss «Il Cuore della Caverna» set to 2 seats; `prizes.spell` on the study. Lesson from step 7: a rookie rescuer without a weapon cannot win an aid against a rescaled enemy, and the lost aid kills the wounded character. No ids of real users, no tokens, no `.env` values.

### 5.5 Answers observed to §2.5

1. Ordering ascending by `resolvedAt` — confirmed on the device (step 5A); the cap was not exercised.
2. Pre-deploy results — boot backfill (3 legacy results acknowledged).
3. `acknowledgeQuestResult(id: String!): CommonResponse!` on BE `8f30d1d`.
4. `Quest.startedAt` is not on the wire on BE `8f30d1d`; not needed by the FE.
5. `me` / `userUpdated` kept the dead character's id until the ack (steps 8 and 9).

Da riportare in BE .planning/phases/09.2-quest-result-delivery-contract/ (UAT) a cura del lato BE (questo repo non modifica il BE).
