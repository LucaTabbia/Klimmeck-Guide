---
phase: 12-hardening
plan: 10
subsystem: repository
tags: [hardening, graphql, error-codes, bad-user-input, travel, quest-acceptance]
requires: ["12-09"]
provides:
  - "graphQlErrorCode reads extensions.code also from ServerException.parsedResponse.errors (HTTP >= 300), null fallback unchanged"
  - "TravelFailure.badUserInput and QuestAcceptanceFailure.badUserInput mapped from badUserInputCode over HTTP 200 and HTTP 400"
  - "travelNoticeFor / questAcceptanceNoticeFor render badUserInput with the existing generic copy"
affects: [12-11, 12-12, 12-16, 12-17]
tech-stack:
  added: []
  patterns:
    - "One private helper _firstCodeOf(List<GraphQLError>) over graphqlErrors + ServerException.parsedResponse.errors"
    - "badUserInput placed right before unauthenticated; notice arm joined to unknown (`X.badUserInput || X.unknown`)"
key-files:
  created:
    - .planning/phases/12-hardening/12-10-SUMMARY.md
  modified:
    - lib/repository/services/graphql/graphql_error_code.dart
    - test/repository/services/graphql/graphql_error_code_test.dart
    - lib/repository/travel_failure.dart
    - test/repository/travel_failure_test.dart
    - lib/screens/mainScreen/travelCubit/travel_notice.dart
    - test/screens/mainScreen/travelCubit/travel_notice_test.dart
    - lib/repository/quest_acceptance_failure.dart
    - test/repository/quest_acceptance_failure_test.dart
    - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart
    - test/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice_test.dart
decisions:
  - "graphqlErrors keep priority over the parsed response (spread order in _firstCodeOf); the SubscriptionError payload branch is still the last resort"
  - "badUserInput renders «Qualcosa è andato storto, riprova» (user veto D-13a): no new copy"
metrics:
  duration: "~15 min"
  completed: 2026-11-09
---

# Phase 12 Plan 10: graphQlErrorCode over HTTP errors and BAD_USER_INPUT on travel/quest acceptance Summary

`graphQlErrorCode` now reads `extensions.code` from the `parsedResponse` of an HTTP >= 300 `ServerException` (the RESEARCH F11 blind spot), so every classifier built on it stops reporting a validation refusal as `connection`; `TravelFailure` and `QuestAcceptanceFailure` gain a dedicated `badUserInput` value (HTTP 200 and HTTP 400 alike), rendered with the existing generic copy.

## Tasks

| Task | Name | Commits | Files |
|------|------|---------|-------|
| 1 | graphQlErrorCode reads the HTTP >= 300 parsedResponse | 9e14123 (test), 94b69bf (fix) | graphql_error_code.dart + test |
| 2 | BAD_USER_INPUT in travel and quest acceptance | 1dff482 (test), 9a61583 (feat) | travel_failure, quest_acceptance_failure, both notices + 4 tests |

## RED observed

- Task 1: `reads the code of a GraphQL error answered with HTTP 400 (D-13)` (Expected 'BAD_USER_INPUT', Actual null) and `a FORBIDDEN answered with HTTP 403 is an access denial (D-13)` (Expected true, Actual false). Green at first run as guards, as the plan foresaw: `prefers the graphql errors over the parsed response (D-13)` (graphqlErrors were already read first) and `returns null for an HTTP error without a code (D-13)` (no parsed response → null already).
- Task 2: compile failure `Member not found: 'badUserInput'` in all four test files. The case `an HTTP error without a code stays connection (D-13)` (×2) is a guard that would have passed on its own.

## Names created

- `lib/repository/services/graphql/graphql_error_code.dart`: private `String? _firstCodeOf(List<GraphQLError> errors)`; `graphQlErrorCode` body: `final link = exception.linkException; final code = _firstCodeOf([...exception.graphqlErrors, if (link is ServerException) ...?link.parsedResponse?.errors]);` then the unchanged `SubscriptionError` branch.
- `TravelFailure.badUserInput`, `QuestAcceptanceFailure.badUserInput` (both right before `unauthenticated`), arms `badUserInputCode => X.badUserInput` with `import 'package:klimmeck_guide/repository/spell_equip_failure.dart' show badUserInputCode;`.
- Test helpers: `_errorWithCode`, `_serverException(code, status)`, `_fromHttp(code, status)`, `_fromHttp400(code)` in graphql_error_code_test; `_fromHttp400(code)` in travel_failure_test and quest_acceptance_failure_test.

## Verification

- `flutter test test/repository` → 799 passed (after Task 1); `flutter test test/repository test/screens/mainScreen/travelCubit test/screens/mainScreen/questAcceptanceCubit test/screens/mainScreen/tabs/board` → 929 passed.
- `flutter analyze`: `47 issues found.` (all info, 0 error, 0 warning). No extra exhaustive switch over the two enums reported.
- `bash tool/hardening_check.sh` → `hardening_check: OK`.
- `dart format` on each touched file: only the two classifier test files reflowed (my additions); lib files unchanged by the formatter.
- No new user-visible string (diff grep empty).

## Deviations from Plan

- **[Boy Scout] Helper written as one `_firstCodeOf` over both error lists** instead of the plan's second `for` loop (same semantics, no duplicated loop, same shape as `characterCreationFailureFrom`). `grep -c "is ServerException"` = 1, `parsedResponse` = 2 (doc + code). Inside commit 94b69bf.
- **[Boy Scout] The prescribed enum doc line is wrapped on two lines** (`/// BAD_USER_INPUT (BE Phase 10): richiesta rifiutata dalla validazione del` / `/// server (Phase 12 D-13a).`) to stay within 80 columns like the neighbouring docs.

## Known Stubs

None.

## Self-Check: PASSED

- Commits 9e14123, 94b69bf, 1dff482, 9a61583 present in `git log`; all files in key-files exist.
