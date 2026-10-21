# Phase 6: Quest Accept & Info Sheets - Research

**Researched:** 2026-10-21
**Domain:** Flutter 3.35.5 / Dart 3.9.2 gameplay UI on the existing stack (no new dependency): `flutter_bloc` 9.1.1, `graphql_flutter` 5.2.1, `flutter_svg` 2.2.0, `auto_size_text` 3.0.0, `flutter_map` 8.2.1; GraphQL `acceptQuest` mutation, three quest lanes on `Character.quests`, per-type `QuestInfoSheet` families, custom swipe-left "tear paper" gesture (`GestureDetector` + `CustomClipper<Path>` + `HapticFeedback`), board filtering/torn state, Map-tab quest paper, error banner
**Confidence:** HIGH for the FE code inventory, the BE contract on `origin/develop` (SDL validated with the BE `graphql` 16.11.0 this session) and the tooling baseline (measured). MEDIUM for BE behaviours that can only be proved on a running backend (populate gaps G1/G2 below were read from BE source, not exercised) and for the BE Phase 8 contract (CONTEXT only, not implemented). LOW only where marked `[ASSUMED]`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions


### Acceptance flow, cost and errors (QUEST-02, QUEST-03, QUEST-05, QUEST-06)
- **D-01:** **The swipe is the confirmation.** No confirmation dialog for any type and **no undo window** (the backend has no cancel for quests or travel). The gesture is a custom `GestureDetector` with a drag threshold (ROADMAP decision, **not** `Dismissible`), swipe-left on the `QuestInfoSheet` **above the board only** — not on the board list and not on the sheet shown inside the Map (`quest_info_overlay.dart` stays read-only).
- **D-02:** **Cost line only for `story`/`worldMission`:** `Punti canale: {twitchPoints} / {requiredPoints}` replaces the hard-coded `3000` in `quest_info_sheet.dart`, highlighted (red/ink emphasis) when the balance is insufficient; `twitchPoints` is the live value from `AuthAuthenticated.user` (`userUpdated`, Phase 3 D-18). **No coins cost for any type** (BE handoff §7): `recommendedLoot` is a display-only hint (D-10). The first plan amends QUEST-05 in `REQUIREMENTS.md`.
- **D-03:** **Optimistic tear, navigation on success:** the tear animation starts with the gesture and the `AcceptQuest` mutation fires when the threshold is crossed; the app switches to the Map tab **only when the backend answers `successful: true`**. On rejection the two halves recompose on the sheet (spring back) and the error surfaces (D-04). The populated lane and the new balance arrive through `characterUpdated`/`userUpdated` — the mutation's `CommonResponse` is never used to build state.
- **D-04:** **Errors in the in-app banner of Phase 5** (`InAppNotificationsCubit.publish` → `KGNotification(title, description)`, parchment strip, auto-dismiss ≈ 5 s, Phase 5 D-17/D-18): Italian domain copy chosen by **`extensions.code`** (BE handoff §2 table: `QUEST_SLOT_BUSY`, `QUEST_FULL`, `QUEST_ALREADY_TAKEN`, `QUEST_TITLE_MISMATCH`, `QUEST_NOT_IN_CITY`, `QUEST_NOT_ACCEPTABLE`, `INSUFFICIENT_POINTS`, `NOT_FOUND`, `FORBIDDEN`; BE Phase 8 adds `TRAVEL_IN_PROGRESS`), never by message text; network/unknown → a generic domain line. The Repository maps `OperationException` into a domain error with the code (`docs/rules/graphql.md`); the UI never sees exceptions. QUEST-06 names the "shop-flow pattern": the researcher documents what the shop does today; the banner is the chosen surface for this phase.
- **D-05:** Mutation document `AcceptQuest($request: AcceptQuestRequest!) { acceptQuest(request: $request) { response successful } }` (naming per `docs/rules/naming.md`) in `lib/graphql/mutations/` (file at planner's choice), Repository → Cubit path (`docs/rules/architecture.md`); `request.id` = `currentCharacter.id`, `questId` = the board quest id.

### Tear gesture and the Map (QUEST-02, QUEST-03)
- **D-06:** **Tear = two halves that separate:** the existing parchment SVG (`CloudinaryAssets.emptySheet`) is clipped in two along a jagged edge and the halves move apart/rotate following the finger; **no new asset**, all in Flutter. Haptic feedback via `HapticFeedback` (flutter/services): one at the threshold and one at the tear (exact pattern at Claude's discretion). Drag threshold and direction at Claude's discretion (provisional, user-reviewed).
- **D-07:** **Persistent quest paper on the Map:** after success the app switches to the Map tab and the **intact board asset** of the accepted quest (same per-type image family as `sheet.dart`, **not** a torn one) stays visible for the **standard lane** (placement at Claude's discretion, provisional) for as long as the quest is active; **tapping it opens the same `QuestInfoSheet` presentation read-only with the state line added** (D-15). Centering the map on the quest marker is Claude's discretion (the character will start travelling there automatically — BE Phase 8 D-02 — rendered by FE Phase 7).
- **D-08:** **`story` and `worldMission` never show a paper on the Map.** After acceptance they stay on the board **torn for their owner** (existing `storyTornSheet` assets; QUEST-04 amended: torn, not hidden) and open read-only; no other "waiting for the GM" indicator in this phase.

### Info sheet layouts (QUEST-01)
- **D-09:** **Three layout families**, variants only where the content differs: **combat** (`hunt`, `enemy`, `boss`, `dungeon`): enemy image + name (+ grade when the model has it), required time, party for `boss`; **narrative** (`story`, `worldMission`): the text of the linked lore (`infos.relatedLore`) **readable inside the sheet, scrollable**, before cost (D-02) and party (`worldMission`); **service** (`heal`, `aid`, `job`, `study`): required time, rewards, recommended loot. `crime`/`guard` out of scope. The rewards block stays as today.
- **D-10:** **Eligibility/state indicators on the sheet** (all four): **required title** (`requirements.minTitle`, highlighted when the character is not eligible — exact title for `story`, minimum for the others, `TitleType` order rookie < adventurer < paladin < mage < hero < legend); **slots per rank** (`requirements.party` `{ title, count }` with the registered count per rank from `registeredAdventurers { character title }`, D-14) for `worldMission`/`boss`/`enemy`/`aid`; **already done** for non-repeatable types (`story`, `worldMission`, `enemy`, `boss`, `aid`) present in `completedQuests` or with the character already registered; **recommended loot** (`requirements.recommendedLoot`) where present.

### Board, lanes and the torn state (QUEST-04)
- **D-11:** **Board access and content.** The board is reachable **only when the character stands on a city marker** (`status.location` equals a `City.markerLocation`; from a quest POI the satchel item is disabled and its cell darkened — the same treatment the travel case gets in FE Phase 7 with `activeTravel`). Content: all quests of that city (`infos.markerLocation` ∈ the city's `pointsOfInterest`) **plus `worldMission` from every city and only the `story` whose `minTitle` equals the character's title** (the other four chapters are not listed; BE Phase 8 D-26 lifts the city check for story/worldMission — until it ships the backend still answers `QUEST_NOT_IN_CITY`). Non-repeatable quests already in `completedQuests` are hidden. An accepted `story`/`worldMission` stays listed **torn for its owner** (D-08, D-12). Everything else stays visible: when the client can tell the quest is not acceptable (title, lane busy, full for the rank, torn) the sheet shows why and the swipe is blocked (the paper resists and springs back); **the backend remains the judge** (banner on rejection). A standard quest the player accepted is never met on the board before its outcome: the character leaves the city automatically (BE Phase 8 D-02) and comes back only when the quest is over.
- **D-12:** **"Torn for everyone" on the board, built on what `sheet.dart` already does:** the current asset mapping stays (boss/enemy → hunt sheets, dungeon/aid → quest sheets, hunt/job/guard → job, heal/study → announcement, story → story, worldMission → story; torn variants `huntTornSheet1/2`, `questSheetTorn1/2`, `storyTornSheet1/2`) and the existing `isFull` rule is **extended to rank**: a registered quest (`worldMission`, `boss`, `enemy`, `aid`) is full when the registered count reaches the **sum of the `count`s** of `requirements.requiredAdventurers` — now a **list of slots `{ title?, count }`** (BE Phase 8 D-28: `title` null = any rank, `party` removed) — **or** when the slots of the player's own rank (slots with that `title` plus the `null` ones) are exhausted, counting `registeredAdventurers { character title }`. The owner's own active `story`/`worldMission` is torn too (D-08). A torn quest cannot be swiped. `hunt`, `dungeon`, `job`, `heal`, `study` are never registered, so never torn. Needs BE Phase 8 (D-27/D-28): see D-16.
- **D-13:** **The travel case of the disabled board** (`activeTravel` present) is **deferred to FE Phase 7**; this phase implements the disabled state for "not on a city marker" (D-11) with the visual the travel case will reuse (satchel item disabled, darker cell).
- **D-14:** **Fragment and documents:** `CharacterFragment.questsFields` gains `pendingQuest`, `activeStoryQuest`, `activeWorldMissionQuest` each selecting `{ id startDate waitingTime pointsSpent quest { id } }` (fragment-only change, Phase 3 D-05; `completedQuests { id }` unchanged; `startDate` is parsed nullable already and **is null while travelling**, BE Phase 8 D-15). The quests query adds what the sheet/board need: `requirements { minTitle requiredPoints requiredAdventurers { title count } recommendedLoot { … } }`, `registeredAdventurers { character title }`, `infos { relatedLore { … } enemy { … } }` (no `party`: BE Phase 8 removes it). `Quest.fromJson` is fixed for `registeredAdventurers` (today it parses a `List<Character>` that never matched the wire) and `QuestRequirements.requiredAdventurers` becomes a list of slots (`title` nullable, `count`), with `isFull` in `sheet.dart` rewritten on top of it. The "on a city marker" check of D-11 comes from the cities query (`city_queries.dart`, `markerLocation { id }`) or the POI `type` (planner's choice).

### State label on the torn paper (QUEST-07 amended)
- **D-15:** **No countdown is shown.** The quest paper of the standard lane (D-07) carries a **server-driven state label**, shown in the opened sheet (and, at Claude's discretion, compactly on the paper itself): `startDate == null` → **"In viaggio"** (the character is travelling to the marker, BE Phase 8 D-15; the travel countdown arrives with FE Phase 7); `startDate` set → a **per-type label** — `enemy`/`boss` "In combattimento…", `hunt` "Cacciando…", `dungeon` "Esplorando…", `job` "Lavorando…", `heal` "Guarendo…", `aid` "Aiutando…", `study` "Studiando…" (copy at Claude's discretion, provisional) — kept until the outcome (Phase 9) empties the lane. QUEST-07 is amended accordingly by the first plan; **no `serverTime` query and no clock offset in this phase** (FE Phase 7).

### Contract, lockstep, tests, tooling, branch
- **D-16:** **Two backend sources.** (a) BE Phase 7 is **merged** on BE `develop` (PR #10, 2026-10-21): `acceptQuest`, the three lanes with `quest { id }`, `pointsSpent`, `party`, `serverTime` — usable now. (b) BE Phase 8 (`feat/08-travel-lifecycle-travel-01`, context captured 2026-10-21) adds: `PendingQuest.startDate` nullable, `registeredAdventurers` as `{ character, title }` objects replacing the id list, `requiredAdventurers` as a list of rank slots replacing the `Int` and `party`, registration of `enemy`/`aid` with capacity (`QUEST_FULL`; a registered quest without slots is `QUEST_NOT_ACCEPTABLE`), `story`/`worldMission` acceptable from any city, automatic travel to the marker on acceptance, `TRAVEL_IN_PROGRESS`, registrations released when the owner deletes the character. The FE develops against the proposed contract with fakes/recorded `QueryResult`s (pattern of Phases 3/4/5); the plan that selects `registeredAdventurers { character title }` runs **after** the BE Phase 8 PR is merged on `develop` (or is the last plan), and the final plan verifies every document with `tool/schema_check` against `Klimmeck-Guide-BE/src/schema.gql` at `origin/develop` and runs the manual E2E (board, families, tear, torn-for-others, lanes, errors) with the UAT data of the BE handoff §8.
- **D-17:** **TDD red → green → refactor** (`docs/rules/testing.md`): unit tests, Flutter-free where possible, for the acceptability classifier (city, lane, title, repeatable, torn/full per rank), the state-label mapping, the cost line, the error-code → copy mapping and the gesture threshold logic; widget tests for the three families, the tear and the blocked swipe; the final manual E2E on device against BE `develop`.
- **D-18:** Tooling discipline unchanged: never `dart format` on directories (Phase 2 D-25); architecture/state-management/GraphQL rules in `docs/rules/`. Branch **`feat/06-quest-accept-info-sheets`** from `develop`, PR to `develop`; no lockstep wait for BE Phase 7 (merged); the BE Phase 8-dependent selections follow D-16.
- **D-19:** **No UI phase and no UI-SPEC** (user decision 2026-10-21, overriding the ROADMAP "UI hint: yes"): the sheet families, the cost line, the tear geometry and haptics, the Map paper and the banner copy are built directly from this context at Claude's discretion. **Everything visual is provisional and will be reworked by the user**: keep layouts simple, token-based (`kg_theme.dart`) and easy to restyle; do not polish, do not add assets.

### Claude's Discretion

- Every visual detail (haptic pattern, tear geometry and thresholds, spring-back, family layouts, labels placement, copy): provisional, user-reviewed after the phase (D-19).
- Placement and size of the persistent torn paper on the Map, whether the map centers on the quest marker, how the read-only sheet opens from it.
- How the sheet blocks the swipe and phrases the reason when the client can tell.
- Repository/Cubit shape for acceptance (e.g. a dedicated `QuestAcceptanceCubit` vs. extending `QuestCubit`), where the quest list is cached, file names for the mutation document.
- Behaviour of the torn-for-others rule before BE Phase 8 is merged (ids-only `registeredAdventurers`): count-only fallback or hide the rank detail.
- Banner copy per code (Italian, domain language), generic copy for network/unknown errors.


### Deferred Ideas (OUT OF SCOPE)


- **Board disabled during travel** (the `activeTravel` case of D-11/D-13) and the **travel countdown / `serverTime` offset** — FE Phase 7.
- **Quest outcomes (Phase 9, BE and FE):** a successfully completed `boss`/`enemy` quest disappears from the board for everyone; a failed `enemy`/`hunt`/`boss`/`dungeon` quest becomes available again (registration released, intact asset back) and an **`aid` quest is created automatically**; if the `aid` taker fails, the character who failed the first quest **dies** (archived) and the second failure triggers a new `aid` quest, and so on; `aid` never returns after a failure. The state label of D-15 ends with the outcome.
- **"Waiting for the GM" indicator for `story`/`worldMission`** (journal or elsewhere): none in this phase.
- **Swipe-accept from the Map overlay:** excluded (D-01).
- **Undo after the swipe:** impossible by backend design (no cancel).
- **`crime`/`guard` layouts:** out of v1.0.
- **Quest countdown (`startDate + waitingTime`) on screen:** dropped (D-15); may return if Phase 9 needs it.

</user_constraints>

<phase_requirements>
## Phase Requirements

QUEST-03, QUEST-05 and QUEST-07 are **amended by CONTEXT** (the first plan rewrites them in `REQUIREMENTS.md`); QUEST-04 and QUEST-06 also change meaning (see "Conflicts with CONTEXT"). The traceability row `QUEST-01 through QUEST-07 | TBD | Pending` must also become `Phase 6`.

| ID | Description (as amended) | Research Support |
|----|--------------------------|------------------|
| QUEST-01 | `QuestInfoSheet` per-type layout, three families (combat / narrative / service) plus eligibility indicators (D-09, D-10) | "Code inventory" (what the sheet renders today and what the query lacks), Pattern 6 (view-model), **G1** (BE does not populate `enemy`/`relatedLore`), Pitfall 2 |
| QUEST-02 | Swipe-left tear gesture on the board sheet only, custom `GestureDetector` with threshold, haptics (D-01, D-06) | Pattern 4 (gesture + tear geometry), "Gesture research", Pitfalls 8-10, validation rows (pure threshold logic, widget drag test, `HapticFeedback` channel recording) |
| QUEST-03 | Swipe is the confirmation; optimistic tear; navigate to Map **only on `successful: true`**; the accepted quest's intact paper stays on the Map (D-03, D-07) | Pattern 1-3 (mutation, repository, cubit), Pattern 5 (navigation callback), Pattern 8 (Map paper), "Map tab and navigation" |
| QUEST-04 | Three lanes; story/worldMission stay on the board **torn for their owner**; board only from a city marker; torn-for-everyone per rank (D-08, D-11, D-12, D-14) | Pattern 6-7 (classifier, board policy), Pattern 9 (satchel disabled), "Location source", **G2**, Pitfalls 4-7 |
| QUEST-05 | No coin cost for any type; only story/worldMission cost `requiredPoints` channel points; cost line `Punti canale: saldo / costo` (D-02) | Pattern 6 (cost line is a pure function over `AuthAuthenticated.user.twitchPoints`), BE handoff §3/§7 |
| QUEST-06 | Acceptance failure rolls the optimistic tear back and surfaces a domain error chosen by `extensions.code` in the Phase 5 banner (D-04) | Pattern 2 (failure mapping), Pattern 3 (cubit), Pattern 10 (banner), "Shop flow: what it does today", **C1** |
| QUEST-07 | No countdown; the standard-lane paper carries a server-driven state label ("In viaggio" while `startDate == null`, per-type label afterwards) (D-15) | Pattern 8 (label mapping is a pure function), Pitfall 11 (`startDate` nullable) |
</phase_requirements>

## Project Constraints (from CLAUDE.md and docs/rules)

Actionable directives the plans must satisfy (same authority as locked decisions):

- **No UI chrome on gameplay screens** (board, map, quest sheets): no `AppBar`, `SnackBar`, `MaterialBanner`, no loaders. The error surface is the Phase 5 parchment strip (D-04). [CITED: CLAUDE.md "Regole invalicabili" 1; docs/rules/ui-ux.md]
- **No blocking loading in an active session**: the board must keep its last data while refreshing; a re-fetch must never blank the list. [CITED: CLAUDE.md rule 2; Phase 3 D-14]
- **Backend is the source of truth**: client eligibility is *advisory* (blocks the swipe, explains why) but the BE judges; the FE never computes debit, balance or lane contents. [CITED: CLAUDE.md rule 4; CONTEXT D-03/D-11]
- **TDD red -> green -> refactor**; every Cubit has `bloc_test`; new models have `fromJson`/`toJson`/`Equatable` tests; critical gameplay widgets (quest accept) need an interaction test written first. [CITED: docs/rules/testing.md]
- **Layering UI -> Cubit -> Repository -> Service**; no `OperationException` reaches the UI; a Cubit never calls another Cubit; side effects (navigation, banner publish) happen in `BlocListener`, never in `BlocBuilder`. [CITED: docs/rules/architecture.md, graphql.md, state-management.md]
- **Documents live in `lib/graphql/`**, one named operation each (`AcceptQuest`), file `<domain>_mutations.dart`; no GraphQL string in a widget/Cubit; `AcceptQuest` uses no cache (`fetchPolicy: noCache` is what `performMutation` already does). [CITED: docs/rules/graphql.md, naming.md]
- **Theme tokens only** (`kg_theme.dart`: `parchment`, `darkWood`, `darkBronze`, `bloodRed`, `spacingXs..Xl`); SVG of domain through `CachedSvg`; Cloudinary URLs only through `CloudinaryAssets`. [CITED: docs/rules/ui-ux.md, assets.md]
- **Tap targets >= 44 px, semantic labels** on interactive elements (a swipe-only action needs a `Semantics` custom action or label). [CITED: docs/rules/ui-ux.md]
- **Naming**: files `snake_case.dart`, feature dirs `lowerCamelCase` (`questAcceptanceCubit/`), states with domain names (`QuestAccepting`, `QuestAccepted`, `QuestAcceptanceFailed`), booleans `isX/canX`, no `manager/helper/utils` class names. [CITED: docs/rules/naming.md]
- **Formatting**: never `dart format` on a directory; the baseline is not format-clean (Phase 11 D-38, Phase 2 D-25). Measured this session: **do not run `dart format` on** `board.dart`, `world_map.dart`, `quest_info_overlay.dart`, `character_fragment.dart`, `quest_queries.dart`, `city_queries.dart`, `quest_type.dart` (each has pre-existing unrelated hunks); new files and the files measured clean (`sheet.dart`, `quest_info_sheet.dart`, `quest_cubit.dart`, `models/quest/*`, `pending_quest.dart`, `character_quests.dart`, `main_screen.dart`, `components/menu_*.dart`, `satchel_menu.dart`, `graphql.dart`, `in_app_notifications_cubit.dart`, `authenticated_shell.dart`) may be checked with `dart format --output=none --set-exit-if-changed <file>`.
- **Workflow**: branch `feat/06-quest-accept-info-sheets` -> PR to `develop`; Conventional Commits in English; planning artefacts committed with the code. [CITED: docs/rules/workflow.md]
- **No UI phase / no UI-SPEC** (CONTEXT D-19): every visual is provisional; keep layouts simple, token-based, no new assets, no polish.

## Summary

The BE contract for acceptance is stable and already on `origin/develop` (Phase 7): `acceptQuest(request: { id: characterId, questId }) -> CommonResponse`, three lanes on `Character.quests`, rejection codes in `extensions.code`. Everything the FE needs in code is a **vertical slice that mirrors Phase 4's `deleteCharacter` flow** (document -> `KlimmeckGraphQl` method with `_dataOrThrow` -> failure mapping by `graphQlErrorCode` -> Repository `_guard` -> Cubit), plus a **pure, Flutter-free "quest availability" layer** (lane of a type, title order, torn/full per rank, cost line, state label) that carries most of the decisions D-10..D-15 and is where the unit tests belong. The gesture is plain Flutter: a horizontal-drag `GestureDetector` inside the already vertical `SingleChildScrollView` of the board sheet does not conflict with scrolling (the arena resolves by axis), the tear is two `ClipPath` layers over the same sheet widget with a deterministic jagged `CustomClipper<Path>`, driven by one `AnimationController`, with `HapticFeedback` (no permission, no package).

The research found **four items that CONTEXT assumes but the code or the backend does not support**, which the planner must resolve before sizing the plans (details in "Conflicts with CONTEXT and backend gaps"): **G1** the BE `quests` query populates only `infos.markerLocation`, so selecting `infos.enemy`, `infos.relatedLore`, `requirements.recommendedLoot[].item` (D-09/D-10/D-14) will fail on the wire for any quest that has them until the BE populates them; **G2** `cities` does not populate `pointsOfInterest` (only `city(id)` does), so "quests of this city" needs a `city(id)` fetch (or a BE change); **C1** `InAppNotificationsCubit.publish` accepts a `PushEvent` (category + intent + dedup + tap routing), **not** a `KGNotification`, so an error banner needs a small cubit extension; **C3** the "shop-flow error pattern" of QUEST-06 is a shopkeeper speech bubble with one hard-coded sentence and no error code, not something to reuse. Additionally the quest list has **no live source** (no `questsUpdated` subscription), so the "torn for everyone" state is only as fresh as the last `quests` query: the Board must silently refresh when it opens and after a rejection.

**Primary recommendation:** build the pure availability layer + the acceptance vertical slice first (both fully testable against BE `develop` today), keep the tear gesture and the sheet families as independent view plans, make the board integration depend on them, and make the single plan that flips the `quests` document to the BE Phase 8 shapes (`registeredAdventurers { character title }`, `requiredAdventurers { title count }`) the **last** one; resolve G1 with the BE owner now, because the narrative and combat families cannot show lore text or the enemy without it.

## Conflicts with CONTEXT and backend gaps

These are findings that contradict an assumption in CONTEXT or in the BE handoff. Locked decisions are not changed here; each item states the smallest way to honour the decision.

| # | Finding | Evidence | Impact | Recommended resolution |
|---|---------|----------|--------|------------------------|
| **G1** | BE `quests` / `quest(id)` populate **only** `infos.markerLocation`. `infos.enemy` (ObjectId ref), `infos.relatedLore` (`[ObjectId]` ref), `requirements.recommendedLoot[].item`, `prizes.prizeItem.item`, `prizes.randomLoot.item` (`refPath`) are returned as raw ids. | `Klimmeck-Guide-BE/src/quests/quests.service.ts:10-17` (`find().populate('infos.markerLocation')`); no `autopopulate`, no `@ResolveField` anywhere in `src` (grep). `relatedLore` is `[Lore!]!` non-null, so a resolver error on its items propagates up to `Quest!`/`[Quest!]!` and can null the whole `quests` list. [VERIFIED: BE source read this session; wire behaviour not exercised - MEDIUM] | D-09 narrative family (lore text) and combat family (enemy image/name), D-10 recommended loot cannot work as specified. The existing `quests` document already selects `prizes.*.item`: if the 4 catalogue quests have prize items it is already failing; if not, it has just never been exercised. | Ask the BE to populate `infos.enemy`, `infos.relatedLore`, `requirements.recommendedLoot.item` (and `prizes.*.item`) in `QuestsService.findAll/findOne`; fold into **BE Phase 8** (still only CONTEXT, same lockstep as D-16) or a one-line BE fix. Add a Wave 0 **probe** task: run the final `quests` document with the UAT data against a running BE and record the result. FE fallback if the BE slips: the families render without lore text / enemy (fields are nullable in the models) and the document selects them only in the BE-gated plan. |
| **G2** | `cities` (list) populates `relatedLore` + `markerLocation` only; `pointsOfInterest` is populated **only** by `city(id)`. `City.pointsOfInterest` is `[PointOfInterest!]` and the FE `City` model and `cities` document do not have it. | `Klimmeck-Guide-BE/src/cities/cities.service.ts:10-34`; SDL `type City`; FE `lib/models/city.dart`, `lib/graphql/queries/city_queries.dart`. | D-11 "quests whose `infos.markerLocation` is among the city's `pointsOfInterest`" cannot be answered from the `cities` the app already loads. | Default: add `GetCity($id: String!) { city(id: $id) { id pointsOfInterest { ...LocationFragment.fields } } }` and fetch it for the current city when the Board opens (one small request, works on BE `develop` today). Alternative if the BE is touched anyway for G1: populate `pointsOfInterest` in `findAll` and add `pointsOfInterest { id }` to the `cities` document (no new query/cubit). Do **not** select `pointsOfInterest { quest }` (POI `quest: ID` is populated into a document by `findOne`; an `ID` cannot serialise a document). |
| **C1** | CONTEXT D-04 says "`InAppNotificationsCubit.publish` -> `KGNotification(title, description)`". The real API is `publish(PushEvent)`; the queue, the dedup key (`category.wireType|id or minute`), the state (`current: PushEvent?`), the overlay (`_bannerFor(PushEvent)`) and the tap (`open(event) -> router.handle(event.intent)`: personal -> jump to Map, `streamerLive` -> Twitch) are all push-shaped. Re-using `NotificationCategory.questEnd` for an error would deduplicate by minute and tap-route to the Map. | `lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart`, `lib/models/push_event.dart`, `authenticated_shell.dart:213-237`. | Add a **second, local entry point** `publishNotice(KGNotification notice, {required String dedupKey})` to the cubit: same queue, same 5 s timer, tap = dismiss only (no router), dedup window = the display duration. Smallest diff that keeps the 27 `state.current` assertions of the existing cubit test green: keep `current: PushEvent?` and add `notice: KGNotification?` to the state (mutually exclusive with `current`); `_bannerFor` renders whichever is set. Alternative (cleaner, rewrites those tests): an `InAppBanner` value type for both. Planner picks; the first is recommended for risk. |
| **C2** | D-10 lists "already done" as an indicator for non-repeatable types in `completedQuests`, while D-11 says non-repeatable quests already in `completedQuests` are **hidden** from the board. | CONTEXT D-10, D-11. | The indicator is unreachable on the board and only reachable on the Map read-only sheet if a lane quest is also in `completedQuests` (it is not: lanes empty on completion). | Implement the classifier branch (`alreadyDone`) because the BE returns `QUEST_ALREADY_TAKEN` and the classifier must mirror BE order; do **not** build a separate visual for it beyond the generic "why it is blocked" line. |
| **C3** | QUEST-06 and ROADMAP criterion 5 say to reuse "the existing shop-flow error pattern". The shop's pattern is `TransactionCubit` catching everything into `TransactionError()` (no code, no message), reset to `TransactionInitial` by `Future.delayed(4s)`, rendered by `shop.dart` as a `TransactionMessageBubble` (comic-balloon SVG) with the fixed sentence "Hmmm... Qualcosa non mi torna. Riproviamo?". It is shopkeeper dialogue, not code-aware, and `doTransaction` throws `Exception('Server error: <message>')`. | `lib/screens/mainScreen/tabs/shop/transactionCubit/*`, `shop.dart:255-276`, `transaction_message_bubble.dart`, `graphql.dart:doTransaction`. | Reusing it would violate D-04 (codes, not text) and Phase 4 D-18. | Amend QUEST-06 in the first plan: "surfaces the error in the Phase 5 in-app banner (D-04); the shop's bubble is shop-specific". Only the **`canAfford` gating** idea (red X, no action when insufficient) is conceptually shared with D-02. |
| **C4** | D-04 "publishes the banner from a Cubit" vs `state-management.md`: "a Cubit never calls another Cubit; orchestration in the UI via `BlocListener`". | docs/rules/state-management.md "Anti-pattern". | A `QuestAcceptanceCubit` must not hold an `InAppNotificationsCubit`. | The acceptance Cubit emits `QuestAcceptanceFailed(failure)`; a `BlocListener` in the Board maps the failure to copy with a pure function and calls `context.read<InAppNotificationsCubit>().publishNotice(...)`. Same pattern Phase 5 used (`BlocListener` + intent cubit). |
| **C5** | Quest list freshness: there is no quests subscription (BE `Subscription` has only `characterUpdated` and `userUpdated`), `QuestCubit.loadQuest()` runs once in `MainScreen.initState`, and `loadQuest()` emits `QuestLoading` (the Board renders `SizedBox.shrink()` unless `QuestLoaded`). | SDL `type Subscription`; `main_screen.dart:58`; `quest_cubit.dart`; `board.dart:99-117`. | "Torn for everyone" (D-12) is stale until the next fetch; calling `loadQuest()` on every visit would blank the board (violates the no-blocking-loading rule). | Add `QuestCubit.refreshQuests()` = silent re-fetch that **keeps the previous `QuestLoaded`** on failure and never emits `QuestLoading` (pattern of `CharacterCubit.refreshCharacter`). Trigger: `Board.initState` (verified: `PageView` has `cacheExtent: 0`, `page_view.dart:975`, so off-screen pages are disposed and a revisit re-runs `initState`), after a `QUEST_FULL`/`QUEST_ALREADY_TAKEN`/`NOT_FOUND` rejection, and on the existing foreground event if the Board is mounted. |
| **C6** | `QuestType` on the wire is `String!`, not an enum, and `TitleType`/`QuestType` parsing in the FE uses `values.byName` (throws `ArgumentError`). Catalogue quests are hand-edited in the DB by the user (CONTEXT "quest catalogue on the DB is updated by the user"). | SDL `QuestInfos.type: String!`, `QuestRequirements.minTitle: String!`; `quest_infos.dart`, `quest_requirements.dart`. | One typo in one hand-edited quest throws inside `Quest.fromJson`, `getQuests` fails as a whole, and the board is empty with no retry. | Parse each quest defensively: `Quest.tryFromJson` returns `null` (with a `debugPrint` of the id only) and `getQuests` keeps the valid ones (pattern of `RaceTraits.tryFromJson`). Test it. |

## Standard Stack

No new runtime dependency is needed or proposed. `HapticFeedback`, `CustomClipper`, `SpringSimulation` are in the Flutter SDK. [VERIFIED: pubspec.yaml / pubspec.lock]

### Core (already present)
| Library | Version (lock) | Purpose | Why |
|---------|----------------|---------|-----|
| `flutter_bloc` / `bloc` | 9.1.1 / 9.0.0 | Cubit + `BlocListener`/`BlocSelector` | project standard |
| `equatable` | 2.0.7 | states and models | project standard |
| `graphql_flutter` | 5.2.1 | mutation transport (`performMutation`, `noCache`) | project standard |
| `flutter_svg` via `CachedSvg` | 2.2.0 | the parchment sheet and the board papers | `docs/rules/assets.md` |
| `auto_size_text` | 3.0.0 | titles/labels in the sheet | already used |
| `flutter_map` | 8.2.1 | Map tab; the persistent paper is a sibling widget, not a marker | already used |

### Supporting (tests, already present)
| Library | Version | Use |
|---------|---------|-----|
| `flutter_test` (SDK) | 3.35.5 | widget tests, `TestDefaultBinaryMessenger` for the `SystemChannels.platform` haptic recording |
| `bloc_test` | 10.0.0 | acceptance Cubit sequences |
| `mocktail` | 1.0.5 | `MockKlimmeckGraphQl`, `MockAuthCubit`, `MockCharacterCubit`, `MockQuestCubit` (exist in `test/helpers/mocks.dart`), new `MockQuestAcceptanceRepository` |
| `fake_async` | 1.3.3 | banner timer, spring-back timing |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| two clipped copies of the sheet widget | `RepaintBoundary.toImage()` snapshot then two painted halves | snapshot is async, loses crispness at 1.5x screen height and is harder to test; two `ClipPath` over the same widget tree is synchronous, testable and restyle-friendly (D-19). Cost: the sheet tree is built twice **only while `progress > 0`**. |
| `Dismissible` | custom `GestureDetector` | locked by ROADMAP/D-01 (Dismissible removes the child and cannot render a custom two-half tear) |
| `flutter_animate` / any tear package | plain `AnimationController` | "do not propose new dependencies unless unavoidable" (task); nothing here is unavoidable |
| dedicated `BoardCubit` for city POIs | extend `QuestCubit` (`QuestLoaded.cityPointIds`) or a tiny `CityPointsCubit` | planner's choice; `QuestCubit` is global and also feeds `QuestMarkersLayer`, so keep new fields additive |

**Installation:** none. **Version verification:** versions read from `pubspec.lock` this session; Flutter 3.35.5 / Dart 3.9.2 (`flutter --version`).

## Current code inventory (research question 1)

### Quest models and parse code
| File | Field -> wire -> parse | Notes / what breaks |
|------|------------------------|---------------------|
| `lib/models/quest/quest.dart` | `id: String` (`json["id"]`), `infos: QuestInfos?`, `requirements: QuestRequirements?`, `prizes: QuestPrizes?`, `registeredAdventurers: List<Character>?` parsed with `Character.fromJson(x)` for each element, default `[]` when absent; `toJson` emits ids | **Today's wire is `[String!]!` (ids)**: `Character.fromJson("abc")` would throw (`json["id"]` on a `String`). It never ran because `registeredAdventurers` is not selected anywhere. With BE Phase 8 the wire is `[{ character: ID!, title: String! }]`: also not a `Character`. -> change type to `List<RegisteredAdventurer>` (`characterId`, `title: TitleType?`). `copyWith` cannot clear fields (`??`). |
| `lib/models/quest/quest_infos.dart` | `title: String?`, `enemy: Enemy?` (`Enemy.fromJson`), `type: QuestType?` via `QuestType.values.byName` (**throws on unknown**), `markerLocation: PointOfInterest?`, `relatedLore: List<Lore>?`, `timeToComplete: int?` (`(num?)?.toInt()`, **milliseconds**, shown via `getStringToShowFromDuration`) | `relatedLore`/`enemy` not selected today (G1). `PointOfInterest.fromJson` needs `json["location"][0]` -> always select `location` with `id` (`LocationFragment.fields`). |
| `lib/models/quest/quest_requirements.dart` | `requiredPoints: int?`, `requiredAdventurers: int?` (`(num?)?.toInt()`), `recommendedLoot: List<AssetQuantity>?`, `minTitle: TitleType?` via `byName` (**throws on unknown**) | **Breaks with BE Phase 8**: `requiredAdventurers` becomes `[{ title?, count }]`; `(List as num?)` throws `TypeError`. -> `List<AdventurerSlot>` (`title: TitleType?`, `count: int`). `party` does not exist in the FE model (good: BE Phase 8 removes it). Not selected in the `quests` document today. |
| `lib/models/quest/quest_prizes.dart` | `prizeCoins`, `xpPrize`, `prizeItem: AssetItem?`, `randomLoot: List<AssetQuantity>?` | selected today; `toJson` puts raw `randomLoot` objects (not `toJson`) - irrelevant. |
| `lib/models/pending_quest.dart` | `id`, `startDate: DateTime?` (**already nullable**, `DateTime.parse` guarded by `!= null`), `waitingTime: int?` (`(num).toInt()`, wire `Float!` ms), `quest: Quest?` (`Quest.fromJson(json["quest"])`, so `quest { id }` yields a stub `Quest` with only `id`) | no `pointsSpent` field (D-14 selects it: add `int? pointsSpent` or leave unparsed - unused by Phase 6). `copyWith` cannot set `startDate` back to `null`. `toJson` emits `quest: id` (not symmetric with `fromJson`). |
| `lib/models/character/character_quests.dart` | `completedQuests: List<Quest>?` (stubs with `id`), `pendingQuest: PendingQuest?` | **add `activeStoryQuest`, `activeWorldMissionQuest`** (fromJson/toJson/copyWith/props). `copyWith` cannot set a lane to `null`. |
| `lib/models/enums/quest_type.dart` | 12 values = BE `QuestType` exactly (hunt, aid, enemy, worldMission, boss, dungeon, story, study, heal, job, crime, guard); `imagePath` = pawn SVG (empty for study/heal/job/crime/guard) | file is not `dart format` clean. |
| `lib/models/enums/title_type.dart` | `enum TitleType { rookie, adventurer, paladin, mage, hero, legend }` = BE order (`TITLE_RANK`); `index` is the rank | use `index` comparison (>= for non-story, == for story); no `byName` throw on tolerant paths. |
| `lib/models/enemy.dart` | `name`, `imagePath` (used as **`Image.asset`** path by the sheet, e.g. a bundled `assets/images/...`), `locations` parsed `json["locations"]?.map(...)` **without `.toList()`** | **Never select `enemy.locations`**: the `Iterable` assigned to `List<PoiType>?` is a runtime `TypeError`. Same latent bug in `PointOfInterest.type` (`json["type"]?.map`): never select POI `type`. |
| `lib/models/lore.dart` | `id`, `type: LoreType?` (byName), `name`, `description`, `relatedLore` (default `[]`), `unlocked` | select only `id name description` for the sheet (avoid `type` byName risk and recursion). |

### Documents
- `QuestQueries.getAllQuests` (`quest_queries.dart`, op name `quests`): selects `id`, `infos { markerLocation{id location} timeToComplete title type }`, `prizes {...}`. **No** `requirements`, `registeredAdventurers`, `infos.enemy`, `infos.relatedLore`. The sheet's enemy block and the `requiredPoints` line are therefore dead code today.
- `CharacterFragment.questsFields` (`character_fragment.dart`): `quests { completedQuests { id } pendingQuest { id } }` (a `static const String`; it must become a getter or stay const with literal text - it has no interpolation). `statusFields` already has `title` and `location { id location }`. `fullFields` feeds both `character(id)` and `characterUpdated`.
- `CharacterMutations` (`character_mutations.dart`): `static const String name = r'''mutation name($request: XRequest!) { name(request: $request) { response successful } }'''`; legacy ops are camelCase (`doTransaction`, `equipItem`), new ones PascalCase (`CreateCharacter`, `DeleteCharacter`). `AcceptQuest` goes in a new `QuestMutations` (`lib/graphql/mutations/quest_mutations.dart`, per `naming.md`).
- `CityQueries.getAllCities`: `id type name markerLocation{id location} relatedLore{id description}`; the `City` model has `area` but the document does not select it.

### What will break with BE Phase 8 types (checked against current SDL: Phase 7 shapes are `registeredAdventurers: [String!]!`, `requiredAdventurers: Int!`, `party: [QuestPartySlot!]!`, `startDate: DateTime!`)
1. `Quest.registeredAdventurers` parser (already wrong today).
2. `QuestRequirements.requiredAdventurers` parser (`as num?` on a list -> `TypeError`) and `sheet.dart`'s `isFull` (`registeredAdventurers?.length == requirements?.requiredAdventurers`, compares an `int?` with an `int?`; with slots it is a type error). Also note the old rule is wrong for unselected data: `0 == 0` would mark a `dungeon` torn when both are 0 - the new rule must only apply to the registered types and require a non-empty slot list.
3. The `quests` document: selecting `registeredAdventurers { character title }` / `requiredAdventurers { title count }` **fails validation against current `origin/develop`** (measured: `Field "registeredAdventurers" must not have a selection since type "[String!]!" has no subfields`). Selecting `party` fails after Phase 8.
4. `PendingQuest.startDate` null: parser already handles it; the UI must (D-15).

## Architecture Patterns

### Recommended Project Structure (new/changed files)
```
lib/
  graphql/mutations/quest_mutations.dart            # AcceptQuest
  graphql/queries/city_queries.dart                 # + GetCity (G2)         [dirty: hand edit]
  graphql/queries/quest_queries.dart                # + requirements/enemy/lore/registered [dirty: hand edit]
  graphql/fragments/character_fragment.dart         # + 3 lanes              [dirty: hand edit]
  models/request/accept_quest_request.dart          # {id, questId} + toJson
  models/quest/adventurer_slot.dart                 # {TitleType? title, int count}
  models/quest/registered_adventurer.dart           # {String characterId, TitleType? title}
  models/quest/quest_lane.dart                      # laneOf(QuestType) pure
  models/quest/quest_availability.dart              # classifier (pure, Flutter-free)
  models/quest/quest_state_label.dart               # state-label copy by type (pure)
  repository/quest_acceptance_failure.dart          # enum + exception + failureFrom(OperationException)
  repository/quest_acceptance_repository.dart       # _guard, like CharacterDeletionRepository
  repository/services/graphql/graphql.dart          # + acceptQuest, getCity, tolerant getQuests
  screens/mainScreen/questAcceptanceCubit/          # cubit + state
  screens/mainScreen/questCubit/quest_cubit.dart    # + refreshQuests()
  screens/mainScreen/tabs/board/                    # board.dart, components/sheet.dart, tear/*
  screens/mainScreen/tabs/map/                      # persistent quest paper + state label
  shared/components/popup/quest_info_sheet.dart     # families + indicators (view-model in)
  shared/components/tear/                           # TearablePaper, TearClipper, TearGesture (pure)
test/ (mirror) + test/helpers/fixtures/quest_fixtures.dart
```
Cubit registered in `AuthenticatedShell`'s `MultiBlocProvider` (like `CharacterDeletionCubit`) so a response arriving after a tab change is not lost and the cubit is closed with the session (`SafeEmit`). `authenticated_shell_test.dart` must be extended to assert the provider.

### Pattern 1: the acceptance mutation (mirrors `deleteCharacter`)
```dart
// lib/graphql/mutations/quest_mutations.dart
class QuestMutations {
  static const String acceptQuest = r'''
    mutation AcceptQuest($request: AcceptQuestRequest!) {
      acceptQuest(request: $request) {
        response
        successful
      }
    }''';
}

// KlimmeckGraphQl
/// Lancia [OperationException] (con `extensions.code`) o [FormatException].
Future<void> acceptQuest(AcceptQuestRequest request) async {
  final data = _dataOrThrow(await performMutation(
    query: QuestMutations.acceptQuest,
    variables: {'request': request.toJson()},
  ));
  final result = data['acceptQuest'];
  if (result is! Map<String, dynamic> || result['successful'] != true) {
    throw const FormatException('acceptQuest not successful');
  }
}
```
`request.toJson()` must be `{'id': characterId, 'questId': questId}` (BE `AcceptQuestRequest { id: String!, questId: String! }`; `id` is the **character** id). Source of `id`: `CharacterLoaded.character.id` (never typed by the UI). Register `'AcceptQuest': QuestMutations.acceptQuest` in `tool/schema_check/schema_check_documents.dart` **in the same commit** (the test `schema_check_documents_test.dart` fails otherwise). Beware: that test scans `lib/graphql/{queries,mutations,subscriptions}/*.dart` with `\b(?:query|mutation|subscription)\s+(\w+)`, so a comment such as "mutation Foo" in those files adds a phantom operation name.

### Pattern 2: error mapping by `extensions.code` (mirrors `character_deletion_failure.dart`)
```dart
// lib/repository/quest_acceptance_failure.dart
enum QuestAcceptanceFailure {
  slotBusy, full, alreadyTaken, titleMismatch, notInCity, notAcceptable,
  insufficientPoints, notFound, forbidden, travelInProgress,
  unauthenticated, connection, unknown,
}

class QuestAcceptanceException implements Exception {
  const QuestAcceptanceException(this.failure);
  final QuestAcceptanceFailure failure;
}

QuestAcceptanceFailure questAcceptanceFailureFrom(OperationException e) {
  final code = graphQlErrorCode(e);
  if (code == null && e.linkException != null) return QuestAcceptanceFailure.connection;
  return switch (code) {
    'QUEST_SLOT_BUSY' => QuestAcceptanceFailure.slotBusy,
    'QUEST_FULL' => QuestAcceptanceFailure.full,
    'QUEST_ALREADY_TAKEN' => QuestAcceptanceFailure.alreadyTaken,
    'QUEST_TITLE_MISMATCH' => QuestAcceptanceFailure.titleMismatch,
    'QUEST_NOT_IN_CITY' => QuestAcceptanceFailure.notInCity,
    'QUEST_NOT_ACCEPTABLE' => QuestAcceptanceFailure.notAcceptable,
    'INSUFFICIENT_POINTS' => QuestAcceptanceFailure.insufficientPoints,
    notFoundCode => QuestAcceptanceFailure.notFound,
    forbiddenCode => QuestAcceptanceFailure.forbidden,
    'TRAVEL_IN_PROGRESS' => QuestAcceptanceFailure.travelInProgress, // BE Phase 8 D-19
    unauthenticatedCode => QuestAcceptanceFailure.unauthenticated,
    _ => QuestAcceptanceFailure.unknown,
  };
}
```
`graphQlErrorCode`, `notFoundCode`, `forbiddenCode` live in `graphql_error_code.dart`; `unauthenticatedCode` in `auth_api_exception.dart`. `UNAUTHENTICATED` leaking means the session flow (silent refresh, else sign-in) is already acting: roll back, publish **no** banner. The copy table is a pure `String? noticeFor(QuestAcceptanceFailure, {QuestType? type})` (provisional Italian, e.g. `slotBusy` -> "Hai già una missione di questo tipo in corso", `full` -> "Non ci sono più posti per il tuo rango", `alreadyTaken` -> "Hai già affrontato questa missione", `titleMismatch` -> "Il tuo titolo non permette questa missione", `notInCity` -> "Devi trovarti in città per accettare", `notAcceptable` -> "Missione non disponibile", `insufficientPoints` -> "Punti canale insufficienti", `travelInProgress` -> "Sei in viaggio", `connection` -> "Connessione assente, riprova", `unknown` -> generic). Exhaustive `switch` over the enum gives compile-time coverage; pin every code in a test.

### Pattern 3: Repository + Cubit (optimistic tear, navigate on success)
```dart
class QuestAcceptanceRepository {
  QuestAcceptanceRepository({required KlimmeckGraphQl graphQl}) : _graphQl = graphQl;
  final KlimmeckGraphQl _graphQl;
  Future<void> accept({required String characterId, required String questId}) async {
    try {
      await _graphQl.acceptQuest(AcceptQuestRequest(id: characterId, questId: questId));
    } on OperationException catch (e) {
      throw QuestAcceptanceException(questAcceptanceFailureFrom(e));
    } on FormatException {
      throw const QuestAcceptanceException(QuestAcceptanceFailure.unknown);
    }
  }
}

sealed class QuestAcceptanceState extends Equatable { const QuestAcceptanceState(); }
final class QuestAcceptanceIdle extends QuestAcceptanceState { ... }
final class QuestAccepting extends QuestAcceptanceState { final String questId; ... }
final class QuestAccepted extends QuestAcceptanceState { final String questId; ... }
final class QuestAcceptanceFailed extends QuestAcceptanceState {
  final String questId; final QuestAcceptanceFailure failure; ...
}
```
`QuestAcceptanceCubit.accept(characterId, questId)`: ignore if already `QuestAccepting` (double submit guard; the BE also rejects with `QUEST_SLOT_BUSY`/`QUEST_ALREADY_TAKEN`), emit `QuestAccepting`, then `QuestAccepted` or `QuestAcceptanceFailed`. `QuestAccepted` is the **only** trigger for navigation (D-03); the populated lane and the new balance arrive through `characterUpdated`/`userUpdated`, never from the `CommonResponse`. Add `reset()` (back to idle) after the UI has handled a terminal state so the next gesture starts clean and a repeated identical failure is not swallowed by Bloc's equal-state dedup. Test with `bloc_test`: `[Accepting, Accepted]`, `[Accepting, Failed(<each code>)]`, double call ignored, late response after `close()` ignored (pattern of `quest_cubit_test.dart`).

### Pattern 4: the tear (custom `GestureDetector`, two `ClipPath` layers, spring)
Geometry and thresholds are provisional (D-19); isolate them so the user can restyle:
- **`TearGesture` (pure Dart, no Flutter):** `progress(dragDx, width) = clamp(-dragDx / (width * 0.45), 0, 1)` (left only; right drags -> 0); `shouldTear(progress, velocityX) = progress >= 1 || (progress >= 0.35 && velocityX <= -900)`; a latch that reports "threshold crossed" once per drag (haptic fires once). All numbers are constructor parameters with defaults. 100% unit-testable.
- **`TearGeometry.at(progress)` (pure):** offsets/angles of the two halves (e.g. left half `dx = -progress * w * 0.35, angle = -0.06 * progress`; right half `dx = +progress * w * 0.15, angle = +0.04 * progress`). Pure so a test can pin monotonicity and the zero at rest.
- **`TearClipper extends CustomClipper<Path>`** with a `side` (left/right) and a **deterministic** jagged line (fixed list of tooth offsets or `sin`-based, never `Random`, so both halves share the identical edge and `shouldReclip` is simply `old.side != side`). Vertical tear at ~50% of the sheet width is the robust choice: the sheet is `1.5 x screen height` tall inside a `screen height` scroll box, so a horizontal tear line would sit mostly off-screen.
- **`TearablePaper`:** at `progress == 0` render `child` once; while `progress > 0` render a `Stack` of two `Transform`+`ClipPath(clipper: TearClipper(side), clipBehavior: Clip.antiAlias)` copies of `child`. Wrap in a `RepaintBoundary`. It sits **inside** the existing `SingleChildScrollView` (around `QuestInfoSheet`), so the scroll offset is preserved.
- **Controller:** one `AnimationController` (`value` = progress). `onHorizontalDragStart` stops any animation; `onHorizontalDragUpdate` sets `value`; `onHorizontalDragEnd` either `animateTo(1.0)` (tear completes, then call `onTorn`) or spring back with `controller.animateWith(SpringSimulation(SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: 0.6), value, 0, velocity))` (import `package:flutter/physics.dart`). Spring-back is also the **rollback** path on `QuestAcceptanceFailed` and the **blocked** path (cap progress at ~0.12 when `availability != available`: "the paper resists", plus `HapticFeedback.lightImpact()`).
- **Do not mix** `onPan*` with `onHorizontalDrag*` on one detector (Flutter asserts) and do not use `Dismissible`. [CITED: docs.flutter.dev/ui/interactivity/gestures - arena resolves by axis; "crashes if onHorizontalDragUpdate or onVerticalDragUpdate is set" with pan]
- **Haptics:** `HapticFeedback.selectionClick()` at the threshold (once, latched), `HapticFeedback.mediumImpact()` (or `heavyImpact()`) when the tear commits. On Android these map to `View.performHapticFeedback` constants (`CLOCK_TICK`, `KEYBOARD_TAP`, `CONTEXT_CLICK` on API 23+) [CITED: flutter/flutter 3.35.5 `PlatformPlugin.java` `vibrateHapticFeedback`, fetched this session]. No `VIBRATE` permission is needed for `performHapticFeedback` and the manifest has none [VERIFIED: grep of `AndroidManifest.xml`; "no permission needed" is general Android knowledge - ASSUMED, low risk]; the user's system "touch feedback" setting can silence them, and `KEYBOARD_TAP`/`CLOCK_TICK` are faint on many devices, so judge the pattern on the real phone (provisional anyway).
- **Gesture arena inside the scrollable sheet:** the vertical `SingleChildScrollView` of the board sheet and a horizontal-drag recognizer on a child do not conflict (each wins on its own axis; diagonal motion is whoever crosses the slop first). The narrative family's lore text is vertical scrolling inside the same sheet: keep it in the same scroll view (no nested scrollable) or the nested vertical scrollable still only competes on the vertical axis. The `Wrap` of papers on the board is not involved (the swipe lives on the overlaid sheet, D-01).

### Pattern 5: navigation to the Map on success
Tab state lives in `_MainScreenState` (`PageController pageController`, `int currentPage`); there is **no cubit** for it. `onItemTap(index)` -> `pageController.jumpToPage(index)`; Phase 5's `NotificationIntentLanding` does the same with `worldMapPageIndex = 0` (and pops root routes first). For Phase 6 pass a callback from `_buildPages` into the Board: `Board(onQuestAccepted: () => pageController.jumpToPage(NotificationIntentLanding.worldMapPageIndex))`, called from a `BlocListener<QuestAcceptanceCubit, ...>` on `QuestAccepted` (then `cubit.reset()`). Pages are `[Map, Profile, Journal, Library, Board, Shop, Settings]` = `SatchelLayout.entries[*].pageIndex`; the Board is index **4**. Prefer a named constant over literals (add `SatchelLayout.boardPageIndex`/`mapPageIndex`, or reuse the existing constant). Test the Board in isolation with a counter callback (the existing `main_screen_test.dart` mocks `MainScreenCubit` at `MainScreenInitial`, so it never builds the pages).

### Pattern 6: the pure availability layer (carries D-10..D-12, D-15) - the heart of the unit tests
Inputs (all plain data): `Quest`, a `CharacterView` (character id, `TitleType title`, `CharacterQuests` with the three lanes + `completedQuests`, current POI id), `twitchPoints`, and the board context (current city POI ids). Outputs: an enum plus the data the sheet needs.
```dart
QuestLane laneOf(QuestType t) => switch (t) {
  QuestType.story => QuestLane.story,
  QuestType.worldMission => QuestLane.worldMission,
  _ => QuestLane.standard,
};
const registeredTypes = {QuestType.worldMission, QuestType.boss, QuestType.enemy, QuestType.aid}; // D-12/D-27
const nonRepeatableTypes = {QuestType.story, QuestType.worldMission, QuestType.enemy, QuestType.boss, QuestType.aid}; // D-10
```
Classification order **mirrors the BE** (handoff §2 "Ordine di valutazione"): `alreadyDone` (non-repeatable in `completedQuests`, or character registered) -> `titleMismatch` (story: `title == minTitle`; others `title.index >= minTitle.index`; `minTitle` null = no constraint) -> `laneBusy` (the quest's lane is occupied by *another* quest) -> `full` (registered types, per rank) -> `notInCity` (standard lane only: marker not among the current city's POIs; story/worldMission exempt, BE Phase 8 D-26) -> `insufficientPoints` (story/worldMission: `twitchPoints < requiredPoints`) -> `available`. Two extra *display* states that are not blocking reasons: `tornForOwner` (the lane holds **this** quest, D-08/D-12) and `tornForEveryone` (`full`). Torn quests cannot be swiped; the others show the reason and block the swipe; **the BE remains the judge**.

Rank-aware fullness (D-12), exact for the BE greedy "exact slot first, `null` slot as overflow" model:
```dart
bool isFull(List<AdventurerSlot> slots, List<RegisteredAdventurer> reg, TitleType? myTitle) {
  if (slots.isEmpty) return false;                       // catalogue defect: BE answers QUEST_NOT_ACCEPTABLE
  final total = slots.fold<int>(0, (s, e) => s + e.count);
  if (reg.length >= total) return true;
  if (myTitle == null) return false;
  int exact(TitleType? t) => slots.where((s) => s.title == t).fold(0, (a, s) => a + s.count);
  final anyRank = exact(null);
  int regOf(TitleType t) => reg.where((r) => r.title == t).length;
  final overflowUsed = TitleType.values.fold<int>(0, (a, t) => a + max(0, regOf(t) - exact(t)));
  final canRegister = regOf(myTitle) < exact(myTitle) || overflowUsed < anyRank;
  return !canRegister;
}
```
Why not the simpler "registered of my rank >= exact + nulls": it answers "available" in `[hero 1, null 2]` with registered `[paladin, mage]` for a third paladin, which the BE would reject with `QUEST_FULL` (verified by reasoning; add it as a named test). **Assumption A1:** the BE fills exact-rank slots before `null` slots; BE Phase 8 is not implemented, so confirm in its PLAN. A wrong guess only produces a BE `QUEST_FULL` banner, never a wrong grant.

Cost line (D-02) and state label (D-15) are pure functions:
- `costLine(type, requiredPoints, twitchPoints) -> (text: 'Punti canale: $twitchPoints / $requiredPoints', insufficient: twitchPoints < requiredPoints)` only for story/worldMission with `requiredPoints > 0`; `null` otherwise (the `enemy` catalogue quest has `requiredPoints: 3000` which the BE ignores - handoff §6 - so keying on type, not on field presence, is mandatory). `twitchPoints` null (no `AuthAuthenticated`) -> show cost only.
- `stateLabel(PendingQuest lane, QuestType type)`: `startDate == null` -> "In viaggio"; else by type (`enemy`/`boss` "In combattimento…", `hunt` "Cacciando…", `dungeon` "Esplorando…", `job` "Lavorando…", `heal` "Guarendo…", `aid` "Aiutando…", `study` "Studiando…", fallback generic "In corso…").

### Pattern 7: Board policy (D-11) as a pure filter + the data sources
Board content = `quests.where(listed)`. `listed(q)`: not (non-repeatable and in `completedQuests`); `story` only when `minTitle == character title`; `worldMission` always; other types only when `q.infos.markerLocation.id` is in the current city's POI id set. "Board accessible" = `status.location.id` equals some `City.markerLocation.id` from `MainScreenLoadData.cities` (see Location source). Rendering keys: each `Sheet` **must** get `ValueKey(quest.id)` (today none: positional reuse + `Sheet.initState` picking a *random* image would show another quest's image after a filter change), and the variant must be deterministic from the quest id (stable fold of its code units), recomputed in `didUpdateWidget` when torn changes. Extract the type -> asset-family mapping (intact/torn lists in `sheet.dart`) into one small pure helper reused by the Board and the Map paper (>= 2 features).

### Pattern 8: the persistent paper on the Map (D-07, D-08, D-15)
`WorldMap` builds `FlutterMap(children: [..., CharacterMarkerLayer, QuestInfoOverlay])` where `QuestInfoOverlay` is a `Positioned` inside the map's stack animated by `_questAnimationController` (`MapConstants.questSheetAnimationDuration`), and `_selectQuest(quest)` sets `_selectedQuest` + `forward()`. Add a sibling `QuestPaperLayer` in the same children list (or a `Stack` above the map): `BlocBuilder` over `CharacterCubit` (lane `pendingQuest`) + `QuestCubit` (resolve the lane's `quest.id` against the loaded list - lanes carry **only** the id, BE handoff §4) -> if the lane is populated and the quest is found and its type is **not** story/worldMission, show the **intact** family asset (`CachedSvg`, ~110 px, slight tilt, top-left corner so it stays clear of the pouch bottom-left, the banner top-centre and the info overlay right) wrapped in a `GestureDetector(onTap: () => _selectQuest(quest))`; the existing overlay then opens the read-only `QuestInfoSheet`, extended with an optional `stateLabel` line. The paper's tap wins over the map's `onTap` handlers (deepest detector). If the quest is not (yet) in the list, render nothing (never a spinner). Centering the map on the marker is optional; if done, use the existing `_mapController.move(...)` and the quest's `markerLocation.location`. No swipe handler on the Map overlay (D-01).

### Pattern 9: satchel item disabled (D-11/D-13)
The grid cell and the flying icon are two widgets: `MenuSection` (cell label + gold borders, tap -> `onTap(entry.pageIndex)`) in `MenuBackground`, and `MenuItem` (SVG circle, tap -> `onTap(pageIndex)`) in `SatchelMenu`. Add an `isEnabled` per entry (a `Set<int> disabledPages` passed from `MainScreen`): disabled -> `MenuSection` wraps its content in a darkening overlay (`ColoredBox` with a theme-token scrim) and swallows the tap; `MenuItem` dims the SVG and ignores the tap. Compute the set in `MainScreen` with a `BlocSelector<CharacterCubit, CharacterState, bool>` + `MainScreenLoadData.cities` (the Phase 7 travel case will add `activeTravel` to the same policy function, so name it generically, e.g. `disabledSatchelPages(character, cities)`), and **also guard `onItemTap`** (defence: no other path may `jumpToPage(4)`). Existing tests to extend: `menu_background_test.dart`, `satchel_menu_test.dart`, `menu_item_test.dart`.

### Pattern 10: banner for the acceptance failure
`BlocListener<QuestAcceptanceCubit, QuestAcceptanceState>` in the Board: on `QuestAcceptanceFailed` -> (1) recompose the torn paper (spring back), (2) `context.read<InAppNotificationsCubit>().publishNotice(KGNotification(title: ..., description: ...), dedupKey: 'quest-acceptance|${failure.name}')` unless the copy function returns null (`unauthenticated`), (3) for `full`/`alreadyTaken`/`notFound` also `context.read<QuestCubit>().refreshQuests()` so the paper shows as torn/removed, (4) `cubit.reset()`. The overlay (`_InAppNotificationOverlay` in `authenticated_shell.dart`) sits above the whole `_ShellBody`, so it is visible over the Board; root-navigator routes (dialogs) stay above it (accepted in Phase 5).

### Anti-Patterns to Avoid
- **Building state from the mutation response** (D-03): the lane and the balance come from the subscriptions only.
- **A `QuestLoading` emission on refresh** (blanks the board).
- **Random asset choice in `initState`** of `Sheet` (flicker, wrong image after a filter change).
- **Client-side `if (twitchPoints < cost) return;` before sending**: the sheet may *block the swipe* when it is sure, but the BE is the judge; never make the check the only gate (stale balance after a missed event).
- **Comparing counts to decide "full"** (`length == requiredAdventurers`): see Pattern 6.
- **Running `dart format` on directories or on the dirty files listed above.**
- **A `Cubit` that publishes to the banner cubit** (C4).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Spring-back / settle animation | a `Timer` ticking offsets | `AnimationController.animateWith(SpringSimulation(...))` (`package:flutter/physics.dart`) | handles velocity hand-off from the fling |
| Jagged clip of a widget tree | image slicing / `toImage` | `ClipPath` + `CustomClipper<Path>` over the same widget | synchronous, hit-test/semantics safe, testable |
| Haptics | platform channel code | `HapticFeedback` from `flutter/services` | one-liners, recordable via `SystemChannels.platform` in tests |
| Error mapping | parsing `message` text | `graphQlErrorCode(OperationException)` + enum + exhaustive `switch` | codes are the contract (handoff §2, Phase 2 D-19) |
| Operation validation | eyeballing documents | `tool/schema_check` (graphql-js of the BE) | caught `registeredAdventurers` mismatches in this very session |
| Banner queue/timer/dedup | a new overlay | `InAppNotificationsCubit` (+ `publishNotice`) | single publication path (Phase 5 D-18) |
| Title ordering | string compare | `TitleType.index` (enum order = BE `TITLE_RANK`) | already ordered |
| Image decoding of the sheet | `Image.network` | `CachedSvg` + `CloudinaryAssets` | assets rule |

**Key insight:** this phase is mostly *decisions encoded as pure functions* (lane, availability, fullness, cost line, label, copy). Keeping them Flutter-free makes the TDD cheap and lets the visual layer be thrown away and restyled by the user without touching behaviour (D-19).

## Map tab and navigation (research question 2)
- Tab switching: `MainScreen` owns `PageController`; `PageView(physics: NeverScrollableScrollPhysics)`; `onItemTap(index)` -> `jumpToPage(index)`. No cubit. `NotificationIntentLanding` wraps the `PageView` and shows the established "jump to Map + pop root routes" idiom (including the `hasClients` guard, Pitfall 14 of Phase 5).
- Off-screen pages are disposed (`PageView` `cacheExtent: 0`, `page_view.dart:975`), so the Board `State` (including `_selectedQuest` and the sheet animation) is re-created on every visit; `QuestCubit`, `CharacterCubit` and the new acceptance cubit live in the shell and survive.
- Map layering: `FlutterMap.children` = map image overlay, `CityMarkersLayer`, `QuestMarkersLayer` (quest pawns, hidden below `questVisibleZoom`, tap -> `_selectQuest`), `CharacterMarkerLayer` (draggable pawn; `changeCharacterLocation` is an empty stub), `QuestInfoOverlay` (animated `Positioned`, right side, `height = screen`, `width = screenHeight * 1.5 * (315/375)`). The outer `GestureDetector.onTap` clears `_selectedQuest`; the map `onTap` reverses the animation.
- The pouch and the satchel grid are overlays in `MainScreen`'s own `Stack` above the `PageView`.

## Location source (research question 3)
- `CharacterStatus.location` is a `PointOfInterest` with `id` + `location` (the fragment already selects `location { id location }`); the character's POI id is in `CharacterLoaded.character.status!.location!.id`.
- Cities: `MainScreenCubit.loadData()` -> `MainScreenLoadData.cities`, each `City.markerLocation` (`id`, `location`). **Cheapest check for D-11:** `cities.any((c) => c.markerLocation?.id == status.location?.id)`; the matching city is "the current city". No new field, no new query, and exactly the definition CONTEXT D-11 uses. [VERIFIED: models + documents]
- POI `type` (`PoiType.city`) is **not** a viable source: it is not selected, and `PointOfInterest.fromJson` mis-parses `type` (`Iterable` vs `List`).
- Quest -> city membership needs the city's POI ids: see **G2** (`GetCity`).

## Shop flow: what it does today (research question 5)
See C3. In short: `TransactionCubit.doTransaction` -> `graphQl.doTransaction` (throws `Exception('Server error: ...')`, `successful` is **not** checked) -> `TransactionLoading` / `TransactionDone` / `TransactionError` (no payload), each followed by a 4 s `Future.delayed` back to `TransactionInitial`; `shop.dart` shows a comic-balloon (`TransactionMessageBubble`) with hard-coded Italian lines. `transaction_modal.dart` gates the signature tap with `canAfford = character.status.coins.canAfford(total)` and paints a red X when false (a *client-side* affordability pre-check on **coins**; nothing to reuse for channel points beyond the idea). `ShopCubit.getData` swallows errors into `ShopError(e.toString())` (a technical string; the Shop UI does not render it).

## Repository -> Cubit and error mapping (research question 6)
- Pattern (Phase 2/4): `KlimmeckGraphQl` method uses `performMutation` + `_dataOrThrow` (throws the raw `OperationException`); `XxxFailure` file in `lib/repository/` holds the enum + `XxxException` + `xxxFailureFrom(OperationException)`; `XxxRepository._guard` converts `OperationException`/`FormatException` to the domain exception; Cubit catches only the domain exception. Reference files: `character_deletion_failure.dart`, `character_deletion_repository.dart`, `character_creation_failure.dart`, `push_device_failure.dart`.
- Code extraction: `graphQlErrorCode(OperationException?)` (`graphql_error_code.dart`) reads `graphqlErrors[*].extensions['code']`, with a defensive path for `SubscriptionError` payloads. `accessDeniedCodes = {FORBIDDEN, NOT_FOUND}` is the sync-path set (not reused here: acceptance failures are user-facing, not silent).
- Test tooling: `test/repository/services/graphql/graphql_character_deletion_test.dart` builds a real `KlimmeckGraphQl` with `GraphQLClient(link: Link.function((req, [fwd]) => handler(req)), cache: GraphQLCache(store: InMemoryStore()))`; responses come from `test/helpers/fixtures/sync_event_fixtures.dart`: `dataResponse({...})`, `errorCodeResponse('CODE')` (`GraphQLError(extensions: {'code': code})`), `userJson`, `characterJson`; `operationNameOf(request)` reads the operation name. Failure-mapping tests build `OperationException(graphqlErrors: [GraphQLError(message: .., extensions: {'code': ..})])` or `linkException: ServerException(...)` directly (see `character_deletion_failure_test.dart`). Cubit tests use `bloc_test` + `MockKlimmeckGraphQl`/repository mocks from `test/helpers/mocks.dart` ("never redefine a mock in a single test file").

## Test fixtures that encode the proposed BE contract (research question 9)
Create `test/helpers/fixtures/quest_fixtures.dart` (one place, imported by model, classifier, widget and repository tests):
```dart
Map<String, dynamic> questJson({
  String id = 'q-1', String type = 'enemy', String minTitle = 'rookie',
  int? requiredPoints, List<Map<String, dynamic>>? slots,        // BE Phase 8: [{title?, count}]
  List<Map<String, dynamic>> registered = const [],               // BE Phase 8: [{character, title}]
  String markerId = 'poi-1', Map<String, dynamic>? enemy, List<Map<String, dynamic>>? lore,
}) => {
  'id': id,
  'infos': {'title': 'T', 'type': type, 'timeToComplete': 60000,
            'markerLocation': {'id': markerId, 'location': [1.0, 2.0]},
            if (enemy != null) 'enemy': enemy, if (lore != null) 'relatedLore': lore},
  'requirements': {'minTitle': minTitle, 'requiredPoints': requiredPoints,
                   'requiredAdventurers': slots ?? [{'title': null, 'count': 1}]},
  'registeredAdventurers': registered,
};
Map<String, dynamic> laneJson({String questId = 'q-1', String? startDate, int pointsSpent = 0})
  => {'id': 'pq-1', 'startDate': startDate, 'waitingTime': 0.0, 'pointsSpent': pointsSpent, 'quest': {'id': questId}};
```
Plus `characterWithLanesJson(...)` building `status {title, location{id location}}` and `quests {completedQuests, pendingQuest, activeStoryQuest, activeWorldMissionQuest}`, and a legacy variant (`requiredAdventurers: 1`, `registeredAdventurers: ['c-1']`) used by exactly one test of the tolerant parser. **Tolerant parsing (recommended):** `AdventurerSlot.listFrom(Object?)` accepts a list of maps (Phase 8) **or** an `int` (Phase 7: becomes a single `null`-rank slot when `> 0`); `RegisteredAdventurer.from(Object)` accepts a map or a plain id `String` (title `null`). With one classifier path this gives the "count-only fallback" CONTEXT allows before BE Phase 8, so plans 1-8 can run the manual E2E on current BE `develop`; only the last plan changes the document.

### What lands now vs. what waits for BE Phase 8
| Item | BE `develop` today | Needs BE Phase 8 | Needs G1/G2 |
|------|:---:|:---:|:---:|
| `AcceptQuest` document, request model, repository, cubit, failure mapping (all codes except `TRAVEL_IN_PROGRESS`, which is just an unmatched/mapped string) | yes | - | - |
| Lanes in `questsFields` + models (`pendingQuest`, `activeStoryQuest`, `activeWorldMissionQuest`) | yes | `startDate` null only after Phase 8 (parser already nullable) | - |
| `requirements { minTitle requiredPoints recommendedLoot{...} }` in `quests` | yes (valid today) | - | `recommendedLoot.item` populate (G1) |
| `infos.enemy`, `infos.relatedLore` selections | validates today | - | **G1 (will error at runtime)** |
| `requiredAdventurers` as slots, `registeredAdventurers { character title }` | **fails validation** | **yes (last plan)** | - |
| Board city filter | via `GetCity` (valid today) | - | G2 only if the `cities` route is chosen |
| `story`/`worldMission` acceptable from any city | BE still answers `QUEST_NOT_IN_CITY` outside the marker's city | D-26 | - |
| Torn-for-everyone for `enemy`/`aid` | no registration for them yet | D-27 | - |
| "In viaggio" label | never visible (`startDate` always set) | D-15 | - |

## Common Pitfalls

### Pitfall 1: `quests` list is a stale snapshot
**What goes wrong:** another player takes the boss; this player's board still shows it intact; the swipe ends in `QUEST_FULL`.
**Why:** no quests subscription (C5). **Avoid:** `refreshQuests()` on Board `initState` and after rejection; treat the banner as the correction path. **Warning sign:** the same quest rejected twice.

### Pitfall 2: selecting unpopulated references (G1/G2)
**What goes wrong:** `quests` returns errors and `getQuests` throws (`result.hasException`), leaving the board empty. **Avoid:** probe against a running BE before merging the document; select `infos.enemy`/`relatedLore` only when G1 is fixed; keep fields nullable in models.

### Pitfall 3: one malformed hand-edited quest blanks the board (C6)
**Avoid:** `Quest.tryFromJson`; log only the quest id.

### Pitfall 4: `Sheet` state reuse
**What goes wrong:** filtering/torn changes re-use `_SheetState` by position; the image is chosen once in `initState` with `Random`. **Avoid:** `ValueKey(quest.id)`, deterministic variant, recompute in `didUpdateWidget`.

### Pitfall 5: old `isFull` semantics
`registeredAdventurers?.length == requirements?.requiredAdventurers` tears every quest when both are `0`/empty (e.g. a `dungeon` with `requiredAdventurers: 0` once the fields are selected). **Avoid:** registered types only, non-empty slots, per-rank rule (Pattern 6).

### Pitfall 6: cost keyed on field presence
The `enemy` catalogue quest carries `requiredPoints: 3000` (ignored by the BE, handoff §6). **Avoid:** show the cost line by *type* (story/worldMission), never by `requiredPoints != null`.

### Pitfall 7: story filter by exact title
Story is acceptable only at the **exact** title (`status.title == minTitle`), others `>=`. A `>=` for story would list the four chapters CONTEXT hides.

### Pitfall 8: swipe racing the response
Tear is optimistic; the user can swipe again, or leave the tab, while `QuestAccepting`. **Avoid:** ignore gestures while `QuestAccepting`; keep halves apart until a terminal state; never navigate on anything but `QuestAccepted`.

### Pitfall 9: duplicated sheet tree cost
Two copies of the 1.5x-screen-height sheet during a drag. **Avoid:** single child at rest, `RepaintBoundary`, both copies share `Key`-less const subtrees; measure on the real phone.

### Pitfall 10: widget tests and `CachedSvg`
`CachedSvg` hits `SvgCacheManager` (network) unless the URL is in `SvgCache`. Seed it as `satchel_menu_test.dart` does (`SvgCache().add(CloudinaryAssets.url(asset), tinySvgFile)`) for `emptySheet` and every paper asset used; otherwise tests hang/spin. Use `useLandscapePhone(tester)` (780x360) and `buildTestApp(home: ...)`. `Image.asset(enemy.imagePath)` in the sheet throws for an unknown bundled path: tests must use an existing asset (`assets/images/arbustoMaligno.png`) or no enemy.

### Pitfall 11: `startDate` null semantic and `copyWith`
`PendingQuest.copyWith(startDate: null)` cannot clear the date; if tests need a "travelling" lane build the model from JSON.

### Pitfall 12: schema-check test and doc comments
See Pattern 1; also the final count: the checker lists 27 operations today (all `OK` against `origin/develop`, measured); expect 28 after `AcceptQuest`, 29 with `GetCity`.

### Pitfall 13: Bloc dedups equal consecutive states
`Failed(q, full)` followed by another identical `Failed` is not re-emitted; always pass through `Accepting` (or `reset()`).

### Pitfall 14: `Board` mounted while the character leaves the city
If a GM teleport changes the location while the Board page is open, the page stays. Not in D-11; recommended: the Board renders an empty state and the satchel stays disabled (no crash on a missing city). Low priority.

## Code Examples

### Lanes in the character fragment (D-14)
```dart
// character_fragment.dart (questsFields: no interpolation needed, keep const)
static const String questsFields = '''
  quests {
    completedQuests { id }
    pendingQuest { id startDate waitingTime pointsSpent quest { id } }
    activeStoryQuest { id startDate waitingTime pointsSpent quest { id } }
    activeWorldMissionQuest { id startDate waitingTime pointsSpent quest { id } }
  }
''';
```
[CITED: BE `BACKEND-NOTES.md` §4 "Selezione consigliata": select **only** `quest { id }` inside a lane.] Valid on current SDL; `startDate` nullable after Phase 8 needs no change.

### Final `quests` selection (BE Phase 8 shape; interim shape = `requiredAdventurers` as a scalar and `registeredAdventurers` as a scalar list)
```graphql
requirements {
  minTitle requiredPoints
  requiredAdventurers { title count }          # interim: requiredAdventurers
  recommendedLoot { quantity item { ... on EquipmentItem { ...simple } ... on LootItem { ...simple } } }
}
registeredAdventurers { character title }      # interim: registeredAdventurers
infos { ... enemy { id name imagePath } relatedLore { id name description } }   # only after G1
```
Never select `enemy.locations`, `markerLocation.type`, `pointsOfInterest.quest`, `party`.

### Recording haptics in a widget test
```dart
final calls = <String?>[];
tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
  SystemChannels.platform,
  (call) async {
    if (call.method == 'HapticFeedback.vibrate') calls.add(call.arguments as String?);
    return null;
  },
);
addTearDown(() => tester.binding.defaultBinaryMessenger
    .setMockMethodCallHandler(SystemChannels.platform, null));
// expect(calls, ['HapticFeedbackType.selectionClick', 'HapticFeedbackType.mediumImpact']);
```
[VERIFIED: `flutter/lib/src/services/haptic_feedback.dart` invokes `'HapticFeedback.vibrate'` with `'HapticFeedbackType.lightImpact' | 'mediumImpact' | 'heavyImpact' | 'selectionClick'`.]

### Dragging in a test
```dart
await tester.drag(find.byType(TearablePaper), const Offset(-300, 0));  // moves past the 0.45*w threshold
await tester.pump();                                                    // then pump the controller
```
Use `tester.timedDrag` or `startGesture/moveBy/up` to control velocity for the fling branch.

## Suggested plan slicing (for the planner)
1. **Docs + models + fixtures (Wave 0/1):** amend QUEST-03/04/05/06/07 + ROADMAP criteria + traceability; `quest_fixtures.dart`; `AdventurerSlot`, `RegisteredAdventurer`, lanes in `CharacterQuests`, tolerant `Quest.tryFromJson`, `questsFields` lanes. (develop-compatible)
2. **Pure availability layer:** lane, classifier, fullness, cost line, state label, copy table. Pure unit tests (largest test count).
3. **Acceptance vertical slice:** `QuestMutations`, `AcceptQuestRequest`, `KlimmeckGraphQl.acceptQuest`, failure mapping, repository, cubit (+ shell provider), `schema_check` entry.
4. **Banner extension:** `InAppNotificationsCubit.publishNotice` + state + overlay rendering (C1).
5. **Tear widget:** `TearGesture`, `TearGeometry`, `TearClipper`, `TearablePaper`, haptics (independent of the others).
6. **Sheet families + indicators:** view-model in, three families, cost line, slots per rank, required title.
7. **Board integration** (depends on 2-6): filter, keyed/deterministic `Sheet` with torn variants, `GetCity` + `refreshQuests`, blocked swipe, acceptance listener (banner + navigation callback), satchel disabled.
8. **Map paper + read-only sheet with state label.**
9. **Last, BE Phase 8 gated:** flip the `quests` document to the slot/object shapes (+ G1 selections if fixed), `tool/schema_check` against `origin/develop`, manual E2E with the BE handoff §8 UAT data on the Android phone.

## State of the Art

| Old approach | Current approach | Impact |
|--------------|------------------|--------|
| `Dismissible` for swipe actions | custom horizontal-drag detector + clipper | needed for the two-halves tear (locked) |
| `MaterialStateProperty`-era haptics wrappers | `HapticFeedback` static API | unchanged, still the SDK path |
| Per-widget `SnackBar` errors | shell-level banner via a queue cubit (Phase 5) | consistent gameplay surface |

**Deprecated/outdated in this repo:** `Board`/`Sheet` count-based `isFull`, `Quest.registeredAdventurers: List<Character>`, hard-coded `3000` in `quest_info_sheet.dart`, `WillPopScope`-style patterns (none found).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | BE Phase 8 fills exact-rank slots before `null` ("any rank") slots when counting capacity | Pattern 6 | FE shows "available" for a quest the BE rejects with `QUEST_FULL` (banner + refresh) - cosmetic |
| A2 | `View.performHapticFeedback` needs no `VIBRATE` permission | Pattern 4 | haptics silent; add the permission only if the real device shows no feedback |
| A3 | Unpopulated refs in `quests` produce resolver errors on the wire (inferred from BE source, not exercised) | G1 | if the BE actually returns something usable, the families could ship without a BE change - the probe decides |
| A4 | `city(id)` returns `pointsOfInterest { id location }` populated for all POIs of the city (read from `findOne`) | G2 | the board city filter would show nothing; probe in Wave 0 |
| A5 | BE Phase 8 keeps `QuestPartySlot` field names `title`/`count` for the new `requiredAdventurers` slots | Fixtures | document/parse mismatch; validated by `schema_check` in the last plan |
| A6 | Showing no banner for `UNAUTHENTICATED` is acceptable (the session flow acts) | Pattern 2 | user sees the paper spring back with no explanation for one frame before sign-in |
| A7 | Provisional Italian copy (banner texts, state labels) | Pattern 2/6 | user rewrites it (D-19) |

## Open Questions

1. **G1 - who populates `infos.enemy`, `infos.relatedLore`, `recommendedLoot.item`?**
   - Known: BE source populates only `markerLocation`; CONTEXT D-09/D-10/D-14 assume the data is there.
   - Unclear: whether the user/orchestrator adds it to BE Phase 8 or wants the FE families degraded.
   - Recommendation: add to BE Phase 8 scope (one `populate` list), keep the FE fields nullable, probe in Wave 0.
2. **G2 - `GetCity` per Board visit vs. BE populate in `cities`.** Recommendation: `GetCity` (no BE dependency).
3. **C1 - banner extension style** (`notice` field vs `InAppBanner` type). Recommendation: `notice` field, minimal diff.
4. **`crime`/`guard` quests on the board:** out of scope for layouts but they exist in the enum, and `Sheet` maps `crime` to its own paper while `guard` falls to the job sheet. Recommendation: list them with the service family fallback (do not filter silently); the user's catalogue currently has none.
5. **`pointsSpent` in `PendingQuest`:** selected by D-14, unused by this phase. Recommendation: parse as `int?` and keep (Phase 9 needs it), no UI.
6. **Board open while the location changes** (Pitfall 14). Recommendation: empty state, no navigation.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter / Dart | everything | yes | 3.35.5 / 3.9.2 | - |
| Node + BE `node_modules/graphql` | `tool/schema_check` | yes | v22.12.0 / graphql 16.11.0 | - |
| BE repo checked out | schema, handoff | yes (branch `feat/08-...`; `origin/develop` = `e5786eb`, PR #10 merged) | - | use `git show origin/develop:src/schema.gql` |
| Running BE (Mongo + Redis) with the UAT catalogue (BE handoff §8) | manual E2E, G1/G2 probes | not verified from here | - | none for E2E; unit/widget tests need no BE |
| Android device + adb | manual E2E (board, tear, haptics, banner) | `adb` not found on this machine's PATH | - | user's phone (Phase 5 UAT used one); haptic feel cannot be judged in tests |
| BE Phase 8 merged on `develop` | last plan only | no (CONTEXT only) | - | plans 1-8 proceed with fakes + tolerant parsing |

**Missing with no fallback:** a running BE with data for the final E2E (user-run). **Missing with fallback:** BE Phase 8 (fakes encode the proposed contract).

## Validation Architecture

(`.planning/config.json` has no `workflow.nyquist_validation: false`, so the section is required.)

### Baseline (measured 2026-10-21 on `feat/06-quest-accept-info-sheets`, clean tree)
- `flutter test` -> **1006 tests, All tests passed, ~26 s**.
- `flutter analyze` -> **56 issues (0 errors)**, all pre-existing (4 warnings + infos; the `dead_null_aware_expression` warnings at `board.dart:54,65` disappear if `quest.id ?? ...` is cleaned while touching the file). Gate: total <= 56, 0 errors, never higher.
- `tool/schema_check` -> **27 documents, 27 `OK`** against `git show origin/develop:src/schema.gql` (BE `graphql` 16.11.0).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK 3.35.5) + `bloc_test` 10.0.0 + `mocktail` 1.0.5 + `fake_async` 1.3.3 |
| Config file | none (defaults); mocks in `test/helpers/mocks.dart`, fakes in `test/helpers/fakes/`, fixtures in `test/helpers/fixtures/` |
| Quick run command | `flutter test test/models test/graphql test/repository/quest_acceptance_failure_test.dart test/repository/quest_acceptance_repository_test.dart test/repository/services/graphql test/screens/mainScreen test/screens/auth/inAppNotificationsCubit test/shared test/tool` |
| Full suite command | `flutter test` (baseline 1006) + `flutter analyze` (<= 56) + `dart format --output=none --set-exit-if-changed <each new or format-clean touched file>` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| QUEST-01 | Combat family shows enemy image+name, required time; narrative family shows scrollable lore text before cost and party; service family shows time, rewards, recommended loot; all ten types render without exception, `crime`/`guard` fall back | widget | `flutter test test/shared/components/popup/quest_info_sheet_test.dart` | Wave 0 |
| QUEST-01 | Indicators: required title highlighted when ineligible; slots per rank with registered counts; already-done; recommended loot | widget + unit | same file + `test/models/quest/quest_availability_test.dart` | Wave 0 |
| QUEST-02 | `TearGesture`: progress clamps, left-only, threshold, fling branch, haptic latch fires once | unit | `flutter test test/shared/components/tear/tear_gesture_test.dart` | Wave 0 |
| QUEST-02 | `TearGeometry` is zero at rest and monotonic; `TearClipper` produces two complementary paths with the identical edge | unit | `flutter test test/shared/components/tear/tear_geometry_test.dart` | Wave 0 |
| QUEST-02 | Drag past threshold fires `onTorn` once, plays `selectionClick` then `mediumImpact`; short drag springs back to 0 and fires nothing; right drag ignored; vertical scroll still scrolls the sheet; blocked quest resists (progress capped) and `lightImpact` | widget | `flutter test test/shared/components/tear/tearable_paper_test.dart` | Wave 0 |
| QUEST-02 | The gesture exists only on the Board sheet, not on the Map overlay | widget | `flutter test test/screens/mainScreen/tabs/map/quest_info_overlay_test.dart` | Wave 0 |
| QUEST-03 | `AcceptQuest` document: one named mutation, `$request: AcceptQuestRequest!`, selects `response successful` | unit | `flutter test test/graphql/quest_mutations_test.dart` | Wave 0 |
| QUEST-03 | `KlimmeckGraphQl.acceptQuest`: sends operation `AcceptQuest` with `{request: {id, questId}}`; `successful:false` / null -> `FormatException`; error code preserved | unit | `flutter test test/repository/services/graphql/graphql_quest_acceptance_test.dart` | Wave 0 |
| QUEST-03 | Cubit sequence `[Accepting, Accepted]`; double call ignored while accepting; late response after `close()` ignored; `reset()` | cubit | `flutter test test/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit_test.dart` | Wave 0 |
| QUEST-03 | Board calls the navigation callback **only** on `QuestAccepted` (not on `Accepting`/`Failed`); mutation fired with `currentCharacter.id` | widget | `flutter test test/screens/mainScreen/tabs/board/board_acceptance_test.dart` | Wave 0 |
| QUEST-03 | Map paper: intact family asset for the standard lane; none for story/worldMission; none when the quest is not in the list; tap opens the read-only sheet with the state line | widget | `flutter test test/screens/mainScreen/tabs/map/quest_paper_layer_test.dart` | Wave 0 |
| QUEST-04 | `laneOf` for the 12 types; classifier order mirrors BE (already done > title > lane busy > full > not in city > points); story exact title vs `>=`; torn for owner; rank-aware `isFull` incl. the `[hero 1, any 2]` overflow case, empty slots, legacy int slots | unit | `flutter test test/models/quest/quest_availability_test.dart` | Wave 0 |
| QUEST-04 | Board policy: city filter via POI ids, `worldMission` from every city, only own-title `story`, completed non-repeatable hidden, listing keeps owner-torn story/worldMission | unit | `flutter test test/models/quest/board_policy_test.dart` | Wave 0 |
| QUEST-04 | `Sheet` picks torn asset family for torn state, keyed by quest id, variant stable across rebuilds | widget | `flutter test test/screens/mainScreen/tabs/board/sheet_test.dart` | Wave 0 |
| QUEST-04 | Satchel: disabled page dims the cell and the icon and swallows taps; `MainScreen.onItemTap` guard; enabled again on a marker | widget | `flutter test test/screens/mainScreen/components` | exists, extend |
| QUEST-04 | Models: `CharacterQuests` three lanes round trip; `Quest.tryFromJson` drops malformed quest, keeps others; slots and registered parsers accept Phase 8 shapes and the legacy shapes | unit | `flutter test test/models/quest test/models/character` | Wave 0 / extend |
| QUEST-04 | Fragment contains the three lanes with `quest { id }` | unit | `flutter test test/graphql/character_fragment_test.dart` | Wave 0 |
| QUEST-05 | Cost line only for story/worldMission, `saldo / costo`, insufficient flag, never for `enemy` with `requiredPoints: 3000`, no coin cost anywhere | unit + widget | `flutter test test/models/quest/quest_cost_line_test.dart test/shared/components/popup/quest_info_sheet_test.dart` | Wave 0 |
| QUEST-06 | `questAcceptanceFailureFrom`: each BE code -> enum, link error -> `connection`, no code -> `unknown`, message text ignored | unit | `flutter test test/repository/quest_acceptance_failure_test.dart` | Wave 0 |
| QUEST-06 | Repository `_guard`: `OperationException` -> `QuestAcceptanceException`; never leaks | unit | `flutter test test/repository/quest_acceptance_repository_test.dart` | Wave 0 |
| QUEST-06 | Copy mapping is exhaustive and Italian; `unauthenticated` -> no banner | unit | `flutter test test/models/quest/quest_acceptance_copy_test.dart` | Wave 0 |
| QUEST-06 | Failure: paper springs back (halves recompose), `publishNotice` called once with the code's copy and dedup key, quest list refreshed for `full`/`alreadyTaken`/`notFound`; with the **real** `InAppNotificationsCubit` the strip appears and auto-dismisses after 5 s | widget + cubit (fake_async) | `flutter test test/screens/mainScreen/tabs/board/board_acceptance_test.dart test/screens/auth/inAppNotificationsCubit` | Wave 0 / extend |
| QUEST-06 | `publishNotice`: queue order with push events, dedup window, tap = dismiss only (router untouched), existing 27 push assertions unchanged | cubit | `flutter test test/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit_test.dart` | exists, extend |
| QUEST-06 | `QuestCubit.refreshQuests`: never emits `QuestLoading`, keeps the previous list on failure, applies the new list on success | cubit | `flutter test test/screens/mainScreen/questCubit/quest_cubit_test.dart` | exists, extend |
| QUEST-07 | `stateLabel`: `startDate == null` -> "In viaggio"; per-type labels; no countdown widget anywhere (no `Timer`/`Ticker` in the paper) | unit + widget | `flutter test test/models/quest/quest_state_label_test.dart test/screens/mainScreen/tabs/map/quest_paper_layer_test.dart` | Wave 0 |
| all | Shell provides `QuestAcceptanceCubit` | widget | `flutter test test/screens/auth/authenticated_shell_test.dart` | exists, extend |
| all | Schema check lists `AcceptQuest` (+ `GetCity`) and every document validates against BE `origin/develop` | unit + scripted | `flutter test test/tool/schema_check_documents_test.dart` + commands below | exists (auto-enforces) |
| E2E | Board in a city / disabled outside; families; tear + haptics; torn-for-others; lanes; each error banner; Map paper + label | manual | UAT recipe with BE handoff §8 data | manual-only (needs device + BE) |

### Schema check (last plan)
```bash
cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide
SCRATCH=$(mktemp -d)
git -C /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE show origin/develop:src/schema.gql > "$SCRATCH/schema.gql"
dart run tool/schema_check/dump_documents.dart "$SCRATCH/docs"
NODE_PATH=/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/node_modules \
  node tool/schema_check/validate_documents.js "$SCRATCH/schema.gql" "$SCRATCH/docs"
```
Expected: all `OK` (27 today; 28/29 after this phase). Run it **after BE Phase 8 is merged**; before that the slot/object selections intentionally fail (measured).

### Sampling Rate
- **Per task commit:** the task's test file(s) + `flutter analyze <touched files>` + `dart format --output=none --set-exit-if-changed <new/clean touched files only>`.
- **Per wave merge:** quick run command above.
- **Phase gate:** full `flutter test` green (>= 1006 + new), `flutter analyze` <= 56 / 0 errors, schema check all `OK` against BE `origin/develop`, manual E2E done on the device, before opening the PR.

### Wave 0 Gaps
- [ ] `test/helpers/fixtures/quest_fixtures.dart` (Phase 8-shaped quest/lane/character JSON + one legacy variant).
- [ ] `test/helpers/mocks.dart`: `MockQuestAcceptanceRepository`, `MockQuestAcceptanceCubit`, `MockInAppNotificationsCubit` (if not yet present), reuse `MockAuthCubit`, `MockCharacterCubit`, `MockQuestCubit`, `MockMainScreenCubit`.
- [ ] A tiny SVG seeding helper for widget tests (extract from `satchel_menu_test.dart`) so every sheet/paper test can `seedSvgCache(urls)`.
- [ ] A haptic recorder helper (Code Examples) in `test/helpers/`.
- [ ] Probe (manual, recorded in the plan summary): the final `quests` and `city(id)` documents against a running BE with the UAT data (G1/G2).
- [ ] REQUIREMENTS/ROADMAP amendments committed in the first plan; traceability QUEST-01..07 -> Phase 6.
- [ ] Failing-first tests for every row above before its implementation (TDD).

## Security Domain

`security_enforcement` is not disabled in `.planning/config.json`; applicable subset for a client-side gameplay mutation:

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (inherited) | existing bearer link + silent refresh; the mutation uses the authenticated client; `UNAUTHENTICATED` handled by the session flow |
| V3 Session Management | yes (inherited) | `AuthenticatedShell` keyed by character id closes the cubit on session change; `SafeEmit` drops late responses |
| V4 Access Control | yes | BE is authoritative and owner-only (`FORBIDDEN` even for the innkeeper); the FE sends only the **session's own** `currentCharacter.id`, never a user-typed id; client-side eligibility is advisory |
| V5 Input Validation | yes | typed GraphQL variables (`$request: AcceptQuestRequest!`), never string interpolation of ids into documents; ids come from server data; defensive parsing of hand-edited catalogue data (`tryFromJson`) |
| V7 Error Handling and Logging | yes | domain copy from `extensions.code`, never the server message or a stack trace in the UI; log only quest ids (no payloads, no tokens) |
| V6 Cryptography | no | - |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tampered client claims an eligible state (bypasses the blocked swipe) | Tampering / Elevation | BE re-validates everything (lane, title, city, rank slots, points) and debits atomically; FE never trusts its own classifier |
| Double submit / replay of the mutation | Tampering | FE ignores gestures while `QuestAccepting`; BE claim is conditional (`QUEST_SLOT_BUSY`/`QUEST_ALREADY_TAKEN`) |
| Acting for another character | Spoofing / Elevation | `id` always from `CharacterLoaded.character.id`; BE `FORBIDDEN` otherwise |
| Information leak through error text | Information disclosure | map codes to fixed Italian copy; unknown -> generic line |
| Malformed catalogue entry crashes parsing (availability) | Denial of service | tolerant per-quest parse |

## Sources

### Primary (HIGH confidence)
- Local code read this session: all files named in "Current code inventory", `main_screen.dart`, `world_map.dart`, `quest_info_overlay.dart`, `quest_markers_layer.dart`, `character_marker_layer.dart`, `satchel_menu.dart`, `menu_item.dart`, `menu_background.dart`, `menu_section.dart`, `satchel_layout.dart`, `authenticated_shell.dart`, `in_app_notifications_cubit.dart`, `push_event.dart`, `notification_category.dart`, `notification_tap_router.dart`, `kg_notification_banner.dart`, `graphql.dart`, `graphql_error_code.dart`, `character_deletion_*`, shop files, `tool/schema_check/*`, `test/helpers/*`, `pubspec.yaml`/`pubspec.lock`.
- BE: `.planning/phases/07-quest-lanes-quest-04/BACKEND-NOTES.md`; `.planning/phases/08-travel-lifecycle-travel-01/08-CONTEXT.md` (D-02, D-15, D-19, D-26..D-30); `src/schema.gql` at `origin/develop` (`e5786eb`); `src/quests/quests.service.ts`, `quests.resolver.ts`, `src/cities/cities.service.ts`, `src/models/quest/*`, `src/models/point-of-interest.model.ts`, `src/models/common/asset-quantity.model.ts`, `src/quests/acceptance/quest-lanes.ts`.
- Measured: `flutter test` (1006 passed), `flutter analyze` (56), `dart format --set-exit-if-changed` per file, `tool/schema_check` (27 OK) and two probe documents against the BE schema with graphql 16.11.0.
- Flutter SDK 3.35.5 source: `lib/src/services/haptic_feedback.dart`, `lib/src/widgets/page_view.dart:975` (`cacheExtent: 0.0` when `allowImplicitScrolling` is false).

### Secondary (MEDIUM confidence)
- https://docs.flutter.dev/ui/interactivity/gestures - gesture arena, horizontal vs vertical drag disambiguation (the nested-scroll answer is general Flutter behaviour, not stated verbatim on the page).
- Flutter engine `PlatformPlugin.java` (tag 3.35.5) - haptic type to `performHapticFeedback` constant mapping.

### Tertiary (LOW confidence)
- Wire behaviour of unpopulated refs (G1) and `city(id)` payload (G2): inferred from BE source, to be confirmed by the Wave 0 probe.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependencies, versions from the lockfile.
- Architecture: HIGH for the repository/cubit/banner/navigation facts (read from code); MEDIUM for the tear geometry (provisional by decision) and for fullness-per-rank (A1).
- Pitfalls: HIGH for FE-side ones (measured/read); MEDIUM for G1/G2 (BE source only).
- BE Phase 8 contract: MEDIUM - taken from CONTEXT, not implemented.

**Research date:** 2026-10-21
**Valid until:** 2026-11-04 (14 days; the BE Phase 8 contract and G1/G2 are in flux - re-read BE `08-CONTEXT.md`/`schema.gql` before the last plan)
