---
status: in-progress
phase: 09-combat-result-sheet
plan: 13
device: Android (USB, adb reverse tcp:3000)
be_ref: 8f30d1d
be_pr: 15
fe_ref: e930d4c
started: 2026-10-29
---

# Phase 9 — Device UAT (Combat Result Sheet)

Manual E2E of plan 09-13 (blocking checkpoint). The app runs on the Android phone (`flutter run`, `adb reverse tcp:3000 tcp:3000`) against the local BE from `develop` (`8f30d1d`, Phase 9 and 9.2 merged, PR #15) on `/api/graphql`. Steps of the BE Phase 9 handoff §13, the BE 9.2 handoff §9 and FE `BACKEND-NOTES.md` §4.

## Preconditions

- BE `develop` (`8f30d1d`) running locally (Mongo replica set + Redis), sweep interval at its default (60 s); the boot backfill has already marked the legacy results as acknowledged.
- FE gates passed at `e930d4c` (plan 09-13 Task 1): full `flutter test` green, `flutter analyze` ≤ 53 / 0 errors, schema check 38/38 OK against BE `8f30d1d`.
- Before the UAT, the two «Prima della UAT» commands of the BE 9.2 handoff §7 run together and in that order (acknowledge the results left pending by the old FE, then unlink users still pointing at a dead character).
- UAT data prepared live with mongosh-equivalent scripts kept outside any repo, following the BE Phase 9 handoff §12 (a)–(j) and the BE 9.2 handoff §7 (a)–(e): a job near the dev character (success); an enemy/boss with a valid `infos.enemy` the character can lose (§12 b/c, failure → aid); a second character to win the aid (rescued + rescuer success) and to fill a 2-seat boss (§12 i, 9.2 §7 d); the aid timeout back-dated (§12 h, 9.2 §7 c, death); a study with `prizes.spell` at Valantar (§12 d); a story for the GM completion (§12 f).
- A GraphQL client session of the user's choice for `sendTestPush(input: { type: questEnd, id: "<questResultId>" })` (9.2 §7 e); no tokens in the transcript.
- Notes carry no ids of real users, no Twitch ids, no tokens and no `.env` values.

## Steps

| Step | ROADMAP criteria | Requirements | Expected | Result | Note |
|------|------------------|--------------|----------|--------|------|
| 1. **Foreground on the Map** | 1, 2, 6 | COMBAT-01, 02, 05, 09 | accept the nearby `job`, stay on the Map; at the deadline the parchment opens at once, no banner; the life bar and the numbers animate; XP/level lines as expected; «Continua» closes it; kill and restart the app → the sheet does not come back (acknowledged). | pending | |
| 2. **Banner gateway** | 1, 5 | COMBAT-01, 07 | with another result due, stay on the Diario tab → banner «Missione conclusa» and no sheet; tap the banner → Map + sheet. | pending | |
| 3. **Push tap** | 1 | COMBAT-01 | app in background at the deadline → system notification → tap → Map + sheet (`questResult(id)`); then `sendTestPush(questEnd, <the acknowledged result id>)` → tap → Map only, no sheet; `sendTestPush(questEnd, <an id of another user or an unknown id>)` → Map + banner «Risultato non disponibile». | pending | |
| 4. **Never lost** | 6 | COMBAT-09 | disable app notifications in Android settings and force-stop the app; let a result be produced (another job); cold start → the sheet opens on the Map; with the «fine quest» toggle off in Impostazioni, a live result produces no banner and no system notification but the sheet still opens on the Map. | pending | |
| 5. **Queue and dismissal** | 4, 5 | COMBAT-06, 07 | produce two results close together (boss with two characters or two deadlines before a cold start) → FIFO by time with «1 di 2» then «2 di 2»; with a quest sheet open on the Map, during a pawn drag, and with the travel confirmation open the result waits and opens right after; on the sheet a tap on the dim scrim, Android back and a swipe do nothing. | pending | |
| 6. **Failure and wounded state** | 3, 8 | COMBAT-03, 04, 08, 10 | lose a fight → «Sconfitta» with the injuries in Italian, consumables and spells used (an orphan spell reads «Magia sconosciuta» if present), no rewards; on the Map «In attesa di soccorso» over the pawn, the pawn cannot be dragged, Bacheca and Negozio cells darker and inert, Diario/Biblioteca usable; on the Board (from a second account/character) the «Soccorso: …» quest shows the combat sheet (enemy, time, rank slots, k/N), no cost line. `SHOP_NOT_IN_CITY` is not reachable from the UI by design (the Shop is disabled off-city): «covered by tests» unless triggered from a GraphQL client. | pending | |
| 7. **Rescue** | 3, 7 | COMBAT-05 | a second character wins the aid → its sheet reads «Hai salvato 1 avventuriero» (rewards, XP); the wounded character gets «Sei stato salvato» with the aid as quest and no rewards; after «Continua» its pawn is already in the city and the wounded label is gone. | pending | |
| 8. **Death live, any tab** | 7 | COMBAT-08, 09 | with a wounded character and the app open on the Diario tab, trigger the aid timeout (§12 h) → the death sheet opens at once on the Diario (any result ahead of it first), dark ink, name, title and level; «Riposa in pace» → (button disabled while waiting) → only then the character-creation page; record whether the creation page ever appeared before the tap. | pending | |
| 9. **Death at cold start** | 7 | COMBAT-08, 09 | repeat with the app killed during the death; cold start → no error screen, the death sheet opens over the loader; «Riposa in pace» → creation page. | pending | |
| 10. **Spell learned and GM completion** | 3 | COMBAT-05 | the study at Valantar → «Magia appresa: …»; a story completed by the GM → «Missione completata» with «Recluta → Avventuriero» (or the title change of the data). | pending | |
| 11. **Started boss stays torn** (BE 9.2) | 8 | COMBAT-10 | a started 2-seat boss whose second participant deletes the character → the paper stays torn on the Board and the counter still shows 2/2. | pending | |
| 12. **Settings deletion while wounded** (D-13 no hold) | 8 | COMBAT-08 | delete a wounded character from Impostazioni → creation page at once, no waiting, no death sheet. | pending | |

## Session notes

