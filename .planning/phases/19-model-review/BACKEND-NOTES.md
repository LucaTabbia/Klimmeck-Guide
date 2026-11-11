# Phase 19 (FE) — Backend notes

Frontend companion of the BE Phase 19 (revisione dei modelli) and of the BE quick task 261111-enm (enemy quests single-player). Branch `feat/19-model-review`; contract proved on BE `origin/develop` `48b20701` (merge of BE PR #33) by plans 19-10..19-12 and on the Android device by plan 19-13 (`19-HUMAN-UAT.md`). English text, user quotes verbatim in Italian. No ids of real users or characters, no secrets, no URIs, no environment values in this file.

## 1. Contract consumed by the FE

```graphql
# CharacterFragment.statusFields — the single spell list (status.spells is no longer selected)
spellStates { usages recoveries active spell { …SpellFragment.fields } }

# CharacterFragment.assetsFields (assets.activeSpells is no longer selected)
wornEquipment { head chest legs arms leftHand rightHand firstAccessory secondAccessory feet }
pet { …PetFragment.fields }
ownedPets { xp currentLifePoints pet { …PetFragment.fields } }

# PetFragment.fields (character, shop pool, quest prizes)
id name speedModifier sellable buyPrice { … } sellPrice { … }
maxXp attack { …DamagesFragment.fields } defense { …DamagesFragment.fields } rarity

# QuestResultFragment.fields, right after xpAfter
petXpGained

# lores, lore, cities.relatedLore
imagePath
```

- `spellStates` is the only source of spells: known = every entry, equipped = `active`, usages and recoveries from the same entry; the full `SpellFragment.fields` are selected inside each state.
- The nine worn slots are one list shared by `character` / `characterUpdated` and by the `equipment(id)` query; the ninth is `feet`.
- The equip request sends the enum name as the slot value: `slotType: feet` for boots (`SlotType.feet`). No other variable changed in any mutation or subscription.
- `ownedPets` is read as entries; `currentLifePoints` is selected and parsed, displayed nowhere (FE D-18).
- `Pet.rarity` is read as nullable: an absent or unknown rarity leaves the name in the usual ink.
- NOT selected by the FE: `Pet.relatedLore` (the lore of a pet reaches the app through `status.unlockedLore`), `Pet.imagePath`, `Pet.maxLifePoints`, `Enemy.weaknesses`, enemy `spells` and `locations`, `PointOfInterest.type`. `LocationFragment.fields` stays `id location`.
- Registry: 46 documents, 46/46 OK against `48b20701` (plans 19-11 and 19-12, unchanged after the UAT quick task).

## 2. FE behaviours proved

- Lenient parsers: unknown weakness, POI type and damage type names are dropped from their list; a malformed owned pet, owned item, worn item, shop pool entry or city is dropped alone; an unknown title or spell energy → `null`; `active` absent → `false`; `petXpGained` absent or negative → 0.
- Spells: the slots follow the order of `spellStates` (learning order) for the server view and for the optimistic one; the slot count is `maxActiveSpells` as served.
- Companion: the experience is printed as served («Esperienza: N / maxXp», no cap and no arithmetic on the FE, hidden without a `maxXp`); the companion life is displayed nowhere; «Attacco: …» and «Difesa: …» are hidden when their list is empty; the name is drawn in the rarity colour of the item cards.
- Result sheet: «Il tuo compagno guadagna N PE» only when `petXpGained` is above 0, independent of the character xp line.
- No window reader is left: the branch must never run against a BE without Phase 19 (every character, shop, result and lore query would be rejected).
- Changed during the device UAT (quick task 261111-enm, mirror of the BE twin): an `enemy` quest is judged with one rank-free seat whatever the wire carries, acceptable by any rank at or above `minTitle` while nobody has taken it; its sheet draws no seats row and no party counter, only «Titolo minimo: …». `boss` keeps its rank-exact seats. No fragment changed: the seats still travel.

## 3. UAT outcome (FE Phase 19, 2026-11-11)

BE Phase 19 code on the orchestrator's machine with the migrated data and the pet content (`develop` `48b20701`; for the last three checks the BE quick-task branch `fix/enemy-quests-single-player`), port 3001, debug APK of the dev flavor built from the FE branch. Verdict: **complete**, steps 1–11 pass, optional 12–14 skipped, extra checks A, B, C pass.

- Pets after the content script: every shop row seen had «Difesa», «Attacco» where the pet has one, and the name in its rarity colour (a common and an uncommon pet were told apart).
- Purchase: a bought pet became an owned entry with `xp` 0 and full life (200); its lore entered `unlockedLore` in the same write. With a non-innkeeper character the Library showed the new page with «Nuovo» right after the purchase (unlocked lore 13 → 14).
- Journal companion: «Esperienza: 0 / 100» with the `maxXp` written at DB; equip and unequip confirmed by the stream.
- Spells: the migrated states are listed in learning order; equip and unequip confirmed without reordering; the refusal with every slot taken as before.
- Boots through `feet`: bought, worn, removed, worn again on the mannequin; a control slot too.
- `petXpGained` on a won fight with the companion equipped: 2 for 18 enemy xp, the sheet line «Il tuo compagno guadagna 2 PE» and the owned entry 0 → 2 («Esperienza: 2 / 100» in the Journal without a reload). On a defeat: 0 and no line. On a won fight without the companion: 0, no line, the entry unchanged.
- Map, Library images from the migrated `imagePath`, enemy portrait and name on the result sheet: as before.
- Enemy quests after the quick task and the alignment of the 155 open `enemy` quests at DB: a «Minaccia» above the viewer's rank is torn with «Titolo minimo: …» in red; one at or below the rank is whole and acceptable for a legend; a boss with rank-exact seats stays not acceptable for a legend.
- Not exercised: the innkeeper completion form (step 12), selling the pet (step 13), a pet as a quest prize (step 14).

## 4. Questions and notes for the BE

- Research assumptions A2, A4 and A5 were answered by the BE handoff (every known spell has a state; `OwnedPet.pet` always populated; `petXpGained` served on ambush results too). Still open from A4: is the order of `ownedPets` the purchase order? The FE lists them in the served order.
- Is `characterUpdated` always emitted after a fight with the new `xp` of the owned entry? It was on the device.
- Placeholder combat: a fight chosen as «certain» for the UAT was lost — the outcome is probabilistic and a character with heavy injuries loses fights that look safe. The step needed the enemy's life lowered at DB to be repeatable. Known placeholder, recorded for the future combat engine.
- Teleport prerequisite: the innkeeper teleport needs an accepted story or world mission (user: «Non posso fare teleport se il personaggio non ha accettato una quest story o worldMission»). Is it intended that the game master cannot move a character without one?
- Boss seats are rank-exact, unchanged by user choice: a legend finds no boss to accept where the seats are of lower ranks, so the pets offered as boss prizes are out of that character's reach.
- Pets as generated quest prizes (BE D-28) were not observed on the device in this UAT.
- Environment: the local Redis was not reachable, so timed jobs were resolved by the periodic sweeps (about 60 s late at most); nothing to change, recorded for whoever repeats the run.
- Any enum name of the new content unknown to this client is dropped from its line or list.

## 5. Product rules added during the UAT

- **Pet shops by city size (user, 2026-11-11; content at DB, no code):** «Valantar non dovrebbe vendere tutti quei pet. Andrebbero contestualizzati…» — a village sells ONE pet, a city at most 2, a capital at most 3 and always at least one; «Cavallo leggero» only in the Valan; «Cavallo da viaggio» at Cliffbreak and Bellport; the camel only in one desert village; no cat at Ko Shaeras. Applied at DB by the orchestrator: 53 cities sell pets (10 capitals, 12 cities, 31 villages).
- **Enemy quests are single-player with a minimum rank (user, 2026-11-11; quick task 261111-enm on both repos):** «Le enemy non dovrebbero avere slot, possono essere prese solo dal giocatore e solo se il rango è adatto (più alto o uguale a quello richiesto)». The FE now judges `enemy` quests like the new BE, so the FE branch must be merged after the BE quick-task PR `fix/enemy-quests-single-player`.

Da riportare nella UAT della BE Phase 19 a cura del lato BE (questo repo non modifica il BE).
