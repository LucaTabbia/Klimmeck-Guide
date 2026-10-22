---
phase: 06-quest-accept-info-sheets
reviewed: 2026-10-22T18:02:52Z
depth: standard
files_reviewed: 57
files_reviewed_list:
  - lib/graphql/fragments/character_fragment.dart
  - lib/graphql/mutations/quest_mutations.dart
  - lib/graphql/queries/city_queries.dart
  - lib/graphql/queries/quest_queries.dart
  - lib/models/character/character_quests.dart
  - lib/models/enums/title_type.dart
  - lib/models/equipment_item.dart
  - lib/models/loot_item.dart
  - lib/models/pending_quest.dart
  - lib/models/quest/adventurer_slot.dart
  - lib/models/quest/board_policy.dart
  - lib/models/quest/quest.dart
  - lib/models/quest/quest_availability.dart
  - lib/models/quest/quest_blocked_reason.dart
  - lib/models/quest/quest_capacity.dart
  - lib/models/quest/quest_cost_line.dart
  - lib/models/quest/quest_lane.dart
  - lib/models/quest/quest_paper_asset.dart
  - lib/models/quest/quest_prizes.dart
  - lib/models/quest/quest_requirements.dart
  - lib/models/quest/quest_sheet_details.dart
  - lib/models/quest/quest_state_label.dart
  - lib/models/quest/quest_viewer.dart
  - lib/models/quest/registered_adventurer.dart
  - lib/models/request/accept_quest_request.dart
  - lib/repository/quest_acceptance_failure.dart
  - lib/repository/quest_acceptance_repository.dart
  - lib/repository/quest_board_repository.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart
  - lib/screens/auth/inAppNotificationsCubit/in_app_notifications_state.dart
  - lib/screens/mainScreen/components/menu_background.dart
  - lib/screens/mainScreen/components/menu_item.dart
  - lib/screens/mainScreen/components/menu_section.dart
  - lib/screens/mainScreen/components/quest_acceptance_outcome_listener.dart
  - lib/screens/mainScreen/components/satchel_availability.dart
  - lib/screens/mainScreen/components/satchel_layout.dart
  - lib/screens/mainScreen/components/satchel_menu.dart
  - lib/screens/mainScreen/main_screen.dart
  - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart
  - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart
  - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_state.dart
  - lib/screens/mainScreen/questCubit/quest_cubit.dart
  - lib/screens/mainScreen/questCubit/quest_state.dart
  - lib/screens/mainScreen/tabs/board/board.dart
  - lib/screens/mainScreen/tabs/board/components/sheet.dart
  - lib/screens/mainScreen/tabs/map/layers/quest_info_overlay.dart
  - lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart
  - lib/screens/mainScreen/tabs/map/world_map.dart
  - lib/shared/components/cards/loot_item_card.dart
  - lib/shared/components/popup/quest_info_sheet.dart
  - lib/shared/components/tear/tear_clipper.dart
  - lib/shared/components/tear/tear_geometry.dart
  - lib/shared/components/tear/tear_gesture.dart
  - lib/shared/components/tear/tearable_paper.dart
  - lib/theme/kg_theme.dart
findings:
  critical: 0
  warning: 3
  info: 10
  total: 13
status: issues_found
---

# Phase 6: Code Review Report

**Reviewed:** 2026-10-22T18:02:52Z
**Depth:** standard
**Files Reviewed:** 57
**Status:** issues_found

## Summary

The 57 production files of `feat/06-quest-accept-info-sheets` (diff base `9c04da4`, BE contract at `Klimmeck-Guide-BE` `origin/develop`) were read in full; pre-existing files were reviewed on their changed hunks. `flutter analyze` is clean for `lib/` and `test/` (the 54 reported items are all `avoid_print` in `tools/`).

Overall the phase is in good shape. The layering holds (UI -> Cubit -> Repository -> Service; Cubits never call Cubits; orchestration is in `QuestAcceptanceOutcomeListener` and the Board `BlocListener`); the acceptance repository maps `OperationException` by `extensions.code` only and the UI never sees an exception; banner and blocked-reason copy are fixed domain Italian with no server text; nothing logs tokens (`debugPrint` only emits a quest id or an exception `runtimeType`); `AcceptQuestRequest.id` is always the session character id. The availability classifier (`quest_availability.dart`, `quest_capacity.dart`) was cross-checked against the BE `quest-eligibility.ts`, `quest-capacity.ts` and `quest-acceptance.service.ts` on `origin/develop`: lane/title/repeatable/city rules, the story-only city exemption (BE D-26 amended), the D-32 rank-capacity algorithm, the `QUEST_NOT_ACCEPTABLE` catalogue-defect rule and the evaluation order all match, so the client blocks the swipe only where the BE would reject. Wire parsing is tolerant where the catalogue is hand-edited (`Quest.tryFromJson` drops a single quest, `RegisteredAdventurer`/`AdventurerSlot` accept both Phase 7 and Phase 8 shapes, unknown titles degrade to `null`). The tear controllers are disposed, `_commitTear` re-checks `mounted` after its await, `recompose()` is guarded, and the generation counter in `refreshQuests` makes the last refresh win.

No critical issues. Three warnings concern unhandled edge cases: a late success after the 15 s client timeout that the banner contradicts, a silent near-empty board when `GetCity` fails on the first open, and a shared card that renders the literal `null`. The info items are mostly Boy Scout opportunities on touched files (duplication, dead field, operation naming, a Flutter import in a Cubit) plus a few robustness suggestions.

## Warnings

### WR-01: A late success after the 15 s client timeout is reported as a connection failure and contradicts the next banner

**File:** `lib/repository/quest_acceptance_repository.dart:29-36`, `lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart:34`, `lib/screens/mainScreen/components/quest_acceptance_outcome_listener.dart:25-29`
**Issue:** `accept()` wraps the mutation in `.timeout(15 s)` and maps `TimeoutException` to `QuestAcceptanceFailure.connection`. The underlying request is not cancelled: if the BE answers after the deadline (the UAT case was a BE blocked on Redis), the quest **is** accepted server-side while the FE recomposes the paper and shows "Connessione assente, riprova". The lane then arrives via `characterUpdated` (story/worldMission become `tornForOwner` on the board; a standard quest makes the character leave the city), and a retry answers `QUEST_SLOT_BUSY` -> "Hai già una missione in corso". State stays consistent (the subscription is the source of truth), but the two messages contradict each other and `connection` is not in `_staleListFailures`, so the board is not refreshed either.
**Fix:** Distinguish the two cases and make the copy honest about the uncertainty:
```dart
// quest_acceptance_failure.dart
enum QuestAcceptanceFailure { ..., connection, timedOut, unknown }

// quest_acceptance_repository.dart
} on TimeoutException {
  throw const QuestAcceptanceException(QuestAcceptanceFailure.timedOut);
}

// quest_acceptance_notice.dart
QuestAcceptanceFailure.timedOut =>
  'Il locandiere non risponde: se la missione risulta accettata la troverai sulla mappa',

// quest_acceptance_outcome_listener.dart
static const Set<QuestAcceptanceFailure> _staleListFailures = {
  ..., QuestAcceptanceFailure.timedOut,
};
```
Optionally, in the Board, skip `recompose()` for `timedOut` when `laneQuestOf(viewer.quests, lane)?.quest?.id == state.questId` already holds (the lane landed first).

### WR-02: A failed `GetCity` on the first Board open leaves a near-empty board with no feedback and no retry

**File:** `lib/screens/mainScreen/questCubit/quest_cubit.dart:52-55`, `lib/screens/mainScreen/tabs/board/board.dart:133-135`, `lib/models/quest/board_policy.dart:38-39`
**Issue:** `refreshQuests(cityId)` runs `getQuests` and `getCityPointIds` in parallel and swallows both errors by design (D-20 C5). When only `GetCity` fails on the first visit there is no `previous.cityPointIds` to keep, so `QuestLoaded(quests, cityId: city, cityPointIds: null)` is emitted; `_viewerOf` then builds a viewer with `cityPointIds == null` and `boardQuestsFor` lists only the viewer's exact-title story (every other type falls into `?? false`). The player sees an empty board, with no domain line and no retry until the Board is reopened (`initState`). The behaviour is correct in that it never shows another city's quests, but it is an unhandled failure path on the primary gameplay surface.
**Fix:** Either surface the state or add a fallback that does not need the second request:
```dart
// Option A (board.dart) — discreet domain line when the city is known but its POIs are not
final cityUnknown = questState.cityId == city.id && questState.cityPointIds == null;
if (cityUnknown) /* render a parchment line "La bacheca non risponde, riprova" and
                    call refreshQuests(cityId: city.id) on tap */

// Option B — select the marker's city in the quests document (SDL: PointOfInterest.city: City)
markerLocation { ${LocationFragment.fields} city { id } }
// and in board_policy._isListed / quest_availability._availabilityOf fall back to
viewer.cityPointIds?.contains(markerId) ?? (quest.infos?.markerLocation?.city?.id == viewer.cityId)
```
Option B removes the single point of failure entirely; Option A is the smaller change. Cover with a Board widget test "GetCity failure shows the retry line, not an empty board".

### WR-03: `LootItemCard` renders the literal text `null` when `power` is absent

**File:** `lib/shared/components/cards/loot_item_card.dart:55-56`
**Issue:** `if (lootItem.power != 0) _buildTextSection(text: lootItem.power.toString())` — `power` is `int?`, and `null != 0` is true, so a loot item fetched without `power` prints `null` on the parchment. The phase made this reachable from the quests document: `LootFragment.simpleFields` (used by `randomLoot` and `recommendedLoot`) selects no `power`, and the file was touched to null-guard `effect` and `rarity` for the same reason but missed `power`. Today the sheet only hands `prizeItem` (which now selects `power`) to this card, so the bug is latent in this phase but live for any future caller of the shared widget.
**Fix:**
```dart
final power = lootItem.power;
if (power != null && power != 0) _buildTextSection(text: '$power'),
```
Add a `LootItemCard` test with `power: null` asserting that no `Text` reads `null`.

## Info

### IN-01: `QuestBoardRepository` passes exceptions through, and `QuestError` carries technical text

**File:** `lib/repository/quest_board_repository.dart:10-13`, `lib/screens/mainScreen/questCubit/quest_cubit.dart:32-34`, `lib/repository/services/graphql/graphql.dart:150-153`
**Issue:** Unlike `QuestAcceptanceRepository`, the board repository forwards whatever the service throws (`Exception(getGenericErrorMessage(...))` includes the server message / `linkException` string), and `loadQuest` stores `e.toString()` in `QuestError.errorMessage`. Nothing displays it today, but the Repository contract in `docs/rules/graphql.md` (map to a domain error, never propagate raw text) is not honoured on this path.
**Fix:** Mirror the acceptance pattern: a `QuestBoardFailure { connection, unauthenticated, unknown }` thrown as `QuestBoardException`, `QuestError(this.failure)` instead of a `String`, and `getQuests`/`getCityPointIds` using `_dataOrThrow` like the newer service methods.

### IN-02: `QuestAcceptanceRepository.accept` wraps only three exception types

**File:** `lib/repository/quest_acceptance_repository.dart:32-38`
**Issue:** The doc comment promises "ogni errore diventa QuestAcceptanceException", but only `OperationException`, `TimeoutException` and `FormatException` are caught; a `TypeError`/`StateError` from the service would escape and is rescued only by the Cubit's generic `catch (_)`. The rule "repositories wrap every exception" is satisfied by the Cubit, not by the Repository.
**Fix:**
```dart
} on FormatException {
  throw const QuestAcceptanceException(QuestAcceptanceFailure.unknown);
} on Object {
  throw const QuestAcceptanceException(QuestAcceptanceFailure.unknown);
}
```
Then the Cubit's catch-all becomes a pure safety net.

### IN-03: The enemy image is rendered with `Image.asset` from a server-provided path

**File:** `lib/shared/components/popup/quest_info_sheet.dart:133-140`
**Issue:** `Enemy.imagePath` is `String!` on the BE and populated server-side (D-20 G1 / BE D-31); the BE spec data uses `enemies/wolf.png`, the FE widget test uses `assets/images/arbustoMaligno.png`. With a remote or Cloudinary path `Image.asset` always falls into the `errorBuilder` and the combat family silently loses its image. `docs/rules/assets.md` routes game-catalogue images through Cloudinary (`CachedSvg` / `cached_network_image`).
**Fix:** Pin the contract with the BE (bundled asset vs Cloudinary id) and, if remote, render with `CachedSvg(url: CloudinaryAssets.url(enemy.imagePath!))` or `CachedNetworkImage`; keep the `errorBuilder`.

### IN-04: The state label of the Map sheet is frozen at tap time

**File:** `lib/screens/mainScreen/tabs/map/world_map.dart:216-222`, `lib/screens/mainScreen/tabs/map/layers/quest_info_overlay.dart:11-16`, `lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart:52`
**Issue:** `QuestPaperLayer` computes `questStateLabel(lane, type)` and hands the `String` to `_openFromPaper`, which stores it in `_selectedStateLabel`. If `startDate` flips from `null` to set while the sheet is open ("In viaggio" -> "In combattimento…"), the open sheet keeps the stale text until it is closed and reopened; the small label under the paper updates, the sheet does not.
**Fix:** Pass the `Quest` only and let `QuestInfoOverlay` derive the label live:
```dart
BlocSelector<CharacterCubit, CharacterState, PendingQuest?>(
  selector: (s) => s is CharacterLoaded ? s.character.quests?.pendingQuest : null,
  builder: (_, lane) => QuestInfoSheet(
    quest: selectedQuest,
    stateLabel: lane?.quest?.id == selectedQuest?.id
        ? questStateLabel(lane!, selectedQuest!.infos?.type) : null,
  ),
)
```

### IN-05: A hard fling on a blocked paper overshoots before springing back

**File:** `lib/shared/components/tear/tearable_paper.dart:111-121`
**Issue:** When `canTear` is false the drag is capped at `blockedCap` (0.12), but `_onDragEnd` still seeds the spring with `-velocity / _width`; a fast left fling gives a positive initial velocity away from rest, so the body visibly travels further left before returning, which undercuts the "the paper resists" intent (D-11).
**Fix:** `_springBack(widget.canTear && _width > 0 ? -velocity / _width : 0);`

### IN-06: Slot tally logic duplicated between the capacity rule and the sheet lines

**File:** `lib/models/quest/quest_capacity.dart:22-30`, `lib/models/quest/quest_sheet_details.dart:135-148`
**Issue:** `exact()`, `reg()`, the unknown-rank count and the `overflow` fold are written twice; a future tweak of D-32 must be applied in both places or the sheet will disagree with the swipe gate.
**Fix:** Extract a small `SlotTally` (`exact(title)`, `registered(title)`, `anyRank`, `overflow`) in `quest_capacity.dart` and have both `canRegisterWithTitle` and `_slotLinesOf` read from it.

### IN-07: `publish` and `publishNotice` duplicate the dedup/enqueue sequence

**File:** `lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart:50-72`
**Issue:** Both methods repeat the `isClosed` guard, expiry sweep, key check, `_expiresAt` write, enqueue and `_showNext` trigger.
**Fix:**
```dart
void _enqueue(String key, Duration window, Object item) {
  if (isClosed) return;
  final now = _now();
  _expiresAt.removeWhere((_, expiry) => !now.isBefore(expiry));
  if (_expiresAt.containsKey(key)) return;
  _expiresAt[key] = now.add(window);
  _queue.add(item);
  if (!state.isShowing) _showNext();
}
```

### IN-08: Dead `_sub` field and a `material.dart` import in a Cubit

**File:** `lib/screens/mainScreen/questCubit/quest_cubit.dart:4,15,73-77`
**Issue:** `StreamSubscription<Quest>? _sub` is never assigned (the `close()` override only cancels it), and the Cubit imports `package:flutter/material.dart` only for `debugPrint`/`@immutable`; `docs/rules/state-management.md` wants Cubits free of Flutter widget dependencies. Both pre-exist but the file was reworked in this phase (Boy Scout).
**Fix:** Delete `_sub` and the `close()` override; replace the import with `package:flutter/foundation.dart`.

### IN-09: Operation names `quests` and `cities` do not follow the `GetXxx` convention

**File:** `lib/graphql/queries/quest_queries.dart:5`, `lib/graphql/queries/city_queries.dart:5`
**Issue:** `query quests {` and `query cities {` are lowercase, non-verb names, while the new `GetCity` and `AcceptQuest` follow `docs/rules/naming.md`. Both documents were edited in this phase.
**Fix:** Rename to `query GetQuests` / `query GetCities` and update `tool/schema_check` and any test asserting the operation name.

### IN-10: The Map paper disappears when the catalogue failed to load, even with a populated lane

**File:** `lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart:36-43`
**Issue:** The lane carries `quest { id }` only, so the paper needs `QuestLoaded` to resolve the quest. If `loadQuest()` at `MainScreen` start fails (`QuestError`) and the player never opens the Board, a running standard quest has no paper and no state label on the Map until the next successful refresh.
**Fix:** In `WorldMap`, a `BlocListener<CharacterCubit, ...>` that, when `pendingQuest?.quest?.id` is set and the `QuestCubit` state is not `QuestLoaded` (or the id is missing from it), calls `context.read<QuestCubit>().refreshQuests()` once (silent, D-20 C5).

---

_Reviewed: 2026-10-22T18:02:52Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
