---
phase: 08-spells-section-journal-tab
plan: 10
subsystem: state-management
tags: [flutter, dart, bloc-listener, spells, notifications, session-wiring]

# Dependency graph
requires:
  - phase: 08-02
    provides: "`SpellsRepository({required graphQl})`, `SpellEquipFailure` (12 values), `MockSpellsRepository`"
  - phase: 08-06
    provides: "`SpellsCubit` (`toggle`, `sync`), `SpellsState { pending, outcome }`, `SpellOutcome`, `SpellOutcomeKind`"
provides:
  - "`spellNoticeFor(SpellOutcome) → KGNotification?` + `spellEquipNoticeTitle` / `spellUnequipNoticeTitle`"
  - "`SpellOutcomeListener({required child})`: sync of every new loaded character, deduped banners, silent re-read on stale views"
  - "`BlocProvider<SpellsCubit>` in `AuthenticatedShell` (session lifetime); `SpellOutcomeListener` mounted in `MainScreen`"
  - "`MockSpellsCubit` in `test/helpers/mocks.dart`"
affects: [08-11, 08-12]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Session-level outcome listener (mirror of `TravelOutcomeListener` + `QuestAbandonOutcomeListener` stale-set re-read)"
    - "One-shot outcome reaction keyed on `previous.outcome != current.outcome` (the state keeps the last outcome)"

key-files:
  created:
    - lib/screens/mainScreen/tabs/journal/spellsCubit/spell_notice.dart
    - lib/screens/mainScreen/components/spell_outcome_listener.dart
    - test/screens/mainScreen/tabs/journal/spellsCubit/spell_notice_test.dart
    - test/screens/mainScreen/components/spell_outcome_listener_test.dart
  modified:
    - lib/screens/auth/authenticated_shell.dart
    - lib/screens/mainScreen/main_screen.dart
    - test/helpers/mocks.dart
    - test/screens/auth/authenticated_shell_test.dart
    - test/screens/mainScreen/main_screen_test.dart

key-decisions:
  - "The slots-full copy is one private constant `_slotsFullLine`, shared by `blockedSlotsFull` and `failed slotsFull` (no duplicated literal)"
  - "The character listener forwards only a NEW loaded character (`previous is! CharacterLoaded || previous.character != current.character`); the initial state is not forwarded (BlocListener never fires on it; `SpellsCubit` already records the character passed to `toggle`)"

patterns-established:
  - "Spell banner dedup key: `spell|<kind.name>|<failure.name or ->|<spellId>`"

requirements-completed: []  # SPELL-06 traceability is done by plan 08-12 (no mark-complete here)

# Metrics
duration: 15min
completed: 2026-10-27
---

# Phase 8 Plan 10: Spell Notices, SpellOutcomeListener and Session Wiring Summary

**`spellNoticeFor` turns every spell block or rollback into fixed Italian copy («Magia non equipaggiata» / «Magia non tolta»), and the session-level `SpellOutcomeListener` in `MainScreen` feeds every `characterUpdated` into the shell-provided `SpellsCubit`, publishes deduped banners through `publishNotice` and silently re-reads the character after the five stale-view rejections**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-10-27
- **Tasks:** 2 (4 TDD commits)
- **Files modified:** 9 (4 created, 5 modified)

## Accomplishments

- D-07/D-11/D-17 banner catalogue with an exhaustive switch (no `default`), titles chosen by `operation`, `null` for `alreadyActive`, `notActive`, `unauthenticated`; a `failed` outcome without a failure reads as `unknown`
- F1 silent realignment: `refreshCharacter()` (never emits `CharacterLoading`, CLAUDE.md rule 2) after `alreadyActive`, `notActive`, `notKnown`, `slotsFull`, `notFound`
- D-16: every new `CharacterLoaded` reaches `SpellsCubit.sync`, so pending operations clear as soon as the subscription confirms them
- F3 / Pitfall 1: `SpellsCubit` lives for the session (closed with the shell), the listener sits at `MainScreen` level, so pending operations and banners survive a tab change (proved by a main-screen test on page 0)

## Public API (for plans 08-11 and 08-12)

```dart
// lib/screens/mainScreen/tabs/journal/spellsCubit/spell_notice.dart
const String spellEquipNoticeTitle = 'Magia non equipaggiata';
const String spellUnequipNoticeTitle = 'Magia non tolta';
KGNotification? spellNoticeFor(SpellOutcome outcome);

// lib/screens/mainScreen/components/spell_outcome_listener.dart
class SpellOutcomeListener extends StatelessWidget {
  const SpellOutcomeListener({Key? key, required Widget child});
}
```

Listener behaviour per outcome:

| Outcome | Banner (description) | `refreshCharacter()` |
|---|---|---|
| `blockedSlotsFull` | Slot pieni: disequipaggia una magia | no |
| `blockedNoSlots` | Nessuno slot disponibile | no |
| `failed notKnown` | Non conosci questa magia | yes |
| `failed alreadyActive` | none | yes |
| `failed slotsFull` | Slot pieni: disequipaggia una magia | yes |
| `failed notActive` | none | yes |
| `failed notFound` | Questa magia non è più disponibile | yes |
| `failed forbidden` | Questo personaggio non può farlo | no |
| `failed badUserInput` / `unknown` | Qualcosa è andato storto, riprova | no |
| `failed unauthenticated` | none | no |
| `failed connection` | Connessione assente, riprova | no |
| `failed timedOut` | Il server non ha risposto in tempo: controlla le magie prima di riprovare | no |
| `failed declined` | Il server ha rifiutato la richiesta, riprova | no |

Title: «Magia non tolta» for `unequip`, «Magia non equipaggiata» otherwise (blocked outcomes are always `equip`). Dedup key `spell|<kind>|<failure or ->|<spellId>` (5 s window of `publishNotice`). The listener reacts only when `outcome` changes (`current.outcome != null && previous.outcome != current.outcome`), so `pending`-only changes do nothing.

How things are provided now:
- `AuthenticatedShell` provides `BlocProvider<SpellsCubit>(create: (_) => SpellsCubit(SpellsRepository(graphQl: graphQl)))` right after `TravelCubit`. There is no separate `RepositoryProvider<SpellsRepository>`: the repository is owned by the cubit. **08-11: read `context.read<SpellsCubit>()` in the section; never add a `BlocProvider<SpellsCubit>` under `tabs/`.**
- `MainScreen`: `TravelOutcomeListener(child: SpellOutcomeListener(child: Scaffold(…)))`. The section does not need its own outcome listener for banners or sync; it only needs to listen to `outcome` for the D-18 spring-back/shake (`failed` → spring-back, blocked → resist signal).
- Tests that pump `MainScreen` with a loaded `MainScreenLoadData` must now provide `BlocProvider<SpellsCubit>` (use `MockSpellsCubit` + `whenListen(…, initialState: const SpellsState())`, Pitfall 9) — `main_screen_test.dart` satchel group already does.

## Task Commits

1. **Task 1 RED: notice + listener tests, MockSpellsCubit** - `88390ec` (test)
2. **Task 1 GREEN: announce spell rollbacks and realign stale views** - `3d897df` (feat)
3. **Task 2 RED: session wiring tests** - `6ac5ef5` (test)
4. **Task 2 GREEN: keep spell operations alive across tabs** - `8ed55cc` (feat)

**Plan metadata:** `docs(phase-8): record plan 10 progress`

### RED failure outputs

- Task 1: compile failure — `spell_notice_test.dart:5:8: Error: Error when reading 'lib/screens/mainScreen/tabs/journal/spellsCubit/spell_notice.dart': No such file or directory`, `Error: Method not found: 'spellNoticeFor'.`; `spell_outcome_listener_test.dart:12:8: Error: Error when reading 'lib/screens/mainScreen/components/spell_outcome_listener.dart': No such file or directory`, `Error: Couldn't find constructor 'SpellOutcomeListener'.`
- Task 2: `+34 -2: Some tests failed.` — shell: `ProviderNotFoundException … Could not find the correct Provider<SpellsCubit>` / `LateInitializationError: Local 'spellsCubit' has not been initialized.`; main screen: `No matching calls (actually, no calls at all).` on `publishNotice`.

## Verification

- Task verifies: notice + listener 37 tests green; `flutter test test/screens/auth test/screens/mainScreen/main_screen_test.dart test/screens/mainScreen/components` 232 green; per-task `flutter analyze` no issues.
- Plan-end quick run `flutter test test/models test/utils test/graphql test/repository test/tool test/shared test/screens/mainScreen test/screens/auth`: +1875, all passed.
- Full `flutter analyze`: 53 issues (≤ 53), 0 errors.
- Acceptance greps all as specified (1/0/1/1/1/1/0/1; `BlocProvider<SpellsCubit>` under `lib/screens/mainScreen/tabs` prints nothing); `dart format --set-exit-if-changed` on the 9 touched files exits 0.

## Decisions Made

See frontmatter `key-decisions`.

## Deviations from Plan

None that change behaviour.
- Boy Scout: the slots-full copy is a private constant reused in both switches instead of a duplicated literal (the acceptance grep for `'Nessuno slot disponibile'` still counts 1).
- `main_screen.dart` diff is larger (≈57 lines) than the logical change: wrapping the `Scaffold` re-indented its subtree after `dart format` (the file was measured clean before the edit, as the plan says).

## Issues Encountered

None.

## Known Stubs

None. Banner copy is provisional by design (D-17, no UI phase).

## Threat Flags

None — no new network surface. T-8-26..T-8-30 mitigations implemented and tested (silent re-read, enum-only copy + token loop, no banner/refresh on `UNAUTHENTICATED`, dedup key, cubit closed with the shell).

## Next Phase Readiness

08-11 can build the Journal section on `context.read<SpellsCubit>()` and `SpellRecoveryCubit` (section-owned); 08-12 does the requirement traceability (SPELL-06).

## Self-Check: PASSED

- FOUND: spell_notice.dart, spell_outcome_listener.dart, spell_notice_test.dart, spell_outcome_listener_test.dart
- FOUND commits: 88390ec, 3d897df, 6ac5ef5, 8ed55cc

---
*Phase: 08-spells-section-journal-tab*
*Completed: 2026-10-27*
