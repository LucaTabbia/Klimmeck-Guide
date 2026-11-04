---
phase: 14-quest-generation
plan: 04
subsystem: ui
tags: [enemy, portrait, cloudinary, cached_network_image, cached_svg, tdd]
requires:
  - 14-01 (QuestEnemy / strongestEnemyOf give the enemy whose imagePath is rendered)
provides:
  - enemyPortraitUrl pure resolver (https with host or Cloudinary v<n>/… → URL, else null)
  - EnemyPortrait shared widget (SVG → CachedSvg, raster → CachedNetworkImage, empty box otherwise)
affects: [14-05, 14-06, phase-17]
tech-stack:
  added: []
  patterns: [allow-list URL resolver, mocktail BaseCacheManager with a never-emitting stream to keep the raster branch offline]
key-files:
  created:
    - lib/utils/enemy_portrait_url.dart
    - lib/shared/components/enemy_portrait.dart
    - test/utils/enemy_portrait_url_test.dart
    - test/shared/components/enemy_portrait_test.dart
  modified: []
decisions:
  - "The enemy portrait URL is an allow-list: https with a host as is, Cloudinary-relative v<n>/… through CloudinaryAssets.url, everything else hidden (D-03, T-14-08)"
  - "EnemyPortrait.canShow lets the sheets reserve space only when a portrait can load (T-14-09)"
metrics:
  duration: ~10 min
  completed: 2026-11-04
  tasks: 2
  commits: 4
---

# Phase 14 Plan 04: Enemy portrait resolver and shared widget Summary

A pure allow-list resolver `enemyPortraitUrl(String? imagePath)` and one shared `EnemyPortrait` widget that renders an SVG through `CachedSvg`, a raster through `CachedNetworkImage` (empty-box placeholder and error widget, no spinner) and nothing at all for an unresolvable path (today's DB placeholders `assets/images/<slug>.png` stay hidden). Not wired into the sheets yet: 14-05 (quest sheet) and 14-06 (result sheet) consume it.

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | enemyPortraitUrl resolver | 2caf1b6 (test), 4fd117b (feat) |
| 2 | EnemyPortrait shared widget | fab0428 (test), 4087ebd (feat) |

## Exact names and signatures

- `lib/utils/enemy_portrait_url.dart` (imports only `package:klimmeck_guide/config/cloudinary_assets.dart`):
  - private `final RegExp _cloudinaryRelativePath = RegExp(r'^v\d+/\S+$');`
  - `String? enemyPortraitUrl(String? imagePath)` — trims; null/blank → null; `Uri.tryParse` scheme `https` with a non-empty host → the trimmed string; `v<digits>/<non-space>+` → `CloudinaryAssets.url(path)`; else null.
- `lib/shared/components/enemy_portrait.dart`:
  - `class EnemyPortrait extends StatelessWidget { const EnemyPortrait({super.key, required this.imagePath, this.height, this.cacheManager}); static const String semanticLabel = 'Ritratto del nemico'; final String? imagePath; final double? height; final BaseCacheManager? cacheManager; static bool canShow(String? imagePath); }`
  - build: url null → `const SizedBox.shrink()`; else `Semantics(label: semanticLabel, image: true, child: …)`; `.svg` (by `Uri.parse(url).path`, case-insensitive) → `CachedSvg(url: url, height: height)`; else `CachedNetworkImage(imageUrl, height, fit: BoxFit.contain, cacheManager, placeholder/errorWidget → SizedBox.shrink())`.

## RED failures observed

- Task 1 (`flutter test test/utils/enemy_portrait_url_test.dart`): compile failure, `lib/utils/enemy_portrait_url.dart` missing / `enemyPortraitUrl` not found (0 tests run).
- Task 2 (`flutter test test/shared/components/enemy_portrait_test.dart`): compile failure, `Error when reading 'lib/shared/components/enemy_portrait.dart'`, `Method not found: 'EnemyPortrait'`.
- No case green at first run.

## How the raster branch stays offline

`class _PendingCacheManager extends Mock implements BaseCacheManager {}` in the test file; `setUp` stubs `getFileStream(any(), key:, headers:, withProgress:)` with `StreamController<FileResponse>().stream` (never emits, never closes), so `CachedNetworkImage` neither hits HTTP nor `path_provider`. The test pumps once (`pump()`, never `pumpAndSettle`) and calls the widget's `placeholder!(context, url)` and `errorWidget!(context, url, Exception('404'))` directly, asserting a zero-size `SizedBox`. The SVG branch uses `seedSvgCache(['v1/goblin_test.svg'])`. No mocktail `registerFallbackValue` was needed.

## Tests

- After Task 1: `flutter test test/utils/enemy_portrait_url_test.dart` → 7 passed.
- After Task 2 (plan verification): `flutter test test/shared/components/enemy_portrait_test.dart test/utils/enemy_portrait_url_test.dart` → 13 passed.
- Analyzer after each code task: `50 issues found.` (all info), 0 error, 0 warning → `ANALYZE_GATE_OK`.
- `dart format` on the four new files, one by one: 0 changed.
- `git diff develop -- pubspec.yaml | wc -l` → 0 (no new dependency); no new `CloudinaryAssets` id, no new env var.
- Acceptance greps: resolver `String? enemyPortraitUrl` 1, `'https'` 1, `'http'` 0, `package:flutter/` none, `D-03)` 7; widget `class EnemyPortrait` 1, `enemyPortraitUrl` 2, `CachedNetworkImage(` 1, `CachedSvg(` 1, `Image.asset|Image.network|CircularProgressIndicator` 0, `D-03)` 6.

## Deviations from Plan

- Acceptance grep `grep -c "CloudinaryAssets.url" lib/utils/enemy_portrait_url.dart` = 2, the plan expects 1: the second match is the `[CloudinaryAssets.url]` reference in the doc comment the plan itself prescribes; there is exactly one call. Left as written.
- Plan bookkeeping writes `04/11` / `Plan: 04 of 11`; the orchestrator's `4/11` / `Plan: 4 of 11` was used (orchestrator wins).

## Observations (out of scope, not fixed)

- `CachedSvg` (pre-existing, shared across the app) shows a 14 px `CircularProgressIndicator` while an uncached SVG is loading from disk/network. The SVG branch of `EnemyPortrait` inherits it; the raster branch has no spinner. Changing `CachedSvg` would touch every SVG in the app and is outside this plan. Today no enemy has a `.svg` Cloudinary path, so nothing visible changes; flag for the review of 14-05/14-06 if rule 2 is applied strictly.

## Known Stubs

None. The widget is complete; its wiring into the sheets belongs to 14-05 and 14-06.

## Self-Check: PASSED

- Files: lib/utils/enemy_portrait_url.dart, lib/shared/components/enemy_portrait.dart, test/utils/enemy_portrait_url_test.dart, test/shared/components/enemy_portrait_test.dart — all FOUND.
- Commits: 2caf1b6, 4fd117b, fab0428, 4087ebd — all FOUND in `git log`.
