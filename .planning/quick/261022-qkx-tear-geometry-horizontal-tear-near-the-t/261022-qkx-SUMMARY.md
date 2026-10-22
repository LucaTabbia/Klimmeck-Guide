---
phase: quick-261022-qkx
plan: 01
requirements: [QUEST-02]
commits:
  - 0023788 test(tear): horizontal seeded tear and off-screen exit
  - 054749b feat(tear): horizontal seeded tear geometry
  - 4691ac3 test(tear): body exits off-screen unclipped
  - 0899c46 fix(tear): torn body slides off-screen unclipped
  - f8e08ef docs(06): amend D-06 tear geometry after device UAT
---

# Quick 261022-qkx: tear geometry Summary

Horizontal seeded jagged tear at 10% of the paper height; the top stub stays, the lower body follows the finger left and slides off-screen unclipped.

## What changed
- tear_clipper.dart: TearPiece {stub, body}, seeded edge (math.Random(seed)), seedOf(id) stable hash.
- tear_geometry.dart: PiecePose, TearGeometry.at(progress, width, exit, exitDistance); stub fixed.
- tearable_paper.dart: tearSeed, exit AnimationController (380 ms in, 240 ms back on recompose), exit distance = paper global right edge, Stack Clip.none, stubKey/bodyKey. Gesture code untouched.
- board.dart (hand-edited): clipBehavior: Clip.none on the sheet scroll view, tearSeed: TearClipper.seedOf(selected.id).
- 06-CONTEXT.md D-06 amended in place.

## Gates
- Full flutter test: 1334 passed, 0 failed.
- flutter analyze: 54 issues (baseline 54), 0 errors.
- No Co-Authored-By trailers.

## Deviations
- [Rule 3] The tearable_paper_test harness child was a childless ColoredBox, which collapses to 0x0 under the Stack's loose constraints, so piece rects were empty. I gave it `SizedBox.expand()`. No production change.

## How to verify on the device
1. Open a quest sheet on the board; swipe left past the threshold.
2. The top ~10% strip stays; the lower piece follows the finger left, tilting slightly.
3. After the tear the lower piece keeps sliding to the left screen edge, with no cut at mid screen.
4. Force a rejection (e.g. lane busy): the lower piece slides back with the spring and the paper is whole.
5. Reopen the same quest: identical jagged edge; a different quest has a different edge.
