# Phase 8: Spells Section (Journal Tab) - Research

**Researched:** 2026-10-27
**Domain:** Flutter widget extraction + optimistic overlay cubit (flutter_bloc 9.1.1), server-anchored countdown (Phase 7 `ServerClockService`), GraphQL mutation/failure slice (graphql_flutter 5.2.1), additive contract with BE Phase 9.1
**Confidence:** HIGH for code/contract facts (read or measured this session); MEDIUM for the 9.1 SDL (proposed, not yet generated: BE branch `feat/09.1-spell-state-and-recovery-contract` holds only docs, `ee4d37a`)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Recovery model and backend companion (SPELL-05, SPELL-07)
- **D-01 (user decision 2026-10-27):** a **real countdown**, not a static indicator. It needs a BE companion phase, **BE Phase 9.1 "Spell State and Recovery Contract"** (inserted today in the BE roadmap, branch `feat/09.1-spell-state-and-recovery-contract` off BE `develop`): a per-spell state with `usages` and `recoveries: [DateTime!]!` that persists **regardless of the equip state**. User, verbatim: *«Il recupero vale sempre, che la magia venga equipaggiata o disequipaggiata. Il timer di recupero non si interrompe mai. Se io disequipaggio la magia e 10 secondi dopo dovrebbe recuperare un utilizzo, 10 secondi dopo recupererà un utilizzo».* Consequences: equipping no longer resets the usages (BE Phase 4 D-11 is superseded by 9.1), the unequip → equip shortcut disappears, the FE needs no rule of its own.
- **D-02:** Proposed contract (fixed by the BE 9.1 CONTEXT; `src/schema.gql` wins once generated): `type SpellState { spell: Spell!, usages: Int!, recoveries: [DateTime!]! }` and `CharacterStatus.spellStates: [SpellState!]!`, one entry per known spell, same ids as `status.spells`. `recoveries` is ascending: the first instant is the next recovered use, `recoveries.length == maxUsages - usages` once every job is tracked. `ActiveSpell { spell, usages }` stays on the wire for the slot order (`usages` documented as equal to the state). `Spell.recoveryTime` is **milliseconds** (the BE uses it directly as the Bull delay). Additive only. The FE reads usages and recoveries from `spellStates` for both the list row and the slot card, joined by spell id.
- **D-03:** The FE develops against the proposed contract with fakes/recorded `QueryResult`s (pattern of Phases 3–7); `CharacterStatus.fromJson` treats `spellStates` as optional until the schema lands (absent → usages from `ActiveSpell`/catalog and the static «in recupero» fallback of D-04). The plan that adds `spellStates { usages recoveries spell { id } }` to `CharacterFragment` runs **after** the BE 9.1 PR is merged on BE `develop` (or is the last plan), and the final plan runs `tool/schema_check` against `git -C <BE> show origin/develop:src/schema.gql` plus the manual E2E on device with the UAT data of the BE handoff. BE PR before FE PR.
- **D-04:** Countdown anchoring: `ServerClockService.now()` (Phase 7) against the first `recoveries` instant; label «prossimo tra X» using the Phase 7 duration formatter (rounds up to minutes, so a positive remainder never reads 0; under one minute Claude chooses between «meno di 1 min» and seconds). When the instant is past but `characterUpdated` has not yet delivered the restored use the label becomes an «in arrivo…»-style wording (Claude's discretion, mirror of Phase 7 D-10). Tick cadence at Claude's discretion (minute granularity is enough; reuse the ticker approach of `TravelProgressCubit` if it fits). `usages == maxUsages` → nothing about recovery is shown. `recoveries` empty but `usages < maxUsages` (legacy jobs enqueued before the BE 9.1 deploy) → static «in recupero» without a time.
- **D-05 (user decision):** the countdown lives **in the list row** («Usi: 1/3 · prossimo tra 12 min») for every known spell whose usages are below the maximum, active or not. The `SpellCard` in the slot keeps only the usages counter it already has (`AnimatedPencilText`); no time on the card.

#### Gestures (SPELL-03, SPELL-04)
- **D-06 (user decision):** **tap toggles.** Row of a known spell: inactive → `equipSpell`, active → `unequipSpell`. Card in a slot → `unequipSpell`. Request `EquipSpellRequest { id: <characterId>, spellId }`; the deprecated `usages` input field is **never sent** (BE Phase 4 handoff §0 item 4).
- **D-07 (user decision):** slots full (`activeSpells.length >= maxActiveSpells`) and tap on an inactive spell: the client does **not** call the BE; the card resists (short spring/shake at Claude's discretion), `HapticFeedback.selectionClick()`, banner «Slot pieni: disequipaggia una magia». The BE stays the judge: a `MAX_ACTIVE_SPELLS_REACHED` from a race → rollback + banner (D-17). Mirror of Phase 6 D-11.
- **D-08:** Haptics on an equip/disequip tap: `HapticFeedback.lightImpact()` at the tap, nothing at confirmation; exact pattern at Claude's discretion (Phase 6 D-06 precedent).
- **D-09 (user decision):** **long-press** on a row or on a slot card opens a **detail sheet** built like `EquipmentInfoSheet` (slides in from the right over the journal page, dismissed by a tap outside, same `AnimationController` pattern as `journal.dart`) with the existing `SpellInfo` extended: name, description, element + power, use type, max usages, recovery time, learn requirements (`minXpToLearn`, `requiredLearnTime`), current usages and next recovery. The sheet offers the same equip/disequip toggle as the row (affordance at Claude's discretion, provisional).

#### Slots and empty states (SPELL-07)
- **D-10:** The slot row renders exactly `maxActiveSpells` boxes (existing bordered container) filled with `activeSpells[i]` cards; a `maxActiveSpells` change delivered by `characterUpdated` re-renders the row; the FE never computes thresholds nor titles (SPELL-07). Defensive only: never index past `activeSpells.length`.
- **D-11 (user decision):** `maxActiveSpells == 0` (titles below `mage`): **no slot row**, one neutral copy line in its place («Nessuno slot per le magie: cresci di rango»), no numbers, no title names; the known-spells list stays visible with its usages/countdown; a tap to equip is blocked like D-07 with the banner «Nessuno slot disponibile».
- **D-12 (user decision):** no known spells (`status.spells` empty): **the Spells section is not built at all**. It appears as soon as `status.spells` has one entry or `maxActiveSpells > 0` (then: slot row and the line «Non hai ancora imparato nessuna magia»).

#### List content (SPELL-01, SPELL-02)
- **D-13:** Row = `SpellCard` (unchanged: use-type icon, element icon, name, power) + description + **one compact line** «Usi: 3 · Recupero: 2 h · Danno: fuoco 12» (`maxUsages`, `recoveryTime` formatted from ms with the shared duration formatter, Italian label of `energyDamage.type` + `power`); for a spell with usages below the maximum the first item becomes «Usi: 1/3 · prossimo tra 12 min» (D-05). Labels and separators provisional.
- **D-14 (user decision, verbatim):** *«Sono marcate con il segnalibro come accade per gli oggetti equipaggiati e restano nella lista al loro posto».* Active spells keep their position in the list and carry the **red bookmark** (`CloudinaryAssets.bookmarkRed`) exactly as `EquipmentItemCard` does for equipped items (`AnimatedPositioned` ribbon). The ribbon is extracted into a shared widget used by both cards, or `SpellCard` gets an `isSelected` built on it: Claude's choice, **zero duplication** of the ribbon code.
- **D-15:** List order = `status.spells` order as delivered by the BE; no sorting, no grouping.

#### Optimistic UI and errors (SPELL-06)
- **D-16 (user decision):** optimistic **with a visible pending look**: the card enters/leaves the slot at once with an attenuated look («inchiostro ancora umido»: opacity or ink-wash at Claude's discretion) until `characterUpdated` reflects the change, then full. Implementation: a **`SpellsCubit`** (new, `tabs/journal/spellsCubit/`) keeps the pending operations keyed by spell id as an **overlay** on the `CharacterCubit` state; an operation clears when the subscription state matches, on failure, or at a **15 s timeout** (Phase 6 D-03 precedent). One pending operation per spell; a tap on a pending spell is ignored. The UI never builds state from `CommonResponse`.
- **D-17:** Failures: the Repository maps `OperationException` into a **`SpellEquipFailure`** (enum + classifier, pattern of `travel_failure.dart`/`quest_acceptance_failure.dart`) by `extensions.code`: `SPELL_NOT_KNOWN`, `SPELL_ALREADY_ACTIVE`, `MAX_ACTIVE_SPELLS_REACHED`, `SPELL_NOT_ACTIVE`, `NOT_FOUND`, `FORBIDDEN`, `UNAUTHENTICATED`, `BAD_USER_INPUT` (arrives with BE Phase 10), plus `connection`, `timedOut`, `declined` (`successful: false`), `unknown`. Banner through `InAppNotificationsCubit.publishNotice` from a `BlocListener` (Phase 6 D-20 C1, Phase 7 `TravelOutcomeListener`). `SPELL_ALREADY_ACTIVE` and `SPELL_NOT_ACTIVE` only drop the pending overlay (the state already matches; BE Phase 4 §2 «riallinearsi»); `UNAUTHENTICATED` is silent; everything else → banner with Italian domain copy (provisional), titles «Magia non equipaggiata» / «Magia non tolta».
- **D-18:** Rollback = the card springs back to where it was (Claude's discretion, Phase 6 tear spring-back precedent) while the banner appears.

#### Process and quality
- **D-19:** **No UI phase, no UI-SPEC** (Phase 6 D-19 and Phase 7 carried forward): everything visual is provisional, token-based (`kg_theme.dart`), no new assets, simple to restyle.
- **D-20:** **TDD red → green → refactor:** unit tests for the failure classifier, the pending-overlay cubit (`bloc_test`), countdown derivation and formatting against a fixed server clock, the join of `spellStates` with `status.spells`/`activeSpells`, slot derivation and the empty-state rules; widget tests for the section (slot row, list line, bookmark, pending look, zero-slot copy, section absent without spells), the detail sheet and the long-press; `flutter analyze` with no new issues; `dart format` only on touched files (Phase 11 D-38); schema check in the final plan (D-03).
- **D-21:** **Boy Scout within scope:** the spells section leaves `journal.dart` for `tabs/journal/sections/` (the directory exists and is empty) and the `!` assertions it carries become null-safe reads; nothing else in the Journal is refactored unless a touched line asks for it.

### Claude's Discretion
- Ticker mechanism and sub-minute wording of the countdown (D-04); haptic pattern (D-08); pending look, resist/shake and spring-back geometry (D-07, D-16, D-18); detail sheet layout and the toggle affordance inside it (D-09); where the shared duration formatter and the bookmark widget live and their names (D-13, D-14); how the models join `spellStates` with `status.spells`/`activeSpells` (D-02); banner copy per code (D-17); whether the mutations live in `KlimmeckGraphQl` or in a dedicated repository (`docs/rules/architecture.md` decides the layer, not the name).

### Deferred Ideas (OUT OF SCOPE)
- FE mapping of `BAD_USER_INPUT` (BE Phase 10) in every classifier and of `IMAGE_REJECTED`/`IMAGE_MODERATION_UNAVAILABLE` in character creation (BE Phase 10 image moderation) — quick task or Phase 12, after the BE Phase 10 PR.
- «Spells used» lines in the combat result sheet — Phase 9 (depends on this phase).
- Spell learning UI and slot unlock — backend only (PROJECT.md out of scope).
- `JournalCubit` cleanup (`print`, unused `getData`) — Boy Scout when touched, otherwise backlog.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SPELL-01 | View owned spells from `Character.status.spells` | Extracted `SpellsSection` (Pattern 6) built from a pure `Spellbook` view (Pattern 2); list order = `status.spells` (D-15); section absent when `spells` empty and `maxActiveSpells == 0` (D-12) |
| SPELL-02 | Name, description, `maxUsages`, `recoveryTime`, `energyDamage` summary | Row = `SpellCard` + description + compact line from pure `spellSummaryLine` (Pattern 3); `recoveryTime` ms → `formatGameDuration` (moved Phase 7 formatter); `EnergyType.label` already Italian (`lib/models/enums/energy_type.dart:4-14`) |
| SPELL-03 | Tap equips into a backend-driven slot (amended: toggle, client block on full/zero slots, no `usages` sent) | `EquipSpell` document + `KlimmeckGraphQl.equipSpell` + `SpellsRepository` + `SpellsCubit.toggle` (Patterns 4–5); toggle intent computed on the **optimistic** view (flag F5) |
| SPELL-04 | Tap on a slot card disequips; long-press opens the detail sheet | `UnequipSpell` document; slot card `onTap`; long-press → `SpellInfoSheet` hosted by the Journal `Stack` (Pattern 7) |
| SPELL-05 | Remaining usages + live countdown in the row (amended) | `SpellState` model + optional `CharacterStatus.spellStates` (Pattern 1); `SpellRecoveryCubit` ticking on `ServerClockService.now()` (Pattern 8); fallback table (Pattern 2) |
| SPELL-06 | Optimistic slot assignment with rollback | `SpellsCubit` pending overlay keyed by spell id, token per op, 15 s settle timer, cleared by subscription match / failure / timeout (Pattern 5); `SpellOutcomeListener` banner + silent refetch on stale codes (flag F1); spring-back trigger via outcome sequence (Pattern 9) |
| SPELL-07 | Slots follow `maxActiveSpells` from the backend | Slot row renders exactly `maxActiveSpells` boxes from `Spellbook.slots` (no thresholds in FE); zero-slot neutral line (D-11); defensive against null `ActiveSpell.spell` and `activeSpells.length > maxActiveSpells` (flag F6) |
</phase_requirements>

## Project Constraints (from CLAUDE.md and docs/rules)

Same authority as locked decisions:

- **No UI chrome on gameplay screens**: the Journal is gameplay; the detail sheet is the parchment `EquipmentInfoSheet` pattern, banners are the shell `KgNotificationBanner` (`publishNotice`), never `SnackBar`/`AlertDialog`/`AppBar`. [CITED: CLAUDE.md rule 1; docs/rules/ui-ux.md]
- **No blocking loading in session**: equip/unequip is optimistic; the realignment refetch is `CharacterCubit.refreshCharacter()` which never emits `CharacterLoading` (`lib/screens/mainScreen/characterCubit/character_cubit.dart:75-95`). No spinner anywhere in the section. [CITED: CLAUDE.md rule 2; VERIFIED: code]
- **Backend is the source of truth**: no slot thresholds, no recovery math beyond `recoveries[0] − serverNow`; usages never decremented/incremented by the FE; state only from `characterUpdated`, never from `CommonResponse`. [CITED: CLAUDE.md rule 4; D-02, D-10, D-16]
- **Layering UI → Cubit → Repository → Service**; the UI never reads `ServerClockService` directly (consumed by a cubit, as `TravelProgressCubit` does); no `OperationException` reaches the UI; Cubits never call Cubits (orchestration via `BlocListener`); Cubits are Flutter-free (so `HapticFeedback` stays in widgets). [CITED: docs/rules/architecture.md, state-management.md, graphql.md]
- **Documents in `lib/graphql/`**, one named operation each, mutation = imperative PascalCase verb (`graphql.md` literally lists `EquipSpell` as the example); every named operation is in `tool/schema_check/schema_check_documents.dart` (enforced by `test/tool/schema_check_documents_test.dart:27-40`). [CITED: docs/rules/graphql.md, naming.md; VERIFIED: test file]
- **Models Flutter-free** (`lib/models/`), `Equatable`, `fromJson`/`toJson` tested first. [CITED: architecture.md, testing.md]
- **Theme tokens only** (`lib/theme/kg_theme.dart`), domain SVG via `CachedSvg`, no new assets (D-19). [CITED: ui-ux.md, assets.md]
- **TDD red → green → refactor**, `bloc_test` for every non-trivial cubit, widget smoke + interaction for gameplay widgets. [CITED: testing.md]
- **Formatting**: never `dart format` on directories; only new files and touched files measured clean (list in Pitfall 10). [CITED: Phase 11 D-38; user memory]
- **Commits**: Conventional Commits in English, docs scope `phase-8`, **no `Co-Authored-By` trailer** (user rule overrides the generic attribution reminder); branch `feat/08-spells-section-journal-tab`, PR to `develop` with `GH_TOKEN=$(gh auth token --user LucaTabbia)`. [CITED: user memory, docs/rules/workflow.md]
- **No secrets**: nothing in this phase reads `.env`; never print it.

## Summary

The partial section today is a single `BlocSelector` builder in `journal.dart:150-213` that renders `maxActiveSpells` bordered boxes filled with `SpellCard`s from `assets.activeSpells` and a `SpellRow` list from `status.spells`, with seven `!` assertions, no handlers and no tests (grep: no test references `Journal`, `SpellCard`, `SpellRow` or `SpellInfo`). The GraphQL documents `equipSpell`/`unequipSpell` exist (`character_mutations.dart:41-55`, lowercase operation names, unused), but there is no `EquipSpellRequest` model, no service method, no failure classifier and no cubit. `SpellInfo` is unused and carries the only spell-related analyzer warning (`spell_info.dart:52`, `dead_null_aware_expression`). The red bookmark ribbon exists in **two** places (`equipment_item_card.dart:174-199` and `equipment_info_sheet.dart:334-352`), and the pencil usages counter is duplicated verbatim between `SpellCard` (64-116) and `EquipmentItemCard` (121-173).

The backend contract is still a proposal: BE `origin/develop` (`121601e`) has no `spellStates`, and the BE 9.1 branch has only docs. I validated the proposed selection against a locally patched copy of the schema: `spellStates { usages recoveries spell { id } }` is `OK` on the proposed SDL and `FAIL` ("Cannot query field spellStates") on today's develop, while renamed `EquipSpell`/`UnequipSpell` documents are `OK` on today's develop. So everything except the fragment line can be built, tested and even exercised on device now; the fragment change is the gated last plan.

Three code facts reshape the CONTEXT slightly (flags below): (1) `PageView` in `MainScreen` disposes offscreen tabs (`cacheExtent: 0`, Flutter `page_view.dart:975`), so the `SpellsCubit` must be provided by `AuthenticatedShell` and its outcome listener mounted in `MainScreen` next to `TravelOutcomeListener`, otherwise a tab switch loses the pending overlay and the failure banner; (2) a rejected mutation writes nothing and emits nothing (BE Phase 4 handoff §0 item 7), so "only drop the overlay" for `SPELL_ALREADY_ACTIVE`/`SPELL_NOT_ACTIVE` leaves the client stale — those codes must also trigger the existing silent `refreshCharacter()` (precedent: `quest_abandon_outcome_listener.dart:17-20,35`); (3) the Journal sheet slides **up from the bottom** anchored right, not in from the right.

**Primary recommendation:** build in vertical slices — models + pure `Spellbook` view and formatters first, then the mutation slice (documents, service, classifier, repository), then `SpellsCubit` + listener + shell wiring, then the shared `BookmarkRibbon` / `SpellCard` / `SpellInfoSheet` widgets, then the `SpellRecoveryCubit` ticker, then the extracted `SpellsSection` wired into the Journal — and keep the `spellStates` fragment line, the schema check and the device E2E for the last plan, after the BE 9.1 PR is merged.

## Contract

### Today (BE `origin/develop` `121601e`, read with `git show origin/develop:src/schema.gql`) [VERIFIED]
```graphql
type ActiveSpell { spell: Spell  usages: Int! }            # spell is NULLABLE on the wire
type CharacterStatus { activeTravel: ActiveTravel  awaitingAid: AwaitingAid  coins: Coins!
  currentLifePoints: Int!  injuries: [InjuryType!]!  level: Int!  location: PointOfInterest!
  maxActiveSpells: Int!  maxLifePoints: Int!  spells: [Spell!]!  title: String!  xp: Int! }
type Spell { description: String!  energyDamage: EnergyDamage!  id: ID!  maxUsages: Int!
  minXpToLearn: Int!  name: String!  recoveryTime: Int!  requiredLearnTime: Int!  useType: String! }
input EquipSpellRequest { id: String!  spellId: String!  usages: Int }   # usages deprecated, ignored
type CommonResponse { response: String!  successful: Boolean! }
# Mutation: equipSpell(request: EquipSpellRequest!): CommonResponse!
#           unequipSpell(request: EquipSpellRequest!): CommonResponse!
#           useSpell(request: UseSpellRequest!): CommonResponse!   (server/combat only, out of scope)
```

### Proposed by 9.1 (BE `09.1-CONTEXT.md` D-05; not generated yet)
```graphql
type SpellState { spell: Spell!  usages: Int!  recoveries: [DateTime!]! }
extend CharacterStatus { spellStates: [SpellState!]! }
```
Semantics the FE relies on (BE 9.1 D-03, D-06, D-07, D-09): one entry per `status.spells` id, same order; `0 ≤ usages ≤ maxUsages`; `recoveries` ascending, never longer than `maxUsages − usages` (legacy jobs can leave it shorter); `equipSpell`/`unequipSpell` never touch the state; `useSpell` requires the spell **active** (so an inactive spell is below max only if it was used while active and then unequipped); a 60 s sweep restores overdue uses (`SPELL_RECOVERY_SWEEP_INTERVAL_MS`). Codes of equip/unequip unchanged: `SPELL_NOT_KNOWN`, `SPELL_ALREADY_ACTIVE`, `MAX_ACTIVE_SPELLS_REACHED`, `SPELL_NOT_ACTIVE`, `NOT_FOUND` (character missing/archived **or spell missing from the catalog**, BE 04 §4), `FORBIDDEN`, `UNAUTHENTICATED`. Malformed `spellId` → `SPELL_NOT_KNOWN` (equip) / `SPELL_NOT_ACTIVE` (unequip) (BE 04 §9).

### Probe results (this session, `tool/schema_check/validate_documents.js` with the BE's graphql-js)
| Document | today's develop | proposed 9.1 (patched copy) |
|---|---|---|
| `mutation EquipSpell($request: EquipSpellRequest!) { equipSpell(request: $request) { response successful } }` | OK | OK |
| `mutation UnequipSpell(...) { unequipSpell(...) { response successful } }` | OK | OK |
| `character(id) { status { … spellStates { usages recoveries spell { id } } } assets { activeSpells { usages spell { id } } } }` | **FAIL** (`Cannot query field "spellStates" on type "CharacterStatus"`) | OK |

## Standard Stack

No new runtime or dev dependency. [VERIFIED: pubspec.yaml + pubspec.lock]

### Core (already present)
| Library | Locked version | Purpose here |
|---------|----------------|--------------|
| flutter_bloc / bloc | 9.1.1 / 9.0.0 | `SpellsCubit`, `SpellRecoveryCubit`, `BlocListener`, `BlocSelector` |
| equatable | 2.0.7 | Models and states; deep `List`/`Map` equality in props (`equatable_utils.dart` `objectsEquals` → `iterableEquals`/`mapEquals`) |
| graphql_flutter | 5.2.1 | `performMutation` (`FetchPolicy.noCache`) |
| intl | 0.20.2 | Already used by `formatArrival`; not needed by this phase |
| Flutter SDK | 3.35.5 / Dart 3.9.2 | `HapticFeedback` (`flutter/services`), `SpringSimulation` (`flutter/physics`), `AnimatedPositioned`, `AnimatedOpacity` |

### Supporting (tests)
| Library | Version | Use |
|---------|---------|-----|
| flutter_test | SDK | widget tests, `tester.longPress`, `recordHaptics` helper |
| bloc_test | 10.0.0 | `blocTest`, `MockCubit`, `whenListen` |
| mocktail | 1.0.5 | `MockKlimmeckGraphQl` (exists), new `MockSpellsRepository`, `MockSpellsCubit`, `MockSpellRecoveryCubit` |
| fake_async | 1.3.3 | 15 s settle timer, repository timeout, recovery ticker |

### Alternatives Considered
| Instead of | Could use | Why not |
|-----------|-----------|---------|
| `SpellsCubit` at shell level | Cubit owned by the Journal/section | Offscreen pages are disposed (`page_view.dart:975`), losing pending ops and banners on tab change |
| 1 s periodic tick with deduplicated derived state | one-shot timer to the next label boundary | Saves a few wake-ups but more code and harder tests; the section is mounted only while the Journal page is visible |
| Moving `formatTravelDuration` | Importing `models/travel/travel_time_format.dart` from spells code | Cross-domain import with a travel-specific name; the move touches 2 lib call sites + 1 test |
| `package:clock` | `ServerClockService` / injected `DateTime Function()` | The project pattern (Phase 7) |

## Current code inventory (what the planner touches)

### Journal (`lib/screens/mainScreen/tabs/journal/journal.dart`, 491 lines, format-dirty)
- Whole page rebuilt by `BlocBuilder<CharacterCubit>` (426-489); sections composed in a `Column` inside `SingleChildScrollView` (454-476); `_buildSpellsSection(lootSize)` at 467 with `lootSize = (screenWidth - 180) / 5` (424) → 120 px on the 780×360 test surface.
- `_buildSpellsSection` (150-213): `BlocSelector<CharacterCubit, CharacterState, Character?>` selecting the **whole** `Character` (so it rebuilds on every emission; irrelevant because the parent rebuilds anyway); `Dropdown(sectionName: "Magie imparate")`; slot row `List.generate(character!.status!.maxActiveSpells!, …)` (167-196) with `Container(height/width: lootSize, BorderRadius 15, Border deepNight 2)`; slot filled when `character.assets!.activeSpells!.length > index` with `SpellCard(spell: …activeSpells![index].spell!, usages: …usages)`; list `List.generate(character.status!.spells!.length, (i) => SpellRow(spell, usages: spells[i].maxUsages))` (199-206). The `!` assertions are at 168 (×3), 181 (×2), 183-186, 188-191, 200, 202, 204.
- Sliding sheet: `AnimationController(300 ms)` (48-51) + `Tween(begin: screenHeight, end: 0)` set in `didChangeDependencies` (411-419); `_buildEquipmentInfoSheet` (298-336) is `AnimatedBuilder → Positioned(top: _positionAnimation.value, right: 0)` sized `height = screenHeight`, `width = screenHeight * 1.3 * 315/375`, i.e. **slides up from the bottom, anchored to the right edge**; `_selectedEquipment` cleared on `isDismissed` (60-64); opened by `_selectEquipment` (361-364); dismissed by the outer `GestureDetector(onTap: _animationController.reverse)` (442-443). `_JournalState` uses `SingleTickerProviderStateMixin` (35).
- `context.read<JournalCubit>().equipItem` (407): out of scope (D-21 deferred cleanup).

### Shared widgets
- `SpellCard` (`lib/shared/components/cards/spell_card.dart`, StatelessWidget, format-dirty): background `emptyCardSheet`, `useType!`/`energyDamage!.type!` icons, name, power hidden when 0 (57), optional `usages` counter = `AnimatedSwitcher` + `AnimatedPencilText(key: ValueKey(usages))` (64-116); `onTap` field declared but unused (15).
- `SpellRow` (`spell_row.dart`, format-clean): `Row(SpellCard, Expanded(description!))`; unused, wrongly-typed `onSelect: Function(AssetItem)?`, `onLongTap: Function(EquipmentItem)?`, `isSelected` (20-25).
- `SpellInfo` (`spell_info.dart`, format-dirty, unused): two rows (element icon + name, use icon + power); warning at 52.
- `EquipmentItemCard` (`equipment_item_card.dart`, StatefulWidget, format-dirty): local optimistic `_isSelected` flipped on tap then `Future.delayed(300 ms, onTap)` (55-66); ribbon (174-199): `Padding(top: size/25) → SizedBox(size − size/25, size) → Stack → AnimatedPositioned(300 ms, easeInOut, top: selected ? 0 : −(size/2.5)+20, left: 5) → RotatedBox(quarterTurns: 3) → SizedBox(size/2.5) → CachedSvg(bookmarkRed)`; `null` `isSelected` = no ribbon.
- `EquipmentInfoSheet` (`popup/equipment_info_sheet.dart`, format-dirty): parchment `emptySheet` sized from screen height; a second ribbon copy (334-352) used as the equip **toggle** (`GestureDetector(onTap: onEquip)` on the bookmark, peeking when not equipped); shows `SpellCard` for `addedSpell` (312).
- `ItemRow` (`item_row.dart`, clean): passes `isSelected` to `EquipmentItemCard`.
- `Dropdown` (`dropdown.dart`): closed by default (`isOpen = false`, 13); content under `ClipRect(SizeTransition(sizeFactor 0))` (136-148) — present in the tree but zero-size until the header is tapped.

### Models
- `Spell` (`lib/models/spell.dart`): all fields nullable except `id`; `recoveryTime`/`maxUsages`/`minXpToLearn`/`requiredLearnTime` parsed via `(num?)?.toInt()`; full `copyWith`, props.
- `ActiveSpell` (`active_spell.dart`): `Spell? spell`, `int? usages`; props `[usages, spell]`.
- `CharacterStatus` (`character/character_status.dart`): `spells` defaults to `[]` when absent (46-48); `maxActiveSpells` nullable (60); `activeTravel` via `ActiveTravel.tryFromJson` (61) — the tolerant-boundary precedent; `copyWith` does **not** take `activeTravel` and keeps it (78-103); only `fromJson` constructs it (grep), so a new optional named field breaks nothing.
- `CharacterAssets` (`character_assets.dart`): `activeSpells` defaults to `[]` (34-38).
- `ActiveTravel` (`travel/active_travel.dart:24-40`): `DateTime.parse(... as String)` on ISO `Z` strings → UTC instants; `toJson` writes `toUtc().toIso8601String()` — reuse for `recoveries`.
- `EnergyType`/`UseType` enums already carry Italian `label`s (`energy_type.dart:4-14`, `use_type.dart:3-35`).
- No `EquipSpellRequest` model exists (`lib/models/request/` has accept/abandon/travel/equip_item/transaction/create_character).

### GraphQL and service
- `CharacterFragment.statusFields` (`fragments/character_fragment.dart:23-53`) selects `maxActiveSpells` and `spells { SpellFields }`; `assetsFields` (55-84) selects `activeSpells { usages spell { SpellFields } }`. Used by `character` and `characterUpdated` (fragment-only change, Phase 3 D-05).
- `character_mutations.dart:41-55`: `mutation equipSpell($request: EquipSpellRequest!)` / `mutation unequipSpell(...)` selecting `response successful`; registered as `'equipSpell'`/`'unequipSpell'` (`schema_check_documents.dart:50-51`). No caller in `lib/`.
- `KlimmeckGraphQl` (`lib/repository/services/graphql/graphql.dart`): `performMutation` (79-91), `_dataOrThrow` (586-590), `startTravel` (538-554) returns the `successful` bool and throws `FormatException` on malformed — the shape to mirror. `equipItem` (426-443) is the legacy anti-pattern (string errors) — do not copy.
- Failure pattern: `travel_failure.dart` (enum + `TravelException` + `travelFailureFrom` using `graphQlErrorCode`, link error → `connection`); `graphql_error_code.dart` exports `forbiddenCode`, `notFoundCode`; `unauthenticatedCode` from `auth_api_exception.dart`.
- `TravelRepository._guard` (58-68): `timeout` 15 s → `timedOut`, `OperationException` → classifier, anything else → `unknown`; `successful: false` → `declined` (45).

### State and session wiring
- `CharacterCubit` (`character_cubit.dart`): emits `CharacterLoaded(character)` on every `characterUpdated` (104-109); `refreshCharacter()` (75-95) is silent, last-request-wins, skipped if a live event arrived meanwhile.
- `AuthenticatedShell` (`lib/screens/auth/authenticated_shell.dart:112-194`): `MultiBlocProvider` with `CharacterCubit`, `JournalCubit`, `InAppNotificationsCubit`, `QuestAcceptanceCubit`, `RepositoryProvider<ServerClockService>` (lazy: false, synced at creation), `TravelCubit` — the place for `SpellsCubit`.
- `MainScreen` (`main_screen.dart:98-101`): `QuestAcceptanceOutcomeListener → PartyWatchListener → TravelOutcomeListener → Scaffold`; pages built in `_buildPages` (173-188) inside a `PageView` (108-115, `NeverScrollableScrollPhysics`) — offscreen pages are disposed (Flutter `page_view.dart:975`, `cacheExtent: allowImplicitScrolling ? 1.0 : 0.0`, default `false`).
- `InAppNotificationsCubit.publishNotice(KGNotification, {required String dedupKey})` (`in_app_notifications_cubit.dart:63-71`): dedup window = display duration (5 s), key `notice|<dedupKey>`.
- `ServerClockService` (`repository/services/time/server_clock_service.dart`): concrete class, `now()`, `isSynced`, `offsetChanges` broadcast stream; `FakeServerClockService implements ServerClockService` (`test/helpers/fakes/fake_server_clock_service.dart`) with settable `current`, `advance`, `resync`.
- `TravelProgressCubit` (`tabs/map/travelProgressCubit/travel_progress_cubit.dart`): created in `WorldMap.initState` with `context.read<ServerClockService>()` (world_map.dart:87-94), `Timer.periodic(_tick)` started lazily and stopped when settled (84-100), recompute on `offsetChanges` (28, 77-80), `close()` cancels both (142-147) — the ticker template.
- `formatTravelDuration` (`models/travel/travel_time_format.dart:12-25`): `≤ 0 → '0 min'`, minutes **ceil**, `< 60 → 'N min'`, `< 24 h → 'H h'`/`'H h M min'`, else `'D g'`/`'D g H h'`; no sub-minute branch (30 s → `'1 min'`). Callers: `character_marker_layer.dart:122`, `travel_confirmation_sheet.dart:103`; test `test/models/travel/travel_time_format_test.dart`.
- Haptics precedent: `TearablePaper` (`shared/components/tear/tearable_paper.dart:102,107,133`) calls `HapticFeedback.lightImpact/selectionClick/mediumImpact` directly in the widget; spring-back = `_controller.animateWith(SpringSimulation(SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: 0.6), value, 0, velocity))` (54-58, 138-142). Test helper `recordHaptics(tester)` (`test/helpers/haptic_recorder.dart`) records `'HapticFeedbackType.lightImpact'` etc.

## Architecture Patterns

### Recommended structure (new/changed files)
```
lib/models/
├── spell/spell_state.dart              # NEW SpellState { spellId, usages, recoveries } + tryFromJson
├── spell/spellbook.dart                # NEW pure view: entries, slots, toggle intent (join + overlay)
├── spell/spell_recovery_status.dart    # NEW sealed status + pure derivation(state, serverNow)
├── spell/spell_lines.dart              # NEW pure Italian strings (summary line, usages line)
├── request/equip_spell_request.dart    # NEW { id, spellId } — never `usages`
└── character/character_status.dart    # + optional List<SpellState>? spellStates
lib/utils/game_duration_format.dart     # MOVED formatTravelDuration → formatGameDuration (+ «meno di 1 min» helper)
lib/graphql/mutations/character_mutations.dart   # rename ops EquipSpell / UnequipSpell
lib/graphql/fragments/character_fragment.dart    # LAST PLAN: spellStates { usages recoveries spell { id } }
lib/repository/services/graphql/graphql.dart     # + equipSpell / unequipSpell → bool successful
lib/repository/spell_equip_failure.dart          # NEW enum + exception + classifier
lib/repository/spells_repository.dart            # NEW equip/unequip with 15 s guard
lib/screens/mainScreen/tabs/journal/
├── spellsCubit/spells_cubit.dart, spells_state.dart, spell_notice.dart   # NEW (provided by the shell)
├── spellRecoveryCubit/spell_recovery_cubit.dart, spell_recovery_state.dart  # NEW (owned by the section)
├── sections/spells_section.dart        # NEW extracted section (Dropdown + content)
├── components/spell_slot_row.dart, known_spell_row.dart, spell_resist.dart  # NEW section widgets
└── journal.dart                        # calls SpellsSection; hosts the spell sheet in its Stack
lib/screens/mainScreen/components/spell_outcome_listener.dart  # NEW, mounted in MainScreen
lib/screens/auth/authenticated_shell.dart        # + BlocProvider<SpellsCubit>
lib/shared/components/bookmark_ribbon.dart       # NEW shared ribbon (3 call sites + spells)
lib/shared/components/cards/spell_card.dart      # + isMarked, onTap/onLongPress, isPending
lib/shared/components/spell_row.dart             # reworked or replaced by known_spell_row (single use)
lib/shared/components/spell_info.dart            # extended (D-09), warning fixed
lib/shared/components/popup/spell_info_sheet.dart  # NEW parchment sheet (EquipmentInfoSheet pattern)
tool/schema_check/schema_check_documents.dart    # keys 'EquipSpell', 'UnequipSpell' (34 entries, unchanged count)
```
Names are recommendations (CONTEXT leaves them to Claude); layers are fixed by `architecture.md`.

### Pattern 1: `SpellState` and the optional `spellStates` (D-02, D-03)
```dart
// lib/models/spell/spell_state.dart — Flutter-free
class SpellState extends Equatable {
  const SpellState({required this.spellId, required this.usages, required this.recoveries});
  final String spellId;            // from spell { id } — the fragment selects only the id
  final int usages;
  final List<DateTime> recoveries; // UTC instants, ascending (sorted defensively at parse)

  factory SpellState.fromJson(Map<String, dynamic> json) => SpellState(
    spellId: (json['spell'] as Map<String, dynamic>)['id'] as String,
    usages: (json['usages'] as num).toInt(),
    recoveries: List<DateTime>.unmodifiable(
      (json['recoveries'] as List).map((v) => DateTime.parse(v as String)).toList()..sort()),
  );
  static SpellState? tryFromJson(Object? json) { /* ActiveTravel.tryFromJson pattern */ }
  Map<String, dynamic> toJson() => {
    'spell': {'id': spellId}, 'usages': usages,
    'recoveries': recoveries.map((d) => d.toUtc().toIso8601String()).toList(),
  };
  @override List<Object?> get props => [spellId, usages, recoveries];
}
```
- `CharacterStatus.spellStates` is `List<SpellState>?`: **`null` = field absent** (fragment not yet extended, pre-9.1 backend) → fallback; a list → per-entry `tryFromJson`, malformed entries skipped (never blank the status). Add to `fromJson`, `toJson`, `props`; `copyWith` keeps it like `activeTravel` (never `spellStates ?? this.spellStates` with a clear semantics problem — just carry it).
- Parsing: ISO strings with `Z` → UTC `DateTime`; `==` on `DateTime` requires the same `isUtc` flag (probe: UTC vs `toLocal()` of the same instant → `false`, `isAtSameMomentAs` → `true`), so fixtures use `DateTime.utc(...)` or ISO `Z` strings (Pitfall 4).

### Pattern 2: pure `Spellbook` view — join + overlay + fallback (D-02/D-03/D-10/D-11/D-12/D-15/D-16)
One pure function turns `(Character, Map<String, SpellOperation> pending)` into everything the widgets render. No widget computes state.
```dart
enum SpellOperation { equip, unequip }
class SpellbookEntry {            // one per status.spells item, BE order (D-15)
  final Spell spell;
  final int usages;               // see fallback table
  final int? maxUsages;
  final bool isActive;            // optimistic: server active ± pending
  final bool isPending;
  final SpellState? state;        // null → no recovery data (fallback)
}
class Spellbook {
  final bool isVisible;           // spells.isNotEmpty || maxActiveSpells > 0   (D-12)
  final int slotCount;            // maxActiveSpells ?? 0; 0 → neutral line (D-11)
  final List<SpellSlot> slots;    // exactly slotCount items; SpellSlot.empty or .filled(spell, usages, isPending)
  final List<SpellbookEntry> entries;
  SpellToggleIntent intentFor(String spellId); // equip | unequip | blockedSlotsFull | blockedNoSlots | ignoredPending
}
```
**Optimistic active list** = server `activeSpells` (filtered `spell != null`, flag F6) minus pending unequips, plus pending equips appended in tap order (the BE `$push` appends, `$pull` compacts — so the optimistic order equals the confirmed order). Slots = first `slotCount` items of that list; never index past it (D-10).

**Fallback table** (D-03/D-04; "state" = `spellStates` entry for the id):
| Case | Row usages shown | Row recovery item | Slot card counter |
|---|---|---|---|
| state present, `usages == maxUsages` | `Usi: 3` (max) | `Recupero: 2 h` (catalog) | `state.usages` |
| state present, `usages < max`, `recoveries` non-empty, `recoveries[0] > now` | `Usi: 1/3` | `prossimo tra 12 min` | `state.usages` |
| state present, `usages < max`, `recoveries[0] <= now` | `Usi: 1/3` | `in arrivo…` | `state.usages` |
| state present, `usages < max`, `recoveries` empty (legacy) | `Usi: 1/3` | `in recupero` (no time) | `state.usages` |
| `spellStates == null` (pre-9.1) **or** no entry for the id, spell **active** with `ActiveSpell.usages < max` | `Usi: u/3` | `in recupero` (no time) | `ActiveSpell.usages` |
| same, spell active with `usages == max`, or spell **inactive** | `Usi: 3` (catalog `maxUsages`) | `Recupero: 2 h` | `ActiveSpell.usages` |
| `maxUsages == null` (defensive) | `Usi: u` without denominator | nothing | as above |

The rest of the compact line (`Recupero: …` only at full usages, `Danno: Fuoco 12`) follows D-13. Pre-9.1 note: today's BE (Phase 4 D-11) resets usages to max on equip, so on device before 9.1 an inactive spell always reads full — consistent with the table.

**Toggle intent** (D-06/D-07/D-11/D-16), computed on the optimistic view: pending → `ignoredPending`; active → `unequip` (allowed even with `slotCount == 0`, e.g. legacy data); inactive and `slotCount == 0` → `blockedNoSlots`; inactive and `optimisticActive.length >= slotCount` → `blockedSlotsFull`; otherwise `equip`.

### Pattern 3: Italian strings (D-04, D-13) — pure, unit-tested
- `formatGameDuration(Duration)` = today's `formatTravelDuration` moved to `lib/utils/game_duration_format.dart` (2 lib call sites + test move; behaviour identical). `formatRecoveryCountdown(Duration remaining)` = `remaining < 1 min → 'meno di 1 min'`, else `formatGameDuration(remaining)` (ceil keeps «1 min» … «59 min» honest).
- `spellSummaryLine(entry, status)`: `Usi: 3 · Recupero: 2 h · Danno: Fuoco 12` / `Usi: 1/3 · prossimo tra 12 min · Danno: Fuoco 12` / `… · in arrivo… · …` / `… · in recupero · …`. `Recupero` from `Duration(milliseconds: spell.recoveryTime)`; omit the item when `recoveryTime == null`. `Danno` uses `EnergyType.label`; power `0` → element only (SpellCard already hides a 0 power, `spell_card.dart:57`).

### Pattern 4: mutation slice (mirror of Phase 7)
- `EquipSpellRequest { id, spellId }` (Equatable, `toJson() => {'id': id, 'spellId': spellId}` — the test asserts the key `usages` is absent).
- Documents renamed (naming.md, graphql.md): `mutation EquipSpell($request: EquipSpellRequest!)`, `mutation UnequipSpell(...)`; registry keys updated in the same commit (34 entries, count unchanged).
- `KlimmeckGraphQl.equipSpell(EquipSpellRequest) → Future<bool>` and `unequipSpell(...)`: `_dataOrThrow(performMutation(variables: {'request': request.toJson()}))`, read `successful` like `startTravel` (538-554); malformed → `FormatException`.
- `spell_equip_failure.dart`: constants `spellNotKnownCode = 'SPELL_NOT_KNOWN'`, `spellAlreadyActiveCode`, `maxActiveSpellsReachedCode`, `spellNotActiveCode`, `badUserInputCode = 'BAD_USER_INPUT'`; `enum SpellEquipFailure { notKnown, alreadyActive, slotsFull, notActive, notFound, forbidden, badUserInput, unauthenticated, connection, timedOut, declined, unknown }`; `SpellEquipException`; `spellEquipFailureFrom(OperationException)` identical in shape to `travelFailureFrom` (link error without code → `connection`). `SPELL_NO_USAGES_LEFT`/`SPELL_RECOVERY_UNAVAILABLE` are `useSpell`-only → `unknown` if ever seen.
- `SpellsRepository({required KlimmeckGraphQl graphQl, Duration timeout = 15 s})`: `equip({characterId, spellId})`, `unequip(...)`; `_guard` copied from `TravelRepository` (58-68); `false` → `SpellEquipException(declined)`. No permission gate.

### Pattern 5: `SpellsCubit` pending overlay (D-16, D-17, D-18)
Provided in `AuthenticatedShell` (flag F3), fed by the listener, Flutter-free, `SafeEmit`.
```dart
class SpellsState extends Equatable {
  const SpellsState({this.pending = const {}, this.outcome});
  final Map<String, SpellOperation> pending;   // keyed by spell id (D-16)
  final SpellOutcome? outcome;                 // last rollback/block event, for listener + spring-back
  @override List<Object?> get props => [pending, outcome];
}
class SpellOutcome extends Equatable {         // sequence makes repeated identical events distinct
  final int sequence; final String spellId; final SpellOperation operation;
  final SpellOutcomeKind kind;                 // blockedSlotsFull | blockedNoSlots | failed
  final SpellEquipFailure? failure;
}

class SpellsCubit extends Cubit<SpellsState> with SafeEmit<SpellsState> {
  SpellsCubit(this._repository, {this.settleTimeout = const Duration(seconds: 15)});
  SpellToggleIntent toggle({required Character character, required String spellId}); // sync result for haptics
  void sync(Character character);   // from the CharacterCubit listener: clears matched ops
  @override Future<void> close();    // cancels every timer
}
```
Rules:
1. `toggle` recomputes the intent with `Spellbook` on `(character, pending)`; `ignoredPending` → nothing; `blocked*` → emit `outcome(kind: blocked…)` (no BE call, D-07/D-11); `equip`/`unequip` → add `pending[spellId]`, start a `Timer(settleTimeout)` with a fresh token, fire the repository call unawaited. It also stores `character` as the latest snapshot.
2. `sync(character)`: for each pending op, **match** = equip and id ∈ active ids, or unequip and id ∉ active ids → remove + cancel its timer.
3. Repository success: if the latest snapshot already matches → clear; else keep (wait for `characterUpdated` or the timer).
4. Repository failure (token still current): remove the op, cancel timer, emit `outcome(kind: failed, failure)`.
5. Timer expiry (token current): remove the op silently if the request already succeeded; if still in flight, remove it, invalidate the token, emit `outcome(failed, timedOut)` — the late answer is ignored by token (Phase 7 07-07 "late answers ignored by request token").
6. One op per spell: the token map is keyed by spell id; `toggle` on a pending id is `ignoredPending`.
Testing: `fakeAsync` around cubit creation + `async.elapse(const Duration(seconds: 15))` + `flushMicrotasks` (pattern `travel_progress_cubit_test.dart:46-56`, `travel_repository_test.dart:125-144`); `blocTest` for the simple sequences.

### Pattern 6: extracted `SpellsSection` (D-10..D-15, D-21)
- `SpellsSection({required double cardSize, required ValueChanged<Spell> onShowDetails})` in `tabs/journal/sections/`; reads `CharacterCubit` (`BlocSelector` on the inputs: `spells`, `activeSpells`, `maxActiveSpells`, `spellStates`, character id), `SpellsCubit` (`BlocBuilder` on `pending`), and owns a `BlocProvider<SpellRecoveryCubit>(create: …context.read<ServerClockService>())` so the ticker lives and dies with the Journal page.
- `!spellbook.isVisible` → `SizedBox.shrink()` (D-12). Otherwise `Dropdown(sectionName: 'Magie imparate', data: SpellbookContent(...))`; content split into `SpellSlotRow` (exactly `slotCount` bordered boxes, `KlimmeckGuideTheme.radius`/`deepNight` tokens; or the neutral line when 0) and `KnownSpellRow` per entry (`ValueKey(spell.id)`).
- Taps: widget calls `final intent = context.read<SpellsCubit>().toggle(...)`; then `switch(intent)`: `equip`/`unequip` → `HapticFeedback.lightImpact()` (D-08); `blocked*` → `HapticFeedback.selectionClick()` + local resist (D-07); `ignoredPending` → nothing. Long-press → `onShowDetails(spell)`.
- Pending look: `AnimatedOpacity(opacity: entry.isPending ? pendingInkOpacity : 1, duration: 200 ms)` on the slot card and the row card (constant defined once, e.g. in the section or as a theme token).

### Pattern 7: detail sheet hosted by the Journal (D-09)
The overlay must sit in the Journal page `Stack` (447-481), not inside the scrolled section. Generalize `_selectedEquipment` into one selection (`EquipmentItem` or `Spell`) and `_buildEquipmentInfoSheet` into `_buildInfoSheet` that renders `EquipmentInfoSheet` or `SpellInfoSheet` with the same `AnimationController`, `Positioned(top: _positionAnimation.value, right: 0)` geometry and dismissal (outer tap → `reverse`, clear on `isDismissed`). `SpellInfoSheet` mirrors `EquipmentInfoSheet`'s parchment layout and embeds the extended `SpellInfo` (name, description, element+power, use type, max usages, recovery time, `minXpToLearn`, `requiredLearnTime` formatted with `formatGameDuration` — unit of `requiredLearnTime` to confirm, Open Question 9 — current usages and the same recovery label as the row). Toggle affordance: the shared `BookmarkRibbon` as a tappable bookmark (same affordance as the equipment sheet), wired to the same `SpellsCubit.toggle`; it reads `SpellsCubit` + `CharacterCubit` through `BlocBuilder` so it reflects the pending/confirmed state live.

### Pattern 8: `SpellRecoveryCubit` countdown ticker (D-04, D-05)
```dart
sealed class SpellRecoveryStatus extends Equatable {}  // Full | Countdown(remainingCeilMinutes or label) | Arriving | RecoveringUnknown
class SpellRecoveryCubit extends Cubit<Map<String, SpellRecoveryStatus>> with SafeEmit {
  SpellRecoveryCubit({required ServerClockService clock, Duration tick = const Duration(seconds: 1)});
  void follow(List<SpellRecoveryInput> inputs); // (spellId, usages, maxUsages, recoveries) from the section
}
```
- Derivation is a pure function `spellRecoveryStatusOf(input, serverNow)` (unit-tested). The cubit emits the whole map; Equatable dedupes, so widgets rebuild only when a label actually changes (quantize `Countdown` to what the label shows, i.e. the ceil-minute count).
- `Timer.periodic(tick)` runs only while at least one `Countdown` exists; stop when none (all `Full`/`Arriving`/`RecoveringUnknown`); recompute on `clock.offsetChanges`; `close()` cancels timer and subscription (copy `TravelProgressCubit` 28, 84-100, 142-147).
- Fed from the section: initial `follow(...)` at creation and a `BlocListener<CharacterCubit>` on the inputs. Before the first clock sync the device clock is used for a few hundred ms (Phase 7 decision); the next tick/offset event corrects.

### Pattern 9: banner, realignment and spring-back (D-07, D-17, D-18)
- `SpellOutcomeListener` in `MainScreen` (next to `TravelOutcomeListener`, `main_screen.dart:98-101`), `MultiBlocListener`:
  - `BlocListener<CharacterCubit>` (`listenWhen` both loaded and character changed) → `spells.sync(character)`.
  - `BlocListener<SpellsCubit>` (`listenWhen: previous.outcome != current.outcome && current.outcome != null`) → `spellNoticeFor(outcome)` → `publishNotice(notice, dedupKey: 'spell|${kind}|${failure?.name}|${spellId}')`; for stale-state failures (`alreadyActive`, `notActive`, `notKnown`, `slotsFull`, `notFound`) also `context.read<CharacterCubit>().refreshCharacter()` (flag F1).
- `spell_notice.dart`: titles «Magia non equipaggiata» (equip) / «Magia non tolta» (unequip); `blockedSlotsFull` → «Slot pieni: disequipaggia una magia», `blockedNoSlots` → «Nessuno slot disponibile»; `alreadyActive`/`notActive`/`unauthenticated` → `null` (no banner); others → domain copy (provisional), e.g. `notKnown` «Non conosci questa magia», `slotsFull` «Slot pieni: disequipaggia una magia», `notFound` «Questa magia non è più disponibile», `forbidden` «Questo personaggio non può farlo», `badUserInput`/`declined`/`unknown` «Qualcosa è andato storto, riprova», `connection` «Connessione assente, riprova», `timedOut` «Il server non ha risposto in tempo: controlla le magie prima di riprovare».
- Spring-back/resist: `KnownSpellRow` and slot cards listen to `SpellsCubit` with `listenWhen` on `outcome.sequence` for their spell id and run a short horizontal shake (`AnimationController` + `SpringSimulation` with the `TearablePaper` spring, or a `TweenSequence` of ±6 px over ~300 ms). The overlay removal itself moves the card back (it leaves/re-enters the slot because the optimistic list changes), so the "spring" is the shake on the row plus the ribbon's own `AnimatedPositioned` return.

### Pattern 10: shared `BookmarkRibbon` (D-14 zero duplication)
```dart
// lib/shared/components/bookmark_ribbon.dart — returns AnimatedPositioned: place it directly in a Stack
class BookmarkRibbon extends StatelessWidget {
  const BookmarkRibbon({super.key, required this.isMarked, required this.length,
    required this.peek, this.left = 5, this.onTap});
  // top: isMarked ? 0 : -length + peek; RotatedBox(quarterTurns: 3) + CachedSvg(bookmarkRed); 300 ms easeInOut
}
```
Replace both existing copies (`equipment_item_card.dart:174-199`: `length = size/2.5`, `peek = 20`, wrapper `Padding(top: size/25)` + clipped `Stack` stays in the card; `equipment_info_sheet.dart:334-352`: `length = screenHeight/2.5`, `peek = screenHeight/4`, `left: 20`, `onTap: onEquip`) and use it in `SpellCard(isMarked: …)`. Verified empirically: an `AnimatedPositioned` returned by a `StatelessWidget` that is a direct child of a `Stack` lays out and animates (throwaway probe, mid-animation offset between start and end, no exception). Visual parity check: equipment card/sheet goldens do not exist, so the plan's widget test asserts the ribbon's top offset for marked/unmarked.

### Anti-Patterns to Avoid
- Building state from `CommonResponse` or decrementing usages locally (CLAUDE.md rule 4).
- Copying `EquipmentItemCard`'s local `_isSelected` + `Future.delayed(300 ms)` pattern into spells: it duplicates optimistic state outside the cubit and leaves pending timers in widget tests.
- Owning `SpellsCubit` or the banner listener inside the Journal page (disposed on tab change).
- Calling `HapticFeedback` or reading `ServerClockService` in a cubit/model (Flutter-free rule / UI → Cubit rule).
- `context.read<CharacterCubit>().state` to render (state-management.md: use `BlocSelector`/`BlocBuilder`).
- Re-sorting or grouping the list (D-15).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Server "now" | device `DateTime.now()` or a new offset | `ServerClockService.now()` (+ `offsetChanges`) | RTT-compensated, resynced on foreground (Phase 7) |
| Duration wording | a second formatter | `formatTravelDuration` moved to `formatGameDuration` | Same ceil semantics already tested |
| Error code extraction | parsing `message` | `graphQlErrorCode(OperationException)` | Handles `graphqlErrors` and `SubscriptionError` payloads |
| Banner | SnackBar / custom overlay | `InAppNotificationsCubit.publishNotice` | Shell queue, dedup, auto-dismiss, immersive |
| Silent realignment | a new query | `CharacterCubit.refreshCharacter()` | Silent, last-wins, yields to live events |
| Bookmark ribbon | a third/fourth copy | shared `BookmarkRibbon` | D-14 zero duplication |
| Spring physics | hand-tuned tween curves | `SpringSimulation` + `TearablePaper` spring description | Existing tuned precedent |
| Post-close emits | `if (!isClosed)` everywhere | `SafeEmit` mixin | Project pattern |
| Haptic assertions | platform mocks per test | `recordHaptics(tester)` | Existing helper |

**Key insight:** every hard part of this phase already exists once in the codebase (clock, ticker, classifier, repository guard, banner, spring, ribbon); the work is composition plus one genuinely new piece — the pending overlay with tokens.

## Runtime State Inventory

Not a rename/migration phase. The only rename is two GraphQL operation names (`equipSpell` → `EquipSpell`, `unequipSpell` → `UnequipSpell`): no persisted queries or operation-name allowlist exists on the BE (`git grep operationName origin/develop -- src` → no match) or the FE (`grep -rn operationName lib` → no match); no stored data, OS registration, secret or build artifact references them. Nothing to migrate.

## Common Pitfalls

### Pitfall 1: losing the overlay or the banner on tab change
**What goes wrong:** pending ops vanish and a failure arriving after the user left the Journal never shows. **Why:** `PageView` disposes offscreen pages (`page_view.dart:975`, `cacheExtent 0`). **Avoid:** `SpellsCubit` in `AuthenticatedShell`, `SpellOutcomeListener` in `MainScreen`. **Detect:** a widget test that switches page with a failure in flight.

### Pitfall 2: stale client after a "silent" rejection
**What goes wrong:** `SPELL_ALREADY_ACTIVE` → overlay dropped → the row still shows the spell inactive forever. **Why:** a rejected mutation writes nothing and emits nothing (BE 04 §0 item 7). **Avoid:** silent `refreshCharacter()` on stale-state codes (flag F1).

### Pitfall 3: client block counted on the server list only
**What goes wrong:** with 1 slot, tapping A then B quickly sends two equips (the second gets `MAX_ACTIVE_SPELLS_REACHED` → banner). **Avoid:** compute D-07/D-11 on the optimistic view (Pattern 2, flag F5).

### Pitfall 4: `DateTime` equality and Equatable
`DateTime ==` is true only with the same `isUtc` (probe this session). Parse with `DateTime.parse` of ISO `Z` strings (UTC) and build expectations with `DateTime.utc`; never compare a `toLocal()` value. Equatable compares `List<DateTime>`/`Map` props deeply (`equatable_utils.dart` `objectsEquals`), so states dedupe correctly.

### Pitfall 5: ticker timers left pending in widget tests
`Timer.periodic` in `SpellRecoveryCubit` must stop when no countdown exists and in `close()`; the cubit must be created by a `BlocProvider(create:)` inside the section so the tree teardown closes it. Otherwise flutter_test fails with "A Timer is still pending even after the widget tree was disposed". Same for the 15 s settle timers (the shell cubit is a `MockSpellsCubit` in widget tests; real-cubit tests use `fakeAsync`).

### Pitfall 6: `Dropdown` content is zero-size until opened
`Dropdown` starts closed (`dropdown.dart:13`, `SizeTransition` at 0): `tester.tap` on a row inside it misses. **Avoid:** widget-test `SpellbookContent` directly, and test the `SpellsSection` wrapper by tapping the «Magie imparate» header first.

### Pitfall 7: overflow in widget tests
The content (slot row + N rows of 120 px cards) exceeds the 780×360 test surface; wrap the harness in a `SingleChildScrollView` with a fixed width (the Journal provides one in production) and seed SVGs (`emptyCardSheet`, `bookmarkRed`, `arrowDown`, `emptySheet`, the fixture's energy/use ids) with `seedSvgCache`.

### Pitfall 8: `ActiveSpell.spell` is nullable on the wire
`schema.gql:15-18`: `spell: Spell` (nullable). The current code asserts it (`journal.dart:186`). **Avoid:** filter null spells out of the optimistic active list (flag F6).

### Pitfall 9: `MainScreen` tests break when a listener is added
`main_screen_test.dart:170` provides `MockTravelCubit` for `TravelOutcomeListener`; adding `SpellOutcomeListener` requires a `MockSpellsCubit` provider there too (and `authenticated_shell_test.dart` should assert the real cubit is provided).

### Pitfall 10: `dart format` and the analyzer gate
Format-**dirty** today (never format the whole file; format only new files, keep touched hunks hand-formatted): `journal.dart`, `spell_card.dart`, `spell_info.dart`, `equipment_item_card.dart`, `equipment_info_sheet.dart`, `spell_fragment.dart`. Format-**clean** (check with `dart format --output=none --set-exit-if-changed <file>` after editing): `spell_row.dart`, `item_row.dart`, `spell.dart`, `active_spell.dart`, `character_status.dart`, `character_assets.dart`, `character_fragment.dart`, `character_mutations.dart`, `graphql.dart`, `authenticated_shell.dart`, `main_screen.dart`, `schema_check_documents.dart`, `travel_time_format.dart`, `mocks.dart`, `character_fragment_test.dart`, `character_status_test.dart`, `sync_event_fixtures.dart`, `journal_cubit.dart`. Analyzer baseline 54 issues / 0 errors / 2 warnings; fixing `spell_info.dart:52` brings it to 53.

### Pitfall 11: schema-check registry and naming
Renaming the operations without updating the registry keys fails `test/tool/schema_check_documents_test.dart` (keys must equal declared names). Do both in one commit.

### Pitfall 12: gesture finders in tests
Inner `GestureDetector(onTap, onLongPress)` wins over the Journal's outer dismiss `GestureDetector` (probe: tap then long-press on the inner → `['tap', 'long']`). Use keyed finders (`ValueKey('spell-row-<id>')`) and pump between consecutive gestures; a broad `find.byType(Stack).last` hit the wrong target in the first probe.

### Pitfall 13: `maxActiveSpells` below the active count
If the BE ever reports fewer slots than active spells (legacy data, GM edit), the slot row shows `slotCount` cards and the extra active spells are visible only as bookmarked rows (still tappable to unequip). Do not render extra boxes (D-10, SPELL-07).

## Code Examples

### Service methods (mirror `startTravel`, graphql.dart:538-554)
```dart
// lib/graphql/mutations/character_mutations.dart
static const String equipSpell = r'''
  mutation EquipSpell($request: EquipSpellRequest!) {
    equipSpell(request: $request) {
      response
      successful
    }
  }''';

// lib/repository/services/graphql/graphql.dart
/// La magia arriva su `characterUpdated`, mai da questa risposta (D-16).
Future<bool> equipSpell(EquipSpellRequest request) =>
    _spellMutation(CharacterMutations.equipSpell, 'equipSpell', request);

Future<bool> _spellMutation(String document, String field, EquipSpellRequest request) async {
  final data = _dataOrThrow(await performMutation(
    query: document,
    variables: {'request': request.toJson()},
  ));
  final result = data[field];
  final successful = result is Map<String, dynamic> ? result['successful'] : null;
  if (successful is! bool) throw FormatException('$field malformed');
  return successful;
}
```

### Recorded responses (existing helpers)
`test/helpers/fixtures/sync_event_fixtures.dart`: `dataResponse({'equipSpell': {'response': 'ok', 'successful': true}})`, `errorCodeResponse('SPELL_NOT_KNOWN')`; client built as in `test/repository/services/graphql/graphql_travel_test.dart:20-30` (`Link.function` recording `requests`, `operationNameOf`).

### Fixture shape (Wave 0, `test/helpers/fixtures/spell_fixtures.dart`)
```dart
Map<String, dynamic> spellJson({String id = 'spell-1', String name = 'Dardo', int maxUsages = 3,
    int recoveryTime = 7200000, String energy = 'fire', int power = 12, String useType = 'attack'}) => {...};
Map<String, dynamic> spellStateJson({String spellId = 'spell-1', int usages = 1,
    List<String> recoveries = const ['2026-10-27T10:12:00.000Z', '2026-10-27T10:42:00.000Z']}) => {...};
Map<String, dynamic> spellbookCharacterJson({String id = 'c-1', int maxActiveSpells = 2,
    List<Map<String, dynamic>> spells = ..., List<Map<String, dynamic>> activeSpells = ...,
    List<Map<String, dynamic>>? spellStates}) => {...}; // spellStates null = pre-9.1 payload
```

### Countdown test shape
```dart
test('next recovery reads the ceil minutes from server time', () {
  final now = DateTime.utc(2026, 10, 27, 10);
  final status = spellRecoveryStatusOf(
    SpellRecoveryInput(spellId: 's', usages: 1, maxUsages: 3,
      recoveries: [DateTime.utc(2026, 10, 27, 10, 11, 30)]), now);
  expect(recoveryLabel(status), 'prossimo tra 12 min');
});
```

## State of the Art

| Old approach | Current approach | When | Impact |
|---|---|---|---|
| Equip resets usages to `maxUsages` (BE 04 D-11) | Usages and recoveries per known spell, untouched by equip/unequip | BE 9.1 (pending) | FE shows the same usages before/after equip; no FE rule |
| `EquipSpellRequest.usages` sent | Deprecated, ignored, never sent | BE Phase 4 | Request model has no `usages` |
| `unequipSpell` on an inactive spell → `NOT_FOUND` | `SPELL_NOT_ACTIVE` | BE Phase 4 | Classifier maps both |
| `useSpell` compensates on enqueue failure (`SPELL_RECOVERY_UNAVAILABLE`) | Best-effort enqueue + sweep; code may disappear | BE 9.1 D-06 | FE does not map it |

**Deprecated/outdated in the FE:** lowercase operation names `equipSpell`/`unequipSpell`; `SpellRow`'s wrongly-typed callbacks; `SpellInfo`'s dead `?? ""`.

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|-------|---------|---------------|
| A1 | The 9.1 SDL will be exactly `SpellState { spell: Spell!, usages: Int!, recoveries: [DateTime!]! }` on `CharacterStatus.spellStates` [ASSUMED from BE 09.1-CONTEXT D-05, not generated yet] | Contract, Pattern 1 | Fragment line and parser change; the gated last plan re-validates against `origin/develop` |
| A2 | `DateTime` scalar serializes as ISO-8601 with `Z` like `activeTravel.endTime` [ASSUMED by analogy with the Phase 7 contract] | Pattern 1 | Parse would need another format; `tryFromJson` keeps the status alive anyway |
| A3 | `requiredLearnTime` is milliseconds like `recoveryTime` [ASSUMED; the BE model types it `Int` with no unit doc found] | Pattern 7 | The sheet line would show a wrong duration; ask the BE handoff (Open Question 9) |

## Open Questions (RESOLVED)

1. **Where does `SpellsCubit` live and who mounts the banner listener?** — RESOLVED: file in `tabs/journal/spellsCubit/` (D-16), provider in `AuthenticatedShell` next to `TravelCubit`, `SpellOutcomeListener` in `MainScreen` next to `TravelOutcomeListener`. Evidence: `page_view.dart:975` (`cacheExtent 0`), `main_screen.dart:98-115,173-182`, `authenticated_shell.dart:185-193`.
2. **How does the overlay know the subscription matched, given Cubits never call Cubits?** — RESOLVED: `SpellOutcomeListener` forwards every `CharacterLoaded` to `SpellsCubit.sync(character)`; `toggle` also receives the current character (latest snapshot) so a success answering after the event clears immediately.
3. **What happens on timeout?** — RESOLVED: one 15 s settle timer per op from the tap; token-guarded; in-flight at expiry → `timedOut` banner + late answer ignored; already succeeded but unmatched → silent clear (the session sync's refetch-on-reconnect realigns). Repository keeps its own 15 s guard for parity with Phase 6/7.
4. **Do `SPELL_ALREADY_ACTIVE`/`SPELL_NOT_ACTIVE` need anything beyond dropping the overlay?** — RESOLVED: yes, a silent `refreshCharacter()` (flag F1); also after `SPELL_NOT_KNOWN`, `MAX_ACTIVE_SPELLS_REACHED`, `NOT_FOUND`. Evidence: BE 04 §0 item 7; precedent `quest_abandon_outcome_listener.dart:17-20,35`.
5. **Does the row's `SpellCard` keep the pencil counter?** — RESOLVED: no; the compact line carries the usages and today's row counter shows `maxUsages` (`journal.dart:204`), which would contradict «Usi: 1/3». The slot card keeps its counter (D-05). (Flag F9 for the record.)
6. **Sub-minute wording (D-04)?** — RESOLVED: «meno di 1 min» for `0 < remaining < 1 min`; ≥ 1 min uses the ceil formatter; past instant → «in arrivo…». No seconds (keeps the 1 s tick cheap and labels calm).
7. **Where does the shared formatter live?** — RESOLVED: `lib/utils/game_duration_format.dart` as `formatGameDuration` (pure helper, utils layer); move `formatTravelDuration` and its tests in a `refactor` commit; `formatArrival`/`formatTravelDistance` stay in travel.
8. **Mutations in `KlimmeckGraphQl` or a dedicated repository?** — RESOLVED: both, by layer: service methods in `KlimmeckGraphQl` (single client owner), domain mapping in `SpellsRepository` (architecture.md "classi XxxRepository esposte all'app"), exactly like `TravelRepository`.
9. **Unit of `requiredLearnTime` in the sheet?** — RESOLVED for planning: render it with `formatGameDuration(Duration(milliseconds: …))` and ask the BE 9.1 handoff to confirm the unit (A3); a wrong unit is a one-line fix and display-only.
10. **Haptic pattern?** — RESOLVED: `lightImpact` on an accepted tap, `selectionClick` on a blocked tap, nothing on confirmation/rollback (D-08), all in widgets.
11. **Pending look values?** — RESOLVED: `AnimatedOpacity` to 0.5 over 200 ms on the slot card and the row card while pending; constant defined once; provisional (D-19).
12. **How is the spring-back triggered?** — RESOLVED: `SpellsState.outcome` with an increasing `sequence`; rows/slot cards with `listenWhen` on their spell id run a short spring shake; the optimistic list change moves the card itself.
13. **`BAD_USER_INPUT` now or deferred?** — RESOLVED: mapped now in the new classifier (D-17 lists it; the deferred item concerns the existing classifiers). Flag F8 records the clarification.
14. **Should the FE call `useSpell` or show `SPELL_NO_USAGES_LEFT`?** — RESOLVED: no (out of scope; combat only); those codes map to `unknown` if ever returned by equip/unequip.
15. **What if `recoveries` arrives unsorted?** — RESOLVED: sort at parse (cheap, contract says ascending anyway).
16. **Section before BE 9.1 on device?** — RESOLVED: works with the fallback table; equip/unequip are already live on BE develop (with the Phase 4 reset-on-equip semantics until 9.1).

## Research flags for the orchestrator

| # | Decision | Finding (evidence) | Proposed amendment wording |
|---|----------|--------------------|----------------------------|
| **F1** | D-17: «`SPELL_ALREADY_ACTIVE` and `SPELL_NOT_ACTIVE` only drop the pending overlay (the state already matches…)» | The client state does **not** match: these codes only happen when the client view is stale, and a rejection writes and emits nothing (BE `04-…/BACKEND-NOTES.md` §0 item 7: «Un rifiuto non scrive nulla e quindi non emette nulla»). Dropping the overlay leaves the stale view. A silent refetch already exists (`character_cubit.dart:75-95`) and is used after stale-lane failures (`quest_abandon_outcome_listener.dart:17-20,35`). | D-17: «`SPELL_ALREADY_ACTIVE` and `SPELL_NOT_ACTIVE` drop the pending overlay **and trigger the silent `CharacterCubit.refreshCharacter()`** (no banner); `SPELL_NOT_KNOWN`, `MAX_ACTIVE_SPELLS_REACHED` and `NOT_FOUND` also trigger it after their banner (BE 04 §2 «refetch / riallinearsi»); `UNAUTHENTICATED` is silent.» |
| **F2** | D-09: sheet «slides in from the right over the journal page» | The Journal sheet animates `Positioned.top` from screen height to 0 with `right: 0` (`journal.dart:302-309`, tween at 411-419): it slides **up from the bottom**, anchored to the right edge. | D-09: «…built like `EquipmentInfoSheet` (rises from the bottom on the right side of the journal page, dismissed by a tap outside, same `AnimationController` in `journal.dart`)…» |
| **F3** | D-16: «a `SpellsCubit` (new, `tabs/journal/spellsCubit/`)» + code_context «the `BlocListener` for the banner sits where the Journal is built (or in `MainScreen`…)» | Offscreen `PageView` pages are disposed (Flutter `page_view.dart:975`, `cacheExtent 0`; `MainScreen` `PageView` at `main_screen.dart:108-115`), so a Journal-owned cubit/listener loses pending ops and banners on tab change. | D-16 add: «The `SpellsCubit` file lives in `tabs/journal/spellsCubit/` but is **provided by `AuthenticatedShell`** (like `TravelCubit`); the outcome listener (banner + `sync` from `CharacterCubit`) is mounted in **`MainScreen`** next to `TravelOutcomeListener`. The countdown ticker (`SpellRecoveryCubit`) is owned by the section and lives only while the Journal page is shown.» |
| **F4** | D-14: «ribbon extracted into a shared widget used by both cards» | A **third** copy exists in `EquipmentInfoSheet` (`equipment_info_sheet.dart:334-352`, used as the equip toggle). Zero duplication means it uses the shared widget too; the spell sheet reuses it as its toggle (D-09). | D-14 add: «…used by `EquipmentItemCard`, `EquipmentInfoSheet` and the spell card/sheet (all current copies are replaced).» |
| **F5** | D-07: «slots full (`activeSpells.length >= maxActiveSpells`)» / D-11 | Counting only the server list lets a second quick tap through while the first equip is pending (D-16 overlay). | D-07: «slots full = the **optimistic** active count (server `activeSpells` + pending equips − pending unequips) `>= maxActiveSpells`.» |
| **F6** | D-10: «Defensive only: never index past `activeSpells.length`» | `ActiveSpell.spell` is **nullable** on the wire (`schema.gql:15-18`, `spell: Spell`) and the current code asserts it (`journal.dart:186`); also `activeSpells.length` may exceed `maxActiveSpells` with legacy data. | D-10 add: «active entries with a null `spell` are skipped; if more spells are active than `maxActiveSpells`, the row still shows exactly `maxActiveSpells` boxes and the others remain bookmarked (and unequippable) in the list.» |
| **F7** | ROADMAP §Phase 8 success criterion 3 | Still says «a recovery indicator derived from `spell.recoveryTime`» (`ROADMAP.md:263`), superseded by the SPELL-05 amendment (`REQUIREMENTS.md:125-126`). | ROADMAP SC3: «Every known spell below its maximum shows remaining `usages` and a live «prossimo tra X» countdown from `status.spellStates[].recoveries` against server time (static «in recupero» without an instant); the slot card shows the usages only.» (first plan edits it) |
| F8 | D-17 lists `BAD_USER_INPUT`; Deferred Ideas defers «`BAD_USER_INPUT` … in every classifier» | Not a real conflict: the new classifier can map it at no cost. | Deferred item: «…in every **existing** classifier (the new `SpellEquipFailure` maps it in Phase 8, D-17)…» |
| F9 | D-13: «Row = `SpellCard` (unchanged…)» | The row card today shows a pencil counter with `maxUsages` (`journal.dart:204`); keeping it would contradict «Usi: 1/3». | D-13 add: «the row's card shows no usages counter (the compact line carries it); only the slot card keeps it (D-05).» |
| F10 | D-21 Boy Scout scope | Touched lines ask for: operation names `equipSpell`/`unequipSpell` violate naming.md/graphql.md (`character_mutations.dart:41-55`, graphql.md lists `EquipSpell`); `SpellRow`'s wrongly-typed unused callbacks (`spell_row.dart:20-25`); `spell_info.dart:52` analyzer warning; the pencil counter duplicated in `spell_card.dart:64-116` and `equipment_item_card.dart:121-173`. | D-21 add: «in scope as touched lines: rename the two spell operations to `EquipSpell`/`UnequipSpell` (registry keys too), fix `SpellRow`/`SpellInfo`; extracting the duplicated pencil counter is optional (planner's call, separate refactor commit).» |

No other D-xx is contradicted by the code.

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Flutter / Dart (fvm) | all | yes | 3.35.5 / 3.9.2 | — |
| Packages in pub cache (bloc, bloc_test, equatable, fake_async, mocktail, graphql_flutter) | build/tests | yes | see Standard Stack | — |
| Node + BE `node_modules/graphql` | `tool/schema_check` | yes (ran this session) | graphql-js from BE | — |
| BE repo `origin/develop` | schema | yes (`121601e`, no `spellStates`) | — | `git show origin/develop:…` (never checkout; BE working tree is on `feat/09.1-…` with a user-modified `.env.example`) |
| BE 9.1 merged on develop | last plan (fragment + schema check + E2E) | **no** (branch has docs only: `fd7689e`, `ee4d37a`) | — | All other plans proceed on fakes; the last plan waits |
| Running BE (Mongo + Redis) with 9.1 UAT data | device E2E | not verified from here (user-run) | — | none for E2E |
| Android device + `adb reverse tcp:3000` | E2E | user's Samsung (memory) | — | none |

**Missing with no fallback:** BE 9.1 merged + running BE + device for the final E2E (user-run, as in Phases 5-7).

## Validation Architecture

(`.planning/config.json` has no `workflow.nyquist_validation: false` → required.)

### Baseline (measured 2026-10-27 on `feat/08-spells-section-journal-tab`, clean tree)
- `flutter test` → **1778 tests, all passed** (~49 s wall).
- `flutter analyze` → **54 issues, 0 errors, 2 warnings** (`spell_info.dart:52` dead_null_aware_expression — fixed in this phase; `test/repository/services/auth/auth_token_service_contract_test.dart:40` unnecessary_cast — out of scope).
- `tool/schema_check` → **34/34 `OK`** against BE `origin/develop` (`121601e`). Probes: `EquipSpell`/`UnequipSpell` OK; `spellStates` selection FAIL on develop, OK on the proposed 9.1 SDL.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK 3.35.5) + bloc_test 10.0.0 + mocktail 1.0.5 + fake_async 1.3.3 |
| Config file | none; mocks `test/helpers/mocks.dart`, fixtures `test/helpers/fixtures/`, fakes `test/helpers/fakes/` (`FakeServerClockService`), `buildTestApp`, `useLandscapePhone`, `seedSvgCache`, `recordHaptics` |
| Quick run command | `flutter test test/models test/utils test/graphql test/repository test/tool test/shared test/screens/mainScreen test/screens/auth` (~25 s) |
| Full suite command | `flutter test` (~50 s, ≥ 1778 + new) + `flutter analyze` (≤ 53 issues, 0 errors) + `dart format --output=none --set-exit-if-changed <each new/clean touched file>` + schema check (last plan) |

### Phase Requirements → Test Map
| Req ID | Behavior | Type | Automated command | File exists? |
|--------|----------|------|-------------------|--------------|
| SPELL-05 | `SpellState.fromJson/toJson/tryFromJson`, ISO `Z` → UTC, sorted recoveries, malformed → null, Equatable | unit | `flutter test test/models/spell/spell_state_test.dart` | Wave 0 |
| SPELL-05 | `CharacterStatus.spellStates`: absent → null, list parsed, malformed entry skipped, `toJson` round trip, props, `copyWith` keeps it | unit | `flutter test test/models/character/character_status_test.dart` | exists (extend) |
| SPELL-01/02/07 | `Spellbook`: visibility (D-12), slot count 0/1/4, slots never past the list, null `spell` skipped, extra actives, BE order kept, optimistic active list (pending equip appended, pending unequip removed), fallback table rows (all 7 cases) | unit | `flutter test test/models/spell/spellbook_test.dart` | Wave 0 |
| SPELL-03/04 | Toggle intent: equip / unequip / blockedSlotsFull (optimistic count) / blockedNoSlots / unequip allowed with 0 slots / ignoredPending | unit | `flutter test test/models/spell/spellbook_test.dart` | Wave 0 |
| SPELL-02/05 | Strings: summary line (full, partial, arriving, legacy «in recupero», power 0, null recoveryTime), «meno di 1 min», ceil minutes, hours/days | unit | `flutter test test/models/spell/spell_lines_test.dart test/utils/game_duration_format_test.dart` | Wave 0 (formatter test moved) |
| SPELL-05 | `spellRecoveryStatusOf(input, serverNow)` for Full / Countdown / Arriving / RecoveringUnknown | unit | `flutter test test/models/spell/spell_recovery_status_test.dart` | Wave 0 |
| SPELL-03/04 | `EquipSpellRequest.toJson` has `id`, `spellId`, never `usages` | unit | `flutter test test/models/request/equip_spell_request_test.dart` | Wave 0 |
| SPELL-03/04 | Documents `EquipSpell`/`UnequipSpell`: single named operation, `$request: EquipSpellRequest!`, selection `response successful`; registry keys | unit | `flutter test test/graphql/spell_documents_test.dart test/tool/schema_check_documents_test.dart` | Wave 0 / exists |
| SPELL-03/04 | `KlimmeckGraphQl.equipSpell/unequipSpell`: operation name, variables `{request:{id,spellId}}`, `successful` true/false, malformed → `FormatException`, code preserved | unit | `flutter test test/repository/services/graphql/graphql_spells_test.dart` | Wave 0 |
| SPELL-06 | `spellEquipFailureFrom`: every code incl. `BAD_USER_INPUT`, link error → connection, no code → unknown, message ignored | unit | `flutter test test/repository/spell_equip_failure_test.dart` | Wave 0 |
| SPELL-06 | `SpellsRepository`: never leaks `OperationException`; 15 s → `timedOut` (fake_async); `false` → `declined` | unit | `flutter test test/repository/spells_repository_test.dart` | Wave 0 |
| SPELL-06 | `SpellsCubit`: pending added on toggle; tap on pending ignored; blocked emits outcome without repo call; `sync` clears matched equip/unequip; success then sync clears; success after matching snapshot clears at once; failure clears + outcome; 15 s in flight → timedOut + late answer ignored; 15 s after success → silent clear; close cancels timers | cubit (fake_async) | `flutter test test/screens/mainScreen/tabs/journal/spellsCubit` | Wave 0 |
| SPELL-06 | Notice catalogue: titles per operation, blocked copies, `alreadyActive`/`notActive`/`unauthenticated` → null | unit | `flutter test test/screens/mainScreen/tabs/journal/spellsCubit/spell_notice_test.dart` | Wave 0 |
| SPELL-06 | `SpellOutcomeListener`: forwards `CharacterLoaded` to `sync`; publishes once with the dedup key; stale codes call `refreshCharacter` (F1); no banner for silent codes | widget | `flutter test test/screens/mainScreen/components/spell_outcome_listener_test.dart` | Wave 0 |
| SPELL-06 | Shell provides `SpellsCubit`; `MainScreen` mounts the listener | widget | `flutter test test/screens/auth/authenticated_shell_test.dart test/screens/mainScreen/main_screen_test.dart` | exist (extend) |
| SPELL-05 | `SpellRecoveryCubit`: ticks only while a countdown exists, label changes at minute boundaries (dedup), Arriving after the instant, recompute on `offsetChanges`, stops when none, close cancels | cubit (fake_async) | `flutter test test/screens/mainScreen/tabs/journal/spellRecoveryCubit` | Wave 0 |
| SPELL-01/02/07 | Section widget: absent without spells and slots; slot row with exactly N boxes; zero-slot neutral line; «Non hai ancora imparato nessuna magia»; compact lines; bookmark marked on active rows in place; pending opacity; slot card counter from state/fallback | widget | `flutter test test/screens/mainScreen/tabs/journal/sections/spells_section_test.dart` | Wave 0 |
| SPELL-03/04 | Interactions: tap inactive → `toggle` + lightImpact; tap active row / slot card → unequip; blocked → selectionClick + shake, no repo call; tap on pending ignored; long-press row/slot → `onShowDetails` | widget | same file (+ `recordHaptics`) | Wave 0 |
| SPELL-04 | `SpellInfoSheet`: all D-09 fields, ribbon toggle calls `toggle`; Journal hosts the sheet, opens on long-press, closes on outside tap | widget | `flutter test test/shared/components/popup/spell_info_sheet_test.dart test/screens/mainScreen/tabs/journal/journal_spells_test.dart` | Wave 0 |
| SPELL-01 (D-14) | `BookmarkRibbon` marked/unmarked offsets, onTap; `EquipmentItemCard`/`EquipmentInfoSheet` still show the ribbon | widget | `flutter test test/shared/components/bookmark_ribbon_test.dart test/shared/components/cards` | Wave 0 |
| SPELL-05 (gated) | Fragment selects `spellStates { usages recoveries spell { id } }`; `characterUpdated`/`character` still parse | unit | `flutter test test/graphql/character_fragment_test.dart` | exists (extend, last plan) |
| all | Every document valid vs BE `origin/develop` after the 9.1 merge | scripted | commands below | — |
| E2E | Device checklist (below) | manual-only | UAT recipe | — |

### Schema check (last plan; same as Phases 6-7)
```bash
cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide
git -C /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE fetch origin develop
SCRATCH=$(mktemp -d)
git -C /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE show origin/develop:src/schema.gql > "$SCRATCH/schema.gql"
grep -n "spellStates" "$SCRATCH/schema.gql"   # must exist before the fragment change is committed
dart run tool/schema_check/dump_documents.dart "$SCRATCH/docs"
NODE_PATH=/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/node_modules \
  node tool/schema_check/validate_documents.js "$SCRATCH/schema.gql" "$SCRATCH/docs"
```
Expected: **34 `OK`** (no new operation; `EquipSpell`/`UnequipSpell` renamed; `character` and `characterUpdated` change in place).

### Manual-only verifications (device, BE 9.1 UAT data — BE handoff §6 point 5 of the FE notes)
| Behavior | Requirement | Why manual | Steps |
|---|---|---|---|
| Countdown from real `recoveries` (~2 min and ~30 min) on the active spell; «in arrivo…» then the use returns within the sweep (≤ 60 s) | SPELL-05 | real BE clock, Bull job/sweep | Journal open on the `mage` UAT character; watch the first instant pass |
| Unequip a recovering spell: countdown keeps running in its row; re-equip: usages unchanged (D-01 user rule) | SPELL-05 | needs 9.1 semantics | tap active row, wait, tap again |
| Equip/unequip optimistic look then full on `characterUpdated` | SPELL-06 | real subscription latency | tap rows/slot cards |
| Full slots → resist + banner, no network call; zero-slot character → neutral line + «Nessuno slot disponibile» | SPELL-03, SPELL-07 | real data | sub-mage UAT character |
| Race rejection (`MAX_ACTIVE_SPELLS_REACHED` / `SPELL_ALREADY_ACTIVE` from a second client) → rollback + banner / silent realign | SPELL-06 | needs a second client | GraphiQL equip on the same character, then tap |
| Phone clock moved: countdown unchanged | SPELL-05 | system clock | settings → time |
| Long-press sheet and its toggle | SPELL-04 | gesture feel | — |
| Slot unlock: GM raises xp/title → new box appears live | SPELL-07 | BE data change | innkeeper/DB edit |

### Sampling Rate
- **Per task commit:** the task's test file(s) + `flutter analyze <touched files>` + format check on new/clean files only.
- **Per wave merge:** quick run command.
- **Phase gate:** full `flutter test` green (≥ 1778 + new), `flutter analyze` ≤ 53 / 0 errors, schema check 34/34 against BE `origin/develop` with `spellStates`, device E2E recorded in the phase summary and in the BE 9.1 UAT file.

### Wave 0 Gaps
- [ ] `test/helpers/fixtures/spell_fixtures.dart`: `spellJson`, `activeSpellJson`, `spellStateJson`, `spellbookCharacterJson` (with and without `spellStates`; UTC ISO instants).
- [ ] `test/helpers/mocks.dart`: `MockSpellsRepository`, `MockSpellsCubit`, `MockSpellRecoveryCubit` (registerFallbackValue for `Character` where `toggle`/`sync` are verified).
- [ ] A section harness helper (fixed-width `SingleChildScrollView` + providers: `CharacterCubit`, `SpellsCubit`, `RepositoryProvider<ServerClockService>.value(FakeServerClockService)`) and `seedSvgCache` ids for the spell fixtures.
- [ ] Move `test/models/travel/travel_time_format_test.dart`'s `formatTravelDuration` group to `test/utils/game_duration_format_test.dart`.
- [ ] `main_screen_test.dart` provider for `MockSpellsCubit` (Pitfall 9) in the plan that mounts the listener.

No framework install needed.

## Security Domain

`security_enforcement` not disabled → included.

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes (inherited) | authenticated client + silent refresh; `UNAUTHENTICATED` → no banner, the session flow acts |
| V3 Session Management | yes (inherited) | `SpellsCubit` lives under `AuthenticatedShell` (closed at logout/character switch); `SafeEmit` + tokens drop late answers |
| V4 Access Control | yes | BE `@OwnsCharacter` on equip/unequip (`FORBIDDEN`); FE sends only `CharacterLoaded.character.id` and a `spellId` taken from loaded `status.spells`, never user-typed |
| V5 Input Validation | yes | typed variables (`$request: EquipSpellRequest!`), no interpolation into documents; tolerant parsing of `spellStates` at the model boundary (malformed entry skipped, status survives) |
| V7 Error Handling and Logging | yes | copy by `extensions.code` only, fixed Italian catalogue, no server text; no payload logging |
| V6 Cryptography | no | — |

| Threat | STRIDE | Mitigation |
|---|---|---|
| Client forges usages/slots | Tampering | FE never writes usages; slots and recoveries only from the BE; the client block is UX only, BE is the judge |
| Device clock manipulation to "recover early" | Tampering | display-only countdown on the server offset; BE restores uses by its own clock |
| Equip on another character | Elevation | id from session; BE `FORBIDDEN` |
| Double tap flooding | Tampering / DoS | one pending op per spell; BE conditional writes (`SPELL_ALREADY_ACTIVE`) |
| Error text leak | Information disclosure | fixed catalogue, never `message` |

## Sources

### Primary (HIGH confidence)
- FE code read this session (file:line cited above): `journal.dart`, `spell_card.dart`, `spell_row.dart`, `spell_info.dart`, `equipment_item_card.dart`, `equipment_info_sheet.dart`, `item_row.dart`, `dropdown.dart`, `section.dart`, `animated_pencil_text.dart`, models (`spell`, `active_spell`, `character_status`, `character_assets`, `character`, `active_travel`, `energy_type`, `use_type`, `travel_time_format`), `character_fragment.dart`, `spell_fragment.dart`, `character_mutations.dart`, `graphql.dart`, `travel_failure.dart`, `quest_acceptance_failure.dart`, `graphql_error_code.dart`, `travel_repository.dart`, `travel_notice.dart`, `travel_outcome_listener.dart`, `quest_abandon_outcome_listener.dart`, `in_app_notifications_cubit.dart`, `server_clock_service.dart`, `travel_progress_cubit.dart`, `world_map.dart`, `character_cubit.dart`, `authenticated_shell.dart`, `main_screen.dart`, `tearable_paper.dart`, `safe_emit.dart`, `tool/schema_check/*`, `test/helpers/*`, `test/tool/schema_check_documents_test.dart`.
- Flutter SDK 3.35.5 `packages/flutter/lib/src/widgets/page_view.dart:975`; `equatable-2.0.7/lib/src/equatable_utils.dart`.
- BE (read-only): `origin/develop:src/schema.gql` (`121601e`); `.planning/phases/09.1-spell-state-and-recovery-contract/09.1-CONTEXT.md`; `.planning/phases/04-integrita-economica-atomics/BACKEND-NOTES.md` §0, §2, §4, §5, §9, §10; `origin/develop:src/models/character/active-spell-slots.ts`, `src/models/spell.model.ts`, `test/fixtures/spell.fixture.ts`.
- Measured: `flutter test` (1778 passed), `flutter analyze` (54 / 0 errors / 2 warnings), per-file `dart format --set-exit-if-changed`, `tool/schema_check` (34/34 + 3 probes on develop and on a patched 9.1 copy), DateTime equality probe, two throwaway widget probes (ribbon in Stack, nested gestures) — deleted.

### Secondary (MEDIUM)
- 9.1 SDL and semantics as written in the BE CONTEXT (not generated yet).

### Tertiary (LOW)
- Unit of `requiredLearnTime` (A3).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — lockfile, no new dependency.
- Architecture: HIGH — every piece mirrors a Phase 6/7 slice read in code; the overlay cubit is new but fully fake-testable.
- Pitfalls: HIGH — measured/probed (page disposal, DateTime equality, gestures, format/analyzer baselines).
- Contract: MEDIUM until the BE 9.1 schema is generated and merged.

**Research date:** 2026-10-27
**Valid until:** 2026-11-10 (re-run the schema check and re-read the BE 9.1 handoff before the last plan)
