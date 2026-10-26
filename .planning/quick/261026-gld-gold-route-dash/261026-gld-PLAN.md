---
phase: quick-261026-gld
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/screens/mainScreen/tabs/map/layers/travel_route_layer.dart
  - test/screens/mainScreen/tabs/map/travel_route_layer_test.dart
  - .planning/phases/07-travel/07-CONTEXT.md
  - .planning/STATE.md
autonomous: true
requirements: [TRAVEL-02, TRAVEL-03]

must_haves:
  truths:
    - "The dashed route (preview and remaining part of a live travel) is painted in the theme's primaryGold; the travelled part stays royalCrimson"
    - "The route layer test pins the gold colour; flutter analyze has 0 errors"
  artifacts:
    - path: "lib/screens/mainScreen/tabs/map/layers/travel_route_layer.dart"
      provides: "_dashedRemaining in primaryGold"
      contains: "KlimmeckGuideTheme.primaryGold"
---

<objective>
Device UAT of Phase 7 (2026-10-26), user feedback on step 3, verbatim: "Cambierei il colore del tratteggio al colore oro principale". The dashed route (preview and remaining part) moves from `darkWood` to the theme token `primaryGold`; the travelled solid part keeps `royalCrimson`. D-06 amended in place. Executed by the orchestrator in TDD (test first, then the colour).
</objective>

<tasks>
<task type="auto" tdd="true">
  <name>Task 1: gold dashes</name>
  <files>lib/screens/mainScreen/tabs/map/layers/travel_route_layer.dart, test/screens/mainScreen/tabs/map/travel_route_layer.dart</files>
  <behavior>`travelRoutePolylines`: the remaining/preview polyline has `color == KlimmeckGuideTheme.primaryGold`; the travelled one keeps `royalCrimson`.</behavior>
  <action>RED: update the two colour assertions; GREEN: `_dashedRemaining` uses `primaryGold`, doc comment updated; `dart format` on the two files only; `flutter analyze` 0 errors.</action>
  <verify><automated>cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && flutter test test/screens/mainScreen/tabs/map/travel_route_layer_test.dart && grep -q "KlimmeckGuideTheme.primaryGold" lib/screens/mainScreen/tabs/map/layers/travel_route_layer.dart</automated></verify>
  <done>Dashes in gold, tests green, D-06 amended.</done>
</task>
</tasks>
