# Phase 14 (FE) — Backend notes

Frontend companion of the BE Phase 13 (quest generation). Branch `feat/14-quest-generation`; contract proved on BE `origin/develop` `162c1f5` (merge of BE PR #19). English text, user quotes verbatim in Italian. No ids of real users, no tokens, no URIs in this file.

## 1. Contract consumed by the FE

```graphql
# QuestFragment (board, quest sheets)
infos {
  description
  enemies { quantity enemy { id name imagePath xp } }
  # … other fields unchanged
}
prizes { pet { id name } }   # alongside the existing prize fields

# QuestResultFragment (result sheet)
enemies { quantity enemy { id name imagePath xp } }
stagesCleared
stagesTotal
rewards { pet { id name } }  # alongside the existing reward fields

# EquipmentFragment.fields / fieldsWithFullSpell
accessoryUseTypes             # [AccessoryUseType!] — attack | defense

mutation GenerateQuests { generateQuests { created } }
```

- The old `enemy { id name imagePath }` selection is gone from every document and model (hard replacement, no document carries both).
- Registry: 44 documents, schema check 44/44 OK against BE `162c1f5`.
- The FE never selects `relatedLore` or `locations` under an enemy (BE populate depth 1).

## 2. Error codes read

`generateQuests` (the FE reads only `extensions.code`, never the message):

| Code / condition | FE behaviour |
| --- | --- |
| `FORBIDDEN` | the Locanda panel closes with «La Locanda non è disponibile» (Phase 10 D-04) |
| `UNAUTHENTICATED` | the normal session flow (silent refresh / login) |
| link errors, timeout 15 s, unknown code, malformed payload | SnackBar «Non è stato possibile generare le missioni. Riprova.» |

Success: SnackBar «Generate N missioni» / «Generata 1 missione» / «Nessuna missione da generare» (`created = 0`). The button is disabled while the call is in flight.

## 3. FE behaviour the BE should know

- Enemy lines «Nx nome» follow the BE order of `enemies`, merged by enemy id; a lone quantity-1 enemy shows the bare name. The portrait picks the enemy with the highest `xp` (the only "strongest" rule on the FE).
- The portrait is shown only from an `https` URL or a Cloudinary `v<n>/…` path; the DB placeholders `assets/images/…` stay hidden (D-03), as does a failed download.
- A malformed `enemies` entry skips the quest on the board; in a result it is dropped (the rest of the result is shown). An orphan enemy entry disappears from the list, an orphan pet becomes null.
- The stage line prints «Esplorazione: tappa `stagesCleared ?? 0` di `stagesTotal`» only when `stagesTotal` is present.
- A pet-only reward shows the rewards section (also on a failure outcome).
- The board sees generated quests only on the next tab open (no `questUpdated` on insert, BE D-18).
- Generated quests carry no mark: they look like any other quest.
- **Since BE 13.1 (D-05, merged 2026-11-05 as BE PR #21):** `quests` is scoped server-side to the viewer's current character (open quests on the POIs of its city, marker included, the `story` quests of its exact title, the quests of its three lanes; `[]` without a current character). The FE keeps `boardQuestsFor` and `QuestMarkersLayer` filters as a defence and rereads the list in silence when `characterUpdated` changes `status.location`, `status.title` or a lane's quest (`QuestScopeListener`, quick task 261105-scp); the legend-on-hero-seat rule (BE 13.1 D-08) is mirrored in `canRegisterWithTitle` (quick task 261105-lgd).
- Rings and necklaces show «Uso: attacco / difesa / attacco e difesa» from a non-null `accessoryUseTypes`; no filter, no equip constraint.

## 4. E2E outcome (FE Phase 14, 2026-11-05)

Outcome: **complete** — steps 1–8 pass (step 8 Cloudinary half skipped by the user's decision), optional step 9 and the pet part of step 3 pass. Full record: `14-HUMAN-UAT.md`.

### 4.1 Setup

- BE ref `162c1f5` (merge of BE PR #19), run by the user from `dist/` on port 3001 after the first real boot of 2026-11-05 (167 generated quests, 40 dungeons staged, 22 legendary, 42 jewels); no restart during the session.
- Samsung SM-S938B over USB, `adb reverse tcp:3000 tcp:3001`; device account innkeeper.

### 4.2 Step outcomes relevant to the BE

- **Generation:** with the world full (167/167) `generateQuests` is expected to return `created = 0`. After the orchestrator concluded one generated quest at DB, the call returned `created = 1`: BE log `Generatore: 1 missioni create (target 167)`, audit `generateQuests` outcome `ok` target `QuestGeneration`, open generated quests back to 167/167; SnackBar «Generata 1 missione».
- **Generated `enemy` sheet:** «Minaccia: Picchiatore presso Talmvere» (rookie) — announcement, «3x Picchiatore» (quantity raised to 3 at DB for the test), «Consigliati», one rank slot line, no portrait (placeholder path).
- **Generated `boss` sheet:** «Boss: Treant presso Talmvere» (mage) — bare enemy name, 2 seats of the mage rank (user: «indica 2 posti disponibili rango mago, pass»), «Compagno in premio: Worg» from `prizes.pet` (populated by name).
- **Dungeon stages:** «Dungeon: Ankheg presso Talmvere» (4 stages: 1x Ankheg, 6x Bandito, 1x Quasit, 1x Bugbear) resolved by the BE sweepers as `outcome: failure`, `stagesCleared: 0`, `stagesTotal: 4`, enemies 1+6+1+1, HP 40000 → 38700, rewards empty → «Esplorazione: tappa 0 di 4». The character was a legend of level 20 with 40000 HP and lost at the first stage: the placeholder dungeon/combat resolver is the user's to revise (BE D-10/D-11). User: «Ho superato 0 tappe di 4. Non è un problema, l'algoritmo devo rivederlo io. pass».
- **Companion reward:** `rewards.pet` (Alce) set at DB on the unacknowledged result → «Compagno ottenuto: Alce» after an app restart, on a failure outcome.
- **Fixed `crime` / `guard`:** «Affari loschi a Chargate» and «Turno di guardia a Chargate» render with the service family and their announcement.
- **Jewels:** use types read from `accessoryUseTypes` after the BE migration — «Uso: attacco» (ring), «Uso: attacco e difesa» (necklace); helms without the line. The seeded items were catalogue items already carrying the values.
- **Portrait:** not exercised with a real path (user: «Il ritratto non mi serve, il resto facciamolo»); the placeholder hiding was seen.
- **Awaiting aid (session fact):** after the dungeon defeat the character stayed in `awaitingAid` with the aid quest «Soccorso: Dungeon: Ankheg presso Talmvere», which blocks the board (Phase 9 behaviour; user: «Sono ancora in attesa di soccorso, non posso aprire il tabellone»). The BE's only exits are a rescue by another character or the 7-day aid timeout, which ends in the character's `death`. The orchestrator cleared it by hand with the BE's write shapes to continue the UAT.

### 4.3 UAT data actually used

Written at DB by the orchestrator at the user's request, with the BE's own write shapes (fields only): `concludedAt`, `prizes.pet`, `infos.enemies[].quantity`, `assets.ownedEquipments[]`, `status.activeTravel.startTime/endTime` (shifted into the past to let the travel sweeper close the travel), `rewards.pet`, `status.location` (teleport to Chargate), `status.awaitingAid`. No `imagePath` was changed.

## 5. Questions for the BE

1. Should inserts of generated quests emit `questUpdated` so the board refreshes live (BE D-18)?
2. Is `stagesCleared` always equal to `stagesTotal` on a dungeon victory and set on every dungeon failure? (Observed on a failure: `0` of `4`.)
3. Is the `enemies` order guaranteed to be the stage order for dungeons and the title order for generated quests?
4. When will the enemy `imagePath` placeholders be replaced by Cloudinary paths (BE Phase 11 D-24)?
5. Any error code of `generateQuests` besides `FORBIDDEN`?
6. Il risolutore segnaposto delle dungeon ignora la forza del personaggio (sconfitta alla tappa 1 con 40000 HP)?
7. Dopo una sconfitta in dungeon l'attesa di soccorso blocca il tabellone: è voluto che un personaggio solo non possa fare nulla fino al soccorso o al timeout di 7 giorni?

Da riportare nella UAT della BE Phase 13 a cura del lato BE (questo repo non modifica il BE).
