---
phase: 02-character-creation
plan: 05
subsystem: services
tags: [dio, cloudinary, image_picker, upload]
requires: [02-01]
provides:
  - KlimmeckRest.uploadImage(File) -> Future<String> on cloudinary/uploadImage (any 2xx, non-empty url, 30 s timeouts)
  - ImageUploadException
  - PortraitPicker interface, PortraitSource, PortraitPickFailure, PortraitPickException
  - ImagePickerPortraitPicker (1024 px, quality 85, requestFullMetadata false)
  - MockImagePicker, MockPortraitPicker shared mocks
affects: [02-07, 02-09]
key-files:
  created:
    - lib/repository/services/rest/image_upload_exception.dart
    - lib/repository/services/image/portrait_picker.dart
    - lib/repository/services/image/image_picker_portrait_picker.dart
    - test/repository/services/rest/rest_upload_test.dart
    - test/repository/services/image/image_picker_portrait_picker_test.dart
  modified:
    - lib/repository/services/rest/rest.dart
    - test/helpers/mocks.dart
key-decisions:
  - "Upload failures are typed (DioException for transport/non-2xx, ImageUploadException for url-less 2xx); no silent null"
  - "Android activity kill during camera intent accepted (Pitfall 8), documented in class doc"
requirements-completed: []  # CHAR-05 closes with the repository/screen plans
duration: 10min
completed: 2026-10-09
---

# Phase 2 Plan 05: Portrait upload fix and picker Summary

The REST upload now reaches `/cloudinary/uploadImage`, accepts 201, throws typed exceptions, and the portrait picker sits behind an injectable interface.

## Commits
- 5675e4d test(character-creation): add failing tests for the portrait upload
- cf80171 fix(character-creation): make the portrait upload hit the real endpoint and fail loudly
- ff64674 test(character-creation): add failing tests for the portrait picker
- a74a8bc feat(character-creation): add the injectable portrait picker

## Verification
- `flutter test`: 354 passed (341 baseline + 13 new)
- `flutter analyze lib test`: 12 issues (unchanged baseline)
- `dart format` only on touched files

## Deviations from Plan
None. Boy Scout: removed no-op try/catch/rethrow in the two `fetchCloudinary...` methods (behaviour unchanged).

## Known Stubs
None.

## Self-Check: PASSED
