# Phase 23: Spell Origins, Void and Shamanic Quests - Context

**Gathered:** 2026-11-15 (interactive discuss, joint with the BE Phase 24 «Origini delle magie, quest void e shamanic»; this file is authoritative for both, same numbering D-01..D-19)
**Status:** Ready for planning — branch `feat/23-spell-origins-void-and-shamanic-quests` stacked on `feat/22-companion-defeat-rest-and-recovery` (FE PR not opened yet, waits for BE PR #43); BE branch `feat/24-origini-magie-quest-void-shamanic` stacked on `fix/23-dungeon-xp-and-innkeeper-corrections` (BE PR #43 draft). **No UI phase** (same rule as the previous phases: the design contract lives in the decisions below).

<domain>
## Phase Boundary

The spells get a macro-class, the **origin**, above use and energy (origin → use → energy), and the world gets two new schools of quests, `shamanic` and `void`, that work exactly like the `magic` quest and teach a spell of their own origin. Three city types are added (`aarakocraCapital`, `dragonbornCapital`, `dragonbornVillage`), one asset is replaced (`aarakocraVillage`), two races are born in their new capital, and a spell is learned from a minimum **level** instead of a minimum xp. The backend owns every rule (origin, the pool a quest draws from, the level gate, quest generation near Necrorian, home cities); the app shows the origin, the new quest sheets and the new city markers.

Out of scope: any effect of the origin on combat (the origin is a classification: it decides which quest teaches which spell), restrictions of an origin by race or class, the real combat engine, iOS.

</domain>

<decisions>
## Implementation Decisions

### Carried forward (not re-asked)
- The backend is the source of truth (rule 4); no app chrome on gameplay (rule 1); no blocking loading in session (rule 2).
- The world lives only in the DB: origins, new spells, minimum levels, the new quests and their texts are written at DB by the orchestrator after the user's review; no content file in either repo; one-off migrators leave the repo after the real boot.
- Non-additive SDL changes are declared in the BE handoff and the FE plans that select the new fields are gated on the BE merge (schema check on the merged SDL), as in Phases 19 and 22.
- Assets with masks built on `feColorMatrix` filters are flattened with headless Chrome before the upload; the user uploads to Cloudinary and gives the new ids, wired in TDD in `lib/config/cloudinary_assets.dart`.

### Spell origin
- **D-01 (user):** every spell carries an origin; the macro-class order is origin → use → energy. The origins are three: `void`, `arcane`, `shamanic` (wire values; BE enum next to `UseType`). **Amended 2026-11-15 (user: «arcane (cambia da magic, troppo generico)»):** the origin is `arcane`, not `magic`; the quest type keeps its name `magic` and teaches the `arcane` origin.
- **D-02 (user):** every spell at DB is reviewed and given its origin «sulla base della descrizione». The orchestrator proposes the table (96 spells today), the user reviews it before the write. First reading: about 6 void, about 8 shamanic, about 82 arcane.
- **D-03 (user, «Circa 30 per origine»):** the DB is filled with new spells until `void` and `shamanic` hold about 30 spells each (about 45 new spells), covering the 9 uses with several energies per use and spread over the levels. Same fields and same balance rules as today's catalogue (power, usages, learn time, recovery); the table is reviewed by the user before the write.
- **D-04 (assumption, stated to the user):** the origin has no effect on combat, on who can learn a spell or on the spell slots. Enemy spells get an origin like any other spell.
- **D-05 (user, «Icona, ve le mando»):** the app shows the origin with an **icon**, like use and energy. The three icons arrived on 2026-11-15 (`arcaneOrigin`, `shamanicOrigin`, `voidOrigin`: each with a mask over `feColorMatrix` filters, flattened at 1000 px into `~/Downloads/<name>_flat.svg`); the UI plan needs only their Cloudinary ids.
- **D-06 (user):** Italian names of the origins: «Arcana» (`arcane`), «Sciamanica» (`shamanic`), «Vuoto» (`void`).

### Minimum level instead of minimum xp
- **D-07 (user):** «Le magie non devono più avere un minimo xp per impararle, ma un minimo livello, quindi rivedi il parametro in base alla tabella dei livelli personaggio». `minXpToLearn` is replaced by a minimum level (name fixed in the plan, e.g. `minLevelToLearn`); non-additive SDL change. Conversion of today's values through the BE level table (`level-table.ts`): the level whose `minXp` is the highest one not above the spell's xp (4 000 → level 6, 12 000 → level 10, 20 000 → level 12, 30 000 → level 15, 50 000 → level 20). The converted table goes to the user with the origin table (one review).
- **D-08:** every reader of the old parameter moves to the level: the spell draw of the quests, the rank prizes with a spell, the innkeeper prize options and their re-validation, the FE line that today reads «min xp» (`lib/utils/spell_lines.dart`). The app never computes a level: it compares nothing, it only prints the level the backend sends.

### Quest types `shamanic` and `void`
- **D-09 (user):** two new quest types, `shamanic` and `void`. «Funzioneranno esattamente come la missione magic»: same lane, same acceptance (no registration), same duration model, same study-lore pool, same spell draw at the end.
- **D-10 (user):** «Ognuna di loro insegnerà una magia sulla base del tipo (adesso magic le insegna tutte)»: the draw of a `magic` quest takes only spells of origin `arcane`, `shamanic` only `shamanic`, `void` only `void`; the level gate of D-07 applies to all three.
- **D-11 (user):** the `void` quest exists only in Necrorian. The `shamanic` quest is available in the two new capitals (Murnborim, `aarakocraCapital`; Thengran, `dragonbornCapital`) and is acceptable from rank mage up. These are DB quests like today's «Iniziazione arcana a Valantar» (the only `magic` quest at DB, `minTitle: mage`, `spellDraw: true`): the orchestrator writes one `void` quest in Necrorian and one `shamanic` quest in each capital, texts reviewed by the user.
- **D-12 (user):** «nessuna quest a Necrorian dovrebbe venir creata con rango minimo inferiore a mage»: the generator never creates a quest in or for Necrorian with a minimum title below mage (today Necrorian has no quest at DB). The `void` quest follows the same floor.
- **D-13 (user):** Italian names of the quest types: «Magia» stays, the new ones are «Rito sciamanico» and «Rito del Vuoto».
- **D-14 (user):** sheet assets: `voidSheet` / `tornVoidSheet` and `shamanicSheet` / `tornShamanicSheet`, used exactly where `magicSheet` / `magicTornSheet` are used today (`lib/models/quest/quest_paper_asset.dart`).

### Cities
- **D-15 (user):** new city types, already written at DB by the user: `690961bfe74c2f6dfc837d8f` Murnborim → `aarakocraCapital`; `690961bf31795cde80768bc7` Thengran → `dragonbornCapital`; `690961bf1bf8bb61e5f6af2f` Veg Faldir → `dragonbornVillage`. Until the BE knows the three types these cities have no size (fail-closed `isCityType`).
- **D-16 (user):** the two capitals have size `capital` (BE `CITY_SIZE_BY_TYPE`); `dragonbornVillage` is a village. On the FE map the two capitals use the same marker size as Talmvere (39); `dragonbornVillage` uses the village size (30) like `aarakocraVillage`.
- **D-17 (user):** assets: `aarakocraCapital`, `dragonbornCapital`, `dragonbornVillage` are new; the `aarakocraVillage` asset is replaced by the new file (Balkuldir stays `aarakocraVillage`).
- **D-18 (user, message during the discuss: «I dragonborn avranno come punto di origine la loro capitale e gli aarakocra avranno la loro»):** home cities of the races: dragonborn → `dragonbornCapital` (today `mountainVillage`), aarakocra → `aarakocraCapital` (today `aarakocraVillage`). Only new characters; existing characters are not moved.

### Assets
- **D-19:** the eight files handed by the user all carry one or more `<mask>` over `feColorMatrix` filters with embedded rasters: flattened on 2026-11-15 into `~/Downloads/<name>_flat.svg` (sheets at 1500 px, city markers at 1000 px, viewBox 0 0 375 375). The user uploads the eight flat files and gives the ids.

### Claude's Discretion
Wire shape and field names, where the origin sits in the BE model, how the generator recognises «a quest of Necrorian», the migrator (xp → level, origin default), the placement of the origin icon next to use and energy, final copy.

</decisions>

<canonical_refs>
## Canonical References

- BE `src/models/spell.model.ts` (`useType`, `energyDamage`, `minXpToLearn`), `src/models/enums/` (use, energy, city, quest, title types)
- BE `src/quests/outcomes/progression/level-table.ts` (the only level table)
- BE `src/quests/outcomes/resolution-loader.service.ts` (`readSpellPool`, `readStudyLorePool`, `LEARNABLE_SPELL_PROJECTION`), `src/quests/outcomes/rewards/quest-rewards.ts`, `src/quests/prizes/rank-prizes.ts`, `src/quests/guided/{mission-prizes,mission-prize-options.service,chosen-rewards}.ts`
- BE `src/quests/acceptance/quest-eligibility.ts` (type sets), `src/quests/generation/` (generator, city picker, rules)
- BE `src/cities/city-size.ts`, `src/characters/creation/race-traits.ts` (`RACE_HOME_CITY_TYPES`)
- FE `lib/models/spell.dart`, `lib/graphql/fragments/spell_fragment.dart`, `lib/utils/spell_lines.dart`, `lib/models/enums/{use_type,energy_type,quest_type,city_type}.dart`, `lib/models/quest/quest_paper_asset.dart`, `lib/config/cloudinary_assets.dart`, `lib/screens/mainScreen/tabs/map/layers/city_markers_layer.dart`
- FE `docs/rules/*.md`, BE repo rules; `tool/schema_check/`

</canonical_refs>

<code_context>
## Existing Code Insights (read on 2026-11-15)

- DB: 96 spells, keys `name, description, useType, requiredLearnTime, minXpToLearn, maxUsages, recoveryTime, energyDamage { type, power }`; uses: attack 22, control 18, defense 14, infuse 11, enhance 10, heal 7, confuse 6, charm 4, illusion 4; `minXpToLearn` from 4 000 to 50 000.
- DB: one `magic` quest («Iniziazione arcana a Valantar», 20 h, 300 xp, `spellDraw: true`, `minTitle: mage`); no quest in Necrorian; cities carry no size (derived from the type).
- BE: the generator never writes `spellDraw: true` and never creates `magic`/`study`/`heal` quests (DB content); `readSpellPool` reads the whole catalogue when `spellDraw` is true; `study` and `magic` share the study-lore pool.
- FE: `QuestType` has `magic` with label «Magia»; `CityType` holds the marker size per type (Talmvere 39, `aarakocraVillage` 30); `Spell.minXpToLearn` is nullable and printed by `spell_lines.dart`.

</code_context>

<specifics>
## Specific Ideas

- One review for the user: a single table with origin, converted level and the new spells.
- Eleven flattened files await the user's upload to Cloudinary (eight of D-19, three origin icons of D-05); the ids are the only thing still owed.

</specifics>

<deferred>
## Deferred Ideas

- Effects of the origin on combat or on who may learn a spell.
- `shamanic`/`void` quests in other cities.

</deferred>

<amendments>
## Amendments of 2026-11-15 (user, after the research) — these WIN over the text above

- **D-20 (user: «anche il tipo di quest, per evitare confusione»):** the quest type `magic` is renamed `arcane` too. The three school types are `arcane`, `shamanic`, `void`, and each draws the origin of the same name. Every mention of the quest type `magic` above reads `arcane`. Non-additive for stored data: the quests and results at DB carrying `magic` are migrated; the label «Magia» stays (D-13) and the sheet assets keep their names.
- **D-21 (user):** the eleven Cloudinary ids are given (D-05, D-19 closed):
  `arcaneOrigin` `v1794764154/arcaneOrigin_retjhh.svg`; `shamanicOrigin` `v1794764172/shamanicOrigin_vkxq6d.svg`; `voidOrigin` `v1794764163/voidOrigin_mxgwls.svg`; `aarakocraVillage` `v1794764202/aarakocraVillage_z7n1rz.svg`; `dragonbornVillage` `v1794764212/dragonbornVillage_doclsu.svg`; `aarakocraCapital` `v1794764223/aarakocraCapital_affl5r.svg`; `dragonbornCapital` `v1794764233/dragonbornCapital_uyedhh.svg`; `shamanicTornSheet` `v1794764330/tornShamanicSheet_exdyou.svg`; `voidTornSheet` `v1794764340/tornVoidSheet_h4sp3g.svg`; `shamanicSheet` `v1794764350/shamanicSheet_ytxu1n.svg`; `voidSheet` `v1794764361/voidSheet_iyocqb.svg`. No stand-in ids.
- **D-22 (user: «Le heal delle due nuove capitali diventano pari a quelle di una città (non di una capitale), idem i negozi»):** Murnborim and Thengran keep size `capital` (D-16) but their heal quests and their shops are those of a **city**. DB content written by the orchestrator; if any code derives heal or shop content from the size, the two types follow the city tier.
- **D-23 (user):** the lore of the cities whose type changed (Murnborim, Thengran, Veg Faldir) is rewritten to reflect the new type, using the world-building document for a better description. DB content, reviewed by the user.
- **D-24 (user: «Quando impari la prima magia void sblocchi la lore sul Vuoto (se non c'è è da creare. Idem vale per le altre 2 origini»):** learning the first spell of an origin unlocks the lore of that origin (three lore entries, created at DB where missing). Ruling: `Spell.relatedLore` (list of lore ids, like `LootItem.relatedLore` and the pets' lore), unlocked whenever a spell is learned through any path (quest draw, rank prize, innkeeper prize); every spell of an origin points to the lore of its origin at DB, so the first one unlocks it and the following ones change nothing. The app shows the unlock as it shows every other lore unlock.

</amendments>
