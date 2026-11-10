---
phase: 18-heal-quests-by-size
reviewed: 2026-11-10
depth: standard (two parallel reviewers by area — A quest cure, healed line, heal with no effect; B Journal potions)
files_reviewed: 43
findings:
  critical: 0
  warning: 1
  info: 11
  total: 12
status: issues_found
---

# Code review — Phase 18 Heal Quests by City Size (plans 18-01..18-11)

The two group reports are the source: [`18-REVIEW-A.md`](./18-REVIEW-A.md) (0 critical, 0 warning, 5 info) and [`18-REVIEW-B.md`](./18-REVIEW-B.md) (0 critical, 1 warning, 6 info). The orchestrator's ruling for every finding is in [`18-REVIEW-RULINGS.md`](./18-REVIEW-RULINGS.md); the fixes are recorded in `18-REVIEW-FIX.md`.

The gated plans 18-12 (schema gate and fragment selections against the merged BE Phase 18) and 18-13 (device UAT and handoff) are outside this review.

| ID | Severity | File | Claim |
|----|----------|------|-------|
| A-IN-01 | info | `lib/shared/components/popup/quest_result_sheet.dart` | dead aliases of the shared lore line prefixes |
| A-IN-02 | info | `lib/screens/mainScreen/components/quest_scope_listener.dart` | injuries compared in wire order: a reordered set rereads for nothing |
| A-IN-03 | info | `lib/utils/item_lines.dart` | a 1% share prints «il 1%» instead of the elided article |
| A-IN-04 | info | `lib/models/quest/quest_paper_asset.dart` | `noEffect` on a non-heal type has no torn asset (the backend sets it only on a heal) |
| A-IN-05 | info | `test/shared/components/popup/quest_info_sheet_test.dart` | no test of a narrative sheet with lore and cure rows together |
| B-WR-01 | warning | `lib/screens/mainScreen/tabs/journal/sections/items_section.dart` | the drag-to-dismiss guard while drinking has no test |
| B-IN-01 | info | `test/screens/mainScreen/tabs/journal/sections/items_section_test.dart` | no test composes the real cubit with section, sheet and listener |
| B-IN-02 | info | `test/repository/item_use_repository_test.dart` | the timeout test waits on a real timer |
| B-IN-03 | info | `lib/repository/services/graphql/graphql_error_code.dart` | the extension is read from the first coded error only |
| B-IN-04 | info | `lib/models/use_item_result.dart` | `quantityLeft` and `toJson` are not read by production code |
| B-IN-05 | info | `lib/screens/mainScreen/tabs/journal/sections/items_section.dart` | an unknown maximum would draw a «x / 0» bar |
| B-IN-06 | info | `lib/repository/item_use_repository.dart` | a malformed result after a successful drink is announced as a refusal with no reread |
