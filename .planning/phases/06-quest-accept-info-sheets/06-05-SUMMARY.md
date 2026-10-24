---
phase: 06-quest-accept-info-sheets
plan: 05
subsystem: ui
tags: [flutter, gesture, haptics, spring, clippath, tdd]
requires: []
provides:
  - TearablePaper widget (board-agnostic tear interaction) with recompose() rollback
  - Pure TearGesture / ThresholdLatch / TearGeometry / TearClipper
  - recordHaptics test helper
affects: [06-10 board wiring]
tech-stack:
  added: []
  patterns: [pure gesture model + thin stateful widget, deterministic jagged clipper, SpringSimulation spring back]
key-files:
  created:
    - lib/shared/components/tear/tear_gesture.dart
    - lib/shared/components/tear/tear_geometry.dart
    - lib/shared/components/tear/tear_clipper.dart
    - lib/shared/components/tear/tearable_paper.dart
    - test/shared/components/tear/tear_gesture_test.dart
    - test/shared/components/tear/tear_geometry_test.dart
    - test/shared/components/tear/tearable_paper_test.dart
    - test/helpers/haptic_recorder.dart
  modified: []
key-decisions:
  - "Spring residue snapped to 0 on completion so the intact child is rendered again after a spring back or recompose"
requirements-completed: [QUEST-02]
duration: 15min
completed: 2026-10-21
---

# Phase 6 Plan 05: Tearable paper Summary

Left-swipe tear interaction as a reusable widget: pure gesture model (45% travel, 35% fling rule, 12% resistance cap), deterministic jagged-edge halves, haptics, SpringSimulation spring back and `recompose()` rollback.

## Tasks
1. Pure gesture model, poses, clipper: `45f3d2f` (RED `test` commit, then GREEN `feat`).
2. TearablePaper widget + haptic recorder: RED `afc5b70`, GREEN `060b00b`.

## Deviations from Plan

**1. [Rule 1 - Bug] Spring left a residual progress (~8e-5) so halves stayed rendered after recompose**
- **Found during:** Task 2
- **Fix:** `_snapToRest` zeroes the controller value after the spring completes (below 0.001, not torn).
- **Files:** tearable_paper.dart
- **Commit:** 060b00b

**2. [Test fix] Vertical-scroll test drags the SingleChildScrollView finder** (the 2000px paper centre is offscreen). Same commit.

## Verification
Full suite 1085 tests green; `flutter analyze` 56 issues (within limit, 0 errors).

## Known Stubs
None.

## Self-Check: PASSED
