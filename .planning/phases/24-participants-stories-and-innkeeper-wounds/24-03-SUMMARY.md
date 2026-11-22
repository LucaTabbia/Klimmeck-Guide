---
phase: 24-participants-stories-and-innkeeper-wounds
plan: 03
subsystem: innkeeper
tags: [stories, dropdown, shared-components, participants-cubit]
requires: ["24-02"]
provides:
  - "BackgroundEntries in lib/shared/components (the one renderer of background entries)"
  - "StoryReader (characterId, name, title) and ParticipantStory (closed Dropdown, entries nullable + pendingLine)"
  - "MissionParticipantsCubit.ensureLoaded(ids): one read per set of ids; load(ids) stays the retry"
  - "MissionParticipantsLoaded.backgroundOf(id) / titleOf(id), null for an unknown id"
affects: [24-04, 24-05, 24-06]
tech-stack:
  added: []
  patterns: ["a nullable list plus a pending line instead of a loading flag", "the Cubit remembers the ids of its last read (private Set)"]
key-files:
  created:
    - lib/screens/innkeeper/missionCompletion/components/participant_story.dart
    - test/shared/components/background_entries_test.dart
    - test/screens/innkeeper/missionCompletion/components/participant_story_test.dart
  modified:
    - lib/shared/components/background_entries.dart (moved from the Profile components)
    - lib/screens/mainScreen/tabs/profile/profile.dart
    - lib/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart
    - lib/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_state.dart
    - test/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit_test.dart
decisions:
  - "ParticipantStory takes entries nullable plus a pendingLine: the page passes the reading line or the failure line, no boolean flag"
  - "backgroundOf gives an empty list for a loaded character with no served infos and null only for an unknown id"
  - "ensureLoaded compares sets of ids, so the order of the participants does not trigger a second read"
metrics:
  duration: "~25 min"
  completed: 2026-11-21
---

# Phase 24 Plan 03: Shared story pieces Summary

`BackgroundEntries` is a shared component, each participant's story is one closed `Dropdown` titled «<nome> · <rango>», and the participants can be read once with the card's ids before the draft exists.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 move | Promote BackgroundEntries to the shared components | 3db9fa7f |
| 1 RED | Expect one story dropdown per participant | 689bffc0 |
| 1 GREEN | Draw a participant's story in a dropdown | ebbcf4cc |
| 2 RED | Expect the participants read once before the draft | 2f7f2c3e |
| 2 GREEN | Read the participants once, also before the draft | ffe0e0a5 |
| 3 | Bookkeeping | (this docs commit) |

## TDD

- **Move (3db9fa7f):** `git mv` (100 % rename) plus the import in `profile.dart`; `flutter test test/screens/mainScreen/tabs/profile` → 7 passed.
- **Task 1 RED (689bffc0):** `participant_story_test.dart` did not compile (missing widget), as expected. `background_entries_test.dart` was NOT fully green at the first run, unlike the plan foresaw: 2 passed, 1 failed (see Deviations).
- **Task 1 GREEN (ebbcf4cc):** `flutter test test/shared/components test/screens/innkeeper test/screens/mainScreen/tabs/profile` → 783 passed.
- **Task 2 RED (2f7f2c3e):** compile failure (`ensureLoaded` undefined; `backgroundOf` / `titleOf` undefined).
- **Task 2 GREEN (ffe0e0a5):** `flutter test test/screens/innkeeper` → 351 passed; plan verification `flutter test test/shared/components test/screens/innkeeper test/screens/mainScreen/tabs/profile` → 791 passed.

## Gates

- Analyzer after the move and after each GREEN: `47 issues found.` → `ANALYZE_GATE_OK`.
- Trailer check after every commit: `0`.
- `grep -rn "profile/components/background_entries.dart" lib test` → empty; `showDialog|showModalBottomSheet` in `participant_story.dart` → 0; `Future<void> ensureLoaded` → 1.
- Formatted one by one; every existing file was formatter-clean before the edits (no `style` commit).
- Full suite not run (REPO-RULES: only in 24-01 and 24-10).

## Deviations from Plan

**1. [Rule 1 - Bug in the new test] The shared test was committed with one red case in the RED commit**
- **Found during:** Task 1, GREEN run.
- **Issue:** «no entry, nothing drawn» asserted a height of 0, but the `Column` of `BackgroundEntries` fills its parent (600 in the harness). The assertion was wrong, the widget is unchanged (the Profile draws exactly as before). The RED commit `689bffc0` therefore holds one failing case in `background_entries_test.dart`, which the plan expected green at the first run.
- **Fix:** the case now checks what is drawn (no `Text`, no sigil, no exception). Fixed in the GREEN commit `ebbcf4cc`.

Details worth knowing:

- No test in the repo mounts a `Dropdown` directly, so the «closed at first» case asserts on the `SizeTransition` factor (0 → 1) and on `hitTestable()`.
- Two cases beyond the plan's list: «a failed read shows the line the page gives» and the `StoryReader` equality.

## Out of scope, not touched

- `bash tool/hardening_check.sh` fails on this stacked branch with «lib/repository/storage/new_entries_store.dart writes SharedPreferences outside the allow-list»: the file comes from `fix/ui-layout-review`, this plan touched neither it nor `tool/`. Nothing of this plan writes to storage or logs a story (T-24-10): the entries live only in the Cubit state. To settle before the gate of 24-10 (allow-list entry or a ruling).

## Notes for the next plans

- `ParticipantStory(reader:, entries:, pendingLine:)`: `entries == null` → `pendingLine` (pass `ParticipantStory.readingLine` while reading, the failure line after a failed read); `[]` → `ParticipantStory.emptyLine`. Key: `ParticipantStory.keyFor(characterId)` = `mission.story.<id>`, set on the inner `Dropdown`. The body stays built while closed: tests open it by tapping `DropdownHeader` and pumping ~400 ms, and seed `CloudinaryAssets.arrowDown`.
- `ensureLoaded(ids)` is dropped while `Loading` even for different ids (like `load`): a page that changes its set of ids during a read must call it again after the outcome. After `Failed` it reads again; `load` always reads again.
- `backgroundOf(id)` → `null` for an unknown id (show the pending line), `[]` for a loaded character with no entries; `titleOf(id)` → `null` when unknown or not served.
- `BackgroundEntries`' `Column` is `MainAxisSize.max`: mount it inside a scroll view or a `Dropdown`, as today.

## Known Stubs

None. `ParticipantStory` and `ensureLoaded` have no consumer until 24-04, by design.

## Self-Check: PASSED

Created and moved files exist; commits `3db9fa7f`, `689bffc0`, `ebbcf4cc`, `2f7f2c3e`, `ffe0e0a5` are in `git log`.
