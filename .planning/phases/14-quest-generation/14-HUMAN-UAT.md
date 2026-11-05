---
status: in-progress
phase: 14-quest-generation
device: Android (USB, adb reverse tcp:3000)
be_ref: 162c1f5
date: 2026-11-05
---

# Phase 14 — Device E2E (quest generation)

App on the Android phone against the local BE from `develop` (`162c1f5`, merge of PR #19 `feat/13-generazione-quest`, BE Phase 13 merged). Gate re-checked before this file was written: `git -C <BE> show origin/develop:src/schema.gql | grep -c "QuestEnemy"` → `3`. Results are recorded only from the tester's words; notes carry no ids of real users, no tokens, no Mongo URIs.

## Setup

Setup: BE `develop` with Phase 13 merged running locally, restarted by the user following the BE handoff runbook (boot migrations `enemy` → `enemies`, dungeon enrichment, jewels' `accessoryUseTypes`); Samsung via USB with `adb reverse tcp:3000 tcp:3000`; the device account is innkeeper (Locanda); optional DB data written by the user with placeholders only (never printed): a boss with `prizes.pet`, an enemy with a Cloudinary `imagePath`, a result with `rewards.pet`.

### Session notes (2026-11-05)

- The user's BE already runs the merged code from `dist/` on port **3001** (first real boot 2026-11-05; boot migrations applied: 167 generated quests, 40 dungeons staged, 22 legendary, 42 jewels). No BE restart is needed for this session.
- Samsung over USB with the tunnel `adb reverse tcp:3000 tcp:3001` (the phone still talks to `localhost:3000`).
- The board already holds ~167 generated quests (target = number of cities): «Genera missioni» is expected to answer «Nessuna missione da generare» (`created = 0`) unless a generated quest was concluded first. New generated quests appear only when the board tab is reopened (no subscription event, BE D-18).
- The optional DB data (steps 3-pet, 8, 9) are written by the orchestrator with read/write scripts at the user's request, never by the executor. Field names (from the BE Phase 13 handoff on BE `origin/develop`, §3 and §9):
  - quest enemies: `infos.enemies[]` = `{enemy, quantity}` (for dungeons the list order = the stage order);
  - an enemy is generable only with `Enemy.legendary: false`;
  - companion prize / reward: `prizes.pet` (quest) and `rewards.pet` (result) = the ObjectId of a pet with `sellable: false`;
  - portrait: `Enemy.imagePath` = an `https://…` URL or a Cloudinary `v<n>/…` path (all enemies carry `assets/images/…` placeholders today, hidden by D-03).

Device notes (user memory): `flutter run` may lose the device in background (relaunch from the phone); the «bad base-64» secure-storage log is benign; screen off → `adb shell svc power stayon usb`; port 3000 busy → `PORT=3001` + `adb reverse tcp:3000 tcp:3001`.

## Steps

| Step | Requirements | Decisions | Expected | Result | Note |
|------|--------------|-----------|----------|--------|------|
| 1 | QGEN-03 | D-08, D-09 | Settings → Locanda: «Genera missioni» is visible at the top, above the queue (also with «Nessuna richiesta in attesa»). Tap → dialog «Generare nuove missioni nel mondo?» → «Annulla»: nothing happens. Tap again → «Genera» → the button is disabled while the call runs → SnackBar «Generate N missioni» / «Generata 1 missione» / «Nessuna missione da generare» (QGEN-03; D-08, D-09). | | |
| 2 | QGEN-01, QGEN-05 | D-02, D-04, D-05 | Board (reopen the tab, BE D-18) → a generated `enemy` quest: the sheet shows the announcement under the title (italic), the portrait only if the enemy has a Cloudinary path, the «Nx nome» lines (e.g. «3x Goblin», «1x Capo goblin») in the order of the title, «Consigliati» when the quest has recommended loot, one slot line of the rank; nothing marks it as generated (QGEN-01, QGEN-05; D-02, D-04, D-05). | | |
| 3 | QGEN-01 | D-06 | A generated `boss` quest → the enemy name (bare, quantity 1), party slot lines (2–6 seats of the rank); optional: «Compagno in premio: <nome>» when the user set `prizes.pet` at DB (QGEN-01; D-06). The pet part is optional. | | |
| 4 | QGEN-01, QGEN-04 | — | A fixed dungeon (enriched, 2–4 stages) → combat family, lines in stage order, «Consigliati» (QGEN-01, QGEN-04). | | |
| 5 | QGEN-02 | D-07 | Resolve that dungeon (accept + resolution, or GM completion from the Locanda) → the result sheet lists the enemies fought («Nx nome») and «Esplorazione: tappa k di N»; a victory shows all the stages (QGEN-02; D-07). | | |
| 6 | QGEN-04, QGEN-05 | D-11 | A fixed `crime` or `guard` quest sheet → service family (no enemy column) with its announcement; no alignment anywhere (QGEN-04, QGEN-05; D-11). | | |
| 7 | QGEN-06 | D-12 | Journal → tap a ring and a necklace (owned or worn) → «Uso: attacco» / «Uso: difesa» / «Uso: attacco e difesa»; a helm shows no «Uso» line; the same in the shop item sheet if a jewel is on sale (QGEN-06; D-12). | | |
| 8 | QGEN-01 | D-03 | Portrait: an enemy whose `imagePath` the user set to a Cloudinary path/URL shows its portrait on the quest sheet; an enemy still on the placeholder `assets/images/…` shows only the name (QGEN-01; D-03). | | |
| 9 | QGEN-02 | D-07 | Optional: a result with `rewards.pet` shows «Compagno ottenuto: <nome>» (QGEN-02; D-07). | | |

Requirement ↔ step map: QGEN-01 (2, 3, 4, 8), QGEN-02 (5), QGEN-03 (1), QGEN-04 (4, 6), QGEN-05 (2, 6), QGEN-06 (7). Steps 3-pet and 9 are optional and never block a requirement. `FORBIDDEN` (non-innkeeper) is not reachable on the device: covered by the 14-08 widget tests.

### Things to look at during the run (from the review fixes)

- Boss sheet with coins + prize item + companion: the card stays square, the coins column narrows to 35% of the row and the «Compagno in premio» line takes the rest (max 3 lines, ellipsis) — WR-01; rows without both an item and a companion look as before.
- A named enemy next to an unnamed DB entry shows «1x <nome>» instead of the bare name (IN-04).
- With TalkBack the «Ritratto del nemico» label is announced only once a raster portrait is shown (IN-01).
