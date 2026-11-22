---
phase: 24-participants-stories-and-innkeeper-wounds
reviewed: 2026-11-22T00:00:00Z
depth: deep
diff_base: fix/ui-layout-review
files_reviewed: 42
files_reviewed_list:
  - lib/config/story_and_wound_corrections.dart
  - lib/graphql/fragments/character_fragment.dart
  - lib/graphql/fragments/mission_draft_fragment.dart
  - lib/graphql/fragments/quest_result_fragment.dart
  - lib/models/character/character_status.dart
  - lib/models/mission/mission_draft.dart
  - lib/models/mission/mission_fight.dart
  - lib/models/quest_result/quest_result.dart
  - lib/models/request/mission_draft_inputs.dart
  - lib/repository/innkeeper_failure.dart
  - lib/screens/characterCreation/character_creation_screen.dart
  - lib/screens/innkeeper/components/injury_chips.dart
  - lib/screens/innkeeper/missionCompletion/components/correction_section.dart
  - lib/screens/innkeeper/missionCompletion/components/mission_step_header.dart
  - lib/screens/innkeeper/missionCompletion/components/participant_story.dart
  - lib/screens/innkeeper/missionCompletion/missionDraftCubit/mission_draft_cubit.dart
  - lib/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart
  - lib/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_state.dart
  - lib/screens/innkeeper/missionCompletion/mission_completion_screen.dart
  - lib/screens/innkeeper/missionCompletion/steps/additions_step.dart
  - lib/screens/innkeeper/missionCompletion/steps/fight_step.dart
  - lib/screens/innkeeper/missionCompletion/steps/recap_step.dart
  - lib/screens/innkeeper/missionCompletion/steps/start_step.dart
  - lib/screens/innkeeper/missionCompletion/steps/stories_step.dart
  - lib/screens/mainScreen/characterCubit/character_selectors.dart
  - lib/screens/mainScreen/components/quest_scope_listener.dart
  - lib/screens/mainScreen/tabs/board/board.dart
  - lib/screens/mainScreen/tabs/journal/components/injury_name_icon.dart
  - lib/screens/mainScreen/tabs/journal/components/potion_sheet.dart
  - lib/screens/mainScreen/tabs/journal/journal.dart
  - lib/screens/mainScreen/tabs/journal/sections/items_section.dart
  - lib/screens/mainScreen/tabs/map/layers/quest_markers_layer.dart
  - lib/screens/mainScreen/tabs/map/world_map.dart
  - lib/screens/mainScreen/tabs/profile/components/background_entries.dart
  - lib/screens/mainScreen/tabs/profile/components/profile_image.dart
  - lib/screens/mainScreen/tabs/profile/profile.dart
  - lib/shared/components/background_entries.dart
  - lib/shared/components/healed_injuries_text.dart
  - lib/shared/components/item_row.dart
  - lib/shared/components/popup/quest_result_sheet.dart
  - lib/shared/components/sheet_text_field.dart
  - lib/utils/item_lines.dart
findings:
  critical: 0
  warning: 1
  info: 3
  total: 4
status: issues_found
---

# Phase 24: Code Review Report

**Reviewed:** 2026-11-22
**Depth:** deep (cross-file: screen, cubits, input builders, models, fragments; the BE counting and place rules read on `develop`, read-only)
**Scope:** `git diff fix/ui-layout-review..HEAD -- lib tool` (42 files under `lib/`; the diff of `tool/` is empty at this base). Tests under `test/` read as context only.
**Status:** issues_found

## Summary

The phase is in good shape. The points the brief asked to check were traced in the code and hold:

- **Additions, state and ids.** The texts live in the screen State, are seeded once from the cubit's served draft at the first entry of the last page (resume on step `stories`, entry from the recap, teleport resume through `opensAtPlace`) and are never reseeded. `backgroundAdditionsInputOf` walks the draft's participants and keys the texts by `characterId`, one entry per participant, trimmed, empty ones included: no path sends a text for another character. Unsaved text is saved on «Indietro», on leaving (PopScope) and by «Concludi».
- **Completion vs queue.** `conclude` keeps `isSubmitting` true across the save and the completion (the intermediate emit carries the saved draft with the flag on), so `_leaveGoneUnlessCalling` cannot pop `CompletionGone` between the two calls; a refused save completes nothing; a refused completion leaves the saved draft served with the flag off.
- **Async gaps.** Every `await` in the screen is followed by a `mounted` check before `context`, `setState` or `_leave`; both cubits use `SafeEmit`.
- **Controllers and focus.** `SheetTextField` owns and disposes its controller; the closed dropdown keeps the field mounted (`SizeTransition`) and `ExcludeFocus` takes the focus away.
- **Length rule.** `text.trim().characters.length > 1000` matches the BE (`trim()` then `Intl.Segmenter` graphemes); the BE's extra cap of 8000 UTF-16 units is not mirrored and does not need to be (UX only, D-07).
- **Removals.** `injuriesRemoved` leaves the app only when the list is not empty or `declaresRemovals` is set, and `declaresRemovals` is set in one function (`_correctionsOf`) from the switch; with the switch off the chips cannot produce a removal. Un-removing drops the wound from the added list (D-16). The innkeeper mark comes only from served lists.
- **Player side.** D-15, D-18, D-20, D-21, D-22 are implemented as written; `Text.rich` in `HealedInjuriesText` exposes the same plain string to screen readers as the old `Text`.
- **Architecture.** No networking in widgets, no Flutter import in `lib/models`, the new fields are selected in exactly three fragments.

One warning: the participants are no longer reread when the mission starts, so «Luogo» can act on positions read while the players were still free. Three info items.

## Warnings

### WR-01: «Luogo» uses the positions read before the mission started

**File:** `lib/screens/innkeeper/missionCompletion/mission_completion_screen.dart:221-228` (with `lib/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart:24-35`)

**Issue:** Before this phase `_openServedStep` called `load(...)` every time a draft became ready, that is right after «Inizia la missione», when the BE has locked the participants. Now it calls `ensureLoaded(...)`, which returns at once when the same ids were already read — and they always were, by `_readCardStories()` when the wizard opened on the stories page. The same `MissionParticipantsLoaded` state feeds two different needs: the stories (fine to read once) and the positions of `PlaceStep` (`commonLocationId`, the rows «nome · luogo»). D-02 says the players are still free while the innkeeper reads, and reading every story before deciding is exactly what the page is for, so the positions can be minutes old when the draft starts.

**Failing scenario:** Aldo and Bea are both in city X. The innkeeper opens the wizard: the characters are read (both in X). While he reads the stories Bea, still free, moves to Y and arrives. «Inizia la missione» → the draft is ready → `ensureLoaded` skips the read. «Luogo» still shows both in X and enables «Resta qui», which sends `saveStep(fights, placeId: X)`. The BE only checks that the place exists (`mission-draft-save.service.ts`, `placeOf`) and then serves the enemy list of the draft's place (`mission-enemies.service.ts`): the mission is set in X with a participant who is not there, and no teleport is proposed. The opposite case (they gathered meanwhile) leaves «Resta qui» disabled until «Riprova», which is shown only after a failed read.

The cubit test `ensureLoaded does not read again the ids already loaded (D-02)` is right for the stories, but no screen test covers the positions after the start, so the regression is not visible in the suite.

**Fix:** Reread when the draft is created, keep the single read for a resume. The smallest change is in the screen: the listener that reacts to «a draft became ready» comes from a start when the previous state was `MissionDraftAbsent`, and only that case needs fresh positions.

```dart
// listener: previous is! MissionDraftReady && current is MissionDraftReady
listener: (_, state) => setState(
  () => _openServedStep(
    (state as MissionDraftReady).draft,
    isJustStarted: previous is MissionDraftAbsent, // via listenWhen capture
  ),
),

void _openServedStep(MissionDraft draft, {bool isJustStarted = false}) {
  ...
  final participants = context.read<MissionParticipantsCubit>();
  final ids = _characterIdsOf(draft);
  // i partecipanti erano liberi durante la lettura delle storie (D-02):
  // all'avvio le posizioni si rileggono
  isJustStarted ? participants.load(ids) : participants.ensureLoaded(ids);
}
```

Two details to settle in the same fix, RED first:
- `load` returns silently while a read is running, so a start tapped during the first read keeps that read's positions; either let the cubit queue one reread, or accept it (that read is seconds old) and say so in the comment.
- During the reread the state goes back to `Loading`: the stories dropdowns show «Lettura della storia…» for a moment if the innkeeper goes back. If that is unwanted, keep the previous characters visible while reloading (the cubit emits the new `Loaded` over the old one without passing through `Loading` when it already has data).

## Info

### IN-01: `healedInjuriesLine` has no caller left in `lib/`

**File:** `lib/utils/item_lines.dart:116-124`

**Issue:** After D-20/D-21 both readers (`ItemRow`, `PotionSheet`) build the line through `healedInjuryLabels` + `HealedInjuriesText`; `healedInjuriesLine` is used only by `test/utils/item_lines_test.dart`. Its doc comment («per chi non conosce chi legge») describes callers that do not exist: the rows that do not know the reader go through `ItemRow` with the default empty list. `lib/shared/components/healed_injuries_text.dart:8` still refers to it as the reference text.

**Fix:** Remove the function and its test group, and reword the comment of `HealedInjuriesText` («il testo letto è prefisso, etichette e virgole, come prima»). The tests that prove the plain string can assert on `healedInjuryLabels` or on the widget's `Text.rich` plain text.

### IN-02: The counter under the addition field counts the untrimmed text

**File:** `lib/screens/innkeeper/missionCompletion/steps/additions_step.dart:176` (with `:40-50`)

**Issue:** The rule of the page counts `text.trim().characters.length` (header summary, error line, «Concludi»), but `maxLength: 1000` makes Flutter's `TextField` draw its own counter and its own error state from `text.characters.length`, untrimmed (`_hasIntrinsicError`). With 998 letters followed by three line breaks the field shows «1001/1000» in the error colour with a red border, while the header reads «aggiunta 998/1000», the line «Massimo 1000 caratteri» is absent and «Concludi» is enabled. Nothing wrong is sent (the text is trimmed on the way out); the two numbers on the same page disagree, against the wording of D-23 («N counted as the BE does, without the spaces at the edges»).

**Fix:** Let the page own the counter: give `SheetTextField` an optional `buildCounter` (or a `counterText`) and pass the trimmed count from `AdditionsStep`, dropping `maxLength` for this field; or keep it as it is and record the difference as accepted.

### IN-03: Null-check operators on the served status in the rewritten «Ferite» selector

**File:** `lib/screens/mainScreen/tabs/journal/journal.dart:184-186`

**Issue:** The selector was rewritten in this phase and keeps `state.character.status!` and `status.injuries!`. `Character.status` and `CharacterStatus.injuries` are both nullable in the model; the sibling selector added by the same phase (`curableInjuriesOf`, `character_selectors.dart`) handles both nulls. Today the JSON parser always yields a list, so the crash needs a character served without `status`; the builder already treats «no wounds» as «no section» (D-22), so the operators buy nothing.

**Fix:**
```dart
final status = state.character.status;
if (status == null) return null;
return (
  injuries: status.injuries ?? const <InjuryType>[],
  innkeeperInjuries: status.innkeeperInjuries,
);
```

---

_Reviewed: 2026-11-22_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
