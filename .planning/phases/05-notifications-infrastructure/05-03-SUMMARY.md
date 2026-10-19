---
phase: 05-notifications-infrastructure
plan: 03
subsystem: push-data
tags: [graphql, repository, storage, shared-preferences, uuid, notifications, fcm, tdd]
requires:
  - "05-01: uuid 4.5.1 direct dependency"
  - "05-02: validEventId (lib/models/notification_intent.dart)"
provides:
  - "PushMutations.registerPushDevice / unregisterPushDevice (validated against BE 0828719, listed for the schema check)"
  - "KlimmeckGraphQl.registerPushDevice({deviceId, token, platform}) / unregisterPushDevice(deviceId), OperationException surfaced unchanged"
  - "PushDeviceRepository.register / unregister + androidPlatform constant"
  - "PushDeviceFailure (isRetryable: connection/unknown only), PushDeviceException, pushDeviceFailureFrom"
  - "DeviceIdentityStore + SharedPreferencesDeviceIdentityStore (klimmeck.push.deviceId, UUID v4, memoised creation)"
  - "ActiveUserStore + SharedPreferencesActiveUserStore (klimmeck.push.activeUserId, uncached)"
  - "MockPushDeviceRepository; FakeSharedPreferencesAsync getString/setString/remove"
affects: [05-05, 05-06, 05-08, 05-09]
tech-stack:
  added: []
  patterns:
    - "Failure mapping on extensions.code only, link error without code -> connection"
    - "Memoised Future with reset on error for create-once storage values"
    - "SharedPreferencesAsync built lazily from an injectable factory (never eager)"
key-files:
  created:
    - lib/graphql/mutations/push_mutations.dart
    - lib/repository/push_device_failure.dart
    - lib/repository/push_device_repository.dart
    - lib/repository/storage/device_identity_store.dart
    - lib/repository/storage/active_user_store.dart
    - test/graphql/push_mutations_test.dart
    - test/repository/services/graphql/graphql_push_test.dart
    - test/repository/push_device_failure_test.dart
    - test/repository/push_device_repository_test.dart
    - test/repository/storage/device_identity_store_test.dart
    - test/repository/storage/active_user_store_test.dart
  modified:
    - tool/schema_check/schema_check_documents.dart
    - lib/repository/services/graphql/graphql.dart
    - test/helpers/mocks.dart
    - test/helpers/fakes/fake_shared_preferences_async.dart
decisions:
  - "DeviceIdentityStore memoises with a try/catch async wrapper (not catchError) so a failed read resets the pending future and the next call retries"
  - "_readOrCreate validates through validEventId and returns its result directly instead of `stored!` (same behaviour, no null assertion)"
metrics:
  duration: "~20 min"
  completed: 2026-10-19
  tasks: 3
  files: 15
---

# Phase 5 Plan 03: Push device data path Summary

Data path of device registration: `RegisterPushDevice` / `UnregisterPushDevice` documents (no selection on `Boolean!`) validated against BE `0828719` and listed for the schema check, the two `KlimmeckGraphQl` methods, `PushDeviceRepository` with `PushDeviceFailure` mapped on `extensions.code` only (retryable = connection/unknown), the device-wide UUID v4 `DeviceIdentityStore` (`klimmeck.push.deviceId`, created once, shared across concurrent calls, regenerated only when the BE alphabet would reject it) and the uncached `ActiveUserStore` mirror (`klimmeck.push.activeUserId`) for the background isolate.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 RED | Failing tests: push mutations documents + KlimmeckGraphQl methods | 3a48689 | 2 test files |
| 1 GREEN | Push documents, schema-check entries, KlimmeckGraphQl methods | 3426e56 | 3 files |
| 2 RED | Failing tests: failure mapping + repository (+ MockPushDeviceRepository) | 0c802a6 | 3 test files |
| 2 GREEN | PushDeviceFailure + PushDeviceRepository | 6fe707f | 2 lib files |
| 3 RED | Failing tests: device identity + active user stores (+ fake getString/setString/remove) | 041f1b6 | 3 test files |
| 3 GREEN | DeviceIdentityStore + ActiveUserStore | 90dafca | 2 lib files |

No REFACTOR commit: nothing to clean after GREEN.

## TDD evidence

**Task 1 RED:**
```
test/graphql/push_mutations_test.dart:4:8: Error: Error when reading 'lib/graphql/mutations/push_mutations.dart': No such file or directory
test/repository/services/graphql/graphql_push_test.dart:42:10: Error: The method 'registerPushDevice' isn't defined for the type 'KlimmeckGraphQl'.
```
**Task 1 GREEN:** `flutter test test/graphql test/tool test/repository/services/graphql` -> `+97: All tests passed!`

**Task 2 RED:**
```
test/repository/push_device_failure_test.dart:5:8: Error: Error when reading 'lib/repository/push_device_failure.dart': No such file or directory
```
**Task 2 GREEN:** `+21: All tests passed!` (both files)

**Task 3 RED:**
```
test/repository/storage/active_user_store_test.dart:2:8: Error: Error when reading 'lib/repository/storage/active_user_store.dart': No such file or directory
```
**Task 3 GREEN:** `flutter test test/repository/storage` -> `+33: All tests passed` (existing notification preferences store tests green over the extended fake)

## Schema check (BE `origin/develop` = `0828719`)

`git show origin/develop:src/schema.gql` written to the session scratchpad, then `dart run tool/schema_check/dump_documents.dart <scratch>/docs` + `NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js <scratch>/schema.gql <scratch>/docs`:
```
dumped 27 documents
OK RegisterPushDevice.graphql
OK UnregisterPushDevice.graphql
... (27 x OK, exit 0)
```

## Verification

- `flutter test` (full suite): **858 passed** (812 baseline + 46 new), 0 failed
- `flutter analyze`: **56 issues, 0 errors** (unchanged)
- `flutter analyze` on every touched file: `No issues found!`
- `dart format` only on touched files by path; the 4 pre-existing files (`graphql.dart`, `schema_check_documents.dart`, `mocks.dart`, `fake_shared_preferences_async.dart`) were format-clean at baseline and stay clean
- Acceptance greps: both document signatures = 1; both schema-check entries = 1; both `Future<void>` service methods = 1; `isRetryable` line = 1; `androidPlatform` = 1; `.message` in failure = 0; `MockPushDeviceRepository` = 1; both store keys = 1; `const Uuid().v4()` = 1; `SharedPreferencesAsync()` = 1 per store (default factory only); `package:flutter/` in stores = 0; `grep -rn sendTestPush lib | wc -l` = 0

## Deviations from Plan

None in behaviour. Process note: the Task 3 RED commit subject was first written at 76 chars and amended (before any further commit, nothing pushed) to `test(push): add failing tests for the device and active user stores` to respect the 72-char limit.

Note: between the Task 2 RED commit and its GREEN commit, `test/helpers/mocks.dart` imported the not-yet-existing repository (as the plan prescribes), so the whole suite only compiled again at 6fe707f.

## Known Stubs

None.

## Threat Flags

None: no surface beyond the plan's threat model (T-05-03-01..05 mitigated as planned; `PushDeviceException.toString()` prints the failure name only, no logging of variables).

## Self-Check: PASSED

- All 11 created files and 4 modified files present
- Commits 3a48689, 3426e56, 0c802a6, 6fe707f, 041f1b6, 90dafca present in `git log`
- No `Co-Authored-By` trailer in any of them
