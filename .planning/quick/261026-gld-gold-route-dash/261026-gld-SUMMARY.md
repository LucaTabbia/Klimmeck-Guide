---
phase: quick-261026-gld
plan: 01
requirements: [TRAVEL-02, TRAVEL-03]
commits:
  - add38ed test(travel): expect the remaining route dashes in primary gold
  - 8ba1154 feat(travel): paint the remaining route dashes in primary gold
---

# Quick 261026-gld: gold route dash Summary

The dashed route (preview and remaining part of a live travel) is now `primaryGold`; the travelled part stays `royalCrimson`. Requested by the user during the Phase 7 device UAT (step 3): "Cambierei il colore del tratteggio al colore oro principale".

## What changed
- travel_route_layer.dart: `_dashedRemaining` colour `darkWood` → `KlimmeckGuideTheme.primaryGold`; doc comment updated.
- travel_route_layer_test.dart: the two colour assertions pin `primaryGold`.
- 07-CONTEXT.md: D-06 amended in place (2026-10-26).

## Gates
- `flutter test test/screens/mainScreen/tabs/map/travel_route_layer_test.dart`: all passed (RED seen first: 2 failures).
- `flutter analyze`: 0 errors (baseline infos unchanged).
- `dart format` on the two touched files only (0 changed).
