# Phase 16: Travel Ambushes - Research

**Researched:** 2026-11-06
**Domain:** Flutter wire-contract extension (`QuestResult.kind`/`ambush`, nullable `quest`), result queue grouping + carousel presentation (`PageView` in the existing `showGeneralDialog`), a fifth push category end to end, reroute proof on `TravelProgressCubit`
**Confidence:** HIGH for code facts (file:line read this session; two throwaway probes run green and deleted); MEDIUM for the BE names (fixed in the BE `15-REPO-RULES.md`, not yet on BE `origin/develop`: `grep -c AmbushReport` = 0 at `b492a46`)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Copied by reference, authoritative text in `16-CONTEXT.md` §Implementation Decisions (do not paraphrase in plans):
- **D-01** contract consumed: `QuestResult.kind: QuestResultKind!` (`quest`|`ambush`, missing/unknown → `quest`), `ambush: AmbushReport { at, nearCity { id name }, reachedCity { id name } }` (`reachedCity` null on a victory), **`quest` nullable** (required only when `kind == quest`; an ambush without `ambush` is dropped item by item); outcome `success`/`failure`; other fields as today; only `QuestResultFragment` grows; registry stays at 45; schema check after the BE merge; models Flutter-free Equatable in `lib/models/quest_result/`.
- **D-02** every lost ambush → push of a new category (`ambushDefeat`), personal, own `storageKey`/`wireType`, settings toggle «Imboscate», popup `focusCharacterOnMap`, in-app banner «Imboscata!» / «Sei stato sconfitto: la via torna verso <città>»; unknown wire types dropped; nothing on a victory.
- **D-03** BE rewrites `activeTravel` from the ambush point; `TravelProgressCubit.follow` already rebuilds; the phase PROVES it with a cubit/widget test, no second mechanism; the quest lane empties through `quests.pendingQuest` → null.
- **D-04** ambush sheet = result sheet with header outcome + «Imboscata presso <nearCity.name>» + date; enemies, HP bar, «Ferite»; won: «Ricompense» (coins) + XP/level/title; lost: «Portato a <reachedCity.name>», no rewards; consumables/spells when present; «Continua».
- **D-05** carousel: one `PageView`, one parchment per ambush, page indicator, chronological; «Continua» closes and acknowledges all (best effort per id); one ambush = one page without indicator; quest results one at a time after; group = consecutive `kind == ambush` at the head of the FIFO, re-evaluated at every presentation.
- **D-06** presentation rules unchanged; no «Missione conclusa» live banner for ambush results.
- **D-07** confirmation sheet, quest «Viaggio» line, previews unchanged and pinned by tests; `travelEnd` → Map where the carousel appears.
- **D-08** technical defaults (names, files, test conventions) — see CONTEXT.
- **D-09** gating: plans before the BE merge on mocks/fixtures; schema gate + device E2E (`16-HUMAN-UAT.md`) + `BACKEND-NOTES.md` after the merge.

### Claude's Discretion
Copy of non-user strings (header, «Portato a», banner title, settings label), page indicator style, carousel transition, reuse `QuestResultSheet` as a page vs a shared body, cubit group API, fixture names, how the city name travels in the push data, reroute test harness shape.

### Deferred Ideas (OUT OF SCOPE)
Client-side banner derived from the reroute; darkened unknown-enemy portraits (Phase 17); HP on the Map; loot from ambushes; dedicated darker sheet; per-page acknowledgement.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AMBUSH-01 | Pawn, dashed route, remaining time follow the rewritten `activeTravel` live; defeat push (new category + toggle) and banner lead to the Map | F6 (reroute probe GREEN, no code change needed), F5 (category threads through 6 files, banner comes from push `title`/`body` with zero new copy) |
| AMBUSH-02 | Ambush reports = result-sheet variants, one carousel per travel, acknowledged together, queued like quest results, free Map | F1 (models/parsing), F2 (group API + batch settling), F3 (presenter branch), F4 (sheet header variant + carousel = `PageView` of `QuestResultSheet`, probe GREEN) |
| AMBUSH-03 | Confirmation sheet and quest «Viaggio» line never reveal an ambush; `travelEnd` → Map | F7 pinning tests on `travel_confirmation_sheet.dart:104-116` and `quest_travel_line.dart`; `TravelPreview` documents untouched (REPO-RULES) |
</phase_requirements>

## Project Constraints (from CLAUDE.md)
- Clean Code, SoC (UI no networking; Cubit no Flutter/`BuildContext`; models Flutter-free), TDD red→green→refactor, Boy Scout rule.
- Rule 1: no app chrome on gameplay surfaces (the carousel is a parchment in the same transparent dialog, no AppBar/bottom nav). Rule 2: no blocking loading in session (the batch-settling wait of F2 is invisible: the carousel just opens a moment later; never a spinner). Rule 3: branch `feat/16-travel-ambushes`, PR → `develop`. Rule 4: the backend is source of truth (no nearest-city, reward or HP logic; the reroute is rendered as received). Rule 5: no secrets.
- `flutter analyze` 0 error / 0 warning — **baseline measured this session on the branch (= `develop` code): `50 issues found`, all info**. `dart format` only on touched files; no `Co-Authored-By`/`Generated with` trailer; docs scope `docs(phase-16)`.
- `docs/rules/state-management.md`: a Cubit never calls a Cubit (presenter orchestrates), `bloc_test` for non-trivial cubits, `BlocListener` for side effects. `docs/rules/architecture.md`: a widget used by ≥ 2 features goes in `lib/shared/components/` (the carousel sits beside the sheet in `lib/shared/components/popup/`). `docs/rules/ui-ux.md`: theme tokens only.
- `16-REPO-RULES.md` fixes the contract and FE names (`QuestResultKind`, `AmbushReport`, `AmbushCity`, `NotificationCategory.ambushDefeat('ambush_defeat', 'ambushDefeat')`, `AmbushReportCarousel`, fixtures `ambushWonResultJson`/`ambushLostResultJson`), the gate grep `AmbushReport` on BE `origin/develop`, and «fragment grows in the SAME commit as the model».

## Summary

The phase is small in new surface but touches the most delicate pipeline of the app (the never-lost result queue). Three facts drive the plan. **(1) The reroute needs no code**: a throwaway probe on `TravelProgressCubit` (follow a travel at halfway, then follow a rewritten `ActiveTravel` with `startTime` = the ambush instant and a road starting at the pawn) is GREEN — position restarts from the new first point, remaining time = new `endTime − now`, the ticker keeps running, `ArrivalRereadLedger` gives a fresh budget (identity `startTime+endTime+to`). Nothing in `world_map.dart` or the layers caches the first travel (`follow` :50-56 compares the whole Equatable; listener `world_map.dart:190-193` fires on any `activeTravel` change). The phase only adds the proof tests (cubit + `world_map_travel_test.dart`). **(2) The push category is almost free**: the BE composes `title`/`body` (BE `15-REPO-RULES.md` :35), `PushEvent.tryParse` already renders them, and the tap/landing/background paths key on `NotificationCategory.fromWireType`; the work is one enum value + one switch arm + one popup entry + ~6 pinned tests. **(3) The carousel is the real work, and it hides a race**: at arrival the BE inserts N ambush `QuestResult`s in one transaction, but the change stream delivers them as N separate `questResultReceived` events, and the presenter presents the head the instant it lands on a free Map (`quest_result_presenter.dart:165-168`, no travel/availability gate holds it). Without a settling step the first ambush opens alone and the second becomes a second one-page carousel. The atomic transaction makes the fix deterministic: on a live ambush arrival, re-read `unacknowledgedQuestResults` (it returns the whole batch, ordered `resolvedAt, _id` by BE 9.2) and do not present an ambush head while that read is in flight.

The cubit already has every primitive the group needs (FIFO merge/sort, dedup `_isKnown`, serialised best-effort acks, external-pop requeue); the minimal API keeps the three existing methods and widens them to the presentable group (`presented(headId)` moves the whole group to `showing`, `closed(headId)` acks every id of the group, `dismissedExternally(headId)` requeues them all). The critical correctness point is `_isKnown` (:339-344): it checks `state.showing?.id` only — with a group showing, a duplicate live/refetch event of page 2 would re-enter the queue and reopen after the ack. A second throwaway probe proved the carousel shape: a `PageView` of two `QuestResultSheet`s inside `showGeneralDialog` in landscape renders without exceptions, the existing «k di N» counter works as the page indicator (shown only when `total > 1`), and a fling that starts on the HP tap block still pages.

**Primary recommendation:** Models + fragment first (one commit pair per REPO-RULES), the category second (independent), then sheet header variant → cubit group + batch settling → `AmbushReportCarousel` → presenter branch, then the reroute/confirmation proofs; 16-08 schema gate and 16-09 device E2E gated on `grep -c AmbushReport ≥ 1`.

## Standard Stack (all already locked, no new dependency)

| Library | Use in this phase | Source |
|---------|-------------------|--------|
| `flutter` `PageView`/`PageController` (SDK) | carousel pages; only existing use is `main_screen.dart:171` | [VERIFIED: codebase] |
| `flutter_bloc` / `bloc_test` / `mocktail` / `fake_async` | cubit, presenter harness, ticker tests | [VERIFIED: codebase, `test/helpers/mocks.dart:100,147`] |
| `equatable` | `QuestResultKind` enum, `AmbushReport`, `AmbushCity` models | [VERIFIED: codebase] |
| `intl` `DateFormat('dd/MM HH:mm')` | ambush header date (reuse `_resolvedAtFormat`, `quest_result_sheet.dart:93`) | [VERIFIED: codebase] |

No page-indicator package (none in `pubspec.yaml`; `grep indicator pubspec.yaml` empty): reuse the sheet counter (F4). No new dependency — REPO-RULES forbid it without the orchestrator's go.

## Architecture Patterns

### Recommended files
```
lib/models/quest_result/quest_result_kind.dart     # enum QuestResultKind { quest, ambush } + tolerant fromWire
lib/models/quest_result/ambush_city.dart           # AmbushCity { id, name } (Equatable, fromJson/toJson)
lib/models/quest_result/ambush_report.dart         # AmbushReport { at (UTC), nearCity, reachedCity? }
lib/models/quest_result/quest_result.dart          # + kind, ambush, quest nullable, isAmbush getter
lib/graphql/fragments/quest_result_fragment.dart   # + kind, ambush { at nearCity { id name } reachedCity { id name } }
lib/models/notification_category.dart              # + ambushDefeat('ambush_defeat', 'ambushDefeat')
lib/screens/mainScreen/tabs/settings/components/notification_preferences_section.dart  # + «Imboscate» arm
lib/screens/mainScreen/components/notification_popup_registry.dart                     # + ambushDefeat: focusCharacterOnMap
lib/shared/components/popup/quest_result_sheet.dart  # header variant + «Portato a» line
lib/shared/components/popup/ambush_report_carousel.dart  # NEW: PageView of QuestResultSheet
lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart / quest_results_state.dart  # group API + batch settling
lib/screens/mainScreen/components/quest_result_presenter.dart  # branch on head kind, no questEnd banner for ambushes
```

### F1. `QuestResult` model and parsing [VERIFIED: codebase]
- Today: `quest` is `final QuestResultQuest quest` (`quest_result.dart:51`), parsed with a hard cast `QuestResultQuest.fromJson(json['quest'] as Map<String, dynamic>)` (:99); `QuestOutcome.fromWire` strict → `FormatException` (:93-95, `quest_outcome.dart:15-16`); `tryFromJson` (:129-136) turns ANY throw into `null`, and the three readers drop `null` per item (`graphql.dart:178`, :235 list readers; :300 `_questResultFrom` throws `FormatException` for the subscription/get-by-id, which the cubit skips at `quest_results_cubit.dart:271`).
- Recommended parse (all inside `fromJson`, so `tryFromJson` stays the boundary):
  - `kind: QuestResultKind.fromWire(json['kind'])` — `value is String ? values.asNameMap()[value] ?? quest : quest` (tolerant both ways, unlike `QuestOutcome`).
  - `quest`: when `kind == quest` keep today's cast (missing/malformed → throw → dropped, D-01); when `kind == ambush` read it tolerantly (`json['quest'] is Map<String, dynamic> ? QuestResultQuest.fromJson(...) : null`) — BE sends `null`.
  - `ambush`: when `kind == ambush` → `AmbushReport.fromJson(json['ambush'] as Map<String, dynamic>)` (missing → throw → dropped, D-01); when `kind == quest` → `null` regardless of the wire (REPO-RULES: `null` iff quest).
  - `AmbushReport.fromJson`: `at` `DateTime.parse(...).toUtc()` strict; `nearCity` strict `AmbushCity.fromJson` (`id`, `name` strings); `reachedCity` tolerant (`is Map` → parse, else `null`). Whether a malformed `reachedCity` map (e.g. no `name`) drops the report or reads `null` is a planner choice — recommend **drop** (strict inside, tolerant only on absence), since «Portato a» on a defeat is the D-04 content.
  - Getter `bool get isAmbush => kind == QuestResultKind.ambush;` (used by cubit, presenter, sheet).
- `toJson` (:164-194) must write `'kind': kind.name`, `'quest': quest?.toJson()`, `'ambush': ambush?.toJson()` — the round-trip group (`quest_result_test.dart:370-398`, «fromJson(toJson()) is equal for …») iterates a fixture map: add the two ambush fixtures there. `props` (:197-224) gain `kind`, `ambush`.
- Only ONE lib reader of `result.quest` exists: `quest_result_sheet.dart:172,181` (grep of `\.quest\.(id|title|type)|result\.quest\b` over `lib/`). Making `quest` nullable is therefore a compile error in exactly that file → the model plan must also touch the sheet header minimally (`_result.quest?.…`) or the analyzer gate fails (Pitfall 2). Innkeeper `completion_recap.dart:47-55` and `results_recap_dialog.dart` never read `quest`.
- Tests reading `result.quest.x` that become analyzer errors once nullable: `test/models/quest_result/quest_result_test.dart:24-26, 65, 74, 83, 220-221` (→ `result.quest!.x` or `result.quest?.x`). `world_map_travel_test.dart:721` is a quest *sheet*, unrelated.
- No test constructs `QuestResult(...)` directly (only `fromJson`), so the constructor change is free.
- Fixtures (`test/helpers/fixtures/quest_result_fixtures.dart`): `questResultJson` (:51-122) has no `kind` key (it is the «older BE» shape — keep it so; the tolerant default is then covered for free) and always writes `'quest': {...}` (:86). Recommended ambush fixtures beside `failureResultJson` (:156): build from `questResultJson(...)` then `..['kind'] = 'ambush' ..['quest'] = null ..['ambush'] = ambushReportJson(...)`, with `rewardItems: const []`, `rewardPet` absent, `spellLearned` null, `rescuedCharacters: []`, stages null (REPO-RULES); won: `outcome: 'success'`, coins > 0, `xpGained > 0`, `reachedCity: null`; lost: `outcome: 'failure'`, `coins: _zeroCoins`, `xpGained: 0`, `hpAfter` low, `reachedCity` set. Add `ambushReportJson({at, nearCityId, nearCityName, reachedCity})` and an `ambushCityJson`.
- Fragment (`quest_result_fragment.dart:12-98`): add `kind` (recommend right after `outcome`: keeps the pinned `'resolvedAt acknowledgedAt'` adjacency, `quest_result_documents_test.dart:92-94`) and `ambush { at nearCity { id name } reachedCity { id name } }` after `rescuedCharacters`. Pinned tests are all `contains(...)` checks (`quest_result_documents_test.dart:33-94`); the enemy-block count (:68-77, `\benemy \{`) is unaffected by `nearCity {`/`reachedCity {`. The fragment is interpolated in 4 documents (`OnQuestResultReceived`, `GetQuestResult`, `ListUnacknowledgedQuestResults`, and `CompletePendingRequest` in `pending_request_mutations.dart:10`, pinned by `pending_request_documents_test.dart:115` via the collapsed fragment — it follows automatically). **No new document**: the registry stays 45 (`test/tool/schema_check_documents_test.dart:32-34`).

### F2. `QuestResultsCubit` — group API and batch settling [VERIFIED: codebase]
- Queue: `_merged` (:346-349) appends and sorts by `resolvedAt` then id (:351-354); `_unseen` (:224-231) dedups a refetch batch; `_accept` (:328-337) for live/tap; `_isKnown` (:339-344) = closed ∪ pendingAcks ∪ acknowledged ∪ `showing?.id` ∪ queue. BE 9.2 orders `unacknowledgedQuestResults` by `{resolvedAt: 1, _id: 1}`, cap 50 (BE `09.2-…/BACKEND-NOTES.md:155, :243`). BE D-13: ambush reports carry `resolvedAt` = ambush instant, inserted in the arrival transaction → they sort before any quest result of the same arrival.
- `presented(id)` (:122-132) moves the head to `showing`, `position + 1`; `closed(id)` (:136-147) adds to `_closedIds`, then `_acknowledgeQuietly` (serialised through `_acknowledgementTail`, :308-324; failure → `_pendingAcks`, retried at the next refetch :233-238); `dismissedExternally(id)` (:151-160) requeues `showing` via `_merged`, `position − 1`; death path (:164-181) unaffected (an ambush is never a death: BE D-11 HP ≥ 1, no `awaitingAid`).
- **Recommended minimal API (Claude's discretion, D-08):**
  - State: replace `final QuestResult? showing` with `final List<QuestResult> showingGroup` (default `const []`) and keep `QuestResult? get showing => showingGroup.firstOrNull` so the death code, `_QuestResultRoute` and every existing test that reads `state.showing` stay valid. Add `List<QuestResult> get presentable` = `queue.isEmpty ? [] : queue.first.isAmbush ? queue.takeWhile((r) => r.isAmbush).toList() : [queue.first]` (D-05 rule, re-evaluated at every read). `copyWith`/`withoutShowing` (:58-90) and `props` (:93-102) follow.
  - `presented(String headId)`: guard `head?.id == headId`; move the whole `presentable` to `showingGroup`; `queue.skip(group.length)`; `position + group.length` (keeps «k di N» of the quest sheets after the carousel consistent with `total = position + queue.length`, :41).
  - `closed(String headId)`: guard `showing?.id == headId`; add every group id to `_closedIds`; ack each id not in `_acknowledgedIds` in order (one `_acknowledgeQuietly` per id: the serialised tail already guarantees one at a time; best effort per id, D-05).
  - `dismissedExternally(String headId)`: requeue the whole group (`_merged(showingGroup)`), `position − group.length` (floor 0).
  - `_isKnown`: `showingGroup.any((r) => r.id == id)` instead of `state.showing?.id == id` (**mandatory**, Pitfall 1).
  - Batch settling (Pitfall 3): in `_onLiveResult`/`_accept` with `isLive && result.isAmbush`, emit the merged queue **with `pendingRefetch: PendingRefetch.inFlight` in the same emit** and start `refetchPending()`; add `bool get isSettlingAmbushes => head?.isAmbush == true && pendingRefetch == PendingRefetch.inFlight` for the presenter. Because the BE commits all reports before the change stream emits, the list read returns the whole batch; `_unseen` dedups the live copies. Note `refetchPending` is single-flight (`_refetchInFlight ??=`, :96-97): if a read started before the commit is still in flight it may return a stale list — the following live events still land before it completes in practice (ms apart); accept, or chain a second read (planner's call; Open Question 2).
- `arrival`/`arrivalSerial` (:30-31, :333-334) still mark live ambush arrivals; the presenter just does not announce them (F3).
- Tests: `quest_results_queue_test.dart` `QueueHarness` (:30-85: real cubit, `FakePendingQuestResults`, `RecordingQuestResultAcknowledger`, buses; `offer(results)` = set pending + `refetchPending`), groups at :87 (order/dedup), :125 (presentation/counter), :173 (ack at close), :239 (external pop), :266 (death). Live arrivals and refetch-in-flight are exercised in `quest_results_delivery_test.dart` (:141 refetch triggers, :268 refetch progress with `FakePendingQuestResults.hold`, :343 subscription). New cases: group of 2 ambushes + quest → `presented` moves 2, quest stays; `closed` acks both in order; one ack failing leaves only that id pending; external pop requeues both; a live duplicate of page 2 while showing is ignored; a live ambush sets `isSettlingAmbushes` until the read completes; a head quest result is a group of one even with ambushes behind it.

### F3. `QuestResultPresenter` [VERIFIED: codebase]
- `_canPresent` (:145-149) = nothing showing + head exists + `_isSheetGround` (:155-163: accepting sheets, no covering route unless it is our own sheet, death unlock, else `isFreeBeneathRoutes` + `TravelIdle`). `_tryPresent` (:165-168) → `_present(head)` (:172-201): `presented(id)`, `showGeneralDialog<bool>(useRootNavigator, barrierDismissible: false, barrierColor: disabledScrim, 250 ms)`, `PopScope(canPop: false)`, `pop(true)` only from the button (`_QuestResultRoute._onContinue` :248-254) → `closed(id)`, anything else → `dismissedExternally(id)`; next presentation post-frame.
- Branch: `_canPresent` adds `!state.isSettlingAmbushes`; `_tryPresent` reads `state.presentable`; `_present(List<QuestResult> group)` calls `presented(group.first.id)`, builds `group.first.isAmbush ? AmbushReportCarousel(results: group, onContinue: () => Navigator.of(context).pop(true)) : _QuestResultRoute(result: group.single, …)` inside the same `Material(transparency) → Center`, and calls `closed/dismissedExternally(group.first.id)`. The whole group returns one `true` (D-05). The death branch (`_deadCharacterName` :205-209, `BlocConsumer` :222-246) stays on the single path.
- Banner (D-06): `_announceArrival` (:111-123) → first line after the serial bookkeeping: `if (arrival.isAmbush) return;` (no publish, no `suppress` — there is no `questEnd` push for reports, BE D-13). `questEndEventOf` (`quest_end_event.dart:12-18`) does not read `quest`, so it would not crash, it would just be wrong copy.
- External pops that hit the carousel: `NotificationIntentLanding._consumePendingIntent` pops the root navigator to the first route on every tap (`notification_intent_landing.dart:52-55`) → a `travelEnd`/`ambushDefeat` banner tapped while the carousel is open requeues the whole group (correct with the widened `dismissedExternally`).
- Tests: `quest_result_presenter_test.dart` `_PresenterHarness` (:43-142: real `QuestResultsCubit` + `MapAvailabilityCubit`, `live` StreamController, `FakePendingQuestResults`, mock Travel/Character/Notices/Preferences, `seedSvgCache` of 7 assets :159-167), gating group :177, dialog group :341. New: two live ambushes → one carousel with 2 pages after the settle read; «Continua» acks both (`acknowledger.acknowledged == ['a1','a2']`); a quest result behind opens after; no `notices.publish` for an ambush arrival off-map; external pop requeues both.

### F4. `QuestResultSheet` and the carousel [VERIFIED: codebase + probe]
- Structure: `build` (:107-147) sizes the parchment from the tighter constraint (`_aspectRatio` 315/375), `Stack[CachedSvg emptySheet, Padding(Column[Expanded(_content), ..._footer])]`; `_content` (:149-169) = header, death identity, enemies (:232-254, doc comment already names Phase 16), stages, HP (:256-288, `TweenAnimationBuilder` + tap-to-skip, 1200 ms), «Ferite» (:290-297), consumables, spells, rewards (:317-339, only when `hasRewards`), xp/level/title/spell learned/rescued lines (`_line` :373-381); footer (:430-445) = counter «k di N» only when `total > 1` (`counterKey`), ack error, «Continua» (:447-458).
- Recommended: keep ONE widget. `_header()` branches on `_result.ambush` (non-null ⇒ ambush): outcome label (same `headerKey`, same `_outcomeInk`) + `'Imboscata presso ${ambush.nearCity.name}'` (new `ambushPlaceKey`) + date; no quest type line. Add `..._line(_reachedCityText(), QuestResultSheet.reachedCityKey)` with `'Portato a ${reachedCity.name}'` when `ambush?.reachedCity != null` (recommend right after `_injuries()`). Rewards/XP need no branch: the BE sends zero coins and `xpGained: 0` on a defeat (REPO-RULES :34, BE D-10), so `hasRewards`/`_xpText` already hide them (the FE does not decide «no rewards on a loss», it renders the zeros — rule 4).
- Carousel: `AmbushReportCarousel(results, onContinue)` = `PageView(children: [for i: QuestResultSheet(result: results[i], position: i + 1, total: results.length, onContinue: …)])`. **Probe result (throwaway, deleted):** `PageView` of two sheets in `showGeneralDialog` on `useLandscapePhone` → no exception; `«1 di 2»` on page 1, fling left → `«2 di 2»` + «Sconfitta»; a fling starting on the HP `GestureDetector` (tap-only) still pages back. So the existing counter IS a page indicator «only with more than one page» (D-05) with zero layout work. Dots would need a new widget outside the parchment `Stack` or a new footer slot (Open Question 3).
- «Continua» per page: every page has its own button; D-05 says it closes the carousel. Tapping it on page 1 acknowledges page 2 unseen (Open Question 1; recommendation: on a non-last page the button animates to the next page, on the last it pops `true`).
- Pages are built lazily (default `PageView`), each sheet's HP animation starts when its page is first built; swiping back may rebuild a disposed page and replay it (no `AutomaticKeepAlive`) — cosmetic, accept.
- Tests (`test/shared/components/popup/quest_result_sheet_test.dart`): `_pump` helper (:20-45) in `buildTestApp(Scaffold(body: sheet))` + `useLandscapePhone`; `seedSvgCache` with **`emptySheet`, `emptyCardSheet`, `healEffect`, `helmetType`, gold/silver/copper** (:61-72) — the probe hung `pumpAndSettle` until `emptyCardSheet` was seeded (Pitfall 5). Groups: success :75, enemies :151, counter :526, layout :603. New carousel test file `test/shared/components/popup/ambush_report_carousel_test.dart` with the same seeds.

### F5. `NotificationCategory.ambushDefeat` end to end [VERIFIED: codebase]
- Enum `notification_category.dart:3-7` (order = settings display order); `isPersonal` (:21) = `this != streamerLive` → ambushDefeat personal for free; `fromWireType` (:24-29) loops values → no change.
- Exhaustive switch: only `notification_preferences_section.dart:44-49` (`_labelOf`) → `NotificationCategory.ambushDefeat => 'Imboscate'`. Boy Scout: its doc comment says «Tre switch» (:9) and there are four → five.
- Iterating `values` (no change, new value automatic): `notification_preferences_store.dart:42-45` (`readAll`), `notification_preferences_state.dart:11-19` (default map), section `:23`, fake `test/helpers/fakes/in_memory_notification_preferences_store.dart:37`.
- Popup registry `notification_popup_registry.dart:15-18` → `NotificationCategory.ambushDefeat: focusCharacterOnMap` (comment :12-14 to extend).
- Foreground banner: FCM foreground → `ForegroundPushEvents.events` (`foreground_push_events.dart:21-30`) → `acceptPushEvent` (`data_message_handler.dart:9-26`: parse + toggle) → `InAppNotificationsCubit.publish` (:51-60) → banner from `event.title`/`event.body` (`push_event.dart:52-53`). Background: `handleDataMessage` (:29-42) → local notification with the same title/body, single Android channel (`flutter_local_notifications_adapter.dart:17-28`, `PushChannel.id`) — no per-category channel. Tap: payload → `NotificationIntent.tryFromPayload` (`notification_intent.dart:27-44`) → `NotificationTapRouter.handle` (personal → intent sink, :21-29) → `NotificationIntentLanding` jumps to Map + popup (`notification_intent_landing.dart:48-60`). **So the FE composes no copy and parses no city** (C1).
- Dedup key `ambushDefeat|<characterId>` (personal id = character id, REPO-RULES :35), window 2 min (`in_app_notifications_cubit.dart:34`); Android notification id = hash of the key → a later defeat replaces the earlier system notification (one defeat per travel by BE D-03, fine).
- Preferences are device-only (Phase 5 CONTEXT :20 «syncing preferences to the backend» out of scope; no preferences document in `lib/graphql`): **the BE does not need to know the toggle**; it sends, the FE filters (`data_message_handler.dart:21`). Default enabled (`defaultEnabled` :12), storage key `klimmeck.notifications.<userId>.ambush_defeat` (`notification_preferences_store.dart:30-31`), never written until toggled.
- BE side: `PushEventType` on `origin/develop` today = `questCancelled questEnd streamerLive travelEnd`; the BE adds `ambushDefeat` (REPO-RULES :35). A FE build without the value drops the push (`push_event.dart:31`) — correct degradation.

### F6. Reroute proof [VERIFIED: probe GREEN, deleted]
- `TravelProgressCubit.follow` (:50-56): `_isSameTravel` = Equatable equality over the whole `ActiveTravel` (:104) → any rewritten field rebuilds `_route` and re-snapshots; `_snapshot` (:109-130) interpolates `travelProgress(serverNow, startTime, duration)` (`travel_route.dart:93-101`), `remainingTime = endTime − now` (:132-135); the periodic timer is kept (`_timer ??=`, :88) — a reroute after a *settled* travel restarts it (test «a new travel after the ticker stopped restarts it», `travel_progress_cubit_test.dart:400`).
- Probe (fakeAsync, `FakeServerClockService`, shared `ArrivalRereadLedger`): follow `activeTravelJson()` at 11:20 (halfway), +10 s, follow a rewritten travel `startTime 11:20, endTime 12:20, duration 3 600 000, to city-marker-9, road [pawn, (5,5)]` → `state.travel == rerouted`, `remainingTime == 59:50`, after +30 min the position equals `route.pointAt(1810/3600)`, after the new `endTime` + 6 s `claimArrivalReread()` is `true` (fresh budget). Existing tests already cover «another start time rebuilds the route» (:141-166) and «a different travel starts with a fresh budget» (:603-622); the new test should be titled for the rule (e.g. «a lost ambush reroute restarts the pawn from the ambush point (D-03)») and assert position at the reroute instant ≈ first point of the new road, remaining time, and progress along the NEW road.
- Map wiring: `world_map.dart:190-193` (listener on `_activeTravelOf` change → `follow`), :196-201 reread listener, :198-213 drag reset only on idle→active; camera frames the pawn only once on map ready (`_handleMapReady` :395-404) and on a focus request (`_consumeCharacterFocus` :422-427, uses `_travellingPawnPoint()` = live progress) → the `ambushDefeat` tap (popup `focusCharacterOnMap`) centres on the rerouted pawn. `travel_route_layer.dart` draws travelled (solid) + remaining (dashed) from the progress state; `character_marker_layer.dart:145-147` label = `formatGameDuration(remainingTime)`; nothing caches the first travel. `TravelCubit`/`TravelOutcomeListener` react only to null↔non-null `activeTravel` (`travel_outcome_listener.dart:36-40, 79-80`) → a non-null→non-null rewrite is invisible to them (correct).
- Widget proof: `world_map_travel_test.dart` harness (`pumpWorldMap(character:, serverNow:)`, `characterStates.add(...)`, `routePolylines(tester)`, `pawnAt`, `serverClock`; e.g. :297-310, :312-329, :392-411): pump mid-travel, add `characterLoaded(activeTravel: <rewritten json>)`, pump → polylines start at the ambush point and the label shows the new remaining time; then `mapFocusCubit.requestCharacterFocus()` → centre at the rerouted pawn. Fixture note: wire coordinates are `[lat, lng]` (`travel_fixtures.dart:1-5`, the probe confirmed it — Pitfall 6).
- Conclusion: **no production change for AMBUSH-01's map half**; tests only.

### F7. Pinned tests to update RED first [VERIFIED: codebase]
| File:line | Pin | Change |
|-----------|-----|--------|
| `test/models/notification_category_test.dart:5-12` | values list «four categories in display order» | five, `ambushDefeat` last |
| same :14-22, :24-32, :35-52, :68-73 | storage keys, wire types, fromWireType, isPersonal | add `ambush_defeat`, `ambushDefeat`, personal |
| `test/repository/storage/notification_preferences_store_test.dart:40-45, :77-82` | `readAll` exact maps | add `ambushDefeat: true` (map equality fails otherwise) |
| `test/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit_test.dart:10-23` | `loaded()` helper map | add `ambushDefeat` param (otherwise silently default) |
| `test/screens/mainScreen/tabs/settings/components/notification_preferences_section_test.dart:72-91` | «four labelled switches in order» + key list | five, «Imboscate» after «Missione annullata», `ambush_defeat` |
| `test/screens/mainScreen/components/notification_intent_landing_test.dart:210-215` | registry keys `{travelEnd, questEnd}` | add `ambushDefeat`; new test «an ambushDefeat tap only latches the camera focus» mirroring :159-180 |
| `test/models/push_event_test.dart` (case at :53-58 for `questCancelled`) | per-type parse | add an `ambushDefeat` case with `id` |
| `test/graphql/quest_result_documents_test.dart:30-95` | `contains` selections | new tests: `kind` selected, `ambush { at nearCity { id name } reachedCity { id name } }` selected |
| `test/models/quest_result/quest_result_test.dart:24-26, 65, 74, 83, 220-221` | `result.quest.x` | null-aware (compile), plus new groups `kind`/`ambush`/nullable `quest` |
| same :370-398 | round trip over fixtures | add ambush fixtures |
| `test/tool/schema_check_documents_test.dart:32-34` | 45 documents | unchanged (proves no new document) |
| `test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart:159-183` | five placeholders, row order | add a D-07 pin: labels exactly `Distanza, Durata, Arrivo, Cibo, Vita` in order and no text containing «Imbosc» |
| `test/models/quest/quest_travel_line_test.dart` | line text | add a D-07 pin that `QuestTravelLine.of` output is unchanged (no ambush wording) |

Analyzer baseline: `flutter analyze` → `50 issues found.` (all info; measured this session). Formatter: the files this phase will touch (28 lib/test files listed in F1–F7, copied to the scratchpad and checked with `dart format --output=none --set-exit-if-changed`) are all **format-clean** (`Formatted 28 files (0 changed)`); the known dirty files stay `city_markers_layer.dart`, `character_marker_layer.dart`, `lib/utils/map_utils.dart` (REPO-RULES; this phase touches none of them if the reroute needs no code).

### F8. Gate and UAT shapes [VERIFIED: 15-08/15-09 plans, `15-HUMAN-UAT.md`]
- 15-08 = autonomous gated plan: `git -C $BE fetch -q origin develop`; `git -C $BE show origin/develop:src/schema.gql > $SCRATCH/schema.gql`; gate grep (STOP + STATE park note if 0); `awk '/^type X /,/^}/'` blocks to prove every name; `dart run tool/schema_check/dump_documents.dart "$SCRATCH/docs"` («dumped 45 documents»); `NODE_PATH=$BE/node_modules node tool/schema_check/validate_documents.js "$SCRATCH/schema.gql" "$SCRATCH/docs" | grep -vc OK` → 0; full suite foreground; analyzer error/warning grep; per-new-file `dart format --output=none --set-exit-if-changed`; trailer grep over `develop..HEAD`; VALIDATION rows green, `wave_0_complete: true` (`15-08-PLAN.md:60-82`). For 16 the awk blocks are `type QuestResult` (`kind: QuestResultKind!`, `quest: QuestResultQuest` without `!`, `ambush: AmbushReport`), `enum QuestResultKind`, `type AmbushReport`, `type AmbushCity`, `enum PushEventType` (contains `ambushDefeat`). The push payload (`title`/`body`/`id`) is not in the SDL → read the BE Phase 15 `BACKEND-NOTES.md` via `git -C $BE ls-tree -r --name-only origin/develop .planning/phases | grep -i "15-.*BACKEND-NOTES"`.
- 15-09 = `autonomous: false`, `user_setup` with the BE runbook, re-check the gate, write `16-HUMAN-UAT.md` (frontmatter `status/phase/device/be_ref/date/verdict`; sections Setup, Session data, Session notes, Steps table «Step | Requirements | Decisions | Expected | Result | Note»), blocking human checkpoint, results only from the user's words, `requirements mark-complete` per passed id, ROADMAP/STATE/REQUIREMENTS closed, FE `BACKEND-NOTES.md`, secrets grep `mongodb(\+srv)?://|token=|password` = 0.
- DB tricks the orchestrator needs (BE CONTEXT D-05/D-16, to be confirmed by the BE handoff §«Dati per la UAT»): the internal `activeTravel.ambush { at, km }` (never on the wire) moved into the past + the ambush sweep (reconciler/sweep filter `activeTravel.ambush.at ≤ now`); `status.currentLifePoints` seeded low to force a defeat (HP never below 1); two ambushes for the carousel = win one (high HP) and let the redraw schedule a second, then move its `at` back again; reports held until arrival → close the travel with coherent `startTime`/`endTime` (shifting only `endTime` is invalid, `15-HUMAN-UAT.md` Session data). Short trips rarely draw an ambush (16 km ≈ 3 % by day, BE D-01) → the field may not exist and must be **seeded whole** — Open Question 5 for the BE handoff. The lost-ambush step needs a standard-lane quest with a road marker (hunt/enemy) to prove «quest lane freed».
- Proposed UAT steps: (1) won ambush on a free travel → no push, no Map change, HP down in the Journal, at arrival `travelEnd` + one-page carousel with coins and XP, no «Missione conclusa» banner; (2) lost ambush on a quest travel → push/banner «Imboscata!» with the city, tap → Map centred on the pawn restarting from the point with the new dashed route and remaining time, quest lane empty on the Board; at arrival carousel with «Sconfitta», «Portato a <città>», no rewards; (3) two ambushes → two pages «1 di 2»/«2 di 2», chronological, one «Continua» acks both (cold restart shows nothing again); (4) settings toggle «Imboscate» off → no push/banner on a defeat, pawn still reroutes; (5) confirmation sheet and quest «Viaggio» line unchanged; (6) optional GM teleport mid-travel delivers the held reports.

### F9. Conventions and runtime [VERIFIED]
- Harness classes per area (`QueueHarness`, `_PresenterHarness`), buses `AppLifecycleEventBus`/`ConnectionRestoredBus`/`UserRefreshRequestBus`, fakes `FakePendingQuestResults` (`results`/`error`/`hold`/`calls`), `RecordingQuestResultAcknowledger` (`acknowledged`/`calls`/`error`/`errorOnce`/`hold`), `FakeServerClockService` (`advance`, `resync`), mocks `MockQuestResultRepository`, `MockQuestResultsCubit` (`test/helpers/mocks.dart:100,147`), `buildTestApp`, `useLandscapePhone`, `seedSvgCache`. Test titles end with the decision id `(D-NN)`.
- Full suite at 15-08: `01:16 +3310: All tests passed!` (`15-08-SUMMARY.md:108`); budget ≥ 300 000 ms Bash timeout, foreground.

### Anti-Patterns to Avoid
- A second «showing» field or a separate carousel cubit: the queue is the single owner (09-CONTEXT D-08); widen the existing state.
- Composing the defeat banner on the FE or parsing the city from `body` (the BE composes both, REPO-RULES :35).
- A debounce `Timer` in the presenter for the batch: use the atomic list read (deterministic, testable with `FakePendingQuestResults.hold`).
- Deriving «no rewards on a loss» on the client: render what the BE sends.
- Showing the carousel counter AND a second dots indicator.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Page indicator | custom dots widget | the existing «k di N» counter (`quest_result_sheet.dart:431-436`) | already gated on `total > 1`, tested (:526-546) |
| Reroute interpolation | client polyline splice | `TravelProgressCubit.follow` as is | proven by the probe; BE rewrites from the point |
| Batch completeness | timers / guess windows | `refetchPending()` (single-flight, silent retry) | the BE inserts the batch in one transaction |
| Ack of N ids | parallel futures | `_acknowledgeQuietly` per id through `_serialised` | BE may reorder parallel mutations (:68-70) |
| Banner text | FE copy constants | push `title`/`body` | BE-composed (REPO-RULES :35) |

## Runtime State Inventory
Not a rename/migration phase. One persisted item is new: the preference key `klimmeck.notifications.<userId>.ambush_defeat` (SharedPreferences), absent until toggled → default enabled; no migration. None in other categories (verified: no build artifacts, OS registrations, or secrets carry a phase-16 name).

## Conflicts

- **C1 (CONTEXT D-08 «`PushEvent` parsing carries the city name additively» and D-02 «the foreground path publishes the in-app banner with the title «Imboscata!» and the body …»; BE CONTEXT D-12 «il FE compone il banner») vs. REPO-RULES/BE `15-REPO-RULES.md:35` (the BE composes `title`/`body`, «nothing is parsed from the body»).** The code path (`PushEvent.tryParse` → `notification`) already renders BE `title`/`body` for every category. **Recommendation:** follow the REPO-RULES — no `PushEvent` change, no FE copy constant, no city field; amend D-08 by striking «`PushEvent` parsing carries the city name additively» and «notice copy». Tests pin that an `ambushDefeat` message with the BE strings yields a banner with exactly those strings.
- **C2 (CONTEXT D-05 «the ambush reports of the same travel open in one carousel» vs. the grouping rule «consecutive `kind == ambush` at the head»).** If the user has unacknowledged reports of two travels (e.g. never opened the app between two arrivals), the head run merges them into one carousel; there is no travel id on the wire to split them. **Recommendation:** accept (rare; chronological order still holds) and say so in BACKEND-NOTES; ask the BE only if the user wants a split (would need e.g. `ambush.travelStartedAt`).
- **C3 (minor, CONTEXT `code_context` «`quest_result_presenter.dart` `questEnd|<id>` banner :115-140»).** The banner logic is `_announceArrival` :111-123 (+ `_isQuestEndBannerEnabled` :125-128); :130-140 is `_announceNotice` (tap-lookup notices), which must NOT change. Line refs only.

## Common Pitfalls

### Pitfall 1: A page of the open carousel re-enters the queue
**What goes wrong:** `_isKnown` (`quest_results_cubit.dart:343`) checks only `state.showing?.id`; a refetch (resume, reconnect) or a duplicate live event of page 2 while the carousel is open re-queues it; after «Continua» acks it, it opens again (and is acked twice).
**How to avoid:** `_isKnown` over the whole showing group; test «a live duplicate of a showing page is ignored (D-05)».

### Pitfall 2: Nullable `quest` breaks the analyzer gate mid-plan
**What goes wrong:** the model commit makes `quest_result_sheet.dart:172,181` and `quest_result_test.dart` (7 lines) compile errors.
**How to avoid:** the model plan includes the minimal null-aware header and test edits in the same GREEN commit (the ambush header comes later).

### Pitfall 3: The first ambush opens alone (live batch race)
**What goes wrong:** N change-stream events arrive one by one; the presenter opens the head at the first emission on a free Map.
**How to avoid:** live ambush → emit with `pendingRefetch: inFlight` + `refetchPending()`; presenter waits while `isSettlingAmbushes`. Cold start/resume reads are already atomic.

### Pitfall 4: «Continua» on page 1 acknowledges unseen pages
**What goes wrong:** every page carries the button; a literal D-05 closes and acks the whole group from page 1.
**How to avoid:** Open Question 1 (recommend advance-then-close).

### Pitfall 5: `pumpAndSettle` hangs in carousel/sheet tests
**What goes wrong:** an unseeded Cloudinary SVG (e.g. `emptyCardSheet` used by `ItemRow`) keeps an animation alive; the probe timed out until it was seeded.
**How to avoid:** copy the seven-asset `seedSvgCache` list of `quest_result_sheet_test.dart:61-72` / `quest_result_presenter_test.dart:159-167`.

### Pitfall 6: Fixture coordinates are `[lat, lng]`
**What goes wrong:** a reroute fixture built as `[lng, lat]` from `LatLng` puts the first point elsewhere and the «restarts from the ambush point» assertion fails (seen in the probe).
**How to avoid:** `[point.latitude, point.longitude]` (`travel_fixtures.dart:1-5`).

### Pitfall 7: The FE branch cannot talk to an unmerged BE
**What goes wrong:** once `QuestResultFragment` selects `kind`/`ambush`, every result document (including the innkeeper `CompletePendingRequest`) fails validation on a BE without Phase 15 → the result pipeline is dead on that BE.
**How to avoid:** expected under D-09; never run the branch against an old BE, never merge FE before BE. Note it in the SUMMARY of the fragment plan.

### Pitfall 8: Position/total drift after a group
**What goes wrong:** `position + 1` for a 2-page carousel makes the next quest sheet read «2 di 2» when 3 results were in the batch, or negative positions after an external pop.
**How to avoid:** `position ± group.length` (floor 0) and tests for both directions.

### Pitfall 9: The quest-end toggle silences nothing for ambushes, the ambush toggle must not gate the carousel
**What goes wrong:** gating the carousel or the reroute on `ambushDefeat`'s toggle.
**How to avoid:** the toggle filters only the push/banner (`data_message_handler.dart:21`); sheets are never gated (Phase 9 test «the quest toggle off silences the banner, never the sheet», presenter test :207).

### Pitfall 10: Greps and tall-style formatting
Same as 15: acceptance greps anchored to one identifier; the `PageView` children comprehension and `switch` arms reflow under `dart format`.

## Code Examples

### Tolerant kind (pattern: `QuestResultQuest.fromJson` type read, `quest_result_quest.dart:17-24`)
```dart
enum QuestResultKind {
  quest,
  ambush;

  /// Missing or unknown kinds read as a quest (Phase 13 tolerant rule, D-01).
  static QuestResultKind fromWire(Object? value) =>
      (value is String ? values.asNameMap()[value] : null) ?? quest;
}
```

### Parsing branch inside `QuestResult.fromJson`
```dart
final kind = QuestResultKind.fromWire(json['kind']);
final isAmbush = kind == QuestResultKind.ambush;
// quest: strict for quests (cast throws → tryFromJson drops), tolerant for ambushes
quest: isAmbush
    ? _questOrNull(json['quest'])
    : QuestResultQuest.fromJson(json['quest'] as Map<String, dynamic>),
ambush: isAmbush
    ? AmbushReport.fromJson(json['ambush'] as Map<String, dynamic>)
    : null,
```

### Group in the state
```dart
List<QuestResult> get presentable {
  final head = this.head;
  if (head == null) return const [];
  if (!head.isAmbush) return [head];
  return List.unmodifiable(queue.takeWhile((result) => result.isAmbush));
}
```

## State of the Art
| Old | New | Impact |
|-----|-----|--------|
| `QuestResult.quest` non-null (Phase 9) | nullable, required only for `kind == quest` | one lib reader (sheet header) |
| one sheet per presentation (09 D-08) | presentation unit = group (singleton for quests, run of ambushes) | cubit/presenter widen, quest path unchanged |
| four push categories | five | settings shows five switches |

## Assumptions Log
| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The BE change stream emits the N inserted reports only after the arrival transaction commits, so a list read triggered by the first event sees all N [ASSUMED: MongoDB change streams report committed operations; BE D-13 says «nella stessa transazione»] | F2, Pitfall 3 | carousel may still split; fallback = chain a second read |
| A2 | On a defeat the BE sends `rewards.coins` all zero and `xpGained: 0` (BE D-10 rewards only on victory) [CITED: BE 15-CONTEXT D-10/D-11; not yet in a handoff] | F4 | a loss sheet would show coins/XP; then branch on `outcome` in the sheet |
| A3 | Seeding a whole `activeTravel.ambush { at, km }` makes the sweep resolve it [ASSUMED] | F8 | UAT needs another trick from the BE handoff |
| A4 | `dart format` of the copied files in the scratchpad matches the repo's formatter config (language version read without the package config) [ASSUMED] | F7 | an executor may see a reflow on first format; note it in SUMMARY |

## Open Questions (RESOLVED — orchestrator 2026-11-06: OQ1 «Continua» advances pages, closes + acks all on the last page, pending the user's veto → CONTEXT D-05 revised; OQ2 one read per live ambush + one chained read if another arrives in flight → D-12; OQ3 «k di N» reused → D-05; OQ4 «Portato a» after «Ferite» → D-13; OQ5 forwarded to the BE Phase 15 CONTEXT/REPO-RULES (UAT seeding of `activeTravel.ambush`, sweep by `ambush.at`, push payload with `sentAt` built like `travelEnd`); OQ6 C1 amendment confirmed → D-02/D-08/D-10; OQ7 C2 accepted → D-16)
1. **«Continua» on a non-last page.** Recommendation: advance to the next page (`animateToPage`, same label «Continua»), close + ack all on the last page; alternative = literal D-05 (close from any page). Needs the user's ok (UX, device-reviewed).
2. **Batch settling depth.** Recommendation: one list read per live ambush arrival, presenter waits while it is in flight; accept the theoretical stale in-flight read. Alternative: when a live ambush arrives during an in-flight read, chain one more read.
3. **Page indicator style.** Recommendation: reuse «k di N» (zero layout, tested); alternative: dots under the parchment (new widget, theme `primaryGold`/`paleSilver`).
4. **«Portato a» position.** Recommendation: right after «Ferite»; alternative: last line before the footer.
5. **For the BE handoff (orchestrator to BE):** how to force an ambush when the departure draw did not hit (seed the whole `activeTravel.ambush { at, km }`? which `km`?), whether shifting `startTime/endTime` to close a travel with a pending ambush is safe (job identity includes `startTimeMs`), and confirm the `ambushDefeat` payload `{type, id, title, body, sentAt}` with `sentAt` present (the FE drops a push without `sentAt`, `push_event.dart:30-31`).
6. **C1 amendment** of D-08 (no `PushEvent` change) — orchestrator to confirm.
7. **C2** — accept the merge of two travels' reports in one carousel?

## Environment Availability
| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK / `flutter test` / `flutter analyze` | all plans | ✓ | analyzer ran (50 info) | — |
| BE `origin/develop` with `AmbushReport` | 16-08, 16-09 | ✗ (count 0 at `b492a46`) | — | park gated plans (D-09) |
| BE `node_modules` for `validate_documents.js` | 16-08 | ✓ (used at 15-08) | — | — |
| Android device + local BE | 16-09 | human checkpoint | — | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test` + `mocktail` + `fake_async` (existing) |
| Config file | none beyond `pubspec.yaml` / `analysis_options.yaml` |
| Quick run command | `flutter test <touched test files>` (e.g. `flutter test test/models/quest_result test/graphql/quest_result_documents_test.dart`) |
| Full suite command | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (foreground, ~76 s, 3310+ tests) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AMBUSH-01 | reroute restarts pawn/route/time (D-03) | unit (fakeAsync) | `flutter test test/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit_test.dart` | ✅ (add cases) |
| AMBUSH-01 | map follows the rewritten travel, focus on the rerouted pawn | widget | `flutter test test/screens/mainScreen/tabs/map/world_map_travel_test.dart` | ✅ (add cases) |
| AMBUSH-01 | `ambushDefeat` enum/storage/wire/personal | unit | `flutter test test/models/notification_category_test.dart test/models/push_event_test.dart` | ✅ |
| AMBUSH-01 | settings «Imboscate» toggle, preferences maps | widget/unit | `flutter test test/screens/mainScreen/tabs/settings test/repository/storage/notification_preferences_store_test.dart` | ✅ |
| AMBUSH-01 | tap → Map + focus | widget | `flutter test test/screens/mainScreen/components/notification_intent_landing_test.dart` | ✅ |
| AMBUSH-01 | foreground banner shows BE title/body; toggle off drops | unit | `flutter test test/repository/services/push/foreground_push_events_test.dart test/repository/services/push/data_message_handler_test.dart` | ✅ |
| AMBUSH-02 | `kind`/`ambush`/nullable `quest` parsing, drop rules, round trip | unit | `flutter test test/models/quest_result` | ✅ (+ new `quest_result_kind_test.dart`, `ambush_report_test.dart`) |
| AMBUSH-02 | fragment selects `kind`, `ambush { … }`; registry 45 | unit | `flutter test test/graphql/quest_result_documents_test.dart test/tool/schema_check_documents_test.dart` | ✅ |
| AMBUSH-02 | ambush header, «Portato a», won rewards/XP, lost none | widget | `flutter test test/shared/components/popup/quest_result_sheet_test.dart` | ✅ |
| AMBUSH-02 | carousel pages, counter only > 1, Continua behaviour | widget | `flutter test test/shared/components/popup/ambush_report_carousel_test.dart` | ❌ Wave 0 |
| AMBUSH-02 | group present/close/ack all/requeue/dedup/settling | cubit | `flutter test test/screens/mainScreen/questResultsCubit` | ✅ (add cases) |
| AMBUSH-02 | presenter opens the carousel, no questEnd banner for ambushes, quest after | widget | `flutter test test/screens/mainScreen/components/quest_result_presenter_test.dart` | ✅ (add cases) |
| AMBUSH-03 | confirmation sheet rows exactly Phase 15; quest «Viaggio» line unchanged | widget/unit | `flutter test test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart test/models/quest/quest_travel_line_test.dart` | ✅ (add pins) |
| all | merged-schema validation 45 × OK | gate | `dart run tool/schema_check/dump_documents.dart` + `validate_documents.js` | ✅ (16-08) |
| all | device E2E | manual | `16-HUMAN-UAT.md` | ❌ (16-09) |

### Sampling Rate
- **Per task commit:** the touched test files.
- **Per plan:** the plan's test directories + repo-wide `flutter analyze` (0 error / 0 warning).
- **Phase gate (16-08):** full suite foreground, analyzer, format of new files, trailer grep, schema check 45 × OK.

### Wave 0 Gaps
- [ ] `test/shared/components/popup/ambush_report_carousel_test.dart` — new (carousel).
- [ ] `test/models/quest_result/quest_result_kind_test.dart`, `ambush_report_test.dart` — new (models).
- [ ] Fixtures `ambushWonResultJson`, `ambushLostResultJson`, `ambushReportJson` in `test/helpers/fixtures/quest_result_fixtures.dart`.
- No framework install needed.

### Manual-only
Device E2E (16-09, `16-HUMAN-UAT.md`): push/banner on a real defeat, live reroute on the phone, carousel at arrival, toggle off, confirmation sheet unchanged — the BE timing (sweep, change stream, FCM) cannot be reproduced in widget tests.

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2/V3 Authentication/Session | no (unchanged) | — |
| V4 Access Control | yes (owner-only results, BE-enforced) | BE change stream owner-only; FE never fetches other users' results |
| V5 Input Validation | yes | tolerant per-item parsing, `tryFromJson` boundary, `validBackendIdentifier` on push `id` (`push_event.dart:39`), unknown push types dropped |
| V6 Cryptography | no | — |

| Threat | STRIDE | Mitigation |
|--------|--------|-----------|
| Malformed ambush report crashing the queue | DoS | `tryFromJson` → null, per-item drop; strict `ambush` for `kind == ambush` |
| Spoofed push `id`/type | Spoofing | `validBackendIdentifier`, unknown type dropped, payload never carries state (rule 4); tap only focuses the camera |
| Push text injection | Tampering | rendered as plain `Text` from `title`/`body`, never a URL (router opens only `TwitchChannel.uri`) |
| Ack replay/double ack | Tampering | ack idempotent on BE (9.2 D-03); group dedup (Pitfall 1) |

## Sources

### Primary (HIGH confidence)
- Codebase files cited by path:line (read this session); probes: `TravelProgressCubit` reroute (GREEN), `PageView` carousel in `showGeneralDialog` (GREEN after seeding `emptyCardSheet`) — both deleted, `git status --short` clean apart from the orchestrator's untracked files.
- BE `origin/develop:src/schema.gql` at `b492a46` (`type QuestResult`, `enum PushEventType`; `AmbushReport` count 0).
- BE `09.2-quest-result-delivery-contract/BACKEND-NOTES.md:155, :243` (ordering, cap).

### Secondary (MEDIUM confidence)
- BE `15-imboscate-in-viaggio/15-CONTEXT.md` D-01..D-16 and `15-REPO-RULES.md:29-45` (contract names, push payload) — not yet merged.
- `.planning/phases/15-travel-food/15-08-PLAN.md`, `15-09-PLAN.md`, `15-08-SUMMARY.md`, `15-HUMAN-UAT.md` (gate/UAT shapes, suite runtime).

## Metadata
**Confidence breakdown:** model/queue/presenter/category facts HIGH (code read + probes); BE contract MEDIUM (agreed, unmerged); batch-race mitigation MEDIUM (A1).
**Research date:** 2026-11-06 — **Valid until:** the BE Phase 15 merge (re-check names in 16-08).

## RESEARCH COMPLETE
