---
phase: quick-261102-lor
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/graphql/queries/lore_queries.dart
  - lib/models/lore.dart
  - test/graphql/lore_documents_test.dart
  - test/models/lore_test.dart
  - .planning/STATE.md
autonomous: true
requirements: []

must_haves:
  truths:
    - "The lore documents (lores, lore) no longer select unlocked: the BE of Phase 11 (D-25) removed the field from the SDL and a client selecting it gets a validation error and no data"
    - "Lore has no unlocked field: fromJson ignores a stray unlocked key from an older backend; toJson, copyWith and props carry only id, type, image, name, description, relatedLore"
    - "Both documents stay registered in tool/schema_check; flutter analyze has 0 errors and 0 warnings (51 infos, the develop baseline); the full flutter test suite is green; dart format only on touched files"
  artifacts:
    - path: "lib/graphql/queries/lore_queries.dart"
      provides: "_LoreFields.full without unlocked"
      contains: "relatedLore"
    - path: "lib/models/lore.dart"
      provides: "Lore without unlocked"
      contains: "class Lore extends Equatable"
    - path: "test/graphql/lore_documents_test.dart"
      provides: "lores and lore pinned to the remaining fields and to the schema-check registry"
      contains: "without unlocked"
  key_links:
    - from: "tool/schema_check/schema_check_documents.dart"
      to: "lib/graphql/queries/lore_queries.dart"
      via: "'lores': LoreQueries.getAllLores and 'lore': LoreQueries.getLoreById (already registered)"
      pattern: "LoreQueries\\.getAllLores"
---

# Quick 261102-lor: drop Lore.unlocked (BE Phase 11, D-25)

## Why

BE Phase 11 "Popolamento del mondo" (LucaTabbia/Klimmeck-Guide-BE#17) removes `Lore.unlocked` from the GraphQL schema (D-25): no BE service read it and per-character unlocking arrives with BE Phase 16 / FE Phase 17 (LORE-01..03, backend-filtered). It is the only non-additive change of that phase: an app still selecting `unlocked` gets `Cannot query field` and `data: null` on every lore list. The BE PR stays in draft until this change is released, so this PR is to be merged with the end of that phase.

## Tasks

1. **Red.** `test/graphql/lore_documents_test.dart`: `lores` and `lore` are single queries, select `id image type name description relatedLore { id name }` with no `unlocked`, keep the `$id: String!` variable and stay registered in `schemaCheckDocuments`. `test/models/lore_test.dart`: `fromJson` reads the selected fields, ignores a stray `unlocked` key, `toJson` has no `unlocked`.
2. **Green.** Remove `unlocked` from `_LoreFields.full` and from `Lore` (constructor, field, `fromJson`, `toJson`, `copyWith`, `props`). `dart format` on the four touched files only; `flutter analyze` repo-wide; targeted tests then the full suite.
3. **Docs.** This plan and summary, row in `STATE.md` → Quick Tasks Completed; PR `fix/lore-unlocked-field` → `develop`.

## Verification

- `flutter test test/graphql/lore_documents_test.dart test/models/lore_test.dart` red before, green after.
- `flutter test` green; `flutter analyze` 0 errors / 0 warnings.
- `grep -rn unlocked lib test` finds only the tests that assert its absence.
