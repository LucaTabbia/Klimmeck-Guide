---
phase: 22
slug: companion-defeat-rest-and-recovery
status: issues_found
reviewed: 2026-11-14
scope: plans 22-01..22-15 (pre-gate), diff 8916a129..937f3f83
reviewers: two area reviewers (A: models, Journal, cards, potions; B: name, result sheet, notifications, innkeeper)
findings: { critical: 0, high: 1, medium: 4, low: 9, info: 6 }
---

# Phase 22 — Code Review (pre-gate)

Static review, no test run by the reviewers. Reviewer B did not open the test files: test quality is left to the verifier. Rulings of the orchestrator at the end.

## Area A — models, Journal, cards, potions

# FE Phase 22 review, AREA A (models, Journal Compagno, cards, details sheet, potion on a companion)

Read-only review of `git diff 8916a129..HEAD -- lib` for the files of area A, checked against the BE (`companion-life.ts`, `owned-pets.mapper.ts`, `owned-pet.resolver.ts`, `schema.gql`). Counts: CRITICAL 0, HIGH 1, MEDIUM 2, LOW 4, INFO 3.

## Clean areas (one line each)
- Live-life rule (`companion_vitality.dart`): same model as BE (lifeAsOf anchor, speed (max-1)/T via `fullLifeAt`, own max, nearest rounding, cap max-1, floor at served life). One rounding nit, see A-04.
- `CompanionVitalityCubit` ticker: starts only while a companion rests or waits for a potion, stops on all-steady, cancelled in `close`, offset subscription cancelled. No leak.
- `CompanionVitalityScope`: created in `create` with the current character, re-followed on every changed `CharacterLoaded`. Equipped/unequipped flips are covered because `equippedPetId` is re-read.
- Lenient parsing: `OwnedPet.tryFromJson` and `Pet.tryFromEntryJson` drop only the malformed entry, never the character; the new fields degrade to null/false.
- Single switch `companionCareEnabled`: potion targets (`ItemsSection._targetsOf`), rename in the Journal, shop name sheet and the quest result presenter are all guarded. No other entry point to `showCompanionNameSheet` or `give(...)` exists. Clean.
- `PotionCubit` single-flight: `PotionDrinking` is emitted synchronously before the await, so a double tap on «Dai a …» sends once. Parchments are disabled while drinking. Clean.
- `CompanionCard` column heights: 0.45 + 1/6 + 0.125 + 1/6 = 0.908 of size, no overflow in landscape.
- Selection of new GraphQL fields (`name defeated lifeAsOf fullLifeAt …`, `recoveryTime`) is intentionally deferred to plan 22-16 (gate). `imagePath`/`maxLifePoints` on `PetFragment` exist on the SDL (`Pet.imagePath: String!`, `maxLifePoints: Int!`). OK.

## Findings

### A-01 HIGH — companion details dialog has no Material ancestor
`lib/shared/components/popup/companion_details_route.dart:14-41` (also the rename underline in `companion_info.dart:117-135`).
`showGeneralDialog` builds its page without a `Material`/`DefaultTextStyle`. The sheet is full of `Text`/`AutoSizeText` with explicit `GoogleFonts` styles that inherit decoration from the ambient `DefaultTextStyle`. Without Material, Flutter falls back to the debug text style: yellow double underline on every line. The project already knows this: `quest_result_presenter.dart:291` and `:328` wrap their dialog content in `Material(type: MaterialType.transparency)`. The Journal sheet is fine because it lives under a Scaffold; the dialog used from shop (long press), cart, quest prize card and oste prizes is not. The route test (`companion_details_route_test.dart`) only checks that widgets exist, not text decoration.
Scenario: Shop, long press on a pet card, details sheet opens with underlined, yellow text.
Fix: in `pageBuilder` wrap the `Align` in `Material(type: MaterialType.transparency, child: ...)`; add a widget test asserting `Material.maybeOf` is non-null over `CompanionInfo`.

### A-02 MEDIUM — details panel stays "open" and empty when the companion disappears (sold) while its sheet is up
`lib/screens/mainScreen/tabs/journal/journal.dart:310-318` (`_buildCompanionSheet`).
When `_ownedPetOf` returns null the builder returns `SizedBox.shrink()` but `_selectedCompanionId` and the slid-in animation remain. The panel is a full-height transparent box until the next tap on the page. The Journal can stay mounted while a sale lands (Shop is another tab; characterUpdated also arrives from the quest outcome). Not a crash, but a stuck state.
Scenario: open the details of pet X, sell X from the shop (pre-fed by the shared `CharacterCubit`), come back: empty panel, `_selectedCompanionId` still X.
Fix: in the builder, when `owned == null` schedule `WidgetsBinding.instance.addPostFrameCallback((_) => _animationController.reverse())` (or a `BlocListener<CharacterCubit>` that reverses when the selected pet left `ownedPets`).

### A-03 MEDIUM — `CompanionVitalityState` is one frame stale after a character update, so a defeated parchment can be tapped
`lib/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_scope.dart:24-31` plus `owned_companion_row.dart:49`.
The rows are built from `CharacterCubit` (new `owned` list) but vitality comes from a cubit refreshed in a `BlocListener`, which fires after the frame. For a new or changed entry `vitality` is null/old for one frame: `isDefeated` is false, the tap goes through `onToggle` → `CompanionCubit.toggle` → a network equip that the BE refuses with `PET_DEFEATED`. The inverse also holds: a companion newly returned in forces stays faded until the listener runs. The window is one frame, but the single-flight mutation is real (and the failure banner is shown to the player). Also `CompanionContent` and `companion_info_sheet` derive `canToggle` the same way.
Fix: make `CompanionVitalityCubit` compute from the character directly (select `ownedPets` in the `BlocBuilder` and call `companionVitalityOf` in the build with `serverClock.now()`, using the cubit only for the tick), or make the scope rebuild `follow` synchronously (listen on `CharacterCubit.stream` in the cubit constructor instead of a widget listener). Minimum: treat `vitality == null && owned.isDefeated` as defeated in `OwnedCompanionRow` and `_buildCompanionSheet`.

### A-04 LOW — interpolation rounds a half point differently from the BE at exact half boundaries
`lib/models/companion/companion_vitality.dart:99-105` and `:87-92`.
BE: `Math.round(((now-asOf)*(max-1))/T)` (integer product, one division). FE: `share = elapsed/span` (double) then `((to-from)*share).round()`: two roundings. At a half point (for example max 10, life 1, T 9000 ms, elapsed 500 ms: exact 0.5; FE `9*(500/9000)` can evaluate to 0.4999999999999999) FE shows 1 point less than the BE for that tick. Also `span` is the BE `ceil`-ed `fullLifeAt - lifeAsOf`, so rate differs by under 1 ms/span. One-point flicker only, self-corrects, so LOW.
Fix: integer math: `final risen = from + (((to - from) * elapsedMs * 2 + spanMs) ~/ (2 * spanMs))` with `elapsedMs` clamped to `[0, spanMs]` (return values clamped as today).

### A-05 LOW — potion sheet targets are a snapshot, and the sheet never reflects a companion that became defeated/waiting while open
`lib/screens/mainScreen/tabs/journal/sections/items_section.dart:222-251`, `potion_sheet.dart:54-62`.
`targets` are computed at open time and the sheet (root navigator, cubits by value) never recomputes. A companion that finishes resting (no longer under max) or a potion wait that starts for another reason stays listed; the BE then refuses with `PET_*` and the banner explains. Acceptable because BE judges, but a refused `givePotion` closes the whole sheet (`_close` on `PotionRefused`) instead of removing the offending row. Confirm this is the intended UX; otherwise keep the sheet open and drop the target.
Fix (optional): on `PotionRefused` with `targetPetId != null` keep the sheet and hide that parchment via local state.

### A-06 LOW — `Semantics(button: true)` stays enabled on the disabled «Dai a …» parchment
`potion_sheet.dart:165-195`.
When `isDrinking`, `onTap` is null but the `Semantics` node still advertises an enabled button (no `enabled: false`), so a screen reader offers an action that does nothing.
Fix: `Semantics(label: label, button: true, enabled: !isDrinking, ...)`.

### A-07 LOW — fragile/unnecessary shared constants in `OwnedPet` docs and duplicated name maps
`lib/models/owned_pet.dart:47-62`, `shop.dart` `_chosenPetNamesOf`, `transaction_modal.dart` `_sellNames`.
(a) The doc comment for `lifeAsOf` and `fullLifeAt` is the same paragraph pasted twice, so neither says which is which. (b) The «name by pet id» map is built in two places with the same body. Move it to `CharacterAssets` (`Map<String,String> get chosenPetNames`) next to `equippedOwnedPet`.
Fix: document each field once; one getter.

### A-08 INFO — speed printed twice
`lib/shared/components/companion_row.dart:70-78` (`companionSpeedLabel` as a text line) and `lib/shared/components/cards/companion_card.dart:59,86` (same label as `CardLabel` on the card now rendered in the same row). The same duplication exists in the details sheet: `CompanionInfoSheet` card plus `CompanionInfo` `speedKey` line, and in the potion target parchment (card only, fine).
Fix: remove the `speed` line from `CompanionRow._buildTexts` (and update `companion-speed-*` tests), keep it on the card; in `CompanionInfo` keep the line only if the card is not showing it (or drop it from the card in details sheets via a `showSpeed` flag).

### A-09 INFO — `showCompanionDetails` from the shop sell side drops level, xp and vitality
`shop.dart:_showCompanionDetails(pet, name)` -> `companion_details_route.dart`. The player sees the owned companion's name but not its level, xp or life; harmless but inconsistent with the Journal. Optional: pass the `OwnedPet` when selling.

### A-10 INFO — haptic missing on equip from the details bookmark
`journal.dart:324-330` calls `CompanionCubit.toggle` directly while the section uses `CompanionSection._toggle` (haptic + ignored-pending handling). Single-flight is preserved by the cubit, so only the feedback differs. Reuse the same handler.

## Tests
No assertion-free test found in the area files spot-checked. Gaps worth a test: A-01 (Material ancestor), A-03 (one-frame stale vitality), A-04 (half-point parity with BE vectors from `companion-life.spec.ts`).

## Area B — name, result sheet, notifications, innkeeper

# FE Phase 22 review, AREA B (read-only, standard-deep, static)

Scope: rename (document/request/service/repo/cubit/sheet/3 entry points), result sheet and ambush lines, notifications, innkeeper companion slider, GraphQL documents. Nothing was run.

Counts: CRITICAL 0, HIGH 0, MEDIUM 2, LOW 5, INFO 3.

## Wire check against the BE (SDL in feat/23 research Q12 + real src/schema.gql)

Names, types and nullability match everywhere they are modelled:
- `RenamePetRequest { id, petId, name }` (rename_pet_request.dart:17) matches, and the `$request: RenamePetRequest!` variable matches.
- `QuestResult.companion` keys `defeated, fullLifeAt, lifeBefore, lifePoints, maxLifePoints, name` match the real `CompanionOutcome`, including `lifeBefore`.
- `AmbushReport.onFoot`, `MissionFightOutcome.companion { pet, name, lifeBefore, maxLifePoints }`, `MissionFightEffects.companionLifeAfter` and `ParticipantOverrideInput.companionLifeAfter` match.
- `OwnedPet.level/maxLifePoints/name/defeated/lifeAsOf/fullLifeAt/potionRecoveryUntil` and `Pet.recoveryTime` (nullable Int) match.
- The codes `PET_NAME_INVALID`, `PET_DEFEATED` and `PET_POTION_RECOVERING` are mapped.
- The only fields selected today are `Pet.imagePath` and `Pet.maxLifePoints`, which are in the current SDL. `renamePet` is registered in the schema-check registry (schema_check_documents.dart:85).

The PushEventType gap is expected until the BE merge: `src/schema.gql` still has only `ambushDefeat`, and the FE accepts both wire types.

## Findings

### B-01 MEDIUM: two companions recovering close together lose the second "in forze" notification
- Where: lib/models/push_event.dart:45 and in_app_notifications_cubit.dart:34, with the BE contract in `23-RESEARCH.md` line 307.
- The BE serves `petRecovered` with `id` = character id, not pet id. The dedup key is `petRecovered|<characterId>` and the window is 2 minutes. `notificationId` is `stableNotificationId(dedupKey)`, so the Android system notification id is also the same.
- Failing scenario: two defeated companions return to full life within 2 minutes of each other (same rest time, same fight). The second banner is dropped by the in-app dedup. The system notification overwrites the first one instead of adding a second.
- Fix: ask the BE to put the pet id in the push (`id` or a second key), or accept the loss. Accepting it is defensible, because the text names the companion and the loss is cosmetic. If it is accepted, say so in BACKEND-NOTES.

### B-02 MEDIUM: a result with a malformed or empty companion name silently loses the defeat line and the life line
- Where: lib/models/quest_result/quest_companion_outcome.dart:30-36.
- `tryFromJson` returns null when `name.trim().isEmpty`. In that case the sheet prints nothing: no life line, no "è stato sconfitto" line, and the xp line falls back to "Il tuo compagno".
- Failing scenario: the BE serves a defeat with a blank display name (a name that is only whitespace is trimmed by the BE helper, but a species with a null name is possible). The result sheet then says nothing about the defeat, even though the fight outcome was real.
- The same pattern is in mission_fight.dart:~63 (`MissionCompanion.tryFromJson`, blank name returns null), so the whole companion slider disappears from the correction step. The innkeeper then cannot correct that companion, and nothing is sent for it.
- Fix: parse the name leniently. Use a fallback label such as "Il tuo compagno" or "Compagno" and keep the numbers. Reject only when the numeric fields are unusable.

### B-03 LOW: the name prompt title is "Come chiamerai il tuo ?" when the species name is null
- Where: companion_lines.dart:`companionNamePromptTitle`, fed by `pet.name ?? ''` at quest_result_presenter.dart:~255, shop.dart:~407 and journal.dart:~352.
- `Pet.name` is nullable in the model. The prize pet parsed from `rewards.pet` has only `id` and `name` in the result fragment.
- Fix: `species.isEmpty ? 'Come chiamerai il tuo compagno?' : ...`.

### B-04 LOW: the prize prompt reads the last loaded character, which can be stale
- Where: quest_result_presenter.dart:241-262.
- The prompt is shown when `_hasNamed(character, pet.id)` is false. `_lastLoadedCharacter` is the last `CharacterLoaded`. If the prize companion just arrived with `characterUpdated`, the check sees "owned, unnamed" or "not owned yet". Both give a prompt, which is right.
- The only wrong case is a companion that was renamed on the Journal after the last loaded state and before the sheet closed. That is not reachable, so the stale read is harmless.
- Residual risk: replaying an old unacknowledged result after a restart prompts again for a companion the player previously skipped ("Più tardi"). That is acceptable. Noted as a deliberate behaviour, not a defect.

### B-05 LOW: the innkeeper companion slider shows `lifeBefore` when no `companionLifeAfter` is served
- Where: correction_section.dart:~113 (`correction.companionLifeAfter ?? companion.lifeBefore`).
- When the fight is not simulated for the companion, or `simulated.companionLifeAfter` is absent, the slider displays the starting life as if it were a proposal.
- Moving it sends a value. Not moving it sends nothing, which is correct because the key is only sent when set (mission_draft_inputs.dart:115).
- `MissionCorrection.fromEffects` copies the simulated `companionLifeAfter`, so correcting only the character's HP also pins the companion life to the simulated value. That is benign and consistent with `hpAfter`. `_copy` keeps the companion value when other fields change, so the correction is not lost.
- Fix (optional): render "—" or no slider when `companionLifeAfter == null` and no correction exists.

### B-06 LOW: the rename sheet cannot clear a name and allows an unchanged resubmit
- Where: companion_name_sheet.dart:`_confirm`, rename_pet_request.dart.
- This is by design (D-31: clearing is not offered). A submit with the identical name makes a pointless mutation. The enabled state ignores `initialName`.
- Fix: `canConfirm &&= normalizedNameOf(_controller.text) != initialName`.

### B-07 LOW: the rename refusal mapping covers few BE codes
- Where: pet_rename_failure.dart:46-59.
- `FORBIDDEN` (the `@OwnsCharacter` guard) and any `PET_*` code the BE adds fall into `unknown`, which prints "Qualcosa è andato storto, riprova". A retry will never succeed for these.
- Fix: map `FORBIDDEN` to `notOwned` if the BE guard emits it. Verify against the BE once `renamePet` exists in `src/schema.gql` and the resolver.

### B-08 INFO: the "Sconfitto" label in the correction section is derived in the FE
- Where: correction_section.dart:~121 (`life == minLifeAfterFight`).
- This is the FE reading the rule "1 = defeated". D-33 states it explicitly, and it is display only. It breaks if the BE ever changes the floor. A comment already ties it to D-17. No action needed.

### B-09 INFO: the settings toggle for "Compagno in forze" is live before the BE sends the push
- Where: notification_preferences_section.dart:51.
- It is harmless. The category defaults to enabled and the popup registry has no entry, so the null-safe lookup at notification_intent_landing.dart:59 does nothing on tap.

### B-10 INFO: items verified clean (no defect found)

- **Toggle migration:** `ambush('ambush_defeat', 'ambush', legacyWireTypes: {'ambushDefeat'})` keeps the stored key. One toggle covers both wire types through `fromWireType`. The dedup key and the local-intent `type` use the canonical `ambush`, so the suppression id `ambush|<result id>` (quest_result_presenter.dart:143) matches the push-side key for both types.
- **Unknown push types:** these return null from `tryParse`. They are dropped without a crash, and that is documented.
- **Rename flow:**
  - Single flight: the cubit guard (companion_name_cubit.dart:20) plus `canConfirm`.
  - Closing mid-flight: `PopScope(canPop: !submitting)` blocks back and barrier, and Skip is disabled while submitting. The listener closes with `pop` only when the route is current.
  - Stale refusal: `_refusalOf` filters by pet id, and `reset()` runs at open.
  - Purchase race: `_petsInFlight` is captured at confirm (shop.dart:130), so a `characterUpdated` that arrives before the reply does not lose the companions.
  - Several bought companions: they are asked one after another.
  - Keyboard: `viewInsets` padding plus a `SingleChildScrollView`.
- **Companion care switch:** while `companionCareEnabled` is false, no rename entry is reachable. The three entries are Journal (`_renameActionOf` returns null), shop (`_askNamesAfterFrame`) and the presenter (`_askPrizeName`). `CompanionInfo` shows the action only when `onRename` is set, and the shop and prize details routes pass none.
- **Result sheet:**
  - Defeat duration is `fullLifeAt − resolvedAt`, never from now. A date not after `resolvedAt` prints the bare defeat line.
  - The life line prints only for a companion that lost life and was not defeated, so an unharmed companion prints nothing.
  - The xp line uses the name when it is served.
- **`onFoot`:** this is read only from the ambush report.
- **Gameplay chrome:** the name sheet is a parchment bottom sheet with no Material dialog or AppBar. The slider is in the innkeeper wizard, where it is allowed.
- **`name_rules.dart` extraction:** the extraction from the character draft is behaviour-identical, and its regex and limits are unchanged.

## Gate reminders (not defects today)

When the gate plan switches on selection, these still have to be added to the documents: `QuestResult.companion { defeated fullLifeAt lifeBefore lifePoints maxLifePoints name }`, `AmbushReport.onFoot`, `OwnedPet { name defeated lifeAsOf fullLifeAt potionRecoveryUntil level maxLifePoints }`, `Pet.recoveryTime`, and `MissionFightOutcome.companion { pet name lifeBefore maxLifePoints }` plus `companionLifeAfter` on the effects. None of them is in a fragment today (grep of lib/graphql finds none), so the parsers are tested only against hand-written JSON. Run the schema gate after the BE merge, because `MissionCompanion` and the `PushEventType` additions are not yet in the BE `src/schema.gql`.

## Rulings of the orchestrator (2026-11-14)

- **Fix (TDD):** A-01 (Material ancestor on the details route), A-02 (close the sheet when its companion leaves the owned list), A-03 (no frame with stale vitality: a defeated parchment is never tappable), A-04 (integer rounding identical to the BE), A-08 (the speed text line leaves `CompanionRow` where the card already prints it; the details sheet keeps one speed line), B-02 (name fallback instead of dropping the entry), B-03 (prompt title without a species), B-05 (the slider says when the value is the life before the fight, not a proposal), B-07 (non-retryable refusals of `renamePet` do not offer a retry).
- **Fix if small, else defer with a reason:** every other LOW / INFO of both areas.
- **B-01 (dedup key of `petRecovered`):** the key is decided by the BE (Phase 23 plan 09: push id = pet id). No FE change; checked by the orchestrator against the BE code before the gate.
