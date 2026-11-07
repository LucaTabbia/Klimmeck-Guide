# Phase 17: Unlockable Lore - Research

**Researched:** 2026-11-07
**Domain:** Flutter wire-contract extension (`CharacterStatus.unlockedLore`, `QuestEnemy.known`, `QuestResult.loreUnlocked`, nullable `City.relatedLore`), silent live refresh of the Library driven by the Character stream, a per-character device baseline for the «Nuovo» bookmark, a black-silhouette portrait, two result-sheet lines, a name-only Map modal
**Confidence:** HIGH for code facts (file:line read this session; two throwaway probe files, 10 probes, run and deleted); MEDIUM for the BE names (fixed in the BE `16-REPO-RULES.md`, not on BE `origin/develop`: `grep -c "loreUnlocked\|unlockedLore"` = 0 at `9103440`)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Copied by reference, authoritative text in `17-CONTEXT.md` §Implementation Decisions (do not paraphrase in plans):
- **D-01** `CharacterStatus.unlockedLore: [ID!]!` ids only, parsed into `List<String>`, used ONLY to know when/what changed (refetch trigger, «Nuovo» marks); known-enemies set never on the wire.
- **D-02** `lores`/`lore(id)` filtered per bearer's current character (`NOT_FOUND` for a locked id); innkeeper sees everything; the dev-bypass account is the innkeeper → the device E2E needs a player identity, written in `17-HUMAN-UAT.md`.
- **D-03** `QuestEnemy.known: Boolean!` on `Quest.infos.enemies[]` and `QuestResult.enemies[]` = exact enemy defeated; `QuestEnemy` gains `known` (strict on the board, lenient on results); `Enemy` unchanged.
- **D-04** `QuestResult.loreUnlocked: [Lore!]!` = only the lore newly unlocked by that outcome; FE selects `{ id name type }`, lenient (malformed entries dropped, result stays).
- **D-05** `LibraryCubit` refetches `lores` when the SET of `unlockedLore` ids changes while a book is open; the page recomputes its lists from the new state; no refetch on HP ticks; failed refetch keeps the page, no error page mid-session, silent retry on the next change.
- **D-06** a section (type) with nothing unlocked is hidden; an empty book shows one status line on the parchment; the four books and their type mapping do not change.
- **D-07** «Nuovo» bookmark on entries unlocked since the last opening of that book, until reopened; baseline = ids shown at the previous opening, per character, `shared_preferences`; live arrivals marked too; no baseline → no marks; recreated character → fresh baseline; never sent to the BE.
- **D-08** unknown enemy → full black silhouette (alpha of SVG or raster, e.g. `ColorFiltered` + `BlendMode.srcIn`, theme ink), same size/placement; name lines and loot unchanged; semantics label distinguishes the states; `EnemyPortrait` takes the flag; the strongest enemy's portrait follows that enemy's `known`; no path → nothing.
- **D-09** victory result → defeated enemies arrive `known: true` (portrait clear); defeat/rescue/death → silhouette stays; ambush sheets inherit; board staleness accepted, noted in BACKEND-NOTES.
- **D-10** after «Magia appresa» one line per `loreUnlocked` entry in BE order: `enemy`/`animal`/`plant` → «Nuova pagina del Bestiario: <name>», other types → «Conoscenza appresa: <name>»; empty → no line.
- **D-11** `City.relatedLore` null → same paper modal with the city name and «Non conosci ancora questa città.», no `lore(id)` call (today `city.relatedLore!.id` would crash); known cities as today; teleport unchanged; quest narrative whole.
- **D-12** technical defaults (models, fragments, store, keys, test conventions) — see CONTEXT.
- **D-13** gating: plans before the BE Phase 16 merge on fixtures/mocks; after it the schema gate and the device E2E (player identity; the 16-08 E2E in the same session), `BACKEND-NOTES.md` closes the phase.
- **D-14** once fragments select the new fields the branch never runs against a BE without Phase 16.

### Claude's Discretion
Copy of the status line, the «Nuovo» mark, the Map line and the result lines; the bookmark's look; the silhouette ink; the refetch debounce; where the id comparison lives (cubit vs shell); fixture names; whether `LoreRef` reuses `Lore` with nullable fields or is its own class; the store's key shape; the test harness for the live refresh. (REPO-RULES since fixed: the copy strings, `List<Lore>` reuse, `LibraryBookmarksStore` names.)

### Deferred Ideas (OUT OF SCOPE)
Lore hyperlinks (v2); lore detail/zoom page, images for non-city lore; filtering the narrative quest paragraphs; knowledge by species; «Nuovo» counts on the book covers; common knowledge / `Lore.unlocked`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LORE-01 | Library shows only the backend-filtered lore, live after each unlock (ids on `CharacterStatus.unlockedLore`), empty sections hidden, one status line for an empty book, «Nuovo» since the last opening per character | F1 (status field + where to observe it), F2 (silent refresh, recompute, guards), F3 (`LibraryBookmarksStore`, `newLoreIds`, C2/C4) |
| LORE-02 | Unknown enemies as black silhouettes with name lines unchanged on quest and result sheets; victory → clear + lines from `loreUnlocked` | F4 (silhouette, probes P7–P10), F5 (`QuestEnemy.known`, pinned selections, fixtures), F6 (`loreUnlocked` parsing + lines, P1–P4) |
| LORE-03 | New character sees home city + regions + state only (BE); unknown city → name-only Map modal; delete/recreate resets | F7 (Map tap branch, P5, C1 stale cities), F3 (key by character id → recreate = fresh baseline), F8 (UAT with a player identity) |
</phase_requirements>

## Project Constraints (from CLAUDE.md)
- Clean Code, SoC (UI no networking; Cubit no Flutter/`BuildContext`; models Flutter-free; repository/storage no `BuildContext`), TDD red→green→refactor, Boy Scout rule.
- Rule 1: no app chrome on gameplay surfaces (Library, Map, sheets). Rule 2: **no blocking loading in session** — the Library refresh must not emit a loading state; an unlock never shows a spinner. Rule 3: branch `feat/17-unlockable-lore`, PR → `develop`. Rule 4: **the backend is the source of truth** — no client unlock logic; `known`, `loreUnlocked`, `lores`, `City.relatedLore` rendered as received. Rule 5: no secrets.
- `flutter analyze` 0 error / 0 warning — **baseline measured this session on the branch: `50 issues found.`, 0 error/warning lines** (one of the 50 is `avoid_print` at `lib/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart:24:7`, a file this phase touches → Boy Scout `debugPrint`).
- `docs/rules/state-management.md` §Anti-pattern: «Cubit che chiama altri Cubit direttamente: orchestrazione … nella UI via `BlocListener`» (relevant to D-12, C3); `bloc_test` for every non-trivial cubit; `BlocListener` + `listenWhen` for side effects.
- `docs/rules/ui-ux.md`: theme tokens only (`lib/theme/kg_theme.dart`), `ListView.builder` for long lists, semantics labels on images, stale data kept on refresh errors. `docs/rules/assets.md`: domain SVGs only through `CachedSvg`. `docs/rules/architecture.md`: storage classes in `lib/repository/storage/`, widget used by ≥ 2 features in `lib/shared/components/`. `docs/rules/naming.md`: `label` for user-facing enum text (convention of `QuestType`, `InjuryType`, `SexType`…), booleans `isX/hasX`.
- `17-REPO-RULES.md`: contract and FE names (§GraphQL contract), the fixed copy, fragment change in the SAME commit as the model that reads it, `dart format` per file, commit trailers forbidden, gate grep `loreUnlocked` on BE `origin/develop`.

## Summary

Three facts shape the plan. **(1) The contract change is mechanical but touches pinned strings in four places**: `known` inside `enemies { … }` breaks two exact selections (`board_documents_test.dart:53`, `quest_result_documents_test.dart:56`), the strict `QuestEnemy.fromJson` makes every enemy fixture invalid unless `known` is added — fortunately all 18 wire fixtures outside `quest_enemy_test.dart` go through ONE helper (`questEnemyJson`, `test/helpers/fixtures/quest_fixtures.dart:6-16`), so a default `known: true` keeps every existing test green and isolates the silhouette cases. `QuestEnemy.toJson` must write `known` or the result round trip (`quest_result_test.dart:370-398`) loses entries. **(2) The «reuse `Lore`» decision of REPO-RULES hides a real bug**: `LoreTypeExtension.name` (`lib/models/enums/lore_type.dart:16-44`) shadows `Enum.name`, so `LoreType.enemy.name == 'Mostri'` and `Lore.toJson` writes the Italian label, which `Lore.fromJson` cannot read back (probes P1, P3: `ArgumentError`). Any `QuestResult.toJson` round trip with `loreUnlocked` fails until the extension getter is renamed `label` (project convention) and the one UI call site (`library_data_page.dart:68`, section titles) is moved to `.label`. **(3) Two staleness traps sit outside the Library**: the Map's `cities` are fetched once per shell (`main_screen.dart:100-107` → `MainScreenCubit.loadData`, which emits a blocking `MainScreenLoading`), so a city visited during the session stays «Non conosci ancora questa città.» until a cold restart (C1); and `LibraryCubit.goToInitial()` runs on every mount of the tab (`library.dart:25`) — a refetch in flight when the player leaves the book would re-open it on completion unless the cubit drops stale completions.

The Library itself is small (429 lines in 8 files, no tests today). The recommended shape: a `LibraryBook` enum (the four books with their types and a storage key), `LibraryCubit(graphQl, bookmarks:, characterId:)` with `openBook(book)` (explicit tap: may emit `LibraryLoading`), `syncUnlockedLore(ids)` (silent: never emits loading; compares sets against the last ids received; single-flight with one trailing re-run), `goToInitial()`; `LibraryLoadData(book, lore, newLoreIds)`; a `BlocListener<CharacterCubit>` in `Library` forwards the ids (no cubit-to-cubit stream, C3); `LibraryDataPage` computes visible sections in `build` with `ValueKey(type)` on each `Dropdown`. The silhouette is one `ColorFiltered(ColorFilter.mode(KlimmeckGuideTheme.deepNight, BlendMode.srcIn))` around the picture — probes P7–P10 show it paints opaque pixels in the ink and keeps transparent ones, for both a seeded `CachedSvg` and a raster `Image`, without hanging `pumpAndSettle`, and keeps the semantics label.

**Primary recommendation:** models + fragments first (rename `LoreType.name`→`label`, then `QuestEnemy.known`, `CharacterStatus.unlockedLore`, `QuestResult.loreUnlocked`, each with its fragment and document test in the same commit), then `EnemyPortrait.known` + sheets, then the store, then Library cubit/page/listener, then the Map branch (+ C1 decision), then the gated schema check and device E2E on `grep -c loreUnlocked ≥ 1`.

## Standard Stack (all already in `pubspec.yaml`, no new dependency)

| Library | Use in this phase | Source |
|---------|-------------------|--------|
| `flutter` `ColorFiltered` / `ColorFilter.mode(…, BlendMode.srcIn)` (SDK) | silhouette over the existing picture | [VERIFIED: probe P7–P10] |
| `flutter_bloc` / `bloc_test ^10.0.0` / `mocktail ^1.0.5` | `LibraryCubit`, `BlocListener<CharacterCubit>`, mocks (`MockKlimmeckGraphQl` `test/helpers/mocks.dart:82`, `MockCharacterCubit` :122, `MockWorldMapCubit` :165) | [VERIFIED: codebase] |
| `shared_preferences 2.5.3` — **`SharedPreferencesAsync`** with an injected factory | `SharedPreferencesLibraryBookmarksStore` (`getStringList`/`setStringList` exist, `shared_preferences_async.dart:86, :122` in the pub cache) | [VERIFIED: codebase + pub cache] |
| `collection ^1.19.1` (direct dependency, `pubspec.yaml:34`) or `foundation.setEquals` | set comparison of `unlockedLore` | [VERIFIED: codebase] |
| `equatable` | `LibraryLoadData`, `CharacterStatus`, `QuestEnemy`, `QuestResult` props | [VERIFIED: codebase] |

`SharedPreferences.setMockInitialValues` does NOT reach `SharedPreferencesAsync` (probe P6: `StateError: The SharedPreferencesAsyncPlatform instance must be set.`) — see C2.

## Architecture Patterns

### Recommended files
```
lib/models/enums/lore_type.dart                     # extension getter name → label; + bool get isBestiary (enemy/animal/plant)
lib/models/enums/library_book.dart                   # NEW enum LibraryBook { bestiary, places, religions, knowledge } with types + title (label) + storageKey
lib/models/lore.dart                                 # (optional) tolerant type via asNameMap (OQ4); toJson writes the wire name after the rename
lib/models/character/character_status.dart           # + List<String> unlockedLore (const [] when absent)
lib/models/quest/quest_enemy.dart                    # + bool known (strict), toJson writes it, + strongestEntryOf
lib/models/quest/quest_sheet_details.dart            # + bool isStrongestEnemyKnown
lib/models/quest_result/quest_result.dart            # + List<Lore> loreUnlocked (lenient, const [])
lib/graphql/fragments/character_fragment.dart        # statusFields + unlockedLore
lib/graphql/fragments/quest_fragment.dart            # enemies { quantity known enemy { … } }
lib/graphql/fragments/quest_result_fragment.dart     # enemies { quantity known … } + loreUnlocked { id name type }
lib/repository/storage/library_bookmarks_store.dart  # NEW abstract LibraryBookmarksStore + SharedPreferencesLibraryBookmarksStore
lib/shared/components/enemy_portrait.dart            # + bool known (default true), silhouette, second semantics label
lib/shared/components/popup/quest_info_sheet.dart    # _enemyColumn passes known
lib/shared/components/popup/quest_result_sheet.dart  # _enemies passes known; lore lines after «Magia appresa»
lib/screens/mainScreen/tabs/library/library.dart                 # BlocListener<CharacterCubit> → syncUnlockedLore; openBook(book)
lib/screens/mainScreen/tabs/library/cubit/library_cubit.dart     # openBook / syncUnlockedLore / goToInitial
lib/screens/mainScreen/tabs/library/cubit/library_state.dart     # LibraryLoadData(book, lore, newLoreIds)
lib/screens/mainScreen/tabs/library/statesPages/library_initial_page.dart  # books from LibraryBook (covers/bookmarks stay here)
lib/screens/mainScreen/tabs/library/statesPages/library_data_page.dart     # sections in build, hidden when empty, status line, ValueKey(type)
lib/screens/mainScreen/tabs/library/components/lore_card.dart    # + isNew → «Nuovo» ribbon (newMarkKey)
lib/screens/mainScreen/tabs/map/world_map.dart                   # _openCityLore branches on relatedLore == null
lib/screens/mainScreen/tabs/map/components/city_modal.dart       # (or new unknown_city_modal.dart) name + fixed line
lib/screens/auth/authenticated_shell.dart + lib/main.dart        # LibraryCubit gets the store and characterId
(C1, if accepted) lib/screens/mainScreen/cubit/main_screen_cubit.dart + main_screen.dart  # silent refreshCities on unlockedLore change
```

### F1. Character contract [VERIFIED: codebase]
- Fragment: `CharacterFragment.statusFields` getter `character_fragment.dart:24-66` (`status {` at :26, `spellStates { usages recoveries spell { id } }` :58-64, closing `}` :65). Add `unlockedLore` (a scalar list, no sub-selection) right after the `spellStates` block. It reaches `GetCharacter` (`character_queries.dart:18`) and `characterUpdated` (`character_subscriptions.dart:7`) through `fullFields` — the only two users of `CharacterFragment` (grep). `PendingRequestFragment` has its own character selection (`pending_request_documents_test.dart:25`), unaffected.
- No test pins the whole status selection: `character_fragment_test.dart:44-52, :54-68, :87-92` are all `contains(...)` checks plus `startsWith('status {')` (:62) → appending is safe. New test: «statusFields selects unlockedLore (D-01)».
- Model `character_status.dart`: ctor :13-27 (optional named fields after the required ones), fields :29-47, `fromJson` :49-74, `_spellStatesFrom` :76-81 (precedent: `is! List → null`), `toJson` :83-97, `copyWith` :99-126 (carries the non-parameter fields explicitly: `activeTravel`, `spellStates`, `awaitingAid` at :122-124 — `unlockedLore` must be carried the same way, Pitfall 6), `props` :128-143. REPO-RULES fix the type to `List<String>` with `const []` when absent (unlike `spellStates`, which is nullable). Recommended parse: `json['unlockedLore'] is List ? List.unmodifiable(list.whereType<String>()) : const []`. No production or test code calls the `CharacterStatus(` constructor outside the model (grep) → adding `this.unlockedLore = const []` is free.
- Tests to extend: `test/models/character/character_status_test.dart` — helper `statusJson` :12-23 (add an `unlockedLore` param with the `_absent` sentinel pattern of `awaitingAid` :15/:22/:25), new group mirroring `spellStates` :93-168 (missing → `[]`, list parsed, non-string entries skipped, non-list → `[]`, `toJson`, props, copyWith keeps it).
- Observing the character: `CharacterCubit` (`character_cubit.dart:38`) emits `CharacterLoaded(character)` from `loadCharacter` :65-83 (after `CharacterLoading`), `refreshCharacter` :88-106 and the stream `_onCharacter` :115-120; state classes `character_state.dart:8-44` (`CharacterLoaded.character` :14). **No cubit in `lib/` subscribes to another cubit's stream** (the only `.stream.listen` is `lib/repository/services/auth/auth_state_channel.dart:19`); the established pattern is `BlocListener<CharacterCubit, CharacterState>` with a `listenWhen` on a derived value: `shop_pool_loader.dart:48-51` (city id change → `ShopCubit.getData`), `world_map.dart:190-193` (activeTravel change → `follow`), `:225-229` (pending lane). The shell provides `CharacterCubit` at `authenticated_shell.dart:136-143` and `LibraryCubit` at :153.

### F2. Library live refresh and empty states [VERIFIED: codebase]
- Today: `Library` (`library.dart:11-62`) holds the open book in widget state (`_selectedTypes`, `_title`, `_bookmarkImagePath` :19-21, set in `getData` :54-61), calls `goToInitial()` in `initState` :23-27, renders `LibraryInitialPage` / `LibraryDataPage` / `LibraryErrorPage` / **`Placeholder()` for `LibraryLoading`** (:47; `LibraryErrorPage` is also a `Placeholder`, `library_error_page.dart:8`). `LibraryCubit.loadLoreData` (`library_cubit.dart:16-25`) always emits `LibraryLoading` first, then `LibraryLoadData(lores)` or `LibraryError`. `LibraryDataPage` builds `_loreLists` in `initState` only (`library_data_page.dart:31-39`) and renders one `Dropdown` per type (:66-71, `sectionName: widget.types[i].name` — which is the Italian label only because of the shadowing extension, P1); `_LoreList` already returns `SizedBox.shrink()` for an empty list (:102) but the section header stays.
- Network: `getAllLores` (`graphql.dart:491-504`) → `performQuery` with `FetchPolicy.noCache` (:76-89) → every refetch is fresh, no cache invalidation needed. An empty `lores: []` parses to an empty list (no throw: only `null` throws, :499-501).
- The Library tab is a page of the main `PageView` (`main_screen.dart:171`, `Library()` at :202) without keep-alive: it is re-mounted at each visit (same observation as `shop_pool_loader.dart:10-12` «il PageView ricrea la tab a ogni apertura») → `goToInitial()` resets the cubit at each visit. The cubit outlives the tab (shell-scoped).
- **Recommended API (REPO-RULES names kept):**
  - `LibraryCubit(KlimmeckGraphQl graphQl, {required LibraryBookmarksStore bookmarks, required String characterId})`.
  - `Future<void> openBook(LibraryBook book)`: explicit user action → `LibraryLoading` allowed; fetch; filter to `book.types`; read the baseline; `newLoreIds = baseline == null ? {} : shownIds − baseline`; write the baseline; emit `LibraryLoadData(book: book, lore: lore, newLoreIds: …)`. Remember the session reference `_reference = baseline ?? shownIds` (C4).
  - `Future<void> syncUnlockedLore(Iterable<String> ids)`: compares `ids.toSet()` with the last set received (`_lastUnlocked`, first call only records); equal → nothing; if no book is shown (`state is! LibraryLoadData`) → record only; else silent refetch: **never emits `LibraryLoading`**, on success emits `LibraryLoadData(book, lore, newLoreIds: shownIds − _reference)` and rewrites the baseline; on failure keeps the state (debugPrint only, no `LibraryError`). Single-flight: a call during an in-flight refetch sets a «dirty» flag and one trailing refetch runs after (no `Timer`, no debounce needed — `characterUpdated` re-emits the whole document once per write).
  - Stale completion guard (Pitfall 2): capture the book (or a generation counter bumped by `openBook`/`goToInitial`) before the await and drop the result if `state` is no longer `LibraryLoadData` of the same book.
  - `goToInitial()` unchanged (bumps the generation).
- Where the ids come from: `Library.build` wraps its `BlocBuilder` in `BlocListener<CharacterCubit, CharacterState>(listenWhen: (_, current) => current is CharacterLoaded, listener: … syncUnlockedLore(current.character.status?.unlockedLore ?? const []))` — the set comparison lives in the cubit (bloc_test-able) and the listener stays dumb. Because `BlocListener` does not fire for the state present at mount, the first event after a re-mount compares against the ids of the previous mount: worst case one extra silent refetch, never a missed change while a book is shown (the open itself reads fresh data). Alternative (shell-level listener next to :153) keeps `_lastUnlocked` always fresh but refetches nothing more; either is fine — recommend the Library-level listener (consumer-local, no shell change beyond the constructor).
- Data page: compute the visible sections in `build` (StatelessWidget or `didUpdateWidget`), `for (final type in book.types) if (listOf(type).isNotEmpty) Dropdown(key: ValueKey(type), sectionName: type.label, data: _LoreList(...))`; when every list is empty render one `Text(LibraryDataPage.emptyBookLine, key: LibraryDataPage.emptyBookKey)` where the sections would be (same parchment, same `SingleChildScrollView`). `ValueKey(type)` keeps each `Dropdown`'s open state when a previously hidden section appears above it (Pitfall 3). `Dropdown` (`lib/shared/components/dropdown.dart:8-155`) needs no change (it is format-dirty: do not touch it).
- `goToInitial()` in `initState`: interferes only with a refetch in flight (handled by the generation guard) — it does not cancel anything and emits synchronously before the first build (existing behaviour).
- Tests: none exist (`test/screens/mainScreen/tabs/library/` absent; `grep -rln "LibraryCubit\|Library()" test` empty). Proposed Wave 0 files in the Validation Architecture. Harness: `MockKlimmeckGraphQl.getAllLores` stubbed with `thenAnswer`; a `Completer` to hold a refetch in flight; `InMemoryLibraryBookmarksStore` fake; widget tests with `buildTestApp` + `useLandscapePhone` (780×360: `LoreCard` uses `width − 360`, `lore_card.dart:36`) and **`seedSvgCache`** for `CloudinaryAssets.bestiary/locations/religions/knowledge` (`cloudinary_assets.dart:52-55`), `bookmarkRed/Green/Yellow/Blue` (:17-20), `arrowDown` (:23) — `CachedSvg` reads `SvgCache` (`cached_svg.dart:45-62`), so `useSvgHttpOverrides()` (which serves `SvgPicture.network`, `svg_http_overrides.dart:9-11`) is not the right seed (C6). Lore fixtures with `image: null` avoid seeding full URLs (`seedSvgCache` keys by `CloudinaryAssets.url(id)`, `svg_cache_seed.dart:13-15`). `BackgroundImage` uses `Image.asset('assets/images/background.png')` — bundled, fine in tests.

### F3. «Nuovo» bookmark store [VERIFIED: codebase + probe P6]
- Pattern: `NotificationPreferencesStore` (`notification_preferences_store.dart:7-17` abstract interface; `SharedPreferencesNotificationPreferencesStore` :22-53 with `SharedPreferencesAsync Function()? preferences` factory and a `late final` instance created at first use — «il costruttore lancia senza plugin registrato, es. nei test» :19-21; `keyPrefix` :28, `keyFor` :30-31). `ActiveUserStore` (`active_user_store.dart:5-33`) is the same shape. The concrete store is created once in `main.dart:155-156` and passed to `AuthenticatedShell` as a required parameter (`main.dart:334-344`, shell field :115); the only test construction of the shell is `authenticated_shell_test.dart:142-151`.
- Test pattern: `test/repository/storage/notification_preferences_store_test.dart:9-17` injects `FakeSharedPreferencesAsync` (`test/helpers/fakes/fake_shared_preferences_async.dart:6-44`: `getBool/setBool/getString/setString/remove`, `readFailures`/`writeFailures` queues) — **it lacks `getStringList`/`setStringList`**: the store plan adds them to the fake (same failure queues). Consumers use an in-memory fake (`in_memory_notification_preferences_store.dart:6-57`); add `test/helpers/fakes/in_memory_library_bookmarks_store.dart`.
- Recommended interface (names from REPO-RULES):
  ```dart
  abstract interface class LibraryBookmarksStore {
    Future<Set<String>?> readSeen(String characterId, LibraryBook book); // null = never opened
    Future<void> writeSeen(String characterId, LibraryBook book, Set<String> loreIds);
  }
  ```
  key `klimmeck.library.<characterId>.<book.storageKey>` (outside `klimmeck.session`, like the notification test at :28-33); value `setStringList` of the ids (sorted, for stable tests). Read failure → treated as «no baseline» (no marks, never an error page); write failure → swallowed (debugPrint).
- `LibraryLoadData.newLoreIds` (`Set<String>`) is computed in the cubit; `LoreCard(lore:, isNew:)` renders the ribbon «Nuovo» (`LoreCard.newMarkKey`, `LoreCard.newMarkLabel = 'Nuovo'`) next to the name row (`lore_card.dart:21-32`). Colour per book (discretion, OQ7): bestiary `royalCrimson`, places `healGreen`, religions `darkBronze`, knowledge `mysticBlue` (`kg_theme.dart:36-48`).
- D-07 «without a second write at close»: implementable — no close hook is needed. Semantics choice in C4.
- Per character: the shell is keyed by character id (`authenticated_shell.dart:84-86`, `SessionHome`) → a recreated character gets a new shell, a new cubit and new keys → fresh baseline for free; old keys stay on the device (tiny, never read).

### F4. Black silhouette [VERIFIED: codebase + probes P7–P10]
- `EnemyPortrait` (`enemy_portrait.dart:13-53`): SVG branch → `_announced(CachedSvg(url, height))` :36-38; raster → `CachedNetworkImage(imageBuilder: (_, image) => _announced(Image(...)), placeholder/error: SizedBox.shrink())` :39-48; `_announced` wraps `Semantics(label: semanticLabel, image: true)` :51-52; `semanticLabel = 'Ritratto del nemico'` :21 (pinned, `enemy_portrait_test.dart:121`). `CachedSvg` draws `SvgPicture.file(_file!, width, height, fit)` (`cached_svg.dart:80`) and a 14 px `CircularProgressIndicator` while loading (:66-73) — under the filter the spinner turns ink too (acceptable, unseeded only).
- Recommended: `EnemyPortrait({…, this.known = true})`; `_picture(Widget p) => known ? p : ColorFiltered(colorFilter: const ColorFilter.mode(KlimmeckGuideTheme.deepNight, BlendMode.srcIn), child: p)`; SVG: `_announced(_picture(CachedSvg(...)))`; raster: `imageBuilder: (_, image) => _announced(_picture(Image(...)))`; `_announced` picks `semanticLabel` or a new `unknownSemanticLabel` (copy needs the orchestrator's go, OQ3: suggested «Sagoma del nemico»). `flutter_svg`'s own `colorFilter` would need a `CachedSvg` change (format-dirty file): the wrapper is smaller and works for both branches.
- Ink: `KlimmeckGuideTheme.deepNight = Color(0xFF1E1B18)` (`kg_theme.dart:41`) — already the death-sheet ink (`quest_result_sheet.dart:462-463`). No new token needed.
- Probes (throwaway, deleted): P7 `ColorFiltered(srcIn, deepNight)` over a half-red box → opaque pixel `[30,27,24,255]` = ink, transparent pixel stays `[0,0,0,0]` (true silhouette of the alpha); P8 over a seeded `CachedSvg` → `pumpAndSettle` completes, `CachedSvg` found as descendant of `ColorFiltered`, no spinner, no exception; P9 over a raster `Image.memory` → `[30,27,24,255]`; P10 a `Semantics` label under `ColorFiltered` is found by `find.bySemanticsLabel`. **Do not copy the pixel technique into the suite**: reading pixels needs `tester.runAsync`, during which `google_fonts` tries its real font loads and the test errors (P7 failed after printing its result for that reason). Tests assert the widget tree: `find.descendant(of: find.byKey(portraitKey), matching: find.byType(ColorFiltered))` + the filter's `colorFilter == ColorFilter.mode(deepNight, BlendMode.srcIn)` + the label.
- Call sites: `quest_info_sheet.dart:213-243` `_enemyColumn` (`portraitPath = details.strongestEnemy?.imagePath` :214, `EnemyPortrait(key: enemyPortraitKey, …)` :219-222); `quest_result_sheet.dart:229-254` `_enemies` (`strongestEnemyOf(_result.enemies)?.imagePath` :235, `EnemyPortrait` :243-247).
- Smallest change for «the strongest enemy's own `known`»: add `QuestEnemy? strongestEntryOf(List<QuestEnemy>)` in `quest_enemy.dart` (same rule as `strongestEnemyOf` :106-114) and re-express `strongestEnemyOf` as `strongestEntryOf(e)?.enemy` (keeps `quest_enemy_test.dart:158-176` green); `QuestSheetDetails` gains `final bool isStrongestEnemyKnown` (= `strongestEntryOf(enemies)?.known ?? true`, added to `props` :140-153) beside `strongestEnemy` (:114, :133 — pinned by `quest_sheet_details_test.dart:246-250`); the result sheet reads `strongestEntryOf(_result.enemies)` directly.
- Existing portrait tests stay green if fixtures default to `known: true`: `quest_info_sheet_test.dart:147-159` (descendant `CachedSvg` of `enemyPortraitKey`), `quest_result_sheet_test.dart:185-201` (same), `enemy_portrait_test.dart:69-78, :112-123` (default `known: true`).

### F5. `QuestEnemy.known` [VERIFIED: codebase]
- Model `quest_enemy.dart:9-80`: `fromJson` strict (:14-32, `FormatException` for a missing enemy/id or bad quantity), `listFrom` strict (board, :39-43), `lenientListFrom` (results, :46-51, `_tryFromJson` :60-66), `toJson` :68-76, `props` :79. Add `known`: `if (json['known'] is! bool) throw const FormatException('QuestEnemy.known missing')` → board: quest dropped by `Quest.tryFromJson` (`quest.dart:38`); results: entry dropped. `toJson` writes `'known': known` (else the result round trip drops every entry). `props` gains `known`.
- Selections: `quest_fragment.dart:21-29` and `quest_result_fragment.dart:86-94` → `enemies { quantity known enemy { id name imagePath xp } }`. `QuestFragment` feeds `GetQuests`-style `quests` (`quest_queries.dart:8`) and `questUpdated` (`quest_subscriptions.dart:8`); `QuestResultFragment` feeds `quest_result_queries.dart:8, :19`, `quest_result_subscriptions.dart:8` and the innkeeper `CompletePendingRequest` (`pending_request_mutations.dart:10`) — all follow automatically. No other document selects `enemies {` (grep over `lib`/`tool`). Registry count unchanged (45).
- Pinned exact strings (update RED first, F9 table): `board_documents_test.dart:51-55` and `quest_result_documents_test.dart:50-66`. Unaffected: the block-count tests (`board_documents_test.dart:74-79`, `quest_result_documents_test.dart:68-77`: `\benemy \{` = `\benemies \{` = 1), `board_documents_test.dart:81` («title type description enemies {»), :88-93 (no lore under an enemy).
- Fixtures: `QuestEnemy(` is constructed only inside the model (`quest_enemy.dart:23`); wire maps: `questEnemyJson` (`quest_fixtures.dart:6-16`) used 18 times in 5 test files (`quest_result_fixtures.dart` 4, `quest_sheet_details_test.dart` 2, `quest_test.dart` 2, `quest_result_test.dart` 3, `quest_info_sheet_test.dart` 7) → add `bool known = true` and write `'known': known` (also update the doc comment at :6, it quotes the selection). Hand-written maps only in `quest_enemy_test.dart`: helper `_entry` :4-13, literal :22-34, the malformed list :47-56 (intentionally invalid — add «missing `known`» and «`known: 'yes'`» cases), lenient list :93-97. The fixture default and the model change go in the SAME commit (analyzer/test gate).
- Ambush carousel (Phase 16) is NOT on this branch: `grep -rln "AmbushReport\|ambushDefeat\|QuestResultKind" lib test tool` → 0 files; `git grep -c AmbushReport develop -- lib test` → 0. Do not plan for it (it inherits `known` when the two branches meet, C8).

### F6. Result lines [VERIFIED: codebase + probes P1–P4]
- Sheet: `_content` order `quest_result_sheet.dart:150-169` (… `_line(_spellLearnedText(), spellLearnedKey)` :166, `_line(_rescuedText(), rescuedKey)` :167); `_line` :373-381 (`Padding(top: spacingSm) → Text(text, key:, style: bodyMedium)`); `_spellLearnedText` :446-450 «Magia appresa: ${spell.name}»; keys :35-55 `ValueKey('questResult.<name>')`. Insert `..._loreUnlockedLines()` between :166 and :167: one `_line('${prefix}${lore.name}', QuestResultSheet.loreUnlockedKeyOf(lore.id))` per entry, `prefix = lore.type?.isBestiary == true ? 'Nuova pagina del Bestiario: ' : 'Conoscenza appresa: '`; expose `static const String bestiaryPagePrefix` / `knowledgePrefix` and `static Key loreUnlockedKeyOf(String id) => ValueKey('questResult.loreUnlocked.$id')` for the tests.
- Model `quest_result.dart:14-225`: add `this.loreUnlocked = const []` (optional named, no test constructs `QuestResult(` directly — grep), field next to `spellLearned` :70, parse next to :118 with a lenient reader (`json is! List → const []`; each `Map<String,dynamic>` through `Lore.fromJson` in try/catch; drop entries without a non-empty `name`), `toJson` next to :185-187 writing `{'id', 'name', 'type': type?.name}` (wire name only after the rename below), `props` next to :218.
- `Lore.fromJson` (`lore.dart:21-30`) with `{id, name, type}`: OK — `description`/`image` `null`, `relatedLore` `[]` (P2). Unknown type → `ArgumentError` from `byName` (P4); missing id → `TypeError` (P4) → both dropped by the lenient reader. Lore types FE vs BE: the 12 values match one to one (`lore_type.dart:1-14` vs BE `src/models/enums/lore-type.enum.ts`), `Lore.type` is `String!` on the wire (BE `origin/develop` `type Lore`).
- **Rename `LoreTypeExtension.name` → `label`** (P1 `LoreType.enemy.name == 'Mostri'`, P3 `Lore.toJson` writes `'Mostri'` and `fromJson(toJson())` throws `ArgumentError`). Callers of the Italian text: only `library_data_page.dart:68` (section titles) → `.label`; `Lore.toJson` (:34) then writes the wire name with no edit. The analyzer will NOT flag the old call site (`.name` still compiles to `Enum.name`): the Library page test must pin the section titles («Mostri», «Animali», «Piante», «Città», «Regioni», «Stati»…) (Pitfall 1). Add `bool get isBestiary` (enemy/animal/plant) on `LoreType`, tested.
- Fragment: add `loreUnlocked { id name type }` right after `spellLearned { id name }` (`quest_result_fragment.dart:82-85`): keeps the pinned adjacency «… } } stagesCleared stagesTotal» (`quest_result_documents_test.dart:56-57`) and «resolvedAt acknowledgedAt» (:91-94); update the doc comment :5-10 («Mai … campi di lore sotto un nemico» stays true — `loreUnlocked` is top level). `\benemy \{` count unaffected.
- Fixtures (`test/helpers/fixtures/quest_result_fixtures.dart:51-120`): add `List<Object?> loreUnlocked = const []` → `'loreUnlocked': loreUnlocked`, plus `loreRefJson({id, name, type})`; round-trip map (`quest_result_test.dart:371-390`) gains a `'lore unlocked'` payload with one Bestiario and one knowledge entry.

### F7. Unknown city on the Map [VERIFIED: codebase + probe P5]
- Tap path: `CityMarkersLayer(onCityTap: _openCityLore)` `world_map.dart:270-274` (null in teleport mode: `world_map_teleport_test.dart:201-210`); `_openCityLore` :441-442 → `WorldMapCubit.loadLoreData(city.relatedLore!.id)` (crash on null); listener :182-188 `WorldMapLoadData → setState(_selectedLore) → _showCityInfoModal()`; `_showCityInfoModal` :635-647 → `showModalBottomSheet(… PaperSheetModal(child: CityModal(lore: _selectedLore!)))`. `CityModal` (`city_modal.dart:8-49`, format-dirty) shows image (if any), `lore.name` (from `lore(id)`, the cities query does not select it), description.
- `City.fromJson` (`city.dart:32-56`) survives `relatedLore: null` (P5: name kept, `relatedLore == null`); `CityQueries.getAllCities` (`city_queries.dart:4-23`) unchanged (`relatedLore { id description image }`, pinned by `travel_documents_test.dart:173`).
- Smallest change: `_openCityLore(City city) { final lore = city.relatedLore; if (lore == null) return _showUnknownCityModal(city.name ?? ''); context.read<WorldMapCubit>().loadLoreData(lore.id); }` with `_showUnknownCityModal` reusing the same `showModalBottomSheet` + `PaperSheetModal`, child `UnknownCityModal(name)` (or a `CityModal.unknown` variant) with `static const String line = 'Non conosci ancora questa città.'`. No cubit change needed (it is a null check of received data, rule 4 intact); Boy Scout `print` → `debugPrint` in `world_map_cubit.dart:24`.
- Other reader of `City.relatedLore`: `travel_confirmation_sheet.dart:89` (`destination.relatedLore?.image`) — already null-safe; an unknown destination now shows the sheet without the city image (`travel_confirmation_sheet_test.dart:385` «omits the image when the lore has none» covers it). Note for the UAT/BACKEND-NOTES.
- Tests: `world_map_teleport_test.dart:132-142` («outside teleport mode a city opens its lore», uses `cityB` with `lore-city-2`) stays; add «a city without lore opens the name-only modal and never calls loadLoreData (D-11)» in the same group (harness `pumpWorldMap` from `world_map_travel_test.dart:105`, `setUpWorldMapHarness`), plus a widget test for the modal.
- **Staleness (C1):** `cities` come from `MainScreenCubit.loadData` (`main_screen_cubit.dart:16-24`), called once on the first `CharacterLoaded` (`main_screen.dart:100-107`); `loadData` emits `MainScreenLoading`, which renders `_ColdStart` (`main_screen.dart:157`) → it must not be reused mid-session (rule 2).

### F8. Gate and UAT shapes [VERIFIED: 16-07/16-08 on `feat/16-travel-ambushes`, 15-08/15-09/15-HUMAN-UAT on `develop`]
- Gate plan (pattern 16-07 `<interfaces>`): `SCRATCH` outside the repo; `git -C $BE show origin/develop:src/schema.gql > "$SCRATCH/schema.gql"` (no fetch: the orchestrator aligns the ref over HTTPS); **gate `grep -c "loreUnlocked" "$SCRATCH/schema.gql"` ≥ 1, else STOP + STATE park note**; prove with `awk '/^type CharacterStatus /,/^}/'` (`unlockedLore: [ID!]!`), `awk '/^type QuestEnemy /,/^}/'` (`known: Boolean!`; today only `enemy`, `quantity`), `awk '/^type QuestResult /,/^}/'` (`loreUnlocked: [Lore!]!`), `awk '/^type City /,/^}/'` (`relatedLore: Lore` still nullable), `awk '/^type Lore /,/^}/'` (`type: String!` unchanged; today `description id image name relatedLore type`); `dart run tool/schema_check/dump_documents.dart "$SCRATCH/docs"` → «dumped 45 documents»; `NODE_PATH=$BE/node_modules node tool/schema_check/validate_documents.js "$SCRATCH/schema.gql" "$SCRATCH/docs" | grep -vc OK` → 0; full suite foreground; analyzer error/warning grep; `dart format --output=none --set-exit-if-changed` per new Dart file; trailer grep `co-authored-by|generated with|claude-session` over `develop..HEAD` = 0; VALIDATION rows green, `wave_0_complete: true`. Registry stays at 45 (`test/tool/schema_check_documents_test.dart:32-34`, `shop_documents_test.dart:128`, `travel_documents_test.dart:178-179`).
- BE today: `origin/develop` = `9103440` (BE Phase 15 merged), `grep -c "loreUnlocked\|unlockedLore"` = 0; BE tree on `feat/16-lore-sbloccabili` at `eb7c967` (docs only, no `BACKEND-NOTES.md` yet).
- UAT plan (pattern 16-08 / 15-09): `autonomous: false`, `user_setup` with the BE runbook, re-check the gate, write `17-HUMAN-UAT.md` (frontmatter `status/phase/device/be_ref/date/verdict`; sections Setup, Session data, Session notes, Steps table «Step | Requirements | Decisions | Expected | Result | Note»), blocking human checkpoint, results only from the user's words, `requirements mark-complete` per passed id, ROADMAP/STATE/REQUIREMENTS closed, FE `BACKEND-NOTES.md` (sections `## 1. Contract consumed by the FE`, `## 2. Error codes read`, `## 3. FE behaviour the BE should know`, `## 4. E2E outcome`, `## 5. Questions for the BE` — `15-travel-food/BACKEND-NOTES.md`), secrets grep `mongodb(\+srv)?://|token=|password` = 0.
- Phase 17 specifics: **identity** — the dev bypass is the innkeeper: `known` is `true` for every enemy and `lores`/`City.relatedLore` are unfiltered for it, so every LORE step needs the player identity (second identity via env on the BE process, as on 2026-11-01; the variable names come from the BE `BACKEND-NOTES.md`, OQ6); the Phase 16 E2E (16-08) can run with the innkeeper. **APKs** — the 17 APK selects `unlockedLore`/`known`/`loreUnlocked` (fails on a BE without 16, D-14); the 16 APK does not select them and works against a BE with 16 (additive). On the 17 APK an ambush report (BE 15) has `quest: null` and is dropped by `QuestResult.tryFromJson` (it stays unacknowledged on the BE) — run 16-08 from the 16 APK as planned. Proposed steps: (1) new character → Luoghi shows its city, its regions, its state only; the other three books show the status line; no «Nuovo» on this first opening; (2) travel to a new city with Luoghi open → its page appears without spinner, marked «Nuovo»; close/reopen → mark gone; (3) Map: tap a never-visited city → name + «Non conosci ancora questa città.»; tap the city just visited → its lore (needs C1); (4) quest with an unknown enemy → silhouette on the quest sheet; (5) win → result sheet portrait clear + «Nuova pagina del Bestiario: …», Bestiario shows the page with «Nuovo»; (6) study won → «Conoscenza appresa: …» (BE `LORE_STUDY_CHANCE=1` on the BE process makes it deterministic, BE CONTEXT §specifics); (7) delete and recreate → Library back to the birth geography, no marks; (8) optional: a defeat keeps the silhouette.

### F9. Conventions and runtime [VERIFIED]
- Analyzer baseline: `50 issues found.` (all info) this session. Test suite at 15-08: `01:16 +3310: All tests passed!` (`15-travel-food/15-08-SUMMARY.md:108`); full suite foreground, Bash timeout ≥ 300 000 ms.
- Format check (`dart format --output=none --set-exit-if-changed`, read-only) on the 52 lib/test files (34 lib, 18 test) this phase may touch: **dirty** = `lib/shared/components/dropdown.dart`, `lib/screens/mainScreen/tabs/library/components/lore_card.dart`, `lib/screens/mainScreen/tabs/library/components/book_type.dart`, `lib/screens/mainScreen/tabs/map/components/city_modal.dart`, `lib/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart`, `lib/shared/components/cached_svg.dart`; **clean** = everything else checked, including `library_data_page.dart`, `library.dart`, `library_cubit.dart`, `library_state.dart`, `library_initial_page.dart`, `world_map.dart`, `enemy_portrait.dart`, both sheets, all fragments/models listed in F1–F6, `authenticated_shell.dart`, `main.dart`, `main_screen*.dart`, and the test files. Formatting a dirty touched file reflows untouched members (REPO-RULES accept it, note in SUMMARY); avoid touching `dropdown.dart` and `cached_svg.dart` at all.
- Harness: `test/helpers/test_app.dart` (`buildTestApp`, disables runtime font fetching), `landscape.dart` (`useLandscapePhone`, 780×360 logical), `svg_cache_seed.dart` (`seedSvgCache`), `fakes/svg_http_overrides.dart` (`useSvgHttpOverrides`, network SVGs only), `mocks.dart` (`MockKlimmeckGraphQl` :82, `MockCharacterCubit` :122, `MockMainScreenCubit` :127, `MockWorldMapCubit` :165), `fakes/fake_shared_preferences_async.dart`, `map_harness.dart`, `fixtures/quest_fixtures.dart`, `fixtures/quest_result_fixtures.dart`, `fixtures/travel_fixtures.dart` (`travelCityJson` with `relatedLore` :92-108). Test titles end with `(D-NN)`.

### F10. Pinned tests to update RED first [VERIFIED: codebase]
| File:line | Pin | Change |
|-----------|-----|--------|
| `test/graphql/board_documents_test.dart:51-55` | `contains('enemies { quantity enemy { id name imagePath xp } }')` | → `'enemies { quantity known enemy { id name imagePath xp } }'` (title gains `D-03)`) |
| `test/graphql/quest_result_documents_test.dart:50-66` | `'enemies { quantity enemy { id name imagePath xp } } stagesCleared stagesTotal'` | → `… quantity known enemy …`; new test «selects the lore unlocked by the outcome (D-04)» `contains('spellLearned { id name } loreUnlocked { id name type }')` |
| `test/graphql/character_fragment_test.dart` (new case beside :54-68) | — | «statusFields selects unlockedLore (D-01)» |
| `test/helpers/fixtures/quest_fixtures.dart:6-16` | `questEnemyJson` shape + doc comment | `bool known = true` → `'known': known` (same commit as the model) |
| `test/models/quest/quest_enemy_test.dart:4-13, :22-34, :47-56, :65-71, :93-97` | helper/literals without `known`; strict error list; round trip | add `known`; new strict cases (missing / non-bool → `FormatException`, D-03); round trip includes `known` |
| `test/models/quest/quest_sheet_details_test.dart:246-250` | `strongestEnemy?.name` | unchanged; add `isStrongestEnemyKnown` cases (D-08) |
| `test/models/quest_result/quest_result_test.dart:308-321, :370-398` | lenient enemies; round trip over fixtures | unchanged via the fixture default; add `loreUnlocked` group (lenient, BE order, `[]` when absent) and a round-trip payload |
| `test/models/character/character_status_test.dart:12-23` | `statusJson` | add `unlockedLore` param; new group (D-01) |
| `test/models/lore_test.dart:6-33` | fields / no `unlocked` | add «round trips its type (wire name)»; (OQ4) unknown type |
| `test/shared/components/enemy_portrait_test.dart:112-123` | `semanticLabel == 'Ritratto del nemico'` | unchanged for `known: true`; add silhouette + label cases (D-08) |
| `test/shared/components/popup/quest_info_sheet_test.dart:147-159`, `quest_result_sheet_test.dart:185-201` | portrait = `CachedSvg` under the key | unchanged; add «an unknown strongest enemy is a silhouette (D-08)» and on the result sheet «a victory shows the defeated enemy in clear (D-09)» |
| `test/shared/components/popup/quest_result_sheet_test.dart:76-126, :511-524` | success content, «Magia appresa: Scudo» | add lines after «Magia appresa» in BE order, labels by type, none when empty (D-10) |
| `test/screens/mainScreen/tabs/map/world_map_teleport_test.dart:132-142, :201-210` | known city → `loadLoreData('lore-city-2')`; teleport → no tap | unchanged; add the unknown-city case (D-11) |
| `test/screens/auth/authenticated_shell_test.dart:142-151` | shell constructor | pass the bookmarks store (if required param) |
| `test/graphql/lore_documents_test.dart:28-31` | lore queries «without unlocked» | unchanged — never add `unlocked*` to `LoreQueries` |
| `test/tool/schema_check_documents_test.dart:32-34`, `shop_documents_test.dart:128`, `travel_documents_test.dart:178-179` | 45 documents | unchanged (proves no new document) |

### Anti-Patterns to Avoid
- `LibraryCubit` listening to `CharacterCubit.stream` (C3) — use a `BlocListener` and a cubit method.
- Emitting `LibraryLoading` (or `LibraryError`) from the live refresh — rule 2; the page keeps rendering.
- Comparing `unlockedLore` by length or list equality — order is not significant (REPO-RULES); compare sets.
- Computing «known», «new city» or «unlocked» on the client from `outcome`, `location` or `relatedLore` (rule 4).
- Reusing `MainScreenCubit.loadData()` to refresh cities mid-session (it renders `_ColdStart`).
- Pixel-reading tests with `runAsync` (google_fonts failures, P7).
- Adding `unlocked` anywhere in `LoreQueries` (pinned absence).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Silhouette | per-format recolouring, `flutter_svg` colour hacks inside `CachedSvg` | one `ColorFiltered(srcIn)` wrapper | works for SVG and raster (P7–P9), no change to format-dirty `cached_svg.dart` |
| Set comparison | sorting + joining strings | `setEquals` / `SetEquality` | order irrelevant, duplicates impossible |
| Device persistence | JSON blobs, `SharedPreferences` legacy API | `SharedPreferencesAsync.setStringList` behind an abstract store | project pattern (Phase 5), testable with the fake |
| Refetch throttling | `Timer` debounce | single-flight + one trailing re-run | deterministic in `bloc_test`, no `fakeAsync` |
| Unknown-enemy knowledge | client cache of defeated enemies | `QuestEnemy.known` from the BE | D-03/D-09, rule 4 |

## Runtime State Inventory
Not a rename/migration phase in the BE sense, but the phase adds device state:
| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data (device) | NEW `shared_preferences` keys `klimmeck.library.<characterId>.<book>` (string lists), absent until a book is opened | none (no migration; old characters' keys are never read again) |
| Stored data (BE) | `status.unlockedLore` / `knownEnemies` backfilled by the BE one-off (BE D-11) | BE side only; the FE UAT character must be created AFTER the BE boot or be backfilled |
| Live service config | None — verified (no FCM topic, no new push category) | — |
| OS-registered state | None — verified | — |
| Secrets/env vars | None in the FE; the UAT player identity lives in env vars of the BE process (BE handoff) | orchestrator only, never printed |
| Build artifacts | Debug APKs of two branches (16 and 17) for the same UAT session | install the right APK per step block (F8) |

## Conflicts

- **C1 (D-11 «known cities behave as today» vs the one-shot `cities` list).** `MainScreenCubit.loadData` runs once per shell (`main_screen.dart:100-107`) and its `MainScreenLoading` renders `_ColdStart` (:157); `City.relatedLore` is resolved per read by the BE → a city visited during the session keeps `relatedLore == null` in the cached list and the Map says «Non conosci ancora questa città.» until a cold restart (and the travel sheet shows no image for it). **Recommendation:** amend D-11 with a silent `MainScreenCubit.refreshCities()` (no `MainScreenLoading`; on failure keep the list; emits `MainScreenLoadData(newCities)` only when the list differs) triggered by a `BlocListener<CharacterCubit>` in `MainScreen` when the `unlockedLore` set changes (same comparison as the Library, cheap: 167 cities). Alternative: on a tap of a null-lore city, re-read `cities` (or extend `GetCity` with `relatedLore { id }`) before choosing the modal — an extra round trip on every unknown-city tap. Without either, step (3b) of the UAT fails by design.
- **C2 (REPO-RULES §Format/tests «`shared_preferences` in tests through `SharedPreferences.setMockInitialValues`», repeated in the `17-VALIDATION.md` draft) vs the store pattern.** The project stores use `SharedPreferencesAsync` with an injected factory; `setMockInitialValues` does not reach it (P6 `StateError`). **Recommendation:** amend the REPO-RULES line to «stores take a `SharedPreferencesAsync Function()` and are tested with `FakeSharedPreferencesAsync` (extended with `getStringList`/`setStringList`); cubit/widget tests use `InMemoryLibraryBookmarksStore`».
- **C3 (D-12 «`LibraryCubit` subscribes to the `CharacterCubit` stream (or receives the ids from the shell)» vs `docs/rules/state-management.md` «Cubit che chiama altri Cubit direttamente»).** No precedent in `lib/` (F1). **Recommendation:** take the second branch of D-12: `BlocListener<CharacterCubit>` in `Library` → `LibraryCubit.syncUnlockedLore(ids)`; the set comparison stays in the cubit.
- **C4 (D-07 «baseline = the set of ids shown at the previous opening» vs «entries arriving live while the book is open are marked too … until the book is reopened»).** With the baseline written only at opening, an entry that arrives live during session N is marked live AND again at opening N+1 (it was not shown at opening N). **Recommendation:** write the baseline after every successful load (opening and live refresh) and keep the session's mark reference (`baseline ?? first shown set`) in memory → live arrivals marked during the session, every mark gone at the next opening; still no write at close. Literal alternative: write only at opening (marks repeat once).
- **C5 (D-12 «`QuestResult.loreUnlocked` (`List<LoreRef>`)» vs REPO-RULES «`List<Lore>` reusing `lib/models/lore.dart`»).** REPO-RULES is later and wins, but reuse requires the `LoreType.name` → `label` rename (P1/P3) — otherwise `QuestResult.toJson` round trips throw. **Recommendation:** plan the rename as the first model task (Boy Scout, own test: «Lore round trips its wire type»; Library section titles pinned).
- **C6 (research flag F2 «widget tests with `useSvgHttpOverrides()` for the book SVGs»).** Books, bookmarks and the dropdown arrow are `CachedSvg` (SvgCache), not `SvgPicture.network`. **Recommendation:** `seedSvgCache([...])` with the 9 ids of F2; `useSvgHttpOverrides()` only if a widget under test uses `SvgPicture.network`.
- **C7 (REPO-RULES §Format «known dirty … the Library files `library_data_page.dart`, `lore_card.dart`, `city_modal.dart`»).** Measured: `library_data_page.dart` is format-clean; the dirty set is `dropdown.dart`, `lore_card.dart`, `book_type.dart`, `city_modal.dart`, `world_map_cubit.dart`, `cached_svg.dart` (F9). Line fix only.
- **C8 (parallel branch, not a CONTEXT decision).** `feat/16-travel-ambushes` (parked) changes `quest_result.dart`, `quest_result_fragment.dart`, `quest_result_sheet.dart`, `quest_result_fixtures.dart`, `quest_result_test.dart`, `quest_result_documents_test.dart`, `quest_result_sheet_test.dart` (diff vs merge-base `f560d1d`). Phase 17 touches the same files → the second PR to merge needs a rebase there plus STATE/ROADMAP. **Recommendation:** keep Phase 17 edits additive and local (new field after `spellLearned`, lines after «Magia appresa», `known` inside `enemies`), say it in the SUMMARYs, and decide the merge order with the user (OQ5).

## Common Pitfalls

### Pitfall 1: The `label` rename is silent at the old call site
**What goes wrong:** after renaming `LoreTypeExtension.name` → `label`, `library_data_page.dart:68` still compiles (`Enum.name`) and shows «enemy», «city» as section titles.
**How to avoid:** the rename task greps `\.name\b` on `LoreType` values and moves the call site; a Library page test pins the Italian titles.

### Pitfall 2: A refetch in flight re-opens a closed book
**What goes wrong:** the player taps the bookmark (`goToInitial`) or leaves the tab (re-mount → `goToInitial`) while a silent refetch runs; its completion emits `LibraryLoadData` and the book reappears.
**How to avoid:** generation counter / same-book check after the await; bloc_test «a refetch completing after goToInitial is dropped (D-05)» with a held `Completer`.

### Pitfall 3: Dropdown state jumps when a hidden section appears
**What goes wrong:** sections built positionally; a live entry in a previously hidden first type inserts a `Dropdown` at index 0 and the open/closed states shift to the wrong sections.
**How to avoid:** `key: ValueKey(type)` on every `Dropdown`; widget test with a section opened, then a live arrival in an earlier type.

### Pitfall 4: `known` missing from `QuestEnemy.toJson`
**What goes wrong:** the result round trip (`quest_result_test.dart:370-398`) re-parses through `lenientListFrom`, drops every entry and the equality fails; the strict board parser would throw.
**How to avoid:** `toJson` writes `known`; round-trip test in `quest_enemy_test.dart`.

### Pitfall 5: Fixture default and model change in different commits
**What goes wrong:** making `known` required before `questEnemyJson` writes it turns every test that parses an enemy fixture red (18 `questEnemyJson` call sites in 5 files, plus the widget tests built on them) (board quests dropped, result enemies empty).
**How to avoid:** one GREEN commit with the model, the fragment, the fixture default `known: true` and the two document tests (REPO-RULES «same commit»).

### Pitfall 6: `copyWith` drops `unlockedLore`
**What goes wrong:** `CharacterStatus.copyWith` rebuilds the status from scratch (`character_status.dart:99-126`); a new field not carried becomes `const []` after any copy and the Library sees «everything removed».
**How to avoid:** carry it like `spellStates`/`awaitingAid`; test «copyWith keeps the current unlockedLore».

### Pitfall 7: Loading state on the live path
**What goes wrong:** reusing `openBook`/`loadLoreData` for the refresh emits `LibraryLoading` → the page flashes a `Placeholder` (`library.dart:47`) mid-session (rule 2).
**How to avoid:** two paths; bloc_test `expect: () => [isA<LibraryLoadData>()]` only, for the refresh.

### Pitfall 8: The innkeeper hides the feature in the UAT
**What goes wrong:** with the dev bypass every enemy is `known: true`, every lore and city visible — the UAT «passes» without exercising anything.
**How to avoid:** player identity for all LORE steps (F8); write it in `17-HUMAN-UAT.md` Setup.

### Pitfall 9: Old BE
**What goes wrong:** once the fragments select `unlockedLore`/`known`/`loreUnlocked`, `GetCharacter`, `characterUpdated`, quests and results fail validation on a BE without Phase 16 (the app is dead).
**How to avoid:** D-14; never run the branch against an old BE; note it in the SUMMARY of the fragment plans and in BACKEND-NOTES.

### Pitfall 10: Greps and tall-style formatting
Acceptance greps anchored to one identifier; the multi-line `Dropdown`/`ColorFiltered` constructors and the `_line` spread reflow under `dart format`.

## Code Examples

### Tolerant id list (pattern of `_spellStatesFrom`, `character_status.dart:76-81`)
```dart
static List<String> _unlockedLoreFrom(Object? json) {
  if (json is! List) return const [];
  return List.unmodifiable(json.whereType<String>());
}
```

### Strict `known` (pattern of `QuestEnemy.fromJson`, `quest_enemy.dart:14-32`)
```dart
final known = json['known'];
if (known is! bool) throw const FormatException('QuestEnemy.known missing');
```

### Silhouette
```dart
Widget _inked(Widget picture) => known
    ? picture
    : ColorFiltered(
        colorFilter: const ColorFilter.mode(
          KlimmeckGuideTheme.deepNight,
          BlendMode.srcIn,
        ),
        child: picture,
      );
```

### Silent refresh skeleton
```dart
Future<void> syncUnlockedLore(Iterable<String> ids) async {
  final next = ids.toSet();
  final previous = _lastUnlocked;
  _lastUnlocked = next;
  if (previous == null || setEquals(previous, next)) return;
  final shown = state;
  if (shown is! LibraryLoadData) return;
  await _refetch(shown.book); // never emits LibraryLoading; drops stale completions
}
```

## State of the Art
| Old | New | Impact |
|-----|-----|--------|
| `lores` returns everything (BE Phase 11 D-25) | filtered per character (BE 16 D-10) | Library shows only known entries; empty books |
| `QuestEnemy { enemy, quantity }` | `+ known` | strict board parse, silhouettes |
| `City.relatedLore` always set (167/167) | null until known | Map name-only modal; travel sheet without image |
| `LoreType.name` = Italian label (shadowing) | `label` + wire `name` | `Lore.toJson` round trips |

## Assumptions Log
| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `characterUpdated` re-emits once per BE write (BE CONTEXT «`CharacterUpdatesPublisher` riemette»), so no debounce is needed [CITED: BE 16-CONTEXT §code_context] | F2 | a burst would cause ≤ 2 refetches (single-flight + trailing) — harmless |
| A2 | The BE resolves `known: true` for the enemies of a victory in the same transaction as the `QuestResult` (BE D-07) [CITED: BE 16-CONTEXT D-07] | F4, D-09 | result sheet of a victory would show a silhouette; FE must not compensate (rule 4) |
| A3 | `loreUnlocked` arrives in a stable BE order (BE discretion «ordine delle `loreUnlocked`») [ASSUMED] | F6 | lines in a different order per read — cosmetic |
| A4 | A player identity can be switched on the BE process via env as on 2026-11-01 [ASSUMED: user memory; names in the future BE handoff] | F8 | UAT blocked until the BE handoff says how |
| A5 | `ColorFiltered` in release on device renders like the test engine (probes ran on the test renderer) [ASSUMED] | F4 | visual check on the device covers it (UAT step 4) |

## Open Questions (RESOLVED — orchestrator, 2026-11-07; the CONTEXT D-07/D-11/D-12 revisions and D-15..D-19 carry the rulings)
1. **C1 — cities refresh.** _(RESOLVED — silent `MainScreenCubit.refreshCities()` on the `unlockedLore` set change, CONTEXT D-11 revised)_ Silent `refreshCities()` on the `unlockedLore` change (recommended) or a re-read on tap? Needed before planning the Map plan.
2. **C4 — baseline write on live refresh.** _(RESOLVED — baseline written after every successful load, marks against the in-memory session reference, CONTEXT D-07 revised)_ Rewrite at every successful load (recommended) or only at opening?
3. **Silhouette semantics copy.** _(RESOLVED — «Sagoma del nemico» approved, CONTEXT D-17, REPO-RULES copy list)_ «Sagoma del nemico» for `known: false` is a new string outside the REPO-RULES copy list — orchestrator's go.
4. **`Lore.fromJson` type tolerance.** _(RESOLVED — tolerant: unknown → `null`, the entry survives, CONTEXT D-16)_ Read `type` with `asNameMap()` (unknown → `null`, the lore survives: no whole-Library error for one unknown type; a `loreUnlocked` entry with an unknown type reads «Conoscenza appresa») or keep `byName` (strict)?
5. **Merge order of the FE 16 and FE 17 PRs** _(RESOLVED — FE 16 first, then `feat/17` rebases on `develop`; additive edits on the shared result files, CONTEXT D-18)_ (both touch the result files, C8).
6. **UAT player identity** _(RESOLVED — read from the BE Phase 16 `BACKEND-NOTES.md` by the gated UAT plan; the orchestrator provides it at the checkpoint)_: env variable names and seed tricks (`unlockedLore` emptied, study roll forced, character moved) come from the BE Phase 16 `BACKEND-NOTES.md`, not written yet.
7. **«Nuovo» ribbon colour per book** _(RESOLVED — the book's bookmark colour, Claude's discretion, device-reviewed)_ (F3 suggestion) — device-reviewed, discretion.

## Environment Availability
| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK / `flutter test` / `flutter analyze` | all plans | ✓ | Flutter 3.35.5; analyzer ran (50 info) | — |
| BE `origin/develop` with Phase 16 (`loreUnlocked`) | gate + UAT plans | ✗ (count 0 at `9103440`) | — | park the gated plans (D-13) |
| BE `node_modules` for `validate_documents.js` | gate plan | ✓ (used at 15-08 / 16-07) | — | — |
| Android device + local BE + player identity | UAT plan | human checkpoint | — | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (Flutter 3.35.5) + `bloc_test ^10.0.0` + `mocktail ^1.0.5` + `fake_async ^1.3.3` (`pubspec.yaml:60-66`) |
| Config file | none beyond `pubspec.yaml` / `analysis_options.yaml`; helpers in `test/helpers/` |
| Quick run command | `flutter test <touched test files>` (e.g. `flutter test test/models/quest test/graphql/board_documents_test.dart test/graphql/quest_result_documents_test.dart`) |
| Full suite command | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (foreground, ~76 s, 3310+ tests) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LORE-01 | `unlockedLore` parsed, `[]` when absent, copyWith/props/toJson | unit | `flutter test test/models/character/character_status_test.dart` | ✅ (add group) |
| LORE-01 | `statusFields` selects `unlockedLore` | unit | `flutter test test/graphql/character_fragment_test.dart` | ✅ |
| LORE-01 | `LoreType.label`, wire `name`, `isBestiary`; `Lore` round trip | unit | `flutter test test/models/enums/lore_type_test.dart test/models/lore_test.dart` | ❌ Wave 0 (`lore_type_test.dart`) / ✅ |
| LORE-01 | `LibraryBook` types/titles/storage keys | unit | `flutter test test/models/enums/library_book_test.dart` | ❌ Wave 0 |
| LORE-01 | store keys, read/write string lists, failures → null / swallowed | unit | `flutter test test/repository/storage/library_bookmarks_store_test.dart` | ❌ Wave 0 |
| LORE-01 | openBook marks vs baseline, first opening no marks, baseline written after marks, silent refresh on set change only, no Loading, failure keeps state, stale completion dropped, single-flight | cubit | `flutter test test/screens/mainScreen/tabs/library/cubit/library_cubit_test.dart` | ❌ Wave 0 |
| LORE-01 | sections hidden, status line, «Nuovo», Italian titles, live recompute keeps open sections | widget | `flutter test test/screens/mainScreen/tabs/library/library_data_page_test.dart` | ❌ Wave 0 |
| LORE-01 | `Library` forwards ids from `CharacterCubit`, refresh without spinner | widget | `flutter test test/screens/mainScreen/tabs/library/library_test.dart` | ❌ Wave 0 |
| LORE-02 | `known` strict/lenient, toJson, `strongestEntryOf`, `isStrongestEnemyKnown` | unit | `flutter test test/models/quest` | ✅ (add cases) |
| LORE-02 | fragments select `known`, `loreUnlocked { id name type }`; registry 45 | unit | `flutter test test/graphql test/tool/schema_check_documents_test.dart` | ✅ |
| LORE-02 | `loreUnlocked` lenient parse, BE order, round trip | unit | `flutter test test/models/quest_result/quest_result_test.dart` | ✅ (add group) |
| LORE-02 | silhouette (ColorFiltered srcIn, ink, label) SVG + raster | widget | `flutter test test/shared/components/enemy_portrait_test.dart` | ✅ (add cases) |
| LORE-02 | quest sheet silhouette of the strongest; result sheet clear after victory; lore lines | widget | `flutter test test/shared/components/popup/quest_info_sheet_test.dart test/shared/components/popup/quest_result_sheet_test.dart` | ✅ (add cases) |
| LORE-03 | unknown city → name-only modal, no `loadLoreData`; known city unchanged; teleport unchanged | widget | `flutter test test/screens/mainScreen/tabs/map/world_map_teleport_test.dart` (+ `components/unknown_city_modal_test.dart`) | ✅ / ❌ Wave 0 |
| LORE-03 | (C1) silent cities refresh on set change, no `MainScreenLoading` | cubit + widget | `flutter test test/screens/mainScreen/cubit/main_screen_cubit_test.dart test/screens/mainScreen/main_screen_test.dart` | ❌ Wave 0 / ✅ |
| all | merged-schema validation 45 × OK | gate | `dart run tool/schema_check/dump_documents.dart` + `validate_documents.js` | ✅ (gate plan) |
| all | device E2E with a player identity | manual | `17-HUMAN-UAT.md` | ❌ (UAT plan) |

### Sampling Rate
- **Per task commit:** the touched test files + repo-wide `flutter analyze` (0 error / 0 warning) + trailer check.
- **Per plan:** the plan's test directories.
- **Phase gate:** full suite foreground, analyzer, format of new files, trailer grep, schema check 45 × OK.

### Wave 0 Gaps
- [ ] `test/models/enums/lore_type_test.dart`, `test/models/enums/library_book_test.dart`
- [ ] `test/repository/storage/library_bookmarks_store_test.dart` + `getStringList`/`setStringList` in `test/helpers/fakes/fake_shared_preferences_async.dart`
- [ ] `test/helpers/fakes/in_memory_library_bookmarks_store.dart`
- [ ] `test/helpers/fixtures/lore_fixtures.dart` (`loreJson`, `loreRefJson`)
- [ ] `test/screens/mainScreen/tabs/library/cubit/library_cubit_test.dart`, `library_data_page_test.dart`, `library_test.dart`
- [ ] `test/screens/mainScreen/tabs/map/components/unknown_city_modal_test.dart` (or a `city_modal_test.dart`)
- [ ] (C1) `test/screens/mainScreen/cubit/main_screen_cubit_test.dart`
- No framework install needed.

### Manual-only
Device E2E (`17-HUMAN-UAT.md`): live Library refresh on a real arrival, «Nuovo» across reopenings and app restarts, silhouette rendering on the phone, the study roll, delete/recreate reset — BE timing (change stream, filters per identity) cannot be reproduced in widget tests.

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2/V3 Authentication/Session | no (unchanged) | — |
| V4 Access Control | yes (per-character filtering is BE-enforced) | FE never filters or infers; a locked `lore(id)` is `NOT_FOUND` like a missing one (no oracle) |
| V5 Input Validation | yes | strict `known` on the board, lenient `loreUnlocked`/result enemies, tolerant `unlockedLore` (non-strings dropped), `City.relatedLore` null handled |
| V6 Cryptography | no | — |

| Threat | STRIDE | Mitigation |
|--------|--------|-----------|
| Malformed lore/enemy entries crashing a sheet or the board | DoS | per-entry drop; whole quest dropped only on the board (existing rule) |
| Device baseline tampering (rooted device edits the string list) | Tampering | cosmetic only: marks are UI convenience, never sent to the BE (D-07) |
| Leaking knowledge across characters on a shared device | Information disclosure | keys by character id; the BE decides what `lores` returns |
| `NOT_FOUND` on a stale known city | DoS (UX) | C1 refresh; `WorldMapError` stays silent (no modal) |

## Sources

### Primary (HIGH confidence)
- Codebase files cited by path:line (read this session); probes `test/_probe_lore_models_test.dart` (P1–P6, green) and `test/_probe_lore_silhouette_test.dart` (P7–P10; P7 printed its result then errored on google_fonts inside `runAsync`), both deleted.
- `dart format --output=none --set-exit-if-changed` on 52 files (read-only); `flutter analyze` → 50 info.
- BE `origin/develop:src/schema.gql` at `9103440` (`type CharacterStatus`, `City`, `Lore`, `QuestEnemy`; `loreUnlocked`/`unlockedLore` count 0); BE `src/models/enums/lore-type.enum.ts`.
- `shared_preferences-2.5.3/lib/src/shared_preferences_async.dart:86, :122` (pub cache).

### Secondary (MEDIUM confidence)
- BE `.planning/phases/16-lore-sbloccabili/16-CONTEXT.md` D-01..D-12 and `16-REPO-RULES.md` (contract names, not merged).
- `feat/16-travel-ambushes:.planning/phases/16-travel-ambushes/16-RESEARCH.md`, `16-07-PLAN.md`, `16-08-PLAN.md`; `develop:.planning/phases/15-travel-food/15-08-SUMMARY.md`, `15-HUMAN-UAT.md`, `BACKEND-NOTES.md` (gate/UAT/handoff shapes, suite runtime).

## Metadata
**Confidence breakdown:** models/fragments/pinned tests HIGH (code read + probes); Library design MEDIUM-HIGH (no existing tests, shape recommended); BE contract MEDIUM (agreed, unmerged); Map staleness HIGH (code read), its fix pending C1.
**Research date:** 2026-11-07 — **Valid until:** the BE Phase 16 merge (re-check names in the gate plan).

## RESEARCH COMPLETE
