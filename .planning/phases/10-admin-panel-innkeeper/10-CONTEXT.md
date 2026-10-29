# Phase 10: Admin Panel (innkeeper) - Context

**Gathered:** 2026-10-29 (interactive discuss, same session as the planning of the BE Phase 10; the BE companion rule BE-HARD-08 was added to the BE Phase 10 context in the same session)
**Status:** Ready for planning (**no UI phase**, same rule as Phases 4, 6, 7, 8 and 9: every visual Claude builds is provisional). The plan that selects the BE-HARD-08 field and the final gate wait for the BE Phase 10 PR (D-07, D-24); everything else can start now.

<domain>
## Phase Boundary

When `User.role == innkeeper`, the streamer opens from Settings a dedicated, full-screen utility surface («Locanda») that shows the **live queue of the pending `story` and `worldMission` requests** and lets the game master **complete** each request after the live session, telling what happened to every participant (HP left, injuries, consumables and spells used) through a form with an explicit confirmation, and **teleport** a queued character by dragging its pawn on the game Map. Every mutation is enforced and audit-logged by the backend (BE Phases 3 and 9, already on BE `develop`); the frontend hides what the role cannot use and reacts to the authoritative state.

What the backend already fixed and this phase inherits (BE Phase 9 D-03/D-04, user decisions): **there is no reject** — a story/worldMission can only end well and stays in the queue until the GM completes it; **there is no grade, no monster and no reward selection** at runtime — monsters and rewards are catalogue data, the GM only overrides HP, injuries, consumables and spells; **story and worldMission never start a travel** (automatic travel exists only for the standard lane).

Out of scope: a list of all characters or a standalone teleport tool (user: «Solo la coda»), admin CRUD of quests/enemies/POIs, reject with refund, an audit viewer, hardening of the admin endpoints on the FE side (HARDEN-02, Phase 12), iOS.

</domain>

<decisions>
## Implementation Decisions

### Access and structure (ADMIN-01)
- **D-01 (user decision):** the panel is reached **from Settings**: a section «Locanda» rendered only when the session user has `role == innkeeper` (read from the `AuthCubit` user, live through `userUpdated`: the section appears or disappears with the role), with one button that **pushes a full-screen route on the root Navigator**. It is a utility surface (Phase 4 precedent): `Scaffold`, `AppBar` with the title «Locanda» and the back arrow, Material controls are allowed; parchment background and `kg_theme.dart` tokens only. The satchel grid, `SatchelLayout` and the `PageView` do not change (the 4×2 grid is full: Mappa spans two rows, seven entries fill eight cells).
- **D-02 (user decision):** **the innkeeper always has a character**: the streamer plays like everybody else, the character-creation page stays mandatory and unchanged (Phase 4 D-03 holds: nothing is reachable from the creation page), the panel lives inside the authenticated shell. No shell without a character, no special boot path.
- **D-03 (user decision — «Solo la coda»):** the panel is **one screen with one list: the queue**. No «Personaggi» tab, no standalone teleport tool: the teleport action lives on a participant row of the queue, so **a character without a pending story/worldMission request is not teleportable from the panel** (ADMIN-04 amended). A list of all characters is a deferred idea.
- **D-04 (technical default):** the route lives on the root Navigator outside the shell providers (Phase 7 Pitfall 5): the queue cubit is created for the route (subscription opened when the panel opens, closed when it pops) and the Map hand-off of the teleport goes through a shell-level cubit (D-15/D-17); a lost role (`FORBIDDEN` at subscribe or `userUpdated` without `innkeeper`) pops the panel silently. Naming and split per `docs/rules/naming.md` and `docs/rules/architecture.md` (planner).

### The queue (ADMIN-02)
- **D-05 (user decision):** **one card per quest** (entries grouped by `quest.id` within the same lane): a story card has one participant; a worldMission card lists the registered participants with the seats «k/N» (sum of `requiredAdventurers[].count` vs the entries). One «Completa» per card = one `completePendingRequest(pendingQuestId)` call with the `PendingRequest.id` of the first entry (the BE closes the request for every registered participant, BE §9).
- **D-06 (user decision):** a participant on a **free travel** (city to city) stays visible, **greyed**, with «In viaggio» and the remaining time (from `activeTravel.endTime` against the server clock, `ServerClockService` + `formatGameDuration`); the card's «Completa» is **disabled while any listed participant travels**. User clarification (verbatim, 2026-10-29): *«story e worldMission non richiedono alcun viaggio»* — confirmed by the BE (`quest-acceptance.service.ts`: automatic travel only for the standard lane), so a travelling participant is always on a free travel and arrives at a city marker. Once `endTime` has passed the row reads «Arrivato» even before the next emission (the BE queue does not re-emit on arrival; D-18).
- **D-07 (user rule, verbatim 2026-10-29):** *«Nessun personaggio che ha accetato una quest, che sia in viaggio o in combattimento, non deve comparire nella lista dei pending che l'admin può gestire. Se sei in viaggio da una città all'altra invece questa regola non vale»*, clarified as: a character whose **standard lane is occupied** (`quests.pendingQuest` set — travelling to that quest or in its waiting time/combat) **is not shown** in the queue; a free travel does not hide him (D-06). The queue entry does not carry the standard lane today: the **BE Phase 10 (BE-HARD-08, user decision)** adds the additive field `PendingRequestCharacter.pendingQuest: ID` (null when the lane is free) and makes `completePendingRequest` refuse with `QUEST_IN_PROGRESS` while any registered active participant has the lane occupied (proposal in `BACKEND-NOTES.md` §2). FE rule: a story card whose character is busy disappears; a worldMission card drops the busy participant from its list, shows «k presenti su N registrati» and keeps «Completa» disabled with the caption «Un partecipante è impegnato in una missione» until the lane frees (**technical default derived from the user rule — listed in the summary for veto**). Until the BE field lands the rule is coded against the proposed field with fakes (D-24).
- **D-08 (user decision — «Minime»):** each participant row shows only the **character name and the state** («Presente» / «In viaggio · 12 min» / «Arrivato» / «In attesa di soccorso» from `awaitingAid`); the card header shows the **quest title** and its Italian type label (`QuestType.label`, Phase 9) plus the seats for a worldMission. User, points spent, location name, HP and injuries are **not** on the card: everything else lives in the completion form (D-11).
- **D-09 (user decision):** **BE order** (`startDate` ascending, travellers last, then id; a card takes the rank of its earliest entry) and an **empty state on parchment**: «Nessuna richiesta in attesa» with the note «La coda si aggiorna da sola».
- **D-10 (technical default):** the source is the **subscription `pendingRequestsUpdated`** (innkeeper-only; snapshot at subscribe, then the full list at every PendingQuest insert/delete, BE §9), opened by the route's cubit with the Phase 3 reconnection policy (silent resubscribe, snapshot replaces the list); the query `pendingRequests` is the **refetch** used by D-18. A loader is allowed when the panel opens until the first snapshot (explicit user action, rule 2); after that the list only replaces itself, never shows a spinner. Entries are parsed item by item (a malformed entry is skipped with a debug log, the list survives — Phase 9 IN-04 lesson).

### Completion and the account of the fight (ADMIN-03, ADMIN-05, ADMIN-06)
- **D-11 (user decision — «Sempre il form»):** one action per card, «Completa», opens the **completion form** with a section per listed participant; the defaults mean «no change» (HP = current, no new injury, nothing used); «Conferma» at the bottom opens the **confirmation dialog** (the shared `DestructiveConfirmationDialog`, or a neutral-styled variant of it at Claude's discretion) with the recap (quest, number of participants, the overrides that differ from the defaults); on «Conferma» the FE calls `completePendingRequest` with `outcomes` **only for the participants whose values differ from the defaults** (an untouched participant is omitted: the BE keeps HP intact, BE §9). No quick path without the form (the recommended two-button variant was overruled).
- **D-12 (user decision):** controls per participant, data loaded with `character(id)` when the form opens (the innkeeper may read any character, BE Phase 3; a loader is allowed here, explicit action): **HP** as a slider `1..maxLifePoints` with the number beside it, default `currentLifePoints`; **injuries** as multi-select chips of the 28 `InjuryType` with the Italian labels of `InjuryTypeExtension.label`, the injuries the character already has shown as inactive chips (the override carries only the injuries **added**); **consumables** as the list of `assets.ownedItems` (loot items) each with a stepper `0..owned`; **spells** as the list of `assets.activeSpells` each with a stepper `0..remaining usages` (from `status.spellStates`). The wire input is `ParticipantOverrideInput { characterId, hpAfter?, injuries?, consumablesUsed? [{ item, quantity }], spellsUsed? [{ spell, usages }] }` (BE §1/§9).
- **D-13 (user decision):** after the mutation returns the created `[QuestResult!]!`, the panel shows a **results recap** per character (outcome label, HP before → after, injuries added, XP gained, level and title only when they change, spell learned) in a sheet or dialog on the panel; the card leaves the list with the next queue emission (an optimistic removal is Claude's call). The Phase 9 full-screen sheet is not reused here: the players get their own sheet on their devices.
- **D-14 (user decision):** errors **per code, inline in the panel** (utility surface: `SnackBar` and inline texts allowed) through a failure classifier like the other repositories: `NOT_FOUND` (completed by a concurrent call or request gone) → the card is removed and «Richiesta non più disponibile»; `QUEST_IN_PROGRESS` (BE-HARD-08) → «Un partecipante è impegnato in una missione», list refetched; `OUTCOME_OVERRIDE_INVALID` / `OUTCOME_NOT_PARTICIPANT` → error under the participant section, form kept; `FORBIDDEN` → the panel pops; network → «Riprova» with the form preserved. No generic in-app banner for these.

### Teleport (ADMIN-04)
- **D-15 (user, verbatim 2026-10-29):** *«Aprirei la mappa, con la pedina che invece di indicare il mio personaggio, indica il personaggio che ho selezionato. A quel punto posso spostare la pedina a mano»*. Flow: «Teletrasporta» on a participant row → the panel route pops → the shell jumps to the **Map tab in teleport mode** (the tab-jump pattern of `NotificationIntentLanding`): the Map shows **only the selected character's pawn** at its current location (`PendingRequestCharacter.location` is a POI id: the coordinates come from the cities cache when it is a city marker, otherwise from `pointOfInterest(id)` or `character(id)` — researcher), with the character's name floating above it; the innkeeper's own pawn, travel route, labels and quest paper are hidden; the pawn is draggable with the Phase 7 drag (same drop rule: the city containing the release point, else the nearest).
- **D-16 (user decision):** **no confirmation**: on release the FE calls `teleportCharacter({ id: characterId, poiId: city.markerLocation.id })` at once (any POI is accepted by the BE, the drop targets of this phase are the **city markers**, Phase 7 geometry; inner POIs as drop targets are deferred). A chip «Annulla» on the Map leaves teleport mode without calling.
- **D-17 (user decision):** after a successful teleport the Map leaves teleport mode (own pawn back) and **the panel route is pushed again** with the live queue. A failure keeps teleport mode with the error inline on the Map chip («Il personaggio è in una missione in corso» for `QUEST_IN_PROGRESS`, «Personaggio o luogo non trovato» for `NOT_FOUND`, network → «Riprova») and the pawn back at its origin. Teleport mode also ends on tab change, on a lost role and at session end (technical default).
- **D-18 (technical default):** the queue re-emits only on PendingQuest insert/delete, never on a location or travel change of a queued character (BE §9): the panel **refetches `pendingRequests`** after an own teleport succeeds, when a listed travel's `endTime` passes, when the panel is (re)opened and on app resume. No BE change is requested for this (optional emission on location change listed as a question in `BACKEND-NOTES.md`).
- **D-19 (user decision — «Disabilita in anticipo»):** satisfied by the hiding rule D-07: a listed participant never has an occupied standard lane, so the «Teletrasporta» action is shown on every listed row without an extra query; a residual `QUEST_IN_PROGRESS` from a race is handled by D-17. A participant on a free travel can be teleported (the BE clears the travel in the same operation, ADMIN-04).
- **D-20 (user decision):** in teleport mode the innkeeper's **own pawn disappears**: only the selected character's pawn is on the Map, with its name label; no second pawn.

### Requirements amended by this discuss (recorded in REQUIREMENTS.md)
- **D-21:** ADMIN-02 (standard lane hidden, free travel greyed), ADMIN-03 (complete only, through the form with an explicit confirmation; no reject), ADMIN-04 (from a queue row, by dragging the pawn on the Map to a city marker, no confirmation), ADMIN-05 (no grade, monsters or rewards: overrides of HP, consumables and spells), ADMIN-06 (injuries as chips in the same form). ADMIN-07 and ADMIN-08 are **delivered by the BE** (Phase 3 `@Roles(innkeeper)` + audit interceptor, Phase 9 `completePendingRequest`, Phase 8 `teleportCharacter`): the FE pins the hidden entry for a non-innkeeper with a widget test and the device UAT calls `pendingRequests` as an adventurer expecting `FORBIDDEN`; HARDEN-02 stays in Phase 12.

### Process and quality
- **D-22:** **No UI phase, no UI-SPEC** (Phases 4–9 precedent): provisional visuals, `kg_theme.dart` tokens, Material controls allowed on this utility surface, existing parchment assets, no new Cloudinary asset (an icon for the Settings button is not needed).
- **D-23:** **TDD red → green → refactor:** unit tests for the `PendingRequest` parsing (entry by entry, optional `pendingQuest`), the grouping by quest, the hiding/greying rules (busy lane, free travel, arrival by time), the order, the override diff (only changed participants), the failure classifiers, the teleport mode state machine; widget tests for the Settings section gated by role, the queue cards and their disabled states, the form controls and the confirmation recap, the Map in teleport mode (own pawn absent, selected pawn draggable, «Annulla»); `flutter analyze` with no new issues; `dart format` only on touched files (Phase 11 D-38); `tool/schema_check` against `git -C <BE> show origin/develop:src/schema.gql` in the gate plan.
- **D-24:** the FE develops against the BE contract already on `develop` (`pendingRequests`, `pendingRequestsUpdated`, `completePendingRequest`, `teleportCharacter`, `character(id)`) and against the **BE-HARD-08 proposal** (`BACKEND-NOTES.md` §2) with fakes and recorded `QueryResult`s (pattern of Phases 3–9); `PendingRequest.fromJson` treats `character.pendingQuest` as optional. The plan that selects `character.pendingQuest` in the registered documents and the device E2E run **after the BE Phase 10 PR is merged** on BE `develop` (same gate pattern as 08-12 and 09-12). BE PR before FE PR.
- **D-25:** Boy Scout within scope: `TravelMutations` gains the teleport document next to `startTravel`; the ROADMAP «Decisions to make during discuss step» of this phase are closed; nothing else outside the touched lines.

### Claude's Discretion
- Copy and layout of the cards, the form and the recap (provisional); whether the confirmation dialog gets a neutral (non-red) style; optimistic removal of a completed card (D-13); the loader look on panel open and form open; the exact refetch triggers beyond D-18; how the teleport mode is modelled (new cubit vs an extension of `MapAvailabilityCubit`/`TravelCubit`) provided the Map-only presenter of Phase 9 keeps working; how the selected character's coordinates are resolved (D-15); whether «Arrivato» rows need a subtle colour; the grouping key when the same quest appears in both lanes (impossible today: story and worldMission are different quest types).

</decisions>

<specifics>
## Specific Ideas

- The user's verbatim rules of 2026-10-29 are quoted in D-07 (hiding rule and its clarification) and D-15 (teleport on the Map); every answer is recorded in `10-DISCUSSION-LOG.md`.
- Four recommended options were overruled by the user: the panel is **only the queue** (no «Personaggi» list, D-03); the row content is **minimal** (D-08); the completion **always goes through the form** (no quick «Completa», D-11); the teleport destination is chosen **by dragging the pawn on the Map, with no confirmation** (D-15/D-16) and the FE **disables in advance** instead of letting the BE refuse (D-19, satisfied by D-07).
- Product rule added by this discuss on the BE side (user decision): a character busy with a standard quest is **not manageable** by the GM — hidden on the FE, refused by the BE (`QUEST_IN_PROGRESS` on `completePendingRequest`, BE-HARD-08).
- The ROADMAP «Decisions to make during discuss step» are closed: placement = Settings → full-screen route (D-01); the admin panel is a utility surface with UI chrome (D-01).

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Backend contract consumed (already on BE `develop`)
- `../Klimmeck-Guide-BE/.planning/phases/09-combat-result-admin-outcomes/BACKEND-NOTES.md` — §9 «Coda e completamento del GM» (queue shape, one entry per character and lane, order, `completePendingRequest` input and semantics, audit), §1 SDL (`PendingRequest*`, `CompletePendingRequestInput`, `ParticipantOverrideInput`, `QuestResult`), §2 codes (`OUTCOME_OVERRIDE_INVALID`, `OUTCOME_NOT_PARTICIPANT`, `NOT_FOUND`, `FORBIDDEN`), §11 placeholder rules, §12 UAT data, §13 deferred UAT checklist items 8–10.
- `../Klimmeck-Guide-BE/.planning/phases/08-travel-lifecycle-travel-01/BACKEND-NOTES.md` — §7 teleport (`teleportCharacter(request: TravelRequest!)`, any POI, order of evaluation), §2 codes (`QUEST_IN_PROGRESS`, `FORBIDDEN`, `NOT_FOUND`).
- `../Klimmeck-Guide-BE/.planning/phases/03-autorizzazione-ownership-ruoli-audit/BACKEND-NOTES.md` — roles, audit log, wire forms of `FORBIDDEN` on HTTP and WS, innkeeper read access to any character.
- `../Klimmeck-Guide-BE/src/schema.gql` on `origin/develop` — the schema wins over every note.

### Backend companion (BE Phase 10, BE-HARD-08, proposed by this phase)
- `.planning/phases/10-admin-panel-innkeeper/BACKEND-NOTES.md` — the FE proposal: `PendingRequestCharacter.pendingQuest: ID`, `QUEST_IN_PROGRESS` on `completePendingRequest`, the FE behaviour the BE should know, UAT plan.
- `../Klimmeck-Guide-BE/.planning/phases/10-hardening-trasversale/10-CONTEXT.md` — D-23/D-24 (the BE side of the rule, fixed in the same session).

### Frontend decisions carried forward
- `.planning/phases/04-settings-screen/04-CONTEXT.md` — D-01..D-06 (Settings as a parchment tab with sections, utility surface), D-17 (routes on the root Navigator outside the shell providers).
- `.planning/phases/07-travel/07-CONTEXT.md` — D-01..D-05 (pawn drag, drop rule, travel confirmation sheet) and the Pitfall 5 on root-Navigator routes.
- `.planning/phases/09-combat-result-sheet/09-CONTEXT.md` — D-06/D-07/D-23 (`MapAvailabilityCubit`, Map-only presenter: teleport mode must not break it), D-16 (awaiting-aid derivations).
- `.planning/phases/03-real-time-sync-foundation/03-CONTEXT.md` — reconnection policy for subscriptions (silent resubscribe, snapshot, terminal `FORBIDDEN`/`NOT_FOUND`).
- `.planning/phases/05-notifications-infrastructure/05-CONTEXT.md` — D-15 tab-jump pattern (`NotificationIntentLanding`).
- `.planning/REQUIREMENTS.md` §«Admin Panel (innkeeper role)» — ADMIN-01..08 as amended on 2026-10-29.
- `.planning/ROADMAP.md` §«Phase 10: Admin Panel (innkeeper)» — goal and success criteria as amended on 2026-10-29.
- `docs/rules/naming.md`, `docs/rules/architecture.md`, `docs/rules/state-management.md`, `docs/rules/graphql.md`, `docs/rules/ui-ux.md`, `docs/rules/testing.md`, `docs/rules/workflow.md` — project rules (naming, layers, cubit shape, documents and schema check, utility vs gameplay chrome, TDD, branch/PR).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/screens/mainScreen/tabs/settings/settings.dart` + `components/settings_section.dart`, `account_section.dart`: the sectioned parchment page where the «Locanda» section goes; `AuthCubit` user (`User.role`, `RoleType.innkeeper`) for the gate.
- `lib/shared/components/modal/destructive_confirmation_dialog.dart`: root-Navigator confirmation dialog returning a bool (D-11); `paper_sheet_modal.dart` for a parchment sheet if the recap uses one.
- `lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart` (`Draggable` pawn, `_handleDragEnd` with `MapUtils.findCityContainingPoint`/`findNearestCity`, `_TravelLabel`), `world_map.dart` (`_handleCharacterDragEnd`, `onDragEnd` wiring), `mapAvailabilityCubit/` (isMapPage/isPawnDragging signals): the drag mechanics to reuse for the teleport mode (D-15).
- `lib/screens/mainScreen/components/notification_intent_landing.dart`: pops root routes and `jumpToPage(0)` to the Map — the hand-off pattern for «open the Map in teleport mode».
- `lib/models/enums/injury_type.dart` (`InjuryTypeExtension.label`, 28 labels), `lib/models/enums/quest_type.dart` (`QuestType.label`), `lib/utils/game_duration_format.dart` (`formatGameDuration`), `lib/repository/services/time/server_clock_service.dart` (server offset for the remaining time).
- `lib/models/character/*` (`status.currentLifePoints`, `maxLifePoints`, `injuries`, `spellStates`, `assets.ownedItems`, `activeSpells`), `lib/models/pending_quest.dart`, `lib/models/quest_result/*` (parsing of the returned results), `lib/graphql/queries/character_queries.dart` (`getCharacter`), `lib/graphql/mutations/travel_mutations.dart` (where `teleportCharacter` is added), `tool/schema_check/schema_check_documents.dart` (registry of every named document).
- Failure classifiers (`lib/repository/*_failure.dart`) and repositories (`*_repository.dart`) as the pattern for the admin repository and its codes.

### Established Patterns
- Utility surfaces may use `Scaffold`/`AppBar`/Material controls (Settings, creation); gameplay screens may not — the panel is utility, the Map in teleport mode is gameplay (no chrome besides the «Annulla» chip in the Map's own style).
- Cubits of the shell are created in `lib/screens/auth/authenticated_shell.dart`; routes on the root Navigator receive them with `BlocProvider.value` (Phase 7 Pitfall 5).
- Subscriptions follow the Phase 3 policy (resubscribe silently, snapshot replaces state, terminal codes stop quietly); lists are parsed entry by entry (Phase 9 IN-04).
- Documents live in `lib/graphql/{queries,mutations,subscriptions}` with fragments in `lib/graphql/fragments`, every named operation registered in the schema-check registry; the gate plan runs `tool/schema_check` against BE `origin/develop`.
- TDD with `bloc_test`/`mocktail`, widget tests with `tester.getTopLeft` for geometry when it matters; `dart format` only on touched files.

### Integration Points
- `Settings` → new «Locanda» section → `Navigator.of(context, rootNavigator: true).push(...)` of the panel route.
- Panel route → queue cubit (subscription + refetch) → completion form → `completePendingRequest` → recap.
- Panel row «Teletrasporta» → shell-level teleport-mode state → `MainScreen` page jump → `WorldMap`/`CharacterMarkerLayer` render the selected pawn → `teleportCharacter` → panel pushed again.
- `KlimmeckGraphQl` service: new methods for the four documents (queue query/subscription, completion, teleport) and the existing `getCharacter`.

</code_context>

<deferred>
## Deferred Ideas

- A «Personaggi» list of all active characters in the panel (teleport of a character without pending requests, search by name) — user chose «Solo la coda»; backlog.
- Inner POIs of a city as drop targets of the teleport (today only city markers are targets) — backlog.
- A BE emission of the queue when a queued character's location or travel changes (today insert/delete of PendingQuest only) — optional, asked as a question in `BACKEND-NOTES.md`; the FE refetches on its own triggers.
- Reject with refund of a story/worldMission — excluded by the user in the BE Phase 9.
- An audit viewer in the app — out of scope (no GraphQL read of `admin_audit_logs`).

</deferred>

---

*Phase: 10-admin-panel-innkeeper*
*Context gathered: 2026-10-29*
