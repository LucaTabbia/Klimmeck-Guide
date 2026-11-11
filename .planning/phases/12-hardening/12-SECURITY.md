---
phase: 12
slug: hardening
audited: 2026-11-09T20:00:00Z
status: secured
asvs_level: 1
block_on: high
threats_total: 56
threats_mitigated: 43
threats_accepted: 4
threats_transferred: 2
threats_open: 0
threats_open_blocking: 0
threats_deferred: 7
open_ids: []
deferred_ids: [T-12-47, T-12-48, T-12-49, T-12-50, T-12-51, T-12-52, T-12-54]
updated: 2026-11-09
---

# Phase 12 - Security (Hardening, FE)

Audit of the threat registers of plans 12-01..12-17 (56 rows, T-12-01..T-12-56) against HEAD `44bbc15` of `refactor/12-hardening` (base `develop` `ac75702`, review fixes of `12-REVIEW-FIX.md` included). Plans 12-16 (gate against the merged BE) and 12-17 (device UAT, handoff, traceability) are not executed: their process threats are DEFERRED, not open. BE-side guarantees the FE leans on (revocation at login, `4409` fan-out, `extensions.reason`, role watcher) are owned by BE Phase 17 (BE 17-CONTEXT D-01..D-06, D-12, D-13); the BE repo was not read. No command read `.env`, `google-services.json`, `android/key.properties` or environment variables. Implementation files read only; no git writes, no build, no directory-wide test run.

## Threat register

| ID | STRIDE | Component | Disposition | Evidence | Note |
|----|--------|-----------|-------------|----------|------|
| T-12-01 | EoP | `EnvConfig` / `flutter_dotenv` in prod `libapp.so` | mitigated | `lib/config/env_config.dart` has no `flutter_dotenv` import (cross-check 2: only doc comments and the `devAuthEnabled` getter match); `tool/hardening_check.sh` | enforced by CI |
| T-12-02 | InfoDisc | log calls in release | mitigated | `test/utils/app_log_test.dart:14` "stays silent in release (D-03)"; 0 direct log calls outside `app_log.dart` | |
| T-12-03 | InfoDisc | `isDebug`/`enableLogging` in release | mitigated | `lib/config/env_config.dart:113,131`; `test/config/env_config_test.dart:28` | defaults follow build mode |
| T-12-04 | EoP | `lib/main.dart` composing the dev bypass | mitigated | `test/bootstrap/entry_points_test.dart:42`; cross-check 2 (no `DevAuth*` in main/bootstrap) | |
| T-12-05 | EoP | barrel re-export of the dev service | mitigated | `test/bootstrap/entry_points_test.dart:74`; hardening_check OK | |
| T-12-06 | InfoDisc | exception objects in moved widget logs | mitigated | `lib/bootstrap/klimmeck_guide_app.dart:155,180` (`${e.runtimeType}`) | |
| T-12-07 | DoS | dev entry without `--flavor dev` | accepted | plan 12-02 (D-16): `assert(appFlavor == 'dev')` fails loudly in debug; no release dev build | |
| T-12-08 | InfoDisc/EoP | `.env` bundled in the release APK | mitigated | `pubspec.yaml:80` `default-flavor: prod`, `:86` flavored `.env` asset (`flavors: - dev`); CI bundle guard `ci.yml:38` | final bundle proof repeated in 12-16 (T-12-50) |
| T-12-09 | InfoDisc | signing secrets / tunnel URLs committed | mitigated | `git ls-files android/key.properties '*.jks' .env` empty; `grep -rn DEV_AUTH env/` = 0; `env/prod.json` URL-only; `e75e6ed` ignores `*.keystore` | |
| T-12-10 | Spoofing | release silently signed with debug keys | mitigated | `android/app/build.gradle.kts:16,66,72-75` (`hasReleaseKeystore`, `logger.quiet` WARNING); `945b580` warns only for release builds | local debug-key fallback accepted per D-03a; `apksigner` signer check is part of 12-17 UAT |
| T-12-11 | Tampering | executor creating the keystore | mitigated | only `test -f` in gradle (`:16`); no keystore tracked | |
| T-12-12 | InfoDisc/Tamp | release over `http://`/`ws://` | mitigated | `app_bootstrap.dart:17-35` check first in `bootstrapApp`; `env_config.dart:70`; `test/config/env_config_secure_transport_test.dart:28-86`; `test/bootstrap/insecure_transport_screen_test.dart:59,68,74`; `env/prod.json` three `https`/`wss` URLs | |
| T-12-13 | InfoDisc | hosts in error/logs | mitigated | `env_config_secure_transport_test.dart:51,102` | key names only |
| T-12-14 | DoS | false positive blocking a good release | mitigated | `env_config_secure_transport_test.dart:42` (https/wss accepted) | |
| T-12-15 | InfoDisc | session/push diagnostics in release | mitigated | all calls via `appLog`; `test/utils/app_log_routing_test.dart`; 0 raw log calls | |
| T-12-16 | InfoDisc | exception values in logs | mitigated | cross-check 5: every `appLog(... ${...})` hit is `.runtimeType` | |
| T-12-17 | InfoDisc | cubit/component logs in release | mitigated | same grep (cubits listed: journal, library, map, splash, quest, auth); `app_log_routing_test.dart` | |
| T-12-18 | EoP | dev bypass re-introduced | mitigated | `tool/hardening_check.sh` source + bundle greps; `ci.yml:34,38` | |
| T-12-19 | InfoDisc | token in SharedPreferences/logs | mitigated | `hardening_check.sh:20-22` allow-list and token-name grep; cross-check 6 (`session_store.dart` uses prefs only for `firstLaunchDoneKey`, `:83-85`) | |
| T-12-20 | InfoDisc | CI secrets | accepted | plan 12-07: workflow uses none; `grep -c "secrets\." ci.yml` = 0 | `ci.yml` also has read-only `permissions` and `concurrency` (`adfe9e7`) |
| T-12-21 | Tampering | weakened guard patterns | mitigated | `hardening_check.sh` unchanged in spirit, OK at HEAD; review ruling "never loosen a pattern" | |
| T-12-22 | InfoDisc/Spoof | logout leaving socket/client/token | mitigated | `test/repository/services/auth/logout_flow_test.dart:119,139,149,186,199` | |
| T-12-23 | DoS | concurrent 401 double refresh | mitigated | `test/repository/services/auth/concurrent_unauthorized_refresh_test.dart`; `session_auth_token_service_revocation_test.dart:129` | |
| T-12-24 | Repudiation | audit claims without evidence | mitigated | `12-08-SUMMARY.md:49-50` per-test green-at-first-run notes | |
| T-12-25 | InfoDisc | cubits/subscriptions surviving logout | mitigated | `test/screens/auth/authenticated_shell_leak_test.dart:378,407` | |
| T-12-26 | InfoDisc/Tamp | stale character state after cross-device change | mitigated | `test/screens/auth/identity_transitions_test.dart` | |
| T-12-27 | InfoDisc | push tap of user A routed to user B | mitigated | `notification_intent_cubit.dart:41-45`; `notification_intent_cubit_test.dart:122` | |
| T-12-28 | Repudiation | leak test that cannot fail | mitigated | `authenticated_shell_leak_test.dart:198,213` | |
| T-12-29 | InfoDisc | server error text shown | mitigated | classifiers read only `extensions.code` (`graphql_error_code.dart`); copy local | |
| T-12-30 | Repudiation | validation refusal as offline | mitigated | `badUserInput` in `lib/repository/*_failure.dart`; tests `travel_failure_test`, `spell_equip_failure_test`, `pet_equip_failure_test`, `transaction_failure_test` | |
| T-12-31 | Repudiation/UX | refusals swallowed | mitigated | `quest_result_failure.dart:14,40`; `quest_result_failure_test.dart` | |
| T-12-32 | InfoDisc | server message reaching UI | accepted | plan 12-11: only `extensions.code` read, copy local | |
| T-12-33 | Tampering | rejected portrait reused on retry | mitigated | `character_creation_cubit.dart:76-77,138,160`; `character_creation_cubit_test.dart` | |
| T-12-34 | InfoDisc | moderation reasons shown | mitigated | `character_creation_failure.dart:71` reads `code` only; `character_creation_failure_test.dart:109-128` | |
| T-12-35 | DoS | moderation outage blocks creation | mitigated | `character_creation_failure_test.dart:120`, `character_creation_repository_test.dart:190`; `character_creation_messages_test.dart` | |
| T-12-36 | DoS | push register retry loop | mitigated | `test/repository/push_device_failure_test.dart:89` | |
| T-12-37 | DoS | city without type crash | mitigated | `city_markers_layer.dart:50`; `city_markers_layer_test.dart:78` | |
| T-12-38 | Tampering | FE deciding city class | mitigated | visibility from served `City.size` only (`city_markers_layer.dart:50`) | CLAUDE.md rule 4 |
| T-12-39 | Spoofing | replaced device keeps session | mitigated | `session_auth_token_service_revocation_test.dart:289,308,253`; `dual_session_revocation_test.dart:106` | BE half transferred to BE 17 D-01 |
| T-12-40 | Tampering | malicious `reason` | mitigated | `auth_api_exception.dart:80-98` (strings only, only on `SESSION_REVOKED`); `session_auth_token_service.dart:390-391` unknown -> neutral; test `:341,367` | |
| T-12-41 | EoP | inferring revocation from 401 | mitigated | `auth_api_exception.dart` 401 -> `AccessTokenRejected`; only `SessionRejected` ends session | |
| T-12-42 | Repudiation | logout racing revocation | mitigated | `session_auth_token_service_revocation_test.dart:405`; `_endInFlight` single-flight (REVIEW-FIX A-IN-01) | |
| T-12-43 | Spoofing | replaced device keeps socket | mitigated | `ws_reconnect_policy.dart:8,38` (4409 routed like 4401); `dual_session_revocation_test.dart` | fan-out owned by BE 17 D-03 |
| T-12-44 | DoS | hot reconnect loop | mitigated | `ws_reconnect_policy_test.dart:222` | |
| T-12-45 | InfoDisc | offline device resuming revoked session | mitigated | `dual_session_revocation_test.dart` (connection_init refused 4409) | |
| T-12-46 | Tampering | close reason trusted | mitigated | `ws_reconnect_policy_test.dart:237` | |
| T-12-47 | Tampering | BE working tree | deferred | 12-16 (read-only `git -C show/log`) | gated on BE merge |
| T-12-48 | InfoDisc | BE `.env` / identities in handoff | deferred | 12-16 | |
| T-12-49 | Spoofing | FE constants drifting from BE contract | deferred | 12-16 schema/contract gate | |
| T-12-50 | EoP | dev bypass / `.env` in release APK | deferred | 12-16 fresh release build + bundle guard (CI runs the same guard at `ci.yml:38`) | |
| T-12-51 | Repudiation | approval without evidence | deferred | 12-16 SUMMARY gate outputs | |
| T-12-52 | InfoDisc | tunnel host/passwords in UAT docs and BE-NOTES | deferred | 12-17 placeholders-only greps | |
| T-12-53 | InfoDisc | keystore and `key.properties` | transferred | user-owned; gitignored, none tracked (`git ls-files` empty) | |
| T-12-54 | Repudiation | requirement traceability | deferred | 12-17 | |
| T-12-55 | Spoofing | tunnel callback on Twitch app | transferred | user adds/removes the redirect URL (D-20) | |
| T-12-56 | Tampering | BE repo and DB | accepted | plan 12-17: read-only refs, BE actions by user/orchestrator | applies at 12-17 execution |

## Cross-cutting checks

| Command | Result |
|---------|--------|
| `bash tool/hardening_check.sh` | `hardening_check: OK` |
| dev-bypass grep on main/bootstrap/env_config | only doc comments and `devAuthEnabled` in `env_config.dart:123-129` |
| `requireSecureTransport`/`secureTransportBlocker` | `app_bootstrap.dart:17,19,35`; `env_config.dart:70`; check precedes client creation |
| `env/prod.json` | `https` x2, `wss` x1; `DEV_AUTH` in `env/` = 0 |
| `pubspec.yaml` flavors | `default-flavor: prod` (:80), flavored `.env` asset (:86) |
| `build.gradle.kts` | `hasReleaseKeystore` (:16,54,66,72), `logger.quiet` (:75), `signingConfig` (:66) |
| `git ls-files android/key.properties '*.jks' .env` | empty |
| raw `print(`/`debugPrint(`/`developer.log(` outside `app_log.dart` | 0 |
| `appLog(... ${e|error|...})` | 37 hits, all `.runtimeType` |
| `4409` / `wsSessionRevokedCloseCode` | `ws_reconnect_policy.dart:8,19,38` |
| `reason` parsing | `auth_api_exception.dart:80-98`, only inside the `sessionRevokedCode` branch |
| revocation notices | `replacedByNewLogin`/`roleChanged` mapped in `auth_gate.dart:64-66`, `session_auth_token_service.dart:390-391`; each Italian copy appears once (`sign_in_screen.dart:12,13`) |
| `SharedPreferences` in auth + `session_store.dart` | only the first-launch flag (`session_store.dart:83-85`); refresh token stays in secure storage |
| `grep -c "secrets\." ci.yml` | 0; `hardening_check` at `:34,38`, `--dart-define-from-file=env/prod.json` at `:36` |
| trailers in `ac75702..HEAD` | 0 matches |
| `pubspec.yaml` diff | `default-flavor: prod`, flavored `.env` asset, `leak_tracker ^11.0.2`, `leak_tracker_flutter_testing ^3.0.10` only |

## Open

None.

## Deferred

- T-12-47: BE tree read-only discipline, enforced at 12-16 execution.
- T-12-48: no `.env`/identities in the BE handoff, 12-16.
- T-12-49: FE constants vs merged BE contract, 12-16 gate.
- T-12-50: fresh release APK bundle guard; CI already runs the guard, re-proven in 12-16.
- T-12-51: gate evidence pasted in the 12-16 SUMMARY.
- T-12-52: placeholder-only UAT/handoff docs, 12-17 greps.
- T-12-54: requirement traceability only from passed evidence, 12-17.

## Unregistered flags

None (no `## Threat Flags` section in the phase summaries raised an unmapped surface).
