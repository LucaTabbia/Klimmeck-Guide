---
phase: quick-261022-qkx
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/shared/components/tear/tear_clipper.dart
  - lib/shared/components/tear/tear_geometry.dart
  - lib/shared/components/tear/tearable_paper.dart
  - lib/screens/mainScreen/tabs/board/board.dart
  - test/shared/components/tear/tear_geometry_test.dart
  - test/shared/components/tear/tear_clipper_test.dart
  - test/shared/components/tear/tearable_paper_test.dart
  - test/screens/mainScreen/tabs/board/board_acceptance_test.dart
  - .planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md
autonomous: true
requirements: [QUEST-02]

must_haves:
  truths:
    - "Swiping the open quest sheet to the left still tears it (same gesture, threshold, haptics, resistance, spring back)"
    - "The tear line is horizontal at 10% of the paper height: the top strip stays still, the lower 90% follows the finger to the left"
    - "Once torn, the lower piece keeps sliding left until it is fully off-screen; it is never cut at mid screen"
    - "A rejected acceptance (recompose) brings the lower piece back and the paper is whole again"
    - "The jagged edge is irregular, differs per quest (seeded by quest id) and is identical for the same quest"
  artifacts:
    - path: "lib/shared/components/tear/tear_clipper.dart"
      provides: "TearPiece {stub, body}, seeded horizontal jagged cut at tearRatio 0.10, seedOf(id)"
      contains: "tearRatio = 0.10"
    - path: "lib/shared/components/tear/tear_geometry.dart"
      provides: "PiecePose, TearGeometry.at(progress, width, {exit, exitDistance}) with stub at rest"
      contains: "class PiecePose"
    - path: "lib/shared/components/tear/tearable_paper.dart"
      provides: "TearablePaper with tearSeed, exit animation, Stack clipBehavior none, stubKey/bodyKey"
      contains: "Clip.none"
    - path: "test/shared/components/tear/tear_clipper_test.dart"
      provides: "Clipper tests (horizontal cut, seed determinism, irregular steps)"
  key_links:
    - from: "lib/screens/mainScreen/tabs/board/board.dart"
      to: "TearablePaper.tearSeed"
      via: "tearSeed: TearClipper.seedOf(selected.id)"
      pattern: "seedOf\\(selected\\.id\\)"
    - from: "lib/screens/mainScreen/tabs/board/board.dart"
      to: "sheet SingleChildScrollView"
      via: "clipBehavior: Clip.none on the board-sheet scroll view"
      pattern: "clipBehavior: Clip.none"
---

<objective>
Rework the tear of the quest info sheet per the user's device-UAT decision (2026-10-22): same left swipe, but the
cut is a horizontal jagged line at 10% of the paper height; the top strip stays, the lower piece follows the finger
left and, once torn, slides fully off-screen without being clipped at mid screen; the jaggedness is more random
(seeded, so still deterministic per quest).

Purpose: the device UAT showed the screen "split in two" and the moving half clipped at the left half.
Output: updated tear clipper/geometry/widget, board wiring, tests, D-06 amended.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
Project root: /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide (prefix EVERY shell command with
`cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide &&`). Branch: feat/06-quest-accept-info-sheets
(stay on it). Rules: docs/rules/testing.md (TDD red first), docs/rules/workflow.md (Conventional Commits, NO
Co-Authored-By trailers). Never run `dart format` on directories.

@.planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md
@.planning/phases/06-quest-accept-info-sheets/06-05-SUMMARY.md
@lib/shared/components/tear/tear_clipper.dart
@lib/shared/components/tear/tear_geometry.dart
@lib/shared/components/tear/tearable_paper.dart
@lib/screens/mainScreen/tabs/board/board.dart

<diagnosis>
Root cause of the "screen split in two / clipped at the left half" (verified by reading the code, the app runs in
LANDSCAPE: tests use `useLandscapePhone` = 780x360 logical):
- The open sheet is `Positioned(right: 0)` > `SizedBox(width: screenHeight * 1.5 * 315/375)` ≈ 454 px on a 780 px
  wide screen, so the paper spans x ≈ 326..780 — its left edge is at ~42% of the screen.
- The old cut was vertical at 50% of the paper (x ≈ 553): the screen looked split in two.
- Two ancestors clip at the paper's left edge (x ≈ 326), hiding the left half as soon as it moves past it:
  1. the `Stack` inside `TearablePaperState._halves` (default `Clip.hardEdge`, bounds = paper);
  2. the board's `SingleChildScrollView(key: ValueKey('board-sheet-${selected.id}'))` (default `Clip.hardEdge`,
     bounds = the SizedBox = paper).
- The board's outer `Stack` and the MainScreen `PageView` clip at the screen edges: that is the desired "off-screen"
  boundary, leave them alone.
Consequence for the exit distance: translating by `-(paperWidth + margin)` is NOT enough in landscape (paper right
edge is at screen x = 780 while paper width is 454). The exit distance must be the paper's global right edge.
</diagnosis>

<interfaces>
Current (to be replaced):
```dart
enum TearSide { left, right }
class TearClipper extends CustomClipper<Path> { const TearClipper({required this.side}); static List<Offset> edgePoints(Size size); }
class HalfPose { final double dx; final double angle; }
class TearGeometry { factory TearGeometry.at(double progress, double width); final HalfPose left; final HalfPose right; }
```
`TearSide`/`HalfPose`/`TearGeometry`/`TearClipper` are used ONLY inside lib/shared/components/tear/ and
test/shared/components/tear/ (grep confirmed) — rename freely.
Unchanged: `TearGesture` (travelFraction 0.45, flingProgress 0.35, flingVelocity -900, blockedCap 0.12),
`ThresholdLatch`, `TearablePaperState.recompose()`, `isTorn`.
board_acceptance_test.dart helpers: `pumpBoard(tester, quests: [...])` (landscape), `openSheet(tester, id)`,
`dragSheetLeft(tester)` (drags -600 then pumps 1 s), `acceptanceStates` StreamController.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Seeded horizontal clipper + new pure geometry (TDD)</name>
  <read_first>
    lib/shared/components/tear/tear_clipper.dart, lib/shared/components/tear/tear_geometry.dart,
    test/shared/components/tear/tear_geometry_test.dart, docs/rules/testing.md
  </read_first>
  <files>lib/shared/components/tear/tear_clipper.dart, lib/shared/components/tear/tear_geometry.dart, test/shared/components/tear/tear_clipper_test.dart, test/shared/components/tear/tear_geometry_test.dart</files>
  <behavior>
    tear_clipper_test.dart (new; move the `TearClipper` group out of tear_geometry_test.dart), size = Size(200, 400):
    - 'edge spans the full width around 10% of the height': first.dx == 0, last.dx == 200, every dy in
      [400 * (0.10 - 0.025), 400 * (0.10 + 0.025)].
    - 'same seed gives the same edge': edgePoints(size, seed: 7) equals edgePoints(size, seed: 7).
    - 'different seeds give different edges': seed 1 != seed 2.
    - 'step widths and depths are irregular': the set of consecutive dx gaps (rounded to 0.1) has > 1 element, and
      the set of |dy - 40| (rounded to 0.1) has > 1 element.
    - 'stub and body clips cover opposite sides of the cut': stub contains (100, 8), not (100, 200); body contains
      (100, 200), not (100, 8).
    - 'shouldReclip only when piece or seed changes'.
    - 'seedOf is stable and id-dependent': seedOf('h-1') == seedOf('h-1'), seedOf('h-1') != seedOf('h-2'),
      seedOf(x) >= 0.
    tear_geometry_test.dart (rewrite):
    - 'is at rest at progress 0': stub and body dx == 0, angle == 0.
    - 'the stub never moves': for progress in [0, 0.25, 0.5, 1] and exit in [0, 0.5, 1]: stub dx == 0, angle == 0.
    - 'the body follows the finger left': for progress 0.25, 0.5, 1 (exit 0): body.dx strictly decreasing, body.angle
      strictly decreasing (negative), body.dx at progress 1 > -400 (still partly on the paper).
    - 'the exit pushes the body past the exit distance': at(1, 400, exit: 1).body.dx <= -400 * 1.15 (default
      exitDistance = width); at(1, 400, exit: 1, exitDistance: 780).body.dx <= -780; body.dx decreases monotonically
      for exit 0 → 0.5 → 1.
  </behavior>
  <action>
    RED first: write both test files, run them, confirm they fail (compile errors count as red); commit
    `test(tear): horizontal seeded tear and off-screen exit` .

    GREEN — tear_clipper.dart (import 'dart:math' as math + flutter/widgets):
    - Replace `TearSide` with `enum TearPiece { stub, body }` (stub = top strip that stays, body = lower piece).
    - `class TearClipper extends CustomClipper<Path>`: `const TearClipper({required this.piece, this.seed = 0});`
      constants `static const double tearRatio = 0.10; static const double minStep = 0.015; static const double
      maxStep = 0.06;` (fractions of width) `static const double maxJag = 0.025;` (fraction of height)
      `static const double minJagShare = 0.2;`.
    - `static int seedOf(String id) => id.codeUnits.fold(17, (hash, unit) => (hash * 31 + unit) & 0x3fffffff);`
      (do NOT use String.hashCode: not guaranteed stable).
    - `static List<Offset> edgePoints(Size size, {int seed = 0})`: `final random = math.Random(seed);` baseY =
      height * tearRatio; start `[Offset(0, baseY)]`; if width <= 0 return `[Offset(0, baseY), Offset(size.width,
      baseY)]`; loop while x < width: x = min(width, x + width * (minStep + random.nextDouble() * (maxStep -
      minStep))); depth = height * maxJag * (minJagShare + (1 - minJagShare) * random.nextDouble()); add
      Offset(x, baseY + (isUp ? -depth : depth)); flip isUp when random.nextDouble() < 0.8 (initial isUp =
      random.nextBool()). Last point therefore has dx == width exactly.
    - `getClip`: edge = edgePoints(size, seed: seed); outerY = piece == stub ? 0 : size.height; path
      moveTo(0, outerY) → lineTo(size.width, outerY) → lineTo each edge point in REVERSE order (from x=width back to
      x=0) → close. Both pieces share the same edge.
    - `shouldReclip(old) => old.piece != piece || old.seed != seed`.
    - Doc comment (Italian, short): "Taglio orizzontale frastagliato al 10% dell'altezza, deterministico per seed
      (mai Random non seminato): stub e body condividono lo stesso bordo."
    tear_geometry.dart:
    - `class PiecePose { const PiecePose({required this.dx, required this.angle}); static const PiecePose rest =
      PiecePose(dx: 0, angle: 0); final double dx; final double angle; }` (replaces HalfPose).
    - `class TearGeometry { const TearGeometry({required this.stub, required this.body}); static const double
      dragShift = 0.35; static const double exitMargin = 0.15; static const double maxAngle = -0.04;`
      `factory TearGeometry.at(double progress, double width, {double exit = 0, double? exitDistance})`:
      dragTravel = progress * dragShift * width; exitTravel = (exitDistance ?? width) * (1 + exitMargin);
      travel = dragTravel + exit * (exitTravel - dragTravel); return TearGeometry(stub: PiecePose.rest, body:
      PiecePose(dx: -travel, angle: maxAngle * progress)).
      Keep the "numeri provvisori, D-19" doc note.
    Run tests green, `dart format` ONLY on these 4 files, commit `feat(tear): horizontal seeded tear geometry`.
  </action>
  <verify>
    <automated>cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && flutter test test/shared/components/tear/tear_clipper_test.dart test/shared/components/tear/tear_geometry_test.dart</automated>
  </verify>
  <acceptance_criteria>
    - `grep -n "tearRatio = 0.10" lib/shared/components/tear/tear_clipper.dart` matches
    - `grep -n "math.Random(seed)" lib/shared/components/tear/tear_clipper.dart` matches
    - `grep -rn "TearSide\|HalfPose" lib/shared/components/tear/tear_clipper.dart lib/shared/components/tear/tear_geometry.dart test/shared/components/tear/tear_clipper_test.dart test/shared/components/tear/tear_geometry_test.dart` returns nothing
    - both test files pass; red commit precedes green commit in `git log`
  </acceptance_criteria>
  <done>Pure clipper and geometry implement the 10% horizontal seeded cut and the off-screen exit, fully tested.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: TearablePaper exit animation, no clipping, board wiring (TDD)</name>
  <read_first>
    lib/shared/components/tear/tearable_paper.dart, test/shared/components/tear/tearable_paper_test.dart,
    lib/screens/mainScreen/tabs/board/board.dart (`_buildQuestInfoSheet`),
    test/screens/mainScreen/tabs/board/board_acceptance_test.dart (helpers pumpBoard/openSheet/dragSheetLeft)
  </read_first>
  <files>lib/shared/components/tear/tearable_paper.dart, test/shared/components/tear/tearable_paper_test.dart, lib/screens/mainScreen/tabs/board/board.dart, test/screens/mainScreen/tabs/board/board_acceptance_test.dart</files>
  <behavior>
    tearable_paper_test.dart (harness: 400x300 paper centered in the default 800x600 surface, paper rect x 200..600):
    - keep all existing tests (rename 'halves stay apart' → 'a full drag tears, haptics fire, the body leaves');
      `find.byType(ClipPath)` counts stay valid (2 pieces while torn, 0 at rest).
    - 'only the body moves while dragging': startGesture at paper center, moveBy(-60, 0) x3 with pumps; then
      tester.getRect(find.byKey(TearablePaper.stubKey)) == tester.getRect(paper) and
      tester.getTopLeft(find.byKey(TearablePaper.bodyKey)).dx < tester.getTopLeft(paper).dx; release (gesture.up).
    - 'a completed tear slides the body off-screen': drag (-300, 0), pumpAndSettle →
      tester.getRect(find.byKey(TearablePaper.bodyKey)).right < 0 and the stub rect still equals the paper rect.
    - 'recompose brings the body back': after the off-screen test flow, recompose() + pumpAndSettle →
      find.byType(ClipPath) findsNothing.
    - 'the pieces are not clipped by the paper bounds': mid-drag, the Stack that is a descendant of the paper has
      `clipBehavior == Clip.none` (`tester.widget<Stack>(find.descendant(of: paper, matching: find.byType(Stack)))`).
    - 'no Dismissible': `find.byType(Dismissible)` findsNothing at rest and mid-drag.
    board_acceptance_test.dart (add to group 'swipe to accept'):
    - 'the open sheet scroll view does not clip the torn piece': openSheet 'h-1' →
      `tester.widget<SingleChildScrollView>(find.byKey(const ValueKey('board-sheet-h-1'))).clipBehavior == Clip.none`.
    - 'a completed tear slides the body off the screen': openSheet, dragSheetLeft →
      `tester.getRect(find.byKey(TearablePaper.bodyKey)).right < 0` (landscape surface, paper left edge ≈ 326).
    - existing 'a rejection recomposes the paper' must still pass (isTorn false after 1 s).
  </behavior>
  <action>
    RED first: add/adjust the tests above, run, confirm red; commit `test(tear): body exits off-screen unclipped`.

    GREEN — tearable_paper.dart:
    - Mixin `TickerProviderStateMixin` (two controllers). Add `late final AnimationController _exitController =
      AnimationController(vsync: this);` dispose it too. Constants `_exitDuration = Duration(milliseconds: 380)`,
      `_returnDuration = Duration(milliseconds: 240)`.
    - New public statics `static const Key stubKey = ValueKey('tear-stub'); static const Key bodyKey =
      ValueKey('tear-body');` (put the key on the ClipPath of each piece).
    - New param `final int tearSeed;` (default 0), passed to `TearClipper(piece: ..., seed: widget.tearSeed)`.
    - Field `double _exitDistance = 0;`. In `_commitTear`, BEFORE animating: read the paper's global right edge
      `final box = context.findRenderObject() as RenderBox?; _exitDistance = box == null ? _width :
      math.max(_width, box.localToGlobal(Offset(box.size.width, 0)).dx);` (the state's context is the
      LayoutBuilder's element; its RenderBox is the paper). Then: `_isTorn = true; await
      _controller.animateTo(1, duration: _commitDuration); if (!mounted) return; HapticFeedback.mediumImpact();
      widget.onTorn(); _exitController.animateTo(1, duration: _exitDuration, curve: Curves.easeIn);` (import
      flutter/animation via widgets — Curves is in package:flutter/animation.dart, already exported by widgets).
      onTorn fires once, at the tear (unchanged contract).
    - `recompose()`: `_isTorn = false; _exitController.animateTo(0, duration: _returnDuration, curve:
      Curves.easeOut); _springBack(0);`.
    - Rest rendering: whole child only when `_controller.value == 0 && _exitController.value == 0`; AnimatedBuilder
      animation = `Listenable.merge([_controller, _exitController])`. `_snapToRest` keeps snapping the progress
      residue; it must not run while `_exitController.isAnimating` matters only for rendering, so the rest check
      above suffices.
    - `_piece(TearPiece piece, PiecePose pose, Key key)` = Transform.translate(Offset(pose.dx, 0)) >
      Transform.rotate(pose.angle) > ClipPath(key: key, clipper: TearClipper(piece: piece, seed: widget.tearSeed),
      clipBehavior: Clip.antiAlias, child: widget.child).
    - `_pieces(progress, exit)`: pose = TearGeometry.at(progress, _width, exit: exit, exitDistance:
      _exitDistance); `RepaintBoundary(child: Stack(clipBehavior: Clip.none, children: [stub, body]))` — stub
      painted first, body on top. The `Clip.none` is the fix for the mid-screen clipping (see <diagnosis>).
    - Update the class doc: "strappo orizzontale al 10% in alto: lo stub resta, il body scivola a sinistra fuori
      schermo (D-06 emendata 2026-10-22)". No Dismissible, gesture code untouched.
    board.dart (pre-existing dirty file: HAND-EDIT only, never `dart format` it):
    - import `package:klimmeck_guide/shared/components/tear/tear_clipper.dart`.
    - On the `SingleChildScrollView(key: ValueKey('board-sheet-${selected.id}'), ...)` add
      `clipBehavior: Clip.none,` — the body must travel across the board to the screen edge; the vertical scroll
      still works (clipping ≠ scrolling); overflow above/below the sheet viewport lands off-screen when the sheet
      is open (top: 0) and is clipped by the board's outer Stack at the screen edges. Leave the outer board Stack
      and the PageView clipping as they are (they are the off-screen boundary).
    - Pass `tearSeed: TearClipper.seedOf(selected.id),` to `TearablePaper`.
    Run tests green; `dart format` ONLY tearable_paper.dart, tearable_paper_test.dart (board_acceptance_test.dart:
    run `dart format --output=none --set-exit-if-changed` on it first; format it only if it was clean before your
    edit, otherwise hand-format your additions). Commit `fix(tear): torn body slides off-screen unclipped`.
  </action>
  <verify>
    <automated>cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && flutter test test/shared/components/tear test/screens/mainScreen/tabs/board</automated>
  </verify>
  <acceptance_criteria>
    - `grep -n "clipBehavior: Clip.none" lib/shared/components/tear/tearable_paper.dart lib/screens/mainScreen/tabs/board/board.dart` matches in both files
    - `grep -n "seedOf(selected.id)" lib/screens/mainScreen/tabs/board/board.dart` matches
    - `grep -n "_exitController" lib/shared/components/tear/tearable_paper.dart` matches
    - `grep -n "Dismissible" lib/shared/components/tear/tearable_paper.dart` returns nothing
    - `git diff --stat lib/shared/components/tear/tear_gesture.dart` is empty
    - tear + board test directories green
  </acceptance_criteria>
  <done>On the landscape board the torn body slides past the screen's left edge, nothing clips it at the paper's left edge, recompose restores the paper.</done>
</task>

<task type="auto">
  <name>Task 3: Amend D-06 and run the full gate</name>
  <read_first>.planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md (line with `- **D-06:**`, and D-19)</read_first>
  <files>.planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md</files>
  <action>
    Edit D-06 IN PLACE (keep the id and the existing text about the parchment SVG, no new asset, haptics), appending:
    " **Amended 2026-10-22 (device UAT, user decision):** the left swipe stays; the cut is a horizontal jagged line
    at 10% of the paper height (e.g. 80 px of 800 px); the top strip stays on the board, the lower piece follows the
    finger left and, once torn, keeps sliding left until fully off-screen (no clipping at mid screen: the paper's
    Stack and the sheet scroll view use `Clip.none`); a rejection recomposes it with the spring. The jaggedness is
    irregular, generated from a `Random` seeded with the quest id (deterministic per quest — never an unseeded
    Random). Still provisional per D-19." Replace the now-wrong phrase "clipped in two along a jagged edge and the
    halves move apart/rotate following the finger" with "clipped along a jagged edge" so the entry is not
    self-contradictory. Do not touch any other decision, ROADMAP.md or STATE.md.
    Gate: full `flutter test`; `flutter analyze` → 0 errors and issue count ≤ 54 (baseline); fix any new issue in the
    touched files. Commit `docs(06): amend D-06 tear geometry after device UAT`.
  </action>
  <verify>
    <automated>cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && flutter test && flutter analyze | tail -3</automated>
  </verify>
  <acceptance_criteria>
    - `grep -n "Amended 2026-10-22" .planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md` matches on the D-06 line
    - `grep -c "D-06" .planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md` unchanged id (no D-06b / new id)
    - full `flutter test` green; `flutter analyze` 0 errors, ≤ 54 issues
    - `git log --format=%B -4 | grep -c Co-Authored-By` is 0
  </acceptance_criteria>
  <done>D-06 reflects the user's decision, the whole suite and analyzer are clean.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| none new | Pure client-side rendering change; no input crosses a trust boundary, acceptance still goes through the existing mutation |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-qkx-01 | T | TearablePaper onTorn | accept | onTorn still fires once per tear (isTorn latch unchanged); the backend validates acceptance (source of truth) |
| T-qkx-02 | D | seeded edge generation | accept | bounded loop (min step 1.5% of width → ≤ ~67 points), width <= 0 guarded |
</threat_model>

<verification>
- `flutter test test/shared/components/tear test/screens/mainScreen/tabs/board` green
- full `flutter test` green; `flutter analyze` 0 errors, no new issues (≤ 54)
- `dart format` run only on the tear files/tests (never on directories, never on board.dart)
- Conventional Commits, no Co-Authored-By trailers; ROADMAP.md / STATE.md untouched
</verification>

<success_criteria>
- Horizontal seeded jagged tear at 10% height; top stub static, lower body follows the finger left
- Completed tear: body exits past the screen's left edge, unclipped at mid screen (landscape board test proves it)
- recompose restores the paper; gesture model untouched
- D-06 amended in place, dated 2026-10-22, still provisional (D-19)
</success_criteria>

<output>
After completion, create `.planning/quick/261022-qkx-tear-geometry-horizontal-tear-near-the-t/261022-qkx-SUMMARY.md`
</output>
