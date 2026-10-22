---
phase: 06
slug: quest-accept-info-sheets
audited: 2026-10-22
status: secured
asvs_level: 1
block_on: high
threats_total: 54
threats_mitigated: 46
threats_accepted: 4
threats_transferred: 4
threats_open: 0
threats_open_blocking: 0
open_ids: []
---

# Phase 06 - Security (Quest Accept and Info Sheets, FE)

Audit of the `<threat_model>` blocks of plans 06-01..06-12 against HEAD of `feat/06-quest-accept-info-sheets` (after review fixes 0b4e6ae..19a2d2d and quick tasks 261022-f0n, 261022-qkx). Test run: `flutter test test/models/quest test/graphql test/repository test/screens/mainScreen test/shared/components/tear test/shared/components/cards test/screens/auth` = 1011 passed, 0 failed (the fixer ran the full suite: 1350 green, `flutter analyze` 0 errors). `.env` is untracked (`git ls-files` shows only `.env.example`).

Disposition: M = mitigate (verified in code + test), A = accept (logged below), T = transfer (BE re-validates, documented below).

## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| client classifier / tear gesture -> BE `acceptQuest` | The client predicts and blocks; the BE is the only judge (lane, title, city, rank slots, points, atomic claim). The client never grants an acceptance. |
| server error -> UI | Rejections are mapped by `extensions.code` only; the player sees fixed Italian copy, never message text or exception text. |
| hand-edited quest catalogue -> app parser/renderer | Every field may be malformed; parsing and rendering are tolerant per element. |
| FE documents <-> BE schema | Contract drift is gated by the schema check before editing documents. |

## Threat Verification

| Threat | Cat. | Sev. | Disp | Status | Evidence (file:line) | Test |
|--------|------|------|------|--------|----------------------|------|
| T-06-01-01 | DoS | med | M | closed | `lib/models/quest/quest.dart:38-45` `tryFromJson` (non-map -> null, `on Object` -> null) | `quest_test.dart` tryFromJson cases |
| T-06-01-02 | Tampering | low | M | closed | `lib/models/quest/quest_capacity.dart` (D-32 mirror); only blocks the swipe (`board.dart:258` `canTear`) | `quest_capacity_test.dart` |
| T-06-01-03 | Info disc. | low | M | closed | `lib/graphql/fragments/character_fragment.dart:84-104` lane quests select `quest { id }` only | `character_fragment_test.dart` |
| T-06-01-04 | Repudiation | low | M | closed | requirement amendments recorded in REQUIREMENTS/CONTEXT (D-ids) before code | doc review |
| T-06-02-01 | EoP | med | T | closed | BE re-validates (Phase 7 D-18, Phase 8 D-32); client `canTear` only blocks (`tearable_paper.dart:99,114`) | `quest_availability_test.dart` |
| T-06-02-02 | Tampering | low | A | closed | logged below; null balance -> available | classifier null-balance cases |
| T-06-02-03 | Info disc. | low | M | closed | `quest_blocked_reason.dart`, fixed copy per enum value | `quest_blocked_reason_test.dart` |
| T-06-02-04 | DoS | low | A | closed | logged below | `board_policy_test.dart` |
| T-06-03-01 | Spoofing/EoP | high | M | closed | `board.dart:279-281` `accept(characterId: viewer.characterId)`; `quest_viewer.dart:21` `characterId: character.id` (session `CharacterLoaded`), no input path; `FORBIDDEN` -> `forbidden` (`quest_acceptance_failure.dart:65`) | `quest_acceptance_failure_test.dart`, `board_acceptance_test.dart` |
| T-06-03-02 | Tampering | med | M | closed | `quest_acceptance_cubit.dart:20` `state is QuestAccepting` guard; BE conditional claim | cubit "second accept ignored" |
| T-06-03-03 | Info disc. | med | M | closed | `quest_acceptance_failure.dart:50-68` switch on `graphQlErrorCode` only; `quest_acceptance_notice.dart` fixed copy; `toString` prints enum name | `quest_acceptance_failure_test.dart`, `quest_acceptance_notice_test.dart` (message text ignored) |
| T-06-03-04 | Tampering | med | M | closed | `graphql.dart:454-465` returns `void`, `successful != true` -> `FormatException`; lanes/balance only via subscriptions | `quest_mutations_test.dart`, service test |
| T-06-03-05 | DoS | low | M | closed | `quest_acceptance_cubit.dart:20` `isClosed` guard + `SafeEmit` | cubit "after close" |
| T-06-03-06 | Spoofing | low | A | closed | logged below; `unauthenticated -> null` (`quest_acceptance_notice.dart:46`) | notice test |
| T-06-04-01 | Info disc. | med | M | closed | `quest_acceptance_outcome_listener.dart:60-69` publishes `questAcceptanceNoticeFor`, never exception text | notice/listener tests |
| T-06-04-02 | DoS | low | M | closed | `in_app_notifications_cubit.dart:63-70` `publishNotice` dedup key + single queue | cubit "same key within window ignored" |
| T-06-04-03 | Tampering | low | M | closed | notice tap calls `dismiss()` only (no router) | shell test "intent sink receives nothing" |
| T-06-04-04 | DoS | med | M | closed | push suite unchanged and green (`test/screens/auth`) | existing cubit suite (green in this run) |
| T-06-05-01 | Tampering | med | M | closed | `tear_gesture.dart:4-5` (0.45 travel, 0.35 fling); `tearable_paper.dart:99-114` | `tearable_paper_test.dart` short/right/vertical drags |
| T-06-05-02 | Tampering | med | M | closed | `tearable_paper.dart:69,85,130-134` `_isTorn` latch before `onTorn`, `_ignoresDrag` | "second drag after commit" |
| T-06-05-03 | DoS | low | M | closed | `tearable_paper.dart:85` `!isEnabled` ignores drags; `board.dart:259` `isEnabled: isIdle` | "isEnabled false" |
| T-06-05-04 | EoP | low | M | closed | `tearable_paper.dart:99,114,121` (IN-05 fix also zeroes velocity when `!canTear`) | "canTear false", "hard fling never overshoots the cap" |
| T-06-06-01 | DoS | low | M | closed | `quest_info_sheet.dart:138` `errorBuilder: SizedBox.shrink` | widget test enemy/no enemy |
| T-06-06-02 | Tampering | low | T | closed | advisory indicators; BE judges, banner corrects (06-10) | view-model tests |
| T-06-06-03 | Info disc. | low | M | closed | `quest_sheet_details.dart` slot lines are counts per rank, no character ids | `quest_sheet_details_test.dart` |
| T-06-06-04 | DoS | low | M | closed | conditional blocks on null lore/enemy/loot; WR-03 fix null-guards `LootItem.power` (`loot_item_card.dart`) | "without lore/enemy/loot" cases, `loot_item_card_test.dart` |
| T-06-07-01 | DoS | med | M | closed | `graphql.dart:162-164` `Quest.tryFromJson` per element, logs id only | `graphql_board_data_test.dart` mixed list |
| T-06-07-02 | DoS | med | M | closed | `quest_cubit.dart:48-79` no `QuestLoading`, previous data kept on failure; WR-02 single city retry (`:71-75`, cancelled on refresh/`close()`) | quest_cubit tests incl. `city retry` group |
| T-06-07-03 | Tampering | low | M | closed | refresh on Board open (`board.dart:59`) and after stale failures (listener `_staleListFailures`: full, alreadyTaken, notFound, timedOut); last call wins via `_refreshGeneration` | cubit "last call wins", listener tests |
| T-06-07-04 | Info disc. | low | M | closed | city query selects POI ids; G1 refs only after BE gate (`quest_queries.dart` enemy/lore, no `locations`/`Lore.type`) | `board_documents_test.dart` negatives |
| T-06-07-05 | Tampering | low | M | closed | `graphql.dart:176` `variables: {'id': cityId}` typed variable | document test |
| T-06-07-06 | Tampering | low | M | closed | `grep -c KlimmeckGraphQl quest_cubit.dart` = 0; depends on `QuestBoardRepository` | grep (this audit) |
| T-06-08-01 | EoP | low | M | closed | `main_screen.dart:196-212` `_isPageDisabled` guard in `onItemTap`; `satchel_availability.dart` | menu/satchel tests; BE `QUEST_NOT_IN_CITY` |
| T-06-08-02 | Tampering | low | M | closed | live `CharacterCubit` location read in guard and `BlocSelector` (`main_screen.dart:83`) | satchel availability tests |
| T-06-08-03 | DoS | low | A | closed | logged below | policy test "empty cities" |
| T-06-09-01 | Tampering | low | M | closed | `board.dart:133-134` `cityPointIds` only when `questState.cityId == city.id` | board test "cityId other" |
| T-06-09-02 | Tampering | low | M | closed | refresh on open (`board.dart:59`); selection by id; BE judges | board tests refresh + selection by id |
| T-06-09-03 | DoS | low | M | closed | no current city -> no papers (`_viewerOf` null path) | board test "quest POI, not a marker" |
| T-06-09-04 | Info disc. | low | M | closed | only torn/intact derived from counts; no ids rendered | sheet/board tests |
| T-06-10-01 | Spoofing | high | M | closed | `board.dart:279-281`, `quest_viewer.dart:21` (session character id) | `board_acceptance_test.dart` asserts `accept(characterId: 'c-1', ...)` |
| T-06-10-02 | Tampering | med | M | closed | `board.dart:259` `isEnabled: isIdle` + cubit guard + `_isTorn` latch + BE conditional claim | "QuestAccepting disables the paper" |
| T-06-10-03 | Tampering | med | M | closed | navigation only on `QuestAccepted`; failure recomposes; lanes only from `characterUpdated`; mutation returns void | outcome tests |
| T-06-10-04 | Info disc. | med | M | closed | `questAcceptanceNoticeFor` fixed copy; repository wraps every throwable (`quest_acceptance_repository.dart:28-35`: `OperationException`, `TimeoutException` -> `timedOut`, `on Object` -> `unknown`); no print/log of exceptions in these files (grep) | outcome tests, repository tests ("maps any other error to unknown") |
| T-06-10-05 | EoP | med | T | closed | BE re-validates all rules | BE suites |
| T-06-10-06 | Tampering | low | M | closed | listener `_staleListFailures` -> `QuestCubit.refreshQuests` (`quest_acceptance_outcome_listener.dart:30-35,47-53`), mounted at `main_screen.dart:96` | listener tests |
| T-06-10-07 | Repudiation | med | M | closed | `QuestAcceptanceOutcomeListener` at MainScreen level publishes banner and resets | "rejection after leaving the Board still publishes the banner" |
| T-06-11-01 | Tampering | low | M | closed | no `Timer`/`DateTime.now` in `lib/models/quest`, `quest_info_sheet.dart`, `quest_paper_layer.dart` (grep empty) | label tests |
| T-06-11-02 | EoP | low | M | closed | `TearablePaper` is used only in `tabs/board/board.dart` (grep), not in the Map overlay | overlay test |
| T-06-11-03 | DoS | low | M | closed | `quest_paper_layer.dart` renders nothing for missing quest | layer test "q-missing" |
| T-06-12-01 | DoS | high | M | closed | BE gate + `tool/schema_check` 29/29 OK recorded in `06-12-SUMMARY.md`; tolerant parsers stay (T-06-01-01) | schema-check output |
| T-06-12-02 | Info disc. | med | M | closed | token read from `.env` into a variable, never echoed; SUMMARY records counts only; `.env` untracked | 06-12 SUMMARY/UAT review |
| T-06-12-03 | Tampering | med | T | closed | BE re-validates; E2E step 10 in `06-HUMAN-UAT.md` shows domain banners with rollback | UAT step 10 |
| T-06-12-04 | Repudiation | low | M | closed | ticks only for passed steps in `06-HUMAN-UAT.md` | doc review |
| T-06-12-05 | Info disc. | low | M | closed | `quest_queries.dart` selects `enemy { id name imagePath }` and `relatedLore { id name description }` only | `board_documents_test.dart` negatives |

## Key properties confirmed

- The client never grants acceptance: `canTear` only caps the gesture (`tearable_paper.dart:99,114`); success is signalled only by the BE (`successful == true`), and lane/balance state arrives only via subscriptions.
- Rejections are mapped by `extensions.code` only (`quest_acceptance_failure.dart:50-68`); the UI uses fixed Italian copy; `QuestAcceptanceException.toString` prints the enum name only.
- No token or user id is logged in the phase files: the only `debugPrint`s print a quest id (`graphql.dart:164`) or `error.runtimeType` (`quest_cubit.dart:85`).
- The repository wraps every throwable (WR-01 `timedOut`, IN-02 `unknown`); `timedOut` triggers the stale-list refresh.
- Tolerant parsing keeps the board alive against hand-edited catalogue data (per-element `tryFromJson`, `errorBuilder`, null guards).
- Double-fire is blocked at three layers: `_isTorn` latch, `isEnabled: isIdle`, and the cubit `QuestAccepting` guard (plus the BE conditional claim).

## Accepted risks log

| Threat | Rationale |
|--------|-----------|
| T-06-02-02 | Stale or null balance only makes the client block or allow a swipe wrongly; the BE judges (`INSUFFICIENT_POINTS`). Live value comes from `userUpdated`. |
| T-06-02-04 | Without a known city the board lists only worldMission/story by design (D-11); the board is reachable only from a marker. |
| T-06-03-06 | `UNAUTHENTICATED` raises no gameplay banner; the session flow refreshes or signs out. |
| T-06-08-03 | The satchel is built only in `MainScreenLoadData` (cities present); an empty city list disables the board by design. |

## Transfers

| Threat | Transferred to | Documentation |
|--------|----------------|---------------|
| T-06-02-01, T-06-10-05 | BE rule engine (Phase 7 D-18, Phase 8 D-32) | The BE re-validates lane, title, city, rank slots, points atomically; BE suites cover it. |
| T-06-06-02 | BE | Client indicators are advisory; BE rejection surfaces as a domain banner (06-10). |
| T-06-12-03 | BE | `06-HUMAN-UAT.md` E2E step 10 confirms rejections surface as banners with rollback. |

## Unregistered flags

None. No SUMMARY of plans 06-01..06-12 or of quick tasks 261022-f0n / 261022-qkx has a `## Threat Flags` section; 06-12-SUMMARY states no new threat surface.

## Notes (informational, non-blocking)

- Review IN-01: `QuestBoardRepository` passes exceptions through and `QuestError` may carry technical text, but nothing renders it today (board failures are silent and keep previous data). Tracked as a follow-up; becomes relevant if a board error UI is added.
- Review IN-03: the enemy image is `Image.asset` from a catalogue path; unknown paths are harmless (`errorBuilder`). The renderer choice awaits the BE contract.
- The 15 s client timeout does not cancel the request; a late BE success is reconciled via `characterUpdated` and the `timedOut` list refresh.

## Audit Trail

| Date | Auditor | Result |
|------|---------|--------|
| 2026-10-22 | gsd-security-auditor | 54/54 threats closed (46 mitigated, 4 accepted, 4 transferred), 0 open |
