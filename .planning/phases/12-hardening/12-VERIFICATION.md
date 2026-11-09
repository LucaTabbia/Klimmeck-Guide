---
phase: 12-hardening
verified: 2026-11-09T18:34:30Z
status: human_needed
score: "10/10 ROADMAP success criteria verified in code and tests for plans 12-01..12-15 (criteria 2, 5-device half, 7-device half, 8-CI-run, 9-10 closure items deferred to the gated plans); device halves wait for 12-17"
overrides_applied: 0
re_verification:
  previous_status: none
  note: "Initial verification. No previous VERIFICATION.md existed."
gaps: []
deferred:
  - truth: "Contract names (SESSION_REVOKED + extensions.reason, WS close 4409, role-change revocation) proved on the merged BE Phase 17 files"
    addressed_in: "Plan 12-16"
    evidence: "REPO-RULES Gate: gated by the BE Phase 17 merge; the BE phase is executed in the other repo; FE code runs on fakes (12-14, 12-15)"
  - truth: "HARDEN-02 evidence: BE authorization matrix (11 innkeeper + 19 owner-only handlers) read in the BE handoff"
    addressed_in: "Plan 12-16"
    evidence: "ROADMAP criterion 2 delivered by the BE Phase 17 matrix; FE records it in the handoff"
  - truth: "45/45 documents validated against the BE schema (schema gate)"
    addressed_in: "Plan 12-16"
    evidence: "12-16-PLAN.md: dump + validate against BE origin/develop after the merge"
  - truth: "Full suite, guard script on the built APK, release build + bundle guard, format/trailer/sanity gates, 12-VALIDATION.md approval"
    addressed_in: "Plan 12-16"
    evidence: "12-16-PLAN.md; 12-VALIDATION.md checklist still unticked; no flutter build run by the verifier"
  - truth: "Code review by area (HARDEN-10 second half) with every finding fixed in TDD or deferred"
    addressed_in: "Review step between 12-15 and 12-16"
    evidence: "ROADMAP: review by area runs between the last code plan and the gate; reports written in parallel; HARDEN-10 ticked only if 12-REVIEW*.md exist (12-17-PLAN)"
  - truth: "12-HUMAN-UAT.md, BACKEND-NOTES.md, HARDEN-01..10 ticked, ROADMAP/STATE closure"
    addressed_in: "Plan 12-17"
    evidence: "12-17-PLAN.md: device UAT as a blocking human checkpoint; mark-complete only there; gated by the BE Phase 17 merge"
human_verification:
  - test: "1. Signing: flutter build apk --release --dart-define-from-file=env/tunnel.local.json -> no «WARNING: android/key.properties not found» line; apksigner verify --print-certs shows the user's certificate, not CN=Android Debug (HARDEN-08; D-03a)"
    expected: "No warning; the user's certificate"
    why_human: "needs the user's keystore in android/key.properties (outside VCS) and a release build, run in the gated plan"
  - test: "2. Release through the tunnel on the Samsung: adb uninstall, adb install -r app-prod-release.apk, real Twitch login, one quest or travel round trip, Settings -> Esci -> sign-in; adb logcat -c before, adb logcat -d -s flutter after prints zero lines; control: a dev debug build prints lines (HARDEN-08; D-03b/c, D-04)"
    expected: "Works end to end over TLS with zero Dart log lines in release"
    why_human: "needs a physical device, a TLS tunnel to the local BE and a real Twitch login"
  - test: "3. TLS fail-fast: flutter build apk --release --dart-define-from-file=env/dev.json (cleartext URLs), install -> only «Questa versione dell'app non può collegarsi al server in modo sicuro. Installa una versione aggiornata.», no button; then adb uninstall (HARDEN-08; D-03b, D-19)"
    expected: "Fail-fast screen with the exact copy and no button"
    why_human: "visual check on the release build on a device"
  - test: "4. Dev workflow untouched: with the usual dev .env (bypass on, innkeeper) flutter run --flavor dev -t lib/main_dev.dart -> instant login as before Phase 12; flutter run -t lib/main_dev.dart WITHOUT --flavor dev stops at start with «Run with --flavor dev» (HARDEN-07; D-01, D-16)"
    expected: "Instant dev login; assert message without the flavor"
    why_human: "needs a running device/emulator session and the local .env"
  - test: "5. DevTools memory snapshot: flutter run --profile --flavor dev -t lib/main_dev.dart with DEV_AUTH_ENABLED=false, real login, open Map, Journal, Library, snapshot A, Settings -> Esci, GC, snapshot B -> in B no instance of CharacterCubit, QuestCubit, WorldMapCubit, JournalCubit, LibraryCubit, ShopCubit, ..., the old WebSocketLink or the session StreamSubscriptions; screenshots of A and B attached (HARDEN-05; D-05)"
    expected: "No retained session objects after logout"
    why_human: "DevTools memory profiler on a profile build, interactive"
  - test: "6. Dual device, last login wins: Samsung and emulator on the same build, same real Twitch account; log in on the Samsung and open the Map; log in on the emulator -> within a minute the Samsung shows the sign-in screen with «Hai effettuato l'accesso da un altro dispositivo.», no crash, no spinner mid-session; the emulator keeps working (HARDEN-06; D-06, D-09, D-12)"
    expected: "First device replaced cleanly with the notice; second device live"
    why_human: "needs the BE Phase 17 live (WS close 4409, SESSION_REVOKED), two devices and a real Twitch account"
  - test: "7. Symmetry: log in again on the Samsung -> the emulator shows the same notice within a minute; the Samsung works (HARDEN-06; D-09)"
    expected: "Same notice on the emulator; Samsung works"
    why_human: "same dual-device setup against the real BE"
  - test: "8. Character removed and recreated elsewhere: with the Samsung logged in, the orchestrator archives the character BE-side with the write of deleteCharacter -> the Samsung goes to the creation page without a restart; create a new character -> fresh shell, nothing of the old character (HARDEN-06; D-11)"
    expected: "Creation page without restart; no old data after recreation"
    why_human: "needs a DB write by the orchestrator and the live subscription on a device"
  - test: "9. (optional) Account switch: logout and login with a second Twitch account -> whole shell rebuilt, nothing of the first account visible (HARDEN-06; D-11)"
    expected: "Full rebuild"
    why_human: "needs a second real Twitch account on a device"
  - test: "10. (optional) Role change: the orchestrator changes the user's role at DB (BE watcher) -> «Il tuo ruolo è cambiato, accedi di nuovo.» (HARDEN-06; D-12, BE Phase 17 D-06)"
    expected: "Role-changed notice on the sign-in screen"
    why_human: "needs the BE watcher live and a DB write"
  - test: "11. CI: the orchestrator reports the GitHub Actions run of refactor/12-hardening green (analyze, test, guard, release build, bundle guard) (HARDEN-09; D-07)"
    expected: "Green run"
    why_human: "needs the pushed branch/PR and a remote runner"
---

# Phase 12: Hardening (frontend companion) - Verification Report

**Phase Goal:** Close v1.0 with an intensive pass on bugs, security and concurrency: no dev bypass or .env in the production entry point, release signed, TLS-only and silent; session layer proven (atomic logout, single-flight refresh, no retained subscriptions/cubits); last login replaces the first with a specific notice and identity transitions rebuild the shell; parked follow-ups closed; review by area; CI guarding it all.
**Branch:** refactor/12-hardening @ 36102cf (base develop ac75702)
**Verified:** 2026-11-09T18:34:30Z
**Status:** human_needed
**Re-verification:** No, initial verification.
**Scope note:** plans 12-16 (gate vs the merged BE Phase 17) and 12-17 (device UAT + handoff) are gated on the BE Phase 17 merge and have not run: deferred, not gaps.

## Evidence gathered (run by the verifier)

| Check | Result |
|---|---|
| flutter test test/config | 20 passed |
| flutter test test/bootstrap | 14 passed |
| flutter test test/utils | 93 passed |
| flutter test test/repository | 845 passed |
| flutter test test/screens/auth | 176 passed |
| flutter test test/screens/signIn | 19 passed |
| flutter test test/screens/mainScreen | 1068 passed |
| flutter test test/screens/characterCreation | 104 passed |
| flutter test test/models, test/graphql, test/tool, test/helpers | 680, 152, 3, 18 passed |
| flutter analyze | 47 issues, all info (0 error, 0 warning); baseline 47 held |
| bash tool/hardening_check.sh | hardening_check: OK |

## Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | No token in prefs/logs/unencrypted disk; grep in CI | VERIFIED | hardening_check.sh OK; all print/debugPrint routed via appLog (none left outside app_log.dart); ci.yml runs the script |
| 2 | Admin endpoints 403 for non-innkeeper | DEFERRED (BE-owned) | BE Phase 17 matrix; evidence read at 12-16, recorded in 12-17 handoff |
| 3 | Logout atomic end to end | VERIFIED (tests) | test/repository/services/auth/logout_flow_test.dart present, suite green |
| 4 | Two 401 -> one refresh | VERIFIED (tests) | concurrent_unauthorized_refresh_test.dart present, suite green |
| 5 | Leak-tracking test + DevTools; dual-device UAT | VERIFIED in code, device half deferred | authenticated_shell_leak_test.dart, identity_transitions_test.dart, dual_session_revocation_test.dart, leak_tracking_bloc_observer.dart; 4409 handled in ws_reconnect_policy.dart; sign-in notices (replacedByNewLogin, roleChanged) in sign_in_screen.dart; human steps 5-8 |
| 6 | No DevAuth/DEV_AUTH/flutter_dotenv in lib/main.dart; no .env/DEV_AUTH in APK; dart-define URLs | VERIFIED in code, bundle half deferred | lib/main.dart is 3 lines on buildSessionAuthComposition; dev bypass only in main_dev.dart, dev_auth_composition.dart, dev_auth_token_service.dart (env_config/auth_token_service mention it in comments or a flag getter only); env/dev.json, env/prod.json; APK grep in 12-16 |
| 7 | Signing, TLS-only, silent logs, release via tunnel | VERIFIED in code, device half deferred | build.gradle.kts key.properties + logger.quiet warning + dev/prod flavors; requireSecureTransport first in bootstrapApp; InsecureTransportScreen; appLog silent in release; .gitignore ignores android/key.properties and env/*.local.json; human steps 1-3 |
| 8 | GitHub Actions workflow | VERIFIED in code, run deferred | .github/workflows/ci.yml: pub get, analyze, test, guard script, release build with env/prod.json, bundle guard; green run = human step 11 |
| 9 | Follow-ups closed (BAD_USER_INPUT, IMAGE_*, City.size) | VERIFIED | BAD_USER_INPUT mapped in all failure classifiers under lib/repository and quest_results_cubit; character_creation_failure.dart and messages; cityClass absent from lib; city_markers_layer.dart visibility from City.size; suites green |
| 10 | Cross-cutting review by area | DEFERRED | review runs between 12-15 and 12-16, reports in parallel |

**Score:** 10/10 criteria verified for the plans in scope (code and tests) with the deferred halves listed above.

## Required Artifacts

All created/modified production files of the diff ac75702..HEAD (lib/bootstrap, lib/config, lib/utils/app_log.dart, lib/main.dart, lib/main_dev.dart, android build.gradle.kts, env/*.json, tool/hardening_check.sh, ci.yml, pubspec.yaml, .gitignore, CLAUDE.md, failure classifiers, cubits) exist and are substantive and wired. Named tests present: logout_flow, concurrent_unauthorized_refresh, authenticated_shell_leak, identity_transitions, dual_session_revocation, entry_points, insecure_transport_screen.

## Key Link Verification

| From | To | Status | Details |
|---|---|---|---|
| main.dart | bootstrapApp + buildSessionAuthComposition | WIRED | read by hand |
| bootstrapApp | EnvConfig.requireSecureTransport | WIRED | first check, app_bootstrap.dart:19 |
| ws_reconnect_policy | 4409 recovery | WIRED | wsSessionRevokedCloseCode |
| SessionRejected.reason | sign-in notices | WIRED | auth_gate.dart / sign_in_screen.dart |
| ci.yml | tool/hardening_check.sh | WIRED | two steps, source and APK |

## Requirements Coverage

HARDEN-01..10: code and tests done for plans 12-01..12-15; ticks deferred to 12-17 (device E2E; HARDEN-02 needs the BE matrix evidence; HARDEN-10 needs the review reports). No orphaned requirements: REQUIREMENTS.md maps HARDEN-01..10 only to Phase 12.

## Anti-Patterns Found

None blocking in the phase files. Quality remarks belong to the review reports.

## Gaps Summary

No gaps in what plans 12-01..12-15 promised. The phase is not closed: 12-16 and 12-17 are gated on the BE Phase 17 merge, and the device E2E (release via tunnel, dual device, DevTools snapshot) is the remaining human verification.

---

_Verified: 
_Verifier: Claude (gsd-verifier)_
