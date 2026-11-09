# Phase 17 (FE) — Backend notes

Frontend companion of the BE Phase 16 (lore sbloccabili). Branch `feat/17-unlockable-lore`; contract proved on BE `origin/develop` `6be50d2` (merge of BE PR #25) by plan 17-09 and on the Android device by plan 17-10 (`17-HUMAN-UAT.md`). English text, user quotes verbatim in Italian. No ids of real users or characters, no tokens, no URIs, no environment values in this file.

## 1. Contract consumed by the FE

```graphql
# CharacterFragment.statusFields (lib/graphql/fragments/character_fragment.dart)
# → GetCharacter and characterUpdated through fullFields
status { … spellStates { usages recoveries spell { id } } unlockedLore }

# QuestFragment (quests, questUpdated) and QuestResultFragment
# (questResult, unacknowledgedQuestResults, questResultReceived, completePendingRequest)
enemies { quantity known enemy { id name imagePath xp } }

# QuestResultFragment, right after spellLearned
spellLearned { id name } loreUnlocked { id name type }

# CityQueries.getAllCities — unchanged, relatedLore already nullable
relatedLore { id description image }
```

- `CharacterStatus.unlockedLore: [ID!]!` is parsed into `List<String>` (`const []` when absent, non-string entries dropped, carried by `copyWith`) and used ONLY as a refetch trigger (set comparison, order ignored, duplicates impossible) and to compute the device-side «Nuovo» marks; the known-enemies set is never selected (`knownEnemies` appears nowhere in `lib`/`test`).
- `QuestEnemy.known: Boolean!` inside `enemies { quantity known enemy { … } }`: **strict on the board** (a missing or non-boolean `known` drops that quest through `Quest.tryFromJson`, never the board), **lenient on results** (the entry is dropped, the result stays). `QuestEnemy.toJson` writes it back.
- `QuestResult.loreUnlocked: [Lore!]!` selected as `{ id name type }`, lenient entry by entry (a malformed entry is dropped, the result stays); an unknown or missing `type` is kept with `type == null` and labelled «Conoscenza appresa»; the FE reuses `Lore` (`lib/models/lore.dart`), whose `type` is now read tolerantly and written back as the wire name (the `LoreType.name` shadowing was removed, D-15).
- `City.relatedLore == null` → the paper sheet with the city name and «Non conosci ancora questa città.», no `lore(id)` call; a city with lore behaves as before. `lores` is rendered as returned; a `NOT_FOUND` on `lore(id)` stays silent (`WorldMapError`, no modal).
- Registry: 45 documents, 45/45 OK against `6be50d2` (plan 17-09); `LoreQueries` unchanged (no `unlocked*` field, pinned by test); nothing else changed on the wire.

## 2. FE behaviours proved

- Library: `LibraryCubit.syncUnlockedLore(ids)` refetches `lores` only when the SET of `unlockedLore` ids changes while a book is shown (no refetch on HP ticks or any other Character change); single-flight with one trailing re-run; a completion arriving after `goToInitial` or for another book is dropped; **no loading nor error state mid-session** (the page keeps rendering and swaps the data; a failed refetch keeps the page, silent retry on the next change).
- «Nuovo» marks: computed against the device baseline of ids per character and per book (`shared_preferences`, keyed by character id + book), written after every successful load (opening and live refresh); no baseline (first opening ever for that character) → no marks; recreating the character gives a fresh baseline. Never sent to the BE.
- Map: `MainScreenCubit.refreshCities()` re-reads `cities` silently when the `unlockedLore` set changes (one read per change, never the cold-start loading); a city learnt mid-session gets its lore without a restart. A tap on the idle pawn opens the sheet of the city under it through the same path as a city tap (D-24, plan 17-12).
- Portraits: the silhouette is driven only by `known` of the strongest entry (`strongestEntryOf`), rendered as `ColorFiltered(srcIn, ink)` over the existing picture with the semantics label «Sagoma del nemico»; the result sheet renders exactly what the BE sends (no inference from `outcome`); the result lines follow the BE order of `loreUnlocked`, one per entry, after «Magia appresa».
- Boot (plan 17-11, D-22): after the Cloudinary folder preload the splash reads `lores` (server-filtered for the bearer) and downloads every `image` into the SVG cache with bounded concurrency (6 at a time) before showing the shell; a failure of that step never blocks the boot. The board warms the enemy `imagePath`s of the quests it loads in the background (never awaited).
- The branch never runs against a BE without Phase 16: `GetCharacter`, `characterUpdated`, the quest documents and the result documents fail validation there (D-14, Pitfall 9).

## 3. UAT outcome (FE Phase 17, 2026-11-09)

BE `develop` `6be50d2` running its final build on port 3001 (`adb reverse tcp:3000 tcp:3001`), Samsung phone over USB, debug APK of `feat/17-unlockable-lore` rebuilt after plans 17-11 and 17-12. **Player identity**: the development auth bypass switched to the player role on the BE process (second identity, mechanism and variable names in the BE Phase 16 handoff §3; the innkeeper identity sees every lore and every enemy in clear and was used only for the GM teleports); the study roll forced on the same process for step 6. Seeds by the orchestrator at DB outside the repo. Steps 1–7 pass, optional step 8 pass (`17-HUMAN-UAT.md`).

- **Geography at birth** (step 1): a new elf born in Ko Shaeras → `lores` returned the home city, its regions and its state only; «Bestiario», «Religioni» and «Conoscenze» blank. User: «pass».
- **Geography at arrival** (step 2): travel Ko Shaeras → Rae Thelar (shortened at DB) → `characterUpdated` carried the enlarged `unlockedLore`, the open «Luoghi» refetched `lores` once and showed the new city page live with «Nuovo», no spinner; the mark was gone at the next opening and after a cold restart. User: «partito», then «pass».
- **`City.relatedLore`** (step 3): a never-visited city came back `null` → name-only sheet; the city just reached came back with its lore without a restart (silent `cities` refresh). The user asked for the sheet to be centred and found the current city untappable under the pawn → D-23/D-24 (plan 17-12), re-verified: «pass».
- **`known` on the board** (step 4): «Caccia: Falco», never defeated → `known: false` → black silhouette, lines and «Consigliati» unchanged. User: «Ho 2 ore e 15 min di viaggio, per il resto pass».
- **First victory** (step 5): the result arrived with the enemy `known: true` and `loreUnlocked` = the Falco page → portrait in clear + «Nuova pagina del Bestiario: Falco»; the Bestiario page carried «Nuovo»; the board card was in clear after the board re-read (return to the city by GM teleport). The first attempt was lost on a 2.5 % roll → result with `known: false` and `loreUnlocked: []` → silhouette kept, no lore line (step 8, «Accettata e pass»); the rescue was done at DB by the orchestrator.
- **Study** (step 6): with the roll forced, the won `study` returned one knowledge entry → «Conoscenza appresa: Hilword Valantar», the page in «Conoscenze» marked «Nuovo». User: «pass e vai».
- **Reset** (step 7): delete + create (aarakocra born in Thengran) → birth geography only, no marks, blank books; after a GM teleport to Portonuovo the Falco card was a silhouette again. User: «pass e creato», then «pass».

Observations confirmed from the BE handoff §7: geography has no sheet (the «Nuovo» bookmark is the only signal); the backfilled characters show no marks at their first opening (no baseline, D-07).

## 4. Questions and notes for the BE

1. Is the order of `loreUnlocked` stable (research A3)? The FE renders one line per entry in the BE order.
2. Board staleness (D-09): a quest card fetched before the victory keeps `known: false` until the board re-reads (the flag is resolved per read) — accepted; in the UAT the board re-read on the return to the city. Any plan for a `questUpdated` re-emission when the viewer's knowledge changes?
3. An unknown enemy's `imagePath` is still sent and the file downloaded (the silhouette hides it, T-17-10; since plan 17-11 the board also warms it in the background) — keep (simplest, the silhouette needs the alpha) or withhold?
4. The travel confirmation sheet of an unknown destination shows no image because `City.relatedLore` is `null` (`relatedLore?.image`, already null-safe) — accepted? After the silent `cities` refresh the image appears for a city just learnt.
5. Does `characterUpdated` always carry the whole `unlockedLore` after an arrival, in the same emission as the location change (A1)? The handoff §7 a says two emissions (movement, then geography): the FE compares sets and refetched once per change in the UAT; both shapes are fine.
6. Content rule stated by the user at step 6: «Le missioni studio dovrebbero essere tutto disponibili fin dal grado rookie». Applied by the orchestrator at DB as content (29 study quests moved from adventurer/paladin to rookie), no BE code change — the quest generation rules (BE Phase 13) should honour it for the study quests generated from now on.
7. Observation at step 5: after a quest resolved at a POI the character stays on the POI and the board is reachable only from a city (earlier-phase rule, not a Phase 17 finding); the UAT returned with a GM teleport. With the player identity `teleportCharacter` is `FORBIDDEN` by design.
8. Load pattern from plan 17-11 (D-22): every cold start reads `lores` once (filtered for the bearer) and downloads every `image` with bounded concurrency; for the innkeeper that is the whole world (473 lore images) on the first boot after install, disk-cached afterwards. Nothing to do on the BE; FYI for the Cloudinary bandwidth and for a future `lores` pagination, which the FE does not expect today.
9. Step 4's 2 h 15 travel for a nearby hunt comes from the road speed factors at DB (travel phase rule): not a finding, noted for the content side.

Da riportare nella UAT della BE Phase 16 a cura del lato BE (questo repo non modifica il BE).
