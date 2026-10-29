# Phase 10: Admin Panel (innkeeper) - Research

**Researched:** 2026-10-29
**Domain:** Flutter utility route on the root Navigator + route-scoped GraphQL subscription + admin mutations + a teleport mode on the existing flutter_map world map
**Confidence:** HIGH (every claim below is read from the FE code on `feat/10-admin-panel`, the BE `origin/develop` schema `8f30d1d`, the BE handoffs, or probed in a throwaway test that has been deleted)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Access and structure (ADMIN-01)
- **D-01 (user decision):** the panel is reached **from Settings**: a section «Locanda» rendered only when the session user has `role == innkeeper` (read from the `AuthCubit` user, live through `userUpdated`: the section appears or disappears with the role), with one button that **pushes a full-screen route on the root Navigator**. It is a utility surface (Phase 4 precedent): `Scaffold`, `AppBar` with the title «Locanda» and the back arrow, Material controls are allowed; parchment background and `kg_theme.dart` tokens only. The satchel grid, `SatchelLayout` and the `PageView` do not change (the 4×2 grid is full: Mappa spans two rows, seven entries fill eight cells).
- **D-02 (user decision):** **the innkeeper always has a character**: the streamer plays like everybody else, the character-creation page stays mandatory and unchanged (Phase 4 D-03 holds: nothing is reachable from the creation page), the panel lives inside the authenticated shell. No shell without a character, no special boot path.
- **D-03 (user decision — «Solo la coda»):** the panel is **one screen with one list: the queue**. No «Personaggi» tab, no standalone teleport tool: the teleport action lives on a participant row of the queue, so **a character without a pending story/worldMission request is not teleportable from the panel** (ADMIN-04 amended). A list of all characters is a deferred idea.
- **D-04 (technical default):** the route lives on the root Navigator outside the shell providers (Phase 7 Pitfall 5): the queue cubit is created for the route (subscription opened when the panel opens, closed when it pops) and the Map hand-off of the teleport goes through a shell-level cubit (D-15/D-17); a lost role (`FORBIDDEN` at subscribe or `userUpdated` without `innkeeper`) pops the panel silently. Naming and split per `docs/rules/naming.md` and `docs/rules/architecture.md` (planner).

#### The queue (ADMIN-02)
- **D-05 (user decision):** **one card per quest** (entries grouped by `quest.id` within the same lane): a story card has one participant; a worldMission card lists the registered participants with the seats «k/N» (sum of `requiredAdventurers[].count` vs the entries). One «Completa» per card = one `completePendingRequest(pendingQuestId)` call with the `PendingRequest.id` of the first entry (the BE closes the request for every registered participant, BE §9).
- **D-06 (user decision):** a participant on a **free travel** (city to city) stays visible, **greyed**, with «In viaggio» and the remaining time (from `activeTravel.endTime` against the server clock, `ServerClockService` + `formatGameDuration`); the card's «Completa» is **disabled while any listed participant travels**. User clarification (verbatim, 2026-10-29): *«story e worldMission non richiedono alcun viaggio»* — confirmed by the BE (`quest-acceptance.service.ts`: automatic travel only for the standard lane), so a travelling participant is always on a free travel and arrives at a city marker. Once `endTime` has passed the row reads «Arrivato» even before the next emission (the BE queue does not re-emit on arrival; D-18).
- **D-07 (user rule, verbatim 2026-10-29):** *«Nessun personaggio che ha accetato una quest, che sia in viaggio o in combattimento, non deve comparire nella lista dei pending che l'admin può gestire. Se sei in viaggio da una città all'altra invece questa regola non vale»*, clarified as: a character whose **standard lane is occupied** (`quests.pendingQuest` set — travelling to that quest or in its waiting time/combat) **is not shown** in the queue; a free travel does not hide him (D-06). The queue entry does not carry the standard lane today: the **BE Phase 10 (BE-HARD-08, user decision)** adds the additive field `PendingRequestCharacter.pendingQuest: ID` (null when the lane is free) and makes `completePendingRequest` refuse with `QUEST_IN_PROGRESS` while any registered active participant has the lane occupied (proposal in `BACKEND-NOTES.md` §2). FE rule: a story card whose character is busy disappears; a worldMission card drops the busy participant from its list, shows «k presenti su N registrati» and keeps «Completa» disabled with the caption «Un partecipante è impegnato in una missione» until the lane frees (**technical default derived from the user rule — listed in the summary for veto**). Until the BE field lands the rule is coded against the proposed field with fakes (D-24).
- **D-08 (user decision — «Minime»):** each participant row shows only the **character name and the state** («Presente» / «In viaggio · 12 min» / «Arrivato» / «In attesa di soccorso» from `awaitingAid`); the card header shows the **quest title** and its Italian type label (`QuestType.label`, Phase 9) plus the seats for a worldMission. User, points spent, location name, HP and injuries are **not** on the card: everything else lives in the completion form (D-11).
- **D-09 (user decision):** **BE order** (`startDate` ascending, travellers last, then id; a card takes the rank of its earliest entry) and an **empty state on parchment**: «Nessuna richiesta in attesa» with the note «La coda si aggiorna da sola».
- **D-10 (technical default):** the source is the **subscription `pendingRequestsUpdated`** (innkeeper-only; snapshot at subscribe, then the full list at every PendingQuest insert/delete, BE §9), opened by the route's cubit with the Phase 3 reconnection policy (silent resubscribe, snapshot replaces the list); the query `pendingRequests` is the **refetch** used by D-18. A loader is allowed when the panel opens until the first snapshot (explicit user action, rule 2); after that the list only replaces itself, never shows a spinner. Entries are parsed item by item (a malformed entry is skipped with a debug log, the list survives — Phase 9 IN-04 lesson).

#### Completion and the account of the fight (ADMIN-03, ADMIN-05, ADMIN-06)
- **D-11 (user decision — «Sempre il form»):** one action per card, «Completa», opens the **completion form** with a section per listed participant; the defaults mean «no change» (HP = current, no new injury, nothing used); «Conferma» at the bottom opens the **confirmation dialog** (the shared `DestructiveConfirmationDialog`, or a neutral-styled variant of it at Claude's discretion) with the recap (quest, number of participants, the overrides that differ from the defaults); on «Conferma» the FE calls `completePendingRequest` with `outcomes` **only for the participants whose values differ from the defaults** (an untouched participant is omitted: the BE keeps HP intact, BE §9). No quick path without the form (the recommended two-button variant was overruled).
- **D-12 (user decision):** controls per participant, data loaded with `character(id)` when the form opens (the innkeeper may read any character, BE Phase 3; a loader is allowed here, explicit action): **HP** as a slider `1..maxLifePoints` with the number beside it, default `currentLifePoints`; **injuries** as multi-select chips of the 28 `InjuryType` with the Italian labels of `InjuryTypeExtension.label`, the injuries the character already has shown as inactive chips (the override carries only the injuries **added**); **consumables** as the list of `assets.ownedItems` (loot items) each with a stepper `0..owned`; **spells** as the list of `assets.activeSpells` each with a stepper `0..remaining usages` (from `status.spellStates`). The wire input is `ParticipantOverrideInput { characterId, hpAfter?, injuries?, consumablesUsed? [{ item, quantity }], spellsUsed? [{ spell, usages }] }` (BE §1/§9).
- **D-13 (user decision):** after the mutation returns the created `[QuestResult!]!`, the panel shows a **results recap** per character (outcome label, HP before → after, injuries added, XP gained, level and title only when they change, spell learned) in a sheet or dialog on the panel; the card leaves the list with the next queue emission (an optimistic removal is Claude's call). The Phase 9 full-screen sheet is not reused here: the players get their own sheet on their devices.
- **D-14 (user decision):** errors **per code, inline in the panel** (utility surface: `SnackBar` and inline texts allowed) through a failure classifier like the other repositories: `NOT_FOUND` (completed by a concurrent call or request gone) → the card is removed and «Richiesta non più disponibile»; `QUEST_IN_PROGRESS` (BE-HARD-08) → «Un partecipante è impegnato in una missione», list refetched; `OUTCOME_OVERRIDE_INVALID` / `OUTCOME_NOT_PARTICIPANT` → error under the participant section, form kept; `FORBIDDEN` → the panel pops; network → «Riprova» with the form preserved. No generic in-app banner for these.

#### Teleport (ADMIN-04)
- **D-15 (user, verbatim 2026-10-29):** *«Aprirei la mappa, con la pedina che invece di indicare il mio personaggio, indica il personaggio che ho selezionato. A quel punto posso spostare la pedina a mano»*. Flow: «Teletrasporta» on a participant row → the panel route pops → the shell jumps to the **Map tab in teleport mode** (the tab-jump pattern of `NotificationIntentLanding`): the Map shows **only the selected character's pawn** at its current location (`PendingRequestCharacter.location` is a POI id: the coordinates come from the cities cache when it is a city marker, otherwise from `pointOfInterest(id)` or `character(id)` — researcher), with the character's name floating above it; the innkeeper's own pawn, travel route, labels and quest paper are hidden; the pawn is draggable with the Phase 7 drag (same drop rule: the city containing the release point, else the nearest).
- **D-16 (user decision):** **no confirmation**: on release the FE calls `teleportCharacter({ id: characterId, poiId: city.markerLocation.id })` at once (any POI is accepted by the BE, the drop targets of this phase are the **city markers**, Phase 7 geometry; inner POIs as drop targets are deferred). A chip «Annulla» on the Map leaves teleport mode without calling.
- **D-17 (user decision):** after a successful teleport the Map leaves teleport mode (own pawn back) and **the panel route is pushed again** with the live queue. A failure keeps teleport mode with the error inline on the Map chip («Il personaggio è in una missione in corso» for `QUEST_IN_PROGRESS`, «Personaggio o luogo non trovato» for `NOT_FOUND`, network → «Riprova») and the pawn back at its origin. Teleport mode also ends on tab change, on a lost role and at session end (technical default).
- **D-18 (technical default):** the queue re-emits only on PendingQuest insert/delete, never on a location or travel change of a queued character (BE §9): the panel **refetches `pendingRequests`** after an own teleport succeeds, when a listed travel's `endTime` passes, when the panel is (re)opened and on app resume. No BE change is requested for this (optional emission on location change listed as a question in `BACKEND-NOTES.md`).
- **D-19 (user decision — «Disabilita in anticipo»):** satisfied by the hiding rule D-07: a listed participant never has an occupied standard lane, so the «Teletrasporta» action is shown on every listed row without an extra query; a residual `QUEST_IN_PROGRESS` from a race is handled by D-17. A participant on a free travel can be teleported (the BE clears the travel in the same operation, ADMIN-04).
- **D-20 (user decision):** in teleport mode the innkeeper's **own pawn disappears**: only the selected character's pawn is on the Map, with its name label; no second pawn.

#### Requirements amended by this discuss (recorded in REQUIREMENTS.md)
- **D-21:** ADMIN-02 (standard lane hidden, free travel greyed), ADMIN-03 (complete only, through the form with an explicit confirmation; no reject), ADMIN-04 (from a queue row, by dragging the pawn on the Map to a city marker, no confirmation), ADMIN-05 (no grade, monsters or rewards: overrides of HP, consumables and spells), ADMIN-06 (injuries as chips in the same form). ADMIN-07 and ADMIN-08 are **delivered by the BE** (Phase 3 `@Roles(innkeeper)` + audit interceptor, Phase 9 `completePendingRequest`, Phase 8 `teleportCharacter`): the FE pins the hidden entry for a non-innkeeper with a widget test and the device UAT calls `pendingRequests` as an adventurer expecting `FORBIDDEN`; HARDEN-02 stays in Phase 12.

#### Process and quality
- **D-22:** **No UI phase, no UI-SPEC** (Phases 4–9 precedent): provisional visuals, `kg_theme.dart` tokens, Material controls allowed on this utility surface, existing parchment assets, no new Cloudinary asset (an icon for the Settings button is not needed).
- **D-23:** **TDD red → green → refactor:** unit tests for the `PendingRequest` parsing (entry by entry, optional `pendingQuest`), the grouping by quest, the hiding/greying rules (busy lane, free travel, arrival by time), the order, the override diff (only changed participants), the failure classifiers, the teleport mode state machine; widget tests for the Settings section gated by role, the queue cards and their disabled states, the form controls and the confirmation recap, the Map in teleport mode (own pawn absent, selected pawn draggable, «Annulla»); `flutter analyze` with no new issues; `dart format` only on touched files (Phase 11 D-38); `tool/schema_check` against `git -C <BE> show origin/develop:src/schema.gql` in the gate plan.
- **D-24:** the FE develops against the BE contract already on `develop` (`pendingRequests`, `pendingRequestsUpdated`, `completePendingRequest`, `teleportCharacter`, `character(id)`) and against the **BE-HARD-08 proposal** (`BACKEND-NOTES.md` §2) with fakes and recorded `QueryResult`s (pattern of Phases 3–9); `PendingRequest.fromJson` treats `character.pendingQuest` as optional. The plan that selects `character.pendingQuest` in the registered documents and the device E2E run **after the BE Phase 10 PR is merged** on BE `develop` (same gate pattern as 08-12 and 09-12). BE PR before FE PR.
- **D-25:** Boy Scout within scope: `TravelMutations` gains the teleport document next to `startTravel`; the ROADMAP «Decisions to make during discuss step» of this phase are closed; nothing else outside the touched lines.

### Claude's Discretion
- Copy and layout of the cards, the form and the recap (provisional); whether the confirmation dialog gets a neutral (non-red) style; optimistic removal of a completed card (D-13); the loader look on panel open and form open; the exact refetch triggers beyond D-18; how the teleport mode is modelled (new cubit vs an extension of `MapAvailabilityCubit`/`TravelCubit`) provided the Map-only presenter of Phase 9 keeps working; how the selected character's coordinates are resolved (D-15); whether «Arrivato» rows need a subtle colour; the grouping key when the same quest appears in both lanes (impossible today: story and worldMission are different quest types).

### Deferred Ideas (OUT OF SCOPE)
- A «Personaggi» list of all active characters in the panel (teleport of a character without pending requests, search by name) — user chose «Solo la coda»; backlog.
- Inner POIs of a city as drop targets of the teleport (today only city markers are targets) — backlog.
- A BE emission of the queue when a queued character's location or travel changes (today insert/delete of PendingQuest only) — optional, asked as a question in `BACKEND-NOTES.md`; the FE refetches on its own triggers.
- Reject with refund of a story/worldMission — excluded by the user in the BE Phase 9.
- An audit viewer in the app — out of scope (no GraphQL read of `admin_audit_logs`).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description (amended 2026-10-29) | Research Support |
|----|-------------|------------------|
| ADMIN-01 | «Locanda» section in Settings only for `role == innkeeper`, live with `userUpdated`, opens a full-screen utility route on the root Navigator | F1 (role path `userUpdated → adoptUser → AuthCubit`, providers visible from a root route, Settings layout, utility-screen template), C8, C11 |
| ADMIN-02 | Live queue of story/worldMission requests, one card per quest, busy-lane participants hidden, free travellers greyed with remaining time, «Completa» disabled until arrival | F2 (subscription pattern, resubscribe verified in graphql 5.2.1), F3 (models, grouping, seats, clock), C4, C5, C6, C7 |
| ADMIN-03 | Complete through the form + explicit confirmation, results recapped, codes mapped inline | F4 (inputs from the real SDL, `QuestResult` reuse, classifier, dialog), C1, C2 |
| ADMIN-04 | Teleport from a queue row by dragging the selected pawn on the Map to a city marker, no confirmation, panel reopens on success | F5 (Map layers, drag mechanics, tab jump, availability interplay), C3, C11, C13, C14, C16, C17 |
| ADMIN-05 | Per participant: HP slider `1..maxLifePoints`, consumables and spells with quantities; no grade/monster/reward | F4 (character read, `Spellbook` usages, `ItemUsageInput`, BE limits) |
| ADMIN-06 | Injuries as chips of the 28 `InjuryType` with Italian labels, existing ones inactive | F4 (28/28 parity FE ↔ BE verified) |
| ADMIN-07 | Role guard server-side; FE hides the entry for non-innkeepers; UAT proves `FORBIDDEN` as adventurer | F1, F7 (test fixtures `buildTestUser(role:)`, BE `roles.guard.ts` JWT snapshot), C8, C9 |
| ADMIN-08 | Audit log on the BE; FE adds nothing | F7 (manual UAT only: `admin_audit_logs` read with mongosh) |
</phase_requirements>

## Summary

Everything the panel needs already exists on BE `develop` (`8f30d1d`): `pendingRequests`, `pendingRequestsUpdated`, `completePendingRequest(input: CompletePendingRequestInput!): [QuestResult!]!`, `teleportCharacter(request: TravelRequest!): CommonResponse!` and `character(id)` readable by the innkeeper. The only missing field is the BE-HARD-08 `PendingRequestCharacter.pendingQuest` (not in the schema yet, and the BE research recommends exactly `pendingQuest: ID` nullable). The schema check gate passes today with 38 documents. The phase adds four (`GetPendingRequests`, `OnPendingRequestsUpdated`, `CompletePendingRequest`, `TeleportCharacter`), so **42**. The rest of the work is FE composition of existing patterns: the `QuestResultsCubit` subscription and resubscribe skeleton, the `TravelProgressCubit` server-clock and reread delays, the Phase 7 drag and drop rule, the `NotificationIntentLanding` tab jump, and the `QuestResult` model and fragment.

The evidence refines the CONTEXT in a few places. These are listed in «Conflicts with CONTEXT», C1–C17. The ones that change plans:
- **C1:** the consumables input is `ItemUsageInput`, and every quantity must be ≥ 1.
- **C2:** the `OUTCOME_*` codes carry no participant id, so the error cannot be placed under one participant.
- **C3:** `PendingRequestCharacter` has no `sex` and its `location` is a bare id, so the teleport pawn needs one `character(id)` read. This also removes the need for a `pointOfInterest` document.
- **C4:** `ActiveTravel.fromJson` requires `road`, so the queue needs a slim travel value.
- **C5/C6:** the reread delays apply to arrival, and the new subscription's snapshot already covers «panel reopened» and «WS reconnected». The resubscribe was verified in the graphql 5.2.1 source.
- **C8:** the BE role guard reads the **JWT snapshot**, so a live promotion shows the section before the BE accepts the calls.
- **C11:** `KlimmeckGraphQl`, `ServerClockService` and `ConnectionRestoredEvents` are not visible from a root route. A shell-level `RepositoryProvider<InnkeeperRepository>` plus `.value` hand-off is required.
- **C13:** teleport mode must make the Map "not free" for the Phase 9 presenter.

**Primary recommendation:** build the work bottom-up in this order:
1. Pure models and derivations.
2. Four documents plus typed service methods, an `InnkeeperRepository`, and one `InnkeeperFailure` classifier.
3. A route-scoped `PendingRequestsCubit` (subscription plus timers).
4. The Settings section and the panel route through a single `openInnkeeperPanel(context)` helper.
5. A `RequestCompletionCubit` with the form, confirmation and recap.
6. A shell-level `TeleportModeCubit` with a `TeleportModeLanding` (page jump, cancel on tab change or lost role, re-push on success), a `TeleportPawnLayer` and an `isTeleportMode` availability flag.
7. Last, the gated plan that selects `character.pendingQuest`, runs the full gate against BE `develop` after the BE Phase 10 merge, and runs the device E2E.

## Project Constraints (from CLAUDE.md)

- Flutter + `flutter_bloc`/Cubit + `equatable`; `graphql_flutter` for GraphQL; no new package needed for this phase (verified `pubspec.yaml`: `bloc_test ^10`, `mocktail ^1.0.5`, `fake_async ^1.3.3` already in dev deps).
- **Rule 1:** chrome only on utility screens: the panel is a utility surface (Scaffold/AppBar allowed); **the Map in teleport mode is gameplay**: no AppBar/Material chrome, only an in-style «Annulla» chip.
- **Rule 2:** no blocking loading in an active session: loaders only on explicit actions (panel open until first snapshot, form open until the character reads), never on resubscribe/refetch.
- **Rule 3:** branch `feat/10-admin-panel` (already checked out), PR to `develop`; commit scope `phase-10` for docs (`docs(phase-10)`), `feat(admin)`/`feat(map)`… for code; **no `Co-Authored-By` trailer** (user memory).
- **Rule 4:** backend is the source of truth: the FE never computes outcomes, never moves a character locally (teleport result arrives through refetch/snapshot), derives only display state (remaining time, «Arrivato»).
- **Rule 5:** no secrets: never print `.env`; logs carry ids and codes only.
- Clean Code, SoC (UI → Cubit → Repository → Service), TDD red→green→refactor, Boy Scout within scope.
- `docs/rules/architecture.md`: documents only in `lib/graphql/`, models Flutter-free in `lib/models/<domain>/`, repositories in `lib/repository/`, feature folders lowerCamelCase, cubit folders `xxxCubit/`.
- `docs/rules/graphql.md`: named operations (`GetXxx`, `OnXxxUpdated`, imperative mutations), never raw `OperationException` to the UI, one consumer per subscription, cleanup in `close()`, backoff with bounded retries.
- `docs/rules/testing.md`: `bloc_test` per non-trivial cubit, `mocktail`, fixtures under `test/helpers/fixtures/`, no `Future.delayed` sync (use `fake_async`/pump).
- **Formatting (user memory + Phase 11 D-38):** never `dart format` a directory; per file only. Measured today: `character_marker_layer.dart` and `map_utils.dart` are **DIRTY** (never format them, edit by hand); `settings.dart`, `world_map.dart`, `main_screen.dart`, `authenticated_shell.dart`, `map_availability_*.dart`, `travel_mutations.dart`, `graphql.dart`, `schema_check_documents.dart`, `travel_route_layer.dart`, `quest_paper_layer.dart`, `settings_test.dart`, `world_map_travel_test.dart`, `authenticated_shell_test.dart`, `mocks.dart`, `fragments.dart` are **CLEAN** (`dart format --output=none --set-exit-if-changed <file>` exit 0).
- `flutter analyze` baseline measured today: **52 issues, 0 errors, 0 warnings** (all `info`). Gate: no new issue.

## Standard Stack

### Core (all already in the project, no install)
| Library | Version (pub cache) | Purpose | Why |
|---------|---------|---------|-----|
| graphql_flutter / graphql | 5.2.1 | queue subscription, query, mutations | project client; re-sends live subscriptions after a socket reconnect (verified below) |
| flutter_bloc / bloc | 9.1.1 / 9.2.0 | `PendingRequestsCubit`, `RequestCompletionCubit`, `TeleportModeCubit` | project standard |
| flutter_map + latlong2 | 8.2.1 | teleport pawn layer | existing map |
| equatable | project | immutable states/models | project standard |
| bloc_test, mocktail, fake_async | ^10 / ^1.0.5 / ^1.3.3 | tests | project standard; `fake_async` for resubscribe backoff and endTime timers |

Flutter 3.35.5 stable [VERIFIED: `flutter --version`].

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `character(id)` (registered `character` doc) for the teleport pawn | new `GetPointOfInterest` query | POI gives coordinates but not `sex` (pawn asset); one more document to register; rejected (C3) |
| Shell-level `TeleportModeCubit` | extend `MapAvailabilityCubit` or `TravelCubit` | both have other owners/semantics (availability is UI-written flags only; TravelCubit is the own character's travel). A dedicated cubit keeps SoC (Discretion) |
| Global `pendingRequestsUpdated` for the whole session | route-scoped (D-04/D-10) | locked by D-04 |

## F1 — Settings section, role source, root route, providers

1. **Settings is a tab, not a route** (Phase 4 D-04): `BackgroundImage` + parchment `Container` + `SingleChildScrollView`, sections at `lib/screens/mainScreen/tabs/settings/settings.dart:50-52` (`NotificationPreferencesSection`, then `AccountSection`), satchel clearance `:14,53`. Phase 4 D-06: «"Esci" is the last scrollable element» → the «Locanda» section goes **between Notifiche and Account** (or first), never after Account. `SettingsSection(title, children)` at `components/settings_section.dart:5-26` is the section primitive.
2. **Role source and liveness** [VERIFIED code]: `SessionSyncCubit._onUser` → `_auth.adoptUser(user)` (`lib/screens/auth/syncCubit/session_sync_cubit.dart:133-146`) → `DevAuthTokenService.adoptUser` emits a new `AuthAuthenticated(user: …)` (`dev_auth_token_service.dart:104-113`; same in `session_auth_token_service.dart:198-205`) → `AuthCubit` re-emits every channel state (`auth_cubit.dart:31-33`). `AuthAuthenticated.props = [user, accessToken]` (`auth_token_service.dart:41`) and `User.props` include `role` (`models/user.dart:56-62`), so a role change is a distinct state. `UserFragment` selects `role` (`graphql/fragments/user_fragment.dart:10`). `AuthGate` does **not** rebuild on a role change (`auth_gate.dart:80-86`), which is fine: the section uses its own `BlocSelector<AuthCubit, AuthState, bool>` (`state is AuthAuthenticated && state.user.role == RoleType.innkeeper`).
3. **What a root route can see** [VERIFIED `lib/main.dart`]: above `MaterialApp` (`:266-298`) only `AppLifecycleEvents`, `AuthTokenService`, `NotificationPermissionGate`, `NotificationTapRouter`, `NotificationIntentCubit`, `AuthCubit`, `SplashCubit`, `GraphQLProvider`. **Not visible** from a root route: `KlimmeckGraphQl` (never provided: `late final graphQl` at `main.dart:152`, passed by constructor to `AuthenticatedShell`, `authenticated_shell.dart:106`), `ServerClockService` (`authenticated_shell.dart:202-213`), `ConnectionRestoredEvents`/`SyncHealth` (`session_sync_scope.dart:42-58`), every shell cubit. The shell documents the rule at `authenticated_shell.dart:91-93`.
4. **Root-route patterns to copy:** read the cubit before the await and pass with `.value` (`account_section.dart:66-74`; `world_map.dart:402-420` `showModalBottomSheet` + `BlocProvider.value`). `AuthGate` already pops every root route on logout, user change and character change (`auth_gate.dart:33-38`), so the panel and its cubit die with the session for free.
5. **Utility screen template:** `CharacterCreationScreen` = `Scaffold(appBar: AppBar(...), body: DecoratedBox(decoration: KlimmeckGuideTheme.getParchmentBackground(), child: SafeArea(...)))` (`character_creation_screen.dart:37-41,58-80`); AppBar colours come from the theme (`kg_theme.dart:151-154`: `darkBronze`/`primaryGold`); title style `theme.titleMedium.copyWith(color: primaryGold)`. For the panel use `AppBar(title: Text('Locanda'))` with the default back arrow (do not set `automaticallyImplyLeading: false`).
6. **Recommended wiring:** `AuthenticatedShell` adds `RepositoryProvider<InnkeeperRepository>(create: (_) => InnkeeperRepository(graphQl: graphQl))` and `BlocProvider<TeleportModeCubit>` (lazy). One function `Future<void> openInnkeeperPanel(BuildContext context)` (in `lib/screens/innkeeper/innkeeper_panel_route.dart`) reads `InnkeeperRepository`, `ServerClockService`, `TeleportModeCubit` (and optionally `ConnectionRestoredEvents`) **from the shell context** and pushes `MaterialPageRoute` on `Navigator.of(context, rootNavigator: true)` with `MultiRepositoryProvider/.value` + `BlocProvider<PendingRequestsCubit>(create: …..start())`. It is used by both the Settings button and the teleport-success re-push (DRY). `AppLifecycleEvents` and `AuthCubit` are readable inside the route directly.

## F2 — Queue subscription

1. **Service shape** [VERIFIED `lib/repository/services/graphql/graphql.dart`]: `performSubscription` returns `Stream<QueryResult>` with `FetchPolicy.noCache` (`:98-109`); typed streams map each result through `_throwIfStreamFailed` → `SubscriptionStreamException(operation, code)` (`:191-197`), parse errors become `FormatException` without closing the stream (`:136-146`, documented at `:133-135`). Lists are parsed item by item with `tryFromJson` + `whereType` (`getUnacknowledgedQuestResults`, `:162-176`); a missing list throws `FormatException`. Codes: `graphQlErrorCode` reads `extensions.code` from HTTP and WS shapes (`graphql_error_code.dart:15-29`); `isAccessDeniedError` = `FORBIDDEN`/`NOT_FOUND` (`:39-44`).
2. **Which existing consumer fits:** `QuestResultsCubit` (`lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart`) is the right skeleton: `start()` opens the stream plus lifecycle listeners (`:83-92`); `_onStreamError` skips `FormatException`, terminates on access denied, otherwise `_scheduleResubscribe` with `exponentialBackoff(_attempt++, max: WsReconnectPolicy.maxReconnectDelay)` (`:270-306`); `_attempt = 0` on every event (`:261-264`); `close()` cancels the timer and the subscriptions (`:356-365`). `QuestCubit.watchQuest` (party watch, `quest_cubit.dart:95-120`) has **no** resubscribe (it drops the watch on error), so do not copy it. `SessionSyncCubit` is the same policy at session scope (`session_sync_cubit.dart:148-185`).
3. **Reconnection** [VERIFIED source `~/.pub-cache/hosted/pub.dev/graphql-5.2.1/lib/src/links/websocket_link/websocket_client.dart`]: on connection loss `hasBeenTriggered` is reset for every live subscription (`:393`) and they are re-sent after `_connect` (`:361`, `:577-613`). With the BE's "snapshot at subscribe" (BE 09 §9), **a WS reconnect re-delivers a full snapshot to the still-open queue stream**. The stream itself does not complete on a socket drop. It completes only on server `complete`, for example after a `FORBIDDEN` (BE Phase 3: `next` with errors, then `complete`).
4. **`ConnectionRestoredBus`** (`connection_restored_events.dart:5-22`, fed by `SessionSyncCubit._onConnection`, `session_sync_cubit.dart:112-121`) is available in the Settings context and can be handed to the route with `.value`. Because of (3) it is **optional**. Recommend not wiring it: fewer moving parts. The resume refetch (`AppLifecycleEvents.foregrounded`, visible at the root) stays as a cheap safety net.
5. **Terminal FORBIDDEN:** `SubscriptionStreamException(code: 'FORBIDDEN')` → cubit emits a terminal `isForbidden` state, cancels, and never resubscribes (same guard as `_isStreamTerminated`). The panel's `BlocListener` pops the route. `NOT_FOUND` cannot happen on this subscription (no argument), but treat it like an unknown error (resubscribe).
6. **Recommended cubit:** `PendingRequestsCubit` in `lib/screens/innkeeper/pendingRequestsCubit/`, with `SafeEmit`. Its state is `PendingRequestsState { requests: List<PendingRequest>, isLoaded, isForbidden, serverNow, hiddenQuestIds (optimistic removals) }`. It receives `InnkeeperRepository`, `ServerClockService`, `AppLifecycleEvents`, `tick`, `rereadDelays`. Actions: `start()`, `refetch()` (single-flight, silent, `silentRetry` like `quest_results_cubit.dart:206-211`), `markCompleted(questId)`. Cards are derived in a pure function, not stored.

## F3 — Models and derivations

1. **Real SDL** [VERIFIED `origin/develop:src/schema.gql`]: `PendingRequest { character: PendingRequestCharacter!, id: ID!, pointsSpent: Int!, quest: PendingRequestQuest!, startDate: DateTime, user: PendingRequestUser! }` (`:370-377`); `PendingRequestCharacter { activeTravel: ActiveTravel, awaitingAid: AwaitingAid, id: ID!, location: ID!, name: String!, title: String! }` (`:379-386`, **no `sex`, no `pendingQuest` yet**); `PendingRequestQuest { id, registeredAdventurers: [QuestRegistration!]!, requiredAdventurers: [QuestPartySlot!]!, title, type: String! }` (`:388-394`, `type` is a **String**, not the enum); `QuestPartySlot { count: Int!, title: String }` (`:545-548`); `QuestRegistration { character: ID!, registeredAt: DateTime, title: String! }` (`:558-562`); `ActiveTravel { duration, endTime, road: TravelPath!, startTime, to }` (`:20-26`).
2. **Do not reuse `ActiveTravel`** for the queue: `ActiveTravel.fromJson` reads `json['road']` unconditionally (`models/travel/active_travel.dart:24-30`) and `tryFromJson` turns a missing road into `null` (`:33-40`). With the slim selection a traveller would parse as **not travelling** and «Completa» would wrongly enable (C4). Use a slim value `QueuedTravel { endTime, to }` (select `activeTravel { endTime to }` as in BE 09 §9's example).
3. **Reusable parsers:** `AwaitingAid.tryFromJson` (`models/character/awaiting_aid.dart:22-30`) fits the `awaitingAid { quest aidQuest since }` selection. `AdventurerSlot.listFrom` (`models/quest/adventurer_slot.dart:21-29`) throws on an unknown `title` (`TitleType.values.byName`), so wrap it in the entry-level `tryFromJson`. `totalSlots(slots)` (`models/quest/quest_capacity.dart:7-8`) gives N. `QuestType.values.asNameMap()[type]` maps the string type, and `QuestType.label` (`models/enums/quest_type.dart:20-33`) gives «Storia»/«Missione mondiale».
4. **Grouping, order, seats** (pure functions in `lib/models/pending_request/`). Group by `quest.id`, keeping the BE order: entries arrive sorted `startDate` asc, nulls last, then id (BE 09 §9). A card's rank is the index of its first entry (a `LinkedHashMap` insertion order), so no re-sort is needed. The first entry's `id` is the `pendingQuestId` (D-05). Seats per C7.
5. **Presence per participant** (pure, takes `serverNow`):
   - `awaitingAid != null` gives «In attesa di soccorso».
   - Otherwise, with `travel != null && serverNow < travel.endTime`, the state is «In viaggio · `formatGameDuration(endTime − serverNow)`» (`utils/game_duration_format.dart:7-20` rounds up to the minute, never «0 min» for a positive time).
   - With `travel != null && serverNow >= endTime`, the state is «Arrivato».
   - Otherwise «Presente».
   - `pendingQuest != null` hides the participant (D-07).
   - Server time comes from `ServerClockService.now()` (`repository/services/time/server_clock_service.dart:33`). Never `DateTime.now()` (Phase 7 Pitfall 2).
6. **Refetch-at-endTime pattern:** `TravelProgressCubit.arrivalRefetchDelays = [5 s, 65 s]` after `endTime` (`travel_progress_cubit.dart:37-40`), because the BE closes a travel by job/sweep, which can take up to about 60 s. The queue cubit schedules one `refetch()` per listed travel at `endTime + 5 s` and `endTime + 65 s`, using `serverNow` and the clock offset (C5). A local ledger like `ArrivalRereadLedger` is overkill for a route-scoped cubit: a `Set<(characterId, endTime, index)>` of already-fired rereads is enough.

## F4 — Completion form

1. **Inputs from the real SDL** [VERIFIED]:
   - `CompletePendingRequestInput { outcomes: [ParticipantOverrideInput!], pendingQuestId: ID! }` (`:184-187`).
   - `ParticipantOverrideInput { characterId: ID!, consumablesUsed: [ItemUsageInput!], hpAfter: Int, injuries: [InjuryType!], spellsUsed: [SpellUsageInput!] }` (`:348-354`).
   - **`ItemUsageInput { item: ID!, quantity: Int! }`** (`:299-302`, not `AssetQuantityInput`, which is the shop's input with a nullable `item`, `:33-36`).
   - `SpellUsageInput { spell: ID!, usages: Int! }` (`:685-688`).
   - `completePendingRequest(input: CompletePendingRequestInput!): [QuestResult!]!` (`:330`).
2. **BE validation limits** (BE 09 §2, `OUTCOME_OVERRIDE_INVALID`):
   - `hpAfter` is an integer in `1..maxLifePoints` (the maximum **before** the reward).
   - Injuries must be in the catalogue.
   - Consumables must be `LootItem`s within what is owned; spells must be active, within the remaining usages.
   - Quantities and usages are integers **≥ 1**.
   - At most one override per character; at most 50 entries per list.
   - So the diff must **omit** zero-quantity lines and omit `outcomes` entirely when nobody changed (C1).
3. **Character data:** `KlimmeckGraphQl.getCharacter(id)` (`graphql.dart:405-425`) with `CharacterFragment.fullFields` (`graphql/fragments/character_fragment.dart`) already selects:
   - `status { currentLifePoints maxLifePoints injuries spellStates { usages recoveries spell { id } } location {…} }`;
   - `infos { name sex … }`;
   - `assets { activeSpells { usages spell {…} } ownedItems { quantity item { ... on LootItem {…} } } }`.

   Innkeeper read access to another character is delivered by BE Phase 3 (`character(id)` ownership: «owner or innkeeper», BE 03 BACKEND-NOTES lines 17, 63, 170). Note: `getCharacter` throws `GraphQlAccessDeniedException` for FORBIDDEN/NOT_FOUND and a plain `Exception` otherwise (`:410-417`). The repository must map both (network vs unknown cannot be told apart, so «Riprova» covers both).
4. **Remaining spell usages:** reuse `Spellbook.of(character).slots` (`models/spell/spellbook.dart:75-127`). Usages come from `state?.usages ?? active?.usages ?? spell.maxUsages` (`:189-190`), the same rule the Journal shows. Do not reimplement it. Consumables come from `assets.ownedItems` filtered on `item?.isLoot == true && (quantity ?? 0) > 0` (`models/asset_item.dart:34-36`).
5. **Injury chips:** `InjuryType` has 28 values with `InjuryTypeExtension.label` (`models/enums/injury_type.dart:47`). **Parity with the BE enum verified: 28/28 identical names** (schema `:266-295`, diff empty). Material `FilterChip` is themed (`kg_theme.dart:173-184`: `selectedColor: primaryGold`, `disabledColor: paleSilver`). Existing injuries are rendered `FilterChip(selected: true, onSelected: null)`, which is disabled. The override carries only the added ones.
6. **Results recap:** the mutation selects `QuestResultFragment.fields` (`graphql/fragments/quest_result_fragment.dart`, valid on `develop`, includes `acknowledgedAt`). Each element is parsed with `QuestResult.tryFromJson` (`models/quest_result/quest_result.dart:119`), item by item. Recap fields:
   - `outcome.label` («Missione completata» for `gmCompleted`, `quest_outcome.dart:2-12`);
   - `hpBefore → hpAfter`;
   - `injuriesAdded` labels;
   - `xpGained`;
   - `hasLevelChanged`/`hasTitleChanged` (`quest_result.dart:73-75`) with `TitleType.label`;
   - `spellLearned?.name`.

   Name per result: match `QuestResult.characterId` to the card's participant names.
7. **Dialogs and styles:** `DestructiveConfirmationDialog` + `showDestructiveConfirmation` (`shared/components/modal/destructive_confirmation_dialog.dart:6-64`) is an `AlertDialog` with a red confirm button (`destructiveButtonStyle`, `kg_theme.dart:211-216`). No neutral button style exists in the theme. A neutral variant needs a new theme token (`ui-ux.md`: no inline styles). Recommendation: add a `confirmButtonStyle` parameter to the dialog, defaulting to the destructive style, plus a `KlimmeckGuideTheme.primaryButtonStyle` (darkBronze/parchment). Alternatively reuse the red one as-is; this is Claude's discretion. The results recap can be a plain `AlertDialog`/`showDialog` on the panel (utility surface).
8. **Existing widgets that fit:** Material `Slider` (theme has no slider override; colours come from `colorScheme`), `IconButton` ± with `Text` for steppers (`UsagesPencilCounter`, `shared/components/usages_pencil_counter.dart`, is a gameplay pencil animation sized 25×50, not an input), `SettingsSection`-like titled blocks, and `ItemRow`/`SpellRow` if a name+icon line is wanted.

## F5 — Teleport mode on the Map

1. **Layers today** (`world_map.dart:223-256`), in order: `_buildMapImage`, `TravelRouteLayer`, `CityMarkersLayer`, `QuestMarkersLayer`, `CharacterMarkerLayer`, `QuestPaperLayer`, `_buildQuestOverlay` (`QuestInfoOverlay`).
   - The own pawn reads `CharacterCubit` (`character_marker_layer.dart:57-70`). The asset is `state.character.infos!.sex!.pawnPath` (`:75`, `models/enums/sex_type.dart:11-18`). The position is `_dragPoint ?? _confirmingDestination(travel) ?? location` (`:73-74`).
   - Dragging is a `Draggable` with `maxSimultaneousDrags` gated by `_canStartTravel` (`:146-150,178-194`).
   - The drag point is converted with the **layer's** render box and `mapController.camera.screenOffsetToLatLng` (`:207-221`).
   - On release: `MapUtils.findCityContainingPoint(...) ?? MapUtils.findNearestCity(...)` (`:224-236`, `map_utils.dart:40-73`) → `onDragEnd(targetCity.markerLocation.location, targetCity)`.
   - `WorldMap._handleCharacterDragUpdate` writes `pawnDragChanged(true)` and pans (`world_map.dart:357-371`). `_handleCharacterDragEnd` clears the flag, then `travelDestinationFor` (same city → `null`, `models/travel/travel_destination.dart:7-15`) → `TravelCubit.preview` (`world_map.dart:380-397`).
2. **Cheapest render of only the selected pawn:** in `WorldMap._buildMap`, a `BlocBuilder<TeleportModeCubit, TeleportModeState>` swaps layers.
   - With teleport mode active, render `_buildMapImage`, `CityMarkersLayer` (the drop targets) and a new `TeleportPawnLayer(target, cities, mapController, onDragUpdate, onDragEnd)`, plus the in-style «Annulla» chip with the error line.
   - Omit `TravelRouteLayer`, `CharacterMarkerLayer`, `QuestPaperLayer`, `QuestMarkersLayer` and `QuestInfoOverlay` (C14).
   - The own `TravelProgressCubit` keeps ticking underneath, because it is owned by `_WorldMapState` (`world_map.dart:61,92-99`), not by the layers. So the own travel is unaffected and resumes on exit. On entering teleport mode, call `_closeQuestSheet()` (`:519-522`).
3. **Drag reuse without duplication:**
   - Extract the release rule into `MapUtils.dropTargetCity(LatLng, List<City>)` (`map_utils.dart` is DIRTY, edit by hand).
   - Extract the drag-point bookkeeping (`_dragPoint`, `_handleDragUpdate`, `_handleDragEnd`) into a `mixin PawnDragging<T extends StatefulWidget> on State<T>` used by both `CharacterMarkerLayer` and `TeleportPawnLayer`. It must stay at **layer** level, because the conversion relies on the layer's full-map `RenderBox` (`character_marker_layer.dart:208-213`). A marker-level widget would convert against a 30×30 box (Phase 7 Pitfall 7).
   - `WorldMap` keeps one `onDragUpdate` (pan + `pawnDragChanged(true)`). `onDragEnd` branches: teleport mode → `TeleportModeCubit.teleportTo(city)` (skip when `travelDestinationFor(target, location: targetLocation) == null`, C16); else the Phase 7 travel path.
4. **Target resolution (C3):** `PendingRequestCharacter.location` is a bare POI id and the entry has no `sex`. One `character(id)` read (the already-registered `character` document) gives `status.location` (`id` + `location` LatLng, `models/point_of_interest.dart:18-21`) and `infos.sex`. `PointOfInterest` in the schema also exposes `city` (`:447-453`), but that would still miss `sex`, so no new document is needed. Do the read **before** popping the panel: the row shows a small inline progress, which counts as an explicit action. `TeleportModeCubit.prepare(characterId, name)` → `TeleportPreparing` → `TeleportReady(target)`. The panel listens for `TeleportReady` and pops; on failure the panel shows a SnackBar and stays.
5. **Tab jump** (`NotificationIntentLanding`, `components/notification_intent_landing.dart:48-60`): `popUntil(isFirst)` on the root Navigator, then `pageController.jumpToPage(0)` guarded by `hasClients`. Mirror it in a `TeleportModeLanding` wrapping the `PageView` in `MainScreen._buildPagesWithSatchel` (`main_screen.dart:153-183`, `pageController` at `:74-79`). It has three listeners: `TeleportReady` → jump to the Map; `TeleportSucceeded` → `openInnkeeperPanel(context)` then `cubit.acknowledgeSuccess()`; `AuthCubit` role lost → `cancel()`. `onPageChanged(page != 0)` → `cancel()` (`main_screen.dart:208-213`). The Map page is never disabled (`satchel_availability.dart:11-18`).
6. **Probe (deleted) results** [VERIFIED throwaway widget test]:
   - `jumpToPage(0)` while already on page 0 fires **no** `onPageChanged`.
   - Jumping 6 → 0 fires `[6, 0]`, exactly once for 0.
   - `pop()` of a root route followed by `jumpToPage(0)` in the same frame works (`hasClients` true, page 0).
   - The "cancel on tab change" rule must therefore be "cancel when the new page ≠ 0", never "cancel on any change".
7. **Phase 9 presenter interplay (C13):** `MapAvailabilityState.isFreeBeneathRoutes = isMapPage && !isQuestSheetOpen && !isPawnDragging` (`map_availability_state.dart:28-29`). In teleport mode, between drags, the Map is "free", so a result sheet of the GM's own character could open over the teleport flow. While the panel route is up, `routeCoveredChanged(true)` already blocks sheets (`quest_result_presenter.dart:55-62`). Add `isTeleportMode` to the state (in `isFreeBeneathRoutes`) and a `teleportModeChanged(bool)` action written by `WorldMap` (the cubit doc says only the UI writes it, `map_availability_cubit.dart:7-10`). Clear it in `WorldMap.dispose` like the other flags (`world_map.dart:146-149`). Edge: `_endPawnDrag` runs when the **own** travel becomes active (`world_map.dart:195-201`); it can reset `isPawnDragging` mid teleport-drag. This is harmless (one frame of "free"), and `isTeleportMode` covers it.
8. **Document:** `TravelMutations.startTravel` (`graphql/mutations/travel_mutations.dart:1-11`, CLEAN) gets `teleportCharacter` next to it: `mutation TeleportCharacter($request: TravelRequest!) { teleportCharacter(request: $request) { response successful } }`. The `TravelRequest { id: String!, poiId: String! }` input (`:722-725`) maps to the existing `TravelRequest` model (`models/request/travel_request.dart`). BE 08 §7: any existing POI is accepted; the BE answers `QUEST_IN_PROGRESS` only for an occupied standard lane, clears a free travel atomically, sends **no push**, and is audited.
9. **«Annulla» chip style:** reuse the `_TravelLabel` look (parchment `DecoratedBox`, `radius`, `labelLarge`/`darkWood`, `character_marker_layer.dart:240-268`) wrapped in a `GestureDetector` with a ≥ 44 px target (`ui-ux.md`). No Material `Chip`/`AppBar` on the gameplay Map.

## F6 — Schema check and documents

- **Registry:** `tool/schema_check/schema_check_documents.dart:33-75` holds **38** entries; `dart run tool/schema_check/dump_documents.dart` prints «dumped 38 documents» and `validate_documents.js` gives 38/38 `OK` against `origin/develop` today [VERIFIED run]. `test/tool/schema_check_documents_test.dart` asserts the registry keys equal every operation name matched by `\b(?:query|mutation|subscription)\s+(\w+)` in `lib/graphql/{queries,mutations,subscriptions}/*.dart`, and that each document's single operation is named like its key. **Never write «query Xxx»/«subscription Xxx» in a doc comment of those files** (Phase 9 lesson).
- **None of the four exists yet** (grep of `lib/` for `pendingRequests|completePendingRequest|teleportCharacter|pointOfInterest(`: no document). New keys: `GetPendingRequests`, `OnPendingRequestsUpdated`, `CompletePendingRequest`, `TeleportCharacter` → **42**. No `GetPointOfInterest` (C3).
- **Fragment convention:** fragments are Dart string constants interpolated, not GraphQL named fragments, except `UserFragment.definition` (`fragments/fragments.dart`, `quest_result_fragment.dart`). Add `lib/graphql/fragments/pending_request_fragment.dart` (`PendingRequestFragment.fields`), exported from `fragments.dart`, used by both the query and the subscription so the gated plan changes **one line** (`pendingQuest` under `character`).
- **Gated selection:** `character.pendingQuest` must not appear in any registered document before the BE Phase 10 PR merges (schema check fails otherwise). The model parses it optionally (`json['pendingQuest'] as String?`).
- **Gate commands** (same as plans 08-12/09-12):
  ```bash
  S=$(mktemp -d)
  git -C /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE fetch origin develop
  git -C /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE show origin/develop:src/schema.gql > "$S/schema.gql"
  dart run tool/schema_check/dump_documents.dart "$S/docs"          # expect: dumped 42 documents
  NODE_PATH=/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/node_modules \
    node tool/schema_check/validate_documents.js "$S/schema.gql" "$S/docs"   # expect: 42 × OK, exit 0
  ```

## F7 — Role gating tests and UAT

- **Fixtures:** `buildTestUser({RoleType role = RoleType.adventurer})` and `buildTestUserWithCharacter` (`test/helpers/auth_fixtures.dart:10-23`); `MockAuthCubit`, `MockKlimmeckGraphQl` and the other mocks live in `test/helpers/mocks.dart:74,108`. Service tests use a `GraphQLClient` over `Link.function` with `dataResponse`/`errorCodeResponse` (`test/repository/services/graphql/graphql_quest_result_test.dart:20-31`, fixtures in `test/helpers/fixtures/sync_event_fixtures.dart`). There is a fake clock at `test/helpers/fakes/fake_server_clock_service.dart`.
- **Settings tests to extend:** `test/screens/mainScreen/tabs/settings/settings_test.dart:55-80` provides a `MockAuthCubit` **without stubbing `state`**. Probe [VERIFIED, deleted]: reading an unstubbed `MockAuthCubit.state` throws `_TypeError`. Once Settings contains a `BlocSelector<AuthCubit>`, setUp must `whenListen(authCubit, …, initialState: AuthAuthenticated(user: buildTestUser(), accessToken: testAccessToken))`.
- **Other harnesses that will need the new providers (Wave 0):** `test/screens/mainScreen/tabs/map/world_map_travel_test.dart:126-139` and `world_map_availability_test.dart` (add `TeleportModeCubit`), `test/screens/mainScreen/main_screen_test.dart` and `main_screen_quest_results_test.dart` (if `TeleportModeLanding` listens to `TeleportModeCubit` and `AuthCubit`), `test/screens/auth/authenticated_shell_test.dart` (new lazy providers: no stub needed unless created eagerly).
- **Dev identity facts for the UAT** [VERIFIED BE code]:
  - The BE dev bypass resolves the bearer to **one cached identity per BE process**, upserted with the BE's own `DEV_AUTH_ROLE` (`src/auth/dev/dev-auth.strategy.ts`: `upsertWithRole(devAuth.twitchId, devAuth.role)`, `stubIdentity` memoised).
  - The FE's `DEV_AUTH_ROLE` is only the offline fallback when `me` fails (`dev_auth_token_service.dart:150-176`).
  - The **BE role guard reads the JWT snapshot** (`src/authz/roles/roles.guard.ts`: «il ruolo è lo snapshot del JWT (D-12): nessuna rilettura da DB»); a refresh re-reads the DB role (BE `auth-session.service.int-spec.ts:160-163`).
  - UAT layout (C9): device = real Twitch account promoted with mongosh, followed by a re-login or token refresh; second identity = dev bypass with BE `DEV_AUTH_ROLE=adventurer` via curl. That same identity proves `FORBIDDEN` on `pendingRequests`.
- **ADMIN-08:** manual check only: `db.admin_audit_logs.find({ action: { $in: ['completePendingRequest','teleportCharacter'] } }).sort({ _id: -1 }).limit(5)` after the E2E.
- **`flutter_tester` orphan:** an IDE-owned `flutter_tester` may be running. It is not this phase's; never kill it. Run `flutter test <file>` in the foreground only.

## F8 — Pitfalls to flag

See «Common Pitfalls» below (P1–P12).

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── graphql/
│   ├── fragments/pending_request_fragment.dart      # PendingRequestFragment.fields (gated line: pendingQuest)
│   ├── queries/pending_request_queries.dart         # GetPendingRequests
│   ├── subscriptions/pending_request_subscriptions.dart  # OnPendingRequestsUpdated
│   └── mutations/pending_request_mutations.dart     # CompletePendingRequest (+ TeleportCharacter in travel_mutations.dart)
├── models/
│   ├── pending_request/
│   │   ├── pending_request.dart          # PendingRequest, PendingRequestCharacter, PendingRequestQuest (+ tryFromJson)
│   │   ├── queued_travel.dart            # { endTime, to } — not ActiveTravel (C4)
│   │   ├── request_card.dart             # grouping, order, seats, visibility, canComplete (pure)
│   │   └── participant_presence.dart     # present / travelling(remaining) / arrived / awaitingAid (pure, serverNow)
│   └── request/
│       ├── complete_pending_request_input.dart  # toJson omits empty outcomes
│       └── participant_override.dart     # draft + diff vs character (only changed, ≥1 quantities)
├── repository/
│   ├── innkeeper_failure.dart            # enum + classifier (extensions.code only)
│   └── innkeeper_repository.dart         # watch/fetch queue, readCharacter, complete, teleport; _guard with timeout
├── screens/
│   ├── innkeeper/
│   │   ├── innkeeper_panel_route.dart    # openInnkeeperPanel(context) — single entry (Settings + re-push)
│   │   ├── innkeeper_panel_screen.dart   # Scaffold + AppBar «Locanda», BlocListeners (FORBIDDEN/role → pop)
│   │   ├── pendingRequestsCubit/         # route-scoped queue cubit + state
│   │   ├── requestCompletionCubit/       # form data, submit, results, failure
│   │   └── components/                   # request_card_view, participant_row, completion_form, injury_chips,
│   │                                     # quantity_stepper, completion_recap_text, results_recap_dialog
│   └── mainScreen/
│       ├── components/teleport_mode_landing.dart   # page jump / cancel on page ≠ 0 / role lost / re-push
│       └── tabs/
│           ├── settings/components/innkeeper_section.dart
│           └── map/
│               ├── teleportModeCubit/    # shell-level: idle → preparing → ready → teleporting → succeeded / failed
│               ├── layers/teleport_pawn_layer.dart
│               └── layers/pawn_dragging.dart   # mixin extracted from CharacterMarkerLayer (no duplication)
```
Every new file is formatter-clean by construction. Only `character_marker_layer.dart` and `map_utils.dart` are DIRTY: edit them by hand and never format them.

### Pattern 1: route-scoped subscription with silent resubscribe (from `QuestResultsCubit`)
```dart
// Source: lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart:255-306 (adapted)
void _subscribe() {
  _subscription = _repository.watchQueue().listen(
    _onSnapshot, onError: _onStreamError, onDone: _onStreamDone);
}

void _onSnapshot(List<PendingRequest> requests) {
  _attempt = 0;
  emit(state.copyWith(requests: requests, isLoaded: true,
      hiddenQuestIds: _stillHidden(requests)));
  _scheduleArrivalRereads(requests);
}

void _onStreamError(Object error) {
  if (error is FormatException) return;               // list survives (IN-04)
  if (isForbiddenError(error)) return _terminate();   // FORBIDDEN only: pop the panel
  _scheduleResubscribe();                             // exponentialBackoff(_attempt++, max: 60 s)
}
```

### Pattern 2: one entry point for the root route (Pitfall 5)
```dart
// Source pattern: lib/screens/mainScreen/tabs/settings/components/account_section.dart:66-74
Future<void> openInnkeeperPanel(BuildContext context) {
  final repository = context.read<InnkeeperRepository>();
  final clock = context.read<ServerClockService>();
  final teleport = context.read<TeleportModeCubit>();
  return Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider<TeleportModeCubit>.value(value: teleport),
        BlocProvider<PendingRequestsCubit>(
          create: (routeContext) => PendingRequestsCubit(
            repository: repository, clock: clock,
            lifecycle: routeContext.read<AppLifecycleEvents>(), // above MaterialApp
          )..start()),
      ],
      child: RepositoryProvider<InnkeeperRepository>.value(
        value: repository, child: const InnkeeperPanelScreen()),
    ),
  ));
}
```

### Pattern 3: override diff (only changed participants, BE limits)
```dart
// Pure: lib/models/request/participant_override.dart
ParticipantOverride? overrideOf(ParticipantDraft draft, Character character) {
  final hp = draft.hpAfter != character.status?.currentLifePoints ? draft.hpAfter : null;
  final injuries = draft.addedInjuries.difference(character.status?.injuries?.toSet() ?? {});
  final consumables = {for (final e in draft.consumables.entries) if (e.value >= 1) e.key: e.value};
  final spells = {for (final e in draft.spells.entries) if (e.value >= 1) e.key: e.value};
  if (hp == null && injuries.isEmpty && consumables.isEmpty && spells.isEmpty) return null;
  return ParticipantOverride(characterId: character.id, hpAfter: hp,
      injuries: injuries, consumablesUsed: consumables, spellsUsed: spells);
}
// toJson omits null/empty keys; CompletePendingRequestInput.toJson omits `outcomes` when empty.
```

### Anti-Patterns to Avoid
- **Parsing the queue's travel with `ActiveTravel.tryFromJson`.** A null `road` silently means "not travelling" (C4).
- **Reading shell providers inside the panel route.** `ProviderNotFoundException` (Pitfall 5). Read them before `push`.
- **Ending teleport mode on every `onPageChanged`.** The jump to page 0 itself fires `onPageChanged(0)`. End only when the new page ≠ 0.
- **A marker-level `Draggable` doing its own LatLng conversion.** It converts against a 30×30 box. Keep the conversion at layer level.
- **Sending zero quantities or an unchanged `hpAfter`.** `OUTCOME_OVERRIDE_INVALID` (quantities ≥ 1), or an unwanted HP write.
- **Matching server messages instead of `extensions.code`.** Every classifier in the repo maps codes only (`travel_failure.dart:52-70`).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Error code extraction (HTTP + WS shapes) | message parsing | `graphQlErrorCode`, `isAccessDeniedError` (`graphql_error_code.dart`) | handles `SubscriptionError` payload shape |
| Resubscribe backoff | ad-hoc timers | `exponentialBackoff(attempt, max: WsReconnectPolicy.maxReconnectDelay)` (`utils/backoff.dart`) | project policy, bounded |
| Silent refetch retries | loops | `silentRetry(..., isCancelled, shouldRetry)` (`utils/silent_retry.dart`) | used by every sync cubit |
| Server time | `DateTime.now()` | `ServerClockService.now()` | device clock drift (Phase 7 Pitfall 2) |
| Remaining time text | custom formatter | `formatGameDuration` | rounds up, days/hours |
| Seats N | sum loops | `totalSlots(AdventurerSlot.listFrom(...))` | existing, tested |
| Remaining spell usages | state merging | `Spellbook.of(character).slots` | same rule as the Journal (`spellbook.dart:189-190`) |
| Drop city | new geometry | `MapUtils.findCityContainingPoint` → `findNearestCity` (extract to `dropTargetCity`) | Phase 7 D-01 rule |
| Same-city no-op | new check | `travelDestinationFor(target:, location:)` | existing, tested |
| Result parsing | new model | `QuestResult.tryFromJson` + `QuestResultFragment.fields` | Phase 9, item-by-item |
| Emit after close | guards everywhere | `SafeEmit` mixin (`shared/bloc/safe_emit.dart`) | every shell cubit uses it |
| Injury labels / quest type labels / outcome labels | new maps | `InjuryTypeExtension.label`, `QuestType.label`, `QuestOutcome.label`, `TitleType.label` | parity already verified |

**Key insight:** the panel is about 80 % composition of Phase 3/7/9 machinery. The only genuinely new logic is the grouping/visibility/diff derivations and the teleport state machine, and those are pure, so they are cheap to test-drive.

## Runtime State Inventory

Not a rename/refactor/migration phase. Runtime state the plans must still know:

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | BE `users.role` decides the innkeeper; `admin_audit_logs` receives every admin mutation (BE Phase 3) | UAT only: promote the device user with mongosh; read the audit after the E2E |
| Live service config | BE `.env` `DEV_AUTH_ROLE` + cached dev identity (`dev-auth.strategy.ts`) | UAT: restart the BE after changing it |
| OS-registered state | None (verified: no new channel, no new permission) | none |
| Secrets/env vars | none new on the FE; `DEV_AUTH_ROLE` on the FE is fallback only | none |
| Build artifacts | none | none |

## Common Pitfalls

### P1: Root route without the shell providers
**What goes wrong:** `context.read<ServerClockService>()` / `<InnkeeperRepository>()` / `<TeleportModeCubit>()` inside the panel throws. **How to avoid:** `openInnkeeperPanel` reads them from the caller's context and passes `.value` (F1.6). **Warning sign:** `ProviderNotFoundException` in the panel widget test when pumped through the real route.

### P2: Settings tests break on the new `BlocSelector<AuthCubit>`
**What goes wrong:** the unstubbed `MockAuthCubit.state` throws `_TypeError` (probe). **How to avoid:** stub `initialState` in `settings_test.dart` setUp (Wave 0).

### P3: Teleport cancel on the jump itself
**What goes wrong:** `onPageChanged(0)` from `jumpToPage(0)` cancels the mode it just opened, if the rule is "any change". **How to avoid:** cancel only when the new page ≠ 0 (probe F5.6).

### P4: Subscription leak / resubscribe after pop
**What goes wrong:** a backoff timer fires after the route popped and re-opens the stream. **How to avoid:** `close()` cancels `_resubscribeTimer` and the reread timers; the timer callback checks `isClosed` (`quest_results_cubit.dart:294-305,356-365`); `bloc_test` + `fake_async` asserts no subscribe after close.

### P5: The queue never re-emits on arrival/teleport
**What goes wrong:** rows stay «In viaggio» forever, or a teleported traveller stays greyed. **How to avoid:** derive «Arrivato» from `serverNow ≥ endTime` (tick), reread at `endTime + 5 s/65 s`, re-subscribe on re-push (fresh snapshot), refetch on resume (C5).

### P6: `ActiveTravel` parsing of the slim selection
See C4.

### P7: JWT role snapshot
**What goes wrong:** the section appears right after a promotion, but the subscription answers `FORBIDDEN` until the token refreshes, so the panel pops silently. **How to avoid:** UAT promotes then re-logs in. Optionally show a SnackBar on the pop (C8).

### P8: Override validation mismatch
**What goes wrong:** `OUTCOME_OVERRIDE_INVALID` from zero quantities, `hpAfter` outside `1..max`, or a consumable that is not loot. **How to avoid:** the pure diff omits zeros and unchanged HP; the slider is clamped (`currentLifePoints.clamp(1, max)`); with `maxLifePoints <= 1` the slider is disabled (Material `Slider` needs `min < max` to be interactive); only loot items are listed.

### P9: Result sheet over the teleport flow
See C13. Add `isTeleportMode` to `MapAvailabilityState`.

### P10: `dart format` tall style vs acceptance greps
**What goes wrong:** the formatter splits long expressions over lines, so single-line greps like `grep "jumpToPage(NotificationIntentLanding.worldMapPageIndex)"` fail. **How to avoid:** the planner writes identifier-anchored greps (`grep -n "teleportModeChanged"`, `grep -c "TeleportCharacter"`), never multi-token single-line patterns. Never format DIRTY files.

### P11: Registry regex in doc comments
**What goes wrong:** a comment like `/// query GetPendingRequests …` in `lib/graphql/queries/*.dart` adds a phantom operation name, and `schema_check_documents_test` fails. **How to avoid:** never write `query|mutation|subscription <Name>` in comments there.

### P12: `NotificationIntentLanding` pops the panel
A push-notification tap pops every root route (`notification_intent_landing.dart:52-55`), including the panel. This is accepted; the GM reopens the panel from Settings. Document it in the UAT.

## Code Examples

### Typed queue stream in the service (item by item)
```dart
// Source pattern: graphql.dart:111-115 (typed stream) + :162-176 (item-by-item list)
Stream<List<PendingRequest>> subscribeToPendingRequests() =>
    performSubscription(PendingRequestSubscriptions.pendingRequestsUpdated)
        .map((result) {
      _throwIfStreamFailed(result, operation: 'pendingRequestsUpdated');
      return _pendingRequestsFrom(result.data?['pendingRequestsUpdated']);
    });

List<PendingRequest> _pendingRequestsFrom(Object? json) {
  if (json is! List) throw const FormatException('pendingRequests missing');
  final parsed = json.map(PendingRequest.tryFromJson).whereType<PendingRequest>().toList();
  if (parsed.length != json.length) {
    debugPrint('[Innkeeper] skipped ${json.length - parsed.length} malformed entries');
  }
  return List.unmodifiable(parsed);
}
```

### Failure classifier (codes only)
```dart
// Source pattern: lib/repository/travel_failure.dart:52-70
enum InnkeeperFailure { notFound, questInProgress, overrideInvalid, notParticipant,
  forbidden, unauthenticated, connection, timedOut, declined, malformed, unknown }

InnkeeperFailure innkeeperFailureFrom(OperationException exception) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) return InnkeeperFailure.connection;
  return switch (code) {
    notFoundCode => InnkeeperFailure.notFound,
    questInProgressCode => InnkeeperFailure.questInProgress,     // travel_failure.dart:10
    'OUTCOME_OVERRIDE_INVALID' => InnkeeperFailure.overrideInvalid,
    'OUTCOME_NOT_PARTICIPANT' => InnkeeperFailure.notParticipant,
    forbiddenCode => InnkeeperFailure.forbidden,
    unauthenticatedCode => InnkeeperFailure.unauthenticated,
    _ => InnkeeperFailure.unknown,
  };
}
```

### Documents
```dart
// lib/graphql/fragments/pending_request_fragment.dart  (gated plan adds `pendingQuest` under character)
class PendingRequestFragment {
  static const String fields = '''
    id
    startDate
    quest { id type title requiredAdventurers { title count } registeredAdventurers { character title } }
    character { id name location activeTravel { endTime to } awaitingAid { quest aidQuest since } }
  ''';
}
// queries:       query GetPendingRequests { pendingRequests { ...fields } }
// subscriptions: subscription OnPendingRequestsUpdated { pendingRequestsUpdated { ...fields } }
// mutations:     mutation CompletePendingRequest($input: CompletePendingRequestInput!) {
//                  completePendingRequest(input: $input) { ${QuestResultFragment.fields} } }
// travel:        mutation TeleportCharacter($request: TravelRequest!) {
//                  teleportCharacter(request: $request) { response successful } }
```
(`user`, `pointsSpent`, `character.title` are not displayed (D-08) and can be left out of the selection. Smaller payload, and no other user's `twitchId` held in memory.)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ADMIN-03 approve/reject | complete only (no reject, no refund, no grade) | BE Phase 9 user decision | no reject UI |
| ADMIN-05 grade/monsters/rewards | overrides of HP/injuries/consumables/spells only | BE Phase 9 | form = 4 controls |
| BE 09 §9 «nessun blocco se in viaggio» | `QUEST_IN_PROGRESS` while a standard lane is occupied (BE-HARD-08) | BE Phase 10 (pending) | classifier handles it now; field selected in the gated plan |

## Conflicts with CONTEXT

Each item is evidence that contradicts or refines a decision, followed by the recommended amendment.

- **C1 — D-12 input shape (refine).** The consumables input type is **`ItemUsageInput { item: ID!, quantity: Int! }`** (schema `:299-302`), not `AssetQuantityInput` (`:33-36`, shop). BE 09 §2 requires quantities/usages **≥ 1** and at most 50 entries. **Amend D-12:** «`consumablesUsed: [ItemUsageInput]`, `spellsUsed: [SpellUsageInput]`; lines at 0 are omitted; `outcomes` omitted when no participant changed».
- **C2 — D-14 per-participant error placement (contradicted).** BE 09 §2: every refusal has `extensions` **exactly `{ code }`**, so `OUTCOME_OVERRIDE_INVALID`/`OUTCOME_NOT_PARTICIPANT` do not say which participant. **Amend D-14:** both show a **form-level inline error** above «Conferma» with the form kept. `OUTCOME_NOT_PARTICIPANT` also refetches the queue (the BE's action: «ricaricare la coda»). The pure diff and clamped controls make both near-impossible from the UI.
- **C3 — D-15 coordinates source (resolved).** `PendingRequestCharacter` has no `sex` and `location` is a bare POI id (schema `:379-386`). The pawn asset needs `infos.sex` (`character_marker_layer.dart:75`). **Amend D-15:** «the target is read with `character(id)` (already registered `character` document; innkeeper read, BE Phase 3) before the panel pops: `status.location.location` for the coordinates, `infos.sex` for the pawn; no `pointOfInterest` document». The row shows an inline progress during the read (explicit action). A read failure gives a SnackBar on the panel and no mode change.
- **C4 — D-06/D-10 travel parsing (new constraint).** `ActiveTravel.fromJson` requires `road` (`active_travel.dart:24-30`) and `tryFromJson` returns `null` on failure (`:33-40`). Reusing it on `activeTravel { endTime to }` would show travellers as present and enable «Completa». **Amend D-10:** «the queue uses its own `QueuedTravel { endTime, to }`; an unparseable `activeTravel` object is fail-closed (row greyed «In viaggio» without time, «Completa» disabled), never "not travelling"».
- **C5 — D-18 refetch triggers (refine).**
  - (a) graphql 5.2.1 re-sends live subscriptions after a socket reconnect (`websocket_client.dart:361,393,577-613`), and the BE emits a snapshot at subscribe.
  - (b) The panel is **re-pushed** after a teleport, which creates a new cubit with a new subscription and therefore a new snapshot.
  - So «after an own teleport» and «when the panel is (re)opened» need **no** explicit `pendingRequests` call. Keep the query for the snapshot-less cases: **reread at `endTime + 5 s` and `endTime + 65 s`** (the BE closes free travels by job/sweep, `travel_progress_cubit.dart:37-40`), not at `endTime`; on **app resume**; after `QUEST_IN_PROGRESS`/`NOT_FOUND`/`OUTCOME_NOT_PARTICIPANT` on completion.
  - **Amend D-18 accordingly.**
- **C6 — D-06 «Completa» enabling (refine).** The BE does not block completion for a free travel (BE 09 §9, kept by BE-HARD-08 §2.2), and it may keep `activeTravel` up to about 60 s after `endTime`. **Amend D-06:** «"Completa" is enabled once every listed participant is present or its `endTime` has passed on the server clock (row «Arrivato»); the BE's late travel closure does not keep it disabled».
- **C7 — D-05 vs D-07 seat numbers (clarify).** D-05's «k/N» (entries vs `sum(requiredAdventurers.count)`) and D-07's «k presenti su N registrati» use two different N. **Amend:**
  - the header seats are **all entries of the quest (hidden busy included) / `totalSlots(requiredAdventurers)`**;
  - the caption reads **visible entries / all entries**;
  - `quest.registeredAdventurers` is not used for counting. It can include seats kept for archived characters (BE 9.2 placeholder rule), while `completePendingRequest` closes exactly the entries' characters (BE 09 §9).
- **C8 — D-01/D-04 role liveness vs BE guard (new risk).** `userUpdated` updates the role instantly (F1.2), but the BE `RolesGuard` reads the **JWT snapshot** (`src/authz/roles/roles.guard.ts`). After a promotion the section appears while the BE still answers `FORBIDDEN` until the next token refresh, so the panel pops silently. After a demotion the section disappears while the token would still pass (BE concern, Phase 12). **Amend D-04:** «on a `FORBIDDEN` pop, show a SnackBar «La Locanda non è disponibile» on the underlying screen (utility surface; the silent pop looks like a crash)». This is a Claude's discretion default; veto keeps the silent pop. UAT: promote, then re-login.
- **C9 — BACKEND-NOTES §5 UAT identities (correct).** The dev bypass is **one cached identity per BE process** and its role comes from the **BE** `.env` (`dev-auth.strategy.ts`); the FE `DEV_AUTH_ROLE` is only the offline fallback (`dev_auth_token_service.dart:150-176`). **Amend §5:** «device: the real Twitch account promoted with `db.users.updateOne({ twitchId: '<id>' }, { $set: { role: 'innkeeper' } })` + re-login; adventurers: the dev bypass with BE `DEV_AUTH_ROLE=adventurer` (BE restart), driven with curl; the same bearer proves `FORBIDDEN` on `pendingRequests`». Two adventurer characters for the worldMission need two identities: the dev bypass plus a second real account, or sequential BE restarts with another `DEV_AUTH_TWITCH_ID`.
- **C10 — canonical ref (doc fix).** «04-CONTEXT D-17 (routes on the root Navigator outside the shell providers)» is wrong: 04 D-17 is the `adoptUser` hand-off. The rule lives in `authenticated_shell.dart:91-93` and 07-RESEARCH Pitfall 5. **Amend the canonical_refs line.**
- **C11 — D-04 «queue cubit created for the route» (refine).** It needs dependencies that are not visible from a root route: `KlimmeckGraphQl` is never provided (`main.dart:152`), and `ServerClockService` is shell-scoped (`authenticated_shell.dart:202`). **Amend D-04:** «the shell provides `RepositoryProvider<InnkeeperRepository>` and the lazy `TeleportModeCubit`; a single `openInnkeeperPanel(context)` reads them plus `ServerClockService` from the caller and hands them to the route with `.value`; `AuthCubit`/`AppLifecycleEvents` are read inside the route (above `MaterialApp`)».
- **C12 — D-15 «labels hidden» (clarify).** The own pawn's labels (`travelLabelKey`, `awaitingAidLabelKey`) disappear with `CharacterMarkerLayer`. The selected pawn gets one floating label with its **name**; travel time is not shown (the teleport clears the travel).
- **C13 — Claude's discretion «Map-only presenter keeps working» (needed change).** Between drags, teleport mode is «free» for `MapAvailabilityState.isFreeBeneathRoutes` (`map_availability_state.dart:28-29`). **Amend:** «`MapAvailabilityState.isTeleportMode` (written by `WorldMap`, cleared in `dispose`) blocks the result sheets of the GM's own character during teleport mode; they open after exit».
- **C14 — D-15 layer list (complete).** Besides the own pawn, route, labels and quest paper, also hide `QuestMarkersLayer` and close `QuestInfoOverlay`: their taps open quest sheets that make no sense in teleport mode. City markers stay (drop targets); their lore tap is disabled in teleport mode. **Amend D-15.**
- **C15 — D-07 worldMission with every participant busy (default).** The CONTEXT is silent. Recommend keeping the card with header and seats, no rows, caption «0 presenti su N registrati» and «Un partecipante è impegnato in una missione», «Completa» disabled. This is consistent with the user rule (no busy character is shown) and tells the GM the mission exists. Listed for veto.
- **C16 — D-16 drop on the character's current city (refine).** Mirror `travelDestinationFor` (`travel_destination.dart:7-15`): the same marker gives **no call**, the pawn returns, and the mode stays. **Amend D-16.**
- **C17 — D-15 pawn position of a free traveller (refine).** The BE keeps `status.location` at the departure until arrival, so the teleport pawn starts at the **departure city**, not mid-road. Accepted: the teleport clears the travel anyway. **Note in D-15.**

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | BE Phase 10 ships `PendingRequestCharacter.pendingQuest: ID` nullable (not a boolean) | F6, gated plan | one-line change in the fragment/model (`standardLaneBusy: Boolean!` alternative in BACKEND-NOTES §2.1); the BE research (`10-RESEARCH.md` F10, Q18) recommends `pendingQuest: ID` [CITED: BE working tree, read-only] |
| A2 | BE `users` change stream emits `userUpdated` on a role change | F1, C8 | if not, the section appears only after `me` refetch (resume); low impact [ASSUMED from BE Phase 3 «userUpdated emitted by the users change stream»] |
| A3 | `startDate` is never null for GM lanes (no automatic travel) | F3 order | ordering only; the derivation keeps the BE order whatever it is [CITED: BACKEND-NOTES §1, BE 09 §9] |

## Open Questions (RESOLVED)

1. **New cubit or extension for teleport mode?** RESOLVED: a new shell-level `TeleportModeCubit` (Discretion). Availability gets only a boolean flag (C13).
2. **How is the selected pawn located and drawn?** RESOLVED: `character(id)` read before the pop (C3); no new document.
3. **Neutral confirmation style?** RESOLVED to Claude's discretion: recommended `confirmButtonStyle` parameter + `primaryButtonStyle` token, defaulting to the red style so existing callers are unchanged.
4. **Optimistic removal of a completed card?** RESOLVED: yes. `hiddenQuestIds` in the queue state, dropped when a snapshot no longer contains the quest. It avoids a ghost card when the emission lags. Discretion.
5. **Loader looks?** RESOLVED: `KGLoader` centred on the parchment until the first snapshot; the form shows `KGLoader` until all participant reads complete (`Future.wait`). A read failure shows «Riprova» (explicit action). Discretion.
6. **Is `ConnectionRestoredEvents` needed in the route?** RESOLVED: no (C5, resubscribe verified).
7. **WorldMission with all participants busy?** RESOLVED to the C15 default (listed for veto).
8. **Should «Arrivato» rows get a colour?** RESOLVED to Claude's discretion: no colour change; normal ink like «Presente».
9. **Tick period of the queue cubit?** RESOLVED: injectable `tick`, default 1 s (parity with `TravelProgressCubit`). The timer runs only while some listed participant is travelling and has not reached `endTime + 65 s`.
10. **Where does the «Locanda» section go?** RESOLVED: between «Notifiche» and «Account» (Phase 4 D-06 keeps «Esci» last); one `ElevatedButton` «Apri la Locanda».
11. **Grouping key across lanes?** RESOLVED: `quest.id` (story and worldMission are different quest types, CONTEXT discretion).
12. **What does the recap show for a character name?** RESOLVED: match `QuestResult.characterId` to the card's participant names; unknown id gives «Personaggio».

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | build/test | ✓ | 3.35.5 stable | — |
| Dart (pub cache graphql 5.2.1, flutter_map 8.2.1) | compile | ✓ | — | — |
| Node + BE `node_modules` (graphql-js) | schema check | ✓ | run today: 38/38 OK | — |
| BE `origin/develop` schema | schema check | ✓ | `8f30d1d` | — |
| BE Phase 10 PR (BE-HARD-08) | gated plan + device E2E | ✗ (BE branch `feat/10-hardening`, planning only) | — | none: the gated plan waits (D-24) |
| Android device + `adb reverse tcp:3000` | device E2E | not probed (human checkpoint) | — | — |
| mongosh | UAT data (role promotion, audit read) | not probed (human checkpoint) | — | — |

**Missing dependencies with no fallback:** BE Phase 10 merge, only for the last plan.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test ^10` + `mocktail ^1.0.5` + `fake_async ^1.3.3` |
| Config file | none (`analysis_options.yaml` for lints) |
| Quick run command | `flutter test <single test file>` (foreground, one file) |
| Full suite command | `flutter test` |
| Lint gate | `flutter analyze` — baseline **52 issues, 0 errors, 0 warnings**; no new issue |
| Schema gate | F6 commands against BE `origin/develop`; expect **dumped 42 documents** and 42 × `OK` (after the gated plan: still 42, with `pendingQuest` selected) |
| Registry test | `flutter test test/tool/schema_check_documents_test.dart` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADMIN-01 | Section visible only for innkeeper; appears/disappears on a role emission; Esci stays last | widget | `flutter test test/screens/mainScreen/tabs/settings/components/innkeeper_section_test.dart` | ❌ Wave 0 |
| ADMIN-01 | Settings still renders sections in order with a stubbed AuthCubit | widget | `flutter test test/screens/mainScreen/tabs/settings/settings_test.dart` | ✅ (needs AuthCubit stub) |
| ADMIN-01 | Button pushes the panel on the root Navigator with the shell deps handed over; role lost → pop; FORBIDDEN → pop (+ SnackBar per C8) | widget | `flutter test test/screens/innkeeper/innkeeper_panel_route_test.dart` | ❌ |
| ADMIN-02 | `PendingRequest.tryFromJson` entry by entry; optional `pendingQuest`; `QueuedTravel` strict; malformed skipped | unit | `flutter test test/models/pending_request/pending_request_test.dart` | ❌ |
| ADMIN-02 | Grouping by quest, BE order kept, first entry id, seats (C7), busy hidden, caption, canComplete (C6), all-busy card (C15) | unit | `flutter test test/models/pending_request/request_card_test.dart` | ❌ |
| ADMIN-02 | Presence: present / travelling «N min» / arrived by server time / awaiting aid | unit | `flutter test test/models/pending_request/participant_presence_test.dart` | ❌ |
| ADMIN-02 | Service: `OnPendingRequestsUpdated`/`GetPendingRequests` op names, item-by-item, `FORBIDDEN` typed stream error | unit | `flutter test test/repository/services/graphql/graphql_pending_requests_test.dart` | ❌ |
| ADMIN-02 | Cubit: loading → loaded on snapshot; replace on emission; silent resubscribe with backoff; FORBIDDEN terminal; rereads at endTime+5/+65 s; resume refetch; nothing after close | bloc_test | `flutter test test/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit_test.dart` | ❌ |
| ADMIN-02 | Cards: header title + type label + seats; rows name+state; greyed traveller; Completa disabled; empty state copy; loader only before first snapshot | widget | `flutter test test/screens/innkeeper/innkeeper_panel_screen_test.dart` | ❌ |
| ADMIN-03 | Classifier: NOT_FOUND, QUEST_IN_PROGRESS, OUTCOME_*, FORBIDDEN, UNAUTHENTICATED, link → connection, unknown | unit | `flutter test test/repository/innkeeper_failure_test.dart` | ❌ |
| ADMIN-03 | Repository: timeout → timedOut, OperationException → failure, `successful:false` → declined, results parsed item by item | unit | `flutter test test/repository/innkeeper_repository_test.dart` | ❌ |
| ADMIN-03 | Documents: four new documents + fragment content (no `pendingQuest` until gated) | unit | `flutter test test/graphql/pending_request_documents_test.dart` | ❌ |
| ADMIN-03 | Completion cubit: reads participants (Future.wait), submit with only changed outcomes, success → results + optimistic hide, NOT_FOUND → card removed, QUEST_IN_PROGRESS → refetch, OUTCOME_* form-level (C2), network keeps form, FORBIDDEN | bloc_test | `flutter test test/screens/innkeeper/requestCompletionCubit/request_completion_cubit_test.dart` | ❌ |
| ADMIN-03 | Confirmation recap lists quest, participant count, changed overrides only; results recap shows outcome, HP before→after, injuries, XP, level/title only when changed, spell | widget | `flutter test test/screens/innkeeper/components/completion_dialogs_test.dart` | ❌ |
| ADMIN-04 | `TeleportCharacter` document + service method (`TravelRequest` variables, `successful`) | unit | `flutter test test/graphql/travel_documents_test.dart` / `test/repository/services/graphql/graphql_travel_test.dart` | ✅ (extend) |
| ADMIN-04 | TeleportModeCubit: prepare → ready (character read) / read failure; teleportTo → succeeded / failed(code); same city → no call; cancel; acknowledgeSuccess → idle | bloc_test | `flutter test test/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit_test.dart` | ❌ |
| ADMIN-04 | Map in teleport mode: own pawn/route/paper/quest markers absent; selected pawn with name; drag to a city calls teleport; «Annulla»; failure text on the chip; pawn back | widget | `flutter test test/screens/mainScreen/tabs/map/world_map_teleport_test.dart` | ❌ |
| ADMIN-04 | Landing: Ready → jumpToPage(0); page ≠ 0 → cancel; jump to 0 does not cancel; Succeeded → panel re-pushed; role lost → cancel | widget | `flutter test test/screens/mainScreen/components/teleport_mode_landing_test.dart` | ❌ |
| ADMIN-04 | Availability: `isTeleportMode` blocks `isFreeBeneathRoutes` | bloc_test | `flutter test test/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_cubit_test.dart` | ✅ (extend) |
| ADMIN-04 | Drag regression: travel drag unchanged after the mixin/`dropTargetCity` extraction | widget | `flutter test test/screens/mainScreen/tabs/map/world_map_travel_test.dart` + `character_marker_layer_test.dart` | ✅ |
| ADMIN-05 | Override diff: unchanged participant omitted; HP equal omitted; zero quantities omitted; outcomes omitted when empty; JSON shape `ItemUsageInput`/`SpellUsageInput` | unit | `flutter test test/models/request/participant_override_test.dart` | ❌ |
| ADMIN-05 | Form controls: slider `1..max` default current (clamped, disabled at max ≤ 1); consumable steppers `0..owned` (loot only); spell steppers `0..remaining` | widget | `flutter test test/screens/innkeeper/components/completion_form_test.dart` | ❌ |
| ADMIN-06 | 28 chips with Italian labels; existing injuries selected+disabled; override carries only added | widget | same `completion_form_test.dart` | ❌ |
| ADMIN-07 | Hidden for adventurer and guard (and null role) | widget | `innkeeper_section_test.dart` | ❌ |
| ADMIN-07 | `FORBIDDEN` on `pendingRequests` as adventurer | manual (device/curl UAT) | — | manual-only: needs a live BE |
| ADMIN-08 | Audit rows for completion and teleport | manual (mongosh) | — | manual-only: BE data |

### Sampling Rate
- **Per task commit:** the touched test file(s) with `flutter test <file>` + `flutter analyze`.
- **Per plan:** every test file listed in the plan + `test/tool/schema_check_documents_test.dart` when documents change + the schema gate when documents change.
- **Phase gate:** `flutter analyze` (≤ 52 issues, 0 errors, 0 warnings), full `flutter test`, schema check 42/42 against BE `origin/develop` **after** the BE Phase 10 merge, then device E2E (BACKEND-NOTES §5 amended per C9).

### Wave 0 Gaps
- [ ] `settings_test.dart`: stub `MockAuthCubit` initial state (P2).
- [ ] `test/helpers/mocks.dart`: `MockInnkeeperRepository`, `MockTeleportModeCubit`, `MockPendingRequestsCubit`, `MockRequestCompletionCubit`.
- [ ] `test/helpers/fixtures/pending_request_fixtures.dart`: entry JSON builders (story, worldMission ×N, traveller, awaiting aid, busy with `pendingQuest`, malformed).
- [ ] Map/MainScreen harnesses: add `BlocProvider<TeleportModeCubit>` (and `AuthCubit` for the landing) to `world_map_travel_test.dart`, `world_map_availability_test.dart`, `main_screen_test.dart`, `main_screen_quest_results_test.dart`.
- [ ] No framework install needed.

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (unchanged; bearer via existing link) | — |
| V3 Session Management | yes (indirectly) | `AuthGate` pops root routes on session end (`auth_gate.dart:33-38`); the route cubit closes and the subscription is cancelled |
| V4 Access Control | yes | BE `@Roles(innkeeper)` + ownership guards (BE Phase 3); FE gate is UX only (role from `AuthCubit`); `FORBIDDEN` terminal handling |
| V5 Input Validation | yes | client-side bounds mirror BE limits (HP `1..max`, quantities ≥1 ≤ owned, ≤ 50, loot only, active spells within usages); the BE re-validates (`OUTCOME_OVERRIDE_INVALID`) |
| V6 Cryptography | no | — |
| V7 Error/Logging | yes | `debugPrint` with ids/codes only, never payloads or tokens (`graphql.md`); never print `.env` |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Non-innkeeper forging the client gate | Elevation | BE role guard (JWT role) answers `FORBIDDEN`; FE pops |
| Stale role after demotion (JWT snapshot) | Elevation | BE concern (HARDEN-02/Phase 12); FE hides the section on `userUpdated` |
| Double completion (two GM devices) | Tampering | BE single transaction: the loser gets `NOT_FOUND` → card removed |
| Holding other users' Twitch ids | Information disclosure | do not select `user { twitchId }` (not displayed, D-08); never log entries |
| Resubscribe hammering | DoS | bounded exponential backoff, terminal `FORBIDDEN` |
| Repudiation of admin actions | Repudiation | BE audit interceptor (`admin_audit_logs`) |

## Suggested wave order

Sequential executors without worktrees (project memory). One plan per wave.

1. **10-01 — Domain models and pure derivations (TDD, no Flutter).** `PendingRequest*`, `QueuedTravel`, `RequestCard` grouping/order/seats/visibility/canComplete, `ParticipantPresence`, `ParticipantOverride` diff, `CompletePendingRequestInput.toJson`, recap text builders; fixtures file. Covers ADMIN-02/05/06 logic.
2. **10-02 — Transport.** `PendingRequestFragment` (without `pendingQuest`), `GetPendingRequests`, `OnPendingRequestsUpdated`, `CompletePendingRequest`, `TeleportCharacter` (in `TravelMutations`, D-25); registry 38 → **42**; typed service methods; `InnkeeperFailure` + `InnkeeperRepository` (incl. `readCharacter` over `getCharacter`); schema check against BE `origin/develop` = 42/42.
3. **10-03 — `PendingRequestsCubit`.** Subscription, silent resubscribe, FORBIDDEN terminal, tick, endTime rereads, resume refetch, optimistic hide, close hygiene (`fake_async`).
4. **10-04 — Settings section + panel route + queue screen.** Shell providers (`InnkeeperRepository`, lazy `TeleportModeCubit` stub or placeholder interface), `openInnkeeperPanel`, `InnkeeperSection`, `InnkeeperPanelScreen` (cards, rows, empty state, loader, role-lost/FORBIDDEN pop), Settings test stub (Wave 0 gaps).
5. **10-05 — Completion.** `RequestCompletionCubit`, form (slider, chips, steppers), confirmation dialog (neutral style option), results recap, per-code errors (C2).
6. **10-06 — Teleport mode.** `TeleportModeCubit`; `MapAvailabilityState.isTeleportMode`; `pawn_dragging.dart` mixin + `MapUtils.dropTargetCity` extraction (hand-edit DIRTY files); `TeleportPawnLayer` + «Annulla» chip; `WorldMap` layer swap; `TeleportModeLanding` (jump, cancel on page ≠ 0 / role lost, re-push on success); «Teletrasporta» on panel rows. May be split into 10-06 (cubit + landing + panel action) and 10-07 (Map rendering) if the planner wants smaller plans.
7. **10-07 (or 10-08) — ⛔ GATED, WAITING FOR THE BE PHASE 10 PR MERGE ON BE `develop` (BE-HARD-08).** Select `pendingQuest` under `character` in `PendingRequestFragment` (one line), record the model fixture from the merged BE, run the full gate (`flutter analyze`, `flutter test`, schema check **42/42** against the merged `origin/develop`), then the **device E2E checkpoint** (BACKEND-NOTES §5 with the C9 identities: queue live, free traveller greyed → «Arrivato», busy lane hidden + `QUEST_IN_PROGRESS` from a stale client, teleport from a row, completion of story and worldMission with different overrides, `FORBIDDEN` as adventurer, audit rows), and write the outcome into `BACKEND-NOTES.md`. BE PR before FE PR.

## Sources

### Primary (HIGH confidence)
- FE code on `feat/10-admin-panel` (every file:line cited above).
- BE `origin/develop` (`8f30d1d`) `src/schema.gql`, `src/authz/roles/roles.guard.ts`, `src/auth/dev/dev-auth.strategy.ts` (read with `git show`, no checkout).
- BE handoffs on `origin/develop`: `.planning/phases/09-combat-result-admin-outcomes/BACKEND-NOTES.md` §2, §9, §11–§16; `.planning/phases/08-travel-lifecycle-travel-01/BACKEND-NOTES.md` §2, §7; `.planning/phases/03-autorizzazione-ownership-ruoli-audit/BACKEND-NOTES.md`.
- `~/.pub-cache/hosted/pub.dev/graphql-5.2.1/lib/src/links/websocket_link/websocket_client.dart` (resubscribe after reconnect).
- Probes (deleted): `PageController.jumpToPage` behaviour; unstubbed `MockAuthCubit.state`.
- Commands run: `flutter analyze` (52 issues, 0 errors, 0 warnings); schema check 38/38 OK; InjuryType FE ↔ BE diff (28/28); `dart format --output=none --set-exit-if-changed` per file.

### Secondary (MEDIUM confidence)
- BE working tree (read-only) `.planning/phases/10-hardening-trasversale/10-RESEARCH.md` F10/C22/Q18 (recommended `pendingQuest: ID` shape, not merged).

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH (nothing new; versions read from the pub cache and `flutter --version`).
- Architecture: HIGH (patterns copied from merged phases; provider visibility read from `main.dart`/shell).
- Pitfalls: HIGH (two probed, the rest read in code or BE source).
- BE-HARD-08 shape: MEDIUM (BE research recommendation, not merged).

**Research date:** 2026-10-29
**Valid until:** BE Phase 10 merge (re-check the `PendingRequestCharacter` SDL then), otherwise 30 days.
