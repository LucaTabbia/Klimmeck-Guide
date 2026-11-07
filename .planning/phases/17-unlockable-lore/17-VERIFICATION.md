---
phase: 17-unlockable-lore
verified: 2026-11-07T12:46:00Z
status: human_needed
score: "3/3 ROADMAP success criteria verified in code and tests for plans 17-01..17-08; the device halves wait for the gated plan 17-10"
overrides_applied: 0
re_verification:
  previous_status: none
  note: "Initial verification. No previous VERIFICATION.md existed."
gaps: []
deferred:
  - truth: "Contract names (CharacterStatus.unlockedLore, QuestEnemy.known, QuestResult.loreUnlocked) proved on the merged BE Phase 16 SDL"
    addressed_in: "Plan 17-09"
    evidence: "CONTEXT D-13 / ROADMAP 17-09: gated by the BE Phase 16 merge; the BE phase is still being executed in the other repo"
  - truth: "45/45 documents validated against the BE schema (schema gate)"
    addressed_in: "Plan 17-09"
    evidence: "17-09-PLAN.md: dump + validate against BE origin/develop after the merge; fragments now select fields a pre-Phase-16 BE rejects (D-14)"
  - truth: "Full suite, repo-wide analyzer, format/trailer gates in the gate plan and 17-VALIDATION.md approval"
    addressed_in: "Plan 17-09"
    evidence: "17-09-PLAN.md ROADMAP line: full suite, analyzer, format/trailer/sanity gates, VALIDATION approved"
  - truth: "17-HUMAN-UAT.md recorded, BACKEND-NOTES.md handoff, LORE-01..03 ticked in REQUIREMENTS.md, ROADMAP/STATE/VALIDATION closure"
    addressed_in: "Plan 17-10"
    evidence: "17-10-PLAN.md: device E2E with a player identity as a blocking human checkpoint; requirements ticked only for passed steps; gated by the BE Phase 16 merge"
human_verification:
  - test: "1. New character (player identity): open the Library -> «Luoghi» shows only the home city, its regions and its state, with no «Nuovo» on this first opening; empty sections hidden; «Bestiario», «Religioni» and «Conoscenze» each show «Le pagine di questo libro sono ancora bianche.» (LORE-01, LORE-03; D-02, D-06, D-07)"
    expected: "Only the birth geography in Luoghi, no marks; the other three books show the empty-book line"
    why_human: "device E2E of the gated plan 17-10; needs BE Phase 16 live, a player identity (the dev bypass is the innkeeper and sees everything) and a freshly created character"
  - test: "2. With «Luoghi» open, travel to a never-visited city (travel time shortened by the orchestrator): at the arrival its page (and its region/state when new) appears without spinner and marked «Nuovo»; close the book and reopen it -> no mark; cold restart and reopen -> still no mark (LORE-01; D-05, D-07)"
    expected: "Live page with «Nuovo», no spinner; marks gone on reopen and after a cold restart"
    why_human: "needs the live characterUpdated subscription carrying unlockedLore, a real arrival and the persisted baseline across a cold start"
  - test: "3. Map: tap a never-visited city -> the paper modal shows only its name and «Non conosci ancora questa città.» (no image, no description); without restarting, tap the city just reached in step 2 -> its lore as before (image, name, description) (LORE-03; D-11)"
    expected: "Name-only modal for the unknown city; the reached city shows its full lore without a restart"
    why_human: "needs City.relatedLore resolved per viewer by the real BE and the silent cities refresh on the live subscription"
  - test: "4. Board: open a quest whose strongest enemy the character never defeated -> the portrait is a full black silhouette, the «Nx nome» lines and the «Consigliati» are unchanged (LORE-02; D-08)"
    expected: "Black silhouette, names and recommended loot unchanged"
    why_human: "visual review of the silhouette and a real known:false from the BE with a seeded quest"
  - test: "5. Win that quest (orchestrator seeds the outcome path as in the BE handoff) -> the result sheet shows the portrait in clear and «Nuova pagina del Bestiario: <nome>» after «Magia appresa» (when present); the «Bestiario» shows the page marked «Nuovo»; after the board re-reads, the same enemy's portrait on a quest card is in clear (LORE-02, LORE-01; D-09, D-10)"
    expected: "Portrait in clear, bestiary line, new page marked «Nuovo», card in clear after the board re-read"
    why_human: "needs a real resolved quest with loreUnlocked from the BE and DB seeding by the orchestrator"
  - test: "6. Win a study quest with the roll forced -> «Conoscenza appresa: <nome>» on the result sheet; the page appears in its book (LORE-02; D-10)"
    expected: "Knowledge line on the sheet and the page in its book"
    why_human: "needs the BE study roll forced through LORE_STUDY_CHANCE and a seeded study quest"
  - test: "7. Delete the character and create a new one -> the Library is back to the birth geography only, no «Nuovo» marks, the enemies of step 4 are silhouettes again (LORE-03; D-07, BE D-01)"
    expected: "Full reset: birth geography only, no marks, silhouettes again"
    why_human: "needs the real deletion and creation flow and a new Character document on the BE"
  - test: "8. (optional) Lose against an unknown enemy -> the silhouette stays on the result sheet and no lore line appears (LORE-02; D-09)"
    expected: "Silhouette stays, no lore line"
    why_human: "needs a lost combat outcome seeded by the orchestrator"
---

# Phase 17: Unlockable Lore (frontend companion) - Verification Report

**Phase Goal:** The Library shows only what the character has discovered and unknown enemies appear as a black silhouette with their name only on quest and result sheets; the result sheet lists the lore unlocked by the outcome; an unknown city opens a name-only modal on the Map; all unlock state is owned by the backend (BE Phase 16), the FE renders ids, flags and lists and computes nothing.
**Branch:** feat/17-unlockable-lore @ 051341c (base develop f560d1d)
**Verified:** 2026-11-07T12:46:00Z
**Status:** human_needed
**Re-verification:** No, initial verification.
**Scope note:** plans 17-09 (schema gate against the merged BE Phase 16) and 17-10 (device E2E, handoff, closure) are gated on the BE Phase 16 merge (CONTEXT D-13) and have not run. Their must-haves are listed under `deferred`, not as gaps. The branch must never run against a BE without Phase 16 (D-14).

## Evidence gathered (run by the verifier)

| Check | Result |
|-------|--------|
| `flutter test test/models test/repository test/graphql test/tool` | 1562 passed, "All tests passed!" |
| `flutter test test/screens` | 1459 passed, "All tests passed!" |
| `flutter test test/shared test/utils` | 333 passed, "All tests passed!" |
| `flutter analyze` | 50 issues, all info (0 error, 0 warning); baseline 50 held |

## Observable Truths

| # | Truth (ROADMAP success criteria) | Status | Evidence |
|---|---|---|---|
| 1 | Library lists only backend-filtered lore, refreshes live on an `unlockedLore` set change, hides empty sections, one status line for an empty book, «Nuovo» for entries new since the last opening, per character on device | VERIFIED (code and tests) | `CharacterFragment.statusFields` selects `unlockedLore`; `LibraryCubit` (`openBook`, silent `syncUnlockedLore`, `goToInitial`), `Library` `BlocListener<CharacterCubit>`, `LibraryDataPage` with «Le pagine di questo libro sono ancora bianche.», `LoreCard` ribbon, `SharedPreferencesLibraryBookmarksStore`; plan tests 17-05/06/07 green |
| 2 | Unknown enemy (`known == false`) shows a black silhouette with unchanged name lines; after a victory the result sheet shows enemies in clear and lists `loreUnlocked` lines | VERIFIED (code and tests) | `QuestEnemy.known` end to end and both fragments select `known`; `EnemyPortrait.known` with «Sagoma del nemico»; `QuestResult.loreUnlocked` and fragment `loreUnlocked { id name type }`; `QuestResultSheet` prefixes «Nuova pagina del Bestiario: » / «Conoscenza appresa: » |
| 3 | New character sees only birth geography; an unvisited city opens a name-only modal instead of crashing; reset on recreation; device UAT | VERIFIED in code, device half deferred | No `relatedLore!` left in `lib`; `UnknownCityModal` line «Non conosci ancora questa città.»; `MainScreenCubit.refreshCities()` silent, triggered by `BlocListener<CharacterCubit>` with `_hasUnlockedLoreChanged`; birth geography and reset are backend-owned and need the device E2E (human steps 1, 3, 7) |

**Score:** 3/3 criteria verified for the plans in scope; the device portions are `human_verification`.

## Required Artifacts

All created/modified production files of `git diff --name-only f560d1d..HEAD -- lib tool` exist, are substantive and wired (models, fragments, `library_book.dart`, `library_bookmarks_store.dart`, `LibraryCubit`/state, `library.dart`, data page, `lore_card.dart`, `library_book_art.dart`, `unknown_city_modal.dart`, `world_map.dart`, `main_screen*.dart`, `enemy_portrait.dart`, both sheets, `authenticated_shell.dart`, `main.dart`). No `tool/` file changed (the schema registry is untouched until 17-09).

## Key Link Verification

| From | To | Status | Details |
|---|---|---|---|
| `CharacterCubit` | `LibraryCubit.syncUnlockedLore` | WIRED | via `BlocListener` in `Library`, no cubit-to-cubit subscription |
| `CharacterCubit` | `MainScreenCubit.refreshCities` | WIRED | `main_screen.dart` `listenWhen: _hasUnlockedLoreChanged` |
| `EnemyPortrait.known` | quest sheet / result sheet | WIRED | strongest entry's own `known` |
| `QuestResult.loreUnlocked` | result sheet lines | WIRED | after «Magia appresa» |
| `City.relatedLore == null` | `UnknownCityModal` | WIRED | `world_map.dart` `_openCityLore` |
| `LibraryBookmarksStore` | `AuthenticatedShell`/`main.dart` | WIRED | created once in `main.dart` |

## Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| LORE-01 | Code and tests done; tick deferred to 17-10 (device steps 1, 2, 5) | Library cubit/page/store |
| LORE-02 | Code and tests done; tick deferred to 17-10 (steps 4, 5, 6) | silhouette, `known`, result lines |
| LORE-03 | Code and tests done; tick deferred to 17-10 (steps 1, 3, 7) | unknown-city modal, cities refresh |

No orphaned requirements: REQUIREMENTS.md maps LORE-01..03 only to Phase 17.

## Anti-Patterns Found

None in the phase files (no TODO/FIXME, no stubs, no empty handlers). Quality remarks belong to `17-REVIEW.md`.

## Gaps Summary

No gaps in what plans 17-01..17-08 promised. The phase is not closed: 17-09 and 17-10 are gated on the BE Phase 16 merge, and the device E2E with a player identity is the remaining human verification.

---

_Verified: 2026-11-07T12:46:00Z_
_Verifier: Claude (gsd-verifier)_
