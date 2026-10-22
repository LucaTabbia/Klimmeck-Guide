---
status: complete
phase: 6
plan: 12
backend_ref: origin/develop (2a3449a)
updated: 2026-10-22
---

# Phase 6 - Human UAT (Android device E2E)

| Step | Expected | Result | Note |
|------|----------|--------|------|
| 1 | Off a city marker: Bacheca cell dimmed, tap does nothing; on a city marker: enabled | passed | Teleport to a forest POI: cell dimmed, tap inert; back on the city marker: enabled. Impeller SetInheritedOpacity warnings while the icon is at opacity 0.4 (note only). |
| 2 | Board in a city: that city's quests, the city's worldMissions, only the story of your exact title (from any city); completed non-repeatable absent | passed | 13 papers: 12 Talmvere quests + the legend story; rookie story absent. Needed two fixes: catalogue `itemType` set at DB on 83 loot + 145 equipment (was nulling the `quests` list); e4211cc loot items without description + prizeItem as AssetQuantity. |
| 3 | Sheets per family: enemy image + name + time; story lore scrolls + `Punti canale: saldo / costo` (red if short); job/heal time, rewards, "Consigliati"; title red if not eligible; rank slots for worldMission/boss/enemy/aid | passed | All families confirmed by the user. Fix c663be2: effect/power selected for the prize loot + LootItemCard null-safe (crash on the `aid` sheet). |
| 4 | Swipe left on an available job/heal sheet: paper tears following the finger, tick at threshold, stronger buzz at tear; switches to Map tab | passed | job and hunt variants. job (marker = city): Map paper at once, read-only sheet, no travel. hunt: BE activeTravel 1h49m, startDate null, app navigates to Map. First hunt attempt hung: Redis down, BE blocked on Bull queue.add after commit; with Redis up DIAG chain accept ok, QuestAccepted, showMap. Tear geometry (quick 261022-qkx) verified on device. |
| 5 | Map: intact paper top-left "In viaggio", later per-type label; tap opens the read-only sheet with state line; swipe does nothing | passed | Map paper 'Lavorando...' / 'In viaggio' with state line, read-only sheet on tap, swipe inert. |
| 6 | Standard lane busy: another standard quest resists and springs back, "Hai gia una missione di questo tipo in corso"; no request sent | passed | Heal resists and springs back, banner 'Hai gia una missione di questo tipo in corso', no request sent. |
| 7 | Story of your title accepted: no Map paper; torn on the Board for you, read-only; channel points drop | passed | Legend story accepted (-1000 points), torn on the Board for the owner, no Map paper. |
| 8 | worldMission accepted in parallel while story and standard lanes are busy | passed | job + story + worldMission in parallel (worldMission -5000, registered {character, title: legend}); points 10000 to 4000. |
| 9 | Boss/enemy slots of your rank full: torn for you; free hero slot still intact for a hero (D-32) | passed | Boss with 3 any-rank slots filled, paladin slot free: torn for the legend viewer, slots line paladin 0/1 (D-32 free slot still intact for the matching rank). |
| 10 | Forced rejections: halves recompose, domain banner (never technical text); after QUEST_FULL the paper turns torn | passed | Enemy slots filled at DB with the board open: recompose + domain banner, paper torn after refresh. |
| 11 | Accept story/worldMission while travelling: "Sei in viaggio: riprova all'arrivo" (or skipped) | passed | Story while travelling: travelInProgress banner, recompose, points unchanged. |
| 12 | Kill and relaunch with a lane populated: Map paper and torn story restored, no Board spinner | passed | Kill and relaunch: Map paper + torn story/worldMission restored, no Board spinner. |

## Session

- Device: Samsung SM-S938B (RZCY92B5BWW), Android 16, real Twitch login, character "Reavor" (legend, Talmvere, 10000 points; test character, no restore).
- BE: develop @ 2a3449a (Phase 8 merged via BE PR #11) + Redis via docker compose. Earlier fallback ref origin/feat/08-travel-lifecycle-travel-01 @ e9b0768 (identical schema).
- Result: 12/12 passed ("Tutto corretto").

## Notes (not failures)

- Impeller `SetInheritedOpacity` warnings while the satchel icon is disabled (opacity 0.4).
- FlutterSecureStorage "bad base-64" fallback on startup; the session is still restored.

## Follow-ups

- BE: `TravelScheduler.schedule/cancel` must bound `queue.add`/`remove` with a timeout (Redis down: WARN, travel stays valid, sweep covers; never hang the mutation); surface Redis connection errors in the boot log.
- FE: temporary DIAG debugPrints used during the session were reverted (not committed).
