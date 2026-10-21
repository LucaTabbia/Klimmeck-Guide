---
status: in-progress
phase: 6
plan: 12
backend_ref: origin/feat/08-travel-lifecycle-travel-01 (e9b0768)
---

# Phase 6 - Human UAT (Android device E2E)

| Step | Expected | Result | Note |
|------|----------|--------|------|
| 1 | Off a city marker: Bacheca cell dimmed, tap does nothing; on a city marker: enabled | pending | |
| 2 | Board in a city: that city's quests, every worldMission, only the story of your exact title; completed non-repeatable absent | pending | |
| 3 | Sheets per family: enemy image + name + time; story lore scrolls + `Punti canale: saldo / costo` (red if short); job/heal time, rewards, "Consigliati"; title red if not eligible; rank slots for worldMission/boss/enemy/aid | pending | |
| 4 | Swipe left on an available job/heal sheet: paper tears following the finger, tick at threshold, stronger buzz at tear; switches to Map tab | pending | |
| 5 | Map: intact paper top-left "In viaggio", later per-type label; tap opens the read-only sheet with state line; swipe does nothing | pending | |
| 6 | Standard lane busy: another standard quest resists and springs back, "Hai gia una missione di questo tipo in corso"; no request sent | pending | |
| 7 | Story of your title accepted: no Map paper; torn on the Board for you, read-only; channel points drop | pending | |
| 8 | worldMission accepted in parallel while story and standard lanes are busy | pending | |
| 9 | Boss/enemy slots of your rank full: torn for you; free hero slot still intact for a hero (D-32) | pending | |
| 10 | Forced rejections: halves recompose, domain banner (never technical text); after QUEST_FULL the paper turns torn | pending | |
| 11 | Accept story/worldMission while travelling: "Sei in viaggio: riprova all'arrivo" (or skipped) | pending | |
| 12 | Kill and relaunch with a lane populated: Map paper and torn story restored, no Board spinner | pending | |
