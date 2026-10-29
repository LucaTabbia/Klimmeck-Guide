---
phase: 09-combat-result-sheet
plan: 10
subsystem: ui presentation
tags: [flutter, cubit, combat, quest-result, dialog, banner, death-flow]

# Dependency graph
requires:
  - phase: 09-05
    provides: "`MapAvailabilityCubit` (`routeCoveredChanged` writer left to this plan), `InAppNotificationsCubit.suppress`"
  - phase: 09-06
    provides: "`QuestResultsCubit` (queue, showing, position/total, arrival/arrivalSerial, notice, deathAcknowledgement) + fakes"
  - phase: 09-07
    provides: "`QuestResultSheet` (continue/acknowledge-error/counter/header/deadName keys)"
  - phase: 09-08
    provides: "`CharacterUnavailable` state"
  - phase: 09-09
    provides: "`MapAvailabilityCubit` provided by `AuthenticatedShell`"
provides:
  - "`QuestResultPresenter({Key? key, required Widget child})` in `lib/screens/mainScreen/components/quest_result_presenter.dart`"
  - "`questResultNoticeTitle` + `KGNotification? questResultNoticeFor(QuestResultFailure)` in `quest_result_notice.dart`"
  - "The fourth `MapAvailabilityCubit` writer (`routeCoveredChanged`, from `ModalRoute.isCurrentOf`, post-frame, reset on dispose)"
affects: [09-11, 09-13]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Non-dismissable root parchment: `showGeneralDialog<bool>(useRootNavigator: true, barrierDismissible: false)` + `PopScope(canPop: false)`; `true` only from the button, `null` from an external pop → requeue"
    - "Widget tests with a real cubit that chains futures: create the cubit lazily inside the test body (`late final … = …`), never in `setUp`, so its pre-completed futures live in the tester's fake zone"

key-files:
  created:
    - lib/screens/mainScreen/components/quest_result_presenter.dart
    - test/screens/mainScreen/components/quest_result_presenter_test.dart
    - test/screens/mainScreen/components/quest_result_presenter_death_test.dart
    - test/screens/mainScreen/questResultsCubit/quest_result_notice_test.dart
  modified:
    - lib/screens/mainScreen/questResultsCubit/quest_result_notice.dart

key-decisions:
  - "Arrival/notice serials are seeded from the cubit state in `initState`: a presenter mounted after an arrival never replays a stale banner or notice (the queued result still opens as a sheet)"
  - "The dead character's name comes from the last `CharacterLoaded` remembered by the presenter (seeded in `initState`, updated by a listener), not from the current state, so a later `CharacterLoading`/`CharacterUnavailable` does not drop it (D-14 C7); shown only when `character.id == result.characterId`"
  - "After the dialog future completes the presenter calls `closed`/`dismissedExternally` even if it was unmounted meanwhile (only `_results.isClosed` stops it), so the cubit never keeps a stale `showing`"
  - "On dispose the presenter writes `routeCoveredChanged(false)` (same reset rule as the 09-09 writers)"
  - "Non-death button pops `true` directly; death button calls `acknowledgeDeath` and the route pops itself only when `deathAcknowledgement` turns `done`"

patterns-established:
  - "Presenter test harness: real `QuestResultsCubit` (lazy) + real `MapAvailabilityCubit`, `MockQuestResultRepository.watch` → broadcast `StreamController<QuestResult>`, `FakePendingQuestResults`, `RecordingQuestResultAcknowledger`, real buses, mocks for Travel/InAppNotifications/NotificationPreferences/Character; seed the 7 SVGs of the sheet test (emptySheet, emptyCardSheet, healEffect, helmetType, gold/silver/copper coin) or `pumpAndSettle` times out"

requirements-completed: []

# Metrics
duration: 35min
completed: 2026-10-28
---

# Phase 9 Plan 10: Quest Result Presenter Summary

**`QuestResultPresenter` turns the `QuestResultsCubit` queue into a button-only parchment on the root Navigator — at once on the free Map (with `suppress`), otherwise after a `questEnd` banner, anywhere for a death-unlocked queue — requeues on an external pop, awaits the death acknowledgement inside the route, writes the «route covered» signal and shows «Risultato non disponibile» for a refused tap lookup.**

## Performance

- **Duration:** ~35 min
- **Completed:** 2026-10-28
- **Tasks:** 2 (4 commits)
- **Files:** 5 (2 lib, 3 test)

## Accomplishments

- Gating (D-06, D-07, D-08, D-23): normal results open only when `MapAvailabilityState.isFree` and `TravelCubit.state is TravelIdle`; a queue with a `death` opens on any tab as soon as `!isRouteCovered`; nothing opens while a sheet is showing, while presenting, or after the death ack is `done` (`isAcceptingSheets`).
- Banner vs suppress (D-07 C6, D-12, checker I1): a live arrival that is itself the head and opens now → `suppress('questEnd|<id>')`; otherwise `publish(questEndEventOf(result))` only if the `questEnd` toggle is on. Port/tap results never produce a banner.
- Dialog (D-05, COMBAT-06): scrim, Android back and a 400 px drag are ignored; the button pops `true` → `closed` (best-effort ack) → next sheet with «k di N»; an external `popUntil(isFirst)` → `null` → `dismissedExternally` → reopens when allowed, never acknowledged.
- Death (D-10, D-13, D-14): button disabled while the ack is in flight, error line + retry on failure, route closes only on `done`, exactly one user refresh request, no further sheet afterwards; dead character name only for the shell's character.
- Side signals: `CharacterUnavailable` → `refetchPending()` (checker I2); a `notice` with a new serial → `publishNotice(questResultNoticeFor(failure), dedupKey: 'questResult|<id>')` (D-11).

## Task Commits

1. **Task 1 RED** — `8270e6a` test(combat): expect the quest result presenter
2. **Task 1 GREEN** — `115ea32` feat(combat): present quest results on the map
3. **Task 2 (pin)** — `f476b0e` test(combat): pin the death sheet flow

## TDD Evidence

- Task 1 RED (`flutter test …/quest_result_presenter_test.dart …/quest_result_notice_test.dart`):
  ```
  Error when reading 'lib/screens/mainScreen/components/quest_result_presenter.dart': No such file or directory
  Error: Method not found: 'questResultNoticeFor'.
  ```
- Task 2: all 9 death behaviours were already green after Task 1 (the plan's GREEN spec for Task 1 already contained the death unlock, the `done` listener, `isAcceptingSheets` and the name lookup), so they were committed as pinning tests (`test(combat): pin the death sheet flow`) as the plan allows. Mutation check before committing: removing the `isUnlockedByDeath` branch and the `isAcceptingSheets` guard from `_canPresent` made all 9 tests fail; the file was restored byte-for-byte.

## Verification

- `flutter test test/screens/mainScreen/components test/screens/mainScreen/questResultsCubit` — green
- Full suite: 2402 → **2427** tests, all passed (+3 notice, +13 presenter, +9 death)
- `flutter analyze`: **52 issues** (baseline 53), 0 errors; the touched files have no issues
- `dart format --set-exit-if-changed` clean on the 5 files; acceptance greps all match (each `= 1` grep is exactly 1)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Harness cubit created lazily inside the test**
- **Found during:** Task 1 GREEN
- **Issue:** with the `QuestResultsCubit` built in `setUp` its `_acknowledgementTail` (`Future.value()`) belongs to the real zone, so the best-effort ack chained on it never ran inside `testWidgets` (`acknowledged` stayed `[]` after the button).
- **Fix:** `late final QuestResultsCubit results = QuestResultsCubit(...)` — first touched in `pump()` inside the test body. Same in the death test. No production change.
- **Files:** both presenter test files; **Commit:** `115ea32`, `f476b0e`

**2. [Rule 3 - Blocking] Coin SVGs seeded**
- **Found during:** Task 1 GREEN
- **Issue:** `pumpAndSettle` timed out (the coin `CachedSvg`s went to the network); the plan named only `emptySheet`.
- **Fix:** seed the same 7 assets as `quest_result_sheet_test.dart`. **Commit:** `115ea32`

**3. [Rule 2 - Correctness] Small hardening over the plan sketch**
- Serials seeded from the current state in `initState` (no stale replay), last `CharacterLoaded` remembered instead of reading the current state, cubit callbacks after the dialog not skipped on `!mounted`, `routeCoveredChanged(false)` on dispose. Recorded in key-decisions. **Commit:** `115ea32`

**Total deviations:** 3 auto-fixed. **Impact:** none on scope; the RED test file was adjusted in the GREEN commit only for the two harness fixes above.

## Known Stubs

None. The presenter is not mounted yet: plan 09-11 mounts it in `MainScreen`.

## Threat Flags

None — the dialog route and the banner calls are the surfaces of T-9-32..T-9-36, all covered by tests.

## Self-Check: PASSED

- FOUND: lib/screens/mainScreen/components/quest_result_presenter.dart
- FOUND: lib/screens/mainScreen/questResultsCubit/quest_result_notice.dart
- FOUND: test/screens/mainScreen/components/quest_result_presenter_test.dart
- FOUND: test/screens/mainScreen/components/quest_result_presenter_death_test.dart
- FOUND: test/screens/mainScreen/questResultsCubit/quest_result_notice_test.dart
- FOUND commits: 8270e6a, 115ea32, f476b0e
