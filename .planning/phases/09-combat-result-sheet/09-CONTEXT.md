# Phase 9: Combat Result Sheet - Context

**Gathered:** 2026-10-27 (interactive discuss; the BE companion Phase 9.2 was inserted in the same session)
**Status:** Ready for planning (**no UI phase**, same rule as Phases 6, 7 and 8: every visual Claude builds is provisional and will be reworked by the user). The plans that select the BE Phase 9.2 fields and the final gate wait for the BE 9.2 PR (D-09, D-21); everything else can start now.
**Amended:** 2026-10-27 after the research (conflicts C1–C10 of `09-RESEARCH.md`) and two user answers of the same day (death with the app closed; death in the queue): D-03, D-07, D-08, D-09, D-10, D-12, D-13, D-14, D-16, D-21; D-23 and D-24 added. This CONTEXT is authoritative over the RESEARCH where they differ — in particular there is **no routing hold**: the BE Phase 9.2 keeps `User.currentCharacter` on the dead character until the acknowledgement (D-13).

<domain>
## Phase Boundary

When a quest resolves, the player sees a full-screen parchment with the outcome: HP before and after animated against the maximum, consumables and spells used, injuries received, rewards (coins and items), XP with the level and title changes, the spell learned and the number of adventurers saved. The sheet is dismissed only with an explicit button and is presented only on the Map tab (user rule, D-06): from anywhere else the in-app banner takes the player there. Several results queue in `resolvedAt` order. Three sources feed one queue: the subscription `questResultReceived(characterId)` in foreground, the `questEnd` push in background or killed state (`data.id` = result id → `questResult(id)`), and the BE Phase 9.2 query of the unacknowledged results at cold start, resume and reconnection, so no sheet is ever lost; every closed sheet is acknowledged on the backend.

The phase also delivers the three consequences of an outcome that earlier phases left to it: the death flow (sheet first, then the character-creation page — Phase 3 D-09), the «in attesa di soccorso» state on the Map (label on the pawn, pawn drag, Board and Shop disabled — Phase 7 deferred item), and the `aid` quest shown with the combat sheet family on the Board (Phase 6 D-09 amended).

Out of scope: the innkeeper queue and `completePendingRequest` (Phase 10), the combat formula and the injury rules (BE placeholders, owned by the user), a history of past results (deferred), any Board change beyond the `aid` family, iOS, the pet/mount UI.

</domain>

<decisions>
## Implementation Decisions

### Sheet anatomy (COMBAT-01..06)
- **D-01 (user decision):** a **full-screen parchment overlay on the root Navigator**, built with the `PaperSheetModal` / `QuestInfoSheet` language (existing Cloudinary parchment SVGs, dimmed scrim, no AppBar) — not a dedicated route, not a Map layer. The shell stays alive underneath: subscriptions, banners and the queue cubit keep running while the sheet is open.
- **D-02 (user decision):** HP delta = **life bar plus counting numbers**: the bar animates from `hpBefore` to `hpAfter` against `maxLifePoints` (the maximum **after** the outcome, BE §3: the bar grows on a level up) with the numbers scrolling in step; `TweenAnimationBuilder` (ui-ux.md), red ink for a loss, green for a gain (`heal` restores the maximum). The dismissal button is enabled from the start: the animation never blocks the player (whether a tap skips it is Claude's call).
- **D-03 (user decision):** content, in this provisional order: header with `quest.title`, the Italian label of `quest.type` (**amended, C2:** Phase 6 has only state labels — add `QuestType.label` with the provisional copy of RESEARCH F12; an unknown wire type shows no label line) and `resolvedAt`; enemy name and, only where the image already resolves as in the Phase 6 combat sheet, its image (`enemy { id name imagePath }`, section hidden when `null`; never select `enemy.locations`, BE §14; research A4: BE image paths are not resolvable today, so the name alone is the expected result); the HP block; `injuriesAdded` rendered with the Italian labels of the 28 `InjuryType` values (**amended, C1:** `InjuryTypeExtension.label` already exists with all 28 and the names match the BE enum — reuse it; COMBAT-04 is delivered by the sheet rendering plus a pinning test of the 28 labels and of the name parity); `consumablesUsed` and `spellsUsed { usages spell { id name } }` (an entry with `spell: null` reads «Magia sconosciuta»); `rewards.coins` (`CoinsDisplay`) and `rewards.items` (`ItemRow`, `ItemUnion` inline fragments as the inventory); `xpBefore`, `xpGained`, `xpAfter`; «Livello 3 → 4» and «Avventuriero → Paladino» only when they change; `spellLearned { id name }`; «Hai salvato N avventurieri» from `rescuedCharacters.length` (user: **the number only**, no names).
- **D-04 (user decision):** **one widget for the five outcomes**: the header and the ink colour change per `outcome` («Vittoria», «Sconfitta», «Sei stato salvato», «È morto», «Missione completata» for `gmCompleted`; copy provisional); a section with no data is not built (no rewards on `failure`, before = after on `rescued` and `death`).
- **D-05 (user decision):** dismissal = **one explicit button at the bottom of the parchment** («Continua»; «Riposa in pace» on death). Tap on the scrim, Android back (`PopScope`) and any swipe are ignored (COMBAT-06).

### Delivery, queue and never-lost results (COMBAT-01, COMBAT-07, COMBAT-09)
- **D-06 (user, verbatim 2026-10-27):** *«Il foglio risultati si vede solo una volta entrati nel tab mappa, per sicurezza. Cliccare sul banner che ti avvisa della fine della missione ti porta sul tab mappa a e apre la sheet del risultato».* The sheet is presented only while the Map tab is the visible page. From any other tab the player gets the in-app banner; its tap lands on the Map through the Phase 5 router and opens the sheet through the `questEnd` entry of `defaultNotificationPopups`.
- **D-07 (user decision):** if the player is **already on the Map** when a result arrives, the sheet opens at once, **without a banner**, provided the Map is free: no route above the shell (parchment sheets, dialogs, travel confirmation, abandon sheet, quest/item/spell sheets), no quest paper overlay open, no pawn drag in progress. Otherwise the queue retries at every change (route popped, overlay closed, drag ended, page changed). Results pending in the queue open by themselves when the player enters the Map. **Amended, C6:** the foreground FCM push would still produce a banner, so when a sheet opens at once the presenter calls a new `InAppNotificationsCubit.suppress(dedupKey)` (marks `questEnd|<id>` as seen for the personal dedup window and drops a queued or current banner with that key); the FE publishes the banner only when the sheet cannot open at once.
- **D-08 (user decision):** several results (group boss, rescue chain, reconciler at boot) → **FIFO by `resolvedAt`, one sheet at a time**: the button closes the current sheet and the next one opens; a «1 di 3» counter at Claude's discretion. **User decision 2026-10-27 (research A2):** a `death` result in the queue **unlocks the whole queue** — every sheet ahead of it opens at once in `resolvedAt` order on any tab, then the death sheet.
- **D-09:** three sources feed **one queue keyed by result id** (dedup): (a) the subscription `questResultReceived(characterId)`, opened with the shell for the whole session like `characterUpdated` (silent resubscribe of Phase 3; `FORBIDDEN`/`NOT_FOUND` are terminal → stop silently, the query covers the rest); (b) the `questEnd` push tap → `questResult(id)` (BE §4: `data.id` is the **result id**; the Phase 5 handoff note that said pendingQuestId is superseded); (c) **BE Phase 9.2** `unacknowledgedQuestResults`, read at cold start (shell bootstrap, after `me`), on resume (`AppLifecycleBridge`) and after a WS reconnection (**amended, F11:** no public reconnection signal exists — add a `ConnectionRestoredBus` fed by `SessionSyncCubit`) — results of the **user**, so a `death` result survives the archive of its character; at a cold start after a death this query is the source of the death sheet (D-13). Results read from this query get no banner: they open on Map entry (D-12). Lost pushes, force-stop and disabled notifications never lose a sheet.
- **D-10 (user decision):** **acknowledgement at close**: pressing the button calls `acknowledgeQuestResult(id)` (BE 9.2), best-effort (retried on the next resume; a failure never blocks the UI). Ids shown or acknowledged are kept in memory for the session as a local dedup; a sheet opened but never closed (app killed) comes back at the next start. **Amended, C4:** the 9.2 documents cannot live in `lib/graphql/` before the gated plan (the registry test requires every named operation to be registered), so the queue cubit is coded against two Flutter-free ports — `PendingQuestResults.fetchUnacknowledged()` and `QuestResultAcknowledger.acknowledge(id)` — with fakes, and the shell composes null-object implementations (`[]` / no-op, pattern `NoopPushMessaging`) until the gated plan swaps in the repository. **For a `death` result the acknowledgement is not best-effort:** the button awaits it; on failure the sheet stays open with an error ink and a retry (button again, or automatically at resume), because only the acknowledgement releases the dead character (D-13).
- **D-11 (user decision):** a `questEnd` tap for a result already acknowledged → **Map tab only, no sheet**; an id unknown locally → `questResult(id)`; `NOT_FOUND`/`FORBIDDEN` → domain banner («Risultato non disponibile», provisional), network error → silent, covered by the resume refetch. Nothing is ever rebuilt from the push payload (rule 4).
- **D-12 (user decision):** the FE **publishes the in-app banner itself from the subscription event** with the dedup key `questEnd|<resultId>` and the **generic BE copy** («Missione conclusa» / «La tua missione è terminata: scopri com'è andata.», the same strings as the push, kept in one place); the foreground push with the same type and id is deduplicated by the existing `InAppNotificationsCubit` rule. The «fine quest» toggle silences the system notification and the banner (Phase 4/5 rule) but **never the sheet**, which still opens on the Map (F4: the banner goes through `publish(PushEvent)` with the toggle read from `NotificationPreferencesCubit`).

### Death, rescue and the wounded state (COMBAT-08)
- **D-13 (user decision 2026-10-27, revised after the research — supersedes the routing hold):** asked how to guarantee «prima il foglio, poi la creazione» even when the app was killed during the death, the user wrote *«Non puoi settare currentCharacter a null solo quando ricevi la conferma di presa visione del risultato?»* and chose **«BE: currentCharacter resta sul morto fino alla conferma»**. The BE Phase 9.2 (its D-12) keeps `User.currentCharacter` on the dead, archived character until `acknowledgeQuestResult` of the `death` result, which unlinks it in the same transaction; only then `userUpdated` carries `currentCharacter: null` and `SessionHome` routes to the creation page exactly as today. The Phase 3 D-10 pop of the root routes on a character change stays where it is: the death sheet is already closed when the character changes, so research C3/C10 are void and there is **no hold and no cap**. Consequences: (a) the death sheet opens on any tab as soon as the root Navigator is free (it unlocks the queue, D-08) and its button **awaits** the acknowledgement (D-10) — the creation page is reachable only after it (the BE refuses `createCharacter` until then); (b) at a cold start after a death the shell boots with the dead character still current: `character(id)`, `characterUpdated` and `questResultReceived` answer `NOT_FOUND` (Phase 3.1 invisibility) — the `CharacterCubit` treats a terminal `NOT_FOUND` on a character that `me` still reports as current as a quiet «character unavailable» state (no error UI, no refresh loop, at most one `requestUserRefresh`, last loaded state kept if any) and the unacknowledged query (D-09) delivers the death sheet within moments; (c) a push tap at that point lands on the Map as usual (the intent is no longer dropped, the character is current). This closes research C9 (cold start after a death) by design.
- **D-14 (user decision):** the death sheet is the **same widget with dark ink**: header «È morto», name, title and level of the dead character (**amended, C7:** `QuestResult` carries no name — taken from the last `CharacterLoaded` state when `result.character` is the shell's character; a historical sheet shows no name; title and level from `titleAfter`/`levelAfter`), the aid as quest, injuries, no rewards; button «Riposa in pace» → acknowledgement → creation page (D-13).
- **D-15 (user decision):** `rescued` → same widget, header «Sei stato salvato», quest = the aid, no rewards, before = after; after the button the pawn is already in the city (from `characterUpdated`).
- **D-16 (user decision):** wounded state (`status.awaitingAid != null`, after a `failure`): the label «In attesa di soccorso» floats over the pawn in the place of the travel remaining-time label; pawn drag, Board and Shop are disabled with the darker satchel cell exactly like the travel rule (Phase 7 D-12, `disabledSatchelPages`); journal, lore and sheets stay readable; `AWAITING_AID` and `SHOP_NOT_IN_CITY` are mapped in the travel, acceptance and shop failure classifiers to a banner (copy provisional) should the BE refuse anyway. `awaitingAid { quest aidQuest since }` joins `CharacterStatus` and `CharacterFragment` (additive, already on BE `develop`). **Amended, C8:** the shop has no failure classifier (`doTransaction` throws a plain `Exception` and drops the code): add `lib/repository/transaction_failure.dart` (`shopNotInCity`, `connection`, `unknown`, …), rethrow the `OperationException` from the service, type `TransactionError` with the failure, banner via `publishNotice` for `shopNotInCity` (speech bubble kept for the rest), `bloc_test` for `TransactionCubit`. The pawn must stop being draggable while wounded: `_canStartTravel` also checks `awaitingAid` (the quest lane is emptied after a failure, so the travel rule alone does not block it).
- **D-17 (user decision):** the `aid` quest («Soccorso: …») moves from the service family to the **combat family** of the Board sheet (Phase 6 D-09 amended): enemy, time, rank slots, party counter k/N, abandon while waiting; free (`requiredPoints: null`, no cost line).
- **D-18 (user decision, 2026-10-27):** started quests stay torn on the Board until they conclude — user: *«finché una missione non è conclusa il foglio resta strappato sulla board una volta che i posti sono pieni (e che quindi la quest è cominciata)»*. The edge case of a seat freed after the start (a participant deletes the character or dies) is closed **by the BE in Phase 9.2** («Il BE non libera i posti delle quest avviate»): the archive keeps the registration as a placeholder, the seats stay full and the Phase 6 torn-when-full rule holds unchanged. **No FE change** beyond the existing rule; the k/N counter may show the placeholder seat.

### Map availability and the sheet mechanism (research F1/F5/F9)
- **D-23:** «Map visible and free» is not modelled today (current page, quest overlay and pawn drag are local widget state): a shell-level `MapAvailabilityCubit` (Flutter-free state, written by `MainScreen` for the page, `WorldMap` for the quest overlay, the marker layer for the drag, and the root route stack via `ModalRoute.isCurrentOf`/a navigator observer) is the single signal the queue listens to. The presenter uses `showGeneralDialog(useRootNavigator: true, barrierDismissible: false)` with `PopScope(canPop: false)` (probe: scrim tap, Android back and swipe are ignored, the button returns `true`); an external pop (session end) returns `null` → the result is requeued, never acknowledged.
- **D-24:** the `aid` quest moves to the combat family in `quest_sheet_details.dart` (one-line change plus the inverted test), D-17.

### Process and quality
- **D-19:** **No UI phase, no UI-SPEC** (Phase 6/7/8 D-19 carried forward): everything visual is provisional, token-based (`kg_theme.dart`), existing parchment assets only (`emptySheet`, `bottomEmptySheet`), no new Cloudinary assets.
- **D-20:** **TDD red → green → refactor:** unit tests for the `QuestResult` parsing (all five outcomes, null enemy/spell, orphan items, optional `acknowledgedAt`), the queue (FIFO by `resolvedAt`, dedup by id, Map-only gating, death exception, ack retry), the delivery coordinator with fakes (subscription, push intent, unacknowledged query), the quiet «character unavailable» state and the awaited death acknowledgement, the injury labels, the awaiting-aid derivations (label, disabled pages, failure codes); widget tests for the sheet (sections per outcome, HP animation end state, button-only dismissal, `PopScope`), the pawn label and the Board `aid` family; `flutter analyze` with no new issues; `dart format` only on touched files (Phase 11 D-38); `tool/schema_check` against `git -C <BE> show origin/develop:src/schema.gql` in the final plan.
- **D-21:** the FE develops against the BE 9.2 contract proposed in `BACKEND-NOTES.md` of this phase with fakes and recorded `QueryResult`s (pattern of Phases 3–8); `QuestResult.fromJson` treats `acknowledgedAt` as optional. The plans that register the `UnacknowledgedQuestResults` / `AcknowledgeQuestResult` documents in the schema-check registry and the device E2E run **after** the BE 9.2 PR is merged on BE `develop` (same gate pattern as 08-12). BE PR before FE PR. **Amended, C5:** the `ItemUnion` branches of the result fragment select `EquipmentFragment.simpleFields` / `LootFragment.simpleFields` plus `description effect power` (the BE example fragment would turn equipment rewards into loot because `AssetItem.fromJson` discriminates on `equipType`); the fragment, `OnQuestResultReceived` and `GetQuestResult` already pass `tool/schema_check` against BE `10e5f43`; expected gate result after the 9.2 merge: 38/38 documents (34 today).
- **D-22:** Boy Scout within scope: the Phase 5 FE handoff note «`questEnd.id` = pendingQuestId» is corrected to the result id; the comment in `NotificationCategory` about a «future `combatResult`» goes (no such push type exists, BE §4); nothing else outside the touched lines.

### Claude's Discretion
- Animation durations and whether a tap skips the HP animation (D-02); the «1 di 3» counter (D-08); where the queue cubit and the delivery coordinator live (provided by `AuthenticatedShell` like `TravelCubit`, listener mounted in `MainScreen` next to `SpellOutcomeListener` — the pattern is fixed, names and split are free); the internals of `MapAvailabilityCubit` (D-23); the retry affordance of the death acknowledgement and the retry policy of the other acks and of the unacknowledged refetch (D-09/D-10); header and button copy, ink colours (provisional); the Italian injury labels (D-03); haptics on sheet open; how `resolvedAt` is formatted.

</decisions>

<specifics>
## Specific Ideas

- The user's verbatim rules of 2026-10-27 are quoted in D-06 and D-18; every answer is recorded in `09-DISCUSSION-LOG.md`.
- Two more user answers after the research (2026-10-27): death with the app closed → *«Non puoi settare currentCharacter a null solo quando ricevi la conferma di presa visione del risultato?»* → «BE: currentCharacter resta sul morto fino alla conferma» (D-13, BE 9.2 D-12); a `death` behind other sheets → «La morte sblocca tutta la coda» (D-08).
- Three recommended options were overruled by the user: the banner uses the **generic BE text** (not per-outcome copy, D-12); the rescuers' sheet shows the **number** of saved adventurers (not their names, D-03); the started-quest edge case is closed **by the BE keeping the seats** (not by an additive `startedAt` field, D-18).
- The ROADMAP question «does `combatResult` carry the full payload or a result id?» is answered by the BE Phase 9 handoff: the subscription carries the full payload, the push only the result id, and no `combatResult` type exists.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Backend contract consumed (BE Phase 9, merged on BE `develop`)
- `../Klimmeck-Guide-BE/.planning/phases/09-combat-result-admin-outcomes/BACKEND-NOTES.md` — §0 TL;DR, §1 SDL (`QuestResult`, `QuestOutcome`, `questResult`, `questResultReceived`, the example fragment), §2 codes (`NOT_FOUND`/`FORBIDDEN` on `questResult` and `questResultReceived`, `AWAITING_AID`, `SHOP_NOT_IN_CITY`), §3 outcome semantics and delivery rules (no snapshot, queue by `resolvedAt`, death ordering), §4 push `questEnd` (`data.id` = result id), §5 lifecycle, §6 rescue and death, §7 progression (level table, titles), §12 UAT data, §13 deferred UAT checklist, §14 notes (`enemy.locations` bug, no results list), §16 open points.
- `../Klimmeck-Guide-BE/src/schema.gql` on `origin/develop` — the schema wins over every note.

### Backend companion (BE Phase 9.2, proposed by this phase)
- `.planning/phases/09-combat-result-sheet/BACKEND-NOTES.md` — the FE proposal: `unacknowledgedQuestResults`, `acknowledgeQuestResult`, `QuestResult.acknowledgedAt`, seats kept on started quests; the FE behaviour the BE must know.
- `../Klimmeck-Guide-BE/.planning/phases/09.2-quest-result-delivery-contract/09.2-CONTEXT.md` — the BE decisions that fix the contract.

### Prior FE decisions carried forward
- `.planning/phases/03-real-time-sync-foundation/03-CONTEXT.md` — D-09 (`currentCharacter: null` → creation page) and the deferred note «routing hold until the Combat Result Sheet is dismissed» (D-13 here).
- `.planning/phases/05-notifications-infrastructure/05-CONTEXT.md` — D-04 (payload), D-15 (intent and Map landing), D-16/D-17/D-18 (banner model and dedup); `.planning/phases/05-notifications-infrastructure/BACKEND-NOTES.md` §3 (popup registry hook, banners from subscriptions) and §5 (UAT matrix).
- `.planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md` — D-08/D-09 (sheet families, torn rules), D-15 (state label), D-19/D-20 (no UI phase, banner by code).
- `.planning/phases/07-travel/07-CONTEXT.md` — D-10 (server-time labels), D-12 (pawn drag, Board and Shop disabled during a travel), D-15 (`travelEnd` popup entry).
- `.planning/phases/08-spells-section-journal-tab/08-CONTEXT.md` — D-16/D-17 (shell-provided cubits, outcome listener in `MainScreen`, failure classifier by `extensions.code`).

### Rules
- `docs/rules/ui-ux.md` — immersive gameplay, no blocking loading, dialogs/sheets, animations.
- `docs/rules/state-management.md`, `docs/rules/architecture.md`, `docs/rules/naming.md`, `docs/rules/graphql.md`, `docs/rules/testing.md`, `docs/rules/workflow.md`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/shared/components/modal/paper_sheet_modal.dart`, `lib/shared/components/popup/quest_info_sheet.dart`, `equipment_info_sheet.dart`, `spell_info_sheet.dart` — the parchment language and the sheet animation patterns (D-01).
- `lib/shared/components/kg_notification_banner.dart` + `lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart` (`publish(PushEvent)`, `publishNotice`, `open`, dedup by `(type, id)`) — the banner (D-12).
- `lib/models/push_event.dart`, `lib/models/notification_intent.dart`, `lib/models/notification_category.dart` (`questEnd` already parsed, toggleable and routed) — push and tap (D-09, D-11).
- `lib/screens/mainScreen/components/notification_popup_registry.dart` (`defaultNotificationPopups`, only `travelEnd` today) + `notification_intent_landing.dart` (pops to the first route, jumps to the Map page, calls the popup) — the `questEnd` entry (D-06).
- `lib/screens/mainScreen/tabs/map/mapFocusCubit/` — the «request served by the map» pattern (D-07).
- `lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart`, `quest_info_overlay.dart`, `components/travel_confirmation_sheet.dart`, `abandon_party_sheet.dart` — the overlays that make the Map «busy» (D-07); the travelling pawn with its floating remaining-time label (Phase 7 plan 07-10) — the awaiting-aid label (D-16).
- `MainScreen.disabledSatchelPages` (Phase 7 D-12) — Board/Shop disabled (D-16).
- `lib/models/enums/injury_type.dart` (28 values, same names as the BE enum) — labels (D-03); `lib/models/enemy.dart`, `asset_quantity.dart`, `coins.dart`, `spell.dart` — reused by `QuestResult.fromJson`.
- `lib/shared/components/` `ItemRow`, `CoinsDisplay`, `CachedSvg` — reward rows and the enemy image (D-03).
- `lib/repository/` failure classifiers (`travel_failure.dart`, `quest_acceptance_failure.dart`, `spell_equip_failure.dart`) — the pattern for `AWAITING_AID`/`SHOP_NOT_IN_CITY` and the result lookup failures (D-11, D-16).
- `ServerClockService` (Phase 7) — `resolvedAt` display if needed; `tool/schema_check` registry — new documents (D-21).

### Established Patterns
- Cubits that must survive a tab change are provided by `AuthenticatedShell`; outcome listeners (banner + sync) are mounted in `MainScreen`; the UI never builds state from a mutation response.
- `CharacterCubit` resubscribes silently; `FORBIDDEN`/`NOT_FOUND` on a stream are terminal.
- `SessionHome` routes on `currentCharacter` and keys the shell by character id (Phase 2/3) — unchanged by D-13: the creation page follows the `userUpdated(null)` that the BE emits at the death acknowledgement.
- The BE contract is developed against fakes and recorded `QueryResult`s; the final plan runs the schema check against BE `origin/develop`.

### Integration Points
- `AuthenticatedShell` (new providers), `MainScreen` (listener, current page, `disabledSatchelPages`), `SessionHome` (unchanged, routes on `userUpdated(null)` after the death acknowledgement), `WorldMap` (pawn label, drag gating, busy state), the Board sheet families (`aid`), `CharacterStatus` + `CharacterFragment` (`awaitingAid`), `KlimmeckGraphQl` / repositories (new documents), `notification_popup_registry.dart` (`questEnd`).

</code_context>

<deferred>
## Deferred Ideas

- **Result history** («ultimi esiti» page) — backlog; BE §14 YAGNI, `unacknowledgedQuestResults` is not a history.
- **Names of the rescued adventurers** on the rescuer's sheet — the user chose the number (2026-10-27); an additive BE field if wanted later.
- **Per-outcome banner copy** («Vittoria: …») — the user chose the generic BE text; revisit after the UAT.
- **Dedicated tombstone parchment** for the death — the user chose the shared widget; asset later.
- **Return to the city after a success** — a free travel chosen by the player (BE §5): nothing to build.
- **Sound or haptics on sheet open** — no requirement; Claude's discretion if cheap.

</deferred>

---

*Phase: 09-combat-result-sheet*
*Context gathered: 2026-10-27*
