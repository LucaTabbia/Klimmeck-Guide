# BACKEND-NOTES — FE Phase 9 Combat Result Sheet (handoff for the BE Phase 9.2 and record of the BE Phase 9 contract the FE consumes)

- **FE phase:** 09-combat-result-sheet (COMBAT-01..10; decisions D-01..D-22 in `09-CONTEXT.md`)
- **Date:** 2026-10-27 — written in the Phase 9 discuss, in the same session in which the BE Phase 9.2 was inserted. **Status: proposal.** The BE fixes the contract in `Klimmeck-Guide-BE/.planning/phases/09.2-quest-result-delivery-contract/09.2-CONTEXT.md` and returns it in its own `BACKEND-NOTES.md`; `src/schema.gql` on BE `develop` wins over this document.
- **Source of the consumed contract:** `Klimmeck-Guide-BE/.planning/phases/09-combat-result-admin-outcomes/BACKEND-NOTES.md` (BE Phase 9, PR #13 merged 2026-10-26) and the 9.1 amendments (PR #14).

---

## 0. TL;DR for the BE

1. **Consumed as-is from BE Phase 9:** `questResultReceived(characterId)` (full payload, no snapshot), `questResult(id)`, push `questEnd` with `data.id` = result id, the five `outcome` values, `status.awaitingAid`, `AWAITING_AID` / `SHOP_NOT_IN_CITY`, the `aid` quest on the board. Nothing in this handoff changes them.
2. **Requested for BE Phase 9.2 (user decisions 2026-10-27):**
   - a query of the **unacknowledged results of the authenticated user** (§2.1) and a mutation that **acknowledges** one result (§2.2), plus the additive field `QuestResult.acknowledgedAt` (§2.3) — so that no result sheet is ever lost (push lost, notifications disabled, force stop, death);
   - **seats of a started quest are no longer freed by the archive** (§2.4) — so that a started quest stays torn on the board until it concludes, as the user specified.
3. **FE behaviour the BE should know (§3):** the sheet is shown only on the Map tab (banner elsewhere), the death sheet anywhere with a routing hold; the acknowledgement is sent when the player closes the sheet; the FE publishes the in-app banner itself from the subscription with the generic BE copy; several results are queued by `resolvedAt`.

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

---

## 3. FE behaviour the BE should know

- **Map-only presentation (D-06):** the sheet is shown only while the Map tab is visible and free (no sheet/dialog open, no pawn drag); elsewhere the player gets the in-app banner and its tap lands on the Map and opens the sheet. Results wait in a FIFO queue by `resolvedAt`.
- **Banner source (D-12):** the FE publishes the banner from the subscription event with the dedup key `questEnd|<resultId>` and the **generic BE copy** («Missione conclusa» / «La tua missione è terminata: scopri com'è andata.»); the foreground push with the same type and id is deduplicated. The «fine quest» toggle silences notification and banner, never the sheet.
- **Death (D-13/D-14):** the death sheet is shown anywhere; the routing to the character creation on `currentCharacter: null` is held until the sheet is closed (cap ~10 s if the result has not arrived); the acknowledgement of a `death` result is sent by the user after the character is gone — the mutation must accept it (user-scoped ownership).
- **Push tap (D-11):** `questResult(id)` only for ids unknown locally; an acknowledged id → Map only. `NOT_FOUND`/`FORBIDDEN` → domain banner, no retry.
- **Wounded state (D-16):** `status.awaitingAid != null` → label on the pawn, pawn drag / Board / Shop disabled client-side; `AWAITING_AID` and `SHOP_NOT_IN_CITY` still mapped to a banner.
- **Aid on the board (D-17):** rendered with the combat sheet family (enemy, time, rank slots, k/N); free (`requiredPoints: null`).

---

## 4. UAT data the FE will need (after both PRs)

BE Phase 9 handoff §12 (a)–(j) as they are, plus: one result per outcome for the dev character (job → `success`; lost fight → `failure` with the aid on the board; aid won by a second character → `rescued` + `success` with `rescuedCharacters`; aid timeout → `death`; GM completion → `gmCompleted`); a result created while the app is force-stopped with push disabled (to prove §2.1); a started boss with a participant deleted (to prove §2.4 on the board). `sendTestPush(input: { type: questEnd, id: "<questResultId>" })` for the tap path.
