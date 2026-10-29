# Phase 9: Combat Result Sheet - Research

**Researched:** 2026-10-27
**Domain:** Flutter (3.35.5 via fvm) — shell-level delivery queue, root-Navigator modal, session routing hold, GraphQL subscription/query/mutation against BE Phase 9 (+ 9.2 proposal), wounded state on the Map
**Confidence:** HIGH (every code fact below was read in this session; routing/modal behaviour proven with a throwaway `flutter test` probe, since deleted; the documents were validated with `tool/schema_check/validate_documents.js` against BE `origin/develop` @ `10e5f43`)

## Summary

Everything Phase 9 needs from BE Phase 9 is on BE `origin/develop` (`10e5f43`): `QuestResult`, `questResult(id)`, `questResultReceived(characterId)`, `status.awaitingAid`. The FE fragment validates against that schema **today**, except `acknowledgedAt`, `unacknowledgedQuestResults` and `acknowledgeQuestResult` (BE 9.2, not merged; the BE branch `feat/09.2-quest-result-delivery-contract` only has its CONTEXT). The schema-check registry test forces every named operation in `lib/graphql/` into the registry, so the two 9.2 documents can only be added in the schema-gated plan; earlier plans build against two ports with null-object implementations (C4).

The structural work is in three places that already exist and must change: (1) `AuthGate` pops every root route as soon as `currentCharacter` changes (`auth_gate.dart:33-38`), which would close the death sheet — the pop must move to `SessionHome`, which also gains the routing hold (C3, F2); (2) "Map visible and free" is not represented anywhere today — the current page is `MainScreen` local state, the quest overlay is `_WorldMapState` local state, the drag is `_CharacterMarkerLayerState._dragPoint`; a new shell-level `MapAvailabilityCubit` fed by those widgets plus `ModalRoute.isCurrentOf(context)` (proven to flip on every root sheet/dialog) gives one signal (F1); (3) the shop has **no** failure classifier at all (`doTransaction` throws a plain `Exception(message)`, losing the code), so `SHOP_NOT_IN_CITY` needs a new small classifier (C8).

Several CONTEXT assumptions are already satisfied or wrong in the code: the 28 Italian injury labels **already exist** (`InjuryTypeExtension.label`, `injury_type.dart:46-107`, untested) (C1); there is **no** Italian label table for `QuestType` (Phase 6 only has state labels) (C2); the BE example fragment's `... on EquipmentItem { id name rarity }` would parse every equipment reward as loot because `AssetItem.fromJson` discriminates on `equipType` (C5); the foreground FCM push would still show a banner when the sheet opens at once on the Map (C6).

**Primary recommendation:** one `QuestResultsCubit` (shell, `lazy: false`) owning subscription + refetch triggers + FIFO queue + ack, one `MapAvailabilityCubit` (shell) for the Map-free signal, one session-level `CharacterExitHoldCubit` (in `SessionSyncScope`) read by a stateful `SessionHome`; a `QuestResultPresenter` widget mounted in `MainScreen` next to `SpellOutcomeListener` presents the parchment with `showGeneralDialog(useRootNavigator: true, barrierDismissible: false)` + `PopScope(canPop: false)` and returns `true` only from the button (external pop → `null` → requeue).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Sheet anatomy (COMBAT-01..06)
- **D-01 (user decision):** a **full-screen parchment overlay on the root Navigator**, built with the `PaperSheetModal` / `QuestInfoSheet` language (existing Cloudinary parchment SVGs, dimmed scrim, no AppBar) — not a dedicated route, not a Map layer. The shell stays alive underneath: subscriptions, banners and the queue cubit keep running while the sheet is open.
- **D-02 (user decision):** HP delta = **life bar plus counting numbers**: the bar animates from `hpBefore` to `hpAfter` against `maxLifePoints` (the maximum **after** the outcome, BE §3: the bar grows on a level up) with the numbers scrolling in step; `TweenAnimationBuilder` (ui-ux.md), red ink for a loss, green for a gain (`heal` restores the maximum). The dismissal button is enabled from the start: the animation never blocks the player (whether a tap skips it is Claude's call).
- **D-03 (user decision):** content, in this provisional order: header with `quest.title`, the Italian label of `quest.type` (Phase 6 labels) and `resolvedAt`; enemy image and name (`enemy { id name imagePath }`, section hidden when `null`; never select `enemy.locations`, BE §14); the HP block; `injuriesAdded` rendered with **Italian labels for the 28 `InjuryType` values** (new label table, COMBAT-04); `consumablesUsed` and `spellsUsed { usages spell { id name } }` (an entry with `spell: null` reads «Magia sconosciuta»); `rewards.coins` (`CoinsDisplay`) and `rewards.items` (`ItemRow`, `ItemUnion` inline fragments as the inventory); `xpBefore`, `xpGained`, `xpAfter`; «Livello 3 → 4» and «Avventuriero → Paladino» only when they change; `spellLearned { id name }`; «Hai salvato N avventurieri» from `rescuedCharacters.length` (user: **the number only**, no names).
- **D-04 (user decision):** **one widget for the five outcomes**: the header and the ink colour change per `outcome` («Vittoria», «Sconfitta», «Sei stato salvato», «È morto», «Missione completata» for `gmCompleted`; copy provisional); a section with no data is not built (no rewards on `failure`, before = after on `rescued` and `death`).
- **D-05 (user decision):** dismissal = **one explicit button at the bottom of the parchment** («Continua»; «Riposa in pace» on death). Tap on the scrim, Android back (`PopScope`) and any swipe are ignored (COMBAT-06).

#### Delivery, queue and never-lost results (COMBAT-01, COMBAT-07, COMBAT-09)
- **D-06 (user, verbatim 2026-10-27):** *«Il foglio risultati si vede solo una volta entrati nel tab mappa, per sicurezza. Cliccare sul banner che ti avvisa della fine della missione ti porta sul tab mappa a e apre la sheet del risultato».* The sheet is presented only while the Map tab is the visible page. From any other tab the player gets the in-app banner; its tap lands on the Map through the Phase 5 router and opens the sheet through the `questEnd` entry of `defaultNotificationPopups`.
- **D-07 (user decision):** if the player is **already on the Map** when a result arrives, the sheet opens at once, **without a banner**, provided the Map is free: no route above the shell (parchment sheets, dialogs, travel confirmation, abandon sheet, quest/item/spell sheets), no quest paper overlay open, no pawn drag in progress. Otherwise the queue retries at every change (route popped, overlay closed, drag ended, page changed). Results pending in the queue open by themselves when the player enters the Map.
- **D-08 (user decision):** several results (group boss, rescue chain, reconciler at boot) → **FIFO by `resolvedAt`, one sheet at a time**: the button closes the current sheet and the next one opens; a «1 di 3» counter at Claude's discretion.
- **D-09:** three sources feed **one queue keyed by result id** (dedup): (a) the subscription `questResultReceived(characterId)`, opened with the shell for the whole session like `characterUpdated` (silent resubscribe of Phase 3; `FORBIDDEN`/`NOT_FOUND` are terminal → stop silently, the query covers the rest); (b) the `questEnd` push tap → `questResult(id)` (BE §4: `data.id` is the **result id**; the Phase 5 handoff note that said pendingQuestId is superseded); (c) **BE Phase 9.2** `unacknowledgedQuestResults`, read at cold start (shell bootstrap), on resume (`AppLifecycleBridge`) and after a WS reconnection — results of the **user**, so a `death` result survives the archive of its character. Lost pushes, force-stop and disabled notifications never lose a sheet.
- **D-10 (user decision):** **acknowledgement at close**: pressing the button calls `acknowledgeQuestResult(id)` (BE 9.2), best-effort (retried on the next resume; a failure never blocks the UI). Ids shown or acknowledged are kept in memory for the session as a local dedup; a sheet opened but never closed (app killed) comes back at the next start.
- **D-11 (user decision):** a `questEnd` tap for a result already acknowledged → **Map tab only, no sheet**; an id unknown locally → `questResult(id)`; `NOT_FOUND`/`FORBIDDEN` → domain banner («Risultato non disponibile», provisional), network error → silent, covered by the resume refetch. Nothing is ever rebuilt from the push payload (rule 4).
- **D-12 (user decision):** the FE **publishes the in-app banner itself from the subscription event** with the dedup key `questEnd|<resultId>` and the **generic BE copy** («Missione conclusa» / «La tua missione è terminata: scopri com'è andata.», the same strings as the push, kept in one place); the foreground push with the same type and id is deduplicated by the existing `InAppNotificationsCubit` rule. The «fine quest» toggle silences the system notification and the banner (Phase 4/5 rule) but **never the sheet**, which still opens on the Map.

#### Death, rescue and the wounded state (COMBAT-08)
- **D-13 (user decision):** **death is the exception to D-06**: the `death` sheet opens on any tab as soon as the root Navigator is free. The routing to the character-creation page on `currentCharacter: null` (Phase 3 D-09, `SessionHome`) is **held** until the death sheet is closed with the button; if `currentCharacter: null` arrives before the result (the BE does not guarantee the order, §3), the shell waits for the sheet up to a cap (technical default 10 s, Claude's discretion) and then routes anyway — the result comes back from the unacknowledged query or the push. The hold keeps the keyed shell alive so the subscription can still deliver the result.
- **D-14 (user decision):** the death sheet is the **same widget with dark ink**: header «È morto», name, title and level of the dead character, the aid as quest, injuries, no rewards; button «Riposa in pace» → creation page.
- **D-15 (user decision):** `rescued` → same widget, header «Sei stato salvato», quest = the aid, no rewards, before = after; after the button the pawn is already in the city (from `characterUpdated`).
- **D-16 (user decision):** wounded state (`status.awaitingAid != null`, after a `failure`): the label «In attesa di soccorso» floats over the pawn in the place of the travel remaining-time label; pawn drag, Board and Shop are disabled with the darker satchel cell exactly like the travel rule (Phase 7 D-12, `disabledSatchelPages`); journal, lore and sheets stay readable; `AWAITING_AID` and `SHOP_NOT_IN_CITY` are mapped in the travel, acceptance and shop failure classifiers to a banner (copy provisional) should the BE refuse anyway. `awaitingAid { quest aidQuest since }` joins `CharacterStatus` and `CharacterFragment` (additive, already on BE `develop`).
- **D-17 (user decision):** the `aid` quest («Soccorso: …») moves from the service family to the **combat family** of the Board sheet (Phase 6 D-09 amended): enemy, time, rank slots, party counter k/N, abandon while waiting; free (`requiredPoints: null`, no cost line).
- **D-18 (user decision, 2026-10-27):** started quests stay torn on the Board until they conclude — user: *«finché una missione non è conclusa il foglio resta strappato sulla board una volta che i posti sono pieni (e che quindi la quest è cominciata)»*. The edge case of a seat freed after the start (a participant deletes the character or dies) is closed **by the BE in Phase 9.2** («Il BE non libera i posti delle quest avviate»): the archive keeps the registration as a placeholder, the seats stay full and the Phase 6 torn-when-full rule holds unchanged. **No FE change** beyond the existing rule; the k/N counter may show the placeholder seat.

#### Process and quality
- **D-19:** **No UI phase, no UI-SPEC** (Phase 6/7/8 D-19 carried forward): everything visual is provisional, token-based (`kg_theme.dart`), existing parchment assets only (`emptySheet`, `bottomEmptySheet`), no new Cloudinary assets.
- **D-20:** **TDD red → green → refactor:** unit tests for the `QuestResult` parsing (all five outcomes, null enemy/spell, orphan items, optional `acknowledgedAt`), the queue (FIFO by `resolvedAt`, dedup by id, Map-only gating, death exception, ack retry), the delivery coordinator with fakes (subscription, push intent, unacknowledged query), the routing hold, the injury labels, the awaiting-aid derivations (label, disabled pages, failure codes); widget tests for the sheet (sections per outcome, HP animation end state, button-only dismissal, `PopScope`), the pawn label and the Board `aid` family; `flutter analyze` with no new issues; `dart format` only on touched files (Phase 11 D-38); `tool/schema_check` against `git -C <BE> show origin/develop:src/schema.gql` in the final plan.
- **D-21:** the FE develops against the BE 9.2 contract proposed in `BACKEND-NOTES.md` of this phase with fakes and recorded `QueryResult`s (pattern of Phases 3–8); `QuestResult.fromJson` treats `acknowledgedAt` as optional. The plans that register the `UnacknowledgedQuestResults` / `AcknowledgeQuestResult` documents in the schema-check registry and the device E2E run **after** the BE 9.2 PR is merged on BE `develop` (same gate pattern as 08-12). BE PR before FE PR.
- **D-22:** Boy Scout within scope: the Phase 5 FE handoff note «`questEnd.id` = pendingQuestId» is corrected to the result id; the comment in `NotificationCategory` about a «future `combatResult`» goes (no such push type exists, BE §4); nothing else outside the touched lines.

### Claude's Discretion
- Animation durations and whether a tap skips the HP animation (D-02); the «1 di 3» counter (D-08); where the queue cubit and the delivery coordinator live (provided by `AuthenticatedShell` like `TravelCubit`, listener mounted in `MainScreen` next to `SpellOutcomeListener` — the pattern is fixed, names and split are free); how «the Map is free» is observed (root Navigator observer, Map overlay state, drag state, current page); the hold cap (D-13); the retry policy of the ack and of the unacknowledged refetch (D-09/D-10); header and button copy, ink colours (provisional); the Italian injury labels (D-03); haptics on sheet open; how `resolvedAt` is formatted.

### Deferred Ideas (OUT OF SCOPE)
- **Result history** («ultimi esiti» page) — backlog; BE §14 YAGNI, `unacknowledgedQuestResults` is not a history.
- **Names of the rescued adventurers** on the rescuer's sheet — the user chose the number (2026-10-27); an additive BE field if wanted later.
- **Per-outcome banner copy** («Vittoria: …») — the user chose the generic BE text; revisit after the UAT.
- **Dedicated tombstone parchment** for the death — the user chose the shared widget; asset later.
- **Return to the city after a success** — a free travel chosen by the player (BE §5): nothing to build.
- **Sound or haptics on sheet open** — no requirement; Claude's discretion if cheap.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COMBAT-01 | Full-screen result sheet, subscription in foreground / push in background; Map-only (death any tab) | F1 (Map-free signal), F3 (subscription), F4 (banner + `questEnd` popup), F5 (root modal), F2 (death) |
| COMBAT-02 | HP before vs after against max, animated | F7 (`TweenAnimationBuilder`, no green token today → new token) |
| COMBAT-03 | Consumables and spells used | F6 (`AssetQuantity`, `SpellUsage` with nullable spell), C5 |
| COMBAT-04 | Injuries with human-readable labels | F12, C1 (labels already exist, need a pinning test) |
| COMBAT-05 | Rewards (coins, items) and XP (+ level/title, spell learned, saved count) | F6, F7 (`CoinsDisplay`, `ItemRow`), C2 (QuestType label table missing), TitleType labels exist |
| COMBAT-06 | Tap to dismiss only; no swipe | F5 (probe: scrim tap, `handlePopRoute`, drag all ignored; button result `true`) |
| COMBAT-07 | Queued until Map visible and free, FIFO `resolvedAt` | F1, queue design in Architecture |
| COMBAT-08 | Wounded state: pawn label, drag/Board/Shop disabled, codes mapped | F8, C8 (shop classifier missing) |
| COMBAT-09 | Never lost: unacknowledged at cold start/resume/reconnect; ack at close; dedup | F10, F11, C4 (gated documents) |
| COMBAT-10 | `aid` in combat family; started quest stays torn (BE 9.2) | F9 (one-line change + test inversion) |
</phase_requirements>

## Project Constraints (from CLAUDE.md and docs/rules)

- Layers UI → Cubit → Repository → Service; Cubit has no Flutter imports, no `BuildContext`, never calls another Cubit (use `BlocListener` in a widget or a bus/port, like `UserRefreshRequests`). [state-management.md, architecture.md]
- GraphQL strings only in `lib/graphql/`; named operations (`GetXxx`/`ListXxx`, imperative mutations, `OnXxxReceived`); never surface `OperationException` to UI — classify `extensions.code`; bounded backoff, no infinite retry; one consumer per subscription, cancelled in `close()`. [graphql.md]
- No UI chrome in gameplay; **no blocking loading in session** (lookups/refetches/acks are silent). [CLAUDE.md rules 1-2, ui-ux.md]
- Backend is source of truth: the sheet is a summary; character state only from `characterUpdated`; nothing rebuilt from push payload. [CLAUDE.md rule 4]
- Theme tokens only (`lib/theme/kg_theme.dart`); no hex/TextStyle inline; new token → add to theme. SVG via `CachedSvg`; URLs via `CloudinaryAssets`. [ui-ux.md, assets.md]
- TDD red→green→refactor; `bloc_test` for every non-trivial Cubit; `mocktail`; no `Future.delayed` sync in tests; `flutter analyze` clean (no new issues). [testing.md]
- Branch `feat/09-combat-result-sheet` (current), PR → `develop` with `GH_TOKEN=$(gh auth token --user LucaTabbia)`, after the BE 9.2 PR; commit scope `phase-9` for docs; **no `Co-Authored-By` trailer** (user memory overrides the harness attribution); subject ≤ 72. [workflow.md, memory]
- **Never `dart format` a directory**; only touched files that are already clean. DIRTY files touched by this phase (hand edits only, never format): `lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart`, `lib/models/enums/injury_type.dart`, `lib/models/enums/quest_type.dart`, `lib/models/asset_item.dart`, `lib/screens/mainScreen/tabs/journal/journal.dart` [VERIFIED: `dart format --output=none --set-exit-if-changed` per file]. CLEAN (format after edit): `world_map.dart`, `main_screen.dart`, `authenticated_shell.dart`, `session_home.dart`, `auth_gate.dart`, `session_sync_scope.dart`, `session_sync_cubit.dart`, `quest_sheet_details.dart`, `quest_info_sheet.dart`, `character_status.dart`, `character_fragment.dart`, `graphql.dart`, `satchel_availability.dart`, `notification_popup_registry.dart`, `notification_category.dart`, `travel_failure.dart`, `quest_acceptance_failure.dart`, `travel_notice.dart`, `quest_acceptance_notice.dart`, `transaction_cubit.dart`, `shop.dart`, `kg_theme.dart`, `main.dart`, `schema_check_documents.dart`, `in_app_notifications_cubit.dart`, `character_cubit.dart`, `title_type.dart`, `notification_intent_landing.dart`, `item_row.dart`, `quest_lane.dart`, `auth_gate_test.dart`, `session_home_test.dart`.
- Never print `.env`/environment; BE repo read-only (`git -C … fetch/show` only).

## Standard Stack

No new dependency is needed. [VERIFIED: pubspec.yaml]

| Library | Version | Use in this phase |
|---------|---------|-------------------|
| flutter (fvm) | 3.35.5 stable | `showGeneralDialog`, `PopScope`, `ModalRoute.isCurrentOf`, `TweenAnimationBuilder` |
| flutter_bloc / bloc_test | ^9.1.1 / ^10.0.0 | new cubits + tests |
| graphql_flutter (graphql 5.2.1) | ^5.2.1 | subscription re-sent after WS reconnect (Phase 3 D-03); `SocketClient.connectionState` is a `BehaviorSubject` [VERIFIED: graphql-5.2.1 websocket_client.dart:215] |
| equatable | ^2.0.0 | models/states |
| mocktail / fake_async | ^1.0.5 / ^1.3.3 | fakes, timers (10 s cap, backoff) |
| intl | ^0.20.2 | `resolvedAt` formatting (`DateFormat`, pattern of `travel_time_format.dart:26-29`) |

**Alternatives considered:** a `NavigatorObserver` on `MaterialApp.navigatorObservers` (none registered today, `main.dart:298-303`) vs `ModalRoute.isCurrentOf(context)` from a widget inside the home route → use `isCurrentOf` (no global wiring; probe verified). `showModalBottomSheet` (draggable, swipe-dismissable, `PaperSheetModal` is a `DraggableScrollableSheet`) vs `showGeneralDialog` → use `showGeneralDialog` (COMBAT-06).

## Findings per research flag

### F1 — "Map tab visible and free"

Facts:
- Current page: `_MainScreenState.currentPage` + `pageController` (`main_screen.dart:46-47, 61-66`), `onPageChanged` (`:199-203`); every change is `jumpToPage` (`NeverScrollableScrollPhysics`, `:111`). Map index `NotificationIntentLanding.worldMapPageIndex = 0` (`notification_intent_landing.dart:19`). Probe: `jumpToPage` fires `onPageChanged` ([2, 0]) [VERIFIED: probe]. Initial page 0 does **not** fire `onPageChanged` → seed the availability state with page 0.
- Root routes: no `navigatorObservers`, no nested Navigator (grep). Root routes on the Map: travel confirmation (`world_map.dart:375-393`), abandon sheet (`:463-486`), city lore modal (`:495-507`) — all `showModalBottomSheet` (default `useRootNavigator: false`, but the only Navigator is the root). Dialogs: `showDestructiveConfirmation` (`destructive_confirmation_dialog.dart:49-64`). Shop/Journal sheets are other tabs.
- In-map overlay: `QuestInfoOverlay` is **in-tree**, driven by `_WorldMapState._selectedQuest/_selectedLane` and `_questAnimationController` (`world_map.dart:72-76, 127-134, 420-435`); closed when the animation is dismissed. `QuestInfoSheet`/`EquipmentInfoSheet`/`SpellInfoSheet` elsewhere are in-tree in Board/Journal (not routes) — irrelevant since the sheet is Map-only.
- Drag: `_CharacterMarkerLayerState._dragPoint` (`character_marker_layer.dart:49`), `Draggable` at `:158-174` (`onDragUpdate`, `onDragEnd`; `onDragStarted` available). After release, `TravelCubit` goes `TravelPreviewing` → sheet; `TravelCubit` is shell-provided.

**Proposal (one concrete way):** `MapAvailabilityCubit` (shell, `lib/screens/mainScreen/tabs/map/mapAvailabilityCubit/`), state `{isMapPage, isRouteCovered, isQuestSheetOpen, isPawnDragging}` with `bool get isFree => isMapPage && !isRouteCovered && !isQuestSheetOpen && !isPawnDragging`. Writers (UI → Cubit, no cubit-to-cubit):
1. `MainScreen.onPageChanged` → `pageChanged(page == worldMapPageIndex)`; initial state `isMapPage: true`.
2. `QuestResultPresenter` (mounted in MainScreen, inside the home route): in `didChangeDependencies`, `routeCovered(!(ModalRoute.isCurrentOf(context) ?? true))`. Probe: a widget in the home route observed `[true, false, true, false, true]` across a modal bottom sheet and a dialog [VERIFIED: probe]. The result sheet itself makes the route covered → no second sheet over it.
3. `WorldMap`: `questSheetChanged(true)` in `_selectQuest`/`_openFromPaper`, `false` in `_clearSelection` (animation dismissed) and in `dispose`.
4. `CharacterMarkerLayer`: `pawnDragChanged(true)` on `onDragStarted`, `false` on `onDragEnd` (and `dispose`). DIRTY file → hand edit.
5. Additionally treat `TravelCubit.state is! TravelIdle` as busy in the presenter (`BlocBuilder`/`listenWhen`), covering the gap between release and the sheet push.

### F2 — Death routing hold

Facts:
- `SessionHome` (`session_home.dart:24-31`) is stateless: `currentCharacter == null` → `creationBuilder`, else `KeyedSubtree('character:<id>')` around `shellBuilder`. It sits under `SessionSyncScope` inside AuthGate's `KeyedSubtree(user.id)` (`main.dart:310-345`); an AuthGate rebuild keeps `SessionSyncScope` providers (same element).
- **`AuthGate` pops every root route on any character change** (`auth_gate.dart:33-38`, `_changesCharacter` `:75-78`): in order "result first, user null second" this pop would close the open death sheet. Tests pinning it: `auth_gate_test.dart:369` (gain), `:381` (lose), `:393` (swap), `:405` (points-only keeps).
- `NotificationIntentCubit.offer` drops intents while `currentCharacter == null` (`notification_intent_cubit.dart:25-28, 45-48`) → a push tap during the hold is dropped (covered by the unacknowledged query).
- Deletion from Settings also produces `currentCharacter: null` via `_handOverDeletedUser` → `AuthCubit.adoptUser` (`authenticated_shell.dart:224-230`).
- BE §3/§6: death happens only to a wounded character of a failed aid (`awaitingAid != null`); the already-open `questResultReceived` delivers the `death` result even after the archive; a **new** subscribe answers `NOT_FOUND`. While the shell is held, `CharacterCubit` may get `NOT_FOUND` on a resubscribe → terminal + `requestUserRefresh` (`character_cubit.dart:124-134`); the watchdog only degrades if no stream is healthy (`sync_watchdog.dart:34-40`) — harmless.

**Proposal:**
- `CharacterExitHoldCubit` (Flutter-free, `lib/screens/auth/characterExitHoldCubit/`), provided in `SessionSyncScope` (user-scoped, above `SessionHome`, reachable from the shell). State `{guardedCharacterId, isDeathSheetOpen, isCapExpired}`. Methods: `guard(id)` / `unguard(id)` (written by a shell listener on `CharacterCubit`: `awaitingAid != null` ↔ guarded), `deathSheetOpened(id)`, `release()` (death button, after the ack attempt; deletion handover), `characterGone(id)` (starts the cap timer `Duration(seconds: 10)` only if no death sheet is open; expiry → release). `close()` cancels the timer.
- `SessionHome` → `StatefulWidget` remembering `_lastCharacterId`; in `build`: if `user.currentCharacter == null` and the hold state guards `_lastCharacterId` (not released) → keep `KeyedSubtree('character:$_lastCharacterId')` + shell; post-frame call `characterGone`. When the rendered character key actually changes (creation shown, or new id) → post-frame `Navigator.of(context, rootNavigator: true).popUntil(isFirst)` (moved from AuthGate). AuthGate keeps popping only on `_leavesSession` (`listenWhen` drops `_changesCharacter`; `buildWhen` unchanged). Move the three character-change pop tests to `session_home_test.dart`.
- `_handOverDeletedUser` calls `hold.release()` before `adoptUser` → a Settings deletion of a wounded character never waits.
- Event orders: **(A) result first** — presenter opens the death sheet on any tab once the root Navigator is free (if a route is open and the character is gone, pop it first: Phase 3 D-10 rationale), calls `deathSheetOpened`; `userUpdated(null)` arrives → no AuthGate pop, SessionHome keeps the shell; «Riposa in pace» → ack (await, ≤ 2 s cap like `AuthCubit.pushUnregisterTimeout`) → `release()` → creation page. **(B) user null first** — guarded → shell kept, cap 10 s; the subscription delivers `death` → sheet (cap cancelled) → button → release. Cap expires → creation page; the result returns later via the unacknowledged query in the new character's shell (historical sheet, see C9). **Not guarded** (not wounded) → immediate routing as today.

### F3 — Subscription lifecycle

Facts: `KlimmeckGraphQl.performSubscription` (`graphql.dart:94-105`, `FetchPolicy.noCache`), typed mapping `subscribeToCharacter` (`:113-120`) with `_throwIfStreamFailed` → `SubscriptionStreamException(operation, code)` (`:131-137`) and parsing boundary `_characterFrom` → `FormatException` (`:139-148`). `CharacterCubit`: `subscribeToCharacter` (`character_cubit.dart:97-102`), `_onStreamError` terminal on `isAccessDeniedError` (`graphql_error_code.dart:39-44`), `_scheduleResubscribe` with `exponentialBackoff(_attempt++, max: WsReconnectPolicy.maxReconnectDelay)` (60 s) (`:136-152`), cleanup in `close()` (`:154-164`). graphql 5.2.1 re-sends live subscriptions after a socket reconnect (Phase 3 D-03); `questResultReceived` has **no snapshot** → the reconnect gap is closed only by the unacknowledged refetch.

**Spec:** `Stream<QuestResult> subscribeToQuestResults(String characterId)` in `KlimmeckGraphQl`, document `QuestResultSubscriptions.questResultReceived` (`subscription OnQuestResultReceived($characterId: String!)`), mapped with `_throwIfStreamFailed(result, operation: 'questResultReceived')` and a `_questResultFrom` boundary. Exposed by a new `QuestResultRepository.watch(characterId)`. Consumer: `QuestResultsCubit` (shell provider, `lazy: false`, `..start()`), same resubscribe/terminal logic as `CharacterCubit`, except: a `FormatException` event is **skipped** (log, no resubscribe — a malformed result must not tear down the stream); do **not** add a `SyncSource` (the watchdog would change logout semantics); closed with the shell (keyed by character id) — so it stays open during the D-13 hold.

### F4 — Push and banner path

- `PushEvent` (`push_event.dart`): `dedupKey = '<wireType>|<id>'` (`:45`), `intent`, `notification`. `InAppNotificationsCubit.publish(PushEvent)` (`in_app_notifications_cubit.dart:50-59`) dedups on that key for `personalDedupWindow = 2 min` (`:33`) and its banner tap calls `open(event)` → `NotificationTapRouter.handle(intent)` (`:81-84`, `notification_tap_router.dart:21-29`) → `NotificationIntentCubit.offer` → `NotificationIntentLanding._consumePendingIntent` (pops root routes, jumps to page 0, calls the popup, `notification_intent_landing.dart:48-60`). `publishNotice` uses key `notice|…` and its tap only dismisses (`:63-72`, `authenticated_shell.dart:307-313`) → **use `publish(PushEvent)`** for D-12.
- Toggle gate: `acceptPushEvent` (`data_message_handler.dart:9-26`) for both background (`handleDataMessage`) and foreground (`ForegroundPushEvents`, `foreground_push_events.dart`). The subscription banner must apply the same rule: read `NotificationPreferencesCubit.state.isEnabled(NotificationCategory.questEnd)` (shell-provided, `..load()` at mount) in the widget listener before `publish`. The sheet is never gated.
- Copy in one place: `lib/models/quest_result/quest_end_event.dart` with `const questEndTitle = 'Missione conclusa'`, `const questEndBody = "La tua missione è terminata: scopri com'è andata."` (BE §4) and `PushEvent questEndEventOf(QuestResult r)` (`category: questEnd, id: r.id, sentAt: r.resolvedAt`).
- Popup: `defaultNotificationPopups` gains `NotificationCategory.questEnd: requestQuestResult` → `context.read<QuestResultsCubit>().requestFromTap(intent.id)` (`notification_popup_registry.dart:13-15`; pattern `focusCharacterOnMap`). Update test `notification_intent_landing_test.dart:177` ('Phase 7 registers only the travelEnd popup').
- D-22: `notification_category.dart:23` comment; FE Phase 5 `BACKEND-NOTES.md:72` (`pendingQuest(id)` → `questResult(id)`) and `:6/:17` (`combatResult`). Keep the tests that use `combatResult` as an unknown-type example.

### F5 — Full-screen parchment overlay

- `PaperSheetModal` is a `DraggableScrollableSheet` (`paper_sheet_modal.dart:12-48`) opened with `showModalBottomSheet` → swipe-dismissable, not usable. `QuestInfoSheet`/`EquipmentInfoSheet`/`SpellInfoSheet` are in-tree with an `AnimationController` (Board/Journal/Map overlay). `DestructiveConfirmationDialog` uses `showDialog(barrierDismissible: false)`.
- **Mechanism:** `showGeneralDialog<bool>(context, useRootNavigator: true, barrierDismissible: false, barrierColor: <token scrim>, pageBuilder: … PopScope(canPop: false, child: QuestResultSheet(...)))`. Probe [VERIFIED]: scrim tap ignored; `handlePopRoute()` (Android back) consumed without popping; a 400 px drag ignored; the button's `Navigator.pop(true)` completes the future with `true`; an external `popUntil(isFirst)` (AuthGate session end, `NotificationIntentLanding`) completes it with `null` → the queue must **requeue, not ack**.
- Root routes are outside the shell providers (`authenticated_shell.dart:79-81`): pass values, not `context.read` inside the route; button callback returns via `pop(true)`, the presenter calls the cubit.
- Assets [VERIFIED: Cloudinary SVG headers]: `emptySheet` viewBox 315×375 (portrait; `QuestInfoSheet` renders it at height × 1.5, scrollable, `quest_info_sheet.dart:46-72`); `bottomEmptySheet` 375×375; `emptyCardSheet` = card background (`loot_item_card.dart:19`). Recommend `emptySheet` like `QuestInfoSheet` inside a `SingleChildScrollView` (landscape app: `main.dart:76-79`).

### F6 — `QuestResult` model and fragment

Wire types [VERIFIED: BE schema]: all `QuestResult` fields non-null except `enemy`, `spellLearned`, `SpellUsage.spell`; `QuestResultQuest.type` is `String` (not an enum); `titleBefore/After` are `String` (`rookie…legend` → `TitleType` with Italian labels in `title_type.dart`); `resolvedAt: DateTime`; `rescuedCharacters: [ID!]!`.

Reuse: `AssetQuantity.fromJson` (`asset_quantity.dart:9-14`, item nullable), `AssetItem.fromJson` (discriminator `equipType != null`, `asset_item.dart:25-31`), `LootItem/EquipmentItem.fromJson` (description defaults to `''`), `Coins.fromJson`, `Spell.fromJson` (tolerates `{id name}`), `Enemy.fromJson` (tolerates `{id name imagePath}`; **if `locations` were present it would throw** — `json["locations"]?.map(...)` assigned to `List<PoiType>?`, `enemy.dart:40-42` — a second reason never to select it). `InjuryType.values.byName` (28 names identical to BE, diff verified). `QuestType`: parse with `QuestType.values.asNameMap()[type]` (unknown → null, keep title). `QuestOutcome`: new enum `{success, failure, rescued, death, gmCompleted}`.

Parsing rules: `QuestResult.tryFromJson` (pattern `ActiveTravel.tryFromJson`, `active_travel.dart:33-40`): missing required scalar or unknown `outcome` → null (event skipped); unknown injury name → skipped entry; orphan items (`item == null`) → skipped; `acknowledgedAt` optional `DateTime?`.

New in `CharacterStatus` (`character_status.dart:44-68`): `awaitingAid: AwaitingAid.tryFromJson(json['awaitingAid'])` (`{quest, aidQuest, since}`), included in `props`, `toJson`, preserved by `copyWith` like `activeTravel`. `CharacterFragment.statusFields` (`character_fragment.dart:23-60`) gains `awaitingAid { quest aidQuest since }` — **not gated** (on BE develop) [VERIFIED: `OnStatus` probe document OK].

**Fragment to register (C5 applied):**
```graphql
id outcome resolvedAt character user
quest { id type title }
hpBefore hpAfter maxLifePoints injuriesAdded
consumablesUsed { quantity item {
  ... on EquipmentItem { ${EquipmentFragment.simpleFields} }          # id name itemType equipType rarity
  ... on LootItem { ${LootFragment.simpleFields} description effect power } } }
spellsUsed { usages spell { id name } }
rewards { coins { ${CoinsFragment.fields} } items { quantity item {
  ... on EquipmentItem { ${EquipmentFragment.simpleFields} description }
  ... on LootItem { ${LootFragment.simpleFields} description effect power } } } }
xpBefore xpGained xpAfter levelBefore levelAfter titleBefore titleAfter
spellLearned { id name }
enemy { id name imagePath }
rescuedCharacters
# acknowledgedAt   ← only in the schema-gated plan
```
Validation [VERIFIED 2026-10-27, BE `10e5f43`]: `OnQuestResultReceived` OK, `GetQuestResult` OK; with `acknowledgedAt` → FAIL `Cannot query field "acknowledgedAt"`; `unacknowledgedQuestResults` / `acknowledgeQuestResult` → FAIL (not merged). `enemy { locations }` validates (the bug is runtime, BE §14). Current registry: 34/34 OK.

### F7 — HP animation and sheet widgets

- No `TweenAnimationBuilder` in `lib/` yet; `AnimatedSwitcher` in `usages_pencil_counter.dart:19`, `loot_item_card.dart:69`, `authenticated_shell.dart:285`. Use `TweenAnimationBuilder<double>(tween: Tween(begin: hpBefore, end: hpAfter), duration: …)` driving a bar (`value / maxLifePoints`) and `Text('${value.round()} / $maxLifePoints')`; widget test asserts the end state after `pumpAndSettle`. Skip-on-tap: rebuild with `duration: Duration.zero` (discretion).
- Journal life display: `journal.dart:85-120` (text `"current / max"`, heal icon via raw URL — DIRTY file, not to touch).
- Tokens [`kg_theme.dart:12-45`]: `bloodRed`, `royalCrimson`, `deepNight`, `darkWood`, `parchment`, `disabledScrim`, text styles `headlineLarge/titleMedium/bodyLarge/bodyMedium/specialText`; **no green** → add one token (e.g. `healGreen`) + a test in `kg_theme_test.dart`.
- Rewards: `CoinsDisplay(coins:, height:, width:)` (`coins_display.dart`); `ItemRow(assetItem:, quantity:, showCoins: false, size:)` (`item_row.dart:11-95`; shows the card, `description`, and since 08-14 the loot effect line keyed `item-effect-<id>` via `itemEffectLabel`) → select `description effect power` (fragment above).
- Enemy: `QuestInfoSheet._combatBody` renders `Image.asset(enemy.imagePath!)` with `errorBuilder` → nothing (`quest_info_sheet.dart:150-188`); BE `imagePath` values are relative (`'enemies/wolf.png'`) and no `assets/images/enemies/` exists → the image is invisible today in both sheets. Mirror the same rendering (consistency); do not use `CachedSvg` (PNG path).

### F8 — Wounded state

- Travelling pawn label: `_buildTravellingPawn` (`character_marker_layer.dart:90-118`) adds a second `Marker` with `_TravelLabel` (`:220-249`, `IgnorePointer`, `travelLabelKey`). Idle pawn `_buildIdlePawn` (`:68-85`): add the same label Marker with «In attesa di soccorso» and a new key (`awaitingAidLabelKey`) when `status.awaitingAid != null`.
- Drag gate `_canStartTravel` (`:127-130`) checks `activeTravel == null && pendingQuest == null && travel is TravelIdle`; after a `failure` the lane is **emptied** (BE §3) → the pawn would be draggable → add `&& status.awaitingAid == null`.
- Satchel: `disabledSatchelPages({location, cities, isTravelling})` (`satchel_availability.dart:10-16`) → add `isAwaitingAid` (Board 4, Shop 5 disabled); `MainScreen._satchelInputsOf` (`main_screen.dart:229-236`) returns the flag; `_isPageDisabled` (`:216-227`) follows.
- Classifiers: `travel_failure.dart:49-65` add `awaitingAidCode = 'AWAITING_AID'` → `TravelFailure.awaitingAid` + copy in `travel_notice.dart`; `quest_acceptance_failure.dart:49-70` → `QuestAcceptanceFailure.awaitingAid` + copy in `quest_acceptance_notice.dart` (both exhaustive switches → compiler enforces copy). Shop: see C8.

### F9 — Board `aid` family

`questSheetFamilyOf` (`quest_sheet_details.dart:18-25`) puts `aid` in `service`. Change: add `QuestType.aid` to the combat arm; invert `test/models/quest/quest_sheet_details_test.dart:20-45` (aid moves to the combat list) and add a `QuestInfoSheet` widget test (`combatFamilyKey`). Everything else already holds: `aid ∈ registeredQuestTypes` (`quest_lane.dart:14-19`) → slot lines k/N; `costLineOf` returns null for the standard lane (`quest_cost_line.dart`); torn assets `questSheetTorn1/2` (`quest_paper_asset.dart:36-42`); state label «Aiutando…»; abandon is the map overlay's `onAbandon` for any waiting lane (`world_map.dart:247-249`). The aid carries the cloned `infos.enemy` and `requiredAdventurers` (BE §6); `QuestFragment` already selects `infos.enemy { id name imagePath }` and slots. D-18: no FE change.

### F10 — Schema-check registry and gating

- Registry `tool/schema_check/schema_check_documents.dart:28-63` (`Map<String, String>`, key = operation name, 34 entries). `test/tool/schema_check_documents_test.dart:28-30` requires **registry keys == every named operation in `lib/graphql/{queries,mutations,subscriptions}`**; `:32-40` one operation named like the key.
- Gate commands (08-12 pattern): `git -C <BE> fetch -q origin develop`; `git -C <BE> show origin/develop:src/schema.gql > $SCRATCH/schema.gql`; `grep -n "unacknowledgedQuestResults\|acknowledgeQuestResult\|acknowledgedAt"` must succeed (else STOP); `dart run tool/schema_check/dump_documents.dart $SCRATCH/docs`; `NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js $SCRATCH/schema.gql $SCRATCH/docs` → expected **38 OK** (34 + `OnQuestResultReceived`, `GetQuestResult`, + gated `ListUnacknowledgedQuestResults`, `AcknowledgeQuestResult`; names follow naming.md; align to the BE's final field names).
- Repository test pattern: `MockKlimmeckGraphQl` (`test/helpers/mocks.dart`), coded `OperationException(graphqlErrors: [GraphQLError(message:, extensions: {'code': …})])` (`spells_repository_test.dart:16-21`); document tests `_collapsed`/`parseString` (`test/graphql/quest_documents_test.dart`). Recorded payload fixtures go in `test/helpers/fixtures/quest_result_fixtures.dart` (one map per outcome).

### F11 — Refetch triggers

- Cold start: the shell exists only after `AuthAuthenticated` with a character (i.e. after `me`) → `QuestResultsCubit.start()` at shell creation = cold-start bootstrap (also = first shell after creation).
- Resume: `AppLifecycleEvents.foregrounded` (`app_lifecycle_events.dart`, fed by `AppLifecycleBridge` `onRestart`, `app_lifecycle_bridge.dart:24-27`), already consumed by `CharacterCubit` (`character_cubit.dart:65-67`), `SessionSyncCubit` (`session_sync_cubit.dart:76-79`), `ServerClockService`.
- WS reconnect: no public signal today; the socket is observed once per session by `SessionSyncCubit` (`:68-72`, `openConnectionStream()` from `SessionSyncScope`). **Proposal:** a Flutter-free `ConnectionRestoredBus` (`lib/repository/services/sync/connection_restored_events.dart`, interface `ConnectionRestoredEvents { Stream<void> get restored; }`, pattern `UserRefreshRequestBus`) provided by `SessionSyncScope`, notified by `SessionSyncCubit` on a `false → true` transition **after** the first connect. `QuestResultsCubit` subscribes to it.
- Each trigger: retry pending acks first, then `fetchUnacknowledged()` with `silentRetry` (`utils/silent_retry.dart`), single-flight like `SessionSyncCubit.refreshUser`.

### F12 — Injury labels

All 28 labels already exist in `InjuryTypeExtension.label` (`injury_type.dart:46-107`), used by `injury_name_icon.dart:22`, no test. FE and BE value sets identical (diff of 28 names, verified). Table (copy verbatim into the test):

| value | label | value | label |
|---|---|---|---|
| headConcussion | Commozione cerebrale | brokenRightLeg | Gamba destra rotta |
| traumaticBrainInjury | Trauma cranico | fracturedRib | Costola fratturata |
| missingLeftEye | Occhio sinistro mancante | puncturedLung | Polmone perforato |
| missingRightEye | Occhio destro mancante | deepCut | Taglio profondo |
| blindness | Cecità | severeBurn | Ustione grave |
| blackEye | Occhio nero | poisonInjection | Iniezione velenosa |
| missingLeftArm | Braccio sinistro mancante | paralysis | Paralisi |
| missingRightArm | Braccio destro mancante | internalBleeding | Emorragia interna |
| brokenLeftArm | Braccio sinistro rotto | frostbite | Congelamento |
| brokenRightArm | Braccio destro rotto | infection | Infezione |
| crushedLeftHand | Mano sinistra schiacciata | spinalInjury | Lesione spinale |
| crushedRightHand | Mano destra schiacciata | missingLeftLeg | Gamba sinistra mancante |
| missingRightHand | Mano destra mancante | missingRightLeg | Gamba destra mancante |
| missingLeftHand | Mano sinistra mancante | brokenLeftLeg | Gamba sinistra rotta |

Phase 8 pattern for labels: enhanced-enum field (`EffectType.label`, `effect_type.dart`; `TitleType.label`) + `test/models/enums/effect_type_test.dart`. Injury: keep the extension (DIRTY file), add `test/models/enums/injury_type_test.dart`.

**QuestType labels (new, C2) — proposed provisional copy:** hunt «Caccia», aid «Soccorso», enemy «Nemico», worldMission «Missione mondiale», boss «Boss», dungeon «Dungeon», story «Storia», study «Studio», heal «Cura», job «Lavoro», crime «Crimine», guard «Guardia». Add as an enhanced-enum `label` (hand edit, `quest_type.dart` DIRTY) + test.

**Outcome headers (D-04):** success «Vittoria», failure «Sconfitta», rescued «Sei stato salvato», death «È morto», gmCompleted «Missione completata»; buttons «Continua» / «Riposa in pace»; lookup banner «Risultato non disponibile»; wounded label «In attesa di soccorso»; travel/acceptance `awaitingAid` copy «Sei in attesa di soccorso»; shop `shopNotInCity` «Il negozio è disponibile solo in città» (all provisional).

### F13 — Test harness

- `bloc_test` + `mocktail` + `fake_async` (`spells_repository_test.dart` uses `fake_async` for the 15 s timeout); shared mocks only in `test/helpers/mocks.dart` (rule in its header); fakes in `test/helpers/fakes/` (`FakeServerClockService`, `RecordingSyncHealth`, `RecordingNotificationIntentSink`, `InMemoryNotificationPreferencesStore`, `FakeGraphQlWsServer` for real-socket tests with `test`, not `testWidgets`).
- Widget harnesses: `buildTestApp(home:)` (`test_app.dart`), `mapHarness` (`map_harness.dart`), `landscape.dart`, `svg_cache_seed.dart` (seed `CachedSvg` to avoid network).
- Shell tests pattern "provides X and closes it on removal" (`authenticated_shell_test.dart:173-252`); a `lazy: false` cubit that subscribes at creation requires stubbing `subscribeToQuestResults` on the shell test's `MockKlimmeckGraphQl` (otherwise mocktail returns null → crash).
- Baselines [VERIFIED 2026-10-27]: `flutter test` **2139 passed in ~60 s**; `flutter analyze` **53 issues, 0 errors** (~5 s); schema check 34/34 OK.

## Conflicts with the CONTEXT (orchestrator amends; recommended resolution)

- **C1 — Injury labels already exist** (D-03 "new label table"). Resolution: reuse `InjuryTypeExtension.label`; COMBAT-04 delivered by a pinning test (28 labels + BE name parity) and the sheet rendering. No new table.
- **C2 — No "Phase 6" Italian label for `quest.type`** (D-03). Only state labels exist (`quest_state_label.dart`). Resolution: add `QuestType.label` with the provisional copy in F12; unknown wire type → no label line.
- **C3 — AuthGate pops root routes on every character change** (`auth_gate.dart:33-38`), which closes the death sheet (D-13). Resolution: move the character-change pop into `SessionHome`, executed when the rendered shell actually changes (after the hold); AuthGate keeps the `_leavesSession` pop. Phase 3 D-10 behaviour preserved; 3 tests move from `auth_gate_test.dart` to `session_home_test.dart`.
- **C4 — D-21 vs the registry test.** A document in `lib/graphql/` must be in the registry (`schema_check_documents_test.dart:28-30`), so the 9.2 documents cannot exist before the gated plan. Resolution: the gated plan adds documents + registry + `KlimmeckGraphQl.getUnacknowledgedQuestResults()`/`acknowledgeQuestResult(id)` + repository methods + `acknowledgedAt` in the fragment; earlier plans code `QuestResultsCubit` against two Flutter-free ports (`PendingQuestResults.fetchUnacknowledged()`, `QuestResultAcknowledger.acknowledge(id)`) with fakes, and the shell composes null-object implementations (`NoPendingQuestResults` → `[]`, `NoQuestResultAcknowledger` → no-op; pattern `NoopPushMessaging`, `NoPushSessionCleanup`) until the gate swaps in the repository.
- **C5 — BE example fragment loses equipment rewards.** `... on EquipmentItem { id name rarity }` has no `equipType`, and `AssetItem.fromJson` discriminates on it (`asset_item.dart:25-31`). Resolution: use `EquipmentFragment.simpleFields` / `LootFragment.simpleFields` (+ `description effect power`) as in `QuestFragment`.
- **C6 — D-07 "without a banner" vs the foreground FCM push.** `ForegroundPushEvents` publishes a `questEnd` banner independently of the subscription. Resolution: add `InAppNotificationsCubit.suppress(String dedupKey)` (marks the key seen for `personalDedupWindow` and drops a queued/current banner with that key); the presenter calls it when a sheet opens at once. Banner rule: publish only when the sheet cannot open immediately.
- **C7 — D-14 "name of the dead character" is not on `QuestResult`.** Resolution: when `result.character` is the shell's character, take the name from the last `CharacterLoaded` (still available during the hold); historical results show no name. Title/level come from `titleAfter`/`levelAfter`.
- **C8 — No shop failure classifier exists.** `KlimmeckGraphQl.doTransaction` throws `Exception(getGenericErrorMessage(...))` (`graphql.dart:409-423`), `TransactionCubit` has a code-less `TransactionError` (`transaction_cubit.dart:15-30`), shop shows a speech bubble (`shop.dart:271-275`). Resolution: `doTransaction` rethrows the `OperationException` (`_dataOrThrow`), new `lib/repository/transaction_failure.dart` (`shopNotInCity`, …, `connection`, `unknown`), `TransactionError(failure)`, banner via `publishNotice` for `shopNotInCity` (bubble kept for the rest). No `TransactionCubit` tests exist today → add `bloc_test`.
- **C9 — Cold start after a death** (app killed while dying): `currentCharacter` is already `null` → creation page, no shell, no queue; the death sheet appears only in the next character's shell as a historical sheet (button closes, no routing). D-13 covers the live order only. Recommendation: accept and record (user confirmation in the next discuss/UAT).
- **C10 — Hold arming.** A Settings deletion also yields `currentCharacter: null`; holding every time would add a 10 s wait. Resolution: guard only while the last character has `awaitingAid != null` (the only state that can die, BE §6) or a death sheet is open; the deletion handover releases the hold.

## Architecture Patterns

```
lib/models/quest_result/          quest_result.dart, quest_outcome.dart, spell_usage.dart,
                                  quest_result_quest.dart, quest_rewards.dart, quest_end_event.dart
lib/models/character/awaiting_aid.dart
lib/graphql/fragments/quest_result_fragment.dart
lib/graphql/subscriptions/quest_result_subscriptions.dart   (OnQuestResultReceived)
lib/graphql/queries/quest_result_queries.dart               (GetQuestResult; gated: ListUnacknowledgedQuestResults)
lib/graphql/mutations/quest_result_mutations.dart           (gated: AcknowledgeQuestResult)
lib/repository/quest_result_repository.dart, quest_result_lookup_failure.dart, transaction_failure.dart
lib/repository/services/sync/connection_restored_events.dart
lib/screens/auth/characterExitHoldCubit/
lib/screens/mainScreen/questResultsCubit/                   (queue + delivery)
lib/screens/mainScreen/tabs/map/mapAvailabilityCubit/
lib/screens/mainScreen/components/quest_result_presenter.dart
lib/shared/components/popup/quest_result_sheet.dart (+ hp_delta_bar.dart)
```

**QuestResultsCubit (state immutable, Equatable):** `queue` (unmodifiable, sorted by `resolvedAt`, ties by id), `pendingAck` ids, `known` ids (shown or acked, session dedup), `arrival` (last subscription result, with a counter so equal results re-emit), `notice` (lookup failure). Actions: `start()`, `requestFromTap(String? id)`, `presented(id)` (removes from queue head into `showing`), `closed(id)` (ack best-effort, add to known, keep in `pendingAck` on failure), `dismissedExternally(id)` (requeue at its FIFO position). Rules: drop any incoming id in `known` or `pendingAck` (a closed sheet whose ack failed must not reappear in the same shell); tap on a known/acked id → nothing (Map already shown by the landing); unknown id → `fetch(id)`; `NOT_FOUND`/`FORBIDDEN` → `notice`; network → silent.

**Presenter (widget, MainScreen next to `SpellOutcomeListener`, `main_screen.dart:99-104`):** listens to `QuestResultsCubit`, `MapAvailabilityCubit`, `TravelCubit`, `CharacterExitHoldCubit`; presentation condition: head exists and (`isFree` or head is `death`, which only needs `!isRouteCovered`; tap-requested presentation ignores the in-map quest overlay because the landing already cleared routes). Death in the queue: lift the Map gate for every result up to and including the death (they concern the dying character; after the hold the shell is gone) [ASSUMED discretion]. Publishes the banner (toggle-checked) for `arrival` results it cannot open immediately, `suppress` otherwise.

### Anti-patterns to avoid
- Building state from the result (HP, location): the character comes from `characterUpdated` only.
- Acking on display or on reception; acking when the route was popped externally (`null`).
- `context.read` of shell cubits inside the dialog route (outside providers).
- Adding the result stream to `SyncWatchdog`.
- Selecting `enemy.locations` (BE bug + FE `Enemy.fromJson` would throw).

## Don't Hand-Roll

| Problem | Don't build | Use |
|---|---|---|
| Route-covered detection | custom observer/global counter | `ModalRoute.isCurrentOf(context)` |
| Non-dismissable modal | custom Overlay/AnimationController | `showGeneralDialog` + `PopScope(canPop: false)` |
| Retry/backoff | ad-hoc loops | `silentRetry`, `exponentialBackoff`, `WsReconnectPolicy.maxReconnectDelay` |
| Error codes | message parsing | `graphQlErrorCode`, `isAccessDeniedError` |
| Banner dedup/tap routing | new banner path | `InAppNotificationsCubit.publish(PushEvent)` + `NotificationTapRouter` |
| Push id validation | regex | `validBackendIdentifier` (already applied to `NotificationIntent.id`) |
| Items/coins rendering | new rows | `ItemRow(showCoins: false)`, `CoinsDisplay` |

## Common Pitfalls

1. **External pop of the sheet** (session end, landing on a new tap) returns `null` → requeue, never ack. Warning sign: a result vanishes after a banner tap.
2. **Death sheet closed by AuthGate** if C3 is not applied (order A). Test: user null emitted while the death sheet is open → sheet still there.
3. **Equipment rewards parsed as loot** without `equipType` (C5).
4. **Duplicate banner** from the foreground FCM push when the sheet already opened (C6).
5. **Re-showing a closed sheet** when the ack failed and the unacknowledged fetch returns it → filter by `pendingAck`.
6. **Draggable pawn while wounded** (lane emptied after `failure`) → `_canStartTravel` must check `awaitingAid`.
7. **Ack lost on «Riposa in pace»** because the shell closes right after → await the ack (≤ 2 s) before `release()`.
8. **Shell tests crash** after adding a `lazy: false` subscribing cubit → stub the mock in `setUp`.
9. **Formatting DIRTY files** (`character_marker_layer.dart`, `quest_type.dart`, `injury_type.dart`).
10. **Malformed result event tearing the stream down** → skip `FormatException`, resubscribe only on transport errors.

## Code Examples

```dart
// Root parchment, button-only dismissal (pattern proven by the probe)
final closedByButton = await showGeneralDialog<bool>(
  context: context,
  useRootNavigator: true,
  barrierDismissible: false,
  barrierColor: KlimmeckGuideTheme.disabledScrim,
  pageBuilder: (routeContext, _, _) => PopScope(
    canPop: false,
    child: QuestResultSheet(
      result: result,
      onContinue: () => Navigator.of(routeContext).pop(true),
    ),
  ),
);
closedByButton == true ? cubit.closed(result.id) : cubit.dismissedExternally(result.id);
```

```dart
// Route covered signal, in a widget inside the home route
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final isCurrent = ModalRoute.isCurrentOf(context) ?? true;
  context.read<MapAvailabilityCubit>().routeCovered(!isCurrent);
}
```

```dart
// HP block
TweenAnimationBuilder<double>(
  tween: Tween(begin: result.hpBefore.toDouble(), end: result.hpAfter.toDouble()),
  duration: hpAnimationDuration,
  builder: (context, hp, _) => HpDeltaBar(hp: hp, max: result.maxLifePoints, isLoss: result.hpAfter < result.hpBefore),
);
```

## State of the Art

| Old | Current | Impact |
|---|---|---|
| Phase 5 note: `questEnd.id` = pendingQuestId | BE §4: `data.id` = result id | popup calls `questResult(id)` |
| planned `combatResult` push type | none (BE §4) | D-22 comment removal |
| BE §14 "no results list" | BE 9.2 `unacknowledgedQuestResults` (proposal) | gated plan |

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|
| A1 | BE 9.2 final names equal the proposal (`unacknowledgedQuestResults`, `acknowledgeQuestResult(id): CommonResponse!`, `acknowledgedAt: DateTime`) | C4, F10 | gated plan renames documents/parsers (small) |
| A2 | Lifting the Map gate for results queued ahead of a `death` is acceptable | Architecture | user may prefer death-only; one condition |
| A3 | 10 s cap, 2 s ack wait before release, banner only when the sheet cannot open at once | F2, C6 | copy/timing tweak |
| A4 | Enemy images are not resolvable (relative BE paths, no local assets) | F7 | section shows name only, as `QuestInfoSheet` today |
| A5 | Proposed Italian `QuestType`/outcome copy | F12 | provisional by D-19 |

## Open Questions (RESOLVED)

1. *Where does "Map free" come from?* → `MapAvailabilityCubit` with four writers (F1). Resolved.
2. *Do subscriptions survive `currentCharacter: null`?* → yes while the keyed shell is held; a resubscribe on the dead character answers `NOT_FOUND` (terminal), covered by the query/push. Resolved (BE §3 + code).
3. *Reconnection signal?* → none public; `ConnectionRestoredBus` fed by `SessionSyncCubit` (F11). Resolved.
4. *Which banner API?* → `publish(PushEvent)` (`questEnd|<id>`), toggle read from `NotificationPreferencesCubit`. Resolved.
5. *Does the fragment compile?* → yes on BE `10e5f43` without `acknowledgedAt` (verified); 9.2 parts fail until merge. Resolved.
6. *Shop classifier?* → does not exist; create (C8). Resolved.
7. *Banner for results from the unacknowledged query?* → no (D-12 says subscription); they open on Map entry. Resolved by D-12 wording.
8. *Cold start after death* → accepted gap C9 — needs user confirmation; cannot be verified without the device E2E.
9. *BE 9.2 exact contract* → cannot be verified now (BE branch has only the CONTEXT); the gated plan's first step checks it.

## Environment Availability

| Dependency | Required by | Available | Version |
|---|---|---|---|
| Flutter (fvm) | build/tests | ✓ | 3.35.5 |
| node | schema check | ✓ | v26.12.1 |
| BE `node_modules/graphql` | schema check | ✓ | 16.11.0 |
| BE `origin/develop` | schema source | ✓ | `10e5f43` (9.1 merged, 9.2 not) |
| BE 9.2 merged | gated plan + E2E | ✗ | — (blocks only the gated plan) |
| Android device + local BE | E2E | manual | — |

## Validation Architecture

### Test Framework
| Property | Value |
|---|---|
| Framework | flutter_test (3.35.5) + bloc_test 10 + mocktail 1.0.5 + fake_async 1.3.3 |
| Config | none (`analysis_options.yaml` with flutter_lints) |
| Quick run | `flutter test <path>` (single file < 10 s) |
| Full suite | `flutter test` (baseline 2139 passed, ~60 s) |
| Analyzer | `flutter analyze` (baseline 53 issues / 0 errors; must not grow) |

### Phase Requirements → Test Map
| Req | Behaviour | Type | Command | File |
|---|---|---|---|---|
| COMBAT-01 | subscription → queue; tap → `questResult(id)`; Map-only, death any tab | bloc + widget | `flutter test test/screens/mainScreen/questResultsCubit test/screens/mainScreen/components/quest_result_presenter_test.dart` | ❌ Wave 0 |
| COMBAT-01 | `questEnd` popup registered; landing opens the sheet | widget | `flutter test test/screens/mainScreen/components/notification_intent_landing_test.dart` | ✅ (amend :177) |
| COMBAT-01 | documents parse/named/registered | unit | `flutter test test/graphql/quest_result_documents_test.dart test/tool` | ❌ |
| COMBAT-02 | HP bar/numbers end state, loss/gain ink | widget | `flutter test test/shared/components/popup/quest_result_sheet_test.dart` | ❌ |
| COMBAT-03 | consumables/spells (null spell → «Magia sconosciuta») | unit + widget | `flutter test test/models/quest_result` | ❌ |
| COMBAT-04 | 28 injury labels + BE parity | unit | `flutter test test/models/enums/injury_type_test.dart` | ❌ |
| COMBAT-05 | rewards/XP/level/title/spell learned/saved count, sections hidden | widget + unit | sheet test + `test/models/enums/quest_type_test.dart` | ❌ |
| COMBAT-06 | scrim, back, drag ignored; button returns true; external pop → requeue | widget | presenter test | ❌ |
| COMBAT-07 | FIFO `resolvedAt`, dedup, retries on availability change | bloc | `flutter test test/screens/mainScreen/tabs/map/mapAvailabilityCubit test/screens/mainScreen/questResultsCubit` | ❌ |
| COMBAT-08 | `AwaitingAid` parse, fragment field, pawn label, drag gate, disabled pages, `AWAITING_AID`/`SHOP_NOT_IN_CITY` | unit + widget | `flutter test test/models/character test/screens/mainScreen/components/satchel_availability_test.dart test/screens/mainScreen/tabs/map/character_marker_layer_test.dart test/repository/travel_failure_test.dart test/repository/quest_acceptance_failure_test.dart test/repository/transaction_failure_test.dart` | partial |
| COMBAT-08 (death) | hold A/B orders, cap 10 s (fake_async), deletion releases, pop moved | bloc + widget | `flutter test test/screens/auth/characterExitHoldCubit test/screens/auth/session_home_test.dart test/screens/auth/auth_gate_test.dart` | partial |
| COMBAT-09 | cold start/resume/reconnect fetch via ports; ack at close; pendingAck filter; reconnect bus | bloc | `flutter test test/screens/mainScreen/questResultsCubit test/screens/auth/syncCubit` | ❌ |
| COMBAT-10 | aid → combat family | unit + widget | `flutter test test/models/quest/quest_sheet_details_test.dart test/screens/mainScreen/tabs/board/sheet_test.dart` | ✅ (invert) |

### Sampling Rate
- Per task commit: the quick commands of the touched area.
- Per wave: `flutter test` + `flutter analyze`.
- Phase gate: full suite green, analyzer ≤ 53 / 0 errors, schema check 38/38 OK against BE `origin/develop` after the 9.2 merge, no trailer, DIRTY files not reformatted.

### Wave 0 Gaps
- `test/helpers/fixtures/quest_result_fixtures.dart` (one recorded payload per outcome, null enemy/spell, orphan item, with/without `acknowledgedAt`).
- Mocks in `test/helpers/mocks.dart`: `MockQuestResultRepository`; fakes `FakePendingQuestResults`, `RecordingQuestResultAcknowledger`, `FakeConnectionRestoredEvents`.
- `test/screens/auth/authenticated_shell_test.dart` setUp stub for `subscribeToQuestResults`.

### Manual-only verifications (device E2E, after the BE 9.2 merge, BE §13 + FE BACKEND-NOTES §4)
1. Foreground on Map: `job` resolves → sheet at once, no banner, HP/XP animate, «Continua» → ack (not shown again after restart).
2. Other tab → banner «Missione conclusa» → tap → Map + sheet.
3. Background push tap (`sendTestPush(questEnd, <resultId>)`) → sheet; acked id → Map only.
4. Force-stop + notifications off → result produced → cold start shows it.
5. Multiple results (boss) → FIFO with counter; quest overlay / drag / travel sheet delay the sheet.
6. `failure` → label «In attesa di soccorso», drag/Board/Shop disabled; aid on the Board with the combat family.
7. `rescued` / rescuer `success` with «Hai salvato N avventurieri».
8. `death` (BE §12 h): both orders, sheet on any tab, «Riposa in pace» → creation page; settings deletion of a wounded character routes at once.
9. Toggle «fine quest» off → no banner/notification, sheet still on the Map.
10. Started boss with a deleted participant stays torn (BE 9.2).

## Security Domain

| ASVS | Applies | Control |
|---|---|---|
| V2 Authentication | no (unchanged session) | — |
| V4 Access control | yes | BE enforces ownership (`FORBIDDEN` incl. innkeeper); FE never trusts push payload; ids filtered by `validBackendIdentifier` |
| V5 Input validation | yes | tolerant `tryFromJson` boundaries; unknown enums skipped |
| V7 Logging | yes | `debugPrint` codes/runtimeType only, never payloads |
| V8 Data protection | yes | no secrets; never print `.env` |

| Threat | STRIDE | Mitigation |
|---|---|---|
| Forged push id | Spoofing | `questResult(id)` ownership check → domain banner |
| Malformed event | DoS | skip on `FormatException`, stream kept |
| Hold never released | DoS | 10 s cap; deletion releases; external pop requeues |
| Retry storm | DoS | bounded backoff, single-flight refetch, idempotent ack |
| Ack of another user's result | Tampering | BE `FORBIDDEN`; FE acks only ids it displayed |

## Sources

### Primary (HIGH)
- Codebase files cited inline (read 2026-10-27); BE `origin/develop:src/schema.gql` @ `10e5f43`; BE Phase 9 `BACKEND-NOTES.md` §0-§16; BE `09.2-CONTEXT.md`; FE `09-CONTEXT.md`, `BACKEND-NOTES.md`; Phase 3/5/6/7/8 contexts.
- Flutter 3.35.5 SDK: `widgets/routes.dart:1305` (`ModalRoute.isCurrentOf`), `material/bottom_sheet.dart:1250`, `material/dialog.dart:1494/1548`.
- graphql 5.2.1 `websocket_client.dart:215` (`BehaviorSubject` connection state).
- Probe test (deleted): isCurrentOf flips, general dialog dismissal rules, `jumpToPage` → `onPageChanged`.
- `validate_documents.js` runs (34/34 current; Phase 9 documents as listed).

## Metadata

**Confidence:** stack HIGH (no new deps); architecture HIGH for the signals and the modal (probe), MEDIUM for the hold UX in rare orders (device-only); pitfalls HIGH (from code).
**Research date:** 2026-10-27 — valid until the BE 9.2 merge (re-check names) or 30 days.
**Repo state at end:** probe deleted, `git status --short` clean (this file is the only new file).
