---
phase: 22-companion-defeat-rest-and-recovery
plan: 14
subsystem: notifications / map
tags: [push, notification-category, ambush, companion, dedup]
requires: ["22-13"]
provides: ["NotificationCategory.ambush (legacy wire ambushDefeat)", "NotificationCategory.petRecovered", "ambush banner suppression by the live carousel"]
affects: ["22-16 (gate: BE pushes ambush / petRecovered)"]
tech-stack:
  added: []
  patterns: ["enum with legacyWireTypes accepted by fromWireType", "dedup key suppression when the sheet ground is free"]
key-files:
  created: []
  modified:
    - lib/models/notification_category.dart
    - lib/screens/mainScreen/tabs/settings/components/notification_preferences_section.dart
    - lib/screens/mainScreen/components/notification_popup_registry.dart
    - lib/screens/mainScreen/components/quest_result_presenter.dart
    - test/models/notification_category_test.dart
    - test/models/push_event_test.dart
    - test/repository/storage/notification_preferences_store_test.dart
    - test/repository/services/push/data_message_handler_test.dart
    - test/screens/mainScreen/tabs/settings/components/notification_preferences_section_test.dart
    - test/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit_test.dart
    - test/screens/mainScreen/components/notification_intent_landing_test.dart
    - test/screens/mainScreen/components/quest_result_presenter_test.dart
decisions:
  - "Enum value ambushDefeat renamed ambush (wireType 'ambush', legacyWireTypes {'ambushDefeat'}, storageKey 'ambush_defeat' unchanged) (plan default, D-30)"
  - "petRecovered placed last in display order, no popup entry: the tap lands on the Map (plan default, D-11)"
  - "Dedup key of both ambush wire types = 'ambush|<id>' through PushEvent.dedupKey (category.wireType)"
metrics:
  duration: ~25 min
  completed: 2026-11-14
---

# Phase 22 Plan 14: Ambush and «in forze» notification categories Summary

One «Imboscate» category for every ambush (`NotificationCategory.ambush`, wire `ambush`, the legacy `ambushDefeat` still accepted, the saved toggle `ambush_defeat` kept), a new personal category «Compagno in forze» (`petRecovered`, no popup), and the presenter suppresses the foreground push banner `ambush|<result id>` when a live ambush opens the carousel on the free Map.

## Tasks

| Task | Commit | Subject |
|------|--------|---------|
| 1 RED | 037a5d03 | test(notifications): expect one ambush category and pet recovered |
| 1 GREEN | 7f4af5ee | feat(notifications): one ambush category and pet recovered |
| 2 RED | 1afa2381 | test(map): expect the ambush banner suppressed by the carousel |
| 2 GREEN | c7e55998 | feat(map): hide the ambush banner when the carousel opens |
| 3 | (this commit) | docs(phase-22): record plan 14 progress |

## RED failures

- Task 1: compile errors `Member not found: 'ambush'` / `'petRecovered'` in all eight test files.
- Task 2: «a live ambush with the Map free suppresses the ambush|<id> banner (Pitfall 5, D-30)» failed with `No matching calls (actually, no calls at all)` on `suppress('ambush|result-1')`.

## Files retargeted for the rename

`ambushDefeat` → `ambush` (enum references only; JSON payloads with `'type': 'ambushDefeat'` kept as the legacy path) in: notification_category_test, push_event_test, notification_preferences_store_test, data_message_handler_test, notification_preferences_section_test, notification_preferences_cubit_test (`loaded()` gains `ambush` and `petRecovered`), notification_intent_landing_test, quest_result_presenter_test. `grep -rn "ambushDefeat" lib` prints only the enum line and the doc line of `lib/models/notification_category.dart`; the popup registry has no occurrence left (map entry and doc line rewritten).

## Green at first run

- «a live ambush away from the Map leaves the push banner alone (D-14)»: the old early return already suppressed nothing.
- «an unseen ambush arriving mid-travel opens on the Map (D-15, D-28)»: existing behaviour (the sheet ground reads `TravelCubit` idle, not the character's active travel). No new mechanism.

## Deviations from Plan

1. **The obsolete Phase 16 case «an ambush arrival on the free map suppresses nothing (D-06)» was retargeted** into the Pitfall 5 case (it pinned the opposite behaviour).
2. **Mid-travel fixture tightened in the GREEN commit:** the RED commit seeded `travellingCharacterJson()` without an active travel; c7e55998 passes `activeTravel: activeTravelJson()` so the case really covers a character on the road (test-only, no amend).
3. Extra cases beyond the plan list: a saved `ambush_defeat=false` read back for `ambush` (store, D-30); one toggle drops both wire types and a `petRecovered` toggle-off case (handler); a `petRecovered` tap lands on the Map with no popup (landing, D-11); storage keys unique across categories.
4. Bookkeeping uses `Plan: 14 of 17` (orchestrator format); the plan's own zero-padded grep would not match — expected.

## Verification

- `flutter test test/models test/repository/storage test/repository/services/push test/screens/mainScreen/tabs/settings test/screens/mainScreen/components` → +1479 all passed.
- `flutter test test/screens/mainScreen` → +1386 all passed.
- Analyzer 47 info / 0 warning / 0 error, ANALYZE_GATE_OK. All touched files formatter-clean before and after.
- Tests +13 → expected suite 4980 (full suite not run).

## Threat surface

T-22-44 mitigated (storageKey pinned by two tests); T-22-45 unknown types still null (existing tests kept). No new surface.

## Self-Check: PASSED
