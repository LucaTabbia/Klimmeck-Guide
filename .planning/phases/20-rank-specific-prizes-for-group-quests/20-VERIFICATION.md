---
phase: 20-rank-specific-prizes-for-group-quests
verified: 2026-11-13T21:08:28Z
status: passed
score: 12/12 must-haves verified
overrides_applied: 0
head: fd7eaced
base: develop
be_ref: 697d40a1
gate_source: 20-04-SUMMARY.md (not re-run by the verifier)
human_verification_source: 20-HUMAN-UAT.md (device UAT of 2026-11-13, user's words verbatim)
---

# Phase 20: Rank-Specific Prizes for Group Quests — Verification Report

**Phase Goal:** A group quest rewards every participant with a prize suited to their own rank: prizes are defined per rank among the ranks admitted by the quest and resolved by the backend for each participant; the app shows each viewer the prize of their own rank on the quest sheet and on the result sheet.
**Verified:** 2026-11-13T21:08:28Z
**Status:** passed
**Re-verification:** No — initial verification
**Branch / HEAD:** `feat/20-rank-specific-prizes` @ `fd7eaced` (base `develop`, 63 commits, working tree clean)

## Method and limits of this verification

- Goal-backward, on the code: every row below was checked by reading `lib/` and `test/` at HEAD, not the SUMMARY files.
- **Nothing was executed.** No `flutter test`, `flutter analyze`, `dart format` or build was run (hard constraint of the orchestrator). Test and analyzer numbers are quoted from the gate recorded in `20-04-SUMMARY.md`: full suite `+4339: All tests passed!`, analyzer 47 info / 0 warning / 0 error, schema check 46 x OK against BE `origin/develop` `697d40a1`, `hardening_check` OK. That gate is the source, not this report.
- The gate still describes HEAD: `git diff c0ebdd4b..HEAD -- lib test tool pubspec.yaml` is empty; the four commits after `c0ebdd4b` are documentation only.
- One static read of the BE SDL (`git -C <BE> show origin/develop:src/schema.gql`, ref `697d40a1`, no fetch) confirmed that the names the FE selects exist: `Quest.awaitingRescue: Boolean!`, `Quest.rankPrizes: [QuestRankPrizes!]!`, `QuestResult.turnsTotal / turnsCompleted / lastTurn: Int`, `lastTurnKind: DungeonTurnKind`, `stagesCleared / stagesTotal: Int`, `enum DungeonTurnKind`. This is a name check, not the 46-document validation.
- Human verification: the device UAT of 2026-11-13 recorded in `20-HUMAN-UAT.md` is accepted as the human verification, as instructed. No observation is added here.

## Truths verified in their final form (superseded during the UAT, no override)

These plan truths were replaced by user decisions recorded verbatim. They are verified as amended; no `overrides:` entry is used because the authoritative documents themselves were amended.

| Original truth | Final form verified | Source of the change |
|----------------|---------------------|----------------------|
| Turn-line copy with «turno» («Caduto al turno L di T…», «Ferito raggiunto al turno L di T», «Turni superati: C di T») (D-21, plan 20-02) | «Caduto al L° piano su T, in esplorazione / in uno scontro», «Soccorso effettuato al raggiungimento del L° piano su T», «Piani superati: C su T». The old strings count 0 in `lib` and `test` | user, verbatim, `20-UAT-FIX-02.md`; `20-REPO-RULES.md` copy table and ROADMAP SC 3 amended |
| D-15: no lock of the dungeon for others while the aid is open | A hunt / dungeon with `awaitingRescue` is torn and not acceptable for every viewer | user rule R-1, verbatim, quick `261113-aql` («Supersedes D-15») |
| Plan 20-01: «the plan changes no file under `lib/`»; REPO-RULES: «the FE mirrors of seat rules are NOT changed» | True for plan 20-01 itself. Later `_slotLinesOf` and the capacity helpers were changed to fold legends onto hero seats | `20-UAT-FIX-01.md`, deviation authorised by the orchestrator after the user saw «vedo Eroe 0/1» |
| Plan 20-03: «`QuestFragment` unchanged» | The `prizes { … }` selection is unchanged and `rankPrizes` is not selected; one field was added, `awaitingRescue` | quick `261113-aql` |
| Reason line «… quando il ferito è stato raggiunto.» | «Soccorso in corso: la missione riapre quando il soccorso si conclude.» | review ruling IN-03, `20-REVIEW-UAT-FIX.md` |
| Duration: minutes truncated | Rounded up to the whole minute from one minute on | review ruling WR-04 |

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | **SC 1 / RANKP-01.** The quest sheet (Board and Map) prints the prize block the BE serves, with today's rows (coins, prize item, pet line, cure lines); the app never chooses a block | VERIFIED | The only readers of the prizes in `lib` are `quest.prizes`: `lib/shared/components/popup/quest_info_sheet.dart:119, 340, 429-466` (coins, item card, pet line, cure) and `lib/models/quest/quest_sheet_details.dart:120` (pet line). No selector, merge or scaling exists. The Map sheet is the same widget with no viewer: `lib/screens/mainScreen/tabs/map/layers/quest_info_overlay.dart:54`. No spell row exists (D-23) |
| 2 | **D-22.** No `rankPrizes` read anywhere in `lib` (no model field, no parser, no selection) | VERIFIED | `grep -rn rankPrizes lib` = 0 matches; `lib/graphql/fragments/quest_fragment.dart:64-103` selects `prizes { prizeCoins xpPrize randomLoot prizeItem pet cure }` only; `lib/models/quest/quest.dart:40-42` parses `prizes` only |
| 3 | **SC 1.** A rank-up rereads the quests silently | VERIFIED | `title` is part of the quest scope: `lib/screens/mainScreen/components/quest_scope_listener.dart:13, 68`; the reread is `QuestCubit.refreshQuests` (`:56`), which never emits `QuestLoading` (`lib/screens/mainScreen/questCubit/quest_cubit.dart:57-93`) |
| 4 | **SC 2 / RANKP-02.** A mixed-rank boss shows one seat line per title in wire order, no «Qualsiasi rango» line without any-rank seats, «Titolo minimo: …» | VERIFIED | `lib/models/quest/quest_sheet_details.dart:199-221` (titles deduplicated in wire order; the any-rank line only when `exactSeatsOf(slots, null) > 0`), `:181-186` (minimum title) |
| 5 | **SC 2 / RANKP-02.** Registration and fullness are judged per seat title, with legends folded onto hero seats by ONE shared rule used both by acceptance and by the seat lines | VERIFIED | Single source in `lib/models/quest/quest_capacity.dart`: `exactSeatsOf` `:47`, `foldedCountsOf` `:55-67`, `anyRankOverflowOf` `:73-82`, `seatTitleOf` `:86-95`; `canRegisterWithTitle` `:35-44` is built on them; `_slotLinesOf` and `_viewerSeatTitleOf` use the same functions (`quest_sheet_details.dart:196, 204, 210-217, 238, 242`). No private duplicate left (`_foldedCountsOf` / `_seatTitleOf` = 0 matches) and no other `TitleType.legend` logic in `lib`. Availability goes through `isFullFor` (`quest_availability.dart:166-173`). The party counter «In attesa del gruppo k/N» counts every registered adventurer over every seat (`lib/models/quest/quest_state_label.dart:28-40`) |
| 6 | **SC 3 / RANKP-03.** The result sheet prints ONE dungeon-floor line from the BE fields with the final copy | VERIFIED | `lib/utils/quest_outcome_lines.dart:43-69`: `success` + aid + `lastTurn` → «Soccorso effettuato al raggiungimento del $last° piano su $total» (`:48-49`); `failure` + `lastTurn` → «Caduto al $last° piano su $total» + «, in esplorazione» / «, in uno scontro» / nothing (`:51-52, 65-69`); otherwise «Piani superati: C su T» (`:60-61`). Wired in the stages slot: `lib/shared/components/popup/quest_result_sheet.dart:172` (`..._turnsOrStages()`), `:461-466`, key `turnsKey` `:45`, existing `bodyMedium` style (no new chrome) |
| 7 | **SC 3.** Nothing on `rescued` / `death` / `gmCompleted`; without turn fields (or total ≤ 0) the sheet falls back to «Esplorazione: tappa N di M» | VERIFIED | `quest_outcome_lines.dart:45` (`total == null || total <= 0` → `null`), `:54-56` (the three outcomes → `null`, exhaustive switch); fallback `quest_result_sheet.dart:463-473` (stages line with `stagesKey`, nothing when `stagesTotal` is null) |
| 8 | **SC 3 / D-22.** Lenient parsing: a malformed turn field never drops the result; the FE never adds 1 and computes no share | VERIFIED | `lib/models/quest_result/quest_result.dart:195-198` (`_countFrom`: non-number → `null`, `:236`; `DungeonTurnKind.fromWire`), `lib/models/enums/dungeon_turn_kind.dart:7-8` (`asNameMap()`, non-string → `null`, never `byName`); fields in `toJson` `:282-285` and `props` `:325-328`. `lastTurn` and `turnsTotal` are interpolated as served; no arithmetic on turn fields in `lib`; no «proporzione» line |
| 9 | **SC 4 / D-22.** The four turn fields and `awaitingRescue` are selected in the fragments; every result document carries them | VERIFIED | `lib/graphql/fragments/quest_result_fragment.dart:115-121` (`stagesCleared stagesTotal turnsTotal turnsCompleted lastTurn lastTurnKind rescuedCharacters`), used by `quest_result_queries.dart:8, 19`, `quest_result_subscriptions.dart:8`, `pending_request_mutations.dart:10`; `lib/graphql/fragments/quest_fragment.dart:63` (`awaitingRescue`, once). Names present on BE `origin/develop` `697d40a1` (static read). Schema check 46 x OK: from the recorded gate |
| 10 | **Quick 261113-aql (supersedes D-15).** A quest with `awaitingRescue` is torn and not acceptable for every viewer, with its reason line; the open sheet cannot be dragged | VERIFIED | Parsed `lib/models/quest/quest.dart:47` (`== true`, lenient), `toJson` `:70`, `copyWith` `:90`, `props` `:102`; `lib/models/quest/quest_availability.dart:111` (after owner / prison / catalogue checks, before every viewer-dependent refusal), torn `:89`; reason `lib/models/quest/quest_blocked_reason.dart:10-11, 40`, printed through `QuestSheetDetails.blockedReason` (`quest_sheet_details.dart:104-106`) at `quest_info_sheet.dart:150-153`; Board `lib/screens/mainScreen/tabs/board/board.dart:246` (torn), `:329-334` (`canTear` false, `isEnabled` false) |
| 11 | **WR-01.** After a refused accept the list is reread silently, so a sheet locked meanwhile turns torn with its reason | VERIFIED | `QUEST_NOT_ACCEPTABLE` → `notAcceptable` (`lib/repository/quest_acceptance_failure.dart:14, 86`); `notAcceptable` in `_staleListFailures` (`lib/screens/mainScreen/components/quest_acceptance_outcome_listener.dart:31-38`) → `refreshQuests` (`:51, 61-62`), the silent reread of truth 3 |
| 12 | **UAT-FIX-03.** «Tempo richiesto» has no stray commas: only non-zero parts joined with «, », seconds only under the minute, rounded up | VERIFIED | `lib/utils/game_duration_format.dart:29-46` (`formatQuestDuration`), used at `quest_info_sheet.dart:330`; the old `getStringToShowFromDuration` counts 0 in `lib` and `test` |

**Score:** 12/12 truths verified

ROADMAP success criteria: SC 1 = truths 1-3; SC 2 = truths 4-5; SC 3 = truths 6-8; SC 4 = truth 9 + the recorded gate + `20-HUMAN-UAT.md`.

### Deferred Items

None. `Quest.rankPrizes` (the innkeeper's view of all blocks) is intentionally not consumed in this phase: Phase 21 prize step (D-22, ROADMAP §Phase 21). It is not a gap of Phase 20.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/models/enums/dungeon_turn_kind.dart` | `DungeonTurnKind` with lenient `fromWire` | VERIFIED | 9 lines, used by `quest_result.dart:198` and `quest_outcome_lines.dart:65-69` |
| `lib/models/quest_result/quest_result.dart` | four nullable turn fields, lenient, in `toJson` / `props` | VERIFIED | `:127-130, 195-198, 282-285, 325-328` |
| `lib/utils/quest_outcome_lines.dart` | `dungeonTurnLine` pure helper | VERIFIED | `:43-69`, called by the result sheet |
| `lib/shared/components/popup/quest_result_sheet.dart` | turn line in the stages slot, `turnsKey` | VERIFIED | `:45, 172, 461-474` |
| `lib/graphql/fragments/quest_result_fragment.dart` | four turn fields after the stages | VERIFIED | `:115-121` |
| `lib/graphql/fragments/quest_fragment.dart` | `prizes` unchanged, `awaitingRescue`, no `rankPrizes` | VERIFIED | `:63-103` |
| `lib/models/quest/quest_capacity.dart` | one shared seat / fold rule | VERIFIED | `:35-106` |
| `lib/models/quest/quest_sheet_details.dart` | seat lines and viewer seat on the shared rule | VERIFIED | `:191-243` |
| `lib/models/quest/quest.dart`, `quest_availability.dart`, `quest_blocked_reason.dart` | served rescue lock, availability, reason | VERIFIED | see truth 10 |
| `lib/screens/mainScreen/tabs/board/board.dart` | locked sheet not draggable | VERIFIED | `:334` |
| `lib/screens/mainScreen/components/quest_acceptance_outcome_listener.dart` | silent reread on `notAcceptable` | VERIFIED | `:37` |
| `lib/utils/game_duration_format.dart` | `formatQuestDuration` | VERIFIED | `:29-46` |
| `test/helpers/fixtures/quest_fixtures.dart` | `mixedBossJson` / `buildMixedBoss`, `awaitingRescue` param | VERIFIED | `:38, 66, 179, 196` |
| `test/helpers/fixtures/quest_result_fixtures.dart` | turn params, `aidDungeonResultJson` | VERIFIED | `:247` |
| `20-HUMAN-UAT.md`, `BACKEND-NOTES.md` (§3, §4), `20-VALIDATION.md` (Approval) | closing documents | VERIFIED | present; UAT `status: complete`; validation approved 2026-11-13 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `quest_result.dart` | `dungeon_turn_kind.dart` | `DungeonTurnKind.fromWire(json['lastTurnKind'])` | WIRED | `quest_result.dart:198` |
| `quest_result_sheet.dart` | `quest_outcome_lines.dart` | `dungeonTurnLine(_result)` in the stages slot | WIRED | `quest_result_sheet.dart:462`, called from `_content()` `:172` |
| `quest_result_fragment.dart` | `QuestResult.fromJson` | selected names = parsed keys | WIRED | fragment `:117-120` ↔ model `:195-198` |
| `quest_result_fragment.dart` | BE SDL `QuestResult` | four fields present on `697d40a1` | WIRED | static read of the SDL; 46 x OK from the recorded gate |
| `quest_fragment.dart` | `Quest.fromJson` | `awaitingRescue`, `prizes` | WIRED | fragment `:63-64` ↔ `quest.dart:40-47` |
| `quest.dart` | `quest_availability.dart` → `quest_blocked_reason.dart` → `quest_info_sheet.dart` | flag → availability → reason line | WIRED | `quest_availability.dart:111`, `quest_blocked_reason.dart:40`, `quest_sheet_details.dart:104-106`, `quest_info_sheet.dart:150-153` |
| `quest_acceptance_failure.dart` | `quest_acceptance_outcome_listener.dart` → `QuestCubit.refreshQuests` | `QUEST_NOT_ACCEPTABLE` → `notAcceptable` → silent reread | WIRED | `:86` → listener `:37, 51, 61` → cubit `:61` |
| `quest_sheet_details.dart` | `quest_capacity.dart` | `foldedCountsOf` / `seatTitleOf` / `anyRankOverflowOf` / `exactSeatsOf` | WIRED | `:196-217, 238, 242` |
| `quest_info_sheet.dart` | `game_duration_format.dart` | `formatQuestDuration` | WIRED | `:330` |
| `quest_scope_listener.dart` | `QuestCubit.refreshQuests` | title in the scope record | WIRED | `:68` → `:56` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| Quest sheet rewards area | `quest.prizes` | `quests` / `OnQuestUpdated` through `QuestFragment.fields` → `Quest.fromJson` | Yes — block resolved by the BE per viewer; seen on the device (UAT steps 1, 3, 7, 10) | FLOWING |
| Result sheet turn line | `turnsTotal`, `turnsCompleted`, `lastTurn`, `lastTurnKind` | three result documents through `QuestResultFragment.fields` → `QuestResult.fromJson` | Yes — DB readings 8/1/2 `fight`, 8/2/2 `fight`, 8/8/8 `fight` matched the lines seen (UAT steps 6, 8, 9, 11, 12) | FLOWING |
| Board torn sheet + reason | `quest.awaitingRescue` | `quests` through `QuestFragment.fields` | Yes — seen on the device (UAT steps 7, 9, 10) | FLOWING |
| Seat lines | `requiredAdventurers`, `registeredAdventurers` | `QuestFragment.fields` `:39-49` | Yes — seen on the device (UAT steps 1-3) | FLOWING |

### Behavioral Spot-Checks

Step 7b: SKIPPED by constraint — the orchestrator forbids running tests, analyzer or builds in this verification. Recorded gate used instead (`20-04-SUMMARY.md`, re-run on BE `697d40a1`): full suite 4339 green, analyzer 47 info / 0 warning / 0 error, schema check 46 x OK, `hardening_check` OK. No code changed after that gate (see Method).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Code | Tests |
|-------------|-------------|-------------|--------|------|-------|
| RANKP-01 | 20-01, 20-04 | The quest sheet (Board and Map) shows the prize block the BE serves, with today's rows; the app never chooses a block | SATISFIED | truths 1-3 | `test/shared/components/popup/quest_info_sheet_test.dart:1207` (served block for paladin, adventurer, hero and no viewer), `:1240` (a `rankPrizes` payload changes nothing), `:1265` (no spell row), `:1285` (cure lines); `test/screens/mainScreen/tabs/map/quest_info_overlay_test.dart:88` (Map sheet, no viewer); `test/models/quest/quest_test.dart:368` (model ignores `rankPrizes`); `test/graphql/board_documents_test.dart:97` (fragment keeps `prizes`, never selects `rankPrizes`); `test/screens/mainScreen/components/quest_scope_listener_test.dart:128` (a new title rereads the quests) |
| RANKP-02 | 20-01, 20-04 | Mixed-rank bosses: one seat line per title, registration and party counter judged per seat title as the BE does | SATISFIED | truths 4-5 | `test/models/quest/quest_sheet_details_test.dart:573, 586, 595` (lines per title, no any-rank line, minimum title), `:215-348` (legend fold, 8 cases incl. WR-03 registration order); `test/models/quest/quest_capacity_test.dart:267, 285, 302, 312`; `test/models/quest/quest_availability_test.dart:797, 807, 814`; `test/models/quest/quest_state_label_test.dart:140` («In attesa del gruppo 1/3») |
| RANKP-03 | 20-02, 20-03, 20-04 | Result sheet: one dungeon line from the BE fields, lenient parsing, stages line as fallback | SATISFIED | truths 6-9 | `test/utils/quest_outcome_lines_test.dart:86-236` (every copy row, never +1 at `:166`, zero / negative total, `rescued`, `death`, `gmCompleted`); `test/shared/components/popup/quest_result_sheet_test.dart:1176` (one line in the stages slot, position asserted between enemies and HP), `:1212, 1230, 1239, 1276, 1287`; `test/models/quest_result/quest_result_test.dart:705-792` (lenient parsing, props, result kept); `test/graphql/quest_result_documents_test.dart:134, 144` |
| RANKP-04 | 20-03, 20-04 | Schema gate on the merged BE SDL, schema check green, device E2E | SATISFIED | truth 9; fragments | Gate recorded in `20-04-SUMMARY.md` (`GATE_OK` on `697d40a1`, 46 x OK, 4339 green) — not re-run here; device E2E in `20-HUMAN-UAT.md` (12 executed steps, all pass) |

Rules added during the UAT, each traced to code and tests:

| Rule | Code | Tests |
|------|------|-------|
| Quick 261113-aql — source quest of an open aid torn for everyone | truth 10 | `test/models/quest/quest_test.dart:327-366`; `test/models/quest/quest_availability_test.dart:547-670` (every title and no title, precedence IN-02, owner and prisoner keep their reason, no travel preview); `test/models/quest/quest_blocked_reason_test.dart:74-82`; `test/screens/mainScreen/tabs/board/board_test.dart:579-675` (torn, reason, `canTear` / `isEnabled` false, swipe never calls accept, lock brought and dropped by a reread list); `test/graphql/board_documents_test.dart:120` |
| WR-01 — silent reread after a refused accept | truth 11 | `test/screens/mainScreen/components/quest_acceptance_outcome_listener_test.dart:234` |
| UAT-FIX-03 / WR-04 — duration wording | truth 12 | `test/utils/game_duration_format_test.dart:29-85`; `test/shared/components/popup/quest_info_sheet_test.dart:1311-1318` («Tempo richiesto: 15 minuti») |

Orphaned requirements: none. `REQUIREMENTS.md` maps exactly RANKP-01..04 to Phase 20 and all four appear in the plans' `requirements` fields.

### Anti-Patterns Found

Scan of the 16 `lib` files changed on the branch (`TODO|FIXME|XXX|HACK|PLACEHOLDER`, `// ignore:`, `print(` / `debugPrint(`): 0 matches. No commit of the branch carries a `Co-Authored-By` / `Generated with` / `Claude-Session` trailer (count 0).

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/models/quest/quest_availability.dart` | 111 | The lock follows the served flag on any quest type, not only hunt / dungeon | Info | Intended (rule 4: the BE decides which quests carry the flag); tests cover hunt and dungeon |
| `lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart` | 30 | The refusal banner of a locked quest is the shared «Missione non disponibile, avvisa il locandiere» | Info | Open copy question left to the user in `20-HUMAN-UAT.md`; the sheet itself prints the specific reason after the reread |
| `lib/models/quest/quest_capacity.dart` | 24-29, 69-82 | FE-only tolerance: unknown-rank registrations count on the any-rank seats, the BE skips them | Info | Documented in the code (IN-04); pre-existing behaviour |

No blocker, no warning.

### Human Verification

Accepted from `20-HUMAN-UAT.md` (device UAT of 2026-11-13, Android via USB, BE `7f3506ac` then the quick-task branch later merged as `697d40a1`; results in the user's words). Status of that record: complete, twelve executed steps pass (step 3 after `20-UAT-FIX-01`; steps 7, 8, 10 with findings fixed during the session). No new human item is raised by this verification.

Observed on the device (as recorded there): served rank block per character and the D-18 fallback for the legend (steps 1, 3); mixed boss seat lines, registration and «In attesa del gruppo 1/2» (steps 2, 3); boss win paid by block (step 4, DB reading); lost fight without rescue (step 5, on an artificial job); dungeon fall line (steps 6, 9); source dungeon torn with the lock line and the aid sheet with the real share (steps 7, 10); rescuer line (steps 8, 11); «Tempo richiesto: 8 secondi» (step 11); «Piani superati» on a cleared dungeon (step 12).

**Not observed on the device, covered by tests** (as that file states, plus what this verification found):

| Item | Device status | Coverage |
|------|---------------|----------|
| P3 — the same quest opened from the Map | not executed | `quest_info_overlay_test.dart:88` |
| P4 — «torn as full» half (no seat for the viewer's rank) | not executed | `quest_capacity_test.dart:312`, `quest_availability_test.dart:814` |
| P2 — title change at DB on an open sheet | replaced by an identity switch between two characters | `quest_scope_listener_test.dart:128` |
| P7 — wounded side («Sei stato salvato», label gone) | DB only | no turn line on `rescued`: `quest_outcome_lines_test.dart:215`, `quest_result_sheet_test.dart:1276` |
| P8 — a result without turn fields (fallback «Esplorazione: tappa N di M») | not observed (no such result generated) | `quest_result_sheet_test.dart:1239`, `quest_outcome_lines_test.dart:197` |
| Fall in an exploration turn («…, in esplorazione»), unknown kind, missing `lastTurn` | not observed (the BE placeholder never fails an exploration) | `quest_outcome_lines_test.dart:86, 114, 175` |
| `death` and `gmCompleted` results with turn fields | not observed | `quest_outcome_lines_test.dart:222, 236`, `quest_result_sheet_test.dart:1276` |
| Malformed turn fields on the wire | not observable on a device | `quest_result_test.dart:759-792` |
| Two legends on the same boss: viewer highlight by registration order (WR-03, marked «requires human verification (logic)» in `20-REVIEW-UAT-FIX.md`) | not observed (one legend in the session) | `quest_sheet_details_test.dart:292, 314` |
| Sub-hour durations other than 8 s («15 minuti», «1 ora, 16 minuti», …) | only «8 secondi» seen | `game_duration_format_test.dart:29-85`, `quest_info_sheet_test.dart:1318` |
| Reread after a refused accept on a quest locked meanwhile (WR-01) | not recorded as a device step | `quest_acceptance_outcome_listener_test.dart:234`, `board_test.dart:636` |
| The lock on a hunt | only a dungeon was locked on the device | `quest_availability_test.dart:553`, `board_test.dart:593` |
| P12 (archiver release, D-16), P13 (non-caster spell, D-05b) | not executed (optional) | BE suite, per `20-HUMAN-UAT.md`; not verifiable from this repo |

### Gaps Summary

No gaps. Every roadmap success criterion, every plan must-have in its final form and every rule born during the UAT is present in the code, wired end to end and pinned by tests that assert the behaviour (not only existence).

Notes that are not gaps:

- **Declared limit (told to the user, WR-01):** the rescue lock is not live on an already open Board. The Board does not follow `questUpdated` for listed quests; the lock appears or disappears at the next list read (Board opening, scope change, map reread) or right after a refused accept.
- **Open questions left to the user, not blocking:** the banner copy on a refused locked quest; `Quest.rankPrizes` readable by every authenticated user (BE side).
- **Test and analyzer numbers are quoted, not measured,** by this verification (see Method).
- **BE-only rules** (D-05b, D-09, D-16, D-18 resolution, D-19, D-20 share) cannot be verified in this repo; the FE only prints what is served, and the device session showed the served values.

---

_Verified: 2026-11-13T21:08:28Z_
_Verifier: Claude (gsd-verifier)_
