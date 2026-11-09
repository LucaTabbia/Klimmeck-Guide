---
status: in-progress
phase: 12-hardening
devices: Samsung (USB) + Android emulator Medium_Phone (Play Store image)
be_ref: 8bfd1b3
date: 2026-11-09
verdict:
---

# Phase 12 — Device E2E (hardening)

Signed release through a TLS tunnel with a real Twitch login, silent logs, the TLS fail-fast screen, the untouched dev workflow, the DevTools memory snapshot, «l'ultimo login caccia l'altro» on two devices, identity transitions, the CI run. BE: merged `develop` `8bfd1b3` (merge of BE PR #27 `feat/17-autorizzazione-e-sessioni`, BE Phase 17). Gate re-checked before this file was written: `git -C <BE> show origin/develop:src/auth/session/session-revoke-reason.enum.ts | grep -c newLogin` → `1`; gate plan 12-16 passed on the same ref (`12-16-SUMMARY.md`). Results are recorded only from the tester's words; notes carry no ids of real users, no tokens, no Mongo URIs, no tunnel host, no identity values (environment variable names only). The orchestrator guides the user one step per message and performs every device and BE-side action (builds, adb, tunnel, DB scripts, CI report); the executor never runs them.

## Prerequisites

User, before step 1; values never written in the repo.

- **P1 Keystore** (D-03a, RESEARCH F3): `"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" -genkey -v -keystore ~/klimmeck-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload` (alias `upload`; answer the key-password prompt with the same password as the store, `storePassword` = `keyPassword`); then `android/key.properties` with the four keys `storePassword=<password>`, `keyPassword=<same password>`, `keyAlias=upload`, `storeFile=/Users/<user>/klimmeck-upload-keystore.jks` (ABSOLUTE path: a relative one resolves from `android/app/`). Keep the keystore and the password safe: losing them means a new store listing. A half-filled `key.properties` fails the Gradle build with a clear message; a missing one falls back to the debug keys with the WARNING line (step 1 checks it is absent).
- **P2 Tunnel** (D-04, D-20): `brew install cloudflared`; a NAMED tunnel (stable host) to the local BE port (the BE runs on `3001`); `env/tunnel.local.json` (gitignored by `env/*.local.json`) with `BASE_URL` `https://<tunnel-host>/`, `GRAPHQL_HTTP_URL` `https://<tunnel-host>/api/graphql`, `GRAPHQL_WS_URL` `wss://<tunnel-host>/api/graphql` (only these three keys; https/https/wss, otherwise the release shows the fail-fast screen of step 3). The WS upgrade through the tunnel as `wss://` is verified at step 2 (BE handoff §3.2, RESEARCH A3).
- **P3 Twitch** (D-20): BE `.env` `TWITCH_REDIRECT_URI=https://<tunnel-host>/auth/twitch/callback`, the same URL added byte for byte to the Twitch application's OAuth Redirect URLs, BE restarted; `APP_AUTH_REDIRECT_URL` unchanged (`klimmeck://auth`). After the UAT the user may remove the tunnel URL from the Twitch console (T-12-55).
- **P4 One BE process** during the whole UAT (the BE socket registry is per process, BE Phase 17 D-16): no second BE «for the sweeps». The BE throttler sees both devices behind the tunnel as one IP (note, RESEARCH A6; `THROTTLE_TRUST_PROXY` off: two devices are fine). If the dev token stays enabled on the BE during the UAT, `DEV_AUTH_TWITCH_ID` must be DISTINCT from the real twitchId of the Twitch account used on the devices: otherwise a `DEV_AUTH_ROLE` different from the role at DB changes the real user's role and revokes its sessions with `roleChanged` (BE handoff §3.1). The dev bypass has no sessions: it never revokes and never receives `4409`.
- **P5 Devices**: Samsung over USB; Android emulator AVD `Medium_Phone_API_36.1` (API 36.1, Play Store image, for Chrome Custom Tabs and FCM) or `Pixel_9`; the SAME real Twitch account on both for steps 6–8. Dev-flavor steps reach the BE with `adb -s <serial> reverse tcp:3000 tcp:3000` on each device (`tcp:3000 tcp:3001` when the BE runs on 3001, as today); FE `.env` `DEV_AUTH_ENABLED=false` for the real-login dev steps (step 4 uses the usual dev `.env`). Between a debug-signed dev build and a release-signed prod build: `adb uninstall it.lordreavor.klimmeckguide.klimmeck_guide` (same `applicationId`; secure storage wiped → re-login).
- **Device notes** (user memory): `adb reverse` is lost at every USB reconnection; screen off → `adb shell svc power stayon usb`; «bad base-64» secure-storage log is benign. The `app-prod-release.apk` left in `build/` by the 12-16 gate is debug-signed with the `.invalid` URLs of `env/prod.json`: NEVER install it for the tunnel steps (step 1 rebuilds it).

## Steps

| Step | Requirements | Decisions | Expected | Result | Note |
|------|--------------|-----------|----------|--------|------|
| 1 | HARDEN-08 | D-03a | Signing: `flutter build apk --release --dart-define-from-file=env/tunnel.local.json` → the output has NO line `WARNING: android/key.properties not found…`; `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ~/Library/Android/sdk/build-tools/36.1.0/apksigner verify --print-certs build/app/outputs/flutter-apk/app-prod-release.apk` shows the user's certificate (not `CN=Android Debug`). | | |
| 2 | HARDEN-08 | D-03b, D-03c, D-04 | Release through the tunnel on the Samsung: `adb uninstall it.lordreavor.klimmeckguide.klimmeck_guide`; `adb install -r build/app/outputs/flutter-apk/app-prod-release.apk`; real Twitch login; one quest or travel round trip (accept a quest or start a travel and see it progress/arrive); Settings → Esci → sign-in screen; before the run `adb logcat -c`, after it `adb logcat -d -s flutter` prints zero lines (Dart tag only; system lines such as ActivityManager «Start proc …» are not app logs); control: the same command after a few actions on a dev debug build prints lines. | | |
| 3 | HARDEN-08 | D-03b, D-19 | TLS fail-fast: `flutter build apk --release --dart-define-from-file=env/dev.json` (cleartext localhost URLs) → install → the app shows only «Questa versione dell'app non può collegarsi al server in modo sicuro. Installa una versione aggiornata.», no button; then `adb uninstall it.lordreavor.klimmeckguide.klimmeck_guide`. | | |
| 4 | HARDEN-07 | D-01, D-16 | Dev workflow untouched: with the usual dev `.env` (dev bypass on, innkeeper) `flutter run --flavor dev -t lib/main_dev.dart` → instant login as before Phase 12; `flutter run -t lib/main_dev.dart` WITHOUT `--flavor dev` stops at start with «Run with --flavor dev». | | |
| 5 | HARDEN-05 | D-05 | DevTools memory snapshot: `flutter run --profile --flavor dev -t lib/main_dev.dart` with `DEV_AUTH_ENABLED=false`, real login; open Map, Journal, Library; DevTools → Memory → snapshot A; Settings → Esci; GC; snapshot B; in B no instance of the session cubits (`CharacterCubit`, `QuestCubit`, `WorldMapCubit`, `JournalCubit`, `LibraryCubit`, `ShopCubit`, …), of the old `WebSocketLink` or of the session `StreamSubscription`s; screenshots of A and B attached (paths in the Note). | | |
| 6 | HARDEN-06 | D-06, D-09, D-12 | Dual device, last login wins: Samsung and emulator on the same build (dev flavor with `DEV_AUTH_ENABLED=false`, or the release through the tunnel), same real Twitch account; log in on the Samsung and open the Map; log in on the emulator → within a minute the Samsung shows the sign-in screen with «Hai effettuato l'accesso da un altro dispositivo.», no crash, no spinner mid-session; the emulator keeps working (open a tab, live data). | | |
| 7 | HARDEN-06 | D-09 | Symmetry: log in again on the Samsung → the emulator shows the same notice «Hai effettuato l'accesso da un altro dispositivo.» within a minute; the Samsung works. | | |
| 8 | HARDEN-06 | D-11 | Character removed and recreated elsewhere: with the Samsung logged in, the orchestrator archives the character BE-side with the same write the BE `deleteCharacter` performs (script outside the repo, values never printed) → the Samsung goes to the creation page without a restart; create a new character → a fresh shell, no data of the old character (quests, journal, inventory). | | |
| 9 | HARDEN-06 | D-11 | (optional) Account switch: logout and login with a second Twitch account → the whole shell rebuilt, nothing of the first account visible. | | |
| 10 | HARDEN-06 | D-12, BE Phase 17 D-06 | (optional) Role change: the orchestrator changes the user's role at DB with an update of the `role` field only (`updateOne` with `$set` on `role`, never a replace; BE watcher) → the device shows «Il tuo ruolo è cambiato, accedi di nuovo.»; then the role is restored (second event, new revocation: log in again). | | |
| 11 | HARDEN-09 | D-07 | CI: the orchestrator reports the GitHub Actions run of `refactor/12-hardening` (push or PR) green — analyze, test, guard, release build, bundle guard (`gh run list --branch refactor/12-hardening` / `gh pr checks <n>` with the personal account `LucaTabbia` selected per command, run by the orchestrator, never by the executor). | | |

## DB checks

Read-only checks by the orchestrator (script outside the repo, values never printed); not a numbered step.

| Check | Origin | Expected | Result | Note |
|-------|--------|----------|--------|------|
| DB-1 | Review finding C-IN-06 (D-13c) | The `size` served (DB `cities` documents / GraphQL `cities { type size }`) for the cities of type `ferrionCity`, `necrorianCity`, `talmvereVillage` — the three types classed `capital` by the removed `cityClass` — is compared with that former class: `capital` → marker always visible as before; `city` / `village` → marker appears only from zoom 2.5 / 3.2 (intended D-13c change, the backend is the source of truth); `null` → marker hidden (gap to report to the BE). Eyeball the three markers on the Map at low zoom. | | |

## Requirement ↔ evidence map

HARDEN-05 (step 5 + leak test, 12-16 gate), HARDEN-06 (steps 6, 7, 8 + dual-session/identity tests), HARDEN-07 (step 4 + 12-16 bundle guard), HARDEN-08 (steps 1, 2, 3), HARDEN-09 (step 11); automated only: HARDEN-01, HARDEN-03, HARDEN-04 (12-16 VALIDATION approved), HARDEN-10 (12-16 approved + the D-14 review files `12-REVIEW*.md` record every finding fixed or deferred), HARDEN-02 (BE matrix spec on BE `origin/develop`, path from the BE handoff §2: `test/authz/authorization-matrix.int-spec.ts`, 89 cases). Steps 9 and 10 optional.

## Session notes
