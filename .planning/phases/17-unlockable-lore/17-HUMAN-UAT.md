---
status: in-progress
phase: 17-unlockable-lore
device: Android (USB, adb reverse tcp:3000)
be_ref: 6be50d2
date: 2026-11-08
verdict:
---

# Phase 17 — Device E2E (unlockable lore)

App on the Android phone against the local BE from `develop` (`6be50d2`, merge of BE PR #25 `feat/16-lore-sbloccabili`, BE Phase 16 merged, backfill run at the real boot and its one-off removed). Gate re-checked before this file was written: `git -C <BE> show origin/develop:src/schema.gql | grep -c "loreUnlocked"` → `1`. Results are recorded only from the tester's words; notes carry no ids of real users, no tokens, no Mongo URIs, no identity values (environment variable names only).

## Setup

Setup: BE `develop` with Phase 16 merged running locally (backfill run at its first boot); **player identity** switched on the BE process as described in the BE Phase 16 handoff — the dev bypass is the innkeeper, who sees every lore and every enemy in clear, so every LORE step below runs as the player (D-02, D-19); Samsung via USB with `adb reverse tcp:3000 tcp:3000` (or `tcp:3000 tcp:3001` when the BE runs on 3001); APK of `feat/17-unlockable-lore` (it selects `unlockedLore`/`known`/`loreUnlocked` and must never run against a BE without Phase 16, D-14); DB tricks by the orchestrator following the BE handoff (quest with a never-defeated strongest enemy, study roll forced through `LORE_STUDY_CHANCE`, shortened travel, character moves); never printed. The FE Phase 16 UAT (16-08) runs in the same session from its own APK and is recorded in the Phase 16 files.

## Player identity

- Mechanism (BE Phase 16 handoff `origin/develop:.planning/phases/16-lore-sbloccabili/BACKEND-NOTES.md` §3, variable names only): environment variables of the BE **process** (never the `.env` file), the BE restarted with them — `DEV_AUTH_ROLE` set to the player role (`adventurer`), `DEV_AUTH_TWITCH_ID` (the twitchId of the owner of the test character; value never written here), `DEV_AUTH_ENABLED` and `DEV_AUTH_ACCESS_TOKEN` as in the existing dev configuration (values never written here); `LORE_STUDY_CHANCE` set to `1` on the same process for step 6 (default 0.5: with it the study repeats until the roll succeeds).
- Rule: **every LORE step runs as the player; the innkeeper sees everything** — with `DEV_AUTH_ROLE` on the innkeeper role every enemy is `known: true`, every lore and every city is visible, and the run proves nothing of Phase 17 (RESEARCH Pitfall 8, T-17-31, handoff §7 d).
- With the player identity `teleportCharacter` answers `FORBIDDEN` (innkeeper-only): arrivals go through a real travel with `status.activeTravel.endTime` moved into the past (the sweep completes it) or a temporary innkeeper restart used only for the teleport (handoff §3).

## Session data (known on 2026-11-08)

Field names only, from the BE Phase 16 handoff §4 and `17-09-SUMMARY.md` §Step 3; no ids, no secrets. Every seed is a script of the orchestrator outside the repo, with the same write shapes as the BE; the characters change stream re-emits `characterUpdated` on every update.

- BE: merged `develop` `6be50d2` running from its final build on port **3001** (no backfill module); tunnel `adb reverse tcp:3000 tcp:3001` (the phone still talks to `localhost:3000`).
- (a) Empty the knowledge: `status.unlockedLore` and `status.knownEnemies` set to `[]` on the test character (one `$set` of the two fields) — the Library empties live, every portrait turns to a silhouette at the next read.
- (b) Study roll: `LORE_STUDY_CHANCE` at `1` on the BE process (see Player identity), then a `study` won without a spell → one lore learnt, `loreUnlocked` carries it.
- (c) Arrival on a city: moving `status.location` at DB unlocks nothing (it is not an arrival). Use the GM teleport (`teleportCharacter`, innkeeper bearer) or a real travel to the city marker with `status.activeTravel.endTime` moved into the past: the sweep completes it within one interval and the city geography (city lore + its regions + its state) enters the set. The Phase 15 UAT shifted `startTime` and `endTime` together to keep the travel coherent.
- (d) Unknown city on the Map: `$pull` the city lore id from `status.unlockedLore` → `City.relatedLore` back to `null` → the FE shows «Non conosci ancora questa città.».
- (e) Darkened portrait: `$pull` the enemy id from `status.knownEnemies` → that exact enemy is `known: false` at the next read (D-03: the exact enemy, not its species).
- (f) Existing characters already carry the knowledge written by the backfill of 2026-11-08 (first boot: 3 characters, 2 updated, 8 lore, 1 enemy, 1 without city; second boot idempotent) — geography of the city they stand on + lore and enemies of their won outcomes. A from-scratch run uses (a) or a new character (step 1 creates one).
- (g) Checks at DB: `characters.status.unlockedLore` / `status.knownEnemies` of the character; `questresults.loreUnlocked` of the last result. GraphQL probe with the player bearer: `{ lores { id name type } cities { id name relatedLore { id } } }`.
- Observations from the handoff §7: an arrival that teaches may emit two `characterUpdated` (movement, then geography) — the FE compares sets and refetches once per change; geography has no sheet (the «Nuovo» bookmark is the only signal, step 2); the line «Nuova pagina del Bestiario: <nome>» appears only when that page was still closed before the victory (step 5); board staleness accepted (`known` resolved per read, D-09): the board must re-read before step 5's last check.

### Session notes (2026-11-08)

_To be filled at Task 3 from the orchestrator's seeds and the user's words — nothing recorded yet._

Device notes (user memory): `flutter run` may lose the device in background (relaunch from the phone); «bad base-64» secure-storage log is benign; screen off → `adb shell svc power stayon usb`; port 3000 busy → `PORT=3001` + `adb reverse tcp:3000 tcp:3001`.

## Steps

| Step | Requirements | Decisions | Expected | Result | Note |
|------|--------------|-----------|----------|--------|------|
| 1 | LORE-01, LORE-03 | D-02, D-06, D-07 | New character (player identity): open the Library → «Luoghi» shows only the home city, its regions and its state, with no «Nuovo» on this first opening; the empty sections are hidden; «Bestiario», «Religioni» and «Conoscenze» each show «Le pagine di questo libro sono ancora bianche.» (LORE-01, LORE-03; D-02, D-06, D-07). |  |  |
| 2 | LORE-01 | D-05, D-07 | With «Luoghi» open, travel to a never-visited city (travel time shortened by the orchestrator): at the arrival its page (and its region/state when new) appears without spinner and marked «Nuovo»; close the book and reopen it → no mark; cold restart and reopen → still no mark (LORE-01; D-05, D-07). |  |  |
| 3 | LORE-03 | D-11 | Map: tap a never-visited city → the paper modal shows only its name and «Non conosci ancora questa città.» (no image, no description); without restarting, tap the city just reached in step 2 → its lore as before (image, name, description) (LORE-03; D-11). |  |  |
| 4 | LORE-02 | D-08 | Board: open a quest whose strongest enemy the character never defeated → the portrait is a full black silhouette, the «Nx nome» lines and the «Consigliati» are unchanged (LORE-02; D-08). |  |  |
| 5 | LORE-02, LORE-01 | D-09, D-10 | Win that quest (orchestrator seeds the outcome path as in the BE handoff) → the result sheet shows the portrait in clear and «Nuova pagina del Bestiario: <nome>» after «Magia appresa» (when present); the «Bestiario» shows the page marked «Nuovo»; after the board re-reads, the same enemy's portrait on a quest card is in clear (LORE-02, LORE-01; D-09, D-10). |  |  |
| 6 | LORE-02 | D-10 | Win a study quest with the roll forced → «Conoscenza appresa: <nome>» on the result sheet; the page appears in its book (LORE-02; D-10). |  |  |
| 7 | LORE-03 | D-07, BE D-01 | Delete the character and create a new one → the Library is back to the birth geography only, no «Nuovo» marks, the enemies of step 4 are silhouettes again (LORE-03; D-07, BE D-01). |  |  |
| 8 | LORE-02 (optional) | D-09 | (optional) Lose against an unknown enemy → the silhouette stays on the result sheet and no lore line appears (LORE-02; D-09). |  |  |

Requirement ↔ step map: LORE-01 (1, 2, 5), LORE-02 (4, 5, 6), LORE-03 (1, 3, 7); step 8 optional. The trailing-refresh race (D-05), the dropped stale completion (D-19) and the «Nuovo» colours per book have no reliable device path or are cosmetic: covered by the 17-06/17-07 tests («changes during a refresh in flight run one trailing refresh (D-05)», «a refresh completing after goToInitial is dropped (D-05, D-19)»).

## Verdict

_Pending the device run (Task 2); written at Task 3 from the user's words only._
