---
phase: 12-hardening
plan: 12
subsystem: repository
tags: [hardening, error-codes, bad-user-input, moderation, character-creation, character-deletion]
requires: ["12-11"]
provides:
  - "CharacterCreationFailure.badUserInput, .imageRejected, .moderationUnavailable; portraitUploadFailureFrom(Object? responseData)"
  - "CharacterCreationRepository.uploadPortrait maps DioException.response.data through portraitUploadFailureFrom"
  - "CharacterCreationCubit clears portraitPath + uploadedPortrait on imageRejected (draft kept); moderationUnavailable keeps everything"
  - "CharacterDeletionFailure.badUserInput rendered with «Impossibile eliminare il personaggio, riprova»"
affects: [12-13, 12-16, 12-17]
tech-stack:
  added: []
  patterns:
    - "REST error bodies read only through `code` (never `message`/`reasons`)"
key-files:
  created:
    - test/screens/mainScreen/tabs/settings/components/character_deletion_messages_test.dart
    - .planning/phases/12-hardening/12-12-SUMMARY.md
  modified:
    - lib/repository/character_creation_failure.dart
    - test/repository/character_creation_failure_test.dart
    - lib/screens/characterCreation/components/character_creation_messages.dart
    - test/screens/characterCreation/components/character_creation_messages_test.dart
    - lib/repository/character_creation_repository.dart
    - test/repository/character_creation_repository_test.dart
    - lib/screens/characterCreation/cubit/character_creation_cubit.dart
    - test/screens/characterCreation/cubit/character_creation_cubit_test.dart
    - lib/repository/character_deletion_failure.dart
    - test/repository/character_deletion_failure_test.dart
    - lib/screens/mainScreen/tabs/settings/components/character_deletion_messages.dart
decisions:
  - "Copy ruling (D-13a veto, D-19): creation badUserInput joins the unknown arm («Qualcosa è andato storto, riprova»); deletion badUserInput joins the generic deletion arm; moderation copy verbatim from D-19"
  - "Boy Scout: characterCreationFailureFrom now delegates code extraction to graphQlErrorCode (same behaviour, pinned by the existing graphqlErrors/HTTP 400 groups)"
metrics:
  duration: "~15 min"
  completed: 2026-11-09
---

# Phase 12 Plan 12: Character creation moderation and BAD_USER_INPUT, character deletion BAD_USER_INPUT Summary

The portrait upload now reads the BE Phase 10 moderation `code` from the REST error body: `IMAGE_REJECTED` clears the portrait and asks for another image, `IMAGE_MODERATION_UNAVAILABLE` keeps the whole draft for a retry or removal; `BAD_USER_INPUT` is classified in both character creation and deletion with the existing generic copy.

## Tasks

| Task | Name | Commits | Files |
|------|------|---------|-------|
| 1 | Creation classifier and messages | 5abe6cb (test), 6f107a0 (feat) | character_creation_failure.dart, character_creation_messages.dart + 2 tests |
| 2 | Upload reads the moderation code; cubit reactions | e48a936 (test), cffd58b (feat) | character_creation_repository.dart, character_creation_cubit.dart + 2 tests |
| 3 | Deletion BAD_USER_INPUT | a7a217e (test), 17f4006 (feat) | character_deletion_failure.dart, character_deletion_messages.dart + 1 test, 1 new test file |

## Names and signatures created

- `lib/repository/character_creation_failure.dart`: `const String imageRejectedCode = 'IMAGE_REJECTED';`, `const String imageModerationUnavailableCode = 'IMAGE_MODERATION_UNAVAILABLE';`; enum values `imageRejected`, `moderationUnavailable` (after `uploadFailed`), `badUserInput` (after `connection`, before `handoverRejected`); `CharacterCreationFailure portraitUploadFailureFrom(Object? responseData)` (Map with String `code` → imageRejected / moderationUnavailable, anything else → uploadFailed); classifier arm `badUserInputCode => CharacterCreationFailure.badUserInput`.
- `lib/screens/characterCreation/components/character_creation_messages.dart`: `imageRejected => 'Immagine non ammessa, scegline un\'altra.'`, `moderationUnavailable => 'Controllo dell\'immagine non disponibile: riprova o procedi senza immagine.'`, `badUserInput || unknown => 'Qualcosa è andato storto, riprova'`.
- `lib/repository/character_creation_repository.dart`: `on DioException catch (error) { throw CharacterCreationException(portraitUploadFailureFrom(error.response?.data)); }` (ImageUploadException and FileSystemException branches unchanged → uploadFailed).
- `lib/screens/characterCreation/cubit/character_creation_cubit.dart`: `_handleSubmitFailure` starts with `if (failure == CharacterCreationFailure.imageRejected) { return _rejectPortrait(); }`; `void _rejectPortrait()` emits `isSubmitting: false, submitFailure: imageRejected, portraitPath: null, uploadedPortrait: null`.
- `lib/repository/character_deletion_failure.dart`: enum value `badUserInput` after `connection`; arm `badUserInputCode => CharacterDeletionFailure.badUserInput` before `unauthenticatedCode`; `show badUserInputCode` import from `spell_equip_failure.dart`.
- `lib/screens/mainScreen/tabs/settings/components/character_deletion_messages.dart`: `notFound || badUserInput || unauthenticated || unknown => 'Impossibile eliminare il personaggio, riprova'`.

## Pinned-test change

`test/repository/character_creation_failure_test.dart`: «BAD_USER_INPUT maps to unknown» → «BAD_USER_INPUT maps to badUserInput (D-13)»; «BAD_USER_INPUT maps to unknown, not connection» → «BAD_USER_INPUT over HTTP 400 maps to badUserInput, not connection (D-13)».

## RED observed

- Task 1: compile failure — `Member not found: 'badUserInput'` / `'imageRejected'` / `'moderationUnavailable'`, `Method not found: 'portraitUploadFailureFrom'`.
- Task 2: 3 failures — repository «a 422 IMAGE_REJECTED upload maps to imageRejected (D-13)» and «a 503 IMAGE_MODERATION_UNAVAILABLE upload maps to moderationUnavailable (D-13)» (got uploadFailed); cubit «a rejected portrait is cleared and the draft kept (D-13)» (portrait kept). «moderation unavailable keeps the portrait for a retry (D-13)» was GREEN at the first run: `_failSubmit` already keeps portrait and draft for any non-alreadyExists failure; the test pins that reaction against future changes.
- Task 3: compile failure — `Member not found: 'badUserInput'` (classifier file); the new messages file failed to compile on the same member.

## Verification

- Task 1: `flutter test test/repository/character_creation_failure_test.dart test/screens/characterCreation` → 118 tests, All tests passed.
- Task 2: `flutter test test/repository/character_creation_repository_test.dart test/screens/characterCreation` → 120 tests, All tests passed.
- Task 3: `flutter test test/repository/character_deletion_failure_test.dart test/screens/mainScreen/tabs/settings` → 85 tests, All tests passed.
- Plan verification: `flutter test test/repository test/screens/characterCreation test/screens/mainScreen/tabs/settings` → 997 tests, All tests passed.
- `flutter analyze` → `47 issues found.` (all info; 0 error, 0 warning) after each task.
- `bash tool/hardening_check.sh` → `hardening_check: OK`.
- `dart format` run on each touched file one by one; none of them was formatter-dirty, the only reflow was in the new test cases.

## Deviations from Plan

None - plan executed exactly as written. (The repository test now imports `package:graphql_flutter/graphql_flutter.dart' hide Response` so the dio `Response` used for the 422/503 fixtures does not clash with gql_exec; test-only.)

## Threat mitigations

- T-12-33: `_rejectPortrait` clears `portraitPath` and the cached `uploadedPortrait`.
- T-12-34: only `code` is read from the upload body; copy is local.
- T-12-35: `moderationUnavailable` goes through `_failSubmit` (draft and portrait kept).

## Self-Check: PASSED
