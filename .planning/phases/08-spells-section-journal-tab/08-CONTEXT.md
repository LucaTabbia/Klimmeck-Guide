# Phase 8: Spells Section (Journal Tab) - Context

**Gathered:** 2026-10-27
**Status:** Ready for planning (**no UI phase**, same rule as Phases 6 and 7: every visual Claude builds is provisional and will be reworked by the user). The final, schema-gated plan waits for the BE companion Phase 9.1 (D-03); everything else can start now.
**Amended:** 2026-10-27 after the research (flags F1–F10 of `08-RESEARCH.md`): D-07, D-09, D-10, D-13, D-14, D-16, D-17, D-21 and the deferred `BAD_USER_INPUT` item. This CONTEXT is authoritative over the RESEARCH where they differ.

<domain>
## Phase Boundary

The partial Spells section of the Journal tab (`lib/screens/mainScreen/tabs/journal/journal.dart`, `_buildSpellsSection`) becomes complete: the player sees the spells the character knows with name, description, max usages, recovery time and element/power; taps a known spell to equip it into one of the `maxActiveSpells` backend-driven slots and taps again (row or slot card) to disequip it; sees, for every known spell, the remaining usages and a live countdown to the next recovered use; long-presses a spell to open a detail sheet. Equip/disequip is optimistic with a visible "pending" look, rolled back on rejection with the in-app banner. The recovery data comes from a new backend contract (BE Phase 9.1, proposed in `BACKEND-NOTES.md` of this phase): a per-spell state with `usages` and `recoveries` that outlives equip and disequip.

Out of scope: casting spells from the app (`useSpell` is called only server-side by the combat outcomes of BE Phase 9), learning spells (backend outcome of `study` quests), slot-unlock rules (backend, SPELL-07), the combat result sheet (Phase 9), any change to the other Journal sections beyond what the extraction of the spells section touches.

</domain>

<decisions>
## Implementation Decisions

### Recovery model and backend companion (SPELL-05, SPELL-07)
- **D-01 (user decision 2026-10-27):** a **real countdown**, not a static indicator. It needs a BE companion phase, **BE Phase 9.1 "Spell State and Recovery Contract"** (inserted today in the BE roadmap, branch `feat/09.1-spell-state-and-recovery-contract` off BE `develop`): a per-spell state with `usages` and `recoveries: [DateTime!]!` that persists **regardless of the equip state**. User, verbatim: *«Il recupero vale sempre, che la magia venga equipaggiata o disequipaggiata. Il timer di recupero non si interrompe mai. Se io disequipaggio la magia e 10 secondi dopo dovrebbe recuperare un utilizzo, 10 secondi dopo recupererà un utilizzo».* Consequences: equipping no longer resets the usages (BE Phase 4 D-11 is superseded by 9.1), the unequip → equip shortcut disappears, the FE needs no rule of its own.
- **D-02:** Proposed contract (fixed by the BE 9.1 CONTEXT; `src/schema.gql` wins once generated): `type SpellState { spell: Spell!, usages: Int!, recoveries: [DateTime!]! }` and `CharacterStatus.spellStates: [SpellState!]!`, one entry per known spell, same ids as `status.spells`. `recoveries` is ascending: the first instant is the next recovered use, `recoveries.length == maxUsages - usages` once every job is tracked. `ActiveSpell { spell, usages }` stays on the wire for the slot order (`usages` documented as equal to the state). `Spell.recoveryTime` is **milliseconds** (the BE uses it directly as the Bull delay). Additive only. The FE reads usages and recoveries from `spellStates` for both the list row and the slot card, joined by spell id.
- **D-03:** The FE develops against the proposed contract with fakes/recorded `QueryResult`s (pattern of Phases 3–7); `CharacterStatus.fromJson` treats `spellStates` as optional until the schema lands (absent → usages from `ActiveSpell`/catalog and the static «in recupero» fallback of D-04). The plan that adds `spellStates { usages recoveries spell { id } }` to `CharacterFragment` runs **after** the BE 9.1 PR is merged on BE `develop` (or is the last plan), and the final plan runs `tool/schema_check` against `git -C <BE> show origin/develop:src/schema.gql` plus the manual E2E on device with the UAT data of the BE handoff. BE PR before FE PR.
- **D-04:** Countdown anchoring: `ServerClockService.now()` (Phase 7) against the first `recoveries` instant; label «prossimo tra X» using the Phase 7 duration formatter (rounds up to minutes, so a positive remainder never reads 0; under one minute Claude chooses between «meno di 1 min» and seconds). When the instant is past but `characterUpdated` has not yet delivered the restored use the label becomes an «in arrivo…»-style wording (Claude's discretion, mirror of Phase 7 D-10). Tick cadence at Claude's discretion (minute granularity is enough; reuse the ticker approach of `TravelProgressCubit` if it fits). `usages == maxUsages` → nothing about recovery is shown. `recoveries` empty but `usages < maxUsages` (legacy jobs enqueued before the BE 9.1 deploy) → static «in recupero» without a time.
- **D-05 (user decision):** the countdown lives **in the list row** («Usi: 1/3 · prossimo tra 12 min») for every known spell whose usages are below the maximum, active or not. The `SpellCard` in the slot keeps only the usages counter it already has (`AnimatedPencilText`); no time on the card.

### Gestures (SPELL-03, SPELL-04)
- **D-06 (user decision):** **tap toggles.** Row of a known spell: inactive → `equipSpell`, active → `unequipSpell`. Card in a slot → `unequipSpell`. Request `EquipSpellRequest { id: <characterId>, spellId }`; the deprecated `usages` input field is **never sent** (BE Phase 4 handoff §0 item 4).
- **D-07 (user decision):** slots full (the **optimistic** active count — server `activeSpells` plus pending equips minus pending unequips — `>= maxActiveSpells`; amended after the research, F5, so two quick taps cannot both reach the BE) and tap on an inactive spell: the client does **not** call the BE; the card resists (short spring/shake at Claude's discretion), `HapticFeedback.selectionClick()`, banner «Slot pieni: disequipaggia una magia». The BE stays the judge: a `MAX_ACTIVE_SPELLS_REACHED` from a race → rollback + banner (D-17). Mirror of Phase 6 D-11.
- **D-08:** Haptics on an equip/disequip tap: `HapticFeedback.lightImpact()` at the tap, nothing at confirmation; exact pattern at Claude's discretion (Phase 6 D-06 precedent).
- **D-09 (user decision):** **long-press** on a row or on a slot card opens a **detail sheet** built like `EquipmentInfoSheet` (rises from the bottom on the right side of the journal page, dismissed by a tap outside, same `AnimationController` pattern as `journal.dart`; wording amended after the research, F2) with the existing `SpellInfo` extended: name, description, element + power, use type, max usages, recovery time, learn requirements (`minXpToLearn`, `requiredLearnTime`), current usages and next recovery. The sheet offers the same equip/disequip toggle as the row (affordance at Claude's discretion, provisional).

### Slots and empty states (SPELL-07)
- **D-10:** The slot row renders exactly `maxActiveSpells` boxes (existing bordered container) filled with `activeSpells[i]` cards; a `maxActiveSpells` change delivered by `characterUpdated` re-renders the row; the FE never computes thresholds nor titles (SPELL-07). Defensive only: never index past `activeSpells.length`. Amended after the research (F6): active entries with a null `spell` (`ActiveSpell.spell` is nullable on the wire) are skipped instead of asserted; if more spells are active than `maxActiveSpells` (legacy data), the row still shows exactly `maxActiveSpells` boxes and the extra ones stay bookmarked in the list (tap = unequip).
- **D-11 (user decision):** `maxActiveSpells == 0` (titles below `mage`): **no slot row**, one neutral copy line in its place («Nessuno slot per le magie: cresci di rango»), no numbers, no title names; the known-spells list stays visible with its usages/countdown; a tap to equip is blocked like D-07 with the banner «Nessuno slot disponibile».
- **D-12 (user decision):** no known spells (`status.spells` empty): **the Spells section is not built at all**. It appears as soon as `status.spells` has one entry or `maxActiveSpells > 0` (then: slot row and the line «Non hai ancora imparato nessuna magia»).

### List content (SPELL-01, SPELL-02)
- **D-13:** Row = `SpellCard` (unchanged: use-type icon, element icon, name, power; **no usages counter on the row card** — the compact line carries it and only the slot card keeps the pencil counter, D-05; amended after the research, F9) + description + **one compact line** «Usi: 3 · Recupero: 2 h · Danno: fuoco 12» (`maxUsages`, `recoveryTime` formatted from ms with the shared duration formatter, Italian label of `energyDamage.type` + `power`); for a spell with usages below the maximum the first item becomes «Usi: 1/3 · prossimo tra 12 min» (D-05). Labels and separators provisional.
- **D-14 (user decision, verbatim):** *«Sono marcate con il segnalibro come accade per gli oggetti equipaggiati e restano nella lista al loro posto».* Active spells keep their position in the list and carry the **red bookmark** (`CloudinaryAssets.bookmarkRed`) exactly as `EquipmentItemCard` does for equipped items (`AnimatedPositioned` ribbon). The ribbon is extracted into a shared widget used by `EquipmentItemCard`, `EquipmentInfoSheet` (a third copy lives there today, as its equip toggle) and the spell card/sheet — every current copy replaced — or `SpellCard` gets an `isSelected` built on it: Claude's choice, **zero duplication** of the ribbon code (amended after the research, F4).
- **D-15:** List order = `status.spells` order as delivered by the BE; no sorting, no grouping.

### Optimistic UI and errors (SPELL-06)
- **D-16 (user decision):** optimistic **with a visible pending look**: the card enters/leaves the slot at once with an attenuated look («inchiostro ancora umido»: opacity or ink-wash at Claude's discretion) until `characterUpdated` reflects the change, then full. Implementation: a **`SpellsCubit`** (new, `tabs/journal/spellsCubit/`) keeps the pending operations keyed by spell id as an **overlay** on the `CharacterCubit` state; an operation clears when the subscription state matches, on failure, or at a **15 s timeout** (Phase 6 D-03 precedent). One pending operation per spell; a tap on a pending spell is ignored. The UI never builds state from `CommonResponse`. Amended after the research (F3): the `SpellsCubit` file lives in `tabs/journal/spellsCubit/` but it is **provided by `AuthenticatedShell`** (like `TravelCubit`), because the `MainScreen` `PageView` disposes offscreen tabs and a Journal-owned cubit would lose pending operations and banners on a tab change; the outcome listener (banner plus sync with `CharacterCubit`) is mounted in **`MainScreen`** next to `TravelOutcomeListener`; the countdown ticker is owned by the section and lives only while the Journal page is shown.
- **D-17:** Failures: the Repository maps `OperationException` into a **`SpellEquipFailure`** (enum + classifier, pattern of `travel_failure.dart`/`quest_acceptance_failure.dart`) by `extensions.code`: `SPELL_NOT_KNOWN`, `SPELL_ALREADY_ACTIVE`, `MAX_ACTIVE_SPELLS_REACHED`, `SPELL_NOT_ACTIVE`, `NOT_FOUND`, `FORBIDDEN`, `UNAUTHENTICATED`, `BAD_USER_INPUT` (arrives with BE Phase 10), plus `connection`, `timedOut`, `declined` (`successful: false`), `unknown`. Banner through `InAppNotificationsCubit.publishNotice` from a `BlocListener` (Phase 6 D-20 C1, Phase 7 `TravelOutcomeListener`). `SPELL_ALREADY_ACTIVE` and `SPELL_NOT_ACTIVE` drop the pending overlay **and trigger the silent `CharacterCubit.refreshCharacter()`** with no banner (a rejection writes and emits nothing, so the client view is stale — BE Phase 4 §0 item 7 and §2 «riallinearsi»; amended after the research, F1); `SPELL_NOT_KNOWN`, `MAX_ACTIVE_SPELLS_REACHED` and `NOT_FOUND` trigger the same silent refresh after their banner; `UNAUTHENTICATED` is silent; everything else → banner with Italian domain copy (provisional), titles «Magia non equipaggiata» / «Magia non tolta».
- **D-18:** Rollback = the card springs back to where it was (Claude's discretion, Phase 6 tear spring-back precedent) while the banner appears.

### Process and quality
- **D-19:** **No UI phase, no UI-SPEC** (Phase 6 D-19 and Phase 7 carried forward): everything visual is provisional, token-based (`kg_theme.dart`), no new assets, simple to restyle.
- **D-20:** **TDD red → green → refactor:** unit tests for the failure classifier, the pending-overlay cubit (`bloc_test`), countdown derivation and formatting against a fixed server clock, the join of `spellStates` with `status.spells`/`activeSpells`, slot derivation and the empty-state rules; widget tests for the section (slot row, list line, bookmark, pending look, zero-slot copy, section absent without spells), the detail sheet and the long-press; `flutter analyze` with no new issues; `dart format` only on touched files (Phase 11 D-38); schema check in the final plan (D-03).
- **D-21:** **Boy Scout within scope:** the spells section leaves `journal.dart` for `tabs/journal/sections/` (the directory exists and is empty) and the `!` assertions it carries become null-safe reads; nothing else in the Journal is refactored unless a touched line asks for it. Amended after the research (F10), touched lines in scope: the two spell operations are renamed `EquipSpell`/`UnequipSpell` (naming.md and graphql.md; the `tool/schema_check` registry keys too), the unused wrongly-typed callbacks of `SpellRow` and the `spell_info.dart` analyzer warning are fixed; extracting the pencil counter duplicated between `SpellCard` and `EquipmentItemCard` is optional (planner's call, separate refactor commit).

### Claude's Discretion
- Ticker mechanism and sub-minute wording of the countdown (D-04); haptic pattern (D-08); pending look, resist/shake and spring-back geometry (D-07, D-16, D-18); detail sheet layout and the toggle affordance inside it (D-09); where the shared duration formatter and the bookmark widget live and their names (D-13, D-14); how the models join `spellStates` with `status.spells`/`activeSpells` (D-02); banner copy per code (D-17); whether the mutations live in `KlimmeckGraphQl` or in a dedicated repository (`docs/rules/architecture.md` decides the layer, not the name).

</decisions>

<specifics>
## Specific Ideas

- Every user answer of 2026-10-27 is recorded in `08-DISCUSSION-LOG.md`; the two verbatim ones are quoted in D-01 and D-14.
- The section title stays «Magie imparate» (existing `Dropdown`) unless restyled later.
- «Nella riga della lista» for the countdown and «Sì, long-press apre il foglio» for the detail are the user's picks against the recommended defaults: keep them even if the planner finds the card or the row "simpler".

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/ROADMAP.md` §"Phase 8: Spells Section (Journal Tab)" — goal, success criteria, SPELL-01..07, BE prerequisite (added today).
- `.planning/REQUIREMENTS.md` §"Spells (Journal Tab)" — SPELL-01..07 (SPELL-03/04/05 amended today).
- `.planning/phases/08-spells-section-journal-tab/BACKEND-NOTES.md` — the contract proposed to BE Phase 9.1, the questions for the BE, what the FE consumes.

### Backend contract
- `Klimmeck-Guide-BE/.planning/phases/09.1-spell-state-and-recovery-contract/09.1-CONTEXT.md` — the BE decisions that fix the contract (written today from this discuss); its `BACKEND-NOTES.md` once the phase ships; `Klimmeck-Guide-BE/src/schema.gql` at `origin/develop` is the only source for the schema check.
- `Klimmeck-Guide-BE/.planning/phases/04-integrita-economica-atomics/BACKEND-NOTES.md` — §0 item 4 (`usages` ignored), §2 (codes `SPELL_*`, `NOT_FOUND`, `FORBIDDEN`), §4 (equip/unequip semantics, slot table), §5 (`useSpell` and recovery).
- `Klimmeck-Guide-BE/.planning/phases/03-autorizzazione-ownership-ruoli-audit/BACKEND-NOTES.md` — ownership on `equipSpell`/`unequipSpell`.
- `Klimmeck-Guide-BE/.planning/phases/09-combat-result-admin-outcomes/BACKEND-NOTES.md` — §7 (progression, `spellLearned`), §5/§8 (spells used by the outcomes).

### Prior FE decisions carried forward
- `.planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md` — D-03 (optimistic + rollback), D-04 (banner by code), D-06 (haptics), D-11 (the client blocks what it can tell, the BE is the judge), D-19 (no UI phase), D-20 C1 (`publishNotice`).
- `.planning/phases/07-travel/07-CONTEXT.md` — server clock, duration formatting, `TravelOutcomeListener`/`travel_notice.dart` pattern, no UI phase.
- `.planning/phases/05-notifications-infrastructure/05-CONTEXT.md` — D-17 (the in-app banner).
- `.planning/phases/03-real-time-sync-foundation/03-CONTEXT.md` — D-05 (fragment-only schema changes), D-19 (whole-Character emissions).

### Rules
- `docs/rules/architecture.md`, `docs/rules/state-management.md`, `docs/rules/graphql.md`, `docs/rules/ui-ux.md` (immersion, no blocking loading, error state), `docs/rules/testing.md`, `docs/rules/naming.md`, `docs/rules/assets.md`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/screens/mainScreen/tabs/journal/journal.dart` `_buildSpellsSection`: the slot row (`maxActiveSpells` bordered boxes with `SpellCard`) and the `SpellRow` list are already laid out; no handlers, no tests.
- `lib/shared/components/cards/spell_card.dart` (`SpellCard`: icons, name, power, animated usages counter), `lib/shared/components/spell_row.dart` (card + description), `lib/shared/components/spell_info.dart` (`SpellInfo`, unused today).
- `lib/shared/components/cards/equipment_item_card.dart` — red bookmark ribbon (`CloudinaryAssets.bookmarkRed`, `AnimatedPositioned`) to share (D-14); `lib/shared/components/popup/equipment_info_sheet.dart` plus the `AnimationController` in `journal.dart` — the sliding sheet pattern (D-09).
- `lib/graphql/mutations/character_mutations.dart` — `equipSpell`/`unequipSpell` documents already exist; `lib/graphql/fragments/spell_fragment.dart`, `character_fragment.dart` (`maxActiveSpells`, `activeSpells { usages spell {…} }`).
- `lib/models/spell.dart`, `lib/models/active_spell.dart`, `lib/models/character/character_status.dart`, `character_assets.dart` — models to extend with `spellStates`.
- `lib/repository/services/time/server_clock_service.dart` (`now()` with the server offset), `lib/models/travel/travel_time_format.dart` (`formatTravelDuration`).
- `lib/repository/travel_failure.dart`, `lib/screens/mainScreen/travelCubit/travel_notice.dart`, `lib/screens/mainScreen/components/travel_outcome_listener.dart`, `lib/repository/services/graphql/graphql_error_code.dart` — failure classifier + notice + listener pattern.
- `lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart` — `publishNotice`.
- `lib/shared/components/dropdown.dart`, `section.dart` — Journal section chrome; `lib/shared/components/tear/tearable_paper.dart` — haptics usage.

### Established Patterns
- Cubit per feature with `SafeEmit`; the Repository maps exceptions to domain failures; the UI reads `CharacterCubit` through `BlocSelector`; no state from `CommonResponse`; fragments change without touching documents (Phase 3 D-05).
- Schema-gated final plan with `tool/schema_check` against BE `origin/develop`; the BE PR merges first.
- Everything visual provisional; tokens from `kg_theme.dart`; `dart format` only on touched files.

### Integration Points
- `journal.dart` → new `tabs/journal/sections/spells_section.dart` (plus components) and `tabs/journal/spellsCubit/`; `KlimmeckGraphQl` (or a dedicated repository) gains `equipSpell`/`unequipSpell`; the `BlocListener` for the banner sits where the Journal is built (or in `MainScreen` like the travel listener).

</code_context>

<deferred>
## Deferred Ideas

- FE mapping of `BAD_USER_INPUT` (BE Phase 10) in every **existing** classifier (the new `SpellEquipFailure` maps it already in Phase 8, D-17) and of `IMAGE_REJECTED`/`IMAGE_MODERATION_UNAVAILABLE` in character creation (BE Phase 10 image moderation) — quick task or Phase 12, after the BE Phase 10 PR.
- «Spells used» lines in the combat result sheet — Phase 9 (depends on this phase).
- Spell learning UI and slot unlock — backend only (PROJECT.md out of scope).
- `JournalCubit` cleanup (`print`, unused `getData`) — Boy Scout when touched, otherwise backlog.

</deferred>

---

*Phase: 08-spells-section-journal-tab*
*Context gathered: 2026-10-27*

## Extension after the device UAT (2026-10-27, user request)

Requested by the user right after the 12/12 device UAT of plan 08-12, to land in the same PR: two extra plans (08-13 spells and shop chips, 08-14 items) extend the phase on `feat/08-spells-section-journal-tab`, sequential (08-14 uses the helper of 08-13). D-19, D-20 and D-21 carry over (no UI phase, TDD red → green → refactor, Boy Scout within scope).

- **D-22 (user decision, verbatim):** *«La lista delle magie dovrebbe avere un sistema di filtri come quello del negozio, basato in questo caso sullo useType.»* → the known-spell list of the Spells section reuses the shop's `ItemsFilter<T>` (`lib/screens/mainScreen/tabs/shop/components/items_filter.dart`: icon chips + «Tutti», single selection) over `UseType`, placed between the slot row and the known rows; it filters the known rows only (the slot row never changes); the selection is local view state like in the shop (nothing goes to the BE, nothing is persisted).
- **D-23 (user decision):** chips show **only the types present in the list** (computed from the known spells / owned items), so a chip never yields an empty list; **the shop filters change the same way** (`ShopModal`: `EquipType` chips from the equipments on sale or owned, `EffectType` chips from the items) — groundwork for an upcoming phase. `ItemsFilter` stays generic; the "present values" computation is a pure helper with unit tests, shared by Journal and shop, that keeps the enum order and drops nulls (an item with a null type is listed only under «Tutti»). If the selected type disappears from the list (e.g. the spell is forgotten, the item sold), the selection falls back to «Tutti».
- **D-24 (user decision):** the compact spell line replaces the word «Danno» with the **useType label**: «Attacco: Fuoco 12» (use-type label, colon, energy label, power; power null or 0 → «Attacco: Fuoco»); with a null `useType` the line falls back to today's «Danno: Fuoco 12». It applies to `spellDamageLabel` (row line and detail sheet). **The detail sheet keeps the «Uso: Attacco» line with its icon as it is.**
- **D-25 (user decision):** `EffectType` gets an Italian `label` like `UseType`: `heal` → «Cura», `hunger` → «Sazietà», `munition` → «Danno» (the real effect of ammunition), `exploration` → «Esplorazione», `none` → «Nessun effetto».
- **D-26 (user decision):** loot item rows get a compact line under the description built like the spell line: «<effect label>: <power>» («Cura: 12»; power null or 0 → «Cura»; null effect → no line). It lives in the shared `ItemRow` (`lib/shared/components/item_row.dart`), so the Journal «Oggetti» section and the shop rows share one presentation; equipment rows are untouched.
- **D-27 (user decision):** the Journal «Oggetti» section (`journal.dart`, `_buildOwnedItemsSection`) gets the same `ItemsFilter` over `EffectType` above its rows, with the D-23 rules.
- **D-28 (Claude's discretion):** copy for the strings: an empty filtered list cannot happen under D-23, so no empty copy; the item line strings live in a new `lib/utils/item_lines.dart` beside `spell_lines.dart`; the spells filter lives in `SpellbookContent`/`SpellsSection` state (the section is already a `StatefulWidget`), the items filter in `_JournalState` like the equipment slot filter; the shop keeps its `setState` fields. Requirements: SPELL-08 (use-type filter), SPELL-09 (use-type line), ITEM-01 (effect labels + row line), ITEM-02 (effect filter in the Journal), SHOP-01 (shop chips limited to the present types), added to REQUIREMENTS.md by the orchestrator with the ROADMAP plan list (14 plans).
