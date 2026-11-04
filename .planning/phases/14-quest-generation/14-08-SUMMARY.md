---
phase: 14-quest-generation
plan: 08
subsystem: innkeeper
tags: [innkeeper, ui, snackbar, confirmation-dialog, quest-generation, qgen-03, tdd]
requires:
  - 14-07 (QuestGenerationCubit, InnkeeperRepository.generateQuests, MockQuestGenerationCubit)
provides:
  - "`GenerateQuestsButton` (label «Genera missioni», key `innkeeper.generateQuests`, disabled while submitting)"
  - "`openInnkeeperPanel` provides a lazy `QuestGenerationCubit` next to `PendingRequestsCubit`"
  - "Locanda panel: button at the top outside the queue builder, neutral confirmation dialog, outcome SnackBars, FORBIDDEN closes the panel"
affects: [14-10, 14-11]
tech-stack:
  added: []
  patterns: [UI → Cubit → Repository, BlocSelector for the in-flight flag, BlocListener for one-shot outcomes]
key-files:
  created:
    - lib/screens/innkeeper/components/generate_quests_button.dart
    - test/screens/innkeeper/components/generate_quests_button_test.dart
  modified:
    - lib/screens/innkeeper/innkeeper_panel_route.dart
    - lib/screens/innkeeper/innkeeper_panel_screen.dart
    - test/screens/innkeeper/innkeeper_panel_route_test.dart
    - test/screens/innkeeper/innkeeper_panel_screen_test.dart
decisions:
  - "The button text is a plain `const Text(label)` like «Completa» on the request cards (the theme's `primaryButtonStyle` sets the colour), not the restyled `Text` of the plan skeleton"
  - "Unauthenticated and the other non-FORBIDDEN failures all fall into the generic retry SnackBar"
  - "Boy Scout: the teleport-failure listener now uses the shared `_showSnackBar` helper"
metrics:
  duration: ~12 min
  completed: 2026-11-04
  tasks: 3
  commits: 6
---

# Phase 14 Plan 08: «Genera missioni» in the Locanda Summary

«Genera missioni» now works in the Locanda, tested on mocks. The button sits at the top of the parchment, outside the queue `BlocBuilder`, so it shows while the queue loads, when the queue is empty and above the cards. Tapping it opens the shared confirmation dialog in the neutral style: «Generare nuove missioni nel mondo?» with «Genera» / «Annulla». «Annulla» sends nothing; «Genera» calls `QuestGenerationCubit.generate()` once. The button is disabled while the call is in flight. Each outcome shows a SnackBar: «Generate N missioni», «Generata 1 missione», «Nessuna missione da generare», or the fixed retry text. `FORBIDDEN` closes the panel through `_closeUnavailable` with «La Locanda non è disponibile». The panel route creates the cubit lazily with the route's `InnkeeperRepository`. No check ran against the BE schema in this plan, and the BE repo was not touched or read.

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | GenerateQuestsButton + cubit provider on the panel route | e3775da (test), 4d27e88 (feat) |
| 2 | Button at the top, confirmation dialog, disabled in flight | 0119167 (test), 53194c7 (feat) |
| 3 | Outcome SnackBars and FORBIDDEN closing the panel | a81e529 (test), 2e0d6b3 (feat) |

## Exact names and signatures

- `lib/screens/innkeeper/components/generate_quests_button.dart`: `class GenerateQuestsButton extends StatelessWidget`, `const GenerateQuestsButton({super.key, required bool isSubmitting, required VoidCallback onPressed})`, `static const Key buttonKey = ValueKey('innkeeper.generateQuests')`, `static const String label = 'Genera missioni'`; an `ElevatedButton` with `KlimmeckGuideTheme.primaryButtonStyle`, `onPressed: isSubmitting ? null : onPressed`.
- `innkeeper_panel_route.dart`: `MultiBlocProvider(providers: [BlocProvider<PendingRequestsCubit>(…unchanged…), BlocProvider<QuestGenerationCubit>(create: (_) => QuestGenerationCubit(repository: repository))], child: const InnkeeperPanelScreen())`.
- `InnkeeperPanelScreen` copy: `generateTitle = 'Genera missioni'`, `generateBody = 'Generare nuove missioni nel mondo?'`, `generateConfirmLabel = 'Genera'`, `noQuestsGeneratedMessage = 'Nessuna missione da generare'`, `generateFailedMessage = 'Non è stato possibile generare le missioni. Riprova.'`, `static String generatedMessage(int created)` (0 → none, 1 → «Generata 1 missione», n → «Generate n missioni»).
- Private: `_confirmGeneration(BuildContext)` (reads the cubit, `showDestructiveConfirmation(… confirmButtonStyle: KlimmeckGuideTheme.primaryButtonStyle)`, `if (confirmed && !generation.isClosed) await generation.generate()`); `_onGenerationOutcome(BuildContext, QuestGenerationState)`; `_showSnackBar(BuildContext, String)`.
- `_buildScaffold`: `SafeArea(child: Column([Padding(fromLTRB(spacingLg, spacingLg, spacingLg, 0), BlocSelector<QuestGenerationCubit, QuestGenerationState, bool>(…GenerateQuestsButton…)), Expanded(BlocBuilder<PendingRequestsCubit, …>)]))`.
- New `BlocListener<QuestGenerationCubit, QuestGenerationState>` in the `MultiBlocListener`, `listenWhen: current is Succeeded || current is Failed`.

## RED failures observed

- Task 1: compilation failure `Error when reading 'lib/screens/innkeeper/components/generate_quests_button.dart'` / `Method not found: 'GenerateQuestsButton'`; the route test failed with `ProviderNotFoundException: Could not find the correct Provider<QuestGenerationCubit> above this InnkeeperPanelScreen`.
- Task 2: the 7 new panel tests failed (no button, no dialog: the finder found nothing); the 28 existing tests stayed green with the new provider in the harness.
- Task 3: the 9 new outcome tests failed (no listener: no SnackBar, the panel stayed open on FORBIDDEN); 35 others green.

## Tests

- Task 1: `flutter test test/screens/innkeeper test/screens/mainScreen/components/teleport_mode_landing_test.dart test/screens/mainScreen/tabs/settings/components/innkeeper_section_test.dart` → 169 passed.
- Task 2: `flutter test test/screens/innkeeper` → 164 passed.
- Task 3 (plan verification): the Task 1 command → 185 passed.
- Analyzer after each task: `50 issues found`, all info, 0 error / 0 warning.
- Trailer check printed 0 after every commit.

## Acceptance greps

- Task 1: `class GenerateQuestsButton` 1; `isSubmitting ? null` 1; `QuestGenerationCubit(repository: repository)` 1; `D-(08|09|10|14))` 2 + 1 = 3.
- Task 2: `GenerateQuestsButton(` 1; `showDestructiveConfirmation` 1; `KlimmeckGuideTheme.primaryButtonStyle` 1; `Generare nuove missioni nel mondo?` 1; `BlocProvider<QuestGenerationCubit>.value` 4; `D-0[89])\|D-14)` 14.
- Task 3: `BlocListener<QuestGenerationCubit, QuestGenerationState>` 1; `InnkeeperFailure.forbidden` 1; `_closeUnavailable(context)` 3; `Nessuna missione da generare` 1; `grep -F 'Generate $created missioni'` 1; `D-09\|D-10\|D-14` **12** (the plan wants ≥ 14; see Deviations).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The mock cubit needs an `isClosed` stub**
- **Found during:** Task 2 (GREEN)
- **Issue:** `_confirmGeneration` checks `!generation.isClosed`. On `MockQuestGenerationCubit` that getter returns null without a stub, so «Genera» runs one generation threw `type 'Null' is not a subtype of type 'bool'`.
- **Fix:** `when(() => generationCubit.isClosed).thenReturn(false)` in the panel test `setUp` (the same pattern as `request_completion_screen_test.dart`).
- **Files modified:** test/screens/innkeeper/innkeeper_panel_screen_test.dart
- **Commit:** 53194c7

**2. [Acceptance grep] `D-09\|D-10\|D-14` counts 12 lines, not ≥ 14**
- The plan asked for the four failure tests to be written as a loop. That puts four test titles on one source line. At run time the file has 16 test titles that name D-09, D-10 or D-14. Every test the plan lists is present with its exact title, so the test file was not padded to reach the line count.

**3. [Style] Button child text**
- The plan's skeleton restyled the label with `bodyMedium.copyWith(color: parchment)`. The code uses `const Text(label)`, like the «Completa» button on `RequestCardView`; `primaryButtonStyle` already sets the colour.

### Other notes

- Subject `feat(innkeeper): add «Genera missioni» with confirmation to the Locanda` is 73 bytes and 71 characters. `wc -c` counts each guillemet as 2 bytes, so the subject is within the 72-character limit.
- `dart format` was run on each touched file one by one. Only the test files changed under the formatter (long titles wrapped).
- Repeated failures: the test «the same failure twice shows the SnackBar twice (D-10)» uses serials 1 and 2. After the first SnackBar times out (5 s pump), it checks that a second SnackBar shows.

## Known Stubs

None. The SnackBar wording is marked «Copy provvisoria» as D-09 says. It is final unless the UAT changes it.

## Threat Flags

None. T-14-17 is covered by the dialog with `barrierDismissible: false` and the disabled button. T-14-18 is covered by FORBIDDEN → `_closeUnavailable` and the existing AuthCubit listener. T-14-19 is covered by the fixed Italian copy; the server message is never shown.

## Self-Check: PASSED
