# Phase 15: Travel Food - Research

**Researched:** 2026-11-05
**Domain:** Flutter wire-contract extension (travel preview + new owner-only query), cubit state machine (starvation re-preview), parchment sheets (confirmation sheet rows, quest-sheet travel line), failure classifiers
**Confidence:** HIGH for code facts (file:line read this session, targeted tests run green); MEDIUM for the BE names (fixed in the BE `14-REPO-RULES.md`, not yet on BE `origin/develop`)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01 (BE Phase 14 CONTEXT D-08/D-09, names final in the BE REPO-RULES and handoff):** `TravelPreview` gains, additively, `food: List<TravelFoodItem>` (`TravelFoodItem { item, quantity }` with `item` a `LootItem` carrying at least `id` and `name`), `hpLost: int` and `arrivesAlive: bool`; `GetTravelPreview` selects them. New document `GetQuestTravelPreview` for the owner-only query (e.g. `questTravelPreview(request: { id, questId })`) returning the **same `TravelPreview` type, nullable**: `null` means the acceptance involves no travel (marker = position, or an instant jump) and no line is shown. The registry grows to 45 documents and the schema check runs after the BE merge. Parsing stays tolerant (Phase 13 rule): a malformed `food` entry is dropped, a missing `food`/`hpLost`/`arrivesAlive` reads as empty / 0 / true so an older BE still renders the sheet. Models stay Flutter-free Equatable in `lib/models/travel/`.
- **D-02 (user decision):** **two rows under «Arrivo»** in the parchment sheet (`TravelConfirmationSheet`, same `_numberRow` language): «Cibo» = the BE list in BE order in the «Nx nome» format («1x Razione da viaggio, 1x Mela selvatica», wrapping) or «nessuno»; «Vita» = «−136 HP» or «nessuna perdita». Placeholders («…») until the preview answers, exactly as Distanza/Durata/Arrivo today. When `arrivesAlive == false` the «Vita» row turns **red** with the user's phrase **«Non hai cibo a sufficienza per il viaggio»** and **«Parti» is disabled** («Resta» stays). Nothing is computed on the client.
- **D-03 (user decision — «foglio aperto con anteprima rinfrescata», confirmed «solo per la fame»):** when `startTravel` is refused with `TRAVEL_STARVING` the sheet **stays open and the cubit re-requests the preview** (new quote: rows updated, «Parti» disabled if still starving); the banner is published as for every refusal. **Every other start refusal keeps the Phase 7 D-14 behaviour** (sheet closed, banner). The route preview on the map stays while the sheet is open.
- **D-04 (user decision):** **one compact line in the costs block** (where the narrative family shows «Punti canale»): «Viaggio: 1x Razione da viaggio · nessuna perdita», «Viaggio: nessun cibo · −136 HP», or red «Viaggio: Non hai cibo a sufficienza per il viaggio» with the **accept swipe disabled** (`TearablePaper(isEnabled: false)`). The line is **absent** while the preview is pending (no spinner), when the preview is `null` (no travel), when the preview fails (any failure: no banner, the swipe stays as today and the BE refusal remains the defence) and on read-only sheets (map overlay, busy lane, during a travel). The preview is requested when the sheet opens from the Board and the swipe would be available. Narrative sheets unchanged.
- **D-05 (user decision):** a `TRAVEL_STARVING` refusal of `acceptQuest` **recomposes the torn sheet** with today's mechanism (`TearablePaperState.recompose()`, Phase 6 D-03) and publishes the banner; no board reread.
- **D-06 (user decision, verbatim):** the phrase **«Non hai cibo a sufficienza per il viaggio»** is used everywhere: the red «Vita» row, the red «Viaggio» line and the body of both banners («Viaggio non partito» / «Missione non accettata»). `TravelFailure.starving` and `QuestAcceptanceFailure.starving` map `TRAVEL_STARVING`; dedup keys as today.
- **D-07 (user decision):** **no feedback after the departure**: the pawn leaves as today; the Journal shows the reduced food («Oggetti») and HP («Punti vita») through `characterUpdated`. The ROADMAP's «the Map the reduced HP» is read as the Journal: the Map renders no HP (research fact).
- **D-08 (technical default, for the veto):** a dedicated repository method (`TravelRepository.previewQuest(characterId, questId)` or equivalent, 15 s timeout, same `_guard`) and a small per-sheet cubit (e.g. `QuestTravelPreviewCubit`: idle → loading → loaded(preview?) / failed) provided by the Board when it opens an interactive sheet; `QuestSheetDetails` gains a pure travel-line model (text, isStarving) built from the preview; `TravelCubit` gains the starving re-preview transition (Starting → Previewing → Confirming) with the same `_previewToken` guard.
- **D-09 (technical default):** gating (pattern 13-10 / 14-10): plans before the BE merge build models, documents, sheets, cubits and classifiers on mocks with the names of the BE CONTEXT/REPO-RULES; after the merge the schema gate (`origin/develop:src/schema.gql`, dump + validate of every document, full suite, analyzer) and the device E2E (`15-HUMAN-UAT.md`, human checkpoint: trip fully covered, partially covered, refused; quest automatic travel line and refusal; teleport unaffected; food seeded at the DB for the test character) run; handoff `BACKEND-NOTES.md` closes the phase. TDD red → green → refactor for every change; `dart format` only on touched files; analyzer compared with the `develop` baseline (error/warning only); no `Co-Authored-By` trailer.

### Claude's Discretion
- Copy of the non-user strings («nessuno», «nessuna perdita», row labels), the food list formatting (separator, truncation of long lists), the exact position of the «Viaggio» line inside the combat/service bodies, whether the red rows also show the numbers, cubit/model/fixture names, how the Board hands the preview to the sheet.

### Deferred Ideas (OUT OF SCOPE)
- **HP on the Map** (pawn label or corner) — not in this phase; the Journal is the HP surface.
- **Food icons / item rows in the sheets** — text lines first; images later with the loot art.
- **Departure banner «Hai mangiato…»** — rejected for now (D-07).
- **Choosing the food manually** — the server chooses (BE D-05/D-06).
- **Ambush report** — Phase 16 (same result sheet pipeline).
- **`QUEST_IN_PROGRESS` missing from `QuestAcceptanceFailure`** — research fact, Boy Scout candidate if touched. *(Research: the BE acceptance never emits it — see Pitfall 9; recommend dropping the item.)*
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FOOD-01 | Confirmation sheet shows food + HP lost from `travelPreview`; red «Vita» + «Parti» disabled on `arrivesAlive: false` | §1 Models, §2 Documents, §4 Confirmation sheet rows, §5 Text helpers |
| FOOD-02 | Combat/service quest sheets show the travel cost line from the owner-only preview; red + swipe disabled when starving; absent without travel | §2 Documents/service/repository, §6 Quest sheet line, §7 Board wiring + `QuestTravelPreviewCubit` |
| FOOD-03 | `TRAVEL_STARVING` → banner; quest sheet recomposes; confirmation sheet stays open with refreshed preview | §3 Classifiers/notices, §4b `TravelRequoting` state machine, §7 recompose (already wired) |
| FOOD-04 | Inventory and HP only through `characterUpdated`; no client arithmetic | Verified already true: `characterUpdated` selects `CharacterFragment.fullFields` (`currentLifePoints` `character_fragment.dart:30`, `ownedItems` :88); Journal reads `CharacterCubit` live (`journal.dart:87-96`, `_buildOwnedItemsSection` :240). No code; covered by the device E2E + a negative review (no arithmetic on `food`/`hpLost`) |
</phase_requirements>

## Project Constraints (from CLAUDE.md)
- Clean Code, SoC (UI no networking; Cubit no Flutter imports, no `BuildContext`; models Flutter-free), TDD red→green→refactor, Boy Scout rule.
- Rule 1: no app chrome on gameplay surfaces (map sheet, board sheet). Rule 2: no blocking loading in session — the quest line simply appears; the confirmation sheet keeps «…» placeholders. Rule 3: branch `feat/15-travel-food`, PR → `develop`. Rule 4: backend is source of truth — no food/HP arithmetic, `arrivesAlive` is the only gate. Rule 5: no secrets.
- `flutter analyze` 0 error / 0 warning (baseline 50 info, measured this session); `dart format` only on touched files (never a directory); no `Co-Authored-By` trailer; docs scope `docs(phase-15)`.
- `docs/rules/state-management.md`: Cubit folder lowerCamelCase, sealed Equatable states, `BlocListener` for side effects, a Cubit never calls a Cubit (orchestration via UI listeners), `bloc_test` for every non-trivial cubit.
- `docs/rules/graphql.md`: named operations, fields reused in ≥ 2 operations live once in `lib/graphql/fragments/`, never raw `OperationException` to the UI.
- `docs/rules/ui-ux.md`: theme tokens only (`kg_theme.dart`); the travel confirmation rule still says «nessun costo» (`docs/rules/ui-ux.md` §Gesture: «Travel conferma: … nessun costo») — must be amended in this phase (Pitfall 10).
- `15-REPO-RULES.md` (already written by the orchestrator, untracked on the branch) fixes: `TravelFoodItem`, `GetQuestTravelPreview`, `KlimmeckGraphQl.previewQuestTravel`, `TravelRepository.previewQuest`, `TravelFailure.starving`, `QuestAcceptanceFailure.starving`; gate grep `TravelFoodItem` on BE `origin/develop`; code scopes `travel`, `quest`, `board`, `models`, `graphql`, `repository`.

## Summary

The phase is small on the wire (three additive fields, one nullable query, one error code) but has one real design problem: the D-03 «sheet stays open on starvation» flow collides with three existing behaviours that all key on `TravelFailed`: the sheet pops itself on `TravelFailed` (`travel_confirmation_sheet.dart:57-60`), `TravelOutcomeListener` announces and then calls `reset()` → `TravelIdle` (`travel_outcome_listener.dart:34-38`), and the route layer draws nothing for `TravelPreviewing`/`TravelFailed` (`travel_route_layer.dart:69-72`). The CONTEXT D-08 transition «Starting → Previewing → Confirming» would therefore make the dashed route disappear during the re-preview, violating D-03's «the route preview on the map stays». The recommended mechanism is a new `TravelQuote` subclass, `TravelRequoting`, emitted instead of `TravelFailed` for the starvation code only: it keeps destination + last preview (route and pawn stay), it is not a `TravelFailed` (no pop, no reset), the outcome listener announces on entering it, and the cubit follows with the preview under the existing `_previewToken`.

The quest-sheet side reuses everything: `QuestAcceptanceFailed` already recomposes the sheet (`board.dart:195-201`) and the session listener already publishes every failure's banner and resets (`quest_acceptance_outcome_listener.dart:43-47`), so D-05 needs only the classifier + copy. The new work is a per-sheet `QuestTravelPreviewCubit` created inside the Board's keyed sheet subtree (`board.dart:259-261`), fed by `TravelRepository.previewQuest`. Today `TravelRepository` is built inline inside the `TravelCubit` provider (`authenticated_shell.dart:233-238`), so the Board cannot reach it: add a `RepositoryProvider<TravelRepository>` to the shell and give the Board tests a mock (Wave 0). Both `TravelPreview` consumers share the text helpers and the user phrase constant.

The schema gate is **not passed**: BE `origin/develop` = `698ae82` (fetch succeeded this session), `grep -c "TravelPreview {"` shows only `distance/duration/road` and `TravelFoodItem`/`questTravelPreview`/`arrivesAlive` are absent. The BE Phase 14 has CONTEXT, REPO-RULES and VALIDATION only (no plans yet).

**Primary recommendation:** 7 ungated plans (models + text helpers → documents/registry/service → repository + classifiers + notices → `TravelCubit` `TravelRequoting` + listener + map layers → confirmation sheet rows → quest-sheet line model + widget → `QuestTravelPreviewCubit` + shell provider + Board wiring) + 2 gated plans (schema gate 45/45, device E2E + `BACKEND-NOTES.md`).

## Standard Stack (all already locked, no new dependency)

| Library | Version | Use in this phase |
|---------|---------|-------------------|
| flutter | 3.35.5 stable | — [VERIFIED: `flutter --version`] |
| flutter_bloc / bloc_test | ^9.1.1 / ^10.0.0 | `TravelCubit` extension, new `QuestTravelPreviewCubit` [VERIFIED: pubspec.yaml] |
| mocktail | ^1.0.5 | `MockTravelRepository` (exists, `mocks.dart:98`), new `MockQuestTravelPreviewCubit` if widget tests need it |
| fake_async | ^1.3.3 | already used by `travel_cubit_test.dart` |
| graphql_flutter / gql | ^5.2.1 | documents, `Link.function` service tests, registry test parses with `gql` |
| equatable | ^2.0.0 | models and states |
| auto_size_text | ^3.0.0 | sheet rows (`_numberRow`) |
| graphql-js (BE node_modules) | 16.11.0 | `validate_documents.js` in the gated plan [VERIFIED: BE `node_modules/graphql/package.json`] |

## Architecture Patterns

### Recommended files
```
lib/models/travel/travel_food_item.dart        # TravelFoodItem {item: LootItem, quantity}, tolerant list parser
lib/models/travel/travel_preview.dart          # + food, hpLost, arrivesAlive (defaults [], 0, true)
lib/models/travel/travel_cost_text.dart        # starvingPhrase, foodText(), lifeText() — pure, shared
lib/models/quest/quest_travel_line.dart        # QuestTravelLine {text, isStarving}.of(TravelPreview?)
lib/graphql/fragments/travel_preview_fragment.dart  # shared selection (2 operations, graphql.md)
lib/graphql/queries/travel_queries.dart        # + getQuestTravelPreview
lib/screens/mainScreen/tabs/board/questTravelPreviewCubit/
    quest_travel_preview_cubit.dart + quest_travel_preview_state.dart
```

### 1. Models (D-01) [VERIFIED: codebase]
- `TravelPreview` today: `distance`, `duration`, `road`, strict `fromJson` (`travel_preview.dart:18-22`), `toJson` :24-28, `props` :31. Add `final List<TravelFoodItem> food; final int hpLost; final bool arrivesAlive;` with constructor defaults `const []`, `0`, `true` so the only constructor call sites (the factory itself — no other `TravelPreview(` in lib/test, verified by grep) keep compiling.
- Tolerant reads (Phase 13 rule): `food: TravelFoodItem.listFrom(json['food'])` (not a `List` → `const []`); `hpLost: json['hpLost'] is num ? (json['hpLost'] as num).toInt() : 0`; `arrivesAlive: json['arrivesAlive'] is bool ? json['arrivesAlive'] as bool : true`. `distance/duration/road` stay strict (a malformed core still throws → `FormatException` in `_travelPreviewFrom`, `graphql.dart:783-792`).
- `TravelFoodItem.listFrom`: keep entries that are `Map<String, dynamic>` with `item` a map whose `name` is a non-empty `String` and `id` a `String`, and `quantity` a `num` ≥ 1; drop everything else (per entry, `try/catch` around `LootItem.fromJson`, because `LootItem.fromJson` uses `EffectType.values.byName`/`RarityType.values.byName` and throws on unknown names, `loot_item.dart:35-40`). Return `List.unmodifiable`, BE order preserved.
- Selection `item { id name }` only: `LootItem.fromJson` tolerates missing `description` (`?? ''`, :27), `effect`, `rarity`, prices (all null-checked) [VERIFIED: `loot_item.dart:23-41`]. Round trip: `toJson` → `{'item': item.toJson(), 'quantity': quantity}`; `LootItem.toJson` writes `description: ''` and nulls, which re-parse equal → `TravelPreview.fromJson(p.toJson()) == p` holds (existing test `travel_preview_test.dart:15-17`).
- `AssetQuantity` (`asset_quantity.dart`) is NOT reused: its `item` is an `AssetItem` union (`AssetItem.fromJson` dispatches on `equipType`) and its `quantity` is nullable; `TravelFoodItem` needs `LootItem` + `int` and stricter dropping.

### 2. Documents, service, repository (D-01, D-08) [VERIFIED: codebase; names CITED: `15-REPO-RULES.md`, BE `14-REPO-RULES.md`]
- Shared selection (graphql.md: fields reused in ≥ 2 operations live in `fragments/`): `lib/graphql/fragments/travel_preview_fragment.dart` with a `static const String fields` = `distance duration road { coordinates distance } food { quantity item { id name } } hpLost arrivesAlive`. The existing documents are `r'''…'''` raw strings with `$request` (`travel_queries.dart:4-14`); with interpolation switch to non-raw + `\$request` (the pattern of `character_subscriptions.dart`) or `static String get`.
- `GetQuestTravelPreview`:
  ```graphql
  query GetQuestTravelPreview($request: AcceptQuestRequest!) {
    questTravelPreview(request: $request) { …same fields… }
  }
  ```
  `AcceptQuestRequest { id, questId }` exists (`lib/models/request/accept_quest_request.dart`, `toJson` = `{'id','questId'}`).
- `KlimmeckGraphQl.previewQuestTravel(AcceptQuestRequest) → Future<TravelPreview?>`: `performQuery` (`noCache`, `graphql.dart:77-89`); `_dataOrThrow` returns `result.data ?? const {}` (:762-766). Recommended: `if (!data.containsKey('questTravelPreview')) throw FormatException(...)`; value `null` → `null`; a `Map` → `_travelPreviewFrom` (reuse); anything else → `FormatException`.
- `TravelRepository.previewQuest({required String characterId, required String questId}) → Future<TravelPreview?>` = `_guard(() => _graphQl.previewQuestTravel(AcceptQuestRequest(id: characterId, questId: questId)))` (`travel_repository.dart:58-68`, 15 s timeout :25). The classifier maps `FORBIDDEN`/`NOT_FOUND`/`QUEST_NOT_IN_CITY`; the last falls to `TravelFailure.unknown` — irrelevant because D-04 hides the line on any failure.
- Registry `tool/schema_check/schema_check_documents.dart:42-89` (44 entries; doc comment :26-41 lists the per-phase additions — add «la Phase 15 aggiunge `GetQuestTravelPreview`»). Count test `test/tool/schema_check_documents_test.dart:32-34` pins `44` → `45` RED first; the name-set test :28-30 reads `lib/graphql/{queries,mutations,subscriptions}` so the new operation must be in `queries/` and registered.
- **`test/graphql/travel_documents_test.dart:38-46` pins the exact collapsed selection** `'travelPreview(request: $request) { distance duration road { coordinates distance } }'` — update it in the same commit that adds the fields (REPO-RULES: model + document in the same commit), and add a `GetQuestTravelPreview` group (single query, `AcceptQuestRequest!` variable, selection, registered).

### 3. Classifiers and notices (D-06) [VERIFIED: codebase]
- `lib/repository/travel_failure.dart`: add `const String travelStarvingCode = 'TRAVEL_STARVING';` next to the codes :6-11, enum value `starving` (doc: BE Phase 14 D-11), switch arm `travelStarvingCode => TravelFailure.starving` in `travelFailureFrom` :58-69.
- `lib/repository/quest_acceptance_failure.dart`: extend the `show` import :5-6 with `travelStarvingCode`, enum value `starving`, arm in :59-73.
- Notices: `travelNoticeFor` (`travel_notice.dart:8-30`) and `questAcceptanceNoticeFor` (`quest_acceptance_notice.dart:9-48`) are **exhaustive switches** → the compiler forces the new arm. Both arms → the shared constant `starvingPhrase` (§5). Titles stay `travelNoticeTitle` «Viaggio non partito» (:4) / `questAcceptanceNoticeTitle` «Missione non accettata» (:5).
- Dedup keys unchanged: `'travel|${failure.name}|${destination.id}'` (`travel_outcome_listener.dart:50`) → `travel|starving|<cityId>`; `'quest-acceptance|${failure.name}|${questId}'` (`quest_acceptance_outcome_listener.dart:66`). `publishNotice` suppresses an equal key only for the display window (5 s, `in_app_notifications_cubit.dart:33,64-72`) [VERIFIED].
- `starving` is NOT in `_staleListFailures` (`quest_acceptance_outcome_listener.dart:27-32`) → no board reread (D-05) with zero code.
- Tests to extend: `test/repository/travel_failure_test.dart:15-31` (`byCode` map), `test/repository/quest_acceptance_failure_test.dart` (same shape), `test/screens/mainScreen/travelCubit/travel_notice_test.dart:8-36` (`descriptions` map; the «no technical token» test :42-50 iterates `TravelFailure.values`), `test/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice_test.dart`.

### 4. Confirmation sheet (D-02) [VERIFIED: codebase]
- `_content` :76-99 renders `_numberRow` × 3 (:92-94) from `_numbersOf` :101-110 (record `_TravelNumbers` :11). Extend the record with `food`, `life`, `isStarving` filled from `TravelQuote.preview` via the §5 helpers; add `_numberRow(context, 'Cibo', numbers?.food, maxLines: 3)` and `_numberRow(context, 'Vita', numbers?.life, maxLines: 2, isAlarm: numbers?.isStarving)` — or better (Clean Code, no boolean flag) pass a nullable `TextStyle? valueStyle` / a dedicated `_lifeRow`. `_numberRow` today forces `AutoSizeText(maxLines: 1)` (:129-138): the phrase and a long food list would shrink to an unreadable font; D-02 says the food list wraps.
- Red token: `KlimmeckGuideTheme.bloodRed` (`kg_theme.dart:45`), the same colour `_costLine` uses for `isInsufficient` (`quest_info_sheet.dart:315`) and `_titleLine` for ineligibility (:301). Placeholder style stays `darkBronze` (:133-136).
- «Parti» (`_actions` :145-166): `onPressed: state is TravelConfirming && state.preview.arrivesAlive ? start : null`. «Resta» unchanged (disabled only in `TravelStarting`, :151). The disabled look is the `TextButton` default disabled foreground (no new token); tests assert `onPressed` is null (pattern `departButton(tester).onPressed`, `travel_confirmation_sheet_test.dart:130-131`).
- Doc comment :13-18 («Nessun costo (BE Phase 8)») must change (Boy Scout).
- Space: `PaperSheetModal` gives the child a `SizedBox(height: screenWidth)` inside a scroll view (`paper_sheet_modal.dart:24-41`) — 780 logical px on the landscape harness: two more rows do not overflow.

### 4b. D-03 mechanism — `TravelRequoting` (recommended) [VERIFIED: codebase; design ASSUMED-best, see Open Question 3]
Facts that constrain the design:
1. The sheet pops on every `TravelFailed` (`travel_confirmation_sheet.dart:57-60`) and on `Idle`/`Failed` at first frame (:48-54).
2. `TravelOutcomeListener` announces on `TravelFailed` and immediately `reset()`s → `TravelIdle` (`travel_outcome_listener.dart:20-23, 34-38`).
3. The route layer draws only for `Confirming`/`Starting`/`Started`; `Previewing`/`Failed`/`Idle` → no route (`travel_route_layer.dart:69-72`, exhaustive switch). The pawn sits on the destination only for `Previewing`/`Confirming`/`Starting`, with a `_ => null` default (`character_marker_layer.dart:163-168`).
4. `world_map.dart:215-219` refits the camera on every `!Confirming → Confirming` edge.
5. `start()` needs `_characterId`, set only by `preview()` (`travel_cubit.dart:52, 77`).

So «Starting → Previewing → Confirming» (CONTEXT D-08) hides the route during the re-preview, contradicting D-03. Recommended states and transitions:

```dart
// travel_state.dart — new TravelQuote subclass (keeps destination, preview, eta)
/// `startTravel` rifiutato per fame (15-CONTEXT D-03): il foglio resta aperto
/// sull'ultima anteprima mentre il cubit la richiede di nuovo; "Parti" spento.
final class TravelRequoting extends TravelQuote {
  const TravelRequoting({required super.destination, required super.preview,
      required super.eta, required super.previewedAt});
  TravelRequoting.from(TravelStarting starting) : this(destination: starting.destination,
      preview: starting.preview, eta: starting.eta, previewedAt: starting.previewedAt);
  @override
  TravelRequoting withEta({required DateTime eta, required DateTime previewedAt}) => …;
}

// travel_cubit.dart — start()
} on TravelException catch (error) {
  if (error.failure == TravelFailure.starving) return _requote(starting);
  _failStart(destination, error.failure);
}

Future<void> _requote(TravelStarting starting) async {
  final destination = starting.destination;
  final token = ++_previewToken;
  emit(TravelRequoting.from(starting));
  try {
    final result = await _repository.preview(
        characterId: _characterId!, poiId: destination.markerLocation!.id);
    if (_isStale(token)) return;
    emit(_confirmingFrom(destination, result));
  } on TravelException catch (error) {
    _failPreview(token, destination, error.failure);
  } catch (_) {
    _failPreview(token, destination, TravelFailure.unknown);
  }
}

bool _isStale(int token) => token != _previewToken ||
    (state is! TravelPreviewing && state is! TravelRequoting);   // was :113-114
void cancel() { if (state is! TravelPreviewing && state is! TravelConfirming
    && state is! TravelRequoting) return; … }                     // was :93-97
```
Transitions: `Confirming → Starting → Requoting(last quote) → Confirming(new quote)`; a failing re-preview → `TravelFailed(stage: preview)` (sheet closes + its own banner, Phase 7); «Resta»/barrier during `Requoting` → `cancel()` → `Idle` and the late answer is dropped by the token; `reset()` while `Requoting` → Idle (allowed, only `Starting` is protected :101).

UI consumers:
- `TravelOutcomeListener`: add a listener `listenWhen: (p, c) => p is! TravelRequoting && c is TravelRequoting` → `_announce(context, failure: TravelFailure.starving, destination: c.destination)` **without** `reset()` (generalise `_announce` to take failure + destination). The `p is!` guard matters: `_fillPendingEta` re-emits `Requoting.withEta` (`travel_cubit.dart:133-138`) and would re-fire the listener.
- Sheet: no listener change (`Requoting` is neither `Started` nor `Failed`); `PopScope(canPop: state is! TravelStarting)` already lets the user leave; rows render the last quote (it is a `TravelQuote`) with «Parti» disabled; then the new `Confirming` updates them.
- `travel_route_layer.dart:69-72`: add `TravelRequoting(:final preview)` to the route arm (the compiler forces it — exhaustive sealed switch).
- `character_marker_layer.dart:163-168`: add `TravelRequoting(:final destination)` (or use `TravelQuote(:final destination)`); **the `_ => null` default would silently snap the pawn back** — must have a test. This file is on the formatter-dirty list (`15-REPO-RULES.md`): note the reflow in the SUMMARY.
- `world_map.dart:215-219`: narrow to `previous is! TravelQuote && current is TravelConfirming` so the requote does not refit the camera the user may have moved (Open Question 6).
- `quest_result_presenter.dart:81, 162`: waits while not `Idle` — unchanged and correct.

Rejected alternative (re-preview before emitting, staying in `Starting`): no state tells the listener to announce, `Starting` blocks «Resta» and back (:63, :151), and the user would wait up to 2 × 15 s with a frozen sheet.

### 5. Text helpers and «Nx nome» (D-02, D-04, D-06) [VERIFIED: codebase]
- «Nx nome» exists twice inline: `quest_sheet_details.dart:96-99` (`'${entry.quantity ?? 1}x ${entry.item!.name}'`) and `quest_enemy.dart:99` (`'${quantities[id]}x ${names[id]}'`). A third copy for food → Boy Scout: extract a pure `String quantityLine(int quantity, String name) => '${quantity}x $name';` under `lib/models/` (models may not import `lib/utils/`, `architecture.md`) and reuse it in the three sites (existing tests stay green).
- Separator precedents: list «, » (D-02 example); « · » is already a constant (`spellLineSeparator`, `lib/utils/spell_lines.dart:9`; also `quest_result_sheet.dart:222`, `teleport_target.dart:28`). Use « · » between food and life in the quest line (D-04 example).
- HP sign: there is no signed-HP formatter in the app (`hp_delta_bar.dart:63-64` prints `'hp / max'`; `completion_recap.dart:51` prints `'+${xpGained} XP'`). Use `'−$hpLost HP'` (U+2212, as the CONTEXT example «−136 HP») and pin the exact string in tests; write the escape, not the glyph, so an executor cannot type an ASCII hyphen by accident [ASSUMED: U+2212 is intended, it is what the CONTEXT literally contains].
- `lib/models/travel/travel_cost_text.dart` (pure):
  ```dart
  const String starvingPhrase = 'Non hai cibo a sufficienza per il viaggio';
  String foodText(List<TravelFoodItem> food, {required String empty}) =>
      food.isEmpty ? empty : food.map((f) => quantityLine(f.quantity, f.item.name!)).join(', ');
  String lifeText(TravelPreview p) => !p.arrivesAlive ? starvingPhrase
      : p.hpLost <= 0 ? 'nessuna perdita' : '−${p.hpLost} HP';
  ```
  Sheet «Cibo» empty = «nessuno»; quest line empty = «nessun cibo» (both from the CONTEXT examples). The notices import `starvingPhrase` (screens → models is allowed).

### 6. Quest sheet line (D-04) [VERIFIED: codebase]
- Families: `questSheetFamilyOf` (`quest_sheet_details.dart:21-29`): combat = hunt/enemy/boss/dungeon/aid; narrative = story/worldMission; service = everything else (study/heal/job/crime/guard, and `null`). Lanes (`quest_lane.dart:7-11`): only story/worldMission are non-standard. So **every combat and service type is standard-lane (has the automatic travel) and narrative never is** — the line can never be legitimately requested for a narrative sheet.
- Model: `QuestTravelLine { String text; bool isStarving }` with `static QuestTravelLine? of(TravelPreview? p)`: `null` → `null`; `!arrivesAlive` → `'Viaggio: $starvingPhrase'`, starving; else `'Viaggio: ${foodText(p.food, empty: 'nessun cibo')} · ${lifeText(p)}'`.
- `QuestSheetDetails.of(quest, {viewer, TravelPreview? travelPreview})` (:67) → new field `travelLine` = `family == narrative ? null : QuestTravelLine.of(travelPreview)`; add to `props` (:125-137) and the constructor.
- `QuestInfoSheet` (`quest_info_sheet.dart:16-35`) gains `final TravelPreview? travelPreview;` (null = no line; the map overlay `quest_info_overlay.dart:49-53` passes nothing → read-only sheets never show it). `_buildContent` :84 passes it to `QuestSheetDetails.of`.
- Position: insert `..._travelLine(details)` right before `..._titleLine(details)` in `_combatBody`'s right column (:188-190, after `_timeLine()`) and in `_serviceBody` (:260-261). This mirrors the narrative order «cost → title → slots» (:247-249). `_travelLine` = copy of `_costLine` (:307-319) with `key: travelLineKey` and `color: line.isStarving ? bloodRed : null`; plain wrapping `Text` (both columns are `SingleChildScrollView`s, :183-186, :255) — no truncation needed.
- Tests: `test/shared/components/popup/quest_info_sheet_test.dart` (`_pump` helper :54-77 gets a `travelPreview` param), `test/models/quest/quest_sheet_details_test.dart`.

### 7. Board wiring + `QuestTravelPreviewCubit` (D-04, D-05, D-08) [VERIFIED: codebase]
- Board facts: one sheet at a time, built in an `AnimatedBuilder` (`board.dart:241-291`) under `SingleChildScrollView(key: ValueKey('board-sheet-${selected.id}'))` (:260-262) → a provider placed inside that keyed subtree is created once per opened quest and disposed when another quest is opened or the Board is disposed. `TearablePaper(key: _tearKey, canTear: standingOf(selected, viewer).canAccept, isEnabled: isIdle)` (:270-276). The Board is not kept alive (only `MainScreen` uses `AutomaticKeepAliveClientMixin`, `main_screen.dart:58, 283`; pages are lazily built by `PageView`), so leaving the tab closes the cubit.
- Request condition (D-04 «the swipe would be available»): `standingOf(selected, viewer).canAccept && laneOf(type) == QuestLane.standard`. The lane check is required: a story/worldMission sheet can be `canAccept` (`quest_availability.dart:86-97`). Put it in a pure function (e.g. `needsTravelPreview(quest, viewer)` in `board_policy.dart`) with a unit test. Busy lane, already done, title mismatch, full, not in city → `canAccept == false` → no request; the Board is unreachable during a travel (satchel disables it).
- Cubit (`lib/screens/mainScreen/tabs/board/questTravelPreviewCubit/`, `SafeEmit` mixin `lib/shared/bloc/safe_emit.dart`):
  - states: `QuestTravelPreviewIdle` → `QuestTravelPreviewLoading` → `QuestTravelPreviewLoaded(TravelPreview? preview)` | `QuestTravelPreviewFailed(TravelFailure failure)`;
  - `load({characterId, questId})` remembers the ids; `refresh()` reloads them (for the starving refusal, Open Question 2); a request token like `_previewToken` drops a superseded answer; any `TravelException`/`Object` → `Failed` (no banner, D-04).
- Provision: `TravelRepository` is constructed inline inside `BlocProvider<TravelCubit>.create` (`authenticated_shell.dart:233-238`) — not reachable. Add `RepositoryProvider<TravelRepository>(create: (context) => TravelRepository(graphQl: graphQl, permissionGate: context.read<NotificationPermissionGate>()))` **before** `TravelCubit` in the shell providers list (mixed Repository/Bloc providers are already used there, :209-226) and let `TravelCubit` read it (Boy Scout; one instance). Lazy → no new stub in `test/screens/auth/authenticated_shell_test.dart` (it reads `TravelCubit` at :223-230, which then reads the repository; `NotificationPermissionGate` is already provided at :131).
- Board subtree (sketch):
  ```dart
  SingleChildScrollView(key: ValueKey('board-sheet-${selected.id}'), clipBehavior: Clip.none,
    child: BlocProvider<QuestTravelPreviewCubit>(
      create: (context) {
        final cubit = QuestTravelPreviewCubit(context.read<TravelRepository>());
        if (needsTravelPreview(selected, viewer)) {
          cubit.load(characterId: viewer.characterId, questId: selected.id);
        }
        return cubit;
      },
      child: BlocListener<QuestAcceptanceCubit, QuestAcceptanceState>(   // Open Question 2
        listenWhen: (_, c) => c is QuestAcceptanceFailed &&
            c.failure == QuestAcceptanceFailure.starving && c.questId == selected.id,
        listener: (context, _) => context.read<QuestTravelPreviewCubit>().refresh(),
        child: BlocBuilder<QuestTravelPreviewCubit, QuestTravelPreviewState>(
          builder: (context, preview) {
            final travelPreview = preview is QuestTravelPreviewLoaded ? preview.preview : null;
            return BlocSelector<QuestAcceptanceCubit, QuestAcceptanceState, bool>(
              selector: (s) => s is! QuestAccepting,
              builder: (context, isIdle) => TearablePaper(
                key: _tearKey, tearSeed: …,
                canTear: standingOf(selected, viewer).canAccept &&
                    travelPreview?.arrivesAlive != false,          // Open Question 1
                isEnabled: isIdle, onTorn: …,
                child: ColoredBox(color: Colors.transparent,
                  child: QuestInfoSheet(quest: selected, viewer: viewer,
                      travelPreview: travelPreview))));
          }))))
  ```
- D-05 recompose: already done for every `QuestAcceptanceFailed` (`board.dart:195-201`); banner + reset by `QuestAcceptanceOutcomeListener` (`main_screen.dart:128`). Both listeners receive `Failed` before the `Idle` emitted by `reset()` (bloc state stream is asynchronous broadcast; the existing recompose already relies on it — precedent, not re-verified in bloc sources) [ASSUMED: ordering identical for a third listener].
- Test harness impact (Wave 0): `test/screens/mainScreen/tabs/board/board_test.dart` (providers :120-125) and `board_acceptance_test.dart` (pumpBoard :134-149) must add `RepositoryProvider<TravelRepository>.value(value: mockTravelRepository)` with a default stub `previewQuest(...) → async => null`, otherwise every test that opens an acceptable standard sheet throws `ProviderNotFoundException`. `main_screen_test.dart` taps the board item only with `pagesBuilder` fake pages (:414-420) → unaffected.

### Anti-Patterns to Avoid
- Emitting `TravelFailed` for starvation and special-casing it in two listeners: the sheet's pop and the outcome listener's reset race; the route already vanished.
- `TravelPreviewing` as the re-preview state: route disappears (`travel_route_layer.dart:72`).
- Computing «would not arrive alive» from `hpLost` and `currentLifePoints` on the client (FOOD-04, CLAUDE.md rule 4): only `arrivesAlive`.
- Passing a cubit into `QuestInfoSheet` (shared component used read-only by the map): pass data (`TravelPreview?`).
- Selecting `food { item { … } }` beyond `id name` (populate depth 1, `15-REPO-RULES.md`).
- A spinner or skeleton for the quest line (rule 2, D-04).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stale/late preview answers | ad-hoc booleans | the existing `_previewToken` + `_isStale` (`travel_cubit.dart:42, 113-114`) and `SafeEmit` | already proven by `travel_cubit_test.dart` cancel group :239-330 |
| Starvation banner | a new banner widget | `InAppNotificationsCubit.publishNotice` via the two outcome listeners | dedup keys and queue exist |
| Swipe rollback | new animation | `TearablePaperState.recompose()` (`tearable_paper.dart:74-83`) | Phase 6 D-03 |
| Swipe gating | wrapper `IgnorePointer` | `TearablePaper(canTear:)` / `isEnabled:` (:30-34) | haptics and resist animation built in |
| Error classification | parse server message | `graphQlErrorCode` → `extensions.code` (`graphql_error_code.dart`) | FE reads only codes |
| Schema proof | hand diff of SDL | `dump_documents.dart` + `validate_documents.js` with BE graphql-js 16.11.0 | 14-10 procedure |

## Runtime State Inventory
Not a rename/refactor phase — omitted (the device UAT seeds food at the DB; see §UAT).

## Common Pitfalls

### Pitfall 1: The starvation refusal closes the sheet / resets the flow
**What goes wrong:** treating `TRAVEL_STARVING` as `TravelFailed` pops the sheet (`travel_confirmation_sheet.dart:57-60`) and resets to Idle (`travel_outcome_listener.dart:37`).
**How to avoid:** `TravelRequoting` (§4b). **Warning sign:** a widget test with `Starting → Requoting` finds no `TravelConfirmationSheet`.

### Pitfall 2: Route or pawn flicker during the re-preview
`travel_route_layer.dart:72` (Previewing → no route) and `character_marker_layer.dart:163-168` (`_ => null`). Add `TravelRequoting` to both and test both (`test/screens/mainScreen/tabs/map/travel_route_layer_test.dart`, `character_marker_layer_test.dart`).

### Pitfall 3: Double banner on clock sync
`_fillPendingEta` re-emits any `TravelQuote` without ETA (`travel_cubit.dart:133-138`); a `listenWhen: c is TravelRequoting` fires twice. Use the `previous is! TravelRequoting` edge.

### Pitfall 4: bloc_test seeds without `_characterId`
`start()` dereferences `_characterId!` (`travel_cubit.dart:77`), set only in `preview()` (:52). Starvation tests must `act` through `preview()` then `start()` (as the existing start tests do), not `seed: () => confirming`.

### Pitfall 5: Placeholder count and pinned selection in existing tests
`travel_confirmation_sheet_test.dart` «shows the destination at once…» expects `findsNWidgets(3)` placeholders (:139) → 5; `travel_documents_test.dart:38-46` pins the exact `GetTravelPreview` selection; registry count `schema_check_documents_test.dart:32-33`. Update each RED first in its plan.

### Pitfall 6: Story/worldMission request the quest preview
`canAccept` is true for an eligible story (`quest_availability.dart:86-97`): gate on the standard lane too, and have `QuestSheetDetails` drop the line for the narrative family (defence in depth).

### Pitfall 7: Board tests break on `context.read<TravelRepository>()`
Wave 0 harness change in `board_test.dart` and `board_acceptance_test.dart` (§7).

### Pitfall 8: `LootItem.fromJson` throws on unknown enum names
`byName` at `loot_item.dart:35-40`: never let one entry fail the whole preview — per-entry `try/catch` in `TravelFoodItem.listFrom`, and select only `id name`.

### Pitfall 9: `QUEST_IN_PROGRESS` is not an acceptance code
The deferred item assumes `acceptQuest` can return it. BE `origin/develop`: `QUEST_IN_PROGRESS` is raised only in `src/travel/travel.updates.ts` and the pending-request/GM completion paths (grep of `src`), and the BE handoff lists it for `startTravel`/`travelPreview`/`teleportCharacter`/`completePendingRequest` only (BE `08-…/BACKEND-NOTES.md:186`, `07-…/BACKEND-NOTES.md:99`); `quest-acceptance.service.ts` raises `questNotAcceptable`/`questNotInCity`/… via `GameRuleException` (lines 297-338) [VERIFIED]. No Boy Scout needed; drop the deferred item.

### Pitfall 10: Rules doc drift
`docs/rules/ui-ux.md` §Gesture still says the travel confirmation shows «nessun costo»; the sheet doc comment `travel_confirmation_sheet.dart:18` says «Nessun costo (BE Phase 8)». Update both (docs commit, scope `phase-15` or within the sheet plan).

### Pitfall 11: `dart format` tall style vs. greps
Signatures over 80 columns wrap (`15-REPO-RULES.md`): acceptance greps anchored to one identifier (`TravelRequoting`, `previewQuestTravel`, `travelStarvingCode`), `grep -A3` fallback. Skeletons in a plan must not contain literals a gate grep wants absent.

### Pitfall 12: Camera refit after a requote
`world_map.dart:215-219` fires on `Requoting → Confirming`. Harmless (same route) but moves a camera the user may have panned; narrow `listenWhen` (Open Question 6).

## Code Examples

### Tolerant food list (pattern: `QuestResult.assetQuantitiesFrom`, `quest_result.dart:139-146`)
```dart
static List<TravelFoodItem> listFrom(Object? json) {
  if (json is! List) return const [];
  return List.unmodifiable(json.map(_tryFrom).whereType<TravelFoodItem>());
}

static TravelFoodItem? _tryFrom(Object? json) {
  if (json is! Map<String, dynamic>) return null;
  final item = json['item'];
  final quantity = json['quantity'];
  if (item is! Map<String, dynamic> || quantity is! num || quantity < 1) return null;
  final name = item['name'];
  if (item['id'] is! String || name is! String || name.isEmpty) return null;
  try {
    return TravelFoodItem(item: LootItem.fromJson(item), quantity: quantity.toInt());
  } on Object {
    return null;
  }
}
```

### Service with nullable result (pattern: `previewTravel`, `graphql.dart:640-648`)
```dart
Future<TravelPreview?> previewQuestTravel(AcceptQuestRequest request) async {
  final data = _dataOrThrow(await performQuery(
    TravelQueries.getQuestTravelPreview,
    variables: {'request': request.toJson()},
  ));
  if (!data.containsKey('questTravelPreview')) {
    throw const FormatException('questTravelPreview missing');
  }
  final json = data['questTravelPreview'];
  return json == null ? null : _travelPreviewFrom(json);
}
```
Service tests follow `test/repository/services/graphql/graphql_travel_test.dart:13-38` (`Link.function` handler, `dataResponse`, `errorCodeResponse`): operation name, variables `{'request': {'id','questId'}}`, `null` → `null`, malformed → `FormatException`, coded error rethrown, never cached.

### bloc_test for the starvation flow
```dart
blocTest<TravelCubit, TravelState>(
  'a starving refusal keeps the quote and previews again (D-03)',
  setUp: () {
    var calls = 0;
    stubPreview().thenAnswer((_) async => calls++ == 0 ? preview : starvingPreview);
    stubStart().thenThrow(const TravelException(TravelFailure.starving));
  },
  build: build,
  act: (cubit) async { await previewValdoria(cubit); await cubit.start(); },
  expect: () => [TravelPreviewing(valdoria), confirming, starting,
      TravelRequoting.from(starting), confirmingWith(starvingPreview)],
);
```
Plus: other refusals still → `TravelFailed(stage: start)`; re-preview failure → `TravelFailed(stage: preview)`; `cancel()` during `Requoting` → Idle and the late answer is dropped; `withEta` on `Requoting` stays `Requoting`; close during requote emits nothing.

## State of the Art

| Old (Phase 7) | Phase 15 | Impact |
|---------------|----------|--------|
| Sheet: «Nessun costo», 3 rows | 5 rows, «Parti» gated by `arrivesAlive` | `ui-ux.md` rule amended |
| Every start refusal closes the sheet | Starvation → `TravelRequoting`, sheet stays | new state handled by 2 layers + listener |
| Combat/service sheets: no cost block | «Viaggio:» line from `questTravelPreview` | new per-sheet cubit + shell `RepositoryProvider<TravelRepository>` |

## Conflicts with the CONTEXT (recommended amendments)
- **C1 — D-08 «Starting → Previewing → Confirming»:** `TravelPreviewing` hides the route (`travel_route_layer.dart:72`), against D-03 «the route preview stays». Use `Starting → TravelRequoting → Confirming` (§4b).
- **C2 — D-04 `TearablePaper(isEnabled: false)`:** `isEnabled` means «mutation in flight, ignore every drag» (`tearable_paper.dart:33-34`); `canTear: false` means «quest not acceptable: the sheet resists and returns whole» with a haptic (:30-31, :99-105), the Phase 6 D-11 behaviour of every other blocked quest. Both satisfy «swipe disabled». Recommend `canTear: false` (Open Question 1).
- **C3 — D-08 «provided by the Board»:** needs a shell `RepositoryProvider<TravelRepository>` (today inline in `TravelCubit`'s create, `authenticated_shell.dart:233-238`).
- **C4 — Deferred `QUEST_IN_PROGRESS`:** not an `acceptQuest` code (Pitfall 9); drop.
- **C5 — ROADMAP §Phase 15 criterion 2 «next to the channel-points line»:** combat/service bodies have no channel-points line (`_costLine` only in `_narrativeBody`, `quest_info_sheet.dart:247`); D-04 already places the line in the costs position — amend the criterion wording at the gate plan.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | «−136 HP» uses U+2212 (the CONTEXT literal), not ASCII «-» | §5 | cosmetic; tests pin the chosen glyph |
| A2 | A third `BlocListener<QuestAcceptanceCubit>` receives `Failed` before the outcome listener's `reset()` Idle (as the Board's recompose listener does today) | §7 | the refresh after a starving accept would not fire; covered by a Board widget test |
| A3 | BE `food[]` order is the order to display (no FE sort) | §1 | cosmetic |
| A4 | `questTravelPreview` returns `null` (not an error) for a standard quest whose marker is the character's position | §2 | line absent either way (D-04) |
| A5 | `food[].item.name` is always populated by the BE (`LootItem.name` is nullable on the SDL, `schema.gql` `type LootItem` `name: String`) | §1 | a nameless entry is dropped → the «Cibo» row under-reports; note in `BACKEND-NOTES.md` |

## Open Questions (RESOLVED — all recommendations adopted in the CONTEXT on 2026-11-05: D-03/D-04/D-05/D-08 revised, D-10..D-13 added)

1. **Swipe gating: `canTear: false` or `isEnabled: false`?** — What we know: both disable acceptance; `canTear` gives the Phase 6 resist + haptic, `isEnabled` makes the paper inert. Recommendation: `canTear: false` (consistent with every other non-acceptable quest); if the orchestrator wants the CONTEXT literal, `isEnabled: !starving && isIdle` works identically for the tests that check «no accept call».
2. **Refresh the quest preview after an `acceptQuest` starving refusal?** — D-05 only says recompose + banner. Without a refresh the recomposed sheet keeps a non-red line and an enabled swipe, inviting the same refusal. Recommendation: yes, `QuestTravelPreviewCubit.refresh()` from a listener inside the sheet subtree (§7) — it mirrors D-03 and is not a «board reread».
3. **During the requote, old numbers or placeholders?** — Recommendation: keep the last quote (it is a `TravelQuote`) with «Parti» disabled, then swap to the new quote; placeholders would flash and the route must stay anyway.
4. **Red «Vita» row: phrase only, or phrase + number?** — Recommendation: phrase only (a refused far trip reads e.g. «−20910 HP», meaningless when refused); the «Cibo» row still lists what would be eaten.
5. **Long food lists** — Recommendation: «Cibo» `maxLines: 3` wrapping in the sheet; the quest line wraps freely (scrollable columns); no truncation logic.
6. **Camera refit on `Requoting → Confirming`** — Recommendation: narrow `world_map.dart:216-217` to `previous is! TravelQuote && current is TravelConfirming`, with a test.
7. **Cubit-side guard on `start()` when `!arrivesAlive`?** — Recommendation: no (UI gate + BE refusal suffice; a cubit rule duplicates the BE). Keep the gate in `_actions` only, widget-tested.
8. **`TravelCubit` reading the new `RepositoryProvider`** — Recommendation: yes (Boy Scout, one instance); `authenticated_shell_test.dart:223-230` keeps passing since `NotificationPermissionGate` is provided (:131).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | all plans | ✓ | 3.35.5 stable | — |
| node | gated schema check | ✓ | v26.12.1 | — |
| BE graphql-js | `validate_documents.js` | ✓ | 16.11.0 (BE `node_modules`) | — |
| BE `origin/develop` with Phase 14 | gated plans | ✗ | `698ae82` (no `TravelFoodItem`) | park gated plans (D-09) |
| BE Phase 14 `BACKEND-NOTES.md` | gated plans, UAT data | ✗ (not written yet) | — | read after the BE merge |
| Android device + local BE | device E2E | human checkpoint | — | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (Flutter 3.35.5) + bloc_test ^10.0.0 + mocktail ^1.0.5 + fake_async ^1.3.3 |
| Config file | none (`test/helpers/test_app.dart`, `landscape.dart` (780×360 @3.0), `svg_cache_seed.dart`, `mocks.dart`, `fakes/fake_server_clock_service.dart`, `fakes/svg_http_overrides.dart` → `useSvgHttpOverrides()`) |
| Quick run command | `flutter test <touched paths>` — the phase subset (travel models, travel cubit, sheet, outcome listener, travel failure/repository/service, registry, quest info sheet, board) = **251 tests in ~10 s** (measured this session, all green) |
| Full suite command | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (3180 tests at 14-10, ~75 s; 314 test files today) |
| Analyzer baseline | `flutter analyze` → 50 issues, 0 error / 0 warning (measured this session on `feat/15-travel-food` = `develop` + docs) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FOOD-01 | `TravelPreview` reads food/hpLost/arrivesAlive; defaults on missing; malformed entry dropped; round trip; equality | unit | `flutter test test/models/travel` | `travel_preview_test.dart` ✅ extend; `travel_food_item_test.dart` ❌ W0 |
| FOOD-01/02 | `foodText`/`lifeText`/`starvingPhrase`/`quantityLine` | unit | `flutter test test/models/travel test/models/quest` | `travel_cost_text_test.dart` ❌ W0 |
| FOOD-01 | `GetTravelPreview` selects the three fields; registry 45 | unit | `flutter test test/graphql/travel_documents_test.dart test/tool` | ✅ extend |
| FOOD-01 | sheet: 5 placeholders; Cibo «Nx nome» list / «nessuno»; Vita «−N HP» / «nessuna perdita»; red phrase + «Parti» disabled; «Resta» enabled | widget | `flutter test test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart` | ✅ extend |
| FOOD-02 | `GetQuestTravelPreview` document; `previewQuestTravel` (null, map, malformed, coded error, noCache) | unit | `flutter test test/graphql test/repository/services/graphql/graphql_travel_test.dart` | ✅ extend |
| FOOD-02 | `TravelRepository.previewQuest` guard (timeout, OperationException, null passthrough) | unit | `flutter test test/repository/travel_repository_test.dart` | ✅ extend |
| FOOD-02 | `QuestTravelLine.of`; `QuestSheetDetails.travelLine` null for narrative | unit | `flutter test test/models/quest` | `quest_travel_line_test.dart` ❌ W0; `quest_sheet_details_test.dart` ✅ |
| FOOD-02 | line in combat/service only, red on starving, absent without preview; overlay never shows it | widget | `flutter test test/shared/components/popup/quest_info_sheet_test.dart test/screens/mainScreen/tabs/map/quest_info_overlay_test.dart` | ✅ extend |
| FOOD-02 | `needsTravelPreview` (standard lane + canAccept) | unit | `flutter test test/models/quest` | `test/models/quest/board_policy_test.dart` ✅ extend |
| FOOD-02 | cubit: idle→loading→loaded(preview/null) / failed; refresh; stale answer dropped; close-safe | bloc_test | `flutter test test/screens/mainScreen/tabs/board/questTravelPreviewCubit` | ❌ W0 |
| FOOD-02/03 | Board: request only for an acceptable standard sheet; line appears; starving → swipe blocked; failure → swipe as today; starving accept refusal → recompose (+ refresh) | widget | `flutter test test/screens/mainScreen/tabs/board` | ✅ extend (harness W0) |
| FOOD-03 | classifiers map `TRAVEL_STARVING` | unit | `flutter test test/repository/travel_failure_test.dart test/repository/quest_acceptance_failure_test.dart` | ✅ extend |
| FOOD-03 | notices: phrase under both titles | unit | `flutter test test/screens/mainScreen/travelCubit/travel_notice_test.dart test/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice_test.dart` | ✅ extend |
| FOOD-03 | `TravelCubit` starving → Requoting → Confirming; other refusals unchanged; cancel/close during requote | bloc_test | `flutter test test/screens/mainScreen/travelCubit/travel_cubit_test.dart` | ✅ extend |
| FOOD-03 | listener announces once on entering Requoting, no reset; sheet stays open on Requoting and closes on other `Failed` | widget | `flutter test test/screens/mainScreen/components/travel_outcome_listener_test.dart test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart` | ✅ extend |
| FOOD-03 | route + pawn kept during Requoting; camera not refit | widget | `flutter test test/screens/mainScreen/tabs/map/travel_route_layer_test.dart test/screens/mainScreen/tabs/map/character_marker_layer_test.dart test/screens/mainScreen/tabs/map/world_map_travel_test.dart` | ✅ extend |
| FOOD-04 | `characterUpdated` keeps selecting `ownedItems` + `currentLifePoints` | unit | `flutter test test/graphql` | ❌ W0 (optional: no test in `test/graphql` pins `currentLifePoints`/`ownedItems` today) |
| all | documents valid against merged BE schema | gate | dump + `validate_documents.js` (45) | gated plan |

### Sampling Rate
- **Per task commit:** targeted `flutter test <paths>` (< 15 s).
- **Per plan:** touched dirs + `flutter analyze` (0 error / 0 warning).
- **Phase gate (gated plan):** full `flutter test` (foreground), analyzer, `dart format --set-exit-if-changed` on the new files only, trailer grep = 0, schema check 45 × OK.

### Wave 0 Gaps
- [ ] `test/models/travel/travel_food_item_test.dart`, `test/models/travel/travel_cost_text_test.dart`, `test/models/quest/quest_travel_line_test.dart`
- [ ] `test/screens/mainScreen/tabs/board/questTravelPreviewCubit/quest_travel_preview_cubit_test.dart`
- [ ] `test/helpers/fixtures/travel_fixtures.dart`: `travelPreviewJson({…, List<Map>? food, int? hpLost, bool? arrivesAlive})` emitting the keys only when given (old-BE shape stays the default for existing tests) + `travelFoodItemJson({id, name, quantity})`
- [ ] `test/helpers/mocks.dart`: `MockQuestTravelPreviewCubit` (only if a widget test isolates the sheet from the cubit); `MockTravelRepository` exists (:98)
- [ ] Board harness: `RepositoryProvider<TravelRepository>.value` + default `previewQuest → null` in `board_test.dart` and `board_acceptance_test.dart`

### Manual-only (device, `15-HUMAN-UAT.md`, table «Step | Requirements | Decisions | Expected | Result | Note» as `14-HUMAN-UAT.md`)
Data (orchestrator, scripts outside the repo, never printed): food in `assets.ownedItems` as `{itemType: 'LootItem', item: <ObjectId of a hunger LootItem>, quantity}` (BE `asset-quantity.model.ts`); `status.currentLifePoints` lowered for the refusal cases (rookie 1000 HP ≤ 44 uncovered km; 16 km uncovered = 136 HP, BE D-02); a finished travel shortened with coherent `startTime`/`endTime` (07-HUMAN-UAT note: shifting only `endTime` is invalid). Numbers: nearest city ≈ 55 power / 16 km; any city median ≈ 700 / 204 km (BE CONTEXT specifics).
1. Fully covered trip: enough food → «Cibo: 1x Razione da viaggio», «Vita: nessuna perdita» → «Parti» → Journal «Oggetti» decreased, «Punti vita» unchanged (FOOD-01, FOOD-04; D-02, D-07).
2. Partially covered: little food → «Vita: −N HP» → «Parti» → food gone and HP reduced in the Journal, no banner (FOOD-01, FOOD-04).
3. Refused at preview: no food, far city → red «Non hai cibo a sufficienza per il viaggio», «Parti» disabled, «Resta» closes (FOOD-01; D-02).
4. `TRAVEL_STARVING` at departure: open the sheet with food, remove the food (or lower HP) at DB, tap «Parti» → banner «Viaggio non partito / Non hai cibo…», sheet stays open, rows refresh red, route stays (FOOD-03; D-03).
5. Quest line: a combat and a service quest away from the marker → «Viaggio: …»; a story sheet and the map overlay show none (FOOD-02; D-04).
6. Quest starving: preview red + swipe blocked; then with food at open, remove it at DB and swipe → banner «Missione non accettata / Non hai cibo…», sheet recomposed (FOOD-02, FOOD-03; D-04, D-05).
7. Innkeeper teleport consumes nothing (Journal unchanged) (ROADMAP criterion 4; BE D-13).

### Schema gate procedure (pattern `14-10-PLAN.md:68-81`)
```
SCRATCH=$(mktemp -d); git -C $BE show origin/develop:src/schema.gql > "$SCRATCH/schema.gql"
grep -c "TravelFoodItem" "$SCRATCH/schema.gql"                       # ≥ 1, else STOP (parked)
awk '/^type TravelFoodItem /,/^}/' "$SCRATCH/schema.gql"             # item: LootItem!  quantity: Int!
awk '/^type TravelPreview /,/^}/' "$SCRATCH/schema.gql"              # + arrivesAlive: Boolean!, food: [TravelFoodItem!]!, hpLost: Int!
grep -n "questTravelPreview" "$SCRATCH/schema.gql"                   # (request: AcceptQuestRequest!): TravelPreview   (no «!»)
dart run tool/schema_check/dump_documents.dart "$SCRATCH/docs"       # «dumped 45 documents»
NODE_PATH=$BE/node_modules node tool/schema_check/validate_documents.js "$SCRATCH/schema.gql" "$SCRATCH/docs" | grep -vc OK   # 0
```
`TRAVEL_STARVING` is not in the SDL: verify it in the BE `BACKEND-NOTES.md` codes table (`git -C $BE show origin/develop:.planning/phases/14-viaggio-e-cibo/BACKEND-NOTES.md`).

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (unchanged session) | — |
| V3 Session Management | no | — |
| V4 Access Control | yes (BE-side) | `questTravelPreview` owner-only (`FORBIDDEN`); FE sends only the current `characterId` (`QuestViewer.characterId`) |
| V5 Input Validation | yes | tolerant per-entry parsing of `food`; strict core fields → `FormatException` → `TravelException.unknown` |
| V6 Cryptography | no | — |

| Threat | STRIDE | Mitigation |
|--------|--------|------------|
| Client gate bypass (disabled «Parti»/swipe forced) | Tampering | BE refuses with `TRAVEL_STARVING` before any write (BE D-11); FE maps it to the banner |
| Malformed preview crashing the sheet | DoS | per-entry drop, defaults, `_travelPreviewFrom` FormatException boundary |
| Server message shown to the user | Info disclosure | FE reads only `extensions.code`; copy from the FE catalogue |
| UAT docs leaking ids/URIs | Info disclosure | grep `mongodb(\+srv)?://|token=|password` = 0 on `15-HUMAN-UAT.md` and `BACKEND-NOTES.md` (14-11 pattern) |

## Sources

### Primary (HIGH confidence)
- Codebase (read this session): `travel_confirmation_sheet.dart`, `travel_cubit.dart`, `travel_state.dart`, `travel_outcome_listener.dart`, `travel_notice.dart`, `travel_failure.dart`, `travel_repository.dart`, `travel_preview.dart`, `travel_queries.dart`, `graphql.dart` (:60-130, :596-700, :762-793), `quest_info_sheet.dart`, `quest_sheet_details.dart`, `quest_cost_line.dart`, `quest_availability.dart`, `quest_lane.dart`, `board.dart`, `tearable_paper.dart`, `quest_acceptance_*`, `authenticated_shell.dart:140-280`, `main_screen.dart`, `travel_route_layer.dart`, `character_marker_layer.dart:150-175`, `world_map.dart:205-560`, `quest_result_presenter.dart`, `in_app_notifications_cubit.dart:60-80`, `loot_item.dart`, `asset_quantity.dart`, `paper_sheet_modal.dart`, `schema_check_documents.dart`, registry/document/service tests
- BE `origin/develop` `698ae82`: `src/schema.gql` (`TravelPreview`, `LootItem`), `src/models/common/asset-quantity.model.ts`, `src/quests/acceptance/quest-acceptance.service.ts`; BE `.planning/phases/14-viaggio-e-cibo/14-CONTEXT.md`, `14-REPO-RULES.md`; `08-…/BACKEND-NOTES.md` §2; `07-…/BACKEND-NOTES.md`
- `.planning/phases/15-travel-food/15-CONTEXT.md`, `15-REPO-RULES.md`; `14-10-PLAN.md`, `14-10-SUMMARY.md`, `14-11-PLAN.md`, `14-HUMAN-UAT.md`, `07-HUMAN-UAT.md`
- Tooling runs: `flutter --version`, `flutter analyze` (50 info, 0 error/warning), targeted `flutter test` (251 green, ~10 s)

### Secondary / Tertiary
- None (no web sources needed; every library already locked and used the same way in previous phases).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependency, versions from `pubspec.yaml`/`flutter --version`.
- Architecture: HIGH for the code facts and the collision analysis; MEDIUM for the `TravelRequoting` choice (a design recommendation, see Open Question 3) and the BE names (fixed in REPO-RULES, unmerged).
- Pitfalls: HIGH — each tied to a line read this session.

**Research date:** 2026-11-05
**Valid until:** the BE Phase 14 merge (re-check the SDL and the BE handoff before the gated plans); otherwise 30 days.

## RESEARCH COMPLETE
