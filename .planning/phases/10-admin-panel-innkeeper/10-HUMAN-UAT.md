---
status: in-progress
phase: 10-admin-panel-innkeeper
device: Android (USB, adb reverse tcp:3000)
be_ref: 4dc7e89
started: 2026-11-01
---

# Phase 10 — Device E2E (innkeeper panel)

App on the Android phone (`flutter run`, `adb reverse tcp:3000 tcp:3000`) against the local BE from `develop` (`4dc7e89`, BE Phase 10 merged) with the UAT data of plan 10-11 `user_setup`. Results are recorded only from the tester's words; notes carry no real user ids, tokens or Mongo URIs.

| Step | ROADMAP criterion | Requirements | Expected | Result | Note |
|------|-------------------|--------------|----------|--------|------|
| 1. Role gate | 1, 5 | ADMIN-01, ADMIN-07 | before the promotion Impostazioni shows no «Locanda»; after the mongosh promotion and re-login «Locanda» sits between «Notifiche» and «Account», «Esci» still last; «Apri la Locanda» opens the full-screen panel with the AppBar «Locanda» and the back arrow; the satchel is unchanged | | |
| 2. Live queue | 2 | ADMIN-02 | an adventurer accepts a story and two adventurers register to a worldMission → a story card (title, «Storia», row «Nome · Presente») and a worldMission card («Missione mondiale», «2/N posti») appear without restarting; with no requests the panel reads «Nessuna richiesta in attesa» | | |
| 3. Free travel | 2 | ADMIN-02 | one participant starts a free travel → greyed «In viaggio · N min» counting down, «Completa» disabled; at arrival the row reads «Arrivato» and «Completa» enables without leaving the panel; no spinner at any refresh | | |
| 4. Busy lane (BE-HARD-08) | 2, 3 | ADMIN-02, ADMIN-03 | one participant accepts a hunt → the story card disappears (or the worldMission card drops the row, shows «k presenti su N registrati» + «Un partecipante è impegnato in una missione» and keeps «Completa» disabled); `completePendingRequest` from a stale client (curl) → `QUEST_IN_PROGRESS` | | |
| 5. Teleport | 4 | ADMIN-04 | «Teletrasporta» on a row → brief inline progress → the panel closes and the Map shows only that character's pawn with its name (own pawn, route, quest markers and paper gone); drop on the same city → nothing; drop on another city → no confirmation, the panel reopens with the row updated; «Annulla» → own pawn back; changing tab during the mode → own Map back | | |
| 6. Completion without changes | 3 | ADMIN-03 | «Completa» on the story → form with HP slider at the current value, existing injuries inactive, steppers at 0 → «Conferma» → dialog «Nessuna modifica…» → «Conferma» → recap «Richiesta completata» on the panel, card gone; the player gets the `gmCompleted` sheet with intact HP (title advances if it was the exact-title story) | | |
| 7. Completion with overrides | 3 | ADMIN-03, ADMIN-05, ADMIN-06 | «Completa» on the worldMission → a different HP, an added injury, a consumable and a spell used for one participant, the other untouched → the dialog lists only those changes → results recap per character (HP before → after, injuries, XP) → two different `questEnd` sheets on the players' devices | | |
| 8. FORBIDDEN | 5 | ADMIN-07 | with the adventurer bearer, `pendingRequests` (curl) → `FORBIDDEN` | | |
| 9. Audit | 5 | ADMIN-08 | `db.admin_audit_logs.find({ action: { $in: ['completePendingRequest','teleportCharacter'] } }).sort({ _id: -1 }).limit(5)` shows the completions and the teleport of this session | | |
| 10. Panel lifecycle | D-04, D-18 | — | background/foreground with the panel open → the list refreshes silently; back arrow closes the panel; (optional) a push tap pops the panel (accepted, P12) | | |
