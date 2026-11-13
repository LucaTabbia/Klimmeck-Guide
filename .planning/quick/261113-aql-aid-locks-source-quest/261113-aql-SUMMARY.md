---
quick: 261113-aql
title: A hunt or a dungeon with an open rescue born from it is torn for everyone
date: 2026-11-13
branch: feat/20-rank-specific-prizes
commits: [2ba13273, 5ded49b4, 2a7effcd, f106ba29, 93cb09fd]
status: complete
---

# Quick task 261113-aql — the source quest of an open aid is torn for everyone

**User rule (2026-11-13), verbatim:**

> «Quando un personaggio attiva una aid a partire da una hunt o da un dungeon (quindi le uniche quest ripetibili che possono creare una aid) la quest che le ha generate deve risultare strappata e quindi non accettable, finché il soccorso non va a buon fine.»

User answers (options picked, 2026-11-13): locked **for everyone**; free again **whenever the aid closes** (rescue done, wounded dead by timeout, wounded archived); a lost rescue opens a new aid from the same quest and the lock continues.

**Supersedes D-15** of Phase 20 / BE Phase 21 («no lock of the dungeon for others while the aid is open»).

BE twin: quick `261113-aql`, BE branch `feat/quick-aid-locks-source-quest` (not touched from here, not awaited).

## What the app consumes

- `Quest.awaitingRescue: Boolean!` (additive, the same for every viewer), selected once in `QuestFragment.fields` → `quests` and `OnQuestUpdated`.
- Refusal of `acceptQuest`: the existing `QUEST_NOT_ACCEPTABLE` → `QuestAcceptanceFailure.notAcceptable` (no new code, no new mapping).
- `questUpdated` republishes the source quest at aid birth and closing, but the app follows `questUpdated` only for the viewer's own lane quest, so the lock is **not live on an open Board** (WR-01 of `20-REVIEW-UAT.md`): it shows at the next read of `quests` (Board opening, scope change of the viewer, map reread) or right after a refused accept, which now rereads `quests` silently (`QUEST_NOT_ACCEPTABLE` → `notAcceptable`, `5e8536b4`). Nothing in `QuestScopeListener` (the change does not travel on `characterUpdated`).

## Where the rule lives

- `lib/models/quest/quest.dart`: `awaitingRescue` (`json['awaitingRescue'] == true`: absent, `null`, `'true'`, `1`, `{}` → `false`, the quest stays) in `fromJson`, `toJson`, `copyWith`, `props`.
- `lib/models/quest/quest_availability.dart`: `QuestAvailability.awaitingRescue`, torn in `isSheetTorn`, not acceptable (so no travel preview either).
- `lib/models/quest/quest_blocked_reason.dart`: `questAwaitingRescueLine` = «Soccorso in corso: la missione riapre quando il soccorso si conclude.» (amended after the review, IN-03, `a30195c1`; the first text «… quando il ferito è stato raggiunto.» was the orchestrator's technical default).
- `lib/screens/mainScreen/tabs/board/board.dart`: the open sheet is not draggable (`isEnabled` false), like a `noEffect` sheet.

### Precedence (in `_availabilityOf`)

`tornForOwner` → `imprisoned` → catalogue checks (`type == null`, `_isCatalogueDefect` → `notAcceptable`) → **`awaitingRescue`** → `alreadyDone` → `titleMismatch` → `laneBusy` → `full` → `notInCity` → `insufficientPoints` → `noEffect` → `available`.

Right after the checks that depend only on the quest itself and before every viewer-dependent refusal: every viewer reads the same reason whatever title (none included), lane, city or balance. The lane owner keeps «Missione già accettata» and a prisoner keeps «Sei in prigione» (their own state wins, as for `noEffect`). Since the lock precedes `laneBusy`, `_failsOwnRequirements` needs no change.

The app never inspects aid quests: the lock is only the served boolean (CLAUDE.md rule 4).

## TDD

- RED `5ded49b4` (model, availability, reason): compile failures `The getter 'awaitingRescue' isn't defined for the type 'Quest'`, `No named parameter with the name 'awaitingRescue'`, `Member not found: 'awaitingRescue'` (QuestAvailability).
- GREEN `2a7effcd`.
- RED `f106ba29` (Board, fragment): 3 failures — the fragment pin (`Expected: an object with length of <1>`, `Actual: []`) and two Board tests (`openSheet.isEnabled` expected `false`, was `true`). Green in RED: «a dungeon awaiting its rescue is drawn torn, an unlocked one stays whole» — the torn state comes from `standingOf`, already GREEN in `2a7effcd`.
- GREEN `93cb09fd`.

## New tests (15, all titled `(quick 261113-aql)`)

- `test/models/quest/quest_test.dart` (3): true/false read; absent/malformed → false, quest kept; `toJson` round trip, `copyWith`, `props`.
- `test/models/quest/quest_availability_test.dart` (7): hunt and dungeon locked for every title and with no title (2); hunt and dungeon unchanged with `false`/absent (2); the lock wins over busy lane, other city, unknown city, a rank too low and no title — each viewer first proved refused without the lock (IN-02, `9c10ff00`; the «no points» viewer was dropped: hunt and dungeon pay no points); lane owner and prisoner keep their reason; no travel preview. The torn-sheet table gets the new value (existing test).
- `test/models/quest/quest_blocked_reason_test.dart` (1): the reason text for hunt and dungeon.
- `test/screens/mainScreen/tabs/board/board_test.dart` (3): locked dungeon and hunt torn, unlocked dungeon whole; open sheet prints the reason, `canTear` and `isEnabled` false, swipe never calls accept; when `questUpdated` clears the flag the sheet is whole, tearable, no reason line.
- `test/graphql/board_documents_test.dart` (1): `awaitingRescue` selected exactly once in `QuestFragment.fields`.

Fixture: `questJson` / `buildQuest` take `awaitingRescue` (key omitted when `null`).

## Gates

- `flutter test test/models/quest test/repository test/shared/components/popup test/screens test/graphql`: **+3195: All tests passed!**
- `flutter analyze --no-fatal-infos`: 47 info, 0 warning, 0 error (baseline).
- `sh tool/hardening_check.sh`: OK.
- Expected full suite: **4312** (4297 + 15); not run here.
- Schema check against the BE: NOT run (the BE `develop` SDL has no `awaitingRescue` until the twin is merged; the orchestrator runs it after that merge). GraphQL document registry still 46 (no new operation).

## Deviations

None. The map sheet (`QuestInfoOverlay`) is not touched: it shows the character's own lane quest with no viewer, so it prints no availability reason.

## Amendments after the review (2026-11-13)

The three sentences above on the live lock, the reason copy and the precedence test were corrected by plan 20-04 to match `20-REVIEW-UAT-FIX.md` and the notes at the bottom of `261113-aql-PLAN.md`. Review commits on the FE: `6596807b`, `5e8536b4`, `fee3690a`, `9c10ff00`, `2c1e0714`, `a30195c1`, `f13a542e`, `c0ebdd4b`. BE twin merged into BE `develop` (PR #37, `697d40a1`); the schema check then ran: `awaitingRescue` present, 46 × OK.
