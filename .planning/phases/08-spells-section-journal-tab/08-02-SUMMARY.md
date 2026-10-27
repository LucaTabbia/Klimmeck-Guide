---
phase: 08-spells-section-journal-tab
plan: 02
subsystem: repository
tags: [flutter, dart, graphql, spells, repository, failures, mutations]

# Dependency graph
requires:
  - phase: BE Phase 4 (spells)
    provides: "`equipSpell`/`unequipSpell(request: EquipSpellRequest!): CommonResponse!` and their rejection codes (handoff §2/§4/§9); `usages` deprecated and ignored"
  - phase: 07-travel
    provides: "travel slice template (`startTravel` service, `travelFailureFrom`, `TravelRepository._guard`)"
provides:
  - "`EquipSpellRequest { id, spellId }` (no `usages`)"
  - "Named documents `EquipSpell` / `UnequipSpell` and the renamed schema-check keys (registry still 34 entries)"
  - "`KlimmeckGraphQl.equipSpell` / `unequipSpell` returning only `successful`"
  - "`SpellEquipFailure`, `SpellEquipException`, `spellEquipFailureFrom` and the five spell code constants incl. `badUserInputCode`"
  - "`SpellsRepository.equip` / `unequip` with the 15 s guard; `MockSpellsRepository` in `test/helpers/mocks.dart`"
affects: [08-05, 08-06, 08-10, 08-12]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two mutations sharing one CommonResponse reader (`_spellSlotMutation(document, field, request)`) instead of copying `startTravel`"
    - "Parametric test helpers (one group body run for equip and unequip) to avoid duplicated test code"

key-files:
  created:
    - lib/models/request/equip_spell_request.dart
    - lib/repository/spell_equip_failure.dart
    - lib/repository/spells_repository.dart
    - test/models/request/equip_spell_request_test.dart
    - test/graphql/spell_documents_test.dart
    - test/repository/services/graphql/graphql_spells_test.dart
    - test/repository/spell_equip_failure_test.dart
    - test/repository/spells_repository_test.dart
  modified:
    - lib/graphql/mutations/character_mutations.dart
    - tool/schema_check/schema_check_documents.dart
    - lib/repository/services/graphql/graphql.dart
    - test/helpers/mocks.dart

key-decisions:
  - "`startTravel` left untouched (the plan forbids refactoring travel here), even though `_spellSlotMutation` could read its response"
  - "`declined` doc comment mirrors `TravelFailure.declined` (BE rejection without code, distinct from a malformed answer = `unknown`)"

patterns-established:
  - "Spell mutations: the service returns `bool successful`, the repository turns `false` into `declined` and every error into `SpellEquipException`; state only via `characterUpdated`"

requirements-completed: []  # SPELL-03/04/06 foundations; traceability done by plan 08-12 (no mark-complete here)

# Metrics
duration: 12min
completed: 2026-10-27
---

# Phase 8 Plan 02: Equip/Unequip Mutation Slice Summary

**`EquipSpell`/`UnequipSpell` named mutations without `usages`, `KlimmeckGraphQl` methods returning only `successful`, a code-only `SpellEquipFailure` classifier (incl. `BAD_USER_INPUT`) and `SpellsRepository` with the 15 s guard**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-10-27T13:10:00Z
- **Completed:** 2026-10-27T13:22:00Z
- **Tasks:** 2 (4 TDD commits)
- **Files modified:** 12 (8 created, 4 modified)

## Accomplishments

- Request model `EquipSpellRequest` serialises `{id, spellId}` only; a test asserts `usages` is absent (T-8-03)
- Documents renamed to `EquipSpell`/`UnequipSpell` together with the registry keys in one commit (Pitfall 11); `test/tool/schema_check_documents_test.dart` green, registry still 34 entries
- `equipSpell`/`unequipSpell` service methods share a private `CommonResponse` reader; `FormatException` when `successful` is not a bool, raw `OperationException` otherwise (T-8-04)
- `spellEquipFailureFrom` maps the 8 codes by `extensions.code` only; link error without code → `connection`; anything else → `unknown` (T-8-05, T-8-07)
- `SpellsRepository`: timeout 15 s → `timedOut`, `false` → `declined`, `OperationException` → classified, anything else → `unknown` (T-8-06)

## Task Commits

1. **Task 1 RED: failing tests for the spell equip mutations** - `e718568` (test)
2. **Task 1 GREEN: send EquipSpell and UnequipSpell without usages** - `0b086a3` (feat)
3. **Task 2 RED: failing tests for spell equip failures** - `6340c3c` (test)
4. **Task 2 GREEN: map spell equip rejections to domain failures** - `ca9761d` (feat)

**Plan metadata:** see `docs(phase-8): record plan 02 progress`

### RED failure outputs

- Task 1: `test/models/request/equip_spell_request_test.dart:2:8: Error: Error when reading 'lib/models/request/equip_spell_request.dart': No such file or directory`; `graphql_spells_test.dart:93:34: Error: The method 'equipSpell' isn't defined for the type 'KlimmeckGraphQl'.` (compile failures); `spell_documents_test.dart`: `+4 -5: Some tests failed.` (operation names still lowercase, keys `EquipSpell`/`UnequipSpell` missing, lowercase keys still present)
- Task 2: `test/repository/spell_equip_failure_test.dart:5:8: Error: Error when reading 'lib/repository/spell_equip_failure.dart': No such file or directory`; `test/helpers/mocks.dart:88:52: Error: Type 'SpellsRepository' not found.` (compile failures, as expected)

## Public API for later plans (08-05, 08-06, 08-10)

```dart
// lib/models/request/equip_spell_request.dart
class EquipSpellRequest extends Equatable {
  const EquipSpellRequest({required String id, required String spellId});
  Map<String, dynamic> toJson(); // {'id', 'spellId'}
}

// lib/repository/services/graphql/graphql.dart (KlimmeckGraphQl)
Future<bool> equipSpell(EquipSpellRequest request);   // throws OperationException / FormatException
Future<bool> unequipSpell(EquipSpellRequest request);

// lib/repository/spell_equip_failure.dart
const String spellNotKnownCode = 'SPELL_NOT_KNOWN';
const String spellAlreadyActiveCode = 'SPELL_ALREADY_ACTIVE';
const String maxActiveSpellsReachedCode = 'MAX_ACTIVE_SPELLS_REACHED';
const String spellNotActiveCode = 'SPELL_NOT_ACTIVE';
const String badUserInputCode = 'BAD_USER_INPUT';
enum SpellEquipFailure {
  notKnown, alreadyActive, slotsFull, notActive, notFound, forbidden,
  badUserInput, unauthenticated, connection, timedOut, declined, unknown,
}
class SpellEquipException implements Exception {
  const SpellEquipException(SpellEquipFailure failure);
  final SpellEquipFailure failure; // toString() == 'SpellEquipException(<name>)'
}
SpellEquipFailure spellEquipFailureFrom(OperationException exception);

// lib/repository/spells_repository.dart
class SpellsRepository {
  SpellsRepository({required KlimmeckGraphQl graphQl, Duration timeout = defaultTimeout});
  static const Duration defaultTimeout = Duration(seconds: 15);
  final Duration timeout;
  Future<void> equip({required String characterId, required String spellId});   // throws only SpellEquipException
  Future<void> unequip({required String characterId, required String spellId}); // throws only SpellEquipException
}

// test/helpers/mocks.dart
class MockSpellsRepository extends Mock implements SpellsRepository {}
```

Notes for the cubit (08-06) and UI copy (08-10): `alreadyActive`/`notActive` are "stale client view" outcomes (D-17: no banner, silent realign); `timedOut` does not cancel the request, a successful change still arrives via `characterUpdated`; nothing in the repository returns state. `SpellsRepository` is not yet provided in the widget tree (wiring belongs to the plan that builds the cubit).

## Files Created/Modified

- `lib/models/request/equip_spell_request.dart` - request model without `usages`
- `lib/graphql/mutations/character_mutations.dart` - operation names `EquipSpell`/`UnequipSpell` (selection unchanged)
- `tool/schema_check/schema_check_documents.dart` - keys renamed; doc comment notes the Phase 8 rename
- `lib/repository/services/graphql/graphql.dart` - `equipSpell`, `unequipSpell`, private `_spellSlotMutation`
- `lib/repository/spell_equip_failure.dart` - codes, enum, exception, classifier
- `lib/repository/spells_repository.dart` - repository with the 15 s guard
- `test/helpers/mocks.dart` - `MockSpellsRepository`
- 5 test files listed in the frontmatter: request 3, documents 9, service 10, classifier 13, repository 13 cases

## Verification

- Task 1 verify: 24 tests green (3 request + 9 documents + 2 registry + 10 service); `flutter analyze` on the path set: no issues
- Task 2 verify: 26 tests green (13 classifier + 13 repository); `flutter analyze` on the path set reports only the baseline `unnecessary_cast` warning in `test/repository/services/auth/auth_token_service_contract_test.dart:40` (untouched since `4f08b40`, part of the 54) → the command exits 1 for that reason only
- Plan-end quick run: **+1665, all passed** (was +1617 after 08-01; +48 new)
- Full `flutter analyze`: **54 issues, 0 errors** (ceiling 54 until 08-03; no new issue)
- All format checks of the acceptance criteria exit 0; `test/graphql/travel_documents_test.dart` "registers 34 documents" still green

## Decisions Made

- The service tests and the repository tests run the same group body for equip and unequip through a small helper, instead of two copied groups (Clean Code, no duplication).
- An extra documents test asserts the lowercase keys `equipSpell`/`unequipSpell` are gone from the registry.

## Deviations from Plan

### Verify-command notes (no code change)

**1. Task 2 `<automated>` analyze step exits 1 because of a pre-existing warning**
- **Found during:** Task 2 verify
- **Issue:** `flutter analyze ... test/repository ...` reports `warning • Unnecessary cast • test/repository/services/auth/auth_token_service_contract_test.dart:40:15`, a baseline issue (last touched `4f08b40`, Phase 1) counted in the 54.
- **Fix:** none (out of scope). The new files analyze clean.

**2. Two acceptance greps of Task 1 need `\$` on macOS BSD grep**
- **Issue:** `grep -c "mutation EquipSpell(\$request: ...)"` in double quotes reaches grep as `$request`, which BSD grep treats as an anchor → `0`. With single quotes and `\$` (or `grep -F`) both counts are `1`, as required.
- **Fix:** none; behaviour verified by the documents tests.

---

**Total deviations:** 2 (verify-command notes, no code change)
**Impact on plan:** none; no scope creep.

## Issues Encountered

None.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 08-06 can inject `SpellsRepository` (mock: `MockSpellsRepository`, fallback `registerFallbackValue(const EquipSpellRequest(id: '', spellId: ''))` only when mocking `KlimmeckGraphQl`).
- 08-10 maps every `SpellEquipFailure` value to copy (12 values, listed above).
- 08-12: the schema check must still validate `EquipSpell`/`UnequipSpell` on BE `develop`.

## Self-Check: PASSED

---
*Phase: 08-spells-section-journal-tab*
*Completed: 2026-10-27*
