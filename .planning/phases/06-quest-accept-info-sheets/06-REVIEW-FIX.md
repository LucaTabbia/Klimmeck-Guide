---
phase: 06-quest-accept-info-sheets
fixed_at: 2026-10-22T18:21:23Z
review_path: .planning/phases/06-quest-accept-info-sheets/06-REVIEW.md
iteration: 1
fix_scope: critical_warning
findings_total: 13
findings_in_scope: 6
fixed: 6
skipped: 7
status: all_fixed
---

# Phase 6: Code Review Fix Report

**Fixed at:** 2026-10-22T18:21:23Z
**Source review:** `.planning/phases/06-quest-accept-info-sheets/06-REVIEW.md`
**Iteration:** 1
**Branch:** `feat/06-quest-accept-info-sheets` (no push)

**Summary:**
- Findings in the review: 13 (0 critical, 3 warnings, 10 info)
- Findings in scope: 6 — the three warnings (`fix_scope: critical_warning`) plus the three zero-risk Info items the orchestrator pulled in (IN-02, IN-05, IN-08)
- Fixed: 6 (every in-scope finding)
- Skipped: 7 — Info items left out of scope by ruling (design choices or follow-ups for a later phase), each with its reason below

Every fix followed Red → Green: a failing-test commit (`test(...)`) followed by the fix commit, Conventional Commits, no trailers. Commits were made with plain `git` (the `gsd-tools commit` helper can create or switch branches according to `branching_strategy`, which the run was told never to do).

## Gate after the fixes

| Check | Result |
|-------|--------|
| `flutter test` (full suite) | **1350 passed, 0 failed** |
| `flutter analyze` | **54 issues, 0 errors, 0 warnings** (unchanged baseline: `avoid_print` in `tools/` and a handful of pre-existing `avoid_print` / `depend_on_referenced_packages` infos in untouched cubits; none in files touched by this run) |
| `dart format --output=none --set-exit-if-changed` | clean on every touched file that was clean before; the pre-existing format-dirty `loot_item_card.dart` was hand-edited, never formatted |

## Per-finding table

| ID | Outcome | Commits (test → fix) | Note |
|----|---------|----------------------|------|
| WR-01 | fixed | `0b4e6ae` → `6f7b8c9` | New `QuestAcceptanceFailure.timedOut`; repository maps `TimeoutException` to it (was `connection`); honest copy; `timedOut` refreshes the list |
| WR-02 | fixed | `6baa68e` → `66b43f6` | `QuestCubit` retries a failed `GetCity` once after `cityRetryDelay` (2 s default, injectable); cancelled by a newer refresh or `close()` |
| WR-03 | fixed | `1962844` → `f26cb14` | `LootItemCard` null-guards `power`; new widget test file |
| IN-02 | fixed | `50e19b2` → `f14562a` | Repository catch-all (`on Object`) → `unknown`; the `FormatException` branch folded into it |
| IN-05 | fixed | `4585033` → `65d9a0b` | Spring velocity zeroed when `!canTear`; blocked paper no longer overshoots the cap |
| IN-08 | fixed | — → `19a2d2d` | Dead `_sub` removed, `material.dart` → `foundation.dart`; pure refactor, no behaviour to test (testing.md exception) |
| IN-01 | skipped | — | Board repository / `QuestError` domain-error shape: a cross-cutting contract change on a path nothing displays today; follow-up |
| IN-03 | skipped | — | Enemy image source (bundled asset vs Cloudinary) needs the BE contract pinned first (D-20 G1 / BE D-31); follow-up |
| IN-04 | skipped | — | Live state label in the Map sheet is a design refinement of a provisional visual (D-19); follow-up |
| IN-06 | skipped | — | `SlotTally` extraction is a structural refactor across two files with a stable D-32 rule today; follow-up |
| IN-07 | skipped | — | `publish`/`publishNotice` dedup helper lives in the Phase 5 notifications cubit, outside this phase's surface; follow-up |
| IN-09 | skipped | — | Renaming the `quests`/`cities` operations touches `tool/schema_check` and FE-visible operation names; design choice deferred |
| IN-10 | skipped | — | Map-side one-shot `refreshQuests()` when the catalogue failed is new orchestration best planned with Phase 7 (travel rendering) |

## Fixed Issues

### WR-01: A late success after the 15 s client timeout is reported as a connection failure and contradicts the next banner

**Files modified:** `lib/repository/quest_acceptance_failure.dart`, `lib/repository/quest_acceptance_repository.dart`, `lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart`, `lib/screens/mainScreen/components/quest_acceptance_outcome_listener.dart`
**Tests:** `test/repository/quest_acceptance_repository_test.dart` (the timeout test now expects `timedOut`), `test/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice_test.dart` (new copy), `test/screens/mainScreen/components/quest_acceptance_outcome_listener_test.dart` (`timedOut` in the refresh loop)
**Commits:** `0b4e6ae` (test), `6f7b8c9` (fix)
**Applied fix:** Added `QuestAcceptanceFailure.timedOut`; `accept()` maps `TimeoutException` to it instead of `connection`; the banner keeps the title "Missione non accettata" with the line "Il server non ha risposto in tempo: controlla la bacheca prima di riprovare" (provisional copy, D-19); `timedOut` joined `_staleListFailures` so the board refreshes. The optional Board tweak (skip `recompose()` when the lane already landed) was not applied — the subscription remains the source of truth and the paper recomposes as before.

### WR-02: A failed `GetCity` on the first Board open leaves a near-empty board with no feedback and no retry

**Files modified:** `lib/screens/mainScreen/questCubit/quest_cubit.dart`
**Tests:** `test/screens/mainScreen/questCubit/quest_cubit_test.dart` — new `city retry` group on `fakeAsync`: default delay is 2 s; retries once after the delay when `GetCity` failed; gives up after the single retry; no retry when the POIs arrived; no retry without a city; a newer refresh supersedes the scheduled retry; `close()` cancels it
**Commits:** `6baa68e` (test), `66b43f6` (fix)
**Applied fix:** The minimal retry from the ruling, not Option A/B of the review. `refreshQuests(cityId)` delegates to `_refresh(cityId, retriesCity: true)`; when the refresh ends for a city with `cityPointIds == null`, a single `Timer(cityRetryDelay)` schedules `_refresh(cityId, retriesCity: false)`. Every refresh cancels a pending timer, `close()` cancels it too (state-management.md). No UI text, no document change. Widget tests use `MockQuestCubit`, so no pending timers leak into them. Worth a device check with the BE down to see the board fill in after ~2 s once it is back.

### WR-03: `LootItemCard` renders the literal text `null` when `power` is absent

**Files modified:** `lib/shared/components/cards/loot_item_card.dart`
**Tests:** `test/shared/components/cards/loot_item_card_test.dart` (new): no `Text` reads `null` for `power: null`, zero power hidden, positive power shown
**Commits:** `1962844` (test), `f26cb14` (fix)
**Applied fix:** `if (lootItem.power != null && lootItem.power != 0) _buildTextSection(text: '${lootItem.power}')`. Hand-edited: the file was already format-dirty, so `dart format` was not run on it.

### IN-02: `QuestAcceptanceRepository.accept` wraps only three exception types

**Files modified:** `lib/repository/quest_acceptance_repository.dart`
**Tests:** `test/repository/quest_acceptance_repository_test.dart` — "maps any other error to unknown" (`StateError`)
**Commits:** `50e19b2` (test), `f14562a` (refactor)
**Applied fix:** `on Object { throw const QuestAcceptanceException(QuestAcceptanceFailure.unknown); }` replaces the `FormatException` clause (same outcome, no duplication); the existing `FormatException` test still passes. The Cubit's `catch (_)` is now a pure safety net.

### IN-05: A hard fling on a blocked paper overshoots before springing back

**Files modified:** `lib/shared/components/tear/tearable_paper.dart`
**Tests:** `test/shared/components/tear/tearable_paper_test.dart` — "a hard fling on a blocked paper never overshoots the cap" (samples the body centre frame by frame; red run measured 373.05 against a 382.7 bound)
**Commits:** `4585033` (test), `65d9a0b` (fix)
**Applied fix:** `_onDragEnd` seeds the spring with `-velocity / _width` only when `widget.canTear && _width > 0`, otherwise `0`.

### IN-08: Dead `_sub` field and a `material.dart` import in a Cubit

**Files modified:** `lib/screens/mainScreen/questCubit/quest_cubit.dart`
**Commits:** `19a2d2d` (refactor)
**Applied fix:** Removed the never-assigned `StreamSubscription<Quest>? _sub` and its `cancel()`; `package:flutter/material.dart` → `package:flutter/foundation.dart` (`debugPrint`, `@immutable`). The `close()` override was kept, contrary to the review's literal suggestion, because WR-02 now needs it to cancel the city retry timer. No test commit: dead-code removal and an import swap are a behaviour-preserving refactor (testing.md exception); the cubit suite stayed green.

## Skipped Issues

All seven are Info findings outside the `critical_warning` scope, left for a later phase by the orchestrator's ruling.

### IN-01: `QuestBoardRepository` passes exceptions through, and `QuestError` carries technical text
**File:** `lib/repository/quest_board_repository.dart:10`
**Reason:** Cross-cutting contract change (`QuestBoardFailure`, `QuestError` shape, service `_dataOrThrow`) on a path nothing displays today; follow-up.

### IN-03: The enemy image is rendered with `Image.asset` from a server-provided path
**File:** `lib/shared/components/popup/quest_info_sheet.dart:133`
**Reason:** Needs the BE contract pinned (bundled asset vs Cloudinary id, D-20 G1 / BE D-31) before choosing the renderer; follow-up.

### IN-04: The state label of the Map sheet is frozen at tap time
**File:** `lib/screens/mainScreen/tabs/map/world_map.dart:216`
**Reason:** Design refinement of a provisional visual the user will rework (D-19); follow-up.

### IN-06: Slot tally logic duplicated between the capacity rule and the sheet lines
**File:** `lib/models/quest/quest_capacity.dart:22`
**Reason:** Structural refactor (`SlotTally`) across two files while the D-32 rule is stable; follow-up.

### IN-07: `publish` and `publishNotice` duplicate the dedup/enqueue sequence
**File:** `lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart:50`
**Reason:** Lives in the Phase 5 notifications cubit, outside this phase's surface; follow-up.

### IN-09: Operation names `quests` and `cities` do not follow the `GetXxx` convention
**File:** `lib/graphql/queries/quest_queries.dart:5`
**Reason:** Rename touches `tool/schema_check` and FE-visible operation names; design choice deferred.

### IN-10: The Map paper disappears when the catalogue failed to load, even with a populated lane
**File:** `lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart:36`
**Reason:** New Map-side orchestration best planned together with Phase 7 (travel rendering); follow-up.

---

_Fixed: 2026-10-22T18:21:23Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
