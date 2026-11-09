---
phase: 12-hardening
group: C
reviewed: 2026-11-09T18:35:00Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - lib/models/enums/city_type.dart
  - lib/repository/character_creation_failure.dart
  - lib/repository/character_creation_repository.dart
  - lib/repository/character_deletion_failure.dart
  - lib/repository/innkeeper_failure.dart
  - lib/repository/push_device_failure.dart
  - lib/repository/quest_abandon_failure.dart
  - lib/repository/quest_acceptance_failure.dart
  - lib/repository/quest_result_failure.dart
  - lib/repository/services/graphql/graphql_error_code.dart
  - lib/repository/transaction_failure.dart
  - lib/repository/travel_failure.dart
  - lib/screens/characterCreation/components/character_creation_messages.dart
  - lib/screens/characterCreation/cubit/character_creation_cubit.dart
  - lib/screens/mainScreen/questAbandonCubit/quest_abandon_notice.dart
  - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart
  - lib/screens/mainScreen/questResultsCubit/quest_result_notice.dart
  - lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart
  - lib/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart
  - lib/screens/mainScreen/tabs/map/layers/city_markers_layer.dart
  - lib/screens/mainScreen/travelCubit/travel_notice.dart
findings:
  critical: 0
  warning: 1
  info: 6
  total: 7
status: issues_found
---

# Phase 12 (FE Hardening): Code Review Report, group C

## Summary

Group C is in good shape. The `BAD_USER_INPUT` work is complete and consistent:
- `badUserInput` exists in all classifiers.
- `badUserInputCode` is reused everywhere (no duplicated literal).
- The generic copy is pinned on every surface.
- `PushDeviceFailure.badUserInput` is non-retryable (the coordinator uses `isRetryable`).
- `QuestResultsCubit` does not retry it and shows the notice.

`graphQlErrorCode` reads the `ServerException.parsedResponse.errors` path. It keeps the `connection` fallback when no code is found, and no classifier maps a transport failure to `badUserInput`.

The moderation codes are read tolerantly (`responseData is Map`, non-string codes fall through to `uploadFailed`), and the two copies are as fixed. `CityType.cityClass` is gone with no reference left in `lib/` or `test/`. `size` and `imageId` are kept, per the D-13c veto. The marker visibility derives from `City.size` (`null` is hidden). I found no token in a log and no dev-bypass reference in this group.

The one real defect is a stale submit banner on the character-creation sheet after the two new moderation outcomes. The rest is quality and test-coverage notes.

## Critical

None.

## Warning

### C-WR-01: Moderation notice stays on screen after the player acts on it

**File:** `lib/screens/characterCreation/cubit/character_creation_cubit.dart:60-75`
**Issue:** `pickPortrait` and `removePortrait` never clear `submitFailure`.
- After `imageRejected`, the cubit clears `portraitPath` and the banner says «Immagine non ammessa, scegline un'altra.». The player picks a new image, and the old banner stays next to the new portrait until they edit a text field (`_editDraft` is the only place that resets it).
- After `moderationUnavailable`, the banner says «riprova o procedi senza immagine». Tapping Remove (the «proceed without image» path) leaves that banner on screen, although the player has already followed it.

**Why it matters:** The D-13b/D-19 flows are explicitly "new pick" and "retry or proceed without image". Both leave a misleading error visible. The player cannot tell whether the new pick was accepted, and the submit button is enabled while an error is still shown. No test pins the intended state after the pick or remove. `cubit.state.submitFailure` is never asserted in `character_creation_cubit_test.dart` after `pickPortrait` or `removePortrait`.

**Suggested fix:** RED tests first, in `test/screens/characterCreation/cubit/character_creation_cubit_test.dart`:
1. Seed `submitFailure: imageRejected`, then `pickPortrait` succeeds. Expect `submitFailure` null.
2. Seed `submitFailure: moderationUnavailable` with a `portraitPath`, then `removePortrait`. Expect `submitFailure` null.

Then:
```dart
emit(state.copyWith(portraitPath: path, submitFailure: null));          // pickPortrait
emit(state.copyWith(portraitPath: null, uploadedPortrait: null, submitFailure: null)); // removePortrait
```
Clearing every `submitFailure` is acceptable, since it is only ever a submit outcome.

## Info

### C-IN-01: `quest_result_notice.dart` uses a `_ => null` default over a failure enum

**File:** `lib/screens/mainScreen/questResultsCubit/quest_result_notice.dart:28-33`
**Issue:** The other four notice switches (`travel`, `abandon`, `acceptance`, `character_creation_messages`) list every value, so a new enum value fails compilation. This one ends with `_ => null`, so a future `QuestResultFailure` value would be silently muted. The silence is by design for network errors, but it is implicit.
**Suggested fix:** List `connection || timedOut || malformed || unknown || unauthenticated => null` explicitly. The existing `quest_result_notice_test` silent-set loop already covers the behaviour.

### C-IN-02: `badUserInputCode` lives in `spell_equip_failure.dart`, imported by ten unrelated files

**File:** `lib/repository/character_creation_failure.dart:3-4` (and nine siblings)
**Issue:** The shared constant is declared in `spell_equip_failure.dart` and imported via `show badUserInputCode` by all the other classifiers. Eight of them also carry a second `show unauthenticatedCode` import from `auth_api_exception.dart`. `graphql_error_code.dart` already hosts the sibling shared codes `forbiddenCode` and `notFoundCode`.
**Suggested fix:** Move `badUserInputCode` (and, in a later boy-scout step, `unauthenticatedCode`) next to `forbiddenCode` in `graphql_error_code.dart`, and drop the cross-feature import lines. Mechanical, no behaviour change.

### C-IN-03: Classification shift for HTTP 5xx answers that carry a parsed error code is not pinned

**File:** `lib/repository/services/graphql/graphql_error_code.dart:19-23`
**Issue:** Reading `parsedResponse.errors` means a 5xx whose body is a GraphQL or Nest error with a code (for example `INTERNAL_SERVER_ERROR`) now yields `code != null`, and every classifier returns `unknown`. Before, it returned `connection`. For acceptance and travel this changes the banner from «Connessione assente, riprova» to «Qualcosa è andato storto, riprova». It is arguably more truthful, and no retry or terminal logic changes for push (both are retryable). The tests pin only `ServerException(statusCode: 500)` with no parsed response, which stays `connection`. The coded-5xx outcome is unpinned.
**Suggested fix:** Add one test in `graphql_error_code_test.dart` (or one classifier test) for `ServerException(statusCode: 500, parsedResponse: errors [INTERNAL_SERVER_ERROR])` expecting `unknown`, so the intended behaviour is recorded.

### C-IN-04: `WorldMapCubit` keeps the raw exception text in state, and the field is never rendered

**File:** `lib/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart:25`
**Issue:** The `print` was correctly replaced by `appLog` with `runtimeType`. But `WorldMapError(e.toString())` still stores the full exception string. `OperationException.toString()` can embed server message text, and nothing renders `errorMessage` (no consumer in `lib/`). It is dead data that would become a leak the moment a screen displays it. The formatter reflow of the class header is a harmless, untouched-member change.
**Suggested fix:** Make `WorldMapError` carry no text (or a fixed copy). Optionally add `appLog` with `runtimeType` only. Test first: `loadLoreData` throwing yields `WorldMapError` without the exception text.

### C-IN-05: `CityType.size` (pixels) and `City.size` (`CitySizeType`) share a name

**File:** `lib/screens/mainScreen/tabs/map/layers/city_markers_layer.dart:36,50`
**Issue:** `_calculateMarkerScale(zoom, city.type!.size)` and `_isVisibleAt(city.size, zoom)` read two different `size` properties on the same object graph. This is the direct cost of the D-13c veto (keep pixel sizes). It is legal and covered by tests, but easy to misread. The `0.2`, `0.1` and `0.08` constants are pre-existing magic numbers.
**Suggested fix:** Optional, future: rename the enum field to `markerSize` (a veto on the values, not the name). Not needed for this phase.

### C-IN-06: Visibility now depends on backend data for three types that were classed `capital` in the enum

**File:** `lib/models/enums/city_type.dart:13-15`, `lib/screens/mainScreen/tabs/map/layers/city_markers_layer.dart:54-59`
**Issue:** The old `cityClass` marked `ferrionCity`, `necrorianCity` and `talmvereVillage` as capitals even though their names suggest otherwise. The visibility now follows the backend `City.size`. If the DB serves `city` or `village` for them, their markers appear at zoom 2.5 or 3.2 instead of always. That is the intended D-13c source of truth, but it is a visible change that FE tests cannot prove. The layer tests do cover all three sizes with the zoom boundaries, `null` size hidden, and `null` type hidden.
**Suggested fix:** Add a check to the device UAT or gate plan (12-16/12-17): compare the three cities' `size` in the DB with the previous behaviour.

## Test notes (no finding)

- The nine `*_failure_test.dart` files each redefine the same `_fromHttp400` / `fromGraphqlCode` builders. A shared helper in `test/helpers/` would remove about nine copies. This is optional boy-scout work, not a defect.
- The moderation cubit tests and the repository tests (422 and 503) use realistic `DioException` bodies. There are no real-time waits, and `QuestResultsCubit` tests use fake async.

---

_Reviewed: 2026-11-09T18:35:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
