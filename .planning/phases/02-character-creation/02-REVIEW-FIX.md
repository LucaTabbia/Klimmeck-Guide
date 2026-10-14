---
phase: 02-character-creation
fixed_at: 2026-10-09T09:58:09Z
review_path: .planning/phases/02-character-creation/02-REVIEW.md
iteration: 1
fix_scope: critical_warning
findings_in_scope: 4
fixed: 4
skipped: 0
info_fixed: 1
status: all_fixed
---

# Phase 2: Code Review Fix Report

**Fixed at:** 2026-10-09T09:58:09Z
**Source review:** .planning/phases/02-character-creation/02-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope (Critical + Warning): 4
- Fixed: 4
- Skipped: 0
- Info findings fixed opportunistically: 1 (IN-03)

**Verification after the last commit:**
- `flutter test`: 481 tests green (baseline 470 + 11 new regression tests)
- `flutter analyze lib test`: 12 issues, identical to the D-34 baseline (none in touched files)
- `dart format --output=none --set-exit-if-changed` clean on every touched file (no directory-wide format)
- Every fix followed red → green: the new tests were run and seen failing for the intended reason before the source change
- No `Co-Authored-By` trailer in any commit (`git log 561f22a..HEAD --format=%B`)

## Fixed Issues

### WR-01: Handover can be silently dropped, leaving the form locked with no exit

**Files modified:** `lib/repository/services/auth/auth_token_service.dart`, `lib/repository/services/auth/dev_auth_token_service.dart`, `lib/repository/services/auth/session_auth_token_service.dart`, `lib/screens/auth/cubit/auth_cubit.dart`, `lib/screens/characterCreation/cubit/character_creation_cubit.dart`, `lib/screens/characterCreation/cubit/character_creation_state.dart`, `lib/screens/characterCreation/character_creation_screen.dart`, `lib/repository/character_creation_failure.dart`, `lib/screens/characterCreation/components/character_creation_messages.dart`, `test/repository/services/auth/session_auth_token_service_adopt_user_test.dart`, `test/repository/services/auth/dev_auth_token_service_transitions_test.dart`, `test/screens/auth/cubit/auth_cubit_test.dart`, `test/screens/characterCreation/cubit/character_creation_cubit_test.dart`, `test/screens/characterCreation/character_creation_screen_test.dart`, `test/screens/characterCreation/components/character_creation_messages_test.dart`
**Commit:** `a5dd474` — `fix(character-creation): keep the exit reachable when the session refuses the created user`
**Applied fix:**
- `AuthTokenService.adoptUser` now returns `bool`; both implementations return `false` (and emit nothing) when the session is not authenticated or the id differs (D-26), `true` after re-emitting `AuthAuthenticated`. `AuthCubit.adoptUser` forwards the verdict.
- The screen's `BlocListener` (`_handOverCreatedUser`) calls `CharacterCreationCubit.handoverRejected()` when the session refuses the user; the cubit unlocks the sheet (`isSubmitting: false`, `createdUser: null`) and shows a notice.
- Deviation from the review snippet: instead of reusing `CharacterCreationFailure.unknown` ("riprova", which would be misleading because the character already exists) a dedicated `CharacterCreationFailure.handoverRejected` was added with the copy *"Personaggio creato, ma la sessione non lo riconosce: esci e rientra"* (D-18 domain language, points the player to the exit).
- `CharacterCreationState.canExit` (`!isSubmitting || createdUser != null`) drives "Esci", which therefore stays enabled once a user has been created (D-29). The existing "everything locked while submitting" test still holds for the in-flight case.
- New tests: service/cubit return values (true/false), `handoverRejected` state sequence, `canExit` table, widget test "a handover refused by the session is reported to the cubit", widget test "Esci stays reachable once the user has been created", message copy.
- Status note: logic fix covered by bloc/widget tests; the real-world reproduction (dev bypass with `me` timing out at cold start) can only be confirmed on a device — recommended manual check during UAT.

### WR-02: Parse errors in the already-exists recovery escape every catch and freeze the spinner

**Files modified:** `lib/repository/services/graphql/graphql.dart`, `lib/screens/characterCreation/cubit/character_creation_cubit.dart`, `test/repository/services/graphql/graphql_character_creation_test.dart`, `test/screens/characterCreation/cubit/character_creation_cubit_test.dart`
**Commit:** `adb0854` — `fix(character-creation): never freeze the spinner on a malformed user in the already-exists recovery`
**Applied fix:**
- `KlimmeckGraphQl._userFrom` wraps `User.fromJson` and converts any `TypeError`/`ArgumentError` into `FormatException` (parse boundary, same pattern as `RaceTraits.tryFromJson`), which the repository `_guard` already maps to `unknown`.
- `_existingCharacterOwner` now catches everything (any failure of the `me` re-read means "no owner" → `alreadyExists` notice, never a stuck spinner).
- `submit()` was restructured as suggested in the optional part of the review: `_createCharacter()` returns the `CharacterCreationFailure?` out of the `try`, and `_handleSubmitFailure` runs afterwards, so no recovery code executes inside a `catch` clause anymore.
- New tests: `createCharacter` with `"id": null` and `getMe` with an unknown role both throw `FormatException`; cubit test "alreadyExists with an unexpected re-read error never leaves the spinner" (`fetchCurrentUser` throws `StateError`, expects `isSubmitting == false`, `submitFailure == alreadyExists`, no unhandled error).

### WR-03: Portrait action buttons fall below the 44×44 tap target

**Files modified:** `lib/screens/characterCreation/components/portrait_column.dart`, `test/screens/characterCreation/components/portrait_column_test.dart`
**Commit:** `2ff5788` — `fix(character-creation): give the portrait buttons a 44 px tap target`
**Applied fix:**
- Removed `visualDensity: VisualDensity.compact` (it subtracted 8 px from the 44 px minimum) and switched `tapTargetSize` to `MaterialTapTargetSize.padded`, so the hit area is ≥ 48 px while the visual button keeps `minimumSize` 44×44. Comment explains why the density tweak must not come back.
- Widget test "every action button meets the 44x44 tap target" asserts width and height ≥ 44 for Galleria / Fotocamera / Rimuovi. Note on the test: the default test font is much wider than the real one, so in the 220 px column the labels wrap to two lines and the measured height (86 px) was already dominated by the text; the test therefore pumps the column at 700 px (one-line labels), where the pre-fix height measured 43 px (red) and the post-fix height is ≥ 48 (green). The `build` helper gained an optional `width` parameter (default unchanged).

### WR-04: Age helper reports "loading" forever when the backend table lacks the chosen race

**Files modified:** `lib/screens/characterCreation/character_creation_screen.dart`, `test/screens/characterCreation/character_creation_screen_test.dart`
**Commit:** `2a91667` — `fix(character-creation): tell the player when the chronicles lack the chosen race`
**Applied fix:**
- `_AgeField._helperText` distinguishes `RaceTraitsStatus.loading` ("Consulto le cronache delle razze…") from `loaded` without traits for the chosen race, which now reads *"Le cronache non conoscono questa razza: scegline un'altra"*. Precedence kept: traits → range; `failed` → no helper (the retry row speaks); no race → "Scegli prima la razza".
- New widget tests: "a chosen race still being loaded says so" and "a chosen race missing from the loaded table asks for another" (`testRaceTraits` without aarakocra, race aarakocra selected).

## Info Findings Fixed Opportunistically

### IN-03: `KlimmeckGraphQl` still depends on `main.dart` for the client

**Files modified:** `lib/repository/services/graphql/graphql.dart`, `lib/main.dart`, `lib/repository/services/graphql/graphql_client_holder.dart`, `test/screens/auth/authenticated_shell_test.dart`
**Commit:** `0d5c625` — `refactor(graphql): inject the client resolver instead of importing main.dart`
**Applied fix:** `resolveClient` is now a required constructor argument; `main.dart` passes `() => widget.graphQlClient.value` (the `ValueNotifier` it already owns, same source `GraphQLProvider` exposes), `_clientFromNavigator` and the `import '../../../main.dart'` are gone, the facade uses `package:` imports only, and the holder's doc comment describes the new wiring. `authenticated_shell_test` uses `MockKlimmeckGraphQl()` instead of a real facade. Pure structural refactor: existing tests stayed green, no behaviour change.

## Skipped Issues

None — all in-scope findings were fixed.

## Info Findings Deliberately Not Addressed (out of `critical_warning` scope)

- **IN-01** (three identical catch bodies in `uploadPortrait`) — not touched by any warning fix.
- **IN-02** (repository doc overstates the translation) — the `_guard` behaviour is unchanged by WR-02 (the boundary moved into the facade), so the doc nit remains as reviewed.
- **IN-04** (theme-token semantics: `spacingSm` as radius, inline button colours, `ProfileImage` magic numbers) — theme/UI polish, out of scope.
- **IN-05** (counter vs validation length units) — out of scope.
- **IN-06** (unexpected picker errors not surfaced) — out of scope; note it is the picker-side twin of the WR-02 pattern and is a one-line `catch (_)` in `pickPortrait` when picked up.
- **IN-07** (test organisation nits) — out of scope.

---

_Fixed: 2026-10-09T09:58:09Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
