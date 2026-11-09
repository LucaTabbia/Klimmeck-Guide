---
phase: 16-travel-ambushes
verified: 2026-11-06T18:51:00Z
status: human_needed
score: "4/4 ROADMAP success criteria verified in code and tests for plans 16-01..16-06; device E2E (16-08) pending"
overrides_applied: 0
re_verification:
  previous_status: none
  note: "Initial verification. No previous VERIFICATION.md existed."
gaps: []
deferred:
  - truth: "Contract names proved on the merged BE SDL (QuestResultKind, QuestResult.kind/quest/ambush, AmbushReport, AmbushCity, PushEventType ambushDefeat) and 45/45 documents valid against the merged BE schema"
    addressed_in: "Plan 16-07"
    evidence: "Gated on the BE Phase 15 PR merge (CONTEXT D-09); plan not run. Registry still lists 45 documents (test/tool green)."
  - truth: "Full flutter test + analyzer/format/trailer gates and 16-VALIDATION.md rows signed (wave_0_complete: true)"
    addressed_in: "Plan 16-07"
    evidence: "Gate plan not run; partial run here: test dirs models/repository/graphql/tool/screens/mainScreen/shared/utils green, analyze 0 error / 0 warning."
  - truth: "ambushDefeat payload documented in the BE handoff; BACKEND-NOTES.md"
    addressed_in: "Plan 16-08"
    evidence: "BACKEND-NOTES.md not yet written; waits for the BE handoff on origin/develop."
  - truth: "16-HUMAN-UAT.md, AMBUSH-01..03 ticked, ROADMAP/STATE closure"
    addressed_in: "Plan 16-08"
    evidence: "Human checkpoint gated on BE Phase 15 merge; REQUIREMENTS/ROADMAP rows still Pending by design."
human_verification:
  - test: "1. Won ambush on a free travel: start a travel >= 10 km, force a won ambush -> no push, no banner, the pawn keeps going on the same route; Journal «Punti vita» decreased; at arrival travelEnd push/banner, then on the free Map a one-page carousel (no «k di N») with «Vittoria», «Imboscata presso <città>», the enemies, the HP bar, «Ricompense» (coins) and «Esperienza»; no «Missione conclusa» banner (AMBUSH-02, AMBUSH-03; D-04, D-05, D-06)"
    expected: "As described"
    why_human: "BE timing (sweep, change stream, FCM) and ambushes forced at DB cannot be reproduced in widget tests; needs BE Phase 15 merged"
  - test: "2. Lost ambush on a quest travel: accept a hunt/enemy quest with a road marker, force a defeat -> push «Imboscata!» / «Sei stato sconfitto: la via torna verso <città>» with the app in background, in-app banner with the same text in foreground; tap -> Map centred on the pawn restarting from the ambush point with a new dashed route and remaining time towards that city; the Board quest lane is free (AMBUSH-01; D-02, D-03, D-10)"
    expected: "As described"
    why_human: "Real FCM delivery, live reroute on the phone and BE lane release"
  - test: "3. Arrival after the defeat: at the nearest city the carousel shows «Sconfitta», «Imboscata presso <città>», the HP bar down to the BE value, «Ferite», «Portato a <città>», no «Ricompense», no «Esperienza»; «Continua» closes; a cold restart shows nothing again (AMBUSH-02; D-04, D-05, D-13)"
    expected: "As described"
    why_human: "Needs real BE report and acknowledgement persistence across a cold restart"
  - test: "4. Two ambushes on one travel: win one, force a second (won or lost) -> at arrival one carousel «1 di 2», swipe -> «2 di 2», chronological; «Continua» on page 1 closes and acknowledges both; a cold restart shows nothing again (AMBUSH-02; D-05, D-11, D-12)"
    expected: "As described"
    why_human: "Real swipe feel and BE-side ordering/ack"
  - test: "5. Toggle «Imboscate» off in Settings, force a defeat -> no push, no banner; the pawn still restarts towards the nearest city and the carousel still opens at arrival; toggle back on (AMBUSH-01; D-02, D-10)"
    expected: "Only the push/banner dropped"
    why_human: "Push suppression depends on real FCM and BE category filtering"
  - test: "6. Before a travel that will be ambushed: the confirmation sheet shows exactly «Distanza, Durata, Arrivo, Cibo, Vita» and the quest «Viaggio» line is as in Phase 15 - no ambush wording anywhere (AMBUSH-03; D-07, D-17)"
    expected: "No ambush wording"
    why_human: "Confirms against a live BE preview (pinned in widget tests, but the device check is the contract)"
  - test: "7. (optional) GM teleport mid-travel with a held report -> after the teleport the carousel opens on the free Map (AMBUSH-02; D-06; BE D-13)"
    expected: "Carousel on the free Map"
    why_human: "Needs the admin teleport flow and a held BE report"
---

# Phase 16: Travel Ambushes Verification Report

**Phase Goal:** The pawn restarts from the ambush point towards the nearest city after a lost ambush (push + banner of a new category); the ambush reports of a travel open at arrival in a carousel of result sheets delivered through the never-lost pipeline; the confirmation sheet never reveals an ambush.
**Verified:** 2026-11-06T18:51:00Z
**Status:** human_needed
**Re-verification:** No - initial verification (plans 16-01..16-06 executed; 16-07/16-08 gated on the BE Phase 15 merge, not run)

## Goal Achievement

### Observable Truths (ROADMAP Phase 16 success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A BE-rewritten `activeTravel` moves pawn, dashed route and remaining time live; defeat push (new category, toggle) and banner lead to the Map | VERIFIED (code/tests); device in human step 2, 5 | `NotificationCategory.ambushDefeat('ambush_defeat','ambushDefeat')`, settings switch «Imboscate», popup registry `ambushDefeat: focusCharacterOnMap`; no FE copy of the text (grep «Sei stato sconfitto» in lib empty, title/body from BE). Reroute: zero lib change by design (research F6); proved by 16-06 characterization tests on `TravelProgressCubit` (4) and `WorldMap` (3) |
| 2 | Ambush `QuestResult` are sheet variants («Imboscata presso», «Portato a»), opened at arrival in one carousel per travel, chronological, acknowledged together on «Continua», on the free Map; quest results stay one at a time | VERIFIED (code/tests); device in human steps 1, 3, 4 | `QuestResultKind`/`AmbushReport`/`AmbushCity` + fragment selects `kind`/`ambush`; `QuestResultSheet` ambush header + reachedCity line; `QuestResultsState.presentable/showingGroup/isSettlingAmbushes` (head alone, else consecutive ambushes); cubit group presented/closed/dismissedExternally and chained settling read; `AmbushReportCarousel` (swipe-only PageView, one onContinue) wired in `QuestResultPresenter._present` |
| 3 | Confirmation sheet and quest «Viaggio» line never reveal an ambush; `travelEnd` leads to the Map where the carousel appears; no extra push | VERIFIED (code/tests); device in human steps 1, 6 | Pins in `travel_confirmation_sheet_test.dart` (2) and `quest_travel_line_test.dart` (1); presenter `if (arrival.isAmbush) return;` avoids a «Missione conclusa» banner; no ambush push other than defeat |
| 4 | (SC 2 tail) Tolerant/safe parsing: unknown kind reads as quest, malformed ambush dropped | VERIFIED | `QuestResultKind.fromWire` default quest; ambush parsed only for kind==ambush; tests in models green |

**Score:** 4/4 truths verified for the scope of 16-01..16-06.

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Contract names on merged SDL, 45/45 documents vs BE schema | 16-07 | gated on BE Phase 15 merge (D-09) |
| 2 | Full suite + analyzer/format/trailer gate, VALIDATION sign-off | 16-07 | gate plan not run |
| 3 | BACKEND-NOTES.md, `ambushDefeat` payload in BE handoff | 16-08 | waits for BE handoff |
| 4 | 16-HUMAN-UAT.md, AMBUSH-01..03 ticked, ROADMAP/STATE closure | 16-08 | human checkpoint |

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `lib/models/quest_result/{quest_result_kind,ambush_city,ambush_report}.dart`, `quest_result.dart` | VERIFIED | exist, substantive, used by fragment/sheet/cubit |
| `lib/graphql/fragments/quest_result_fragment.dart` | VERIFIED | selects `kind` and `ambush { at nearCity reachedCity }` |
| `lib/models/notification_category.dart`, settings section, popup registry | VERIFIED | wired end to end |
| `lib/shared/components/popup/quest_result_sheet.dart` | VERIFIED | `ambushPlaceKey`, `reachedCityKey` |
| `lib/shared/components/popup/ambush_report_carousel.dart` | VERIFIED | used by presenter |
| `quest_results_state.dart`, `quest_results_cubit.dart`, `quest_result_presenter.dart` | VERIFIED | group queue, settling, carousel branch |

### Key Link Verification

| From | To | Status | Details |
|------|----|--------|---------|
| fragment | QuestResult.fromJson | WIRED | kind/ambush parsed kind-gated |
| presenter | cubit `presentable`/`presented`/`closed` | WIRED | lines 118, 153, 176, 198 |
| presenter | AmbushReportCarousel | WIRED | `head.isAmbush ? _AmbushReportRoute` |
| registry | `focusCharacterOnMap` | WIRED | ambushDefeat entry |
| fragment | merged BE SDL | DEFERRED | 16-07 |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| models/repository/graphql/tool | `flutter test test/models test/repository test/graphql test/tool` | +1542 all passed (registry 45 documents) | PASS |
| screens/shared/utils | `flutter test test/screens/mainScreen test/shared test/utils` | +1327 all passed | PASS |
| analyzer | `flutter analyze` | 50 issues (info baseline), 0 error, 0 warning | PASS |
| trailers | grep Co-Authored/Generated with over `f560d1d..HEAD` | 0 | PASS |

### Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| AMBUSH-01 | SATISFIED in code/tests, device pending | category + toggle + tap focus; reroute characterization |
| AMBUSH-02 | SATISFIED in code/tests, device pending | sheet variant, group queue, carousel |
| AMBUSH-03 | SATISFIED in code/tests, device pending | pins + no ambush banner/push at arrival |

Checkboxes stay unticked until 16-08 (by design). No orphaned requirements.

### Anti-Patterns Found

None blocking in the phase files (no TODO/placeholder stubs; no hardcoded user-facing duplicate of BE push text).

### Human Verification Required

See frontmatter (7 device steps of 16-08, step 7 optional).

### Gaps Summary

No gaps for plans 16-01..16-06. The contract against the merged BE schema and the device E2E wait on the BE Phase 15 merge (16-07, 16-08).

---

_Verified: 2026-11-06T18:51:00Z_
_Verifier: Claude (gsd-verifier)_
