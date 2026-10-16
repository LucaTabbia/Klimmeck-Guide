# Phase 4: Settings Screen - Research

**Researched:** 2026-10-16
**Domain:** Flutter / `flutter_bloc` Cubits, `shared_preferences` 2.5.x (`SharedPreferencesAsync`), GraphQL mutation `deleteCharacter`, satchel-menu geometry, parchment-sheet tab
**Confidence:** HIGH (every claim about FE code was read in this repo at the cited line; BE contract read from the final BE handoff and `src/schema.gql`; the new document was validated against the real schema with the BE `graphql` 16.11.0). MEDIUM only on real-device behaviour of `SharedPreferencesAsync` inside a Phase 5 background isolate (documented by the plugin README, not exercised here) and on the narrow-screen overlay width (computed, not run on a device).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Entry point in the satchel menu (SET-01)**
- **D-01:** Settings is the **seventh satchel item** and the **seventh `PageView` page (index 6)** of `MainScreen`. The menu overlay grid is reworked: the **Mappa** cell spans **one column wide and two rows tall** on the left; to its right a **2×3 grid** — row 1: **Profilo, Diario, Libreria**; row 2: **Bacheca, Negozio, Impostazioni**. The landing positions of the flying `MenuItem`s follow the same grid (today `index <= 2` → top row, else bottom row, hard-coded: must be generalised to the new layout). The app is landscape-only (`main.dart` locks `landscapeLeft/Right`), so a four-column overlay fits.
- **D-02:** The overlay label is **"Impostazioni"**, same `MenuSection` style as the other labels (`titleMedium`, `paleSilver`, `bordersForText`). The satchel icon is a **new Cloudinary SVG the user uploads separately** (naming per `docs/rules/assets.md`, snake_case). Until it exists, `CloudinaryAssets.settings` points to an **existing SVG as temporary placeholder** (planner picks, e.g. `pouch` or `emptySatchel`); swapping the path is the only change when the asset lands. `CachedSvg` renders an empty box on a missing asset, so a wrong path never crashes.
- **D-03:** Settings is **not** reachable from the character creation page, which keeps only its "Esci" action (Phase 2 D-07).

**Screen structure (SET-01, SET-03)**
- **D-04:** Settings is a **tab, not a pushed route**: no `AppBar`, no `Scaffold`, satchel and overlay stay above it. Presentation like `Profile`: `BackgroundImage` + parchment sheet, the title **"Impostazioni"** in Cinzel at the top of the sheet, sections below, scrollable (`SingleChildScrollView`, bottom padding so the satchel never covers the last control).
- **D-05:** A header row with the **current character's name** (from `CharacterCubit`'s `CharacterLoaded`, via `BlocSelector`) sits above the sections. No other account data (the `User` carries only `twitchId`).
- **D-06:** Two sections: **"Notifiche"** (three switches) and **"Account"** ("Elimina personaggio", then "Esci"). **"Esci" is the last scrollable element**, an `ElevatedButton` in `bloodRed` as in `LogoutConfirmationDialog`, far from the toggles. Exact copy and spacing are Claude's discretion within `kg_theme.dart` tokens (no inline colours/`TextStyle`).
- **D-07:** Logout reuses **`confirmLogout(context)`** unchanged (confirmation dialog + `AuthCubit.logout()`, Phase 11 D-11/D-12). **No "Cambia account" button**: switching account is logout followed by a new login (the backend already sends `force_verify=true`, Phase 11 D-14).
- **D-08:** Material `Switch`es are acceptable on this surface; they are themed through `kg_theme.dart` (`SwitchThemeData` or equivalent), never per-widget colours.

**Notification toggles (SET-02, SET-04)**
- **D-09:** Three categories, modelled as an enum (e.g. `NotificationCategory { travelEnd, streamerLive, questEnd }`). **Default: all enabled.**
- **D-10:** **Local only, `shared_preferences`**, behind an interface with an injectable `SharedPreferences` factory (pattern of `SecureSessionStore`). The backend is unaware: **no new contract**. Phase 5 reads these preferences on the device to decide whether to surface a notification in each of the three app states.
- **D-11:** Preferences are **keyed per user id on the device** (e.g. `klimmeck.notifications.<userId>.<category>`, or one JSON blob per user — planner's choice): a second account on the same phone has its own toggles. They are **not session artefacts**: logout (Phase 11 D-12 clears secure storage only) and the sync-lost teardown leave them untouched.
- **D-12:** **Persist immediately on tap, no Save button.** The switch is optimistic; if the write fails it reverts to the previous value with only a `debugPrint` (no error UI — the switch state is the whole feedback).
- **D-13:** **No OS-permission handling in this phase:** no hint, no link to system settings. Permission is requested in context by Phase 5 (NOTIF-02); Phase 5 may add a note under the toggles.
- **D-14:** The preferences must be readable **outside the widget tree** (Phase 5's background FCM handler runs in a separate isolate, where cubits do not exist): a Flutter-free store/repository that works standalone, plus the in-tree Cubit for the Settings UI. The store API (read current values, stream of changes) is Claude's discretion but must not depend on `BuildContext` or on `flutter_bloc`.

**Character deletion (SET-05 — in scope by user decision 2026-10-15)**
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

### Deferred Ideas (OUT OF SCOPE)
- **"Cambia account" button** in Settings (logout + immediate login, Phase 11 D-14) — not needed; the sign-in screen covers it.
- **OS-permission hint / link to system settings** under the toggles — Phase 5 (NOTIF-02) decides once the permission flow exists.
- **Syncing notification preferences to the backend** (server-side suppression, multi-device coherence) — only if a real need appears; noted for BE Phase 5 in `BACKEND-NOTES.md` §5.
- **Typed-name confirmation** for deletion — rejected for now; revisit if accidental deletions are reported.
- **A notice after deletion** on the creation page ("Il tuo personaggio è stato eliminato") — Phase 3 D-09 keeps the transition silent.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SET-01 | Access a Settings screen from the main menu | `SatchelLayout` model (7 entries, Settings = page index 6), `MenuBackground`/`MenuItem` generalisation, `Settings` tab in `MainScreen._buildPages`, `CloudinaryAssets.settings` placeholder (Patterns 1, 2, 3; Pitfalls 1, 2) |
| SET-02 | Toggle individual notification categories | `NotificationCategory` enum + `NotificationPreferencesStore` (`SharedPreferencesAsync`) + `NotificationPreferencesCubit` (optimistic, revert on failure), themed `Switch` (Patterns 4, 5, 7) |
| SET-03 | Trigger logout from Settings | `confirmLogout(context)` reused unchanged as the last scrollable element (Pattern 7); the dialog template shared with the deletion dialog (Pattern 6) |
| SET-04 | Preferences persist across app restarts | Per-user, per-category boolean keys in `SharedPreferencesAsync`, not touched by logout/teardown (Pattern 4, Pitfall 5); store test proves write -> new store instance -> read |
| SET-05 | Delete the current character after explicit confirmation; app returns to character creation | `DeleteCharacter` document (validated against the real BE schema), `KlimmeckGraphQl.deleteCharacter`, `CharacterDeletionRepository`, `CharacterDeletionCubit`, `AuthCubit.adoptUser` hand-off, dialog on root Navigator (Patterns 6, 8; Pitfalls 3, 4, 6) |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

Treated with the same authority as locked decisions.

- **Principles always applied:** Clean Code, SoC (UI does no networking, Cubit builds no widgets, Repository knows no `BuildContext`, Model is Flutter-free), **TDD red -> green -> refactor (test written BEFORE the implementation)**, Boy Scout Rule (fix small things in touched files in the same commit; massive refactors out of scope).
- **Inviolable rules:** (1) no UI chrome outside utility screens (Settings is allowed chrome by rule, but D-04 still makes it a parchment tab with no `AppBar`/`Scaffold`); (2) no blocking loading in an active session (the deletion progress is an explicit user action: allowed; the preference load must never show a spinner); (3) branch + PR per phase (`feat/04-settings-screen`, PR target `develop`, BE PR 03.1 merged first); (4) backend is the source of truth (the FE never decides whether a deletion is allowed, D-21); (5) no secrets in repo.
- **Commands:** `flutter pub get` (not needed: no new dependency in the recommended plan), `flutter analyze` ("clean" = no new issues in touched files, baseline below), `flutter test`, `dart format` **only on single touched files** (`dart format --output=none --set-exit-if-changed <file>`; never a directory, Phase 11 D-38).
- **Commit hygiene (project memory):** commit scope `phase-4` (not `04`); **no `Co-Authored-By: Claude` trailer** (project memory overrides the harness reminder); BE handoff notes stay in `.planning/phases/04-settings-screen/BACKEND-NOTES.md`; PRs use `GH_TOKEN=$(gh auth token --user LucaTabbia)` per command, base `develop`.
- **Rule files read:** `docs/rules/naming.md`, `architecture.md`, `state-management.md`, `graphql.md`, `ui-ux.md`, `testing.md`, `workflow.md`, `assets.md` (key points are folded into the patterns below).
- **Working-tree note:** `pubspec.lock` is already modified in the working tree before this phase (1 line, unrelated). Do not stage it with phase commits; do not run `flutter pub get`.

## Summary

Phase 4 is small on the network side (one no-argument mutation whose contract is final and already in the BE schema) and mostly a UI/state phase. Three findings drive the plan. First, **the menu is the riskiest piece**: `MenuBackground` hard-codes two rows of three 152 px cells, `MenuItem` hard-codes `index <= 2`, and `MainScreen._buildPages`, `SatchelMenu.menuImages` and the `MenuSection` indices must change together; a small pure `SatchelLayout` model (entries with `pageIndex`, `label`, `assetPath`, `column`, `row`, `rowSpan`) removes all three duplications and makes the flight end-points unit-testable. The new four-column overlay is `152 + 4*152 = 760` logical px wide: it fits the 780-wide test phone but **overflows on 667-wide screens**, so the cell width must be adaptive. Second, **`SharedPreferencesAsync` (not the legacy `SharedPreferences`) is the right API** for a store that Phase 5's FCM background isolate will read: the legacy API caches per isolate and goes stale, `SharedPreferencesAsync` always reads the platform store; it is already available in the locked 2.5.3, needs no `pubspec` change, and is testable with a hand-written `Fake implements SharedPreferencesAsync`. Third, **`adoptUser` already accepts a `User` with `currentCharacter: null`** in both services (no code change needed, only a regression test), `SessionHome`/`AuthGate` already route to creation and pop root routes on `id -> null`, and `userUpdated` is a working backup; the deletion hand-off is therefore the exact mirror of the creation hand-off (`createdUser` -> `BlocListener` -> `adoptUser`, `handoverRejected` when refused).

The baseline is **645 tests passing in ~19 s** (not the ~500 estimated; Phase 3 grew the suite) and **57 analyzer issues (0 errors, 4 warnings, 53 infos)**, all pre-existing. There is a trap in the test suite: `test/tool/schema_check_documents_test.dart` fails as soon as a new operation is declared in `lib/graphql/**` without being listed in `tool/schema_check/schema_check_documents.dart`, so the document and its listing must land in the same commit.

**Primary recommendation:** Build bottom-up and test-first: (1) pure `SatchelLayout` + `MenuBackground`/`MenuItem` rework with the 7th entry and the `Settings` tab shell; (2) `NotificationCategory` + `NotificationPreferencesStore` (`SharedPreferencesAsync`, per-user per-category boolean keys) + `NotificationPreferencesCubit`; (3) `DeleteCharacter` document + schema-check listing + `KlimmeckGraphQl.deleteCharacter` + `CharacterDeletionRepository` + `CharacterDeletionCubit` + dialog; (4) wire both cubits in `AuthenticatedShell`, finish the screen; (5) schema check against the BE schema + manual E2E. Place both cubits in the `AuthenticatedShell` `MultiBlocProvider`, never tab-local.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_bloc` / `bloc` / `equatable` | 9.1.1 / 9.0.0 / 2.0.7 (locked) | Cubits and Equatable states | Project standard (`docs/rules/state-management.md`) [VERIFIED: pubspec.lock] |
| `shared_preferences` | `^2.0.12` in `pubspec.yaml`, **2.5.3 locked** (platform: android 2.4.10, foundation 2.5.4) | `SharedPreferencesAsync` for the preferences store | Already a direct dependency; `SharedPreferencesAsync` exists since 2.3.0 and is the recommended API for new code and for multi-isolate use [VERIFIED: pubspec.lock; CITED: `~/.pub-cache/hosted/pub.dev/shared_preferences-2.5.5/README.md` lines 20-47] |
| `graphql_flutter` | locked (project) | `performMutation` through `KlimmeckGraphQl` | Existing service layer; the new method mirrors `createCharacter` (`lib/repository/services/graphql/graphql.dart:402`) [VERIFIED: codebase] |
| `auto_size_text`, `google_fonts` | locked (project) | Overlay labels, Cinzel text styles via `KlimmeckGuideTheme` | Already used by the menu and the theme [VERIFIED: codebase] |

### Supporting (tests)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `bloc_test` | 10.0.0 | Cubit sequences | `NotificationPreferencesCubit`, `CharacterDeletionCubit` [VERIFIED: pubspec.lock] |
| `mocktail` | 1.0.5 | Mocks/Fakes (`Fake implements SharedPreferencesAsync`, `MockKlimmeckGraphQl`, `MockCharacterDeletionRepository`) | Repository and widget tests [VERIFIED: pubspec.lock] |
| `fake_async` | 1.3.3 | Only if a test needs timers | Probably unneeded in this phase (no timers) [VERIFIED: pubspec.lock] |
| `gql` (`parseString`) | already used | Document unit tests | `DeleteCharacter` document test, same pattern as `test/graphql/character_creation_documents_test.dart` [VERIFIED: codebase] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `SharedPreferencesAsync` | legacy `SharedPreferences.getInstance` (the `SecureSessionStore` pattern) | Legacy API caches per isolate; Phase 5's background handler would read stale values unless every read is preceded by `reload()`. `SecureSessionStore` only uses it for a first-launch marker, where staleness is irrelevant. Not recommended here. [CITED: shared_preferences README] |
| One boolean key per (user, category) | One JSON blob per user | A blob needs read-modify-write; two quick taps on different switches can race and lose a write. One key per toggle is atomic and needs no parsing. |
| Store with a change `Stream` | No stream (read-at-event-time) | `SharedPreferencesAsync` always reads fresh, and the only in-tree writer is the Cubit; Phase 5's background isolate cannot receive an in-process stream anyway. **Recommended: no stream** (YAGNI). If the planner wants one, it is a ~10-line broadcast `StreamController` fed after a successful write. |
| `SettingsCubit` (one) | `NotificationPreferencesCubit` + `CharacterDeletionCubit` | Two unrelated responsibilities (local persistence vs a network mutation with a hand-off): SoC says split. **Recommended: two cubits.** |
| Cubits tab-local (`BlocProvider` in `_buildPages`) | Cubits in `AuthenticatedShell` | `PageView` disposes off-screen non-keep-alive pages, so a tab-local provider would recreate the cubit on every visit and drop an in-flight deletion. **Recommended: shell.** |

**Installation:** none. No `pubspec.yaml` change is needed (`shared_preferences` is already a direct dependency; `SharedPreferencesAsync` ships in 2.5.3). Do **not** import `shared_preferences_platform_interface` in `test/` (transitive: it would trip `depend_on_referenced_packages`); use a hand-written fake instead.

**Version verification:** versions above are the *locked* ones read from `pubspec.lock` on 2026-10-16; no bump is proposed. Flutter 3.35.5 / Dart 3.9.2 [VERIFIED: `dart --version`, project `flutter --version`].

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── config/cloudinary_assets.dart                    # + `settings` constant (placeholder path)
├── graphql/mutations/character_mutations.dart       # + deleteCharacter document
├── models/notification_category.dart                # enum with explicit storageKey (Flutter-free)
├── repository/
│   ├── character_deletion_failure.dart              # enum + exception + code mapping
│   ├── character_deletion_repository.dart           # _guard around KlimmeckGraphQl.deleteCharacter / getMe
│   ├── services/graphql/graphql.dart                # + KlimmeckGraphQl.deleteCharacter()
│   └── storage/notification_preferences_store.dart  # interface + SharedPreferencesAsync impl
├── screens/mainScreen/
│   ├── components/
│   │   ├── satchel_layout.dart                      # NEW pure model (entries + geometry)
│   │   ├── menu_background.dart                     # rebuilt from SatchelLayout
│   │   ├── menu_section.dart                        # takes an entry + cell metrics
│   │   ├── menu_item.dart                           # takes the flight end-point
│   │   └── satchel_menu.dart                        # iterates SatchelLayout.entries
│   ├── main_screen.dart                             # _buildPages + Settings()
│   └── tabs/settings/
│       ├── settings.dart                            # tab widget (BackgroundImage + parchment sheet)
│       ├── components/                              # notification_switch_row, account_section, messages
│       ├── notificationCubit/                       # notification_preferences_cubit.dart / _state.dart
│       └── deletionCubit/                           # character_deletion_cubit.dart / _state.dart
├── shared/components/modal/destructive_confirmation_dialog.dart   # shared by logout + deletion
└── theme/kg_theme.dart                              # + switchTheme, destructive ButtonStyle
tool/schema_check/schema_check_documents.dart        # + 'DeleteCharacter'
test/…                                               # mirror (see Validation Architecture)
```
Naming per `docs/rules/naming.md`: feature sub-cubit folders are lowerCamelCase (`notificationCubit/`, `deletionCubit/`, like `characterCubit/`, `questCubit/`); tab widget has no suffix (`Settings`, like `Profile`, `Shop`; no clash with a Flutter SDK `Settings` class: grep of `packages/flutter/lib` found none) [VERIFIED].

### Pattern 1: `SatchelLayout` — one table drives labels, icons, pages and geometry (SET-01, D-01)

**Current wiring (all three must change together today):**
- `lib/screens/mainScreen/components/satchel_menu.dart:29-54`: `menuImages` is a `List` (dynamic) of maps `{selectedImagePath, unselectedImagePath}` — both keys always hold the same URL; order = page index.
- `lib/screens/mainScreen/components/menu_background.dart:59-85`: a `Column` with `Row(MenuSection("Mappa" 0, "Profilo" 1, "Diario" 2)`, a **456 px** divider (`= 3 * 152`) and `Row("Libreria" 3, "Bacheca" 4, "Negozio" 5)`. Left of it: a 150 px "Chiudi il menù" column (`:34-50`) and a 2 px gold vertical border (`:51-58`), i.e. **152 px** before the grid.
- `lib/screens/mainScreen/components/menu_section.dart:15-47`: each cell is 150 px of label (`Align.bottomCenter`, bottom padding 15) + a 2 px right border = **152 px wide**, `height = H/2 - 1`.
- `lib/screens/mainScreen/components/menu_item.dart:48-57`: flight end `x = 150 + 25 + (50 + itemSize) * col`, `y = -(H*3/4) + 50` for `index <= 2`, `-(H/4) + 50` otherwise; start `Offset(25, -(H/2) + 50)`; the parabola apex is `-(H/2 + 100)` (`:59-63`). Items live in a `Stack(alignment: bottomLeft)` (`satchel_menu.dart:180-181`), so translations are relative to the bottom-left corner and `itemSize = 100` (`:28`).
- `lib/screens/mainScreen/main_screen.dart:132-141`: `_buildPages` returns `[WorldMap, Profile, Journal, Library, Board, Shop]` in index order.

**Recommended model** (Flutter-free apart from `dart:ui` `Offset`/`Size`, unit-testable):

```dart
// lib/screens/mainScreen/components/satchel_layout.dart
class SatchelEntry extends Equatable {
  const SatchelEntry({
    required this.pageIndex,
    required this.label,
    required this.assetPath,   // CloudinaryAssets constant (raw path, not the URL)
    required this.column,      // 0 = Mappa column, 1..3 = grid
    required this.row,         // 0 or 1
    this.rowSpan = 1,
  });
  final int pageIndex;
  final String label;
  final String assetPath;
  final int column;
  final int row;
  final int rowSpan;
  @override
  List<Object?> get props => [pageIndex, label, assetPath, column, row, rowSpan];
}

abstract final class SatchelLayout {
  static const int columns = 4;           // Mappa column + 3 grid columns
  static const int rows = 2;
  static const double closeColumnWidth = 152;   // 150 label + 2 gold border (menu_background.dart:34-58)
  static const double maxCellWidth = 152;

  static const List<SatchelEntry> entries = [
    SatchelEntry(pageIndex: 0, label: 'Mappa',        assetPath: CloudinaryAssets.map,      column: 0, row: 0, rowSpan: 2),
    SatchelEntry(pageIndex: 1, label: 'Profilo',      assetPath: CloudinaryAssets.mirror,   column: 1, row: 0),
    SatchelEntry(pageIndex: 2, label: 'Diario',       assetPath: CloudinaryAssets.journal,  column: 2, row: 0),
    SatchelEntry(pageIndex: 3, label: 'Libreria',     assetPath: CloudinaryAssets.library,  column: 3, row: 0),
    SatchelEntry(pageIndex: 4, label: 'Bacheca',      assetPath: CloudinaryAssets.board,    column: 1, row: 1),
    SatchelEntry(pageIndex: 5, label: 'Negozio',      assetPath: CloudinaryAssets.shop,     column: 2, row: 1),
    SatchelEntry(pageIndex: 6, label: 'Impostazioni', assetPath: CloudinaryAssets.settings, column: 3, row: 1),
  ];

  /// Adaptive: 152 on >= 760 px wide screens, shrinks (never below the 100 px icon) on narrower ones.
  static double cellWidth(double screenWidth) =>
      math.min(maxCellWidth, (screenWidth - closeColumnWidth) / columns);

  /// Cell centre from the top-left of the screen.
  static Offset centerOf(SatchelEntry e, Size screen) {
    final cellW = cellWidth(screen.width);
    final rowH = screen.height / rows;
    return Offset(
      closeColumnWidth + (e.column + 0.5) * cellW,
      (e.row + e.rowSpan / 2) * rowH,
    );
  }

  /// Flight end-point in MenuItem's frame (Stack bottomLeft, translate from bottom-left).
  static Offset flightEnd(SatchelEntry e, Size screen, double itemSize) {
    final c = centerOf(e, screen);
    return Offset(c.dx - itemSize / 2, -(screen.height - c.dy) + itemSize / 2);
  }
}
```

Sanity check against the current code: for `index 1` today `end.dx = 325`; the model gives `152 + 1.5*152 - 50 = 330` (the model is centred on the real cell; today drifts 0-7 px because it uses a 150 px pitch for 152 px cells). Vertical: top row `centerY = H/4` -> `-(3H/4) + 50` = identical to today; bottom row `centerY = 3H/4` -> `-(H/4) + 50` identical; **Mappa** `centerY = H/2` -> `-(H/2) + 50` = the animation start y (a horizontal flight with the same apex: the parabola in `_parabolaCoefficients` stays well-defined because `x2 != x0`).

Wiring:
- `SatchelMenu` iterates `SatchelLayout.entries` (replaces `menuImages`; deletes the dynamic list of maps and the duplicated selected/unselected keys — Boy Scout) and passes `end: SatchelLayout.flightEnd(entry, MediaQuery.sizeOf(context), _itemSize)` to `MenuItem`; `MenuItem` loses its `index <= 2` branch and its own `index` stays only for `onTap(pageIndex)`.
- `MenuBackground` keeps the left "Chiudi il menù" column and divider, then renders the grid with a `SizedBox(width: cellW * 3 + cellW ...)`: build it as a `Stack` of `Positioned(left: col*cellW, top: row*rowH, width: cellW, height: rowSpan*rowH)` `MenuSection`s. Borders live **inside** each cell's `DecoratedBox`: right border on every cell (as today), bottom border only on cells with `row + rowSpan < rows` (the Mappa cell has none), so the horizontal divider does not cross the Mappa column and the separate 456 px divider widget disappears. `BoxDecoration` borders are drawn inside the box, so cell sizes stay `H/2` and `H` exactly (today they are `H/2 - 1` plus a 2 px divider).
- `MainScreen._buildPages` appends `Settings()` as index 6 and gets `assert(pages.length == SatchelLayout.entries.length)`.

### Pattern 2: placeholder asset (D-02)

`lib/config/cloudinary_assets.dart` §Menu (lines 39-46): `map`, `mirror`, `journal`, `library`, `board`, `shop`, `pouch`. Constants are camelCase and hold `v<version>/<name>_<hash>.svg` paths consumed through `CloudinaryAssets.url(...)`. `docs/rules/assets.md` demands snake_case file names for **new** uploads (the existing ids are camelCase legacy); the user's new asset should be uploaded as `settings.svg`.

I downloaded PNG renders of `pouch` and `emptySatchel` from Cloudinary (scratchpad, not committed) and looked at them: `pouch` is the **closed drawstring pouch that is the satchel button itself** (`satchel_menu.dart:246`), so using it for Settings would show two identical pouches in the open overlay. `emptySatchel` (`:32`, Shop section) is an open leather satchel seen from above: same visual family, clearly distinct from the button. **Use `emptySatchel` as the placeholder**:

```dart
// ============== Menu ==============
...
static const String settings = emptySatchel; // placeholder until settings_<hash>.svg is uploaded
```
`CachedSvg` (`lib/shared/components/cached_svg.dart:63-65`) returns an empty `SizedBox` on a missing file, so a later wrong path never crashes. Swapping the constant is the only change when the asset lands. [VERIFIED: codebase + rendered images]

### Pattern 3: the parchment-sheet tab (D-04, D-05, D-06)

`Profile` (`lib/screens/mainScreen/tabs/profile/profile.dart:23-99`) is `BackgroundImage(child: Padding(horizontal: 50, child: Container(color: parchment, child: BlocSelector<CharacterCubit, CharacterState, CharacterInfos?>(selector: (s) => s is CharacterLoaded ? s.character.infos : null, ...SingleChildScrollView(AlwaysScrollableScrollPhysics ... SizedBox(height: 120)))))`. Replicate that skeleton; select only the name:

```dart
BlocSelector<CharacterCubit, CharacterState, String?>(
  selector: (state) => state is CharacterLoaded ? state.character.infos.name : null,
  builder: (context, name) => ...,
)
```
(`CharacterInfos.name` is `String?`, `lib/models/character/character_infos.dart:22`.) The 120 px bottom `SizedBox` is the "satchel never covers the last control" padding (D-04). The sheet is a landscape surface of ~360 px height: title + header + two sections must **scroll** (`SingleChildScrollView`); use `ListView`-free columns since the content is a fixed handful of rows. Text styles only via `KlimmeckGuideTheme.instance.titleMedium` / `bodyMedium` / `errorText`; spacing via `KlimmeckGuideTheme.spacingXs..Xl`.

### Pattern 4: preferences model and store (SET-02, SET-04, D-09..D-14)

```dart
// lib/models/notification_category.dart  (Flutter-free)
enum NotificationCategory {
  travelEnd('travel_end'),
  streamerLive('streamer_live'),
  questEnd('quest_end');
  const NotificationCategory(this.storageKey);
  final String storageKey; // explicit, so renaming an enum value never orphans stored data
}
```
```dart
// lib/repository/storage/notification_preferences_store.dart  (no flutter_bloc, no BuildContext)
abstract interface class NotificationPreferencesStore {
  Future<bool> isEnabled(String userId, NotificationCategory category);
  Future<Map<NotificationCategory, bool>> readAll(String userId);
  Future<void> setEnabled(String userId, NotificationCategory category, {required bool enabled});
}

class SharedPreferencesNotificationPreferencesStore implements NotificationPreferencesStore {
  SharedPreferencesNotificationPreferencesStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();
  static const String keyPrefix = 'klimmeck.notifications';
  static String keyFor(String userId, NotificationCategory c) => '$keyPrefix.$userId.${c.storageKey}';
  static const bool defaultEnabled = true;       // D-09
  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isEnabled(String userId, NotificationCategory c) async =>
      await _preferences.getBool(keyFor(userId, c)) ?? defaultEnabled;
  ...
}
```
Decisions inside Claude's discretion:
- **Key scheme:** one `bool` per `(user.id, category)`: `klimmeck.notifications.<userId>.<travel_end|streamer_live|quest_end>`. An absent key means the default (enabled); **never write defaults on read**. Use `User.id` (Mongo id), not `twitchId`.
- **API choice:** `SharedPreferencesAsync` reads the platform store on every call, so a Phase 5 background isolate that calls `isEnabled(userId, category)` per message always sees the latest value, with no `reload()` and no singleton cache. The README explicitly lists multi-isolate and plugin-created background engines (it names `firebase_messaging`) as the cases where the cached API goes stale [CITED: shared_preferences 2.5.5 README lines 31-47]. The "injectable factory" of D-10 becomes an injectable `SharedPreferencesAsync` instance (a cheap constructor, no `Future`).
- **Separate storage from the legacy marker:** `SecureSessionStore.firstLaunchDoneKey` uses the legacy API (`flutter.`-prefixed on native); the new keys go through the Async API with no prefix; there is no collision and no migration (new keys only).
- **Phase 5 consumption:** inject the same `NotificationPreferencesStore` into the foreground-banner path (the app-level instance) and construct a fresh `SharedPreferencesNotificationPreferencesStore()` inside the background handler (no state to share). The BE will send `travelEnd`/`streamerLive`/`questEnd` as the data-message type (BE handoff §8), which maps to `NotificationCategory`. The isolate also needs the **user id**: the cheapest option is for Phase 5 to put `userId` in the FCM data message (the BE knows the recipient). `[ASSUMED]` — recorded as A2, a Phase 5 decision, not a Phase 4 task.
- **Dispose:** the store holds no resources.

`NotificationPreferencesCubit` (provided in `AuthenticatedShell`, constructed with `store` + `userId`):

```dart
class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState({this.enabled = const {...all true}, this.isLoaded = false});
  final Map<NotificationCategory, bool> enabled;   // always all three keys
  final bool isLoaded;
  NotificationPreferencesState copyWith({...});
  @override List<Object> get props => [enabled, isLoaded];
}
```
- `load()`: `readAll(userId)` -> emit loaded values; on failure `debugPrint` and keep defaults (`isLoaded: true`). Switches are `onChanged: null` until `isLoaded` (a few ms; no spinner, rule 2).
- `toggle(category, value)`: emit the new value immediately; `await store.setEnabled`; on failure `debugPrint('[NotificationPreferences] write failed: ${error.runtimeType}')` and revert **only that category** to its previous value (two switches toggled quickly must not clobber each other). Guard: ignore if the value equals the current one. Use `SafeEmit` like every shell cubit.
- Never log the user id or values beyond the error type.

### Pattern 5: SET-04 persistence across restart

Logout (Phase 11 D-12) and the sync-lost teardown clear secure storage only (`SecureSessionStore.clear` deletes `refreshTokenKey`; `lib/repository/storage/session_store.dart:70`); preferences keys are not under the `klimmeck.session.` namespace and are never touched. The store test proves persistence by writing through one `SharedPreferencesNotificationPreferencesStore` and reading through a **new instance over the same fake backing map**.

### Pattern 6: deletion — document, service, repository, cubit, dialog (SET-05, D-15..D-19)

**Document** (validated OK against the real BE `src/schema.gql` with the BE's `graphql` 16.11.0 during this research):
```dart
// lib/graphql/mutations/character_mutations.dart
static const String deleteCharacter = r'''
  mutation DeleteCharacter {
    deleteCharacter {
      ...UserFields
    }
  }
''' + UserFragment.definition;
```
`schema.gql:289` -> `deleteCharacter: User!` (no arguments). Naming: PascalCase operation `DeleteCharacter`, like `CreateCharacter` (`docs/rules/graphql.md`).

**Service** (`lib/repository/services/graphql/graphql.dart`, next to `createCharacter` at :402 and re-using the private `_dataOrThrow`/`_userFrom` at :416-434):
```dart
Future<User> deleteCharacter() async {
  final data = _dataOrThrow(await performMutation(query: CharacterMutations.deleteCharacter));
  return _userFrom(data['deleteCharacter']);
}
```
`User.fromJson` already maps a JSON `null` `currentCharacter` to `null` (`lib/models/user.dart:23-29`), so the returned `User` carries `currentCharacter == null` with no model change. (Test trap: `User.copyWith(currentCharacter: null)` cannot clear the field because it uses `??` — `lib/models/user.dart:43`; build such users from `buildTestUser()` in `test/helpers/auth_fixtures.dart`, which already has `currentCharacter: null`.)

**Repository** `lib/repository/character_deletion_repository.dart` (mirrors `CharacterCreationRepository`, `lib/repository/character_creation_repository.dart:60-68`):
```dart
class CharacterDeletionRepository {
  CharacterDeletionRepository({required KlimmeckGraphQl graphQl}) : _graphQl = graphQl;
  final KlimmeckGraphQl _graphQl;
  Future<User> deleteCurrentCharacter() => _guard(_graphQl.deleteCharacter);
  Future<User> fetchCurrentUser() => _guard(_graphQl.getMe);
  Future<T> _guard<T>(Future<T> Function() call) async {
    try { return await call(); }
    on OperationException catch (e) { throw CharacterDeletionException(characterDeletionFailureFrom(e)); }
    on FormatException { throw const CharacterDeletionException(CharacterDeletionFailure.unknown); }
  }
}
```
Failure enum `CharacterDeletionFailure { notFound, unauthenticated, connection, handoverRejected, unknown }` in `lib/repository/character_deletion_failure.dart`. **Reuse `graphQlErrorCode(exception)`** from `lib/repository/services/graphql/graphql_error_code.dart:14` instead of copying the code-extraction logic of `characterCreationFailureFrom` (that one additionally reads `ServerException.parsedResponse` for HTTP-400 `BAD_USER_INPUT`, which cannot occur for an argument-less mutation; `GRAPHQL_VALIDATION_FAILED` falls to `unknown`). Mapping: `code == 'CHARACTER_NOT_FOUND'` -> `notFound`; `'UNAUTHENTICATED'` -> `unauthenticated`; no code but a `linkException` -> `connection`; otherwise `unknown`. Define the constants next to the enum like `character_creation_failure.dart:3-7`. `UNAUTHENTICATED` normally never reaches the cubit: `AuthLink` retries once through the refresh single-flight (`lib/repository/services/graphql/auth_link.dart:41,59,113-115`) and a definitive rejection ends the session (the shell, and the cubit with it, unmount).

**Cubit** `CharacterDeletionCubit` (shell-provided, `SafeEmit`), state as Equatable with `isDeleting`, `failure`, `deletedUser` — the exact mirror of `CharacterCreationState.createdUser` / `handoverRejected` (`lib/screens/characterCreation/cubit/character_creation_cubit.dart`):
- `deleteCharacter()`: ignore if already `isDeleting` (double-tap guard); emit `isDeleting: true, failure: null`; call the repository; success -> emit `deletedUser: user, isDeleting: false` (the listener hands it to `AuthCubit`).
- `CharacterDeletionFailure.notFound` (D-18, BE handoff §0.3): stale state, **not** an error: call `fetchCurrentUser()`; if the returned `User.currentCharacter == null` emit `deletedUser: thatUser` (same hand-off -> creation page); if it still has a character, or the refetch fails, emit `failure: unknown`. Mirror of `_existingCharacterOwner` (`character_creation_cubit.dart`, `_handleSubmitFailure`).
- any other failure -> `isDeleting: false, failure: <code>`; a catch-all `catch (_)` -> `unknown` (anti infinite spinner, same guarantee the creation cubit documents).
- `handoverRejected()`: `isDeleting: false, deletedUser: null, failure: handoverRejected`.
- `dismissFailure()` is **not** needed: the inline message clears when the next attempt starts (`failure: null` at the beginning of `deleteCharacter()`).

**Widget hand-off** (`Settings` tab): `BlocListener<CharacterDeletionCubit, CharacterDeletionState>(listenWhen: (p, c) => p.deletedUser == null && c.deletedUser != null, listener: (context, state) { final adopted = context.read<AuthCubit>().adoptUser(state.deletedUser!); if (!adopted) context.read<CharacterDeletionCubit>().handoverRejected(); })` — identical to `character_creation_screen.dart:32-56`. Everything after `adoptUser` is existing behaviour (see Pattern 8).

**Dialog.** `LogoutConfirmationDialog` (`lib/shared/components/modal/logout_confirmation_dialog.dart:7-52`) is an `AlertDialog` with a `titleMedium` title, a `bodyMedium` body, a `TextButton` "Annulla" and an `ElevatedButton.styleFrom(backgroundColor: bloodRed)`; `showLogoutConfirmationDialog` uses `barrierDismissible: false`; `confirmLogout` reads `AuthCubit` **before** the `await` (`:56-58`). Boy Scout: extract `DestructiveConfirmationDialog({title, body, confirmLabel})` + `showDestructiveConfirmation(context, ...) -> Future<bool>` into `shared/components/modal/destructive_confirmation_dialog.dart`, make `LogoutConfirmationDialog` a thin wrapper (keep the public names and strings: `test/shared/components/modal/logout_confirmation_dialog_test.dart` is the regression guard) and add `showDeleteCharacterConfirmation(context, {String? characterName})`. Copy (D-15): title "Eliminare il personaggio?", body "Sei sicuro di voler eliminare <nome>? L'azione è irreversibile." (fallback "il tuo personaggio" when the name is null), actions "Annulla" / "Elimina". The deletion call site mirrors `confirmLogout`:
```dart
Future<void> _confirmDeletion(BuildContext context, String? name) async {
  final cubit = context.read<CharacterDeletionCubit>();      // read BEFORE the await
  if (await showDeleteCharacterConfirmation(context, characterName: name)) {
    await cubit.deleteCharacter();
  }
}
```
The dialog is on the **root `Navigator`**, outside the shell's providers (`authenticated_shell.dart:34-36` doc comment): it must stay a pure `bool`-returning dialog; it must never `context.read` a shell cubit.

**Copy for failures** (inline in the Account section, `KlimmeckGuideTheme.instance.errorText`, an extension like `CharacterCreationFailureMessage` in `character_creation_messages.dart:34-45`): `connection` -> "Errore di connessione, riprova"; `handoverRejected` -> "Personaggio eliminato, ma la sessione non si è aggiornata: esci e rientra"; `unauthenticated`/`unknown` -> "Impossibile eliminare il personaggio, riprova". `notFound` has no message (it is resolved by the refetch).

### Pattern 7: theme additions (D-06, D-08)

`lib/theme/kg_theme.dart` today (read in full): colour tokens `primaryGold 0xFFFFD700`, `darkBronze`, `royalCrimson`, `arcanePurple`, `parchment`, `deepNight`, `mysticBlue`, `darkWood`, `paleSilver`, `bloodRed 0xFF9B1C1C` (:28-37); `bordersForText` (:20-25); text styles `headlineLarge` (cinzelDecorative 32), `titleMedium` (cinzel 20/w600), `bodyLarge`, `bodyMedium` (sourceSans3 16/w500), `errorText` (cinzel 12, bloodRed) (:65-124); spacing `spacingXs..Xl = 4/8/16/24/32` (:13-17). `materialTheme` (:135-175) sets only `colorScheme`, `textTheme`, `scaffoldBackgroundColor`, `appBarTheme`, `inputDecorationTheme`, `chipTheme`. **There is no `SwitchThemeData`, no `ElevatedButtonThemeData`**; the destructive style is currently inline `ElevatedButton.styleFrom(backgroundColor: KlimmeckGuideTheme.bloodRed)` in the logout dialog (a token reference, not a hex, but repeated). `test/theme/kg_theme_test.dart` already asserts theme pieces (`input`, `chip`).

Recommended additions (tokens only):
- `switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith(...), trackColor: ..., trackOutlineColor: ...)` — selected: thumb `primaryGold`, track `darkBronze`; unselected: thumb `darkWood`, track `parchment` with `darkBronze` outline; disabled: `paleSilver`. (Design choice, Assumption A5; WidgetState API is current in Flutter 3.35.5.)
- `static ButtonStyle get destructiveButtonStyle => ElevatedButton.styleFrom(backgroundColor: bloodRed, foregroundColor: parchment);` used by the dialog confirm button, "Elimina personaggio" and "Esci"; remove the inline `styleFrom` from the logout dialog (Boy Scout).
- Tests: extend `test/theme/kg_theme_test.dart` with the switch states and the destructive style.
- Tap targets (`ui-ux.md`: >= 44x44): `SwitchListTile` and `ElevatedButton` use Material's padded tap target (48 px); do not set `MaterialTapTargetSize.shrinkWrap`.

### Pattern 8: what happens after `adoptUser(User(currentCharacter: null))` (D-17, D-21)

Verified by reading the code; **no production change is required**:
- `SessionAuthTokenService.adoptUser` (`session_auth_token_service.dart:197-204`): refuses only when the channel is not `AuthAuthenticated` or `user.id != _user?.id`; otherwise stores the user and re-emits. It never inspects `currentCharacter`.
- `DevAuthTokenService.adoptUser` (`dev_auth_token_service.dart:103-113`): same condition (`current.user.id != user.id`), re-emits `AuthAuthenticated(user: user, accessToken: current.accessToken)`. With the dev bypass the session user id comes from the real backend `me` (`DEV_AUTH_TWITCH_ID`), so the id of the mutation response matches (same assumption `createCharacter` already relies on).
- `AuthCubit.adoptUser` delegates (`auth_cubit.dart:40`).
- `AuthGate` (`auth_gate.dart:75-78`): `_changesCharacter` is true for `id -> null` (`previous...currentCharacter?.id != current...currentCharacter?.id`), so it pops every root route (`popUntil(isFirst)`) and rebuilds; `SessionHome` (`session_home.dart:25-26`) returns the creation page when `currentCharacter == null` and the `ValueKey('character:<id>')` shell is unmounted, which closes every shell cubit (including `CharacterCubit` and its `characterUpdated` subscription) — the BE does **not** close that subscription server-side (BE handoff §4/§5).
- Idempotency: if `userUpdated` also delivers the same `currentCharacter: null` (backup path or event first), `SessionSyncCubit` calls `adoptUser` again (`session_sync_cubit.dart:126`); `AuthGate._shouldRebuild` is false for an unchanged character, so no flicker. If the `userUpdated` event arrives **before** the mutation response, the shell (and `CharacterDeletionCubit`) is already closed: `SafeEmit` swallows the late emission and the listener never fires — also correct.
- Gap found: no existing test adopts a user whose `currentCharacter` becomes `null` (`session_auth_token_service_adopt_user_test.dart:74-138` and `dev_auth_token_service_transitions_test.dart:186-225` cover id->id and refusal). **Add a regression test per service** ("adopts a user whose character was deleted").

### Pattern 9: where the new Cubits live (D-19 discretion)

`AuthenticatedShell` (`lib/screens/auth/authenticated_shell.dart:55-82`) builds a `MultiBlocProvider` of nine cubits from `graphQl`; the shell is keyed by `characterId` (`session_home.dart:27-30`) under `AuthGate`'s `user.id` key, so everything closes on logout, sync loss, account change **and character change**. Add:

```dart
BlocProvider<NotificationPreferencesCubit>(
  create: (_) => NotificationPreferencesCubit(notificationStore, userId: userId)..load(),
),
BlocProvider<CharacterDeletionCubit>(
  create: (_) => CharacterDeletionCubit(CharacterDeletionRepository(graphQl: graphQl)),
),
```
Required signature change: `AuthenticatedShell` gains `required NotificationPreferencesStore notificationStore` and `required String userId`; `main.dart` (`:256-260`, the `shellBuilder: (context, characterId) => AuthenticatedShell(...)` closure already has `user` in scope: `userId: user.id`) passes them, and `_KlimmeckGuideAppState` owns one `SharedPreferencesNotificationPreferencesStore` (a `late final` next to `graphQl`, `:131-134`). The existing `test/screens/auth/authenticated_shell_test.dart:62-67` constructs the shell and must pass an `InMemoryNotificationPreferencesStore` and a `userId` (known, mechanical test edit). `main_screen_test.dart` is unaffected (the pages are only built in `MainScreenLoadData`).

### Anti-Patterns to Avoid
- **Legacy `SharedPreferences.getInstance` for the store:** stale across isolates (Phase 5). Use `SharedPreferencesAsync`.
- **JSON blob per user:** read-modify-write race between two quick toggles.
- **Tab-local `BlocProvider`:** the `PageView` disposes non-adjacent pages; an in-flight deletion cubit would be recreated or lost. Keep them in the shell.
- **Calling `authCubit.adoptUser` from the cubit:** cubit-calls-cubit is forbidden (`state-management.md`); use the `BlocListener` hand-off.
- **Dialog reading a shell cubit:** the dialog is on the root Navigator (no shell providers).
- **Copying `characterCreationFailureFrom` wholesale:** reuse `graphQlErrorCode`.
- **Pre-checking quests/travel before deleting:** D-21 forbids it; the backend archives regardless (BE handoff §7.1).
- **Hard-coded hex or `TextStyle(fontSize...)` in the Settings widgets:** theme tokens only.
- **Showing the `CharacterDeletionFailure.notFound` as an error:** it is the stale-state path (refetch and continue).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-isolate-safe local persistence | Own file/JSON store or a `reload()` dance | `SharedPreferencesAsync` | Always reads the platform store; documented for multi-isolate use |
| GraphQL error-code extraction | New parsing of `OperationException` | `graphQlErrorCode` (`lib/repository/services/graphql/graphql_error_code.dart:14`) | Already handles `graphqlErrors` and the subscription-payload shapes |
| `User` parsing from the mutation payload | Parse JSON in the repository | `KlimmeckGraphQl._userFrom` + `User.fromJson` | One parsing boundary, malformed -> `FormatException` -> `unknown` |
| Session hand-off after a `User`-returning mutation | Direct auth state mutation or navigation | `AuthCubit.adoptUser` + existing `AuthGate`/`SessionHome` | Already routes, pops dialogs and closes cubits (Phase 3 D-08/D-09/D-10) |
| Logout confirmation + teardown | A second logout flow | `confirmLogout(context)` unchanged | D-07; Phase 11 atomic teardown |
| Confirmation dialog | A second hand-written `AlertDialog` | `DestructiveConfirmationDialog` extracted from the logout dialog | One style, one test guard |
| Switch/button colours | Per-widget colours | `SwitchThemeData` + `destructiveButtonStyle` in `kg_theme.dart` | `ui-ux.md` "theme is the only source" |
| SVG display | `SvgPicture.network` | `CachedSvg` | `docs/rules/assets.md` |
| Flight geometry per item | Per-index `if` branches | `SatchelLayout.flightEnd` | One tested function for any grid |
| Schema validation of the document | Manual reading | `tool/schema_check` (command below) | Uses the BE's own `graphql` |

**Key insight:** this phase adds almost no new infrastructure: persistence is a 10-line store over a platform API, deletion is a mirror of creation, and the session reaction to `currentCharacter -> null` already exists. The only genuinely new logic is the layout model and the optimistic toggle revert.

## Runtime State Inventory

> Not a rename/refactor/migration phase. The only persisted artefact introduced is a new set of `shared_preferences` keys; nothing existing is renamed.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | New keys `klimmeck.notifications.<userId>.<category>` (new, additive). Existing keys untouched: `klimmeck.session.refresh_token` (secure storage), `klimmeck.session.first_launch_done` (legacy prefs), `cachedUrls` (legacy `KGStorageManager`). On the backend: the deleted `Character` is soft-archived (`deletedAt`, `deletionReason: user_request`), the `User` keeps `twitchPoints`. | None. Preferences of a deleted character's user are **kept** (they are per user, not per character). |
| Live service config | None — verified: no external service stores per-character or per-preference configuration in this phase (FCM token sync is Phase 5). | None |
| OS-registered state | None — verified: no scheduled tasks, no notification channels registered in this phase. | None |
| Secrets / env vars | None new. `DEV_AUTH_*` unchanged; no key renamed. | None |
| Build artifacts / installed packages | None — no dependency change; no generated code (no codegen in this project for the touched files). | None |

## Common Pitfalls

### Pitfall 1: the four-column overlay overflows narrow screens
**What goes wrong:** `152` (close column + border) `+ 4 * 152 = 760` logical px. The test surface `useLandscapePhone` is 780x360 (`test/helpers/landscape.dart:5-9`) and fits; a 667-wide landscape phone (e.g. iPhone SE class) overflows the `Row`, showing the debug overflow stripe and clipping the Settings column.
**Why:** cell width is hard-coded to 150 + 2 in `MenuSection`.
**How to avoid:** `SatchelLayout.cellWidth(screenWidth) = min(152, (screenWidth - 152) / 4)`; label `AutoSizeText` already scales (`minFontSize 12`). A cell must stay >= `itemSize` (100) -> screens >= 552 px wide. Widget-test `MenuBackground` at 780x360 and at 667x375 (no overflow exception, all seven labels found).
**Warning signs:** "A RenderFlex overflowed" in widget tests at a narrower view size.

### Pitfall 2: `menuImages`, the `MenuSection` indices and `_buildPages` drift apart
**What goes wrong:** adding the 7th entry in one place only gives a label that jumps to the wrong page, or a `RangeError` in `PageController.jumpToPage`.
**How to avoid:** the single `SatchelLayout.entries` table + `assert(pages.length == SatchelLayout.entries.length)` + a unit test that `pageIndex` values are exactly `0..6`, unique, and that no two cells overlap (grid occupancy), and that Settings is `(col 3, row 1)`.

### Pitfall 3: `User.copyWith(currentCharacter: null)` does not clear the character
**What goes wrong:** a test (or code) that "removes" the character through `copyWith` keeps the old one (`currentCharacter: currentCharacter ?? this.currentCharacter`, `lib/models/user.dart:43`).
**How to avoid:** build deleted users with `buildTestUser()` (null character) or `User.fromJson({... 'currentCharacter': null})`. Do not "fix" `copyWith` in this phase (out of scope; mention in the plan if touched).

### Pitfall 4: `schema_check_documents_test.dart` goes red the moment the mutation is added
**What goes wrong:** `test/tool/schema_check_documents_test.dart` asserts that `schemaCheckDocuments.keys` equals every `query|mutation|subscription <Name>` declared under `lib/graphql/{queries,mutations,subscriptions}`. Adding `DeleteCharacter` without listing it fails the suite.
**How to avoid:** the Red/Green commit that introduces the document also adds `'DeleteCharacter': CharacterMutations.deleteCharacter` to `tool/schema_check/schema_check_documents.dart`. (Also: `UserFields` must be defined exactly once in the document, as the creation-document test asserts.)

### Pitfall 5: preferences stored in the session namespace or cleared with the session
**What goes wrong:** putting the keys under `klimmeck.session.` or calling a broad `clear()` in a teardown would wipe toggles on logout, violating D-11.
**How to avoid:** distinct `klimmeck.notifications.` prefix; never call `SharedPreferencesAsync.clear()` (no `clear` on the store interface); test that `SecureSessionStore.clear()`/logout paths do not reference the store (they are separate classes) and that the store survives a new instance.

### Pitfall 6: the deletion cubit is closed by its own success
**What goes wrong:** `adoptUser` unmounts the shell synchronously inside the `BlocListener`, closing `CharacterDeletionCubit` while its own `deleteCharacter()` future may still be completing; an `emit` after `close` throws `StateError`.
**How to avoid:** `SafeEmit` on the cubit (as every shell cubit); emit `deletedUser` **last**; never `await` anything after emitting it. Same discipline as `CharacterCreationCubit`.

### Pitfall 7: dialog content reading shell cubits, or `context` used across the `await`
**What goes wrong:** `showDialog` mounts on the root `Navigator`, above the shell's `MultiBlocProvider` (`authenticated_shell.dart:34-36`): `context.read<CharacterDeletionCubit>()` inside the dialog throws `ProviderNotFoundException`; using the tab `context` after the `await` trips `use_build_context_synchronously`.
**How to avoid:** read the cubit (and the name) before the `await`; the dialog is a pure widget returning `bool` (pattern of `confirmLogout`, `logout_confirmation_dialog.dart:56-58`).

### Pitfall 8: enum `name` as the storage key
**What goes wrong:** renaming `streamerLive` in a refactor orphans every stored toggle (silently resets users to "enabled").
**How to avoid:** explicit `storageKey` strings on the enum (Pattern 4) and a test that pins the three key strings.

### Pitfall 9: flicker / wrong default while preferences load
**What goes wrong:** a `Switch` showing "on" for a stored "off" for one frame, or a user toggling before the read finishes and having it overwritten by the late `load()` result.
**How to avoid:** `isLoaded` gate (`onChanged: null` until loaded; no spinner); `load()` must not overwrite a category already toggled by the user (apply loaded values only while `!isLoaded`).

### Pitfall 10: the parchment sheet and the open overlay stacking
**What goes wrong:** the overlay `MenuBackground` is `Opacity`-faded in `MainScreen` (`main_screen.dart:83-87`) with `size: opacityAnimation.value == 0 ? 0 : double.infinity`; the Settings page sits underneath. Nothing new is needed, but the Settings sheet's bottom `SizedBox(height: 120)` is required because the pouch button is positioned at the bottom-left (`satchel_menu.dart:235-239`).

## Code Examples

### Document + repository + cubit sequence (test-first skeleton)
```dart
// test: character_deletion_cubit_test.dart
blocTest<CharacterDeletionCubit, CharacterDeletionState>(
  'emits isDeleting then deletedUser on success',
  build: () {
    when(() => repository.deleteCurrentCharacter()).thenAnswer((_) async => buildTestUser());
    return CharacterDeletionCubit(repository);
  },
  act: (cubit) => cubit.deleteCharacter(),
  expect: () => [
    const CharacterDeletionState(isDeleting: true),
    CharacterDeletionState(deletedUser: buildTestUser()),
  ],
);

blocTest<CharacterDeletionCubit, CharacterDeletionState>(
  'CHARACTER_NOT_FOUND refetches me and hands over the user without an error',
  build: () {
    when(() => repository.deleteCurrentCharacter()).thenThrow(
      const CharacterDeletionException(CharacterDeletionFailure.notFound));
    when(() => repository.fetchCurrentUser()).thenAnswer((_) async => buildTestUser());
    return CharacterDeletionCubit(repository);
  },
  act: (cubit) => cubit.deleteCharacter(),
  expect: () => [
    const CharacterDeletionState(isDeleting: true),
    CharacterDeletionState(deletedUser: buildTestUser()),
  ],
);
```

### Faking `SharedPreferencesAsync` (no new dependency)
```dart
// test/helpers/fakes/fake_shared_preferences_async.dart
class FakeSharedPreferencesAsync extends Fake implements SharedPreferencesAsync {
  FakeSharedPreferencesAsync([Map<String, Object>? initial]) : values = {...?initial};
  final Map<String, Object> values;
  Object? failure;                       // set to make the next write throw
  @override Future<bool?> getBool(String key) async => values[key] as bool?;
  @override Future<void> setBool(String key, bool value) async {
    final error = failure;
    if (error != null) { failure = null; throw error; }
    values[key] = value;
  }
}
```
`SharedPreferencesAsync` is a plain class (`shared_preferences-2.5.3/lib/src/shared_preferences_async.dart:19`), so `implements`/`Fake` works.

### Cubit-level in-memory store (for cubit/widget tests)
```dart
// test/helpers/fakes/in_memory_notification_preferences_store.dart (pattern: in_memory_session_store.dart)
class InMemoryNotificationPreferencesStore implements NotificationPreferencesStore {
  final Map<String, bool> values = {};
  bool failNextWrite = false;
  Object? readFailure;
  ...
}
```

### MockCubit registration for widget tests
Add to `test/helpers/mocks.dart` (header rule: "never redefine a mock in a single test file"): `MockCharacterDeletionRepository`, `MockCharacterDeletionCubit extends MockCubit<CharacterDeletionState>`, `MockNotificationPreferencesCubit extends MockCubit<NotificationPreferencesState>`, `MockNotificationPreferencesStore`.

### Schema check (exact commands, for the last plan)
```bash
cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide
rm -rf /tmp/kg-docs   # or a scratch dir
dart run tool/schema_check/dump_documents.dart /tmp/kg-docs
NODE_PATH=/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/node_modules \
  node tool/schema_check/validate_documents.js \
  /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/schema.gql /tmp/kg-docs
```
(Usage block in `tool/schema_check/validate_documents.js:1-6`; `dump_documents.dart` writes one `<operation>.graphql` per entry of `schemaCheckDocuments`, one file per document because `UserFields` repeats.) Expected: every line `OK <name>.graphql`, exit 0, now including `OK DeleteCharacter.graphql` (the `schemaCheckDocuments` map has 24 entries today). The BE schema currently contains `deleteCharacter: User!` at line 289. **During this research** the same `validate_documents.js` was run (with the BE `graphql` 16.11.0 and the BE `src/schema.gql`) on a scratch copy of the proposed `DeleteCharacter` document (+ `UserFields`) and printed `OK DeleteCharacter.graphql`. Note: `dart run` may trigger an implicit pub resolution; the executor of the last plan (not this read-only research) decides whether that is acceptable with the already-modified `pubspec.lock`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `SharedPreferences.getInstance` (cached singleton, `flutter.` prefix) | `SharedPreferencesAsync` / `SharedPreferencesWithCache` | `shared_preferences` 2.3.0; README says the legacy API "will be deprecated in the future" | Use Async for the new store; leave `SecureSessionStore`'s marker alone (no migration, no scope creep) |
| `MaterialStateProperty` | `WidgetStateProperty` | Flutter 3.22 | Use `WidgetStateProperty.resolveWith` in `SwitchThemeData` (3.35.5 here) |
| hard-coded `index <= 2` menu geometry | table-driven `SatchelLayout` | this phase | Any grid change is data, not code |

**Deprecated/outdated:** `lib/repository/storage/storage_manager.dart` (`KGStorageManager`, static legacy wrapper) — do not extend (D-10 note); `lib/repository/storage/cubit/storage_cubit.dart` is unrelated to preferences.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `emptySatchel` is an acceptable temporary icon for Settings (judged from a rendered PNG; subjective) | Pattern 2 | Low: swap one constant; user supplies the real asset |
| A2 | Phase 5's background FCM isolate will obtain the user id from the FCM data message (`userId`), since the store is keyed per user; not specified anywhere yet | Pattern 4 | Medium for Phase 5 only: if the BE cannot add it, Phase 5 needs a different "active user" pointer; Phase 4's store API (explicit `userId` parameter) works with either |
| A3 | `SharedPreferencesAsync` read from a background FCM isolate on a real device returns the foreground isolate's latest write (documented in the plugin README; not exercised here) | Standard Stack, Pattern 4 | Low-medium: Phase 5 must verify on device with the app killed; fallback is `SharedPreferences.reload()` on the legacy API |
| A4 | A 667 px-wide landscape device is a realistic support target (iPhone SE class); the adaptive `cellWidth` formula is computed, not run on such a device | Pitfall 1 | Low: the formula only helps; widget test covers 667x375 |
| A5 | The `SwitchThemeData` colour mapping (gold thumb / bronze track / wood-parchment off state) suits the parchment sheet | Pattern 7 | Low: cosmetic, tokens only |
| A6 | `dart run tool/schema_check/dump_documents.dart` does not need `flutter pub get` (all its imports are already in the lock) | Code Examples | Low: if it re-resolves, only `pubspec.lock` (already modified) is affected |

## Open Questions (RESOLVED)

1. **Which existing SVG is the placeholder for `settings`?**
   - RESOLVED: `emptySatchel` (`static const String settings = emptySatchel;`), because `pouch` would look identical to the satchel button in the open overlay (Pattern 2, A1).
2. **`SettingsCubit` or two cubits?**
   - RESOLVED: two (`NotificationPreferencesCubit`, `CharacterDeletionCubit`), both in `AuthenticatedShell` (Patterns 4, 6, 9).
3. **Key scheme and store API?**
   - RESOLVED: one boolean key per (user id, category), `klimmeck.notifications.<userId>.<travel_end|streamer_live|quest_end>`; interface `isEnabled/readAll/setEnabled`; no change stream (Alternatives Considered, Pattern 4).
4. **Does `adoptUser` accept `currentCharacter: null`?**
   - RESOLVED: yes in both services; a regression test is the only addition (Pattern 8).
5. **Does anything else need to change in `SessionHome`/`AuthGate` for deletion?**
   - RESOLVED: no (Pattern 8). The old `characterUpdated` subscription is closed by the shell unmount; the BE does not complete it (BE handoff §4).
6. **What if `CHARACTER_NOT_FOUND` arrives?**
   - RESOLVED: refetch `me`; if `currentCharacter == null`, hand the user to `adoptUser` as a normal success; otherwise show the generic inline message (Pattern 6; BE handoff §0.3, §4 corrupted-reference case also resolves through `deleteCharacter` itself).
7. **FE proposal vs final BE contract?**
   - RESOLVED: no divergence in names or codes (BE handoff §10); the BE handoff and `src/schema.gql` win. Differences with no wire impact: subscribe on an archived id returns `NOT_FOUND` (not `FORBIDDEN`) and is silent/not completed for already-open streams.
8. **How will the overlay fit narrow screens?**
   - RESOLVED: adaptive `cellWidth` (Pitfall 1).
9. **Does the BE refuse deletion during an active quest/travel?**
   - RESOLVED: no; it archives anyway, `pendingQuest` stays on the archived document (BE handoff §7.1); the FE does no pre-check (D-21).

(No unresolved item remains; the only unverifiable-here points are recorded in the Assumptions Log: A2, A3.)

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | build/tests | yes | 3.35.5 (Dart 3.9.2) | — |
| `flutter test` / `flutter analyze` | gates | yes (run this session) | — | — |
| Node.js | `tool/schema_check/validate_documents.js` | yes | 22.12.0 | — |
| BE `node_modules/graphql` | schema validation (`NODE_PATH`) | yes | 16.11.0 | — |
| BE `src/schema.gql` with `deleteCharacter: User!` | schema check (SET-05, D-20) | yes (line 289; BE PR #6 merged into BE `develop`) | — | — |
| Physical device / emulator + running BE | manual E2E (delete -> creation -> same name -> shell) | not probed (the project memory documents a Samsung over USB with `adb reverse tcp:3000`) | — | Emulator against a local BE; E2E is manual-only |
| Cloudinary reachability | rendering placeholder (not required by tests) | yes (PNG renders fetched) | — | `CachedSvg` empty box |

**Missing dependencies with no fallback:** none for development. The manual E2E needs a device and the BE running (the user's environment).
**Missing dependencies with fallback:** none.

## Validation Architecture

(`.planning/config.json` has no `workflow.nyquist_validation: false`, so this section is required.)

### Baseline (recorded 2026-10-16, branch `feat/04-settings-screen`, working tree = HEAD + the pre-existing `pubspec.lock` change)
- `flutter test` -> **645 tests, All tests passed, ~19 s** (`00:19 +645: All tests passed!`). (Phase 3's research recorded 481; the suite has grown since. The CONTEXT/task estimate of ~500 is stale.)
- `flutter analyze` -> **57 issues found (ran in 2.9 s): 0 errors, 4 warnings, 53 infos**, all pre-existing: `dead_null_aware_expression` in `lib/screens/mainScreen/tabs/board/board.dart:54,65` and `lib/shared/components/spell_info.dart:52`, `unnecessary_cast` in `test/repository/services/auth/auth_token_service_contract_test.dart:40`, the rest `avoid_print` infos in `tools/svg_tool.dart` etc. Plans must not regress these numbers: run `flutter analyze <touched files>` per task and confirm the total stays <= 57.
- Existing helper layout: `test/helpers/mocks.dart` (shared mocks, header: add mocks there, never in a test file), `auth_fixtures.dart` (`buildTestUser`, `buildTestUserWithCharacter`, `testUserId`, `testCharacterId`), `auth_session_fixtures.dart`, `landscape.dart` (`useLandscapePhone`: 780x360), `test_app.dart` (`buildTestApp(home:)`, disables Google Fonts fetching), `fakes/` (`in_memory_session_store.dart`, `recording_sync_health.dart`, fake WS server, scripted HTTP adapters), `fixtures/` (`race_traits_fixture.dart`, `sync_event_fixtures.dart`, `dev_auth_env.dart`). GraphQL service tests fake results with `Link.function` returning `Stream.value(Response(...))` (`test/repository/services/graphql/graphql_character_creation_test.dart:35-60`); repository tests mock `KlimmeckGraphQl` with mocktail and throw `OperationException(graphqlErrors: [GraphQLError(message:, extensions: {'code': ...})])` (`character_creation_repository_test.dart:30-44`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test` 10.0.0 + `mocktail` 1.0.5 (+ `fake_async` 1.3.3 if timers appear) |
| Config file | none (defaults); shared mocks in `test/helpers/mocks.dart` |
| Quick run command | `flutter test test/screens/mainScreen test/repository/storage test/repository/character_deletion_repository_test.dart test/repository/services/graphql test/graphql test/shared/components/modal test/theme test/tool test/screens/auth` |
| Full suite command | `flutter test` (baseline 645, ~19 s) + `flutter analyze <touched files>` + `dart format --output=none --set-exit-if-changed <each touched file>` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SET-01 | `SatchelLayout`: 7 entries, `pageIndex` 0..6 unique, Mappa `(col 0, row 0, span 2)`, row 0 = Profilo/Diario/Libreria, row 1 = Bacheca/Negozio/Impostazioni, no cell overlap | unit | `flutter test test/screens/mainScreen/components/satchel_layout_test.dart` | Wave 0 |
| SET-01 | `flightEnd` equals the legacy values for the old grid cells (top row `-(3H/4)+50`, bottom `-(H/4)+50`) and Mappa lands at the animation start y; `cellWidth` shrinks below 760 px and never exceeds 152 | unit | same file | Wave 0 |
| SET-01 | `MenuBackground` renders the 7 labels, tapping "Impostazioni" calls `onTap(6)` and "Mappa" `onTap(0)`; no overflow at 780x360 and 667x375 | widget | `flutter test test/screens/mainScreen/components/menu_background_test.dart` | Wave 0 |
| SET-01 | `CloudinaryAssets.settings` exists and is a valid asset path | unit | `flutter test test/config` (extend, or inside the layout test) | extend/Wave 0 |
| SET-01 | `Settings` tab smoke: renders title "Impostazioni", the character name from `CharacterLoaded`, sections "Notifiche" and "Account", no `AppBar`/`Scaffold` | widget | `flutter test test/screens/mainScreen/tabs/settings/settings_test.dart` | Wave 0 |
| SET-02 | `NotificationCategory.storageKey` pinned (`travel_end`, `streamer_live`, `quest_end`) | unit | `flutter test test/models/notification_category_test.dart` | Wave 0 |
| SET-02 | Cubit: `load` fills from the store (default all true when empty); `toggle` emits the new value then persists; failed write reverts only that category and does not throw; `toggle` before load is ignored; late `load` does not overwrite a user toggle; `close()` then late emit is silent | cubit (`bloc_test`) | `flutter test test/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit_test.dart` | Wave 0 |
| SET-02 | Widget: three switches reflect state, tapping calls `toggle(category, value)`, switches disabled until loaded; theme colours come from `switchTheme` (no inline colours) | widget | `settings_test.dart` + `flutter test test/theme/kg_theme_test.dart` | Wave 0 / extend |
| SET-03 | "Esci" is the last scrollable element; tapping it opens the logout dialog and "Esci" confirm calls `AuthCubit.logout()` once; "Annulla" does not | widget | `settings_test.dart` (+ existing `logout_confirmation_dialog_test.dart` stays green after the shared-dialog extraction) | Wave 0 / exists |
| SET-04 | Store: write -> new store instance over the same backing map -> same values; per-user isolation (user A off does not affect user B); absent key = enabled; keys are exactly `klimmeck.notifications.<userId>.<storageKey>`; read failure surfaces to the caller (cubit falls back to defaults) | unit | `flutter test test/repository/storage/notification_preferences_store_test.dart` | Wave 0 |
| SET-04 | Logout/teardown leave preferences untouched (the store is not reachable from `SecureSessionStore`; keys outside `klimmeck.session.`) | unit | same file | Wave 0 |
| SET-05 | Document `DeleteCharacter`: one named mutation, no variables, selects `...UserFields` defined once | unit (document) | `flutter test test/graphql/character_deletion_document_test.dart` | Wave 0 |
| SET-05 | Schema-check listing includes `DeleteCharacter` (suite fails otherwise) | unit | `flutter test test/tool/schema_check_documents_test.dart` | exists (auto-enforces) |
| SET-05 | `KlimmeckGraphQl.deleteCharacter`: sends operation `DeleteCharacter` with no variables, maps `currentCharacter: null` payload to a `User` with null character, raises `OperationException` keeping the code | unit | `flutter test test/repository/services/graphql/graphql_character_deletion_test.dart` | Wave 0 |
| SET-05 | Repository: `CHARACTER_NOT_FOUND` -> `notFound`, `UNAUTHENTICATED` -> `unauthenticated`, link error without code -> `connection`, malformed payload (`FormatException`) -> `unknown`; message text never used | unit | `flutter test test/repository/character_deletion_repository_test.dart` (+ `character_deletion_failure_test.dart`) | Wave 0 |
| SET-05 | Cubit: success sequence; `notFound` -> refetch -> hand-over without error; `notFound` + refetch still has a character or fails -> `unknown`; other failures keep the player able to retry; double tap ignored while deleting; `handoverRejected`; `SafeEmit` after close | cubit | `flutter test test/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit_test.dart` | Wave 0 |
| SET-05 | Widget: "Elimina personaggio" opens the dialog with the character name, "Annulla" does nothing, "Elimina" calls `deleteCharacter` once; barrier tap keeps it open; button disabled with progress while `isDeleting`; inline failure message by code; `deletedUser` triggers `adoptUser`, refused adoption calls `handoverRejected` | widget | `settings_test.dart` + `flutter test test/shared/components/modal` | Wave 0 |
| SET-05 | `adoptUser` accepts a user whose `currentCharacter` becomes null (real service and dev stub) | unit | `flutter test test/repository/services/auth/session_auth_token_service_adopt_user_test.dart test/repository/services/auth/dev_auth_token_service_transitions_test.dart` | exist, extend |
| SET-05 | `AuthGate`/`SessionHome`: `id -> null` shows creation and pops root dialogs (already covered by Phase 3; keep green) | widget | `flutter test test/screens/auth/auth_gate_test.dart test/screens/auth/session_home_test.dart` | exist |
| SET-05 | Shell provides both cubits and closes them on character change | widget | `flutter test test/screens/auth/authenticated_shell_test.dart` | exists, extend (new constructor args) |
| SET-05 | End-to-end: delete -> creation page -> create with the SAME name -> game shell; second tap/stale state; relaunch keeps toggles | manual (real BE + device) | checklist below | manual-only: needs BE and device |
| D-20 | All FE documents (24 + `DeleteCharacter`) validate against the BE schema | scripted pre-PR gate | `tool/schema_check` commands above | tooling exists |

**Manual E2E checklist (last plan, to be recorded in `BACKEND-NOTES.md`):** BE PR 03.1 merged on BE `develop` and running; log in (dev bypass or Twitch); open the satchel, Settings is the 7th entry and opens the tab; toggle each switch, kill the app, relaunch: values persist; log out and back in as the same user: values persist; delete the character via the dialog: lands on the creation page without a flash of the game; create a character with the **same name** (BE handoff §0.4): accepted; delete twice quickly / stale state: no blocking error; airplane mode during delete: inline connection message, retry works.

### Sampling Rate
- **Per task commit:** the targeted test file(s) of the task (`flutter test <file>`), plus `flutter analyze <touched files>` and `dart format --output=none --set-exit-if-changed <touched files>` (single files only).
- **Per wave merge:** the quick run command above.
- **Phase gate:** full `flutter test` green (>= 645 + the new tests), `flutter analyze` total <= 57 issues with 0 errors, schema check green against the BE schema, manual E2E checklist done — **before** the PR is opened (BE PR first, D-20).

### Wave 0 Gaps (scaffolding the plans need first, TDD)
- [ ] `test/helpers/fakes/fake_shared_preferences_async.dart` — in-memory `Fake implements SharedPreferencesAsync` with failure injection.
- [ ] `test/helpers/fakes/in_memory_notification_preferences_store.dart` — cubit/widget-level fake with `failNextWrite` / `readFailure` (pattern of `in_memory_session_store.dart`).
- [ ] `test/helpers/mocks.dart` — add `MockCharacterDeletionRepository`, `MockCharacterDeletionCubit`, `MockNotificationPreferencesCubit`, `MockNotificationPreferencesStore`.
- [ ] Failing-first tests (Red) for every new unit listed in the map before its implementation.
- [ ] `test/screens/auth/authenticated_shell_test.dart` — update the construction site for `notificationStore` and `userId`.
- [ ] `tool/schema_check/schema_check_documents.dart` — list `DeleteCharacter` **in the same commit** as the document (Pitfall 4).
- [ ] REQUIREMENTS.md traceability (SET-01..05 -> Phase 4) and `BACKEND-NOTES.md` final section (E2E result) at the end; planning docs travel with the code in the PR (`docs/rules/workflow.md`).

## Security Domain

(`security_enforcement` is absent in `.planning/config.json`, therefore enabled.)

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (inherited) | Logout reuses `confirmLogout` -> `AuthCubit.logout()` -> Phase 11 atomic teardown; the mutation carries the session bearer through `AuthLink` (refresh single-flight) |
| V3 Session Management | yes | After deletion the session user is replaced only through `adoptUser` (refuses another `user.id`); cubits close with the session subtree (`SafeEmit`) |
| V4 Access Control | yes | The FE sends **no identifier**: `deleteCharacter` takes no arguments and the BE derives identity from the bearer (BE handoff §0.1); the FE cannot target another user's character; `FORBIDDEN`/`NOT_FOUND` semantics for others are the BE's |
| V5 Input Validation | yes | No free-text input in this phase. The mutation response is parsed at one boundary (`_userFrom`/`User.fromJson`); malformed -> `FormatException` -> `unknown`, never an unhandled exception. Stored preference values are read as `bool?` only (a wrongly typed value would throw inside the store and falls back to defaults in the cubit) |
| V6 Cryptography | no | No new crypto; the preferences are non-sensitive booleans in plain `shared_preferences` (tokens stay in secure storage) |
| V7 Error handling & logging | yes | Log only error *types/codes*, never tokens, payloads, user ids or the character name (`docs/rules/graphql.md`); UI messages are domain copy chosen by code, never server text (`ui-ux.md`) |
| V12 / business logic (destructive action) | yes | Irreversible action behind a non-dismissible confirmation dialog; double-tap and concurrent calls neutralised by the in-flight guard (FE) and by the BE's single-winner transaction (`CHARACTER_NOT_FOUND` for losers) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental or repeated deletion (fat finger, double tap, retry storm) | Tampering / DoS (self) | Confirmation dialog with `barrierDismissible: false`; `isDeleting` guard in the cubit; button disabled while in flight; BE idempotency (one winner, others `CHARACTER_NOT_FOUND`) |
| Deleting while the session is stale or another identity is active | Spoofing / Elevation | No identifier sent; `adoptUser` refuses a response for a different `user.id` (`handoverRejected`); a late response after logout hits a closed cubit (`SafeEmit`) |
| Late response of a previous session entering the next one | Info disclosure | Cubit closed with the shell; `adoptUser` id guard; no static/global holder of the result |
| Local preference tampering / leakage across accounts | Tampering / Info disclosure | Preferences are non-secret UI state; keyed per `user.id`, so a second account never reads the first one's toggles; no PII in the key beyond the opaque Mongo id; not synced anywhere |
| Preferences wiped or leaked by logout | Info disclosure / Repudiation | Separate namespace, never cleared on logout (D-11); no token or session data in `shared_preferences` |
| Technical error text shown to the user / information leak via messages | Info disclosure | Map by `extensions.code`; fixed Italian domain copy; never display `OperationException` text |
| Logging sensitive values (user id, character name, tokens) | Info disclosure | `debugPrint` limited to `runtimeType`; no payload logging |
| Stale archived character still subscribed after deletion | Info disclosure / DoS | Shell unmount closes the `characterUpdated` subscription (BE does not complete it); a new subscribe on the archived id gets `NOT_FOUND`+`complete`, which the FE already treats as terminal (Phase 3) |
| Dev bypass in production builds issuing real mutations | Elevation | Out of scope here (Phase 12 hardening removes the stub); the mutation still hits the real BE, which is the security boundary |

## Sources

### Primary (HIGH confidence)
- Repo code read this session (paths and line numbers cited inline): `lib/screens/mainScreen/{main_screen.dart, components/*}`, `lib/config/cloudinary_assets.dart`, `lib/shared/components/{cached_svg.dart, background_image.dart, modal/logout_confirmation_dialog.dart}`, `lib/screens/mainScreen/tabs/profile/profile.dart`, `lib/theme/kg_theme.dart`, `lib/repository/storage/{session_store.dart, storage_manager.dart}`, `lib/graphql/{mutations/character_mutations.dart, fragments/user_fragment.dart}`, `lib/repository/{character_creation_repository.dart, character_creation_failure.dart}`, `lib/repository/services/graphql/{graphql.dart, graphql_error_code.dart, auth_link.dart}`, `lib/repository/services/auth/{session_auth_token_service.dart, dev_auth_token_service.dart, auth_token_service.dart}`, `lib/screens/auth/{auth_gate.dart, session_home.dart, authenticated_shell.dart, session_sync_scope.dart}`, `lib/screens/characterCreation/{character_creation_screen.dart, cubit/character_creation_cubit.dart, components/character_creation_messages.dart}`, `lib/models/user.dart`, `lib/main.dart`, `tool/schema_check/*`, `test/helpers/*`, `test/tool/schema_check_documents_test.dart`, `test/repository/storage/session_store_test.dart`, `pubspec.yaml`, `pubspec.lock`.
- BE final contract: `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/03.1-character-deletion-contract/BACKEND-NOTES.md` (all sections) and `src/schema.gql` line 289 (`deleteCharacter: User!`).
- `shared_preferences` package docs read from the local pub cache: `shared_preferences-2.5.5/README.md` (API comparison, multi-isolate caveat), `shared_preferences-2.5.3/lib/src/shared_preferences_async.dart` (class shape, methods), `shared_preferences_platform_interface-2.4.1/lib/in_memory_shared_preferences_async.dart`.
- Executed this session: `flutter test` (645 passed), `flutter analyze` (57 issues), `node tool/schema_check/validate_documents.js <BE schema> <scratch dir>` with the proposed `DeleteCharacter` document (`OK`), `dart --version`, rendered PNGs of `pouch`/`emptySatchel` from Cloudinary.

### Secondary (MEDIUM confidence)
- None used.

### Tertiary (LOW confidence)
- None. Items not verifiable here are in the Assumptions Log (A2, A3, A4).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — everything is already in the project; no dependency change; `SharedPreferencesAsync` present in the locked version.
- Architecture: HIGH for the layout model, deletion path and session hand-off (code read, document validated); MEDIUM for the placement recommendation of the cubits (design choice within stated discretion, consistent with `AuthenticatedShell` practice).
- Pitfalls: HIGH for 1-9 (derived from code and tests read), MEDIUM for device-level overlay fit (computed only).

**Research date:** 2026-10-16
**Valid until:** 2026-11-15 (30 days; re-check if the BE contract changes before the BE PR merges, if `shared_preferences` is bumped, or if the Cloudinary `settings` asset lands)
