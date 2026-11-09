---
phase: 12-hardening
plan: 07
subsystem: ci
tags: [hardening, ci, guard, release]
requires: ["12-06"]
provides:
  - "tool/hardening_check.sh: single guard (source greps of HARDEN-01/HARDEN-07/D-03c; with an APK argument, the three decompressing bundle greps of D-02)"
  - ".github/workflows/ci.yml: GitHub Actions CI (analyze, test, guard, prod release build, bundle guard) on PR to develop and push to feat/fix/refactor branches"
affects: [12-16, 12-17]
tech-stack:
  added: []
  patterns:
    - "One guard script shared by CI and the local gate plan"
key-files:
  created:
    - tool/hardening_check.sh
    - .github/workflows/ci.yml
  modified: []
decisions:
  - "Guard script and workflow written verbatim from the RESEARCH §Code Examples; no pattern loosened, no finding on the tree"
metrics:
  duration: "~6 min"
  completed: 2026-11-09
---

# Phase 12 Plan 07: Hardening guard script and Flutter CI Summary

Single bash guard `tool/hardening_check.sh` (dev bypass, SharedPreferences allow-list, token writes, direct logs, credential interpolation in logs; bundle greps for `.env`, `DEV_AUTH_`, `DevAuthTokenService` on a given APK) plus a GitHub Actions workflow that runs analyze/test/guard/prod release build/bundle guard without any secret.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | tool/hardening_check.sh | 8e21468 | tool/hardening_check.sh (mode 100755) |
| 2 | GitHub Actions workflow | 1e97859 | .github/workflows/ci.yml |

## Task 1 check outputs

```
$ bash -n tool/hardening_check.sh && echo SYNTAX_OK
SYNTAX_OK
$ bash tool/hardening_check.sh; echo "exit=$?"
hardening_check: OK
exit=0
$ bash tool/hardening_check.sh /nonexistent.apk; echo "exit=$?"
FAIL: /nonexistent.apk not found
hardening_check: 1 check(s) failed
exit=1
$ flutter build apk --release --dart-define-from-file=env/prod.json > <scratch log> 2>&1; echo "build=$?"
build=0   (63 s, assembleProdRelease 60.7 s, app-prod-release.apk 118.7 MB; key.properties WARNING present once = expected local debug-key fallback)
$ bash tool/hardening_check.sh build/app/outputs/flutter-apk/app-prod-release.apk; echo "exit=$?"
hardening_check: OK
exit=0
```

Extra: `api.klimmeck.invalid` occurrences in the APK = 9 (prod URLs baked in, as after 12-03).

Acceptance greps: `test -x` → EXEC; `unzip -p` = 2; `flutter_assets/` = 1; `lib/bootstrap/session_auth_composition.dart` = 1.

Negative probe (not committed): a copy of `lib/` + `tool/` in the scratchpad with an injected `DevAuthTokenService` comment in `main.dart`, a `print(`, an `appLog('… $accessToken')` and a `setString('jwtToken', …)` in `env_config.dart` → 5 FAIL lines, exit 1 (dev bypass, allow-list, token write, direct log, credential interpolation). The copy was deleted.

## Task 2 check outputs

```
$ ruby -e 'require "yaml"; d = YAML.load_file(".github/workflows/ci.yml"); puts d["jobs"]["flutter"]["steps"].length'
9
```

Greps: `flutter analyze --no-fatal-infos` 1; `tool/hardening_check.sh build/app/outputs/flutter-apk/app-prod-release.apk` 1; `branches: [develop]` 1; `'refactor/**'` 1; `flutter-version: '3.35.5'` 1; `java-version: '17'` 1; `timeout-minutes: 30` 1; `dart-define-from-file=env/prod.json` 1; `secrets.` 0. Local `flutter --version` = 3.35.5 stable (matches the pin). Local `flutter analyze --no-fatal-infos` exits 0 (47 infos).

**CI run to be checked by the orchestrator after the push/PR** (`GH_TOKEN=$(gh auth token --user LucaTabbia) gh pr checks <n>` or `gh run list --branch refactor/12-hardening`); expected ~4 min tests + ~6 min first release build (RESEARCH A4). No `gh` was run here; the workflow was never triggered.

## Gates

- `flutter analyze`: 47 issues, all info, 0 error, 0 warning (no Dart file touched).
- No Dart test added: both tasks are infrastructure, verified by the commands above (REPO-RULES).
- `dart format`: not applicable (no Dart file touched).

## Deviations from Plan

None - plan executed exactly as written. The orchestrator's progress format `7/17` / `Plan: 7 of 17` was used instead of the plan's `07/17` (brief rule).

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: tool/hardening_check.sh, .github/workflows/ci.yml
- FOUND commits: 8e21468, 1e97859
