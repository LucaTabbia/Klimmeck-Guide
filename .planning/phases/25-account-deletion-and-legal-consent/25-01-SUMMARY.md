---
phase: 25-account-deletion-and-legal-consent
plan: 01
subsystem: signIn
tags: [consent, legal, login, link-opener, shared-preferences]
requires: []
provides:
  - LegalDocuments (termsUri, privacyUri, version '2026-11-24' provisional)
  - LegalConsentStore / SharedPreferencesLegalConsentStore (key klimmeck.legal.acceptedVersion)
  - InMemoryLegalConsentStore test fake (acceptedVersion, failOnRemember)
  - LegalConsentCubit (restore / accept / withdraw)
  - LegalConsentRow (checkbox + sentence with two link spans)
  - SignInCubit.openTerms / openPrivacy
  - AuthGate.legalConsentStore (required)
  - LinkOpener under lib/repository/services/links/
affects: [25-02, 25-05, 25-07]
tech-stack:
  added: []
  patterns:
    - TapGestureRecognizer spans owned and disposed by a StatefulWidget
    - store handed to AuthGate by constructor, like the shell stores
key-files:
  created:
    - lib/config/legal_documents.dart
    - lib/repository/storage/legal_consent_store.dart
    - lib/screens/signIn/consentCubit/legal_consent_cubit.dart
    - lib/screens/signIn/consentCubit/legal_consent_state.dart
    - lib/screens/signIn/components/legal_consent_row.dart
    - test/config/legal_documents_test.dart
    - test/repository/storage/legal_consent_store_test.dart
    - test/screens/signIn/consentCubit/legal_consent_cubit_test.dart
    - test/helpers/fakes/in_memory_legal_consent_store.dart
  modified:
    - lib/repository/services/links/link_opener.dart (moved from push/)
    - lib/repository/services/links/url_launcher_link_opener.dart (moved from push/)
    - lib/screens/signIn/sign_in_screen.dart
    - lib/screens/signIn/cubit/sign_in_cubit.dart
    - lib/screens/auth/auth_gate.dart
    - lib/bootstrap/klimmeck_guide_app.dart
    - lib/theme/kg_theme.dart
    - tool/hardening_check.sh
    - test/repository/services/push/push_boundaries_test.dart
    - test/screens/signIn/sign_in_screen_test.dart
    - test/screens/signIn/cubit/sign_in_cubit_test.dart
    - test/screens/auth/auth_gate_test.dart
    - test/screens/auth/auth_gate_dev_bypass_test.dart
    - test/screens/auth/identity_transitions_test.dart
    - test/screens/auth/authenticated_shell_leak_test.dart
decisions:
  - "Acceptance written on tick, removed on untick (research A3); a failing store keeps the tick for the screen"
  - "Version constant '2026-11-24' provisional (D-12); legal pages placeholder untouched"
  - "AuthGate receives LegalConsentStore by constructor; LegalConsentCubit takes the version as an argument"
  - "Disabled login = onTap null + Semantics(enabled: false) + Opacity(KlimmeckGuideTheme.disabledOpacity = 0.5), no new colour"
  - "The sentence's GestureDetector is excludeFromSemantics: the checkbox (labelled with the sentence) is the accessible toggle, each wording its own link node"
metrics:
  duration: ~10 min
  completed: 2026-11-25
  tasks: 4
  files: 26
---

# Phase 25 Plan 01: Legal consent on the login Summary

Consent checkbox «Accetto i Termini di servizio e l'Informativa sulla privacy» above the Twitch login with two tappable wordings opening the public legal pages through `LinkOpener`, device memory of the accepted version (`SharedPreferencesAsync`, key `klimmeck.legal.acceptedVersion`) restored by `LegalConsentCubit`, footer links removed, login disabled while unticked; `LinkOpener` moved to `services/links/`. Nothing new reaches today's BE.

## Suite baseline (Task 1, before any edit)

`01:52 +5549: All tests passed!` — **5549 green** on this branch (written into `25-VALIDATION.md`). Analyzer before the edits: «47 issues found». Analyzer after every task: «47 issues found. (ran in 5.1s)» `ANALYZE_GATE_OK`.

## Tasks

| Task | Commits |
|------|---------|
| 1 Baseline, move, constants | `5ca43ba3` refactor(shared): move LinkOpener out of the push services; `ef5a58c8` test(shared): expect the legal document links and version; `4b226fb6` feat(shared): add the legal document links and version |
| 2 Consent memory + Cubit | `12416594` test(signIn): expect the consent memory and its cubit; `3a11ed8f` feat(signIn): remember the accepted legal version on the device |
| 3 Checkbox row, footer removed, gated login | `eb8abcd4` test(signIn): expect the consent row and the disabled login; `be9e9c7c` feat(signIn): consent checkbox with the legal links, login gated on it |
| 4 Bookkeeping | `docs(phase-25): record plan 01 progress` |

## RED failures

- Task 1: compile failure — `Error when reading 'lib/config/legal_documents.dart': No such file or directory`, `Undefined name 'LegalDocuments'`.
- Task 2: compile failure — `lib/repository/storage/legal_consent_store.dart` missing, `SharedPreferencesLegalConsentStore` undefined (and the Cubit missing).
- Task 3: compile failure — `The method 'openTerms' isn't defined for the type 'SignInCubit'` (plus `openPrivacy`, `LegalConsentRow`, the `legalConsentStore` argument).

No case was green at the first run (all the new files failed to compile).

## Move commit (D-21)

`5ca43ba3`: two `git mv` (renames), six import lines, and the `push_boundaries_test.dart` pin edited in place to `'lib/repository/services/links/url_launcher_link_opener.dart'` (split over three lines by the formatter). The acceptance grep of the refactor commit prints nothing. The test files that use `RecordingLinkOpener` import the helper relatively and needed no change; only 6 lib/test files import `link_opener.dart` directly.

## Files formatted

Every touched file with `dart format <file>` one by one (all were formatter-clean beforehand, checked on their HEAD content). The formatter changed only my own edits: the `push_boundaries_test.dart` pin, `in_memory_legal_consent_store.dart`, `legal_consent_row.dart`, `sign_in_screen.dart`, `identity_transitions_test.dart`, `authenticated_shell_leak_test.dart`. No `style(...)` commit needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] One extra pump in `auth_gate_dev_bypass_test.dart`**
- **Found during:** Task 3 GREEN
- **Issue:** «logout shows sign-in and Twitch login re-enters instantly» tapped the login right after `settle`; the lazily created `LegalConsentCubit` restores the remembered version one frame later, so the button was still disabled (checkbox `false` at tap time, verified by a temporary print, then removed).
- **Fix:** `await tester.pump();` with a one-line comment before the tap. App behaviour unaffected (the restore is a microtask on the real device too).
- **Files modified:** `test/screens/auth/auth_gate_dev_bypass_test.dart`
- **Commit:** `be9e9c7c`

**2. Harness name kept**
- The plan calls the sign-in harness `pumpSignIn`; the existing `pumpScreen` was kept and gained `isConsentAccepted` (default `true`) and `rememberedVersion`, so the existing cases keep running ticked without a rename churn.

**3. Theme constant for the disabled opacity**
- `KlimmeckGuideTheme.disabledOpacity = 0.5` added next to `pendingInkOpacity` (the plan allowed a theme value or a literal `Opacity(0.5)`); `CheckboxThemeData` added in `materialTheme` (fill `primaryGold` when selected, transparent otherwise, check `deepNight`, side `parchment`).

**4. `tool/hardening_check.sh`** listed in Task 2 as planned (`|legal_consent_store` added to the `allowed=` alternation): `hardening_check: OK`.

## Accessibility notes

- The login's semantics node is `button`, `hasEnabledState`, `isEnabled: false` while unticked (test asserts with `containsSemantics`).
- The checkbox carries the sentence as `semanticLabel`; `find.semantics.byLabel('Termini di servizio')` / `('Informativa sulla privacy')` each find exactly one `isLink` node. The sentence's `GestureDetector` is `excludeFromSemantics: true` so it does not merge a tap action into the paragraph node.

## Known Stubs

None. The version `2026-11-24` is a deliberate provisional value (D-12): the user replaces it at the launch.

## Threat Flags

None beyond the plan's register (T-25-01: `grep -rn launchUrl lib/screens` empty; T-25-04: refactor commit imports only).

## For the next plans

- `AuthGate` now requires `legalConsentStore`; `KlimmeckGuideApp` owns `final LegalConsentStore legalConsentStore = SharedPreferencesLegalConsentStore();` — 25-02 can hand the same instance to the deletion teardown to call `forget()`.
- `InMemoryLegalConsentStore` exposes `acceptedVersion` and `failOnRemember`.
- `LegalConsentCubit` is provided lazily inside `AuthUnauthenticated`; widget tests that tap the login through the real gate need one pump after the sign-in screen appears.
- `login()` signature and `lib/graphql`, `lib/repository/services/auth` untouched (`git diff --stat 5c0b1b80` empty).

## Self-Check: PASSED

All created files exist; commits `5ca43ba3`, `ef5a58c8`, `4b226fb6`, `12416594`, `3a11ed8f`, `eb8abcd4`, `be9e9c7c` present in `git log`.
