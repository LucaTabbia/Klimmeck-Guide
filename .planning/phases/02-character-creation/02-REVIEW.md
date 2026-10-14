---
phase: 02-character-creation
reviewed: 2026-10-09T09:31:46Z
depth: standard
files_reviewed: 78
files_reviewed_list:
  - lib/main.dart
  - lib/screens/auth/session_home.dart
  - lib/screens/auth/auth_gate.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/screens/auth/cubit/auth_cubit.dart
  - lib/repository/services/auth/auth_token_service.dart
  - lib/repository/services/auth/dev_auth_token_service.dart
  - lib/repository/services/auth/session_auth_token_service.dart
  - lib/screens/characterCreation/character_creation_screen.dart
  - lib/screens/characterCreation/components/character_creation_messages.dart
  - lib/screens/characterCreation/components/enum_choice_row.dart
  - lib/screens/characterCreation/components/portrait_column.dart
  - lib/screens/characterCreation/components/sheet_row.dart
  - lib/screens/characterCreation/components/sheet_text_field.dart
  - lib/screens/characterCreation/components/submit_bar.dart
  - lib/screens/characterCreation/cubit/character_creation_cubit.dart
  - lib/screens/characterCreation/cubit/character_creation_state.dart
  - lib/screens/characterCreation/cubit/character_draft.dart
  - lib/repository/character_creation_repository.dart
  - lib/repository/character_creation_failure.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/repository/services/rest/rest.dart
  - lib/repository/services/rest/image_upload_exception.dart
  - lib/repository/services/image/portrait_picker.dart
  - lib/repository/services/image/image_picker_portrait_picker.dart
  - lib/graphql/fragments/user_fragment.dart
  - lib/graphql/fragments/auth_session_fragment.dart
  - lib/graphql/fragments/fragments.dart
  - lib/graphql/mutations/character_mutations.dart
  - lib/graphql/queries/character_queries.dart
  - lib/graphql/queries/auth_queries.dart
  - lib/models/character/race_traits.dart
  - lib/models/request/create_character_request.dart
  - lib/models/enums/sex_type.dart
  - lib/shared/components/character_portrait.dart
  - lib/screens/mainScreen/main_screen.dart
  - lib/screens/mainScreen/tabs/profile/profile.dart
  - lib/screens/mainScreen/tabs/profile/components/profile_image.dart
  - lib/theme/kg_theme.dart
  - .fvmrc
  - android/app/build.gradle.kts
  - ios/Flutter/AppFrameworkInfo.plist
  - ios/Podfile
  - ios/Runner.xcodeproj/project.pbxproj
  - ios/Runner/Info.plist
  - pubspec.yaml
  - test/helpers/mocks.dart
  - test/helpers/landscape.dart
  - test/helpers/fakes/scripted_http_client_adapter.dart
  - test/helpers/fakes/scripted_http_client_adapter_test.dart
  - test/helpers/auth_fixtures.dart
  - test/helpers/fixtures/race_traits_fixture.dart
  - test/graphql/character_creation_documents_test.dart
  - test/models/character/race_traits_test.dart
  - test/models/enums/sex_type_test.dart
  - test/models/request/create_character_request_test.dart
  - test/repository/character_creation_failure_test.dart
  - test/repository/character_creation_repository_test.dart
  - test/repository/services/auth/dev_auth_token_service_transitions_test.dart
  - test/repository/services/auth/session_auth_token_service_adopt_user_test.dart
  - test/repository/services/graphql/graphql_character_creation_test.dart
  - test/repository/services/image/image_picker_portrait_picker_test.dart
  - test/repository/services/rest/rest_upload_test.dart
  - test/screens/auth/auth_gate_test.dart
  - test/screens/auth/authenticated_shell_test.dart
  - test/screens/auth/cubit/auth_cubit_test.dart
  - test/screens/auth/session_home_test.dart
  - test/screens/characterCreation/character_creation_screen_test.dart
  - test/screens/characterCreation/components/character_creation_messages_test.dart
  - test/screens/characterCreation/components/portrait_column_test.dart
  - test/screens/characterCreation/components/sheet_components_test.dart
  - test/screens/characterCreation/components/submit_bar_test.dart
  - test/screens/characterCreation/cubit/character_creation_cubit_test.dart
  - test/screens/characterCreation/cubit/character_draft_test.dart
  - test/screens/mainScreen/main_screen_test.dart
  - test/screens/mainScreen/tabs/profile/components/profile_image_test.dart
  - test/shared/components/character_portrait_test.dart
  - test/theme/kg_theme_test.dart
findings:
  critical: 0
  warning: 4
  info: 7
  total: 11
status: issues_found
---

# Phase 2: Code Review Report

**Reviewed:** 2026-10-09T09:31:46Z
**Depth:** standard
**Files Reviewed:** 78
**Status:** issues_found

## Summary

Reviewed the whole character-creation slice on `feat/character-creation` (merge-base with `develop`: `6e86c733`): the new feature folder `lib/screens/characterCreation/`, the repository/failure mapper, the GraphQL and REST service additions, the `adoptUser` handover across `AuthTokenService` → `AuthCubit` → `AuthGate` → `SessionHome`, the shared `CharacterPortrait`, the theme additions, native config and all 32 test files.

Baselines hold: `flutter analyze lib test` reports exactly the 12 pre-existing issues listed in D-34 (none in the reviewed files) and the 242 tests of the reviewed suites pass.

The security surface checked out clean: the upload goes through `RestClient`'s `AuthInterceptor` (bearer verified by `rest_upload_test`), Dio rewrites the content-type for `FormData`, the picked file never leaves the device before "Crea" (D-16), the server's error *text* is never shown (codes only, D-19) and every user-visible string is Italian domain copy. No secrets, no `eval`-class constructs, no technical messages reach the UI.

The architecture follows the project rules: the cubit is Flutter-free and receives the repository by constructor, the UI only triggers actions via `context.read`, side-effects live in a `BlocListener`, documents are in `lib/graphql/`, models are `Equatable` and Flutter-free, the creation screen is a utility screen so its `AppBar` is allowed, and D-01/D-02/D-26/D-27/D-28/D-29/D-30/D-31/D-32 are honoured in code.

Key concerns are all about resilience of the *handover* after a successful creation, which deliberately leaves the form locked (`isSubmitting: true`, "Esci" disabled) and relies on `AuthGate` unmounting the screen: two paths can defeat that and leave the player with a spinner and no exit (WR-01, WR-02). Two further UX-rule gaps: the portrait buttons' tap target is ~36 px instead of ≥ 44 (WR-03) and the age helper keeps saying "Consulto le cronache…" when traits are loaded but the chosen race is missing from the backend table (WR-04). Info items cover duplication, a doc/behaviour mismatch, the lingering `main.dart` import in the GraphQL service, theme-token semantics, a counter/validation mismatch and test organisation.

## Warnings

### WR-01: Handover can be silently dropped, leaving the form locked with no exit

**File:** `lib/screens/characterCreation/cubit/character_creation_cubit.dart:87` and `:118`, `lib/screens/characterCreation/character_creation_screen.dart:35-36` and `:60`, `lib/repository/services/auth/dev_auth_token_service.dart:94`, `lib/repository/services/auth/session_auth_token_service.dart:184`
**Issue:** On success (and on the `CHARACTER_ALREADY_EXISTS` recovery) the cubit emits `createdUser` while keeping `isSubmitting: true`, so every control — including "Esci" (`screen.dart:60`) — stays disabled; the only way out is `AuthCubit.adoptUser` making `AuthGate` swap the subtree. Both `adoptUser` implementations return silently when `user.id != current.user.id` (correct guard per D-26), but then nothing tells the cubit, and the player is stuck with a spinner until they kill the app. The mismatch is reachable in the dev bypass (D-03, the intended manual test path): `DevAuthTokenService._resolveUser` falls back to `DEV_AUTH_USER_ID` from `.env` when `me` times out at cold start (backend started after the app); the later `createCharacter` returns the backend's id, `adoptUser` ignores it, and the form is locked forever. In production the same dead-end would follow any future reason for `adoptUser` to decline.
**Fix:** Make the handover observable and give the player an exit:
```dart
// auth_token_service.dart
/// Ritorna false se la sessione non ha adottato lo user (non autenticata o id diverso).
bool adoptUser(User user);

// auth_cubit.dart
bool adoptUser(User user) => _authTokenService.adoptUser(user);

// character_creation_screen.dart (BlocListener.listener)
listener: (context, state) {
  final adopted = context.read<AuthCubit>().adoptUser(state.createdUser!);
  if (!adopted) context.read<CharacterCreationCubit>().handoverRejected();
},

// character_creation_cubit.dart
/// La sessione non ha accettato lo user creato: sblocca la scheda e avvisa.
void handoverRejected() =>
    emit(state.copyWith(isSubmitting: false, createdUser: null,
        submitFailure: CharacterCreationFailure.unknown));
```
and keep "Esci" usable once a user has been created: `onPressed: state.isSubmitting && state.createdUser == null ? null : () => confirmLogout(context)`. Add the red test first (`auth_gate_test`/`character_creation_screen_test`: "a rejected handover unlocks the sheet").

### WR-02: Parse errors in the already-exists recovery escape every catch and freeze the spinner

**File:** `lib/screens/characterCreation/cubit/character_creation_cubit.dart:88-93` and `:122-129`, `lib/repository/character_creation_repository.dart:60-68`, `lib/repository/services/graphql/graphql.dart:405-410`
**Issue:** `_existingCharacterOwner` only catches `CharacterCreationException`, and the repository `_guard` only maps `OperationException` and `FormatException`. `KlimmeckGraphQl._userFrom` → `User.fromJson` can throw `TypeError` (`"id": null`) or `ArgumentError` (`RoleType.values.byName` on an unknown role) — neither is mapped. Such an error raised while running `_handleSubmitFailure` *inside* the `on CharacterCreationException` clause of `submit()` is **not** caught by the sibling `catch (_)` (Dart does not route exceptions thrown in one catch clause to another of the same `try`), so `submit()` completes with an unhandled error and `isSubmitting` stays `true` forever — exactly the "spinner infinito" the generic catch was written to prevent (`:90-93`). The same gap exists in `createCharacter` itself, but there the outer `catch (_)` does rescue it.
**Fix:** Close the parse boundary where the JSON is read (same pattern as `RaceTraits.tryFromJson`) and make the recovery path total:
```dart
// graphql.dart
User _userFrom(Object? json) {
  if (json is! Map<String, dynamic>) throw const FormatException('user missing');
  try {
    return User.fromJson(json);
  } on Object catch (error) {
    // Parse boundary: TypeError/ArgumentError di fromJson diventano FormatException.
    throw FormatException('user malformed: ${error.runtimeType}');
  }
}

// character_creation_cubit.dart
Future<User?> _existingCharacterOwner() async {
  try {
    final user = await _repository.fetchCurrentUser();
    return user.currentCharacter == null ? null : user;
  } catch (_) {
    return null; // qualunque fallimento della rilettura → notice, mai spinner bloccato
  }
}
```
Optionally restructure `submit()` so the recovery runs after the `try` (capture the failure in a local, handle it outside), which also removes the "exception inside a catch clause" trap for future edits. Regression test: `fetchCurrentUser` stubbed to throw `StateError` → expect `isSubmitting == false`, `submitFailure == alreadyExists`.

### WR-03: Portrait action buttons fall below the 44×44 tap target

**File:** `lib/screens/characterCreation/components/portrait_column.dart:104-108`
**Issue:** `_action` sets `minimumSize: Size(44, 44)` to honour the ≥ 44 px rule (docs/rules/ui-ux.md), but combines it with `visualDensity: VisualDensity.compact` and `tapTargetSize: MaterialTapTargetSize.shrinkWrap`. `ButtonStyleButton` applies `VisualDensity.effectiveConstraints`, which subtracts `baseSizeAdjustment` (−8 px per axis for `compact`) from the minimum size → effective minimum 36×36; with `shrinkWrap` the hit area equals the visual size, so "Galleria", "Fotocamera" and "Rimuovi" end up ~36 px tall. The named constant documents the intent while the style defeats it.
**Fix:** Drop the density tweak (the width is already governed by the icon+label), or let Material pad the hit area:
```dart
style: TextButton.styleFrom(
  minimumSize: const Size(_minTapTarget, _minTapTarget),
  tapTargetSize: MaterialTapTargetSize.padded, // hit area ≥ 48 anche se compatto
  foregroundColor: KlimmeckGuideTheme.deepNight,
),
```
Add an assertion in `portrait_column_test`: `expect(tester.getSize(find.widgetWithText(TextButton, 'Galleria')).height, greaterThanOrEqualTo(44));`.

### WR-04: Age helper reports "loading" forever when the backend table lacks the chosen race

**File:** `lib/screens/characterCreation/character_creation_screen.dart:225-230`
**Issue:** `_helperText` returns `'Consulto le cronache delle razze…'` whenever `traits == null`, the status is not `failed` and a race is selected — including when `raceTraitsStatus == RaceTraitsStatus.loaded` but `raceTraits[race]` is absent (backend table missing an app-known race, which `getRaceTraits` tolerates by design). The field stays disabled, "Crea" stays disabled (`isCompleteFor` requires traits) and the copy promises a load that will never finish; the player has no hint to pick another race. D-11 lets the backend add races before the app, but not the reverse, so this edge is unhandled rather than impossible.
**Fix:** Distinguish the loaded-but-missing case and say so in domain language:
```dart
String? _helperText(RaceTraits? traits) {
  if (traits != null) return 'Tra ${traits.minAge} e ${traits.maxAge} anni';
  return switch (state.raceTraitsStatus) {
    RaceTraitsStatus.failed => null,
    RaceTraitsStatus.loading =>
      state.draft.race == null ? 'Scegli prima la razza' : 'Consulto le cronache delle razze…',
    RaceTraitsStatus.loaded =>
      state.draft.race == null
          ? 'Scegli prima la razza'
          : 'Le cronache non conoscono questa razza: scegline un\'altra',
  };
}
```
Alternatively disable the chips of races without traits once loaded. Add a widget test with `loadedState.copyWith(draft: CharacterDraft(race: RaceType.aarakocra), raceTraits: {...} /* senza aarakocra */)`.

## Info

### IN-01: Three identical catch bodies in `uploadPortrait`

**File:** `lib/repository/character_creation_repository.dart:40-52`
**Issue:** `on ImageUploadException`, `on DioException` and `on FileSystemException` each rethrow the same `CharacterCreationException(uploadFailed)` — triplicated code (Clean Code: zero duplicazione).
**Fix:**
```dart
Future<String> uploadPortrait(String localPath) async {
  try {
    return await _rest.uploadImage(File(localPath));
  } catch (error) {
    if (error is ImageUploadException || error is DioException || error is FileSystemException) {
      throw const CharacterCreationException(CharacterCreationFailure.uploadFailed);
    }
    rethrow;
  }
}
```

### IN-02: Repository doc promises a total translation it does not perform

**File:** `lib/repository/character_creation_repository.dart:15-16` and `:35`
**Issue:** The class comment says it "traduce ogni errore in `CharacterCreationException`", yet `pickPortrait` deliberately lets `PortraitPickException` through (the cubit handles it) and `_guard` maps only `OperationException`/`FormatException` (see WR-02). The comment misleads the next reader about the contract.
**Fix:** Either widen `_guard` (WR-02) and document the `PortraitPickException` exception explicitly, e.g. `/// ... tranne [PortraitPickException], che resta tipata per la UI del ritratto.`, or trim the claim to "errori di rete e di parsing".

### IN-03: `KlimmeckGraphQl` still depends on `main.dart` for the client

**File:** `lib/repository/services/graphql/graphql.dart:21` and `:36-37`
**Issue:** The service layer imports the composition root (`../../../main.dart`) to reach `navigatorKey.currentContext!` — an inversion of `UI → BLoC → Repository → Service` (docs/rules/architecture.md) that D-29 only worked around with the injectable `resolveClient`. The file also mixes relative and `package:` imports (`:20-26`). Pre-existing, but this phase touched the constructor, so the Boy Scout fix is cheap now.
**Fix:** Inject the resolver from `main.dart`, where the `ValueNotifier<GraphQLClient>` already lives, and delete the import:
```dart
// main.dart (_KlimmeckGuideAppState)
late final KlimmeckGraphQl graphQl =
    KlimmeckGraphQl(resolveClient: () => widget.graphQlClient.value);
```
Then remove `_clientFromNavigator` and make `resolveClient` required. This also removes the `currentContext!` null-bang.

### IN-04: Theme-token semantics drift in the new sheet widgets

**File:** `lib/theme/kg_theme.dart:180`, `lib/screens/characterCreation/components/portrait_column.dart:62-68`, `lib/screens/characterCreation/components/submit_bar.dart:41-44` and `:52`, `lib/screens/mainScreen/tabs/profile/components/profile_image.dart:14-20`
**Issue:** `spacingSm` (a spacing token) is used as a corner radius in both the theme's `_sheetBorder` and the portrait frame while a `radius` token exists; `SubmitBar` styles the button inline (`ElevatedButton.styleFrom(backgroundColor/foregroundColor)`, `strokeWidth: 2`) instead of an `elevatedButtonTheme`; `ProfileImage`, rewritten in this phase, keeps the magic numbers `10.0`, `200`, `Radius.circular(30)` (ui-ux.md: "Nuovo token → aggiungere al tema, non improvvisare").
**Fix:** Add `static const double radiusSm = 8;` (and use it in `_sheetBorder` and `PortraitColumn`), move the "Crea" colours into `materialTheme.elevatedButtonTheme`, and express `ProfileImage` paddings with `spacingSm`/`radius` tokens.

### IN-05: Background/name counters count graphemes, validation counts UTF-16 units

**File:** `lib/screens/characterCreation/components/sheet_text_field.dart:58-59`, `lib/screens/characterCreation/cubit/character_draft.dart:45-47` and `:52-53`
**Issue:** `TextField.maxLength` renders its counter from `characters.length` (grapheme clusters) of the raw text, while `isBackgroundTooLong`/`nameError` use `.length` (UTF-16 code units) of the *trimmed* text (D-32). With emoji or other surrogate pairs the counter can read "250/500" while the sheet refuses to submit, and trailing spaces inflate the counter without affecting validity.
**Fix:** Provide a `buildCounter` that mirrors the rule, e.g. `buildCounter: (_, {required currentLength, required isFocused, maxLength}) => Text('${value.trim().length}/$maxLength')`, or document the deliberate divergence next to `backgroundMaxLength`.

### IN-06: Unexpected picker errors are neither mapped nor surfaced

**File:** `lib/repository/services/image/image_picker_portrait_picker.dart:32-34`, `lib/screens/characterCreation/cubit/character_creation_cubit.dart:67-69`
**Issue:** The picker maps only `PlatformException`; the cubit catches only `PortraitPickException`. Any other error from `pickImage` becomes an unhandled async error with no `pickFailure` shown — no stuck state (there is no "picking" flag), but the player gets silence instead of "Impossibile usare questa immagine, riprova".
**Fix:** In the cubit add a trailing `catch (_) { emit(state.copyWith(pickFailure: PortraitPickFailure.unknown)); }`, mirroring the "garanzia anti-spinner" already used in `submit()`.

### IN-07: Test organisation nits

**File:** `test/helpers/fakes/scripted_http_client_adapter_test.dart:54-59`, `test/theme/kg_theme_test.dart:20-84`
**Issue:** The HTTP-adapter test file hosts a test for `buildTestUserWithCharacter`, an auth fixture, which breaks the mirror structure of docs/rules/testing.md; `kg_theme_test` uses `testWidgets` for pure value assertions without pumping any widget, paying the widget-binding cost for nothing.
**Fix:** Move the fixture test to `test/helpers/auth_fixtures_test.dart`; switch the theme assertions to plain `test()` (keep `GoogleFonts.config.allowRuntimeFetching = false` in `setUpAll`).

---

_Reviewed: 2026-10-09T09:31:46Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
