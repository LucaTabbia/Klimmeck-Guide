---
phase: quick-261102-lor
plan: 01
subsystem: lore
tags: [lore, graphql, model, schema]
requirements: []
requires:
  - BE Phase 11 D-25 (LucaTabbia/Klimmeck-Guide-BE#17): Lore.unlocked removed from the SDL
provides:
  - lore documents (lores, lore) without unlocked
  - Lore model without unlocked, tolerant of a stray unlocked key
affects: [library, schema-check registry]
key-files:
  created:
    - test/graphql/lore_documents_test.dart
    - test/models/lore_test.dart
  modified:
    - lib/graphql/queries/lore_queries.dart
    - lib/models/lore.dart
    - .planning/STATE.md
decisions:
  - fromJson stays tolerant (ignores unlocked) so the app works against both the develop BE and the Phase 11 BE
  - no UI change: no widget read Lore.unlocked (grep on lib/ on 2026-11-02)
  - dart format reflowed the two getters of lore_queries.dart (file was not formatter-clean)
commits:
  - 37a2473 test(lore): expect the lore documents and model without unlocked
  - d6346a9 fix(lore): drop unlocked, removed from the BE schema in Phase 11
completed: 2026-11-02
---

# Quick 261102-lor: drop Lore.unlocked Summary

The lore queries and the `Lore` model no longer carry `unlocked`, which the BE of Phase 11 removed from its schema (D-25). The app is compatible with both backends: the reduced selection is valid against the `develop` BE too, and `fromJson` ignores a leftover `unlocked` key.

## What changed

- `lib/graphql/queries/lore_queries.dart`: `_LoreFields.full` selects `id image type name description relatedLore { id name }`.
- `lib/models/lore.dart`: `unlocked` removed from constructor, field, `fromJson`, `toJson`, `copyWith`, `props`.
- Tests: `test/graphql/lore_documents_test.dart` (documents pinned to the remaining fields, `$id: String!`, schema-check registry), `test/models/lore_test.dart` (fields read, stray `unlocked` ignored, not serialized).

## Verification

- Targeted tests: 4 failures before the fix (serialized `unlocked`, documents selecting it), 10/10 green after.
- `flutter test`: 2862 tests, all passed.
- `flutter analyze`: 0 errors, 0 warnings, 51 infos (same as `develop`).
- `dart format` on the four touched files only.

## Release note

Merge with the end of BE Phase 11 and release the app before deploying that BE: an app still selecting `unlocked` gets no lore from it.
