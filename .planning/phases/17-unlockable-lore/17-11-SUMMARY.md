---
phase: 17-unlockable-lore
plan: 11
subsystem: library
tags: [library, slivers, cached-svg, image-warmer, splash, board, performance, tdd]

requires:
  - phase: 17-09
    provides: "gates green on the merged BE Phase 16; device UAT run that surfaced the low-memory kill (CONTEXT D-20..D-22)"
  - phase: 17-07
    provides: "LibraryDataPage(book, lore, newLoreIds, onBack), LoreCard(isNew, newMarkInk), sectionKeyOf"
  - phase: 17-06
    provides: "LibraryCubit / library_test harness (MockKlimmeckGraphQl, InMemoryLibraryBookmarksStore)"
provides:
  - "CachedSvg without any progress indicator: an empty SizedBox of the requested size while the file loads (D-21)"
  - "SvgCacheManager.maxObjects = 2000 used by its Config (D-22)"
  - "DropdownHeader(sectionName, turns, onTap) shared by Dropdown and the Library sections"
  - "LibraryBookFrame(book, onBack, slivers) on one CustomScrollView; LibraryDataPage (StatefulWidget) with open sections per LoreType and SliverList.builder per open section (D-20)"
  - "ImageWarmer(fetch, cache, concurrency = 6).warm(urls): bounded, dedup, cached urls and failures skipped, files recorded in SvgCache (D-22)"
  - "SplashCubit(rest, {graphQl, warmer}): folder preload + lore images warm-up before SplashData; QuestCubit(repository, {cityRetryDelay, warmer}): portrait warm-up never awaited (D-22)"
  - "Board Sheet hit-tests its whole box (HitTestBehavior.opaque)"
affects: [17-10]

tech-stack:
  added: []
  patterns:
    - "lazy sliver page: SliverToBoxAdapter header + SliverList.builder only while the section is open"
    - "ImageWarmer worker pool over a shared iterator (concurrency workers, no Timer)"
    - "RecordingImageWarmer test fake with per-call holds and a failure threshold"

key-files:
  created:
    - lib/repository/cache/image_warmer.dart
    - test/shared/components/cached_svg_test.dart
    - test/repository/cache/image_warmer_test.dart
    - test/helpers/fakes/recording_image_warmer.dart
  modified:
    - lib/shared/components/cached_svg.dart
    - lib/repository/cache/svg_cache_manager.dart
    - lib/screens/mainScreen/tabs/board/components/sheet.dart
    - lib/shared/components/dropdown.dart
    - lib/screens/mainScreen/tabs/library/statesPages/library_book_frame.dart
    - lib/screens/mainScreen/tabs/library/statesPages/library_data_page.dart
    - lib/screens/mainScreen/tabs/library/statesPages/library_error_page.dart
    - lib/screens/splash/cubit/splash_cubit.dart
    - lib/screens/mainScreen/questCubit/quest_cubit.dart
    - lib/main.dart
    - lib/screens/auth/authenticated_shell.dart
    - test/screens/mainScreen/tabs/board/sheet_test.dart
    - test/screens/mainScreen/tabs/board/board_acceptance_test.dart
    - test/screens/mainScreen/tabs/library/library_data_page_test.dart
    - test/screens/mainScreen/tabs/library/library_test.dart
    - test/screens/splash/cubit/splash_cubit_test.dart
    - test/screens/mainScreen/questCubit/quest_cubit_test.dart
    - .planning/phases/17-unlockable-lore/17-VALIDATION.md

key-decisions:
  - "The board paper (Sheet) hit-tests its whole box: with D-21 the empty placeholder no longer hit-tests, and the deferToChild detector was only reachable through the 14 px spinner while the image loaded"
  - "The splash folder preload goes through the same ImageWarmer as the lore images (one download path, bounded, testable); a single failing folder file is skipped instead of turning the preload into SplashError (the shell proceeds on both states)"
  - "The D-22 cache-cap test asserts the static SvgCacheManager.maxObjects: constructing the manager in a plain test raises unhandled path_provider MissingPluginExceptions"
  - "Each open Library section keeps the old Dropdown body indentation through a SliverPadding(left 10, top 10, bottom 10)"

requirements-completed: []

duration: ~30min
completed: 2026-11-08
---

# Phase 17 Plan 11: Lazy Library page, spinner-less CachedSvg, boot image warm-up Summary

**The Library book page is one `CustomScrollView` whose sections are `DropdownHeader` adapters plus, only while open, a `SliverList.builder` of `LoreCard`s (a closed section builds no card, an open one only the cards on screen); `CachedSvg` shows an empty box instead of a spinner; a bounded `ImageWarmer` fills the SVG cache with the viewer's lore images at the cold start and with the board's enemy portraits in the background; the SVG disk cache holds 2000 objects.**

## Performance

- **Duration:** ~30 min (2026-11-08T16:13Z → 16:43Z)
- **Tasks:** 4/4
- **Files:** 4 created, 18 modified (12 lib, 9 test, 1 planning) + this SUMMARY + bookkeeping
- **Commits:** 8 (3 RED, 3 GREEN, 2 docs)

## Accomplishments

### Task 1 — spinner-less `CachedSvg`, cache cap (D-21, D-22)
- `lib/shared/components/cached_svg.dart`: the `_loading` flag and the `CircularProgressIndicator` are gone; `build` returns `SizedBox(width: widget.width, height: widget.height)` while `_file == null` (loading or failed), then `SvgPicture.file`. `_loadSvg` no longer calls `setState` on a failed download (same output).
- `lib/repository/cache/svg_cache_manager.dart`: `static const int maxObjects = 2000` used in `Config(... maxNrOfCacheObjects: maxObjects)` (300 before).
- `lib/screens/mainScreen/tabs/board/components/sheet.dart`: `GestureDetector(behavior: HitTestBehavior.opaque, …)` (deviation 1).

### Task 2 — lazy sliver book page with a shared header (D-20)
- `lib/shared/components/dropdown.dart`: `class DropdownHeader extends StatelessWidget { const DropdownHeader({super.key, required this.sectionName, required this.turns, required this.onTap}); }` — `LayoutBuilder` (content width = 4/5), `SizedBox(height: 42)` row with `InkWell`, `AutoSizeText` (titleMedium), `RotationTransition(turns: AlwaysStoppedAnimation(turns))` around the 40×40 `CachedSvg(CloudinaryAssets.arrowDown)`, bronze top rule. `Dropdown` keeps its API and body; its header is `AnimatedBuilder(animation: _sizeFactor, builder: … DropdownHeader(turns: _sizeFactor.value * 0.5, onTap: _toggle))`.
- `lib/screens/mainScreen/tabs/library/statesPages/library_book_frame.dart`: `const LibraryBookFrame({super.key, required this.book, required this.onBack, required this.slivers})`; `CustomScrollView(physics: AlwaysScrollableScrollPhysics(), slivers: [SliverToBoxAdapter(title with 40 px top / 20 px bottom padding, centred), ...slivers, SliverToBoxAdapter(SizedBox(height: 120))])`; bookmark overlay unchanged.
- `lib/screens/mainScreen/tabs/library/statesPages/library_data_page.dart`: `LibraryDataPage` is a `StatefulWidget` (same constructor; `emptyBookLine`, `emptyBookKey`, `sectionKeyOf` unchanged and public); `_LibraryDataPageState` holds `final Set<LoreType> _open = {}` and `_toggle(type)`; sections = `book.types` with entries (D-06); per section `SliverToBoxAdapter(DropdownHeader(key: sectionKeyOf(type), sectionName: type.label, turns: isOpen ? 0.5 : 0, onTap))` and, only if open, `SliverPadding(left 10, top 10, bottom 10, sliver: SliverList.builder(itemCount, itemBuilder → LoreCard(lore, isNew, newMarkInk)))`; empty book → one adapter with `Text(emptyBookLine, key: emptyBookKey)`. No `Dropdown`, no `shrinkWrap`.
- `lib/screens/mainScreen/tabs/library/statesPages/library_error_page.dart`: `slivers: [SliverToBoxAdapter(child: Text(errorLine, key: errorKey, …))]`.

### Task 3 — image warm-up at the cold start and on the board (D-22)
- `lib/repository/cache/image_warmer.dart`: `class ImageWarmer { ImageWarmer({Future<File> Function(String url)? fetch, SvgCache? cache, this.concurrency = defaultConcurrency}); static const int defaultConcurrency = 6; Future<void> warm(Iterable<String> urls); }` — urls not in `SvgCache` are deduplicated into one iterator drained by `concurrency` async workers; a failed download is `debugPrint('[ImageWarmer] skipped <runtimeType>')`; every fetched file goes into `SvgCache`; default fetch = a lazily created `SvgCacheManager().getSingleFile`. Imports `package:flutter/foundation.dart show debugPrint` only.
- `lib/screens/splash/cubit/splash_cubit.dart`: `SplashCubit(this.rest, {KlimmeckGraphQl? graphQl, ImageWarmer? warmer})`; `getImages(folder)`: `_folderImageUrls(folder)` (today's `CacheExpiry` / `KGStorageManager` / `rest.fetchCloudinarySubfoldersUrls` steps) → empty/null → `SplashError("No images")`; else `await _warmer.warm(imageUrls)`, `await _warmLoreImages()` (`graphQl.getAllLores()` → `warm(lores.map((l) => l.image).whereType<String>())`, own try/catch with a `debugPrint`), `emit(SplashData())`; outer catch → `SplashError`. The public `svgCacheManager` field is gone (no other reader).
- `lib/screens/mainScreen/questCubit/quest_cubit.dart`: `QuestCubit(this.repository, {this.cityRetryDelay = defaultCityRetryDelay, ImageWarmer? warmer})`; private `_emitLoaded(QuestLoaded next)` = `emit(next)` + `unawaited(warmer.warm(_portraitSvgUrlsOf(next.quests)))` used by `loadQuest`, `_refresh` and `_replaceQuest`; `_portraitSvgUrlsOf` = `quests.expand(infos?.enemies).map((e) => enemyPortraitUrl(e.enemy.imagePath)).whereType<String>().where(endsWith('.svg'))`.
- `lib/main.dart`: `SplashCubit(rest, graphQl: graphQl, warmer: ImageWarmer())`. `lib/screens/auth/authenticated_shell.dart`: `QuestCubit(QuestBoardRepository(graphQl: graphQl), warmer: ImageWarmer())` (the cubit is created there, not in `main.dart`).

### Task 4 — full gates
- Full suite `01:15 +3437: All tests passed!` (3420 at 17-09 + 17 new cases). Analyzer `50 issues found.` → `ANALYZE_GATE_OK` (0 error / 0 warning). Format gate on the 21 touched Dart files: no `UNFORMATTED`. Trailers `git log develop..HEAD … | grep -ci` → `0`. Sanity: `CircularProgressIndicator` in `lib/shared/components` + `lib/screens/mainScreen/tabs/library` → nothing; `shrinkWrap` in the Library → nothing; `git diff --stat develop -- lib/screens/mainScreen/tabs/journal lib/screens/mainScreen/tabs/shop pubspec.yaml` → nothing (see the acceptance note for `lib/graphql`).
- `17-VALIDATION.md`: rows `17-11-01..03` added after `17-10-03`, all `✅ green`; gate line appended under the sign-off.

## Task Commits

1. Task 1 RED `c10721c` test(shared): expect no spinner in the cached svg (D-21); GREEN `5d8ffd0` fix(shared): drop the CachedSvg spinner and raise the svg cache cap
2. Task 2 RED `b07de7d` test(library): pin the lazy sliver book page (D-20); GREEN `e3dfd29` feat(library): render the book page as lazy slivers with a shared header
3. Task 3 RED `01f7a96` test(cache): pin the bounded image warm-up at boot and board (D-22) (subject shortened to 67 bytes); GREEN `c299d08` feat(cache): warm the viewer's images at the cold start and on the board
4. Task 4 `docs(phase-17): record the plan 11 gates` (VALIDATION rows); bookkeeping `docs(phase-17): record plan 11 progress` (this SUMMARY, ROADMAP 10/11 + `[x] 17-11-PLAN.md`, STATE `Plan: 10 of 11`)

## RED failures observed

- Task 1 (`cached_svg_test.dart`): «shows an empty box … never a spinner (D-21)» → `Expected: no matching candidates / Actual: Found 1 widget with type "CircularProgressIndicator"`; «keeps 2000 objects … (D-22)» → `Expected: <2000> / Actual: <300>` plus two unhandled `MissingPluginException(No implementation found for method getTemporaryDirectory / getApplicationSupportDirectory on channel plugins.flutter.io/path_provider)` raised by the `SvgCacheManager()` constructor in a plain `test()` (deviation 3). «renders the cached file as a picture (D-21)» green at first run (the seeded path already rendered `SvgPicture`; it pins the non-regression).
- Task 1 board regression (`sheet_test.dart`, observed with the `Sheet` of HEAD and the new `CachedSvg`): «a paper is tappable before its image is cached (D-21)» → `derived an Offset (Offset(80.0, 80.0)) that would not hit test on the specified widget`, `Expected: Quest … / Actual: <null>`.
- Task 2 (`library_data_page_test.dart`): compile failure `'DropdownHeader' isn't a type` / `Undefined name 'DropdownHeader'` (6 errors). `library_test.dart` (7) and `library_error_page_test.dart` (1) green at first run: before D-20 the collapsed `SizeTransition` body kept the cards in the tree, so tapping «Città» first changed nothing; with the sliver page those taps are what makes the cases pass.
- Task 3: compile failures — `Type 'ImageWarmer' not found`, `Error when reading 'lib/repository/cache/image_warmer.dart'`, `No named parameter with the name 'warmer'` (quest, splash), `No named parameter with the name 'graphQl'` (splash).

## Tests

- Task 1: `cached_svg_test.dart` 3/3; `test/shared test/screens/mainScreen/tabs/board test/screens/mainScreen/tabs/library` → `+331` green (after deviations 1–2; before them 17 board cases were red: 16 «would not hit test» on the paper, 1 travel line not rendered).
- Task 2: `test/screens/mainScreen/tabs/library test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/shop test/screens/auth test/screens/mainScreen/main_screen_test.dart` → `+454` green.
- Task 3: `test/repository test/screens/splash test/screens/mainScreen/questCubit test/screens/auth` → `+989` green.
- Task 4: full suite `+3437`.
- Acceptance greps: Task 1 `CircularProgressIndicator` in `cached_svg.dart` 0, `2000` in the manager 1, `D-21)` 2, `D-22)` 1; Task 2 `SliverList` 1, `shrinkWrap` 0, `Dropdown(` 0, `class DropdownHeader` 1, `class Dropdown ` 1, `D-20)` 3, consumers diff empty; Task 3 `class ImageWarmer` 1, `package:flutter/material` in the warmer 0, `warm` in the splash cubit 9, `unawaited` in the quest cubit 2, `D-22)` 4 / 4 / 3; Task 4 `^\| 17-11-0[1-3] .*✅ green` = 3.

## Files formatted

Every touched file by name. `cached_svg.dart` and `dropdown.dart` were format-dirty at baseline: `cached_svg.dart` was rewritten (the one-line `setState(() { … })` bodies and the long `SvgPicture.file(...)` line are gone with the change itself), `dropdown.dart` reflowed its untouched `Dropdown` members (`107 insertions(+), 79 deletions(-)` including the extraction) — accepted per the REPO-RULES. All other touched files were clean after the edits (`0 changed`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Board papers untappable while their image loads**
- **Found during:** Task 1 (16 board tests red: `tap()` on the paper «would not hit test on the specified widget»)
- **Issue:** `Sheet` wraps the paper in a default (`deferToChild`) `GestureDetector`; with the spinner gone the `CachedSvg` placeholder is an empty `SizedBox` that does not hit-test, so a paper is dead until its SVG is on disk (the tests, and a first-boot user, used to hit the 14 px spinner at the centre).
- **Fix:** `GestureDetector(behavior: HitTestBehavior.opaque, …)` in `lib/screens/mainScreen/tabs/board/components/sheet.dart`; regression test «a paper is tappable before its image is cached (D-21)» in `test/screens/mainScreen/tabs/board/sheet_test.dart` (observed red with the old `Sheet`).
- **Files (outside `files_modified`):** `sheet.dart`, `sheet_test.dart`. **Commit:** `5d8ffd0`.

**2. [Rule 3 - Blocking] `board_acceptance_test.dart` counted frames the spinner used to schedule**
- **Found during:** Task 1 («asks the travel preview once the quest becomes acceptable (D-04)» red: travel line not found after two pumps; green on the baseline files)
- **Issue:** `AutomatedTestWidgetsFlutterBinding.pump()` builds a frame only when one is scheduled; the spinner's ticker kept one scheduled at every pump, so `emitCharacter` (stream add + two bare `pump()`s) got three frames' worth of work. Without the ticker the first pump only delivers the stream event.
- **Fix:** `emitCharacter` → `characterStates.add(state); await tester.pumpAndSettle();` (intent unchanged). **Commit:** `5d8ffd0`.

**3. [Rule 3 - Blocking] D-22 cache-cap test on the static constant**
- The plan's first choice `SvgCacheManager().config.maxNrOfCacheObjects` works (the getter is public in `flutter_cache_manager 3.4.1`) but constructing the manager in a plain `test()` surfaces two unhandled path_provider `MissingPluginException`s (its `IOFileSystem`/repository futures). The plan's fallback is used: `static const int maxObjects = 2000` in `SvgCacheManager`, used by its `Config`, asserted by the test. **Commit:** `c10721c` / `5d8ffd0`.

**4. [Rule 3 - Blocking] Splash folder preload routed through the `ImageWarmer`**
- **Found during:** Task 3 (the plan's splash tests must drive `getImages` to `SplashData` with mocks; `svgCacheManager.getSingleFile` on the real manager cannot run under `flutter test`)
- **Fix:** `getImages` keeps today's url steps (`CacheExpiry`, `KGStorageManager`, `rest.fetchCloudinarySubfoldersUrls`) and downloads the folder files with `await _warmer.warm(imageUrls)` instead of `Future.wait(svgCacheManager.getSingleFile)` + `SvgCache().add` — the warmer does exactly that work, bounded; the duplicate loop and the public `svgCacheManager` field (no other reader) are gone.
- **Behaviour delta:** a single failing folder file is skipped and logged instead of turning the whole preload into `SplashError`; `_ShellBodyState` proceeds on `SplashData` and `SplashError` alike, so nothing visible changes. Empty folder → `SplashError("No images")` as today (pinned by «an empty folder still reads as the error state (D-22)»). **Commit:** `c299d08`.

**5. `QuestCubit` is created in `authenticated_shell.dart:150`**, not in `main.dart`: `warmer: ImageWarmer()` is passed there (the plan said «where they are created»; `main.dart` only gained the `SplashCubit` arguments). **Commit:** `c299d08`.

### Test adjustments after RED (noted, intent unchanged)
- «builds only the cards on screen of an open section (D-20)»: `scrollUntilVisible(find.text('Città 60'), 500)` — with 300 px the default 50 iterations (15 000 px) did not reach the 60th card (60 × ~270 px). **Commit:** `e3dfd29`.
- «warms the viewer's lore images before the data state (D-22)»: asserts `cubit.state` (`SplashInitial` while the lore warm-up is held, `SplashData` after) instead of a stream listener, which receives the state one microtask after `emit`. **Commit:** `c299d08`.
- `library_error_page_test.dart` left untouched: it builds `LibraryErrorPage`, not the frame.
- Splash tests call `SharedPreferences.setMockInitialValues({})` for the legacy static `CacheExpiry`/`KGStorageManager` (precedent `test/repository/storage/session_store_test.dart`); the REPO-RULES ban targets the `SharedPreferencesAsync` stores, which this plan does not touch.

### Acceptance discrepancies (noted, not fixed)
- Task 4 sanity `git diff --stat develop -- … lib/graphql …` lists the three fragments changed by plans 17-01..17-03 (the whole branch vs `develop`); against the plan start `4e04a89` the diff over `lib/graphql pubspec.yaml journal shop` is empty.
- Task 2 RED expected red cases in `library_test.dart`; they were green at first run (reason above).

## Shared result files with the parked FE Phase 16 (CONTEXT D-18)

Not touched.

## Known Stubs

None.

## Threat Flags

None beyond the plan's register: T-17-33 mitigated by the 60-entry and closed-section tests, T-17-34 by the bounded/failure/never-awaited tests, T-17-36 by the untouched consumers (`git diff --stat develop` empty on Journal and shop). The board paper now hit-tests its whole box (deviation 1) — no new surface, same tap target as a loaded paper.

## Self-Check: PASSED

- Files exist: `image_warmer.dart`, `cached_svg_test.dart`, `image_warmer_test.dart`, `recording_image_warmer.dart`, `dropdown.dart`, `library_data_page.dart`, this SUMMARY.
- Commits `c10721c`, `5d8ffd0`, `b07de7d`, `e3dfd29`, `01f7a96`, `c299d08`, `821f4fa` in `git log`.
