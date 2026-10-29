---
phase: 09-combat-result-sheet
verified: 2026-10-28T00:00:00Z
status: human_needed
score: 8/8 success criteria verified in code and tests (plans 09-01..09-11); 10/10 requirement IDs accounted for; device E2E and schema-gated plans 09-12/09-13 pending by design
overrides_applied: 0
re_verification:
  previous_status: none
  note: "Initial verification. No previous VERIFICATION.md existed."
gaps: []
human_verification:
  - test: "One result per outcome (victory, failure, rescued, death, gmCompleted) delivered live while the player is on the Map tab"
    expected: "Full-screen parchment appears at once with the outcome header and ink; HP bar animates against maxLifePoints with counting numbers; consumables, spells, injuries (Italian labels), rewards, XP, level/title, spell learned and adventurers saved appear only where there is data; the only way out is the button (scrim, Android back, swipe ignored); a closed sheet never returns"
    why_human: "device E2E of the gated plan 09-13, after the BE 9.2 merge"
  - test: "Result produced while the app is closed (push lost or notifications off), then cold start and resume"
    expected: "The sheet appears over the Map at the next cold start or resume via the unacknowledged-results query; after the button it is acknowledged and not shown again"
    why_human: "device E2E of the gated plan 09-13, after the BE 9.2 merge"
  - test: "Death with the app killed, then reopen"
    expected: "The death sheet («È morto», button «Riposa in pace») shows over the loader on any tab; character creation appears only after the acknowledgement (BE keeps currentCharacter until then, no FE hold)"
    why_human: "device E2E of the gated plan 09-13, after the BE 9.2 merge"
  - test: "Started boss quest with an archived member"
    expected: "The quest stays torn on the Board until it concludes (BE 9.2 keeps the seats after the start; D-18)"
    why_human: "device E2E of the gated plan 09-13, after the BE 9.2 merge (this behaviour is entirely BE-side)"
  - test: "questEnd push tap from background and from killed state; in-app banner «Missione conclusa» from a non-Map tab"
    expected: "Tap lands on the Map tab and opens the sheet (questResult(id)); a tap for an already acknowledged result lands on the Map with no sheet; banner tap from another tab lands on the Map and opens the sheet"
    why_human: "device E2E of the gated plan 09-13, after the BE 9.2 merge"
  - test: "Wounded state after a lost fight (status.awaitingAid set) and the aid quest on the Board"
    expected: "«In attesa di soccorso» floats over the pawn; pawn drag, Board and Shop are disabled as during a travel; AWAITING_AID / SHOP_NOT_IN_CITY show the domain banner; the aid quest uses the combat sheet family (enemy, time, rank slots, party counter, abandon while waiting)"
    why_human: "device E2E of the gated plan 09-13, after the BE 9.2 merge"
---

# Phase 9: Combat Result Sheet - Verification Report

**Phase Goal:** When a quest resolves, the user sees a full-screen parchment with the outcome (HP before/after animated, consumables and spells used, injuries, rewards, XP with level and title changes, spell learned, adventurers saved), dismissed only with an explicit button and presented only on the Map tab; results queue by `resolvedAt` and arrive from the subscription, the `questEnd` push and the BE 9.2 unacknowledged-results query so none is lost; each closed sheet is acknowledged. The phase also closes the death flow, the «in attesa di soccorso» state and the `aid` quest as a combat sheet.
**Branch:** feat/09-combat-result-sheet @ 0e19269 (137 files changed, 69 commits vs origin/develop 6d8f4b9)
**Re-verification:** No, initial verification.
**Scope note:** by CONTEXT D-21 plans 09-12 (9.2 documents, registry 38, repository ports live) and 09-13 (phase gates, device E2E, traceability, closure) run only after BE Phase 9.2 (PR #15, open) is merged on BE `develop`. Their must-haves are deferred, not gaps. Today the shell wires `const NoPendingQuestResults()` / `const NoQuestResultAcknowledger()` on purpose (`lib/screens/auth/authenticated_shell.dart:192-193`).

## Evidence gathered (run by the verifier)

| Check | Result |
|-------|--------|
| `flutter test` (full, foreground) | 2432 passed, 0 failed ("All tests passed!") |
| `flutter analyze` | 52 issues, 0 errors (baseline 53, one fewer, none new) |
| Schema check: `dart run tool/schema_check/dump_documents.dart` then `validate_documents.js` against `git show origin/develop:src/schema.gql` of the BE (after `git fetch -q origin develop`; schema read through git only, BE working tree sources not read; BE `node_modules` used as NODE_PATH as the script header prescribes) | "dumped 36 documents", 36 lines, all `OK` (tail shows `OK quests.graphql`); registry test `the schema check registers 36 documents` passes |
| `grep -rlE 'acknowledgedAt\|ListUnacknowledgedQuestResults\|AcknowledgeQuestResult' lib/graphql` | only `lib/graphql/fragments/quest_result_fragment.dart`, line 7, a doc comment; no selection of the gated fields |
| `gsd-tools verify artifacts` on plans 01..11 | 01: 5/5, 02: 4/4, 03: 4/4, 04: 3/3, 05: 3/3, 06: 3/3, 07: 3/3, 08: 3/3, 09: 1/2, 10: 2/2, 11: 3/3. The single miss (09) is the test file `world_map_availability_test.dart` lacking the literal string `questSheetChanged`; the test covers the behaviour (quest paper and marker mark the map busy, drag, release, dispose cleanup) and `world_map.dart` calls `questSheetChanged` / `pawnDragChanged` (lines 141, 148-149, 349, 367, 439, 448). Cosmetic, not a gap |
| `gsd-tools verify key-links` on plans 01..11 | Tool reports false / "Invalid regex pattern" on regex-escaped patterns (`\\.`, `\\(`) even where the wiring exists. All 19 flagged links re-checked by hand with `grep -E`: each count >= 1 (AssetQuantity.fromJson, NotificationCategory.questEnd, AwaitingAid.tryFromJson, QuestResultSubscriptions.questResultReceived, questResultFailureFrom, transactionFailureFrom, TransactionOutcomeListener, notifyRestored, `_repository.watch/fetch`, fetchUnacknowledged/acknowledge, `restored`, requestUserRefresh, `.label`, pageChanged, questSheetChanged/pawnDragChanged, suppress, routeCoveredChanged, requestFromTap, QuestResultPresenter). All wired |
| `package:flutter/` import in `quest_results_cubit.dart`, `map_availability_cubit.dart`, `quest_result_delivery_ports.dart` | none (grep exit 0 matches). Models: not re-listed beyond the three cubits/ports above; the plan-level tests keep them Flutter-free |
| `DateTime.now`, TODO/FIXME/XXX in quest result cubit, presenter, sheet, models, repository, map availability cubit | none |
| REQUIREMENTS.md COMBAT-01..10 checkboxes | all 10 still `[ ]`; traceability row still `Pending`; `mark-complete` never run (expected, 09-13 ticks them) |
| Trailers `Co-Authored-By` / `Generated with` in `git log origin/develop..HEAD` | 0 |
| `git status --short` | clean at verification start |
| Backend repo | contract check performed only through `git show origin/develop:src/schema.gql`; 9.2 documents are 09-12's job |

## Success criteria (ROADMAP as amended 2026-10-27)

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Sheet at once on a free Map; banner «Missione conclusa» from other tabs leading to the Map and the sheet; `questEnd` push tap does the same via `questResult(id)` | VERIFIED in code and tests; device pending | `QuestResultPresenter` (`_canPresent`, `suppress(event.dedupKey)` when the head is presented at once, otherwise banner), `QuestResultsCubit.requestFromTap` wired from `notification_popup_registry.dart`, `QuestEndEvent` dedup key `questEnd\|<id>` shared with the foreground push; presenter mounted in `MainScreen` (09-11) |
| 2 | `hpBefore` vs `hpAfter` against `maxLifePoints`, life bar and counting numbers | VERIFIED in code and tests | `HpDeltaBar` with `TweenAnimationBuilder`, `healGreen` token (09-07); skip test passes |
| 3 | Consumables, spells, injuries with Italian labels, rewards, XP, level/title, spell learned, adventurers saved; one widget with header and ink per outcome | VERIFIED in code and tests | `QuestResultSheet` (five outcomes, sections not built without data), `QuestType.label`, injury labels pinned (09-01), 09-07 tests |
| 4 | Dismissed only with the button; scrim, back, swipe do nothing | VERIFIED | `barrierDismissible: false` and `PopScope(canPop: false)` in the presenter (lines 172-178); single button «Continua» / «Riposa in pace» (`quest_result_sheet.dart:426`) |
| 5 | FIFO by `resolvedAt`, one at a time, only when Map is free (no route above, no quest overlay, no pawn drag); pending open on entering the Map | VERIFIED in code and tests | `QuestResultsState` queue, `MapAvailabilityCubit` fed by `MainScreen.pageChanged`, `WorldMap` (quest sheet, drag), presenter `routeCoveredChanged` via `ModalRoute` observation (09-05/09-09/09-10) |
| 6 | Result produced while closed reappears at cold start/resume (9.2 query); a closed sheet is acknowledged and never returns | VERIFIED in the cubit against the ports; LIVE DELIVERY DEFERRED to 09-12 | Cubit has `refetchPending` on start, foreground and `ConnectionRestoredBus`, ack serialised FIFO and retried (`_retryPendingAcknowledgements`), local dedup by id; ports are the null objects until 09-12 swaps them, by design |
| 7 | Death: sheet on any tab (queue unlocked), creation only after the ack; `rescued` reads «Sei stato salvato» | VERIFIED in code and tests; device pending | `isUnlockedByDeath` makes the presenter ignore the Map gate (route cover still respected); `acknowledgeDeath` awaits the ack, requests a user refresh once; `CharacterUnavailable` handles the death cold start (09-08); no routing hold (D-13) |
| 8 | `status.awaitingAid`: label over the pawn, drag/Board/Shop disabled, banners; `aid` quest in the combat family; started quests torn (BE 9.2) | VERIFIED in code and tests for the FE part; BE seat rule device pending | `AwaitingAid` model on `CharacterStatus` and `CharacterFragment`; `AWAITING_AID` in `travel_failure.dart` / `quest_acceptance_failure.dart`; `TransactionFailure` with `SHOP_NOT_IN_CITY` and `TransactionOutcomeListener` in Shop; `character_marker_layer.dart` label and drag gate; `aid` moved in `lib/models/quest/quest_sheet_details.dart` with the inverted test. The "started stays torn" rule is BE-side (9.2), only observable on device |

**Score:** 8/8 success criteria verified in code and tests; SC6/SC7/SC8 have device-only parts listed under human verification.

## Decisions honoured (09-CONTEXT)

D-01 root-Navigator full-screen parchment, no AppBar (presenter dialog over the shell). D-02 bar plus counting numbers. D-03/D-04 one widget, header and ink per outcome, empty sections not built. D-05 button-only dismissal. D-06/D-07 Map-only presentation, immediate when the Map is free, no banner then (`suppress`). D-08 FIFO by `resolvedAt`, death unlocks the queue. D-09 three sources, one queue keyed by id (subscription, push intent, query port). D-10 ack at close, best-effort, retried; externally popped sheet returns to the queue (`dismissedExternally`). D-11 `questEnd` tap path (`requestFromTap`). D-12 the FE publishes the banner from the subscription event with `questEnd|<id>`. D-13 no routing hold: grep finds no hold logic; death handled by the ack only. D-14/D-15 death and rescued variants. D-16 wounded state. D-17/D-24 `aid` in the combat family. D-18 started quests torn: BE-side, no FE logic, device UAT. D-19 no UI phase (token-based, existing assets). D-20 TDD: tests present for models, cubit, ports, sheet, presenter, availability, shell wiring. D-21 develop against the proposed contract with null objects; gated documents not registered (36, not 38). D-22 Boy Scout notes (questEnd.id correction, stale `combatResult` comment) done in 09-02. D-23 `MapAvailabilityCubit` Flutter-free, shell-level.

## Requirements traceability

| ID | Plans declaring it | Status | Evidence |
|----|--------------------|--------|----------|
| COMBAT-01 | 03, 05, 06, 10, 11 (+12 gated) | SATISFIED in code; device pending | SC1 |
| COMBAT-02 | 07 | SATISFIED in code | SC2 |
| COMBAT-03 | 01, 07 | SATISFIED in code | SC3 |
| COMBAT-04 | 01, 07 | SATISFIED in code | SC3 |
| COMBAT-05 | 01, 07 | SATISFIED in code | SC3 |
| COMBAT-06 | 07, 10 | SATISFIED in code; device pending | SC4 |
| COMBAT-07 | 05, 06, 09, 10, 11 | SATISFIED in code; device pending | SC5 |
| COMBAT-08 | 02, 04, 06, 08, 10, 11 | SATISFIED in code; device pending | SC8 |
| COMBAT-09 | 03, 05, 06, 08, 10, 11 (+12 gated) | SATISFIED in the cubit against fakes; live delivery pending 09-12 | SC6, SC7 |
| COMBAT-10 | 02 (+13 gated) | SATISFIED in code (aid in the combat family); started-torn rule is BE 9.2, device pending | SC8 |

All ten IDs from the PLAN frontmatters exist in REQUIREMENTS.md (lines 142-151); no orphaned requirement. Checkboxes and the traceability row stay open on purpose: plan 09-13 ticks them after the device UAT. Expected, not a gap.

## Deferred to 09-12 / 09-13 (gated by BE 9.2, PR #15)

Not failures; the plans have not run by design (CONTEXT D-21).

| # | Must-have | State today |
|---|-----------|-------------|
| 1 | BE gate: `unacknowledgedQuestResults`, `acknowledgeQuestResult`, `QuestResult.acknowledgedAt` present in `origin/develop:src/schema.gql` as the first step | Not run (PR open) |
| 2 | `ListUnacknowledgedQuestResults` / `AcknowledgeQuestResult` documents, `acknowledgedAt` selected in the result fragment, registry 36 -> 38, all documents validate against BE `origin/develop` | Fragment and registry untouched (36 OK) |
| 3 | `QuestResultRepository` implements the two delivery ports; shell swaps the null objects | Shell still passes `NoPendingQuestResults()` / `NoQuestResultAcknowledger()` |
| 4 | Final gates (tests, analyze <= 53, format of touched files, no trailer) | Already green on this HEAD; re-run after 09-12 |
| 5 | Device E2E checkpoint (see human_verification) | Pending, human |
| 6 | COMBAT-01..10 ticked, roadmap rows closed, HUMAN-UAT and validation sign-off, handoff update | Pending |

## Anti-patterns

No blocker or warning found. No `DateTime.now`, no TODO/FIXME, no `package:flutter` in the cubits, ports or availability cubit, no empty handlers in the touched files scanned. The null objects in the shell are a documented gating device (D-21), not a stub: they are replaced by 09-12. Plan 09 artifact check misses a literal string in a test file only (see evidence).

## Human verification required

Six UAT items are listed in the frontmatter: one result per outcome, result produced while the app is closed, death with the app killed, started boss with an archived member, `questEnd` push tap and banner, wounded state and the `aid` quest. All need the device E2E of the gated plan 09-13, after the BE 9.2 merge. No observations are claimed here.

## Gaps summary

No automated gap in plans 09-01..09-11. Status is `human_needed` because the device E2E and the BE-9.2-gated plans 09-12 and 09-13 cannot run yet.

---

_Verified: 2026-10-28T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
