---
phase: 05-notifications-infrastructure
verified: 2026-10-20T20:00:00Z
status: passed
score: 5/5 roadmap success criteria verified (plus 9/9 plans' must-haves spot-checked)
overrides_applied: 0
re_verification: false
gaps: []
deferred:
  - truth: "Tap surfaces context popups (travel-end, quest-end, death) and the permission prompt call site at first travel confirmation"
    addressed_in: "Phase 7 / Phase 9"
    evidence: "ROADMAP SC 4 amended 2026-10-19; hook defaultNotificationPopups ready, ensureRequested() has no call site by design"
---

# Phase 5: Notifications Infrastructure Verification Report

**Phase Goal:** The app receives and displays push + in-app notifications for travel end, streamer live and quest end across all three app states, with permission requested contextually and taps routed uniformly to the Map tab.
**Verified:** 2026-10-20 | **Status:** passed | **Re-verification:** No (initial). Android only (user decision).

## Goal Achievement

| # | Truth (ROADMAP SC) | Status | Evidence |
|---|---|---|---|
| 1 | After login the FCM token is registered per-device; refresh handled | VERIFIED | `push_registration_coordinator.dart` (152 l), `push_device_repository.dart`, `push_mutations.dart`, `device_identity_store.dart` (UUID in `klimmeck.push.deviceId`). Unit tests green. UAT steps 3 (same deviceId across relaunch, lastSeenAt updated) and 9 (re-registration with same deviceId) |
| 2 | Permission requested in context, not at cold launch | VERIFIED (gate only, per scope) | `notification_permission_gate.dart` exists; `grep "ensureRequested("` in `lib/` outside the gate: 0 call sites; `Permission.notification` only in `permission_handler_notification_permission.dart`. UAT step 2: no prompt at launch/splash/sign-in/Settings. Call site is Phase 7 (documented in BACKEND-NOTES) |
| 3 | Travel-end, streamer-live, quest-end delivered/handled in killed, background, foreground | VERIFIED | `push_background_handler.dart` + `data_message_handler.dart` (background/killed), `foreground_push_events.dart` + `InAppNotificationsCubit` (foreground); UAT steps 5, 6, 7 passed for all three types; toggles-off suppression in all three states (step 8) |
| 4 | Tap routes to Map tab uniformly (amended: streamerLive opens Twitch; popups Phases 7/9) | VERIFIED | `notification_tap_router.dart`, `notification_intent_cubit.dart`, `notification_intent_landing.dart` (Map page 0), empty `defaultNotificationPopups` hook; `TwitchChannel.uri` constant only. UAT steps 5-7: Map tab / Twitch in all three states |
| 5 | Push + banner never both shown; banners use `KGNotification` | VERIFIED | Foreground never shows system notification; `InAppNotificationsCubit.publish` dedup; `kg_notification_banner.dart` has no SnackBar/MaterialBanner/Scaffold; same event -> same `stableNotificationId`. UAT step 5 dedup confirmed |

**Score:** 5/5

## Plan must-haves spot-check

| Plan | Check | Result |
|---|---|---|
| 01 | google-services plugin 4.5.0 in settings, WARN strategy in app build; `POST_NOTIFICATIONS` in manifest; `ic_stat_klimmeck.xml` and `raw/keep.xml` exist; `firebase_auth` gone, `uuid ^4.5.1` present; legacy `lib/utils/notification.dart` deleted | OK |
| 02 | All 7 model/config/util files present; wire names pinned (`wireType`), channel `klimmeck_events`, URL `twitch.tv/lordreavor` | OK |
| 03 | push mutations, repository, failure mapper, device/active-user stores present | OK |
| 04 | background handler, bootstrap with guarded `Firebase.initializeApp` (only call site is `push_bootstrap.dart`, with timeout), `PushServices`; boundaries test in suite | OK |
| 05 | Coordinator + `PushSessionCleanup`; `AuthCubit.logout` awaits unregister with 2 s timeout, failure only logged | OK |
| 06 | Gate, `NotificationPermissionCubit`, hint row present; no call site outside gate | OK |
| 07 | Intent cubit, tap router, landing, popup registry present | OK |
| 08 | Foreground events, in-app cubit, banner present | OK |
| 09 | UAT complete 10/10 (user-approved 2026-10-20), BACKEND-NOTES, VALIDATION present | OK |

## Behavioral checks run
- `flutter test`: 986 passing, all green.
- `flutter analyze`: 56 issues (all info/warnings of baseline, 0 errors, 0 in push/notification files); matches the <= 56 gate.
- `git diff origin/develop...HEAD -- lib/repository/services/auth`: empty (auth untouched, no regression).
- No `Co-Authored-By` trailers in branch commits (63 commits).
- Schema documents: `schema_check_documents_test.dart` passes (27 documents).

## Requirements Traceability

| Req | Plans | Status | Evidence |
|---|---|---|---|
| NOTIF-01 | 01,03,05,09 | SATISFIED | Registration coordinator + repository; UAT 3, 9 |
| NOTIF-02 | 06,09 | SATISFIED (gate; call site Phase 7 as scoped) | Gate, no cold-launch prompt, UAT 2, 4 |
| NOTIF-03 | 01,02,04,08,09 | SATISFIED | travelEnd in 3 states, UAT 5-7 |
| NOTIF-04 | 01,02,04,08,09 | SATISFIED | streamerLive (topic) in 3 states, UAT 5-7 |
| NOTIF-05 | 01,02,04,08,09 | SATISFIED | questEnd in 3 states, UAT 5-7 |
| NOTIF-06 | 02,07,09 | SATISFIED (amended SC 4) | Router/landing; UAT 5-7 |
| NOTIF-07 | 02,08,09 | SATISFIED | `KgNotificationBanner` on `KGNotification` |
| NOTIF-08 | 02,04,08,09 | SATISFIED | Foreground suppression, stable ids, cubit dedup; UAT 5 |

All 8 IDs are marked complete in REQUIREMENTS.md (lines 80-88, traceability row 209); no orphaned requirements.

## Anti-patterns
None blocking. No TODO/stub hits in the Phase 5 files inspected; empty `defaultNotificationPopups` is an intentional extension hook (Phases 7/9).

## Human verification
Already completed: `05-HUMAN-UAT.md` status complete, 10/10, approved 2026-10-20. Recorded finding: FCM topic subscription needs IAM `cloudmessaging.topicSubscriptions.create` on the BE service account. This is a BE/ops item, not an FE gap.

## Gaps Summary
None. Phase goal achieved within the stated scope (Android only; prompt call site and context popups deferred to Phases 7/9 by explicit decision).

_Verifier: Claude (gsd-verifier)_
