---
status: complete
phase: 10-admin-panel-innkeeper
device: Android (USB, adb reverse tcp:3000)
be_ref: 4dc7e89
started: 2026-11-01
completed: 2026-11-01
verdict: approved
---

# Phase 10 — Device E2E (innkeeper panel)

App on the Android phone (`flutter run`, `adb reverse tcp:3000 tcp:3000`) against the local BE from `develop` (`4dc7e89`, BE Phase 10 merged) with the UAT data of plan 10-11 `user_setup`. Results are recorded only from the tester's words; notes carry no real user ids, tokens or Mongo URIs.

| Step | ROADMAP criterion | Requirements | Expected | Result | Note |
|------|-------------------|--------------|----------|--------|------|
| 1. Role gate | 1, 5 | ADMIN-01, ADMIN-07 | before the promotion Impostazioni shows no «Locanda»; after the mongosh promotion and re-login «Locanda» sits between «Notifiche» and «Account», «Esci» still last; «Apri la Locanda» opens the full-screen panel with the AppBar «Locanda» and the back arrow; the satchel is unchanged | pass | Account already innkeeper: the «before the promotion» half was not re-tested. «Locanda» and the empty panel seen. User: «aperto». |
| 2. Live queue | 2 | ADMIN-02 | an adventurer accepts a story and two adventurers register to a worldMission → a story card (title, «Storia», row «Nome · Presente») and a worldMission card («Missione mondiale», «2/N posti») appear without restarting; with no requests the panel reads «Nessuna richiesta in attesa» | pass (after fixes) | First build showed 2 cards (story entries grouped by quest). User: «dovrebbero essere 3: una per utente per la story e una unica per la world mission… completare la story per un solo utente» → `f7c6dd1`; then «pass» (3 cards). User: «quando si accetta una story o worldMission non bisogna cambiare tab e portare l'utente sulla mappa» → `9c54218` (map jump only for the standard lane). |
| 3. Free travel | 2 | ADMIN-02 | one participant starts a free travel → greyed «In viaggio · N min» counting down, «Completa» disabled; at arrival the row reads «Arrivato» and «Completa» enables without leaving the panel; no spinner at any refresh | pass (new rule) | Free travel Talmvere→Daracre, 157 min. User: «Tutto giusto» (greyed row, countdown, «Completa» off). Then rule «non voglio vedere le card su cui non posso fare nulla» → `a919ade` (travelling card hidden; worldMission only when complete). Travel shortened in the DB and closed by the sweep: «sono visibili» (cards back with «Arrivato»). |
| 4. Busy lane (BE-HARD-08) | 2, 3 | ADMIN-02, ADMIN-03 | one participant accepts a hunt → the story card disappears (or the worldMission card drops the row, shows «k presenti su N registrati» + «Un partecipante è impegnato in una missione» and keeps «Completa» disabled); `completePendingRequest` from a stale client (curl) → `QUEST_IN_PROGRESS` | pass | User: «caccia accettata»; BE: the character's `pendingQuest` set, its cards hidden (new rule). `completePendingRequest` from a stale client → `QUEST_IN_PROGRESS` «Il personaggio è impegnato in una missione in corso». Abandon not tested: «Non posso abbandonare la caccia una volta avviata (è una scelta di design)». The hunt was closed via the DB and lost (character awaiting aid) → rule «Un personaggio in attesa di soccorso blocca una quest story o worldMission» → `abaf9b4` (+ `660e7b0`). |
| 5. Teleport | 4 | ADMIN-04 | «Teletrasporta» on a row → brief inline progress → the panel closes and the Map shows only that character's pawn with its name (own pawn, route, quest markers and paper gone); drop on the same city → nothing; drop on another city → no confirmation, the panel reopens with the row updated; «Annulla» → own pawn back; changing tab during the mode → own Map back | pass | Group teleport (one «Teletrasporta» per card, `1565abe` + `616d726`): «funziona, i due personaggi sono a Talmvere». User asked for a Map marker and «Annulla» back to the panel → `25294e2`; after the rebuild: «Confermo tutto». Not observed: teleport during a free travel (the travel had already ended), tab change during the mode. |
| 6. Completion without changes | 3 | ADMIN-03 | «Completa» on the story → form with HP slider at the current value, existing injuries inactive, steppers at 0 → «Conferma» → dialog «Nessuna modifica…» → «Conferma» → recap «Richiesta completata» on the panel, card gone; the player gets the `gmCompleted` sheet with intact HP (title advances if it was the exact-title story) | pass | Story completed without changes: BE `gmCompleted`, HP 1000→1000, title rookie→adventurer, result confirmed on the phone. User: «Fatto entrambi i punti e hanno funzionato.» |
| 7. Completion with overrides | 3 | ADMIN-03, ADMIN-05, ADMIN-06 | «Completa» on the worldMission → a different HP, an added injury, a consumable and a spell used for one participant, the other untouched → the dialog lists only those changes → results recap per character (HP before → after, injuries, XP) → two different `questEnd` sheets on the players' devices | pass | worldMission completed with overrides on one participant (HP 14550→10919, injury headConcussion, 1 «Radice Curativa», 1 «Palla di fuoco»), the other untouched (1000→1000); `gmCompleted` for both. User: «Fatto entrambi i punti e hanno funzionato.» |
| 8. FORBIDDEN | 5 | ADMIN-07 | with the adventurer bearer, `pendingRequests` (curl) → `FORBIDDEN` | pass | BE restarted as adventurer: `pendingRequests` → `FORBIDDEN` «Operazione riservata al locandiere»; `me.role = adventurer`. |
| 9. Audit | 5 | ADMIN-08 | `db.admin_audit_logs.find({ action: { $in: ['completePendingRequest','teleportCharacter'] } }).sort({ _id: -1 }).limit(5)` shows the completions and the teleport of this session | pass | `admin_audit_logs`: `completePendingRequest` ok (story 19:46:33, worldMission 19:55:44), `QUEST_IN_PROGRESS` (19:28:18), 7 `teleportCharacter` of the day. BE observation: the audit target of `teleportCharacter` is the `CommonResponse` (id null), the character id sits in the args. |
| 10. Panel lifecycle | D-04, D-18 | — | background/foreground with the panel open → the list refreshes silently; back arrow closes the panel; (optional) a push tap pops the panel (accepted, P12) | pass | Queue changed via curl (remaining story completed) with the app in background; back in foreground the card had to disappear without a spinner; back arrow. Final verdict: «approved». Push tap not tried (optional). |

**Verdict:** «approved» (2026-11-01). Requirements → steps: ADMIN-01 (1), ADMIN-02 (2, 3, 4), ADMIN-03 (4, 6, 7), ADMIN-04 (5), ADMIN-05 (7), ADMIN-06 (7), ADMIN-07 (1, 8), ADMIN-08 (9): all eight pass.

## Not observed

- Step 1: the «before the promotion» half (the account was already innkeeper).
- Step 4: abandoning the hunt (by design a started hunt cannot be abandoned).
- Step 5: teleport during a free travel (the travel had already ended); tab change during the teleport mode (not reported).
- Step 10: tap on a push with the panel open (optional).

## Fix durante la UAT

All TDD (test commit first), on `feat/10-admin-panel` after `d5df824`; full `flutter test` 2852 passed and analyzer 51 issues / 0 errors / 0 warnings after the last one.

| Commits | User rule implemented |
|---------|-----------------------|
| `6c5fe5a` + `f7c6dd1` | one card per story request, a shared card only for a worldMission (`cardKeyOf`) |
| `4bf0866` + `9c54218` | the Board stays after a story/worldMission accept; the map jump is for the standard lane only |
| `635aab0` + `a919ade` + `327d83e` | the queue lists only actionable cards (every seat covered, nobody hidden, nobody travelling); a worldMission appears only when complete |
| `30870b3` + `3067699` + `1565abe` + `616d726` | one «Teletrasporta» per card, pawn «Gruppo · N», N sequential `teleportCharacter` calls |
| `cff54eb` + `25294e2` | «Modalità Locanda» badge on the Map; «Annulla» reopens the panel (`TeleportCancelled`) |
| `ba1a77d` + `abaf9b4` + `660e7b0` | a participant awaiting aid blocks (hides) the card |

## Session notes

- UAT data: two fresh characters (one per account), both teleported to Talmvere; channel points seeded on both accounts; worldMission seats lowered to 2 in the DB for the session and restored afterwards (hero 2, paladin 2, any 4); a free travel shortened and a hunt expired in the DB; a character healed in the DB after the lost hunt; one character raised to mage with an active spell and two consumables in the DB for step 7. A third, older character was unlinked from the account at the user's request and stayed out of the UAT.
- Network: the app logged «Failed host lookup: 'localhost'» (WebSocket closed) a few times with the adb tunnel and the BE up; to clarify with the user (Wi-Fi / airplane mode?). No step failed because of it.
