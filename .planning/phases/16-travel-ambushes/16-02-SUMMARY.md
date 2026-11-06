---
phase: 16-travel-ambushes
plan: 02
subsystem: push
tags: [flutter, dart, push, fcm, notifications, settings, ambush]

requires:
  - phase: 16-01
    provides: QuestResultKind / AmbushReport models (not read here; only the plan order)
provides:
  - NotificationCategory.ambushDefeat('ambush_defeat', 'ambushDefeat'), fifth value, personal, last in display order
  - Settings switch «Imboscate» (key notification-switch-ambush_defeat, default on) after «Missione annullata»
  - defaultNotificationPopups[ambushDefeat] = focusCharacterOnMap (tap -> Map tab + camera on the pawn)
affects: [16-05, 16-06, 16-07, 16-08]

tech-stack:
  added: []
  patterns:
    - "New push category = one enum value + one exhaustive switch arm + one popup map entry; storage/state/fake iterate values"

key-files:
  created: []
  modified:
    - lib/models/notification_category.dart
    - lib/screens/mainScreen/tabs/settings/components/notification_preferences_section.dart
    - lib/screens/mainScreen/components/notification_popup_registry.dart
    - test/models/notification_category_test.dart
    - test/models/push_event_test.dart
    - test/repository/services/push/data_message_handler_test.dart
    - test/repository/storage/notification_preferences_store_test.dart
    - test/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit_test.dart
    - test/screens/mainScreen/tabs/settings/components/notification_preferences_section_test.dart
    - test/screens/mainScreen/components/notification_intent_landing_test.dart

key-decisions:
  - "The defeat banner/notification render the BE title/body verbatim; PushEvent untouched, no FE copy of «Sei stato sconfitto» (D-10)"
  - "The ambushDefeat tap reuses focusCharacterOnMap exactly like travelEnd (D-02)"

requirements-completed: []

duration: 3min
completed: 2026-11-06
---

# Phase 16 Plan 02: Ambush defeat push category Summary

**`NotificationCategory.ambushDefeat` end to end: fifth personal category, settings switch «Imboscate», BE `title`/`body` shown verbatim through the unchanged `PushEvent` path, and the tap lands on the Map with the camera on the pawn.**

## Performance

- Duration: ~3 min
- Completed: 2026-11-06
- Tasks: 2 (4 commits, TDD red/green each)
- Files: 3 lib modified, 7 test modified

## Accomplishments

- `lib/models/notification_category.dart`: `ambushDefeat('ambush_defeat', 'ambushDefeat')` after `questCancelled` (now `,`); enum doc gains «`ambushDefeat` (Phase 16 D-02): sconfitta in un'imboscata, titolo e testo dal BE.». `isPersonal` and `fromWireType` unchanged (they cover it).
- `notification_preferences_section.dart`: `_labelOf` arm `NotificationCategory.ambushDefeat => 'Imboscate'`; class doc «Tre switch …» → «Uno switch per categoria di notifica …» (Boy Scout: there were four).
- `notification_popup_registry.dart`: `NotificationCategory.ambushDefeat: focusCharacterOnMap` in `defaultNotificationPopups`; comment above the map extended.
- `lib/models/push_event.dart` untouched (`git diff HEAD~2` empty after Task 1); `grep -rn "Sei stato sconfitto" lib` prints nothing.

## Task Commits

1. Task 1 RED — `ff54032` test(push): expect the ambush defeat category
2. Task 1 GREEN — `a0f04ed` feat(push): add the ambush defeat category and its toggle
3. Task 2 RED — `f2824fa` test(push): expect the ambush defeat tap to focus the pawn
4. Task 2 GREEN — `95e747f` feat(push): focus the pawn when an ambush defeat is tapped

## Tests added / changed

- `notification_category_test.dart`: «exposes the five categories in display order (D-02)»; storage key `ambush_defeat`, wire type `ambushDefeat`, `fromWireType('ambushDefeat')` added to the pinned tests; new «an ambush defeat is a personal event (D-02)».
- `push_event_test.dart`: «keeps the character id of an ambush defeat with the backend copy (D-02, D-10)».
- `data_message_handler_test.dart`: const `ambushDefeatData` (type `ambushDefeat`, title «Imboscata!», body «Sei stato sconfitto: la via torna verso Bosa», sentAt `2026-10-18T12:10:00.000Z`, id `6712a0c4e1b2c3d4e5f60718`) joins the «shows one notification for …» loop; new «shows the ambush defeat with the backend title and body (D-02, D-10)»; in `acceptPushEvent`: «drops an ambush defeat when its toggle is off (D-10)», «the ambush toggle off keeps the other categories (D-10)».
- `notification_preferences_store_test.dart`: both exact `readAll` maps gain `ambushDefeat: true`; new «stores the ambush toggle under ambush_defeat (D-02)».
- `notification_preferences_cubit_test.dart`: `loaded({…, bool ambushDefeat = true})`.
- `notification_preferences_section_test.dart`: «shows title and five labelled switches in order (D-02)» (`Imboscate` below `Missione annullata`, key `ambush_defeat`); «reflects a disabled category» map gains `ambushDefeat: true`.
- `notification_intent_landing_test.dart`: «registers the travelEnd, questEnd and ambushDefeat popups (D-02)» replaces the two-key test; new «an ambushDefeat tap only latches the camera focus on the pawn (D-02)».

## RED failures observed

- Task 1: compile failures in every touched test file — `Error: Member not found: 'ambushDefeat'` (e.g. `notification_category_test.dart:11:28`, `push_event_test.dart:71:52`, `data_message_handler_test.dart:188:43`); `Some tests failed`.
- Task 2: «an ambushDefeat tap only latches the camera focus on the pawn (D-02)» `Expected: true Actual: <false>` (`isCharacterFocusPending`); «registers the travelEnd, questEnd and ambushDefeat popups (D-02)» set mismatch; `+6 -2: Some tests failed.`
- Green in substance at first run (RED only by compilation): «the ambush toggle off keeps the other categories (D-10)» — the toggle is already per category in `acceptPushEvent`; the test pins the T-16-06 mitigation. The `readAll`/cubit/section map changes are RED only via the missing enum value too.

## Tests run

- Task 1 verify (`test/models/notification_category_test.dart test/models/push_event_test.dart test/repository/services/push test/repository/storage test/screens/mainScreen/tabs/settings`) → `+225: All tests passed!`
- Task 2 verify (`notification_intent_landing_test.dart`, `notification_tap_router_test.dart`, `main_screen_test.dart`) → `+46: All tests passed!`
- Plan verification (`test/models test/repository/services/push test/repository/storage test/screens/mainScreen/tabs/settings test/screens/mainScreen/components/notification_intent_landing_test.dart test/screens/mainScreen/main_screen_test.dart`) → `+860: All tests passed!`

## Gates

- `flutter analyze` → `50 issues found.` (all info; error/warning count 0) after each GREEN.
- `dart format` file by file on all 10 touched files: `0 changed` on every one.
- Trailer check → `0` on all four commits.

## Deviations from Plan

None - plan executed exactly as written. (The plan's bookkeeping wrote `02/8`; the orchestrator's `2/8` / `Plan: 2 of 8` was used.)

## Threat mitigations

- T-16-04: the tap only latches `requestCharacterFocus` (no sheet, no dialog, payload id unused) — pinned by the new landing test; id still filtered by `validBackendIdentifier`.
- T-16-06: the toggle filters only `acceptPushEvent` — «the ambush toggle off keeps the other categories (D-10)».

## Known Stubs

None.

## Self-Check: PASSED
