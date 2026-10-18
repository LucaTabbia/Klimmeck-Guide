# Phase 4: Settings Screen - Context

**Gathered:** 2026-10-15
**Status:** Ready for planning

<domain>
## Phase Boundary

A **Settings tab** inside the game shell — the seventh item of the satchel menu and the seventh page of the `MainScreen` `PageView` — from which the player:

- toggles the three notification categories (**fine viaggio**, **streamer live**, **fine quest**), persisted locally per user and surviving app kill/restart (SET-02, SET-04);
- logs out through the existing confirmation dialog and atomic teardown (SET-03, Phase 11 D-11/D-12);
- **deletes the current character** with an explicit confirmation, after which the app returns to character creation (new requirement **SET-05**, added by user decision 2026-10-15; the deletion source anticipated by Phase 3 D-09).

Settings is a utility surface (chrome allowed by rule 1), but it lives as a tab under the satchel menu, so it adopts the *parchment sheet* language of the other tabs (no `AppBar`, no `Scaffold` chrome). The phase also delivers the menu rework needed to host a seventh item.

**Backend prerequisite (lockstep):** the backend has no character deletion mutation. It lands in the inserted companion **BE Phase 03.1 "Character Deletion Contract"** (`Klimmeck-Guide-BE/.planning/phases/03.1-character-deletion-contract/`), proposed in this phase's `BACKEND-NOTES.md`. The FE builds against the proposed contract with fakes, verifies the GraphQL documents against the regenerated `Klimmeck-Guide-BE/src/schema.gql` and runs the manual E2E before its PR; the BE PR merges first (same discipline as Phases 2 and 3).

Out of scope: notification permission prompt, OS-permission hints and any FCM wiring (Phase 5, NOTIF-01/02), syncing preferences to the backend, a "Cambia account" action, admin-only settings, app version/about rows, accessibility pass.

</domain>

<decisions>
## Implementation Decisions

### Entry point in the satchel menu (SET-01)
- **D-01:** Settings is the **seventh satchel item** and the **seventh `PageView` page (index 6)** of `MainScreen`. The menu overlay grid is reworked: the **Mappa** cell spans **one column wide and two rows tall** on the left; to its right a **2×3 grid** — row 1: **Profilo, Diario, Libreria**; row 2: **Bacheca, Negozio, Impostazioni**. The landing positions of the flying `MenuItem`s follow the same grid (today `index <= 2` → top row, else bottom row, hard-coded: must be generalised to the new layout). The app is landscape-only (`main.dart` locks `landscapeLeft/Right`), so a four-column overlay fits.
- **D-02:** The overlay label is **"Impostazioni"**, same `MenuSection` style as the other labels (`titleMedium`, `paleSilver`, `bordersForText`). The satchel icon is a **new Cloudinary SVG the user uploads separately** (naming per `docs/rules/assets.md`, snake_case). Until it exists, `CloudinaryAssets.settings` points to an **existing SVG as temporary placeholder** (planner picks, e.g. `pouch` or `emptySatchel`); swapping the path is the only change when the asset lands. `CachedSvg` renders an empty box on a missing asset, so a wrong path never crashes.
- **D-03:** Settings is **not** reachable from the character creation page, which keeps only its "Esci" action (Phase 2 D-07).

### Screen structure (SET-01, SET-03)
- **D-04:** Settings is a **tab, not a pushed route**: no `AppBar`, no `Scaffold`, satchel and overlay stay above it. Presentation like `Profile`: `BackgroundImage` + parchment sheet, the title **"Impostazioni"** in Cinzel at the top of the sheet, sections below, scrollable (`SingleChildScrollView`, bottom padding so the satchel never covers the last control).
- **D-05:** A header row with the **current character's name** (from `CharacterCubit`'s `CharacterLoaded`, via `BlocSelector`) sits above the sections. No other account data (the `User` carries only `twitchId`).
- **D-06:** Two sections: **"Notifiche"** (three switches) and **"Account"** ("Elimina personaggio", then "Esci"). **"Esci" is the last scrollable element**, an `ElevatedButton` in `bloodRed` as in `LogoutConfirmationDialog`, far from the toggles. Exact copy and spacing are Claude's discretion within `kg_theme.dart` tokens (no inline colours/`TextStyle`).
- **D-07:** Logout reuses **`confirmLogout(context)`** unchanged (confirmation dialog + `AuthCubit.logout()`, Phase 11 D-11/D-12). **No "Cambia account" button**: switching account is logout followed by a new login (the backend already sends `force_verify=true`, Phase 11 D-14).
- **D-08:** Material `Switch`es are acceptable on this surface; they are themed through `kg_theme.dart` (`SwitchThemeData` or equivalent), never per-widget colours.

### Notification toggles (SET-02, SET-04)
- **D-09:** Three categories, modelled as an enum (e.g. `NotificationCategory { travelEnd, streamerLive, questEnd }`). **Default: all enabled.**
- **D-10:** **Local only, `shared_preferences`**, behind an interface with an injectable `SharedPreferences` factory (pattern of `SecureSessionStore`). The backend is unaware: **no new contract**. Phase 5 reads these preferences on the device to decide whether to surface a notification in each of the three app states.
- **D-11:** Preferences are **keyed per user id on the device** (e.g. `klimmeck.notifications.<userId>.<category>`, or one JSON blob per user — planner's choice): a second account on the same phone has its own toggles. They are **not session artefacts**: logout (Phase 11 D-12 clears secure storage only) and the sync-lost teardown leave them untouched.
- **D-12:** **Persist immediately on tap, no Save button.** The switch is optimistic; if the write fails it reverts to the previous value with only a `debugPrint` (no error UI — the switch state is the whole feedback).
- **D-13:** **No OS-permission handling in this phase:** no hint, no link to system settings. Permission is requested in context by Phase 5 (NOTIF-02); Phase 5 may add a note under the toggles.
- **D-14:** The preferences must be readable **outside the widget tree** (Phase 5's background FCM handler runs in a separate isolate, where cubits do not exist): a Flutter-free store/repository that works standalone, plus the in-tree Cubit for the Settings UI. The store API (read current values, stream of changes) is Claude's discretion but must not depend on `BuildContext` or on `flutter_bloc`.

### Character deletion (SET-05 — in scope by user decision 2026-10-15)
- **D-15:** An **"Elimina personaggio"** action in the Account section (destructive styling, distinct from "Esci"). Confirmation is a **simple two-button dialog** like the logout one — "Sei sicuro di voler eliminare *<nome>*? L'azione è irreversibile." with **Annulla / Elimina** (`bloodRed`), `barrierDismissible: false`. No typed-name confirmation.
- **D-16:** Contract proposed to the backend (fixed in BE Phase 03.1 CONTEXT): **`deleteCharacter: User!` with no arguments** — identity from the bearer, acts on the caller's `currentCharacter`, archives it (**soft delete**, unlinked from the `User`) and returns the updated `User` with `currentCharacter: null` (same shape as `me`/`createCharacter`). Stable codes in `extensions.code`: **`CHARACTER_NOT_FOUND`** when the caller has no current character (second tap, concurrent call), plus the standard `UNAUTHENTICATED`. The FE maps codes, never messages. Details (name release, archived-document visibility, audit) are the backend's — see `BACKEND-NOTES.md`.
- **D-17:** On success the app **adopts the returned `User`** through `AuthCubit.adoptUser` (same path as creation, Phase 2 D-02/D-26): `SessionHome` routes to character creation silently (Phase 3 D-09), the gameplay subtree keyed by `characterId` is unmounted and the old `Character` stream dies (Phase 3 D-08). `userUpdated` (emitted by the backend's `users` change stream) is the **backup** if `adoptUser` refuses the user or the response is lost. Open dialogs/sheets are popped by the existing `AuthGate` behaviour (Phase 3 D-10).
- **D-18:** Failure handling: the dialog closes; an **inline domain message** appears in the Account section (by error code, never technical text, rule in `docs/rules/ui-ux.md`); the player may retry. While the mutation is in flight the "Elimina" button is disabled with an in-button progress (an explicit user action: loading allowed). `CHARACTER_NOT_FOUND` on a stale state → refetch `me`/adopt, same as `CHARACTER_ALREADY_EXISTS` in Phase 2.
- **D-19:** The mutation goes through a **Repository → Cubit** path (`docs/rules/architecture.md`): GraphQL document in `lib/graphql/mutations/character_mutations.dart` selecting `...UserFields`, error mapping in the repository (pattern of `CharacterCreationRepository._guard`), a Cubit in the Settings feature; the widget never calls the service. Dialogs open on the root `Navigator`: read the cubits before the `await` (see `AuthenticatedShell` doc comment).
- **D-20:** **Lockstep with BE Phase 03.1:** FE developed against the proposed contract with fakes/recorded `QueryResult`s; the last plan verifies the documents against the regenerated `Klimmeck-Guide-BE/src/schema.gql` (the existing `tool/schema_check` flow) and runs the manual E2E on device; **BE PR before FE PR**.
- **D-21:** The FE does **not** pre-check active travel/quest state before deleting; whether the backend refuses or cleans up pending state is the backend's call (open question in `BACKEND-NOTES.md`). With the dev bypass the mutation still hits the real backend (like `createCharacter`); the planner verifies that `DevAuthTokenService.adoptUser` accepts a `User` with `currentCharacter: null`.

### Claude's Discretion
- Feature folder and names (`lib/screens/mainScreen/tabs/settings/…`, `SettingsCubit` vs separate `NotificationPreferencesCubit` + `CharacterDeletionCubit`), per `docs/rules/naming.md` and `docs/rules/state-management.md`.
- Store key format (D-11), the store/repository API and how Phase 5 will consume it (D-14).
- The temporary placeholder asset (D-02) and the exact `CloudinaryAssets` constant name.
- How the `MenuItem`/`MenuBackground` geometry is generalised to the new grid (D-01) — a small layout model (cells with column/row/rowSpan) is welcome; Boy Scout on the `menuImages` `List` of maps in `SatchelMenu` if touched.
- Section copy, spacing and the destructive-button variants within `kg_theme.dart`.
- Where the new Cubits are provided (`AuthenticatedShell` `MultiBlocProvider` vs tab-local `BlocProvider`), as long as they close with the session subtree.
- Test layout (`test/screens/mainScreen/tabs/settings/…`, `test/repository/storage/…`) per `docs/rules/testing.md`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §"Phase 4: Settings Screen" — goal, success criteria 1–5 (SC 5 added 2026-10-15 for SET-05), decisions to make.
- `.planning/REQUIREMENTS.md` — SET-01..SET-05 (SET-05 added 2026-10-15); NOTIF-02/03 as the future consumers of the toggles.
- `.planning/PROJECT.md` §"Key Decisions" — "Backend fonte di verità", dev bypass kept until Phase 12.
- `.planning/phases/04-settings-screen/BACKEND-NOTES.md` — the `deleteCharacter` proposal and the open questions for the backend (written in this discuss).

### Prior phase decisions this phase builds on
- `.planning/phases/11-auth-session-bootstrap/11-CONTEXT.md` — D-11 (logout always confirmed), D-12 (teardown order; secure storage only), D-14 (account switch = logout + login), D-24/D-29 (dev stub `logout()`/`DEV_AUTH_START_SIGNED_OUT`), D-38 (never `dart format` whole directories).
- `.planning/phases/02-character-creation/02-CONTEXT.md` — D-01 (`SessionHome` branches on `currentCharacter`), D-02/D-26 (`adoptUser` after a mutation that returns `User`), D-07 ("Esci" on creation), D-33 (schema check before PR, BE PR first).
- `.planning/phases/03-real-time-sync-foundation/03-CONTEXT.md` — D-07 (`adoptUser` is the single entry for `User` changes), D-08 (shell keyed by `characterId`), D-09 (`currentCharacter → null` routes to creation silently; deletion from Settings is one of its two sources), D-10 (root routes popped on character change), D-11 (logout teardown).
- `.planning/phases/03-real-time-sync-foundation/BACKEND-NOTES.md` §"Phase 4 (Settings)" note — deletion relies on `userUpdated.currentCharacter == null`.

### Backend (separate repo — contract and current implementation)
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/03.1-character-deletion-contract/03.1-CONTEXT.md` — the BE decisions on `deleteCharacter` (soft delete, name release, visibility, codes) — **the FE follows these names**.
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/03-autorizzazione-ownership-ruoli-audit/BACKEND-NOTES.md` — `userUpdated` snapshot semantics, ownership rules, `FORBIDDEN`/`NOT_FOUND` codes.
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/02.1-character-creation-contract/BACKEND-NOTES.md` — `createCharacter: User!` pattern the deletion mirrors (identity from bearer, `User` returned, selection `currentCharacter { id }`).
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/schema.gql` — generated schema; **wins** over every document. `deleteCharacter` appears only after BE 03.1 ships.

### Project rules
- `docs/rules/ui-ux.md` — chrome rule, "azioni distruttive con conferma", error-state copy, theme-only styles, `semanticLabel`, 44×44 targets.
- `docs/rules/architecture.md` — UI → Cubit → Repository → Service; `lib/repository/storage/` for local persistence.
- `docs/rules/state-management.md` — Cubit rules (Flutter-free, DI by constructor, `close()` cleanup).
- `docs/rules/naming.md`, `docs/rules/assets.md` (Cloudinary constants, `CachedSvg`), `docs/rules/testing.md`, `docs/rules/workflow.md` (branch `feat/04-settings-screen`, PR to `develop`, planning docs committed with the code).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/shared/components/modal/logout_confirmation_dialog.dart` — `confirmLogout(context)` is the ready-made SET-03 entry point (reads `AuthCubit` before the `await`); `LogoutConfirmationDialog` is the visual template for the deletion dialog (D-15).
- `lib/screens/auth/cubit/auth_cubit.dart` — `adoptUser(User)` and `logout()`.
- `lib/screens/mainScreen/tabs/profile/profile.dart` — the parchment-sheet tab pattern (`BackgroundImage` + `parchment` container + `BlocSelector<CharacterCubit, …>`), including the character name source for D-05.
- `lib/repository/storage/session_store.dart` — `SecureSessionStore`: interface + implementation with injectable `SharedPreferences.getInstance`, the pattern for the preferences store (D-10). `lib/repository/storage/storage_manager.dart` is a legacy static wrapper: do not extend it.
- `lib/graphql/mutations/character_mutations.dart` + `lib/graphql/fragments/user_fragment.dart` — `createCharacter` document selecting `...UserFields`; `deleteCharacter` follows the same shape.
- `lib/repository/character_creation_repository.dart` — `_guard` error-code mapping from `OperationException` to a typed failure; mirror it for deletion.
- `lib/config/cloudinary_assets.dart` §Menu — where `settings` joins `map`, `mirror`, `journal`, `library`, `board`, `shop`, `pouch`.
- `lib/shared/components/cached_svg.dart` — empty box on missing asset (safe placeholder behaviour).
- `tool/schema_check/` — the document-vs-schema verification used before the Phase 3 PR (D-20).

### Established Patterns
- `MainScreen._buildPages` returns the six tabs in index order matching `SatchelMenu.menuImages` and the `MenuSection` indices; the three must change together (D-01).
- `MenuItem` computes landing positions with `index <= 2` → top row, else bottom row, and `MenuBackground` hard-codes two `Row`s of three `MenuSection`s with a 456 px divider: the geometry to generalise.
- Session subtree: `AuthenticatedShell` provides the gameplay cubits (closed on logout/character change, `SafeEmit`); routes opened with `showDialog` live on the root `Navigator` outside those providers.
- `AuthGate._leavesSession`/character-change handling pops root routes (Phase 3 D-10) — nothing to add for the deletion dialog.
- Landscape-only app (`main.dart` `setPreferredOrientations`).
- No `lib/routes`: navigation inside the shell is the `PageView`; the only pushed routes are dialogs/sheets.

### Integration Points
- `SatchelMenu.menuImages` (+1 entry), `MenuBackground` grid, `MenuItem` geometry, `MainScreen._buildPages` (+ `Settings` tab at index 6).
- `AuthenticatedShell` `MultiBlocProvider` (or tab-local provider) for the new Cubits; the preferences store created at the composition root (`main.dart`) or lazily in the repository.
- `AuthCubit.adoptUser` after `deleteCharacter`; `SessionHome` already routes on `currentCharacter == null`.
- Phase 5 will inject the preferences store into its notification display path (foreground banner, background handler).

</code_context>

<specifics>
## Specific Ideas

- User (2026-10-14): *"Settima voce nella borsa. Lo slot della mappa prende le dimensioni di una casella in larghezza e due in altezza. bisogna creare un nuovo asset da aggiungere a cloudinary, lo farò separatamente."* — the Mappa cell is 1 column × 2 rows; the Settings icon asset is the user's deliverable, outside this phase.
- User (2026-10-15): character deletion is in scope *now*, with backend work; *"crea direttamente il necessario anche sul repo BE"* — BE Phase 03.1 inserted and its CONTEXT written in this discuss.
- Deletion confirmation is deliberately the lighter two-button dialog, not a typed-name gate.

</specifics>

<deferred>
## Deferred Ideas

- **"Cambia account" button** in Settings (logout + immediate login, Phase 11 D-14) — not needed; the sign-in screen covers it.
- **OS-permission hint / link to system settings** under the toggles — Phase 5 (NOTIF-02) decides once the permission flow exists.
- **Syncing notification preferences to the backend** (server-side suppression, multi-device coherence) — only if a real need appears; noted for BE Phase 5 in `BACKEND-NOTES.md` §5.
- **Typed-name confirmation** for deletion — rejected for now; revisit if accidental deletions are reported.
- **A notice after deletion** on the creation page ("Il tuo personaggio è stato eliminato") — Phase 3 D-09 keeps the transition silent.

</deferred>

---

*Phase: 04-settings-screen*
*Context gathered: 2026-10-15*
