# Phase 24: Participants' Stories and Innkeeper Wounds - Research

**Researched:** 2026-11-21
**Domain:** Flutter (BLoC/Cubit) innkeeper wizard + player-side injury rendering, against a NestJS GraphQL contract still being drafted (BE Phase 25)
**Confidence:** HIGH on the FE code (every claim read in the tree, file:line), MEDIUM on the wire (names are FE proposals until the BE `BACKEND-NOTES.md` lands)

Line numbers refer to the phase branch `feat/24-participants-stories-and-innkeeper-wounds` at `5e1f60f3` unless a claim says «review branch» (`fix/ui-layout-review` at `0af75334`).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Carried forward (not re-asked)
- The backend is the source of truth (rule 4); the innkeeper flow is a utility screen (chrome allowed); no blocking loading in an active player session (rule 2).
- `CharacterInfos.background` is a list of entries since BE PR #47 (2026-11-18); the Profile already draws one block per entry and seals a new one with `newEntrySigil` (device-only «seen» store, `NewEntriesCubit`).
- Non-additive SDL changes are declared in the BE handoff; FE plans that select new fields are gated on the BE merge (schema check on the merged SDL).
- One-off migrators leave the repo after the real boot; no content file in either repo.

#### Reading the stories (first step)
- **D-01 (user, verbatim):** «Come primo step serve una schermata dove ogni partecipante ha una propria dropdown, al cui interno si trova il suo background, in modo che io possa leggere la storia di tutti prima di prendere decisioni.»
- **D-02 (user, «Prima dell'avvio»):** the reading page is what the flow opens on, before the mission is started and with the players still free; «Inizia la missione» sits at the bottom of that page. Once the mission is started the page stays reachable by going back. Starting the mission keeps its explicit tap (Phase 21 D-28): opening the page never creates the draft.
- **D-02a (user, 2026-11-21, «Sì, niente popup allora»):** the page with the dropdowns stays as fixed in D-01/D-02; the alternative raised by the user (a popup with the background on the tap of a character's name in the request cards) is dropped: no popup.
- **D-03:** one dropdown per participant (name and rank on the header, the shared `Dropdown` component), closed at first; inside, every background entry in order, oldest first. A participant with no background shows one in-world line saying so.

#### Adding to the stories (last step)
- **D-04 (user, verbatim):** «serve un ultimo step (alla fine di tutto), dove io possa fare un aggiunta al background di ogni partecipante, potendo anche rileggere la storia del singolo».
- **D-05 (user, «Dopo il riepilogo, prima di chiudere»):** the page comes after the recap and is the last of the flow; one «Concludi» closes the mission and writes the additions in the same BE transaction. The additions live in the draft: leaving and coming back finds them.
- **D-06 (user, verbatim):** «Le aggiunte sono per partecipante, non una sola per tutti»: one text field per participant, each optional; an empty field adds nothing to that participant.
- **D-07 (user, «1000 caratteri»):** one addition holds at most 1000 characters. The BE validates (same counting rule as the creation background, which stays at 400); the FE counter is UX only.
- **D-08:** an addition becomes a new entry appended at the end of the participant's `infos.background`. Existing entries are never edited or removed here. On the last page each participant has a dropdown with the story so far (as in D-03) and the field for the addition under it.

#### What the player sees
- **D-09 (user, «Sigillo + riga nel foglio del risultato»):** the existing wax sigil marks Profile and the new entry; in addition the result sheet of the mission carries one line for a participant whose background got an addition. Proposed copy: «La tua storia ha una nuova pagina» (Claude's wording, to confirm at the UAT). No dedicated push. The BE says on the result whether an addition was written (field name fixed in the plan); the app never infers it.

#### Scope of the two steps
- **D-10:** the two pages exist only in the guided flow, that is for `story` and `worldMission`. Every other pending request keeps today's completion.

#### Innkeeper wounds
- **D-11 (user, verbatim):** «Le ferite applicate dall'innkeeper sono rimuovibili solo dall'innkeeper, non sono influenzabili da quest heal, pozioni o premi».
- **D-12 (user, «Solo quelle aggiunte a mano»):** an innkeeper wound is one the innkeeper adds by his own hand in the corrections of a resolution, of any quest type (guided flow or plain pending request). A wound produced by the simulated fight and left as it is stays an ordinary, curable wound. In the guided flow: the wounds of the corrected outcome that the simulation did not produce.
- **D-13 (user, «Nelle correzioni di ogni risoluzione»; amended 2026-11-21, user verbatim: «Le correzioni possono rimuovere qualsiasi tipo di ferita, quelle dell'oste e non»):** the corrections of every resolution, in the guided flow and in the other pending requests, can remove any wound the participant carries, the innkeeper's and the ordinary ones alike; the innkeeper's are marked. Today the corrections can only add wounds: the removal is new on both sides.
- **D-14:** no cure reaches an innkeeper wound: the cure of a heal quest, a potion drunk from the Journal, the cure inside a prize (rank block, guided prize `cure`), and any other cure path found by the research. `injuriesHealed` never lists one. A cure whose only matching wounds are the innkeeper's has no effect, and the existing no-effect notices and refusals treat it so.
- **D-15 (user):** the player recognises an innkeeper wound: in the Journal it carries a mark and the line «Troppo grave per essere curata» (user's copy, replacing the proposed «Solo l'oste può guarirla»); heal quest sheets («Cura le tue ferite: …») and potions do not list it among the wounds they heal.
- **D-16 (technical default):** the character keeps the origin of its wounds; the shape is fixed in the plan, additive on the wire if possible (for example a second list holding the subset that belongs to the innkeeper, so every wound already at DB stays ordinary with no migration). The maluses of a wound do not depend on its origin. **Amended 2026-11-21 (user, verbatim: «l'oste per rendere non curabile una ferita curabile già presente deve prima rimuoverla e poi aggiungerla di nuovo»):** a wound the character already carries cannot be added again and never changes origin by itself; to turn an ordinary wound into an innkeeper wound the innkeeper removes it and adds it again, in the same correction.
- **D-17 (superseded 2026-11-21 by the user's amendment of D-13):** the assumption «the removal takes off innkeeper wounds only» is withdrawn: every wound is removable from the corrections.

### Claude's Discretion
- Field and type names on the wire, the draft shape for the additions, the query that serves the backgrounds to the innkeeper (the innkeeper reads other players' characters: admin-only, as the rest of the flow).
- Layout of the two pages inside the existing step scaffold (`MissionStepHeader`, back button), the mark of an innkeeper wound in the chips and in the Journal.

### Deferred Ideas (OUT OF SCOPE)
None raised in the discuss.

Out of scope by the phase boundary: editing or deleting existing background entries, a background editor for the player, any change to the injury maluses, the real combat engine, iOS.
</user_constraints>

<phase_requirements>
## Phase Requirements

ROADMAP §Phase 24 reads «Requirements: TBD (fixed in the plan)». The ids below are a **proposal** for the planner (the orchestrator fixes them); the Validation Architecture maps tests to them.

| ID (proposed) | Description | Research Support |
|----|-------------|------------------|
| STORY-01 | The guided flow opens on a reading page: one closed `Dropdown` per participant (name · rank), every background entry oldest first, an in-world line when empty; «Inizia la missione» at the bottom; no draft created on open; reachable by «Indietro» once started (D-01..D-03, D-10) | §1 Guided flow today, Pattern 1, Pattern 2 |
| STORY-02 | After the recap a last page: per participant a story dropdown and an optional field up to 1000 characters; additions saved in the draft; one «Concludi» closes the mission (D-04..D-08) | Pattern 3, Pattern 4, FE needs N1..N4 |
| STORY-03 | The player's result sheet reads «La tua storia ha una nuova pagina» from a BE flag; the wax sigil marks Profile and the new entry with no new code (D-09) | §5 Result sheet, FE need N5, prerequisite P1 |
| WOUND-01 | The corrections can remove any wound the participant carries, show which are the innkeeper's, and re-add a removed ordinary wound in the same correction (D-12, D-13, D-16) | Pattern 5, FE needs N6..N8 |
| WOUND-02 | The player reads an innkeeper wound as «Troppo grave per essere curata» in the Journal and never finds it in «Cura le tue ferite: …» nor in a potion's «Cura: …» (D-14, D-15) | Pattern 6, FE need N9 |
| GATE-24 | Schema gate on the merged BE Phase 25 SDL (new fields selected only there), schema check, full suite, device E2E, FE `BACKEND-NOTES.md` | §6 Tooling, Validation Architecture |
</phase_requirements>

## Summary

The guided wizard is a single `StatefulWidget` (`mission_completion_screen.dart`) driving five local pages over a draft served by the BE; every «Avanti» is one `saveMissionDraft` call and the page changes only if the call was not refused (`_runThenOpen`, `:496-508`). The two new pages fit this shape with small, mechanical changes: the reading page replaces `StartStep` on `MissionDraftAbsent` and becomes page 1 once the draft exists; the additions page becomes the last page, takes the completion (and its confirmation) from the recap, and saves its texts as one more section of the draft. **The backgrounds need no new BE operation**: `MissionParticipantsCubit` already reads every participant with `character(id)` and `CharacterFragment.fullFields`, which selects `infos.background` (`character_fragment.dart:11-22`, `innkeeper_repository.dart:43-44`).

Three findings contradict or sharpen the CONTEXT and must be settled before planning (details in «Contradictions with the CONTEXT»): (1) the background list, `BackgroundEntries`, `NewEntriesCubit`, the wax sigil and the `Dropdown` badge exist **only on `fix/ui-layout-review`**, not on this branch nor on `develop`: here `CharacterInfos.background` is still `String?` and cannot even parse the `[String!]!` the BE serves; (2) the FE has **no plain pending-request completion**: plan 21-17 deleted the Phase 10 form, so the wizard's `CorrectionSection` is the only correction surface of the app; (3) the creation background cap is **500** graphemes on both sides, not 400.

The wound work is FE-light because the app never decides what a cure heals: `Quest.noEffect`, `QUEST_NO_EFFECT`, `ITEM_NO_EFFECT` and `injuriesHealed` are all served. The only place where the app intersects `canHeal` with the character's wounds is `curableInjuriesLine` (`item_lines.dart:107-118`); the potion line `healedInjuriesLine` lists the potion's whole `canHeal` with no character in sight.

**Primary recommendation:** settle prerequisite P1 (bring the review branch's background/sigil work under this branch) as Wave 0; then plan pre-gate, lenient, unselected models and the two pages against today's BE, and one gate plan that selects the new fields on the merged BE Phase 25 SDL, exactly as Phases 21 and 23 did.

## Contradictions with the CONTEXT

| # | CONTEXT says | The code says | Consequence |
|---|--------------|---------------|-------------|
| C1 | «Carried forward»: `background` is a list, Profile draws one block per entry and seals a new one (`NewEntriesCubit`); canonical refs `background_entries.dart`, `newEntriesCubit/` | On this branch `CharacterInfos.background` is `String?` read with `json["background"]` (`character_infos.dart:27,37`), Profile is a `TextSection` (`profile.dart:88`), and `background_entries.dart`, `newEntriesCubit/`, `new_entry_sigil.dart`, the `Dropdown.badge` do not exist. They live on `fix/ui-layout-review` (commits `81ede5bc`, `2f06636f`, `e94d9721`; 18 commits ahead of the common base `8871a409`) [VERIFIED: `git diff --stat HEAD...fix/ui-layout-review`, `git log HEAD..fix/ui-layout-review`]. The BE serves `CharacterInfos.background: [String!]!` (`src/schema.gql:86`) [VERIFIED: BE working tree], so the `String?` reader on this branch throws on any character | **Blocking prerequisite P1** — see Open Questions Q1. D-09's «existing wax sigil» is not available to this phase until the review work is under it |
| C2 | D-12/D-13: corrections «of every resolution … in the guided flow and in the other pending requests»; D-10: «every other pending request keeps today's completion» | Plan 21-17 deleted the Phase 10 form, its Cubit, `ParticipantOverride`, `CompletePendingRequestInput` and the `CompletePendingRequest` document (`21-17-SUMMARY.md`); every card opens the wizard (`innkeeper_panel_screen.dart:33,193-200`, `request_card_view.dart:68-78`); `InjuryChips` has one caller, `correction_section.dart:76` [VERIFIED: grep]. `completePendingRequest` still exists in the BE SDL (`src/schema.gql:558`) | On the FE the «plain pending request» has no surface: WOUND-01 is the wizard's `CorrectionSection` only. The BE may still extend `completePendingRequest`; the FE does nothing there |
| C3 | D-07: «the creation background, which stays at 400» | `CharacterDraft.backgroundMaxLength = 500` (`character_draft.dart:29`), copy «Massimo 500 caratteri» (`character_creation_messages.dart:9`); BE `BACKGROUND_MAX_GRAPHEMES = 500` (`create-character-input.validator.ts:11`) [VERIFIED: both trees] | Wording slip only: the addition cap is 1000, the creation cap stays what it is (500). Nothing to change |
| C4 | D-15: «potions do not list it among the wounds they heal» | The potion line `healedInjuriesLine(item)` (`item_lines.dart:93-101`) lists the item's whole `canHeal`; it never sees the character. Callers: `item_row.dart:45` (shared by Journal, shop, wizard prizes, result sheet) and `potion_sheet.dart:111` | The line must become character-aware where the reader is the owner (Pattern 6). Resolved in Q6 |

## Standard Stack

No new dependency (project rule, `21-REPO-RULES.md` §Secrets; the phase needs none).

### Core (already in `pubspec.yaml`)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_bloc | ^9.1.1 | Cubits of the wizard | project rule (`docs/rules/state-management.md`) [VERIFIED: pubspec.yaml] |
| equatable | ^2.0.0 | immutable states and models | project rule [VERIFIED: pubspec.yaml] |
| graphql_flutter | ^5.2.1 | documents through `KlimmeckGraphQl` | project rule [VERIFIED: pubspec.yaml] |
| bloc_test / mocktail | ^10.0.0 / ^1.0.5 | Cubit and widget tests | project rule (`docs/rules/testing.md`) [VERIFIED: pubspec.yaml] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `character(id)` for the backgrounds | a dedicated BE query (e.g. stories of a pending request) | lighter payload, but a new document (registry 55 → 56, four count pins) and a BE resolver for data the wizard already downloads today. Not recommended |
| shared `Dropdown` | `ExpansionTile` (as `CorrectionSection`) | D-03 names the shared `Dropdown`; `ExpansionTile` is ruled out by the decision |
| `package:characters` in a model | grapheme count in the widget layer | `characters` is only a transitive dependency (`pubspec.lock`): importing it from `lib/models` trips `depend_on_referenced_packages` and breaks the «no new dependency» rule. Count in the widget, where `package:flutter/widgets.dart` already exposes it [ASSUMED: the re-export] |

**Installation:** none.

## Architecture Patterns

### 1. The guided flow today (what the planner changes)

| Fact | Where |
|------|-------|
| Pages: `enum MissionPage { place, encounters, fight, prizes, recap }`, local navigation, never saved | `mission_completion_screen.dart:32` |
| The served step picks the page only at the first draft read or created: `_openServedStep` → `_pageOf(draft.step)`; `teleport` or unknown → `place` | `:175-180`, `:208-213` |
| `MissionDraftAbsent` → `StartStep` (note + «Inizia la missione», a centred column) | `:321-324`, `steps/start_step.dart:8-41` |
| Start: `MissionDraftCubit.start()` → `startMissionDraft`; a refusal stays on the page with a new `failureSerial` | `mission_draft_cubit.dart:51-69` |
| Header «Passo k di 5 · titolo»: `stepNumber: _page.index + 1`, `MissionStepHeader.stepCount = 5`; built only inside `_buildReady` and hidden while the keyboard is open | `:347-359`, `:339-341`, `components/mission_step_header.dart:12` |
| «Indietro»: `MissionBackScope.onBack` is `null` on `place` and while submitting; each page lays out `MissionBackButton` in its own button row | `:361-366`, `components/mission_back_button.dart:5-37`, `place_step.dart:69` |
| Going back is local: `_enterPrevious` (recap → prizes → last fight … → encounters → place) | `:521-538` |
| Advancing saves then opens: `_runThenOpen(action, next)` opens `next` only if the state is still `MissionDraftReady` with the same `failureSerial` | `:496-508` |
| Per-step saves: `saveStep(step, placeId)`, `saveFights`, `saveCorrections(fightIndex, corrections, step)`, `savePrizes(prizes, step)` — all through `_save` → `SaveMissionDraftInput` with only the sections present | `mission_draft_cubit.dart:71-147`, `mission_draft_inputs.dart:273-300` |
| Every answer replaces the served draft; one call at a time (`isSubmitting`) | `mission_draft_cubit.dart:150-175` |
| Completion: `RecapStep` confirms with `showDestructiveConfirmation` (body = recap lines) then `MissionDraftCubit.complete()` → `completeGuidedMission(pendingQuestId)` → `MissionDraftCompleted(results)` → the screen pops `CompletionCompleted(results)` | `steps/recap_step.dart:87-96,125-132`, `mission_draft_cubit.dart:139-143`, `mission_completion_screen.dart:241-242` |
| `MissionParticipant` carries `characterId`, `name`, `title` (`TitleType?`), `maxLifePoints`, `pendingQuestId` — **no background** | `models/mission/mission_draft.dart:13-57` |
| `MissionParticipantsCubit.load(ids)` reads each character with `readCharacter` (full character) plus the places; called only from `_openServedStep`, i.e. only once a draft exists | `mission_participants_cubit.dart:23-45`, `mission_completion_screen.dart:182-183` |
| Before the draft exists the participants are known from the card: `RequestCard.participants` (`PendingRequestCharacter { id, name, … }`, no rank) | `models/pending_request/request_card.dart:28`, `pending_request.dart:42-66` |
| Route: Cubits created with the route; `MissionDraftCubit..load()` at once | `mission_completion_route.dart:35-55` |
| Keyboard: `resizeToAvoidBottomInset: false`, the body pads itself; header hidden while typing (UAT 2026-11-14) | `mission_completion_screen.dart:286`, `:302`, `:313-316`, `:339-341` |

### Recommended structure (new and touched files)

```
lib/screens/innkeeper/missionCompletion/
├── mission_completion_screen.dart        # MissionPage + stories/additions, Absent branch, back rules
├── steps/stories_step.dart               # NEW — reading page (replaces start_step.dart)
├── steps/additions_step.dart             # NEW — last page
├── steps/recap_step.dart                 # «Completa» → «Avanti», confirmation moves to the last page
├── components/participant_story.dart     # NEW — Dropdown(name · rank) + entries, used by both pages
├── components/correction_section.dart    # two wound groups
└── components/mission_step_header.dart   # stepCount from MissionPage.values.length
lib/screens/innkeeper/components/injury_chips.dart   # removable existing wounds, innkeeper mark
lib/shared/components/background_entries.dart        # PROMOTED from profile/components (≥ 2 features)
lib/shared/components/sheet_text_field.dart          # PROMOTED from characterCreation/components (≥ 2 features)
lib/models/mission/…, lib/models/request/mission_draft_inputs.dart, lib/models/character/character_status.dart,
lib/models/quest_result/quest_result.dart            # lenient new fields
lib/graphql/fragments/{mission_draft,character,quest_result}_fragment.dart   # selections, gate plan only
```

`docs/rules/architecture.md`: a widget used by two features moves to `lib/shared/components/` — this applies to `BackgroundEntries` (Profile + innkeeper) and `SheetTextField` (creation + innkeeper).

### Pattern 1: the reading page before the draft (D-01, D-02)
**What:** `MissionDraftAbsent` renders `StoriesStep` instead of `StartStep`; the same widget is `MissionPage.stories` once the draft exists.
**How:**
- `enum MissionPage { stories, place, encounters, fight, prizes, recap, additions }`; `MissionStepHeader.stepCount` becomes `MissionPage.values.length` (7) so the counter can never drift again.
- `_buildBody` (`:318-332`): the `MissionDraftAbsent` branch builds the header «Passo 1 di 7 · Storie» and `StoriesStep(participants: widget.card.participants, action: start)`; the bottom row holds the start note (`MissionCompletionScreen.startNote`, `:48-49`) and «Inizia la missione» (`startKey`, unchanged). `_buildReady` on `MissionPage.stories` builds the same step with «Avanti» (local `_enter(MissionPage.place)`, no save: nothing changed on the draft).
- Participants' data: call `MissionParticipantsCubit.load(card participant ids)` when the draft is found absent (in `initState` for a state already absent, otherwise from the existing `MissionDraftCubit` listener block `:118-133`). After the start, `_openServedStep` (`:175-180`) loads again with the draft's ids: skip that second read when the Cubit is already `Loaded`/`Loading` for the same ids (today `load` drops a call made while `Loading`, `:24`).
- After «Inizia la missione» the existing listener (`:123-129`) runs `_openServedStep` and lands on «Luogo», exactly as today. `_pageOf` is untouched: a served step never maps to `stories`.
- Back: `onBack` is `null` only on `MissionPage.stories` (today on `place`, `:362`); `_enterPrevious` sends `place` and `encounters`' predecessor chain to `stories` (`:537`).
- Header of each dropdown (D-03): name · rank. Before the start the rank is `characters[id]?.status?.title?.label`; after it `MissionParticipant.title?.label`. `TitleType.label` exists on both branches.
- A failed read (`MissionParticipantsFailed`) shows the failure line and «Riprova» as `PlaceStep` does (`place_step.dart:43-57,83-88`); it never disables «Inizia la missione» (Phase 21 D-31: a failed read never blocks the flow).

### Pattern 2: one story widget for both pages (D-03, D-08)
`ParticipantStory(name, title, entries)` = `Dropdown(sectionName: '$name · ${title.label}', data: BackgroundEntries(entries: …))`, closed at first (`Dropdown.isOpen` defaults to `false`, `dropdown.dart`), entries in the served order (the BE appends, so served order = oldest first). Empty list → one line, proposed copy «Di questo avventuriero non si sa ancora nulla» (to confirm at the UAT). `Dropdown` keeps its child built while closed (`SizeTransition`, no lazy build), so nothing inside is lost on toggle.

### Pattern 3: the additions in the draft (D-05, D-06)
- Model: `MissionDraft.backgroundAdditions` (lenient `missionEntriesOf`, default `const []`) and `MissionDraft.additionOf(characterId)`; input `SaveMissionDraftInput.backgroundAdditions` (a section replaced whole, absent = untouched, like `fights` and `prizes`, `mission_draft_inputs.dart:288-296`); a new `MissionDraftStep` value for the resume (`_pageOf` maps it to `MissionPage.additions`).
- Cubit: `saveAdditions(additions, {step})` beside `savePrizes` (`mission_draft_cubit.dart:122-131`), and `conclude(additions)` = save then `completeGuidedMission` inside ONE `_act`, emitting the saved draft before the completion call so a refused completion leaves the saved texts served.
- The recap's «Completa» becomes «Avanti» (`saveStep(additions)` through `_runThenOpen`); the explicit confirmation with the recap lines (`recap_step.dart:87-96`) moves to «Concludi» (Phase 21 D-08 / Phase 10 D-11: never a completion without confirmation). `missionRecapLinesOf` stays the source of the dialog body.
- When the texts are saved: on «Concludi», on «Indietro» from the last page, and on leaving the wizard from the last page with unsaved text (a `PopScope` on that page saves, then pops). Texts live in the step's State keyed by character id, seeded once from the served draft; a new served draft must NOT reseed a field being typed (the fight step reseeds on every new draft, `fight_step.dart:62-70` — do not copy that here).
- Only non-empty trimmed texts are sent (D-06).

### Pattern 4: the 1000-character field (D-07)
Reuse `SheetTextField` (own controller, survives rebuilds, `MaxLengthEnforcement.none` with the counter, `sheet_text_field.dart:40-68`) exactly as the creation «Storia» field does (`character_creation_screen.dart:183-196`): `maxLength: 1000`, `minLines: 3`, `maxLines: 5`, error text «Massimo 1000 caratteri» and «Concludi» disabled while any field is too long. Count trimmed grapheme clusters in the widget layer (the BE counts graphemes after trim, `create-character-input.validator.ts:41-47`). The creation draft counts UTF-16 units (`character_draft.dart:44-45`): do not copy that rule, and do not «fix» it in this phase.

### Pattern 5: corrections that remove and re-add (D-13, D-16)
Today: `InjuryChips` shows `existing` selected and disabled, `added` toggles (`injury_chips.dart:24-32`); `MissionCorrection.injuries` is «all the wounds the fight adds» (`mission_draft_inputs.dart:58-59`) and is sent whole (`:105`); `MissionFightOutcome.injuriesBefore` is «shown, not removable» (`mission_fight.dart:152-153`).

Prescribed shape:
- `MissionCorrection` gains `injuriesRemoved` (list, sent whole like `injuries`) with `withInjuryRemovalToggled`; `fromEffects` seeds it from the served effect.
- Two groups in `CorrectionSection` under «Ferite» (`correction_section.dart:75-81`):
  - «Ferite presenti»: one chip per wound of `outcome.injuriesBefore` only; selected = kept, tap = removed; an innkeeper wound carries the mark.
  - «Ferite da aggiungere»: every `InjuryType`; a wound still carried (in `injuriesBefore` and not removed) is disabled; a removed one becomes available again.
  This is the user's sentence turned into two gestures («prima rimuoverla e poi aggiungerla di nuovo») with no three-state chip.
- Invariant kept by the model, tested: `injuries ∩ injuriesBefore ⊆ injuriesRemoved`; un-removing a wound drops it from `injuries`.
- The mark: the app marks only what the BE serves (rule 4) — the innkeeper subset of `injuriesBefore`, and after a save the innkeeper subset of the effective added wounds. While editing, a fixed note under the second group says it: proposed copy «Una ferita aggiunta a mano è dell'oste: nessuna cura la toglie». The app never computes «corrected minus simulated».
- Recap: `_characterLines` (`recap_step.dart:42-59`) adds «Ferite tolte: …» from the served `injuriesRemoved`.
- Existing keys `completion.injury.<name>` (`injury_chips.dart:26`) are used by tests: the two groups need distinct key prefixes.

### Pattern 6: the player's side (D-15)
Model: `CharacterStatus.innkeeperInjuries` (`List<InjuryType>`, `injuryTypesFrom`, default `const []`; `character_status.dart:17,37,80,113,133,144,166` are the seven places `injuries` is threaded through). Selected in `CharacterFragment.statusFields` (`character_fragment.dart:33`) only in the gate plan.

| Place | Today | Change |
|-------|-------|--------|
| Journal «Ferite» | `journal.dart:159-178` → `InjuryNameIcon` (`components/injury_name_icon.dart:6-27`) per wound of `status.injuries` | an innkeeper wound gets the mark and the line «Troppo grave per essere curata» under its name (gameplay screen: text in the theme's styles, no chrome, no new Cloudinary asset) |
| Quest sheet «Cura le tue ferite: …» | `quest_info_sheet.dart:343-352` → `curableInjuriesLine(cure, characterInjuries)` (`item_lines.dart:107-118`); `characterInjuries` comes from `characterInjuriesOf` (`character_selectors.dart:5-6`) at `board.dart:342-347` and `world_map.dart:391-399` (→ `quest_info_overlay.dart:58`) | a second selector «curable wounds» = `injuries` minus `innkeeperInjuries`, used by those two callers; `curableInjuriesLine` itself is untouched. Covers heal quests and every prize with a `cure` (the sheet reads `quest.prizes.cure` for all families, `:343-345`) |
| Potion «Cura: …» | `healedInjuriesLine(item)` at `item_row.dart:45` and `potion_sheet.dart:111` | optional «wounds beyond cure» argument, passed by the Journal items section (`items_section.dart:237`) and the potion sheet; shop, wizard and result-sheet rows keep the catalogue line (Q6) |
| «Guarite: …» | `healedLine(_result.injuriesHealed)` at `quest_result_sheet.dart:190-193`, `healedLine(state.result.injuriesHealed)` at `potion_sheet.dart:85` | none: served, D-14 is the BE's guarantee |
| No-effect notices | `Quest.noEffect` (`quest.dart:27,46`), `QUEST_NO_EFFECT` (`quest_acceptance_failure.dart:17,96`), `ITEM_NO_EFFECT` (`item_use_failure.dart:14,73`), copy in `quest_blocked_reason.dart:6` and `potion_notice.dart:39-42` | none: all served |
| Board refetch key | `quest_scope_listener.dart:77,81-82` keys the reread on the sorted names of `status.injuries` | **must add `innkeeperInjuries` to the key** (Pitfall 4) |

`curableInjuriesLine` is the only place where the app intersects `canHeal` with the character's wounds [VERIFIED: grep of `canHeal`, `.injuries`, `characterInjuries` over `lib/`].

### Anti-Patterns to Avoid
- **Deriving the origin of a wound in the app** (corrected minus simulated, or «added in a guided flow»): rule 4; read the served subset.
- **`ListView.builder` around stateful dropdowns and text fields:** an item scrolled away is disposed and loses its open state and its controller. Participants are few: `SingleChildScrollView` + `Column`, texts held by the step's State.
- **Selecting a new field before the gate:** on today's BE the whole document fails and the character is lost (`21-REPO-RULES.md` «Gated selection»).
- **A second completion path:** «Concludi» is the only caller of the completion; the recap must not keep a «Completa».
- **`dart format` on a directory** (the baseline is not formatter-clean).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Collapsible story block | a new expander | `Dropdown` (`lib/shared/components/dropdown.dart`) | D-03 names it |
| Background entries list | a second renderer | `BackgroundEntries` (review branch, promoted to shared) | one renderer for Profile and innkeeper; `newEntries` defaults to empty |
| Multi-line field with counter | a raw `TextField` + controller in the step | `SheetTextField` (promoted to shared) | controller ownership and counter behaviour already tested |
| Wax sigil for the new entry | any new «unseen» logic | `NewEntriesCubit` + `NewEntriesListener` + `newEntryIdsOf` (review branch) | already keyed on the entry's text |
| Save-then-advance | a new navigation guard | `_runThenOpen` (`mission_completion_screen.dart:496-508`) | T-21-46: the page changes only if the call was not refused |
| Refusal mapping | reading server messages | `innkeeperFailureFrom` (`innkeeper_failure.dart:47-62`) + `failureLineOf` (`mission_completion_screen.dart:78-83`) | codes only, never server text |
| Confirmation dialog | a new dialog | `showDestructiveConfirmation` with `confirmButtonStyle: primaryButtonStyle` (`recap_step.dart:88-94`) | same look as today's completion |

**Key insight:** every piece of this phase already has a neighbour in the tree; the work is wiring and two lenient model extensions, not new machinery.

## Common Pitfalls

### Pitfall 1: the background/sigil code is not under this branch
**What goes wrong:** plans cite `background_entries.dart` or `NewEntriesCubit` and the executor finds nothing; or the executor re-implements the list reader and conflicts with the review branch later (it touches 123 files, among them `dropdown.dart`, `quest_info_sheet.dart`, `quest_result_sheet.dart`, `journal.dart`, `items_section.dart`, `prizes_step.dart`, `completion_recap.dart`, `results_recap_dialog.dart` — all files this phase edits).
**How to avoid:** Wave 0 settles P1 (Q1) before any code plan. **Warning sign:** `grep -n "List<String> background" lib/models/character/character_infos.dart` prints nothing.

### Pitfall 2: step counter and back rules are pinned by tests
`MissionStepHeader.stepCount = 5` and «Passo k di 5» appear in the wizard tests (59 tests in `mission_completion_screen_test.dart`), which also assume `MissionDraftAbsent` → `StartStep` and «Indietro» disabled on «Luogo». Expect a RED-first rewrite of those cases, not additions only.

### Pitfall 3: a served draft reseeding a field being typed
`FightStep` reseeds its corrections whenever the served fight changes (`fight_step.dart:62-70`). On the last page a save (which replaces the draft) must not overwrite what the innkeeper is typing: seed once, in `initState`.

### Pitfall 4: an origin flip does not change `status.injuries`
Removing and re-adding the same wound in one correction leaves `status.injuries` identical while `innkeeperInjuries` and the heal quests' `noEffect` change. `QuestScopeListener` rereads the Board only when its key changes (`quest_scope_listener.dart:77`): without the new list in the key, a heal quest keeps a stale `noEffect`. Same care for any `BlocSelector` on `injuries` alone (`journal.dart:160-166`, `character_selectors.dart:5-6`).

### Pitfall 5: `Dropdown` goes to the network in tests
Its arrow is a `CachedSvg` of `CloudinaryAssets.arrowDown` (`dropdown.dart`, id at `cloudinary_assets.dart:23`): every widget test of the two pages seeds it with `seedSvgCache([CloudinaryAssets.arrowDown])` (`test/helpers/svg_cache_seed.dart`). On the review branch the sigil needs `CloudinaryAssets.newEntrySigil` too.

### Pitfall 6: the keyboard in landscape
The wizard is used in landscape; the scaffold does not resize and the header hides while typing (`mission_completion_screen.dart:286,339-341`, UAT 2026-11-14). The last page has several multi-line fields: test it with `test/helpers/landscape.dart` and an open keyboard inset (the field being typed stays visible, the bottom row does not overflow).

### Pitfall 7: card participants versus draft participants
Before the start the page lists `card.participants` (visible entries only, `request_card.dart:93-97`); the draft lists the BE's snapshot. A card opens only when `canComplete` holds (no hidden participant, `:50-54`), so the two sets match, but the code must key everything by character id and tolerate a participant missing from either side.

### Pitfall 8: the sigil identifies a background entry by its text
`newEntryIdsOf` puts the entries' texts in a set (review branch `new_entry_ids.dart:28`): an addition equal to an existing entry is not «new», and the first sync of a category marks nothing (`new_entries_cubit.dart:26-28`). Fine for real prose; say it in the UAT script (use a fresh text, on a device that has already opened the Profile once).

### Pitfall 9: unknown `step` on an older client
`MissionDraftStep` is parsed leniently (`mission_draft.dart:117`): an unknown value is `null` → «Luogo». A draft left on the new step and opened by an app without it lands on page «Luogo»: harmless, but the gate plan must add the enum value before any save sends it.

## Code Examples

Patterns already in the tree (to copy, not to invent):

```dart
// Save, then open the next page only if the call was not refused
// Source: lib/screens/innkeeper/missionCompletion/mission_completion_screen.dart:487-508
void _savePrizes(List<MissionPrizeInput> prizes) {
  final cubit = context.read<MissionDraftCubit>();
  _runThenOpen(
    () => cubit.savePrizes(prizes, step: MissionDraftStep.recap),
    MissionPage.recap,
  );
}
```

```dart
// A draft section sent only when present (the additions follow this shape)
// Source: lib/models/request/mission_draft_inputs.dart:288-296
Map<String, dynamic> toJson() => {
  'pendingQuestId': pendingQuestId,
  if (step case final step?) 'step': step.name,
  if (prizes case final prizes?)
    'prizes': [for (final prize in prizes) prize.toJson()],
};
```

```dart
// Lenient list of wounds: unknown names dropped, a non-list is empty
// Source: lib/models/enums/injury_type.dart:197-203
List<InjuryType> injuryTypesFrom(Object? json) { … }
```

```dart
// The multi-line field with a counter and a too-long error
// Source: lib/screens/characterCreation/character_creation_screen.dart:183-196
SheetTextField(
  label: 'Storia',
  initialValue: draft.background,
  onChanged: cubit.updateBackground,
  errorText: draft.isBackgroundTooLong ? backgroundTooLongMessage : null,
  minLines: 3, maxLines: 5,
  maxLength: CharacterDraft.backgroundMaxLength,
)
```

## What the FE needs from the BE contract

Names are **FE proposals**; the BE `BACKEND-NOTES.md` decides. Every item is additive on the wire.

| # | Need | Proposed shape | Used by |
|---|------|----------------|---------|
| N0 | Nothing new to read the stories: `character(id)` stays readable by the innkeeper for any character and returns `infos.background: [String!]!` oldest first | existing (`src/schema.gql:86,745`) | STORY-01, STORY-02 |
| N1 | The additions served on the draft | `MissionDraft.backgroundAdditions: [{ character: ID!, text: String! }!]!` | STORY-02 resume |
| N2 | The additions saved as a section, replaced whole, absent = untouched; empty text never sent | `SaveMissionDraftInput.backgroundAdditions: [{ characterId: ID!, text: String! }!]` | STORY-02 |
| N3 | A step value for the last page (resume) | one new `MissionDraftStep` value (e.g. `additions`) | STORY-02 |
| N4 | The refusal code of an addition over 1000 graphemes (BE D-07: its own code) and where it is raised (save, completion or both); `completeGuidedMission(pendingQuestId)` keeps its signature and writes the additions from the draft | code name TBD | STORY-02 |
| N5 | A flag on the result of a participant whose story got an entry | `QuestResult.backgroundEntryAdded: Boolean!` | STORY-03 |
| N6 | Removal in the correction input | `ParticipantOverrideInput.injuriesRemoved: [InjuryType!]`; a wound may appear in both `injuriesRemoved` and `injuries` (remove and re-add, D-16) and only a wound in `injuriesBefore` can be removed | WOUND-01 |
| N7 | The removal served back | `MissionFightEffects.injuriesRemoved: [InjuryType!]!` (empty on `simulated`) | WOUND-01 seeding, recap |
| N8 | Which wounds are the innkeeper's, served, never derived | `MissionFightOutcome.innkeeperInjuriesBefore: [InjuryType!]!` (subset of `injuriesBefore`, wounds hand-added in an earlier fight of the same draft included) and, on the effective effect, the innkeeper subset of the added wounds (e.g. `MissionFightEffects.innkeeperInjuriesAdded`) | WOUND-01 marks |
| N9 | The player's innkeeper wounds | `CharacterStatus.innkeeperInjuries: [InjuryType!]!` (subset of `injuries`) on `character` and `characterUpdated` | WOUND-02 |
| N10 | `characterUpdated` for every participant at completion (new background entry, wounds and their origin), also when only the origin of a wound changed | existing publisher | STORY-03, WOUND-02 |
| N11 | `Quest.noEffect`, `QUEST_NO_EFFECT`, `ITEM_NO_EFFECT`, `injuriesHealed`, and the `quests` board served to a character all ignore innkeeper wounds (D-14) | no shape change | WOUND-02 |
| N12 | Whether a wound removed by a correction is told to the player (in `injuriesHealed`, in a new list, or not at all): the FE prints only what is served | BE/product choice — Q7 | — |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 10 override form (`completePendingRequest`) | the wizard is the only completion path | plan 21-17, 2026-11-14 | no «plain» correction surface on the FE (C2) |
| `background: String` | `background: [String!]!` | BE PR #47, 2026-11-18 | FE reader fixed only on the review branch (C1) |
| existing wounds locked in the chips (Phase 21 D-14) | any carried wound removable (D-13 amended) | this phase | `InjuryChips`, `CorrectionSection`, `MissionCorrection`, tests titled «(D-14)» rewritten |

**Deprecated/outdated:** `steps/start_step.dart` (replaced by the reading page; delete RED-first with its test cases).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The innkeeper queue only ever holds `story` and `worldMission` requests (the two pending lanes) | C2 | if other types reach the queue they already open the wizard today; D-10 «today's completion» would need a BE refusal the FE maps |
| A2 | `package:flutter/widgets.dart` re-exports `characters`, and `TextField.maxLength` counts grapheme clusters | Pattern 4, Alternatives | the counter and the too-long check could disagree by a few characters on emoji; UX only (D-07), the BE decides |
| A3 | The BE keeps additions in the draft and `completeGuidedMission(pendingQuestId)` unchanged | N1..N4 | if the BE prefers an argument on the completion, `conclude` sends it there and the «leaving and coming back» saves change shape |
| A4 | The BE serves the innkeeper subset as lists beside the existing ones (D-16's example) | N8, N9 | a different shape (objects with an origin) is a non-additive change: models and fragments change, the gate plan grows |
| A5 | The proposed copy («Storie», «Di questo avventuriero non si sa ancora nulla», «Ferite presenti», «Ferite da aggiungere», the note under the chips, «Massimo 1000 caratteri», «Ferite tolte: …») | Patterns 1–5 | copy only; reviewed at the UAT |
| A6 | Requirement ids STORY-01..03, WOUND-01..02, GATE-24 | Phase Requirements | bookkeeping only |

## Open Questions (RESOLVED)

1. **Q1 — P1: how does the review branch's background/sigil work get under this phase? (TRUE PRODUCT/WORKFLOW QUESTION — needs the user)**
   - What we know: the discuss answer was «GSD pair, layout branch still open»; the code this phase reuses and extends exists only there (C1); the two branches edit the same files.
   - Options: (a) PR `fix/ui-layout-review` → `develop` now, then merge `develop` into this branch (cleanest history; the review branch can keep going afterwards from `develop`); (b) merge `fix/ui-layout-review` into this branch (the phase PR then carries the 18 review commits); (c) cherry-pick `81ede5bc`, `2f06636f`, `e94d9721` (duplicate commits, conflicts when the review branch lands).
   - **Recommendation: (a).** Until it is settled no code plan can start; the planner writes it as a Wave 0 checkpoint for the orchestrator and the user.

2. **Q2 — Which query serves the backgrounds?** RESOLVED: the existing `character(id)` through `MissionParticipantsCubit` (N0). No new document; the registry stays at 55.

3. **Q3 — Is «Inizia la missione» blocked while the stories are loading or failed?** RESOLVED: no. The page shows the names at once (from the card), the stories when they arrive, a failure line with «Riprova» otherwise.

4. **Q4 — When are the additions saved?** RESOLVED: on «Concludi» (save then complete, one Cubit action), on «Indietro» from the last page, and on leaving the wizard from the last page with unsaved text. No save per keystroke.

5. **Q5 — Does «Concludi» keep the confirmation dialog?** RESOLVED: yes, the recap's dialog moves to the last page unchanged in content plus one line per participant who gets an addition (proposed «Storia di <nome>: una nuova pagina»); the recap page gets «Avanti».

6. **Q6 — Where does the potion line drop an innkeeper wound?** RESOLVED: in the Journal (item rows and the potion sheet), where the reader is the owner about to drink. Shop rows, the wizard's prize catalogue and the result sheet keep the catalogue line. If the user wants the shop too, it is one more caller of the same argument — ask at the UAT, not before.

7. **Q7 — Does the player's result sheet tell a wound removed by the innkeeper?** RESOLVED for the FE: no FE change; the sheet prints `injuriesHealed` as served. Whether a removal by correction belongs in that list is the BE's call under D-14 (N12); flag it to the user only if the BE researcher finds the two readings both defensible.

8. **Q8 — Three-state chip or two groups?** RESOLVED: two groups (Pattern 5).

9. **Q9 — How is an innkeeper wound marked in the Journal without a new asset?** RESOLVED: the user's line «Troppo grave per essere curata» under the wound's name in the theme's emphasis style is the mark; no new Cloudinary id (project rule). A drawn mark can come from the layout review later.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | analyze, tests | ✓ | 3.35.5 stable | — |
| Node | schema check (`validate_documents.js`) | ✓ | v22.12.0 | — |
| BE `node_modules/graphql` | schema check (`NODE_PATH`) | ✓ | present in the BE tree | — |
| BE SDL with Phase 25 | gate plan | ✗ (not merged; BE branch `feat/25-storie-dei-partecipanti-e-ferite-dell-oste` holds only the context) | — | none: the gate plan waits for the merge |
| Device (Samsung via USB) | device E2E | human checkpoint | — | — |

**Missing dependencies with no fallback:** the merged BE Phase 25 SDL (blocks only the gate plan and the device E2E).

## Validation Architecture

`workflow.nyquist_validation` is absent from `.planning/config.json` → enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test` ^10.0.0 + `mocktail` ^1.0.5 |
| Config file | none (`analysis_options.yaml` with `flutter_lints`) |
| Quick run command | `flutter test <paths of the task>` (foreground) |
| Full suite command | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (gate plan only, alone in its call, timeout ≥ 300 000 ms) |
| Analyzer gate | `OUT=$(flutter analyze --no-fatal-infos 2>&1); echo "$OUT" \| tail -1; ! echo "$OUT" \| grep -qE '^ *(error\|warning) •' && echo ANALYZE_GATE_OK` — baseline **47 info / 0 warning / 0 error** [VERIFIED: run on 2026-11-21 on this branch] |
| Schema check | `dart run tool/schema_check/dump_documents.dart <dir>` then `NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js <schema.gql> <dir>`; SDL read with `git -C <BE> show origin/develop:src/schema.gql` into a `mktemp -d` directory |
| Suite baseline | to be measured in Wave 0 **after** P1 is settled (5170 at the close of Phase 23; the review branch adds test files) |

Helpers: `buildTestApp` (`test/helpers/test_app.dart`), `seedSvgCache` (`svg_cache_seed.dart`), `landscape.dart`, fixtures `mission_fixtures.dart`, `pending_request_fixtures.dart`, `quest_result_fixtures.dart`, `potion_fixtures.dart`, mocks `MockInnkeeperRepository`, `MockMissionDraftCubit`, `MockMissionParticipantsCubit`, `MockCharacterCubit` (`test/helpers/mocks.dart:122,201,204,136`).

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STORY-01 | absent draft → reading page with one closed dropdown per card participant, names shown before the read ends | widget | `flutter test test/screens/innkeeper/missionCompletion/steps/stories_step_test.dart` | ❌ Wave 0 |
| STORY-01 | entries oldest first; empty background → the in-world line; failed read → line + «Riprova», start still enabled | widget | same file | ❌ Wave 0 |
| STORY-01 | opening never calls `startMissionDraft`; «Inizia la missione» calls it once and lands on «Luogo»; «Indietro» from «Luogo» shows the stories with «Avanti» | widget | `flutter test test/screens/innkeeper/missionCompletion/mission_completion_screen_test.dart` | ✅ rewrite cases |
| STORY-01 | participants read with the card's ids when the draft is absent, not read twice after the start | bloc + widget | `…/missionParticipantsCubit/mission_participants_cubit_test.dart`, screen test | ✅ extend |
| STORY-01 | header «Passo k di 7», count from `MissionPage.values` | widget | screen test | ✅ rewrite cases |
| STORY-02 | `MissionDraft.backgroundAdditions` lenient parse; `SaveMissionDraftInput` sends the section only when present, only non-empty trimmed texts | unit | `flutter test test/models/mission test/models/request` | ✅ extend |
| STORY-02 | `saveAdditions` and `conclude` state sequences (save refused → page stays; completion refused → saved draft served; success → `MissionDraftCompleted`) | bloc | `…/missionDraftCubit/mission_draft_cubit_test.dart` | ✅ extend |
| STORY-02 | last page: story dropdown + field per participant, texts seeded from the draft once, 1001 graphemes → error text and «Concludi» disabled, confirmation before the call | widget | `…/steps/additions_step_test.dart` | ❌ Wave 0 |
| STORY-02 | recap shows «Avanti» and no completion; served step → last page on resume; «Indietro» and leaving save the texts | widget | `…/steps/recap_step_test.dart`, screen test | ✅ rewrite cases |
| STORY-02 | landscape with the keyboard open: no overflow, typed field visible | widget | `…/steps/additions_step_test.dart` (`landscape.dart`) | ❌ Wave 0 |
| STORY-03 | `QuestResult` flag lenient (`true` only); sheet shows the line only when set | unit + widget | `flutter test test/models/quest_result test/shared/components/popup/quest_result_sheet_test.dart` | ✅ extend |
| STORY-03 | a new background text arriving on the character marks Profile and the entry | bloc + widget | `test/screens/mainScreen/newEntriesCubit/`, `test/screens/mainScreen/tabs/profile/profile_background_test.dart` | ✅ after P1 (review branch) |
| WOUND-01 | `MissionCorrection` removal toggles, invariant `injuries ∩ before ⊆ removed`, `toJson` carries both lists, seeded from the served effect | unit | `flutter test test/models/request` | ✅ extend |
| WOUND-01 | chips: carried wound removable, innkeeper wound marked, removed wound addable again, kept wound not addable | widget | `test/screens/innkeeper/components/injury_chips_test.dart`, `…/components/correction_section_test.dart` | ✅ rewrite cases |
| WOUND-01 | fight step sends the full corrections with removals; recap line «Ferite tolte: …» | widget | `…/steps/fight_step_test.dart`, `…/steps/recap_step_test.dart` | ✅ extend |
| WOUND-02 | `CharacterStatus.innkeeperInjuries` lenient, default empty, in `props`/`copyWith`/`toJson` | unit | `flutter test test/models/character` | ✅ extend |
| WOUND-02 | Journal: innkeeper wound shows «Troppo grave per essere curata», an ordinary one does not | widget | `test/screens/mainScreen/tabs/journal/` | ✅ extend |
| WOUND-02 | «Cura le tue ferite: …» leaves the innkeeper wound out; no line when only innkeeper wounds match | unit + widget | `flutter test test/utils test/shared/components/popup/quest_info_sheet_test.dart test/screens/mainScreen/characterCubit` | ✅ extend |
| WOUND-02 | potion sheet and Journal item row leave it out; shop row unchanged | unit + widget | `flutter test test/utils test/shared/components/item_row_test.dart test/screens/mainScreen/tabs/journal` | ✅ extend |
| WOUND-02 | Board rereads when only `innkeeperInjuries` changes | widget | `test/screens/mainScreen/components/` (quest scope listener test) | ✅ extend |
| GATE-24 | new fields selected in the three fragments; documents pinned | unit | `flutter test test/graphql test/tool` | ✅ extend |
| GATE-24 | every document valid on the merged SDL; registry count (55 unless a document is added: pins at `test/tool/schema_check_documents_test.dart:34`, `test/graphql/shop_documents_test.dart:155`, `travel_documents_test.dart:197`, `loot_fragment_test.dart:125`) | gate | schema check block + full suite | ✅ |
| GATE-24 | device E2E (reading page, additions, sigil, result line, remove/re-add, cure refused on an innkeeper wound) | manual | human checkpoint guided by the orchestrator | — justified: real BE and device |

### Sampling Rate
- **Per task commit:** the task's test paths + the analyzer gate.
- **Per wave merge:** the test directories named in the plan's `<verification>`.
- **Phase gate:** schema check all OK, full suite green, analyzer at baseline, `tool/hardening_check.sh` clean, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] P1 settled and the suite baseline measured on the resulting tree (Q1).
- [ ] `24-REPO-RULES.md` with the draft wire names agreed with the BE researcher (as Phases 21–23).
- [ ] `test/screens/innkeeper/missionCompletion/steps/stories_step_test.dart` — STORY-01.
- [ ] `test/screens/innkeeper/missionCompletion/steps/additions_step_test.dart` — STORY-02.
- [ ] Fixtures: background additions, removed wounds and innkeeper subsets in `test/helpers/fixtures/mission_fixtures.dart`; `innkeeperInjuries` in the character fixtures; the result flag in `quest_result_fixtures.dart`.
- [ ] No framework install needed.

## Security Domain

`security_enforcement` is absent from the config → enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (unchanged) | existing session/bearer |
| V3 Session Management | no (unchanged) | — |
| V4 Access Control | yes | the innkeeper role is enforced by the BE (`@Roles(innkeeper)`); the FE only maps `FORBIDDEN` → `CompletionForbidden` (`mission_completion_screen.dart:260-265`). Reading other players' characters and writing their background stay BE-guarded |
| V5 Input Validation | yes | the 1000-character rule is authoritative on the BE (D-07); the FE counter is UX. The addition is free text rendered with `Text` only (no markup, no link parsing) |
| V6 Cryptography | no | — |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| A non-innkeeper calling the save/complete with additions or removals | Elevation of privilege | BE role guard; FE has no client-side role decision beyond hiding the panel |
| Free text of another player's story logged | Information disclosure | never `appLog` a draft, a background or an addition (`tool/hardening_check.sh` forbids `print`/`debugPrint` outside `app_log.dart`; `21-REPO-RULES.md`: no payload logging) |
| Addition persisted on the device | Information disclosure | texts live in widget state and on the BE draft only; no `SharedPreferences` write (the hardening check has a write allow-list) |
| Oversized or control-character text | Tampering / DoS | BE cap and its own refusal code (N4); FE maps the code to one line, never shows server text |
| Client deciding that a wound is curable | Tampering | the app only filters a display line; cures, `noEffect` and `injuriesHealed` are BE facts (rule 4) |

## Project Constraints (from CLAUDE.md)

- Read the relevant `docs/rules/*.md` before placing code; layers UI → Cubit → Repository → Service, models and GraphQL documents free of Flutter.
- Clean Code, SoC, **TDD (Red → Green → Refactor, test first)**, Boy Scout Rule in scope.
- Rule 1: no UI chrome outside utility screens — the wizard may use Material controls; Journal, quest sheets, result sheet and Profile may not.
- Rule 2: no blocking loading in an active player session — the player's new fields arrive silently with the character; loaders only on the innkeeper's explicit actions.
- Rule 3: branch + PR per phase, target `develop`, never a direct push.
- Rule 4: the backend is the source of truth — no client-side wound origin, cure effect or validation authority.
- Rule 5: no secret in the repo; never read or print `.env`.
- Commands: `flutter analyze` clean (baseline 47 info), `flutter test`; `dart format` **only on touched files, one by one, never on a directory**; a touched file that is not formatter-clean gets its own `style(<scope>): format <file>` commit first.
- Commits: Conventional Commits in English, docs scope `phase-24`, no `Co-Authored-By` / `Generated with` trailer (user rule).
- Maintain `.planning/phases/24-participants-stories-and-innkeeper-wounds/BACKEND-NOTES.md` for the BE agent.
- No project skills directory (`.claude/skills`, `.agents/skills`) exists in the repo.

## Sources

### Primary (HIGH confidence)
- FE tree at `5e1f60f3`: every file cited with line numbers above.
- `fix/ui-layout-review` at `0af75334` read with `git show` / `git diff` (no checkout): `character_infos.dart`, `dropdown.dart`, `background_entries.dart`, `new_entry_sigil.dart`, `newEntriesCubit/`, `new_entries_listener.dart`, `new_entries_builder.dart`, `profile.dart`, `journal.dart`, `title_type.dart`.
- BE working tree (read-only, branch `feat/25-storie-dei-partecipanti-e-ferite-dell-oste`): `src/schema.gql` (lines 84-109, 429-503, 557-575, 598-605, 745, 864-878, 969-975), `src/characters/creation/create-character-input.validator.ts`, `25-CONTEXT.md`.
- Planning docs: `24-CONTEXT.md`, `24-DISCUSSION-LOG.md`, `21-CONTEXT.md`, `21-REPO-RULES.md`, `21-17-SUMMARY.md`, Phase 21 `BACKEND-NOTES.md`, `23-VALIDATION.md`, ROADMAP §Phase 24.
- `flutter analyze --no-fatal-infos` run on 2026-11-21: 47 issues, all info.

### Secondary / Tertiary
- None: no web source was used (the task forbids the network); library behaviour not read in the tree is tagged `[ASSUMED]` (A2).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new library, versions read from `pubspec.yaml`.
- Architecture (wizard, corrections, player side): HIGH — read line by line; the prescribed shapes follow existing neighbours.
- Wire: MEDIUM — FE proposals, the BE researcher works in parallel.
- Pitfalls: HIGH for 1–7 (seen in the code), MEDIUM for 8–9 (behaviour inferred from the review branch's code, not run).

**Research date:** 2026-11-21
**Valid until:** the BE Phase 25 `BACKEND-NOTES.md` lands or `fix/ui-layout-review` moves (re-check the line numbers of the files it touches); otherwise 30 days.
