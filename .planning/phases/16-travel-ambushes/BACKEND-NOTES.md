# Phase 16 (FE) — Backend notes

Frontend companion of the BE Phase 15 (imboscate in viaggio). Branch `feat/16-travel-ambushes`; contract proved on BE `origin/develop` `9103440` (merge of BE PR #24, plan 16-07) and exercised on the device against BE `develop` `6be50d2` (BE Phases 15 and 16 merged, plan 16-08). English text, user quotes verbatim in Italian. No ids of real users, no tokens, no URIs in this file.

## 1. Contract consumed by the FE

```graphql
# QuestResultFragment (lib/graphql/fragments/quest_result_fragment.dart) — additions of this phase
kind
ambush { at nearCity { id name } reachedCity { id name } }
```

- The fragment is shared (interpolated) by `OnQuestResultReceived` (subscription), `GetQuestResult`, `ListUnacknowledgedQuestResults` and the innkeeper `CompletePendingRequest`: every result document now selects `kind` and `ambush`.
- `quest` is read as nullable and required only when `kind == quest`; a missing or unknown `kind` reads as `quest` (Phase 13 tolerant rule); an ambush result without `ambush`, or with a malformed city (missing `id` or `name`), is dropped item by item as today.
- `ambush.reachedCity` null = victory; set = defeat («Portato a <città>»).
- Schema check: 45 documents, 45/45 OK on BE `9103440` (plan 16-07); no document added.
- `ActiveTravel` consumed unchanged (`road`, `startTime`, `endTime`, `duration`, `to`): the travel rewritten after a defeat is taken as-is.

## 2. Push consumed

- `ambushDefeat` (wire `type`), personal: `id` = the character id, `title` («Imboscata!») and `body` («Sei stato sconfitto: la via torna verso <città>») rendered verbatim, `sentAt` required — a push without it is dropped, as for every category.
- Device-only toggle «Imboscate» (default on) in the Settings: it gates the system notification and the in-app banner only; the BE always sends; it never gates the reroute nor the carousel.
- Tap (system notification or banner) → Map tab with the camera on the pawn (`focusCharacterOnMap`, as `travelEnd`). No FE copy of its own, no field added to the push model.
- No push or banner on a victory (BE); the arrival is announced by `travelEnd` only (D-07).

## 3. FE behaviour the BE should know

- Grouping rule: the consecutive `kind == ambush` results at the head of the queue ordered by `resolvedAt, id` form one carousel (one parchment per ambush, chronological, «k di N»); a quest result stays one at a time, after the carousel.
- Reports of two different unacknowledged travels merge into one carousel (there is no travel id on the wire): accepted by the user (D-16), no BE change requested.
- A live `kind == ambush` arrival triggers one `unacknowledgedQuestResults` read before presenting, and exactly one more if another arrives in flight (D-12); this relies on the arrival transaction committing all the reports of the travel before the change stream emits (A1).
- «Continua» on any page acknowledges every report of the carousel: one `acknowledgeQuestResult` per id, in order, best effort (a failed ack keeps the report for the next read, as today).
- No «Missione conclusa» (`questEnd`) banner for ambush results; the «Fine quest» toggle does not apply to them.
- Rewards and XP are printed as sent (zeros on a defeat hide the lines, A2): no client branch on the outcome beyond the header ink/label and «Portato a».
- The reroute is rendered from the new `activeTravel` only (pawn from `startTime` + `duration` on the new polyline, dashed remaining route, remaining time); the FE never derives a banner from the reroute.
- Since the fragment selects `kind`/`ambush`, this branch must never run against a BE without Phase 15: every result document would fail validation (D-15).

## 4. E2E outcome (FE Phase 16, 2026-11-09)

BE `develop` `6be50d2` (BE Phases 15 and 16 merged) running locally, Android phone over USB (`adb reverse`), debug APK of this branch (`b0d173a`, rebuilt twice for plan 16-09). Test character: a fresh rookie (aarakocra) created for the session, start city Portonuovo (nearest city by road Blu Minore, 21.6 km; quest travel «Caccia: Falco», 14 km by road); the player identity on the BE through the development auth bypass by role, the GM actions from a second BE process with the innkeeper identity. Seeds by the orchestrator at DB with the BE's own write shapes (BE Phase 15 handoff §6): `status.activeTravel.ambush { at, km, attempts: 0 }` seeded whole on in-progress travels (the natural draw never hit on 21.6 km by day), `assets.wearedEquipment` / `assets.activeSpells` emptied for the forced defeats and copied from another character for the victories, `status.currentLifePoints` topped up twice, travels closed with coherent `startTime`/`endTime` shifts and the sweeps (no Redis: sweeps every 60 s). Steps 1–7 pass (`16-HUMAN-UAT.md`, step 7 optional).

- **Won ambush, free travel (step 1):** no push, no banner, `activeTravel` unchanged, HP 1000 → 800 on `characterUpdated` at once; the report held until the arrival; at the arrival `travelEnd` and one `QuestResult` `kind: ambush` with `reachedCity` null → one-page carousel «Vittoria», «Imboscata presso Portonuovo», coins and XP. User: «pass».
- **Lost ambush, quest travel (step 2):** push `ambushDefeat` («Imboscata!» / «Sei stato sconfitto: la via torna verso Portonuovo») received with the app in background; `activeTravel` rewritten from the ambush point towards Portonuovo (new road, `startTime` = the ambush instant), rendered live by the pawn and the dashed route; `quests.pendingQuest` null → the quest sheet disappeared from the Map. User: «pass».
- **Arrival after the defeat (step 3):** report with `reachedCity` set, coins and XP zero → «Sconfitta», «Portato a Portonuovo», no rewards; `acknowledgeQuestResult` on «Continua»; a cold restart re-read `unacknowledgedQuestResults` and showed nothing. User: «pass».
- **Two reports, one travel (step 4):** first ambush lost (detour towards Blu Minore, 3.9 km), second seeded on the detour and won → at the arrival two `QuestResult` delivered together, one carousel «1 di 2» / «2 di 2» in `resolvedAt` order; «Continua» on page 1 acknowledged both; nothing after a cold restart. User: «pass».
- **Toggle off (step 5):** forced defeat with «Imboscate» off: no notification, no banner; reroute and carousel unaffected. User: «pass».
- **Confirmation sheet (step 6):** «Distanza, Durata, Arrivo, Cibo, Vita» only; the quest «Viaggio» line unchanged; nothing about ambushes on the wire of `travelPreview` / `questTravelPreview`. User: «partito, foglio pass».
- **GM teleport mid-travel (step 7, optional):** a won ambush with the report held, `teleportCharacter` from the innkeeper identity → the BE cancelled the travel and delivered the held report; the carousel opened on the free Map. User: «pass».

The user's carousel finding at step 4 (FE-only, D-19, plan 16-09: peeking pages and an opening nudge) was fixed and re-checked on the device during the E2E; no BE impact.

## 5. Questions for the BE

1. Is `reachedCity` always set on a defeat and never on a victory? The FE prints «Portato a» from it and reads its absence as a victory (observed so on every step).
2. Are `rewards.coins` and `xpGained` always zero on a defeat (A2)? The FE has no client branch and hides the lines only through the zeros (observed on steps 3 and 4).
3. Does the arrival transaction insert all the reports of a travel before the change stream emits (A1)? The FE settles the live batch with one re-read (D-12); step 4 delivered the two reports together.
4. Reports of two unacknowledged travels merge into one carousel (D-16, accepted by the user, no change requested): any plan for a travel id on the report if the user ever wants them split (research C2)?
5. Detour safety — the user at step 4, verbatim: «Non posso ricevere imboscate dopo un'imboscata che ha dato esito sconfitta, il tragitto verso la città più vicina dovrebbe sempre essere sicuro. Se sono pianificate imboscate dopo quella dove sei stato sconfitto, dovrebbero venire annullate». Already honoured by the BE Phase 15 D-03 (`afterDefeat`: «nessuna imboscata sulla deviazione»); the second ambush of step 4 existed only because the orchestrator seeded it on the detour. No change requested — keep the rule pinned by a test on the BE side.
6. The GM teleport mid-travel delivered the held report (BE D-13 confirmed on the device, step 7).
7. FYI: a second BE process started for the GM identity also runs the travel and ambush sweeps and resolved seeded ambushes itself — functionally fine (idempotent on the DB state), but the `Imboscata … risolta` log lines can appear in either process.
8. FYI, outside Phase 15: on the pre-Phase-17 app a tap on a city the character does not know opens nothing, because BE Phase 16 (D-10) returns `City.relatedLore` null and the pre-17 code dereferences it; FE Phase 17 (D-11) ships the name-only sheet — FE PR order 16 then 17.
9. FYI: HP clamped at 1 on a defeat observed once (480 → 1) — consistent with «HP never below 1».

Da riportare nella UAT della BE Phase 15 a cura del lato BE (questo repo non modifica il BE).
