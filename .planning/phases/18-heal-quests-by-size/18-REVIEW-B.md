---
phase: 18-heal-quests-by-size
group: B
reviewed: 2026-11-10T11:50:00Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - lib/models/loot_recovery.dart
  - lib/models/loot_item.dart
  - lib/models/character/character_status.dart
  - lib/models/use_item_result.dart
  - lib/graphql/mutations/character_mutations.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/repository/services/graphql/graphql_error_code.dart
  - lib/repository/item_use_failure.dart
  - lib/repository/item_use_repository.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/screens/mainScreen/main_screen.dart
  - lib/screens/mainScreen/components/potion_outcome_listener.dart
  - lib/screens/mainScreen/tabs/journal/journal.dart
  - lib/screens/mainScreen/tabs/journal/components/potion_sheet.dart
  - lib/screens/mainScreen/tabs/journal/sections/items_section.dart
  - lib/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart
  - lib/screens/mainScreen/tabs/journal/potionCubit/potion_state.dart
  - lib/screens/mainScreen/tabs/journal/potionCubit/potion_notice.dart
  - lib/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_cubit.dart
  - lib/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_state.dart
  - lib/shared/components/item_row.dart
  - tool/schema_check/schema_check_documents.dart
findings:
  critical: 0
  warning: 1
  info: 6
  total: 7
status: issues_found
---

# Phase 18: Code Review Report, group B (Journal potions)

## Summary

The potion flow was followed end to end: tap on a heal parchment, `reset()`, `PotionSheet`, «Bevi», `PotionDrinking`, then `PotionDrunk` (outcome on the same sheet) or `PotionRefused` (the sheet pops, `PotionOutcomeListener` publishes the banner).

The production code is sound. `dart analyze` on the touched `lib` directories reports no issues. The points below held up:

- **Stale outcome on reopen.** `reset()` runs synchronously before `showModalBottomSheet`. `PotionSheet._faceOf` also ignores a `PotionDrunk` of another item, so no stale outcome is shown.
- **Sheet closed in flight.** The sheet cannot be closed while `PotionDrinking`: `PopScope(canPop: false)` blocks back and the barrier tap, and the `DraggableScrollableNotification` swallow blocks the drag. The refusal path closes it with `Navigator.pop`, guarded by `isCurrent`. So "outcome lost silently" is not reachable.
- **Single flight and `isClosed`.** `drink()` returns while `PotionDrinking`, so double taps and a second item make no call. `SafeEmit` covers `isClosed` after the `await`. The cubit test proves that nothing is emitted after `close`.
- **Banner dedup and rereads.** The `sequence` is part of both `PotionRefused.props` and the banner `dedupKey`. Only `notOwned` and `timedOut` trigger the silent `refreshCharacter()`.
- **Countdown.**
  - It runs on `ServerClockService` and rounds up to the minute.
  - The timer stops on a null or past date, and `close()` cancels the timer and the offset subscription.
  - It re-follows on every character change and resyncs on an offset change.
  - A tap during the countdown has no `onSelect`, so no call and no `reset()`.
- **Refusal copy.** `POTION_RECOVERING` uses the server's `extensions.recoveryUntil`, and a missing or malformed date gives the generic line.
- **Contract and parsing.**
  - `graphQlErrorExtension` reads both error shapes (`graphqlErrors` and HTTP 400 `parsedResponse`).
  - The `UseItem` document selects exactly the contract fields, with no `relatedLore`, and the registry is 46.
  - `LootRecovery` and `potionRecoveryUntil` are lenient (`null` instead of throwing), and `copyWith` and `props` carry `potionRecoveryUntil`.
  - The repository turns any parse error into `ItemUseFailure.unknown`.
- **UI rules.** There is no `AlertDialog`, `SnackBar` or spinner. `turns` is never shown. All copy matches the REPO-RULES. `ItemRow` takes `isDisabled` and `statusLine` from the caller only.

One warning: a protection that the code adds, and that an earlier phase found as a bug elsewhere, has no test. The infos are test-composition gaps and small hygiene points.

## Critical

None.

## Warning

### B-WR-01: Drag-to-dismiss protection of the potion sheet while drinking is untested

**File:** `lib/screens/mainScreen/tabs/journal/sections/items_section.dart:217-219`
**Issue:** `_confirmDrink` swallows `DraggableScrollableNotification` while `potionCubit.state is PotionDrinking`. This is the only thing that stops a drag to minimum extent from calling `Navigator.pop` and skipping the `PopScope`. The same pattern in `world_map.dart` (comment «WR-01») was introduced after a real bug, and it has a test (`world_map_travel_test.dart:530`, «dragging the sheet down cannot dismiss a start in flight»). `items_section_test.dart` has no equivalent. Its twelve cases only cover opening, reset, countdown, awaiting aid and travel. `potion_sheet_test.dart` pumps the bare `PotionSheet` in a `MaterialPageRoute` with a `MockPotionCubit`, so `PaperSheetModal`, the `NotificationListener` and the real modal route are never exercised for the drinking state.
**Why it matters:** If the swallow stops working (for example if the `NotificationListener` is moved or the modal changes), a drag during the 15 s in-flight window closes the sheet. When the call lands, `PotionDrunk` has no sheet to show it: the outcome (HP gain, healed injuries, the «Conoscenza appresa» line) is lost silently, and no banner is shown because `PotionOutcomeListener` only handles refusals. The regression would stay green today.
**Suggested fix:** RED first, in `items_section_test.dart`. Stub the `MockPotionCubit` with `whenListen(initialState: PotionDrinking(_herb))`, set `when(() => potionCubit.state).thenReturn(const PotionDrinking(_herb))`, open the sheet (the stub makes `reset()` a no-op, the state stays `PotionDrinking`) and mirror `dragSheetDown`: `tester.dragFrom(const Offset(390, 250), const Offset(0, 300))`, then `pumpAndSettle`, then `expect(find.byType(PotionSheet), findsOneWidget)`. Add the opposite case (state `PotionIdle`, same drag, sheet gone) so that the test cannot be green because the drag does nothing.

## Info

### B-IN-01: No test composes the real `PotionCubit` with the sheet, the section and the listener

**File:** `test/screens/mainScreen/tabs/journal/sections/items_section_test.dart:97` (also `potion_sheet_test.dart:42`, `potion_outcome_listener_test.dart:37`)
**Issue:** Every widget test uses `MockPotionCubit`, so the following cross-unit properties are only asserted as isolated calls (`verify(reset).called(1)`):
- reopening a sheet after `PotionDrunk`/`PotionRefused` shows the confirmation, not the previous outcome;
- the refusal pops the sheet and publishes exactly one banner;
- «Bevi» then `PotionDrunk` shows the outcome on the same sheet.

The correct behaviour depends on the order `reset()` then `show` and on the `itemId` guard in `_faceOf`.
**Why it matters:** The stale-outcome scenario named in the brief is covered only by unit pieces, so a reorder in `_confirmDrink` would not fail any test.
**Suggested fix:** Add one composition test with a real `PotionCubit(FakeItemUseRepository)`:
1. open the sheet, drink, assert the outcome;
2. press «Continua», reopen the same potion, assert «Bevi <nome>?» and no `potion.hp` key;
3. make the fake throw `ItemUseException(noEffect)`, drink, and assert that the sheet is gone and one `KGNotification` titled «Pozione non bevuta» was published.

### B-IN-02: Repository timeout test waits on a real 20 ms timer

**File:** `test/repository/item_use_repository_test.dart:60-72`
**Issue:** `'a timeout is timedOut (D-19)'` builds the repository with `timeout: const Duration(milliseconds: 20)` and a never-completing `Completer`, so it waits on a real timer. REPO-RULES: countdown and clock tests use `fakeAsync` or an injected clock, never real time. It is short and leaves no pending timer, so it is not flaky, but it differs from the convention.
**Why it matters:** Convention drift, and a loaded CI machine pays real milliseconds. It is not a correctness risk.
**Suggested fix:** Wrap in `fakeAsync`: start `repository.useItem('l-herb')`, `async.elapse(ItemUseRepository.defaultTimeout)`, `async.flushMicrotasks()`, and assert the `timedOut` failure with `expectLater(..., throwsA(...))`.

### B-IN-03: `graphQlErrorExtension` returns the key of the first coded error even when it is null

**File:** `lib/repository/services/graphql/graphql_error_code.dart:35-48`
**Issue:** `.where(code is String).map(error.extensions?[key]).firstOrNull` returns the first coded error's value. If that error lacks `key` but a later coded error has it, the result is `null`. `graphQlErrorCode` takes the first code, so the two stay consistent in the common one-error case. With several coded errors the date could be dropped, and `POTION_RECOVERING` would then show the generic line. The BE sends a single error for this mutation, so this is hygiene.
**Why it matters:** The helper is public and documented as a sibling of `graphQlErrorCode`. The name suggests "the value of this key", which it does not always give.
**Suggested fix:** Take the first non-null value among the coded errors: `.map((e) => e.extensions?[key]).nonNulls.firstOrNull`. Add the two-error case to `graphql_error_code_test.dart` (the first error has a code without the key, the second has the key).

### B-IN-04: `UseItemResult.quantityLeft` and `toJson` are never read by production code

**File:** `lib/models/use_item_result.dart:21,38-48`
**Issue:** `quantityLeft` is parsed strictly (a missing value makes the whole result fail) but nothing in `lib` reads it. The quantity on screen comes from the character stream. `UseItemResult.toJson` has no production caller either (only the model test round-trips it). The `recoveryUntil` field is also unread, since the countdown follows `potionRecoveryUntil` of the character.
**Why it matters:** Dead surface (CLAUDE.md Boy Scout rule). The strict `quantityLeft` parse means a BE that dropped the field would turn a drunk potion into an `unknown` refusal for a value nobody uses. Keeping the fields is defensible as the contract mirror, but then it should be a decision.
**Suggested fix:** Either drop `toJson` and the unused fields from the model (and from the document, which would need a decision on the contract), or keep the fields and record in the class doc that they mirror the contract. At minimum remove `toJson` if no cache needs it.

### B-IN-05: Sheet opens with `maxLifePoints: 0` when the status has no maximum

**File:** `lib/screens/mainScreen/tabs/journal/sections/items_section.dart:222`
**Issue:** `character.status?.maxLifePoints ?? 0` is passed to `PotionSheet`. With a null maximum, `HpDeltaBar` draws an empty bar with «8 / 0». A loaded character with a status always has a maximum, so this is hard to reach. Still, the fallback silently builds a wrong visual instead of making the state explicit.
**Why it matters:** Minor robustness. Backend truth is not violated, but the user would see a wrong number.
**Suggested fix:** Make `maxLifePoints` nullable in `PotionSheet` and omit the bar when it is null (still showing «Guarite» and the lore line), or keep the 0 and note why it is unreachable.

### B-IN-06: A malformed result after a successful drink is reported as a refusal

**File:** `lib/repository/item_use_repository.dart:21-31` (with `lib/repository/services/graphql/graphql.dart:733-752` and `potion_outcome_listener.dart:20-23`)
**Issue:** If the mutation succeeds on the server but the strict `UseItemResult.fromJson` fails (for example a field dropped or retyped on the BE), the call becomes `ItemUseFailure.unknown`. The user gets the banner «Pozione non bevuta / Qualcosa è andato storto, riprova» although the potion was consumed. `unknown` does not trigger the silent reread, unlike `timedOut`, which is the other uncertain-outcome case, so the Journal stays on the stream's state. That state is correct if `characterUpdated` fires, but the banner contradicts it. This is declared as intended in the brief (parse error to `unknown`), so it is kept as info only.
**Why it matters:** Contract drift would show up as a wrong message on the very action that changes the character, and the quantity could change under the banner.
**Suggested fix:** Add `ItemUseFailure.unknown` to `_staleViewFailures` (rereading is harmless, it is silent), or give the parse failure its own value. If the strictness is kept, add a RED test in `potion_outcome_listener_test.dart` for the chosen behaviour.

---

_Reviewed: 2026-11-10T11:50:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
