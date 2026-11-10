# Phase 18: Heal Quests by City Size - Research

**Researched:** 2026-11-10
**Domain:** Flutter wire-contract extension (`QuestPrizes.cure`, `QuestResult.injuriesHealed`, `LootItem.recovery`, `CharacterStatus.potionRecoveryUntil`, mutation `useItem`), two sheet lines, a Journal potion flow (confirmation on parchment → mutation → feedback → notices) and a server-clock countdown
**Confidence:** HIGH for code facts (file:line read this session on `feat/18-heal-quests-by-size` at `3e76010`; one throwaway probe file, 6 probes, run and deleted); MEDIUM for the BE names (fixed in the two `18-REPO-RULES.md`, not on BE `origin/develop` `86095d89`: `grep -cF` = 0 for all six gate names)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Copied by reference, authoritative text in `18-CONTEXT.md` §Implementation Decisions (do not paraphrase in plans):
- **D-01** `QuestPrizes.cure: QuestCure` nullable (`lifePointsShare: Float!` 0..1 ceiling, `canHeal: [InjuryType!]!`); `cure { lifePointsShare canHeal }` joins the shared `QuestFragment`; `QuestCure` model inside `QuestPrizes` (`copyWith`, `toJson`, `props`); lenient: unknown injury dropped (`InjuryType.values.asNameMap()`), malformed `cure` → null, board strict rules untouched; `null` = no rows.
- **D-02** `QuestResult.injuriesHealed: [InjuryType!]!` (default empty) joins the result fragment; lenient (unknown names dropped, the result stays).
- **D-03** cure line lists ONLY the current character's injuries that are in `canHeal` («Cura le tue ferite: taglio profondo, contusione», lowercase labels, order of the character's injuries); no count, never the full list; no cure line when none matches; the intersection is FE display filtering from `CharacterStatus.injuries`.
- **D-04** life row always shown when `cure` is present: «Vita: almeno il 50%» (share 1 → «Vita: al massimo»; share 0 → hidden).
- **D-05** rows keyed by the presence of `cure`, never by `QuestType.heal`; the heal paper, description and time line unchanged.
- **D-06** result sheet «Guarite: <labels>» after the HP delta bar and before the injuries-added line; hidden when empty.
- **D-07** the plans that select the new names on the wire and the device E2E are gated by the BE Phase 18 merge; E2E: seeded injuries, one heal per size.
- **D-08** executed after the Phase 12 Hardening merge (done: `develop` `53c734e`). **D-09** out of scope as listed. **D-10** no game rule on the FE.
- **D-11** Journal «Oggetti»: heal parchments (`effect: heal`, `recovery` non-null) tappable (`ItemRow.onSelect`); in-world confirmation on parchment («Bevi <nome>?»); dedicated cubit → `useItem(itemId)` through a repository with its own failures; success drives `HpDeltaBar` gain, «Guarite: …», «Nuova pagina delle Conoscenze: <name>»; state from the character stream (no refetch); refusals are notices (`POTION_RECOVERING` with the remaining time from `extensions.recoveryUntil`, `ITEM_NO_EFFECT`, others generic); allowed in travel, hidden while `awaitingAid` is set.
- **D-12** `CharacterStatus.potionRecoveryUntil` (nullable `DateTime`); while in the future heal parchments disabled with countdown «pronta fra 1 h 12 min» ticking from the server date; a tap during the countdown does nothing; the backend is the judge.
- **D-13** item rows in the shop and in the Journal show «Ricarica: 2 h» from `recovery.time` under the «Cura: …» line; `turns` not shown; `LootItem` gets a nullable `LootRecovery` (lenient).
- **D-14** nothing touches combat on the FE. **D-15** times live at DB, never hard-coded. **D-16** lore «Il limite del corpo» through the Phase 17 Library flow; `LootItem.relatedLore` not selected.

### Claude's Discretion
Exact copy and place of the rows (since fixed in `18-REPO-RULES.md` §Copy fixed); whether the potion feedback lives on the Journal parchment or in a small result overlay; cubit split (REPO-RULES since fixed: dedicated `PotionCubit`); helper names (REPO-RULES since fixed: `curableInjuriesLine`, `lifeShareLine`, `healedLine`, `recoveryLine`); model file names (fixed); fixture shapes; whether «Guarite» reuses the injury chips or plain text.

### Deferred Ideas (OUT OF SCOPE)
Potions in combat (`recovery.turns`); turns on the item rows; travel food; per-size cure label and the full list on the sheet.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HEAL-01 | Quest sheet: life row + viewer-filtered cure line for any quest with `prizes.cure`; lenient parsing | F1 (fragment + `QuestPrizes`), F2 (three family bodies, `QuestSheetDetails`, where the injuries come from — OQ4), F9 lines |
| HEAL-02 | Result sheet «Guarite: …» from `QuestResult.injuriesHealed` | F3 (fragment, model, insertion point `quest_result_sheet.dart:168-169`) |
| HEAL-03 | Schema gate on the merged BE SDL + device UAT, one heal per size | F8 (`tool/schema_check`, gate shape), F12 |
| HEAL-04 | Journal potion flow: tap → confirmation on parchment → `useItem` → feedback/notices; travel yes, awaiting aid no | F4 (Journal «Oggetti»), F5 (confirmation + notices precedents), F7 (repository, failure, `extensions.recoveryUntil`), F10 (cubit shape) |
| HEAL-05 | `potionRecoveryUntil` + `LootRecovery` parsed; disabled parchments with countdown; «Ricarica: …» rows in shop and Journal | F6 (status + loot selection/model), F9 (humaniser — OQ2), F11 (countdown on `ServerClockService`) |
</phase_requirements>

## Project Constraints (from CLAUDE.md)
- Clean Code, SoC (UI no networking; Cubit no Flutter/`BuildContext`; models Flutter-free; repository no `BuildContext`), TDD red→green→refactor, Boy Scout rule.
- Rule 1: no app chrome on gameplay surfaces (Journal, sheets): confirmation, feedback and notices in-world. Rule 2: no blocking loading in session (the potion call shows no blocking spinner; state from the stream). Rule 3: branch `feat/18-heal-quests-by-size`, PR → `develop`. Rule 4: backend is the source of truth. Rule 5: no secrets.
- `flutter analyze --no-fatal-infos`: **baseline measured this session: `47 issues found.`, 0 error / 0 warning lines** [VERIFIED: analyzer run].
- `docs/rules/state-management.md`: `XxxCubit` + `XxxState` in `<feature>Cubit/`, `Equatable` states with complete `props`, no cubit-to-cubit calls (orchestration via `BlocListener`), `close()` cancels timers; `bloc_test` for every non-trivial cubit.
- `docs/rules/graphql.md`: documents only in `lib/graphql/`, named operations (`UseItem`), never a raw `OperationException` to the UI, repositories consume `KlimmeckGraphQl`.
- `docs/rules/ui-ux.md`: theme tokens only, tap targets ≥ 44, destructive/irreversible actions ask for confirmation (parchment, never `AlertDialog`). `docs/rules/naming.md`: booleans `isX/hasX/canX`, `label` for user-facing enum text. `docs/rules/architecture.md`: pure helpers in `lib/utils/`, widget used by ≥ 2 features in `lib/shared/components/`.
- `18-REPO-RULES.md`: contract names, FE names, fixed Italian copy, gate greps, `dart format` per file, no commit trailers.

## Summary

Four facts shape the plan. **(1) Two lines of the REPO-RULES do not match the code and need a ruling before planning** (C1, C2): `LootFragment.simpleFields` is NOT the selection of the shop and the Journal — it is the 4-field selection (`id name itemType rarity`) nested in quest and result documents; the shop, the Journal inventory and the loot queries use `LootFragment.fields`, which is where `canHeal` already lives. Adding `recovery` to `simpleFields` would not reach a single shop or Journal row and would break two pinned literals. And the fixed copy «Ricarica: 1 h 30» / «Ricarica: 24 h» cannot come from the same humaniser as «pronta fra 1 h 12 min»: the existing shared `formatGameDuration` prints «1 h 30 min» and «1 g» for 24 h (pinned by `game_duration_format_test.dart`, probe P3). **(2) Everything the potion flow needs already exists as a pattern in the Journal**: a shell-scoped mutation cubit with a session-level outcome listener that publishes in-app banners (`CompanionCubit` + `CompanionOutcomeListener`), a section-scoped countdown cubit on `ServerClockService` with `Timer.periodic` stopped when nothing can change (`SpellRecoveryCubit`, tested with `fakeAsync` + `FakeServerClockService`), and a confirmation on parchment that stays open while the mutation flies (`AbandonPartySheet` inside `PaperSheetModal`). **(3) The quest sheet has no access to the character's injuries on the Map**: `QuestInfoOverlay` passes no `viewer`; the Board builds a `QuestViewer` that does not carry injuries. The cure line needs a new input on both surfaces (OQ4). **(4) Lenient models make the gate cheap**: with the fields absent the new models default to `null` / `[]` (probe P4: today's parsers ignore the unknown keys), so every model, line, widget and cubit plan runs before the gate, and the gated plan is only the four fragment selections + the schema check. The heal parchments stay inert on a pre-gate build because `recovery` never arrives until it is selected.

**Primary recommendation:** models + shared lenient readers first, then the pure lines, then the two sheets, then `UseItem` document + repository + failure, then `PotionCubit` / notices / countdown, then `ItemRow` + Journal `ItemsSection` + the potion sheet, then the gated fragment plan (schema gate + `schema_check` 46 × OK) and the device E2E as the last human-checkpoint plan.

## Standard Stack (all already in `pubspec.yaml`, no new dependency)

| Library | Use in this phase | Source |
|---------|-------------------|--------|
| `flutter_bloc` / `bloc_test ^10.0.0` / `mocktail ^1.0.5` | `PotionCubit`, countdown cubit, `MockCubit`s in `test/helpers/mocks.dart` | [VERIFIED: codebase] |
| `graphql_flutter 5.2.1` (`GraphQLError.extensions` is a `Map<String, dynamic>?`) | `extensions.code` and `extensions.recoveryUntil` of a refusal | [VERIFIED: probes P1, P2] |
| `fake_async ^1.3.3` | countdown tests (pattern `spell_recovery_cubit_test.dart:1, :60-70`) | [VERIFIED: codebase] |
| `equatable` | `QuestCure`, `LootRecovery`, `UseItemResult`, cubit states | [VERIFIED: codebase] |
| `ServerClockService` (`lib/repository/services/time/server_clock_service.dart:9-62`) | «pronta fra …» on the server-estimated time | [VERIFIED: codebase] |

## Architecture Patterns

### Recommended files
```
lib/models/quest/quest_cure.dart                       # NEW QuestCure (lifePointsShare, canHeal), tryFromJson, toJson, copyWith, props
lib/models/quest/quest_prizes.dart                     # + QuestCure? cure
lib/models/quest_result/quest_result.dart              # + List<InjuryType> injuriesHealed (lenient, const [])
lib/models/loot_recovery.dart                          # NEW LootRecovery (time ms, turns), tryFromJson
lib/models/loot_item.dart                              # + LootRecovery? recovery
lib/models/character/character_status.dart             # + DateTime? potionRecoveryUntil
lib/models/use_item_result.dart                        # NEW UseItemResult
lib/models/enums/injury_type.dart                      # (Boy Scout) one shared lenient list reader, 3 private copies today
lib/models/lore.dart                                   # (refactor) the lenient lore-ref reader shared by QuestResult and UseItemResult
lib/utils/item_lines.dart                              # + curableInjuriesLine, lifeShareLine, healedLine, recoveryLine (+ countdown label)
lib/utils/game_duration_format.dart                    # the one humaniser (OQ2)
lib/models/quest/quest_sheet_details.dart              # + cureLine / lifeLine strings in the view model
lib/shared/components/popup/quest_info_sheet.dart      # the two rows in the three family bodies
lib/shared/components/popup/quest_result_sheet.dart    # «Guarite: …» between _hp() and _injuries()
lib/shared/components/item_row.dart                    # «Ricarica: …» line, disabled state, countdown line
lib/graphql/mutations/character_mutations.dart         # + useItem (operation name UseItem)
tool/schema_check/schema_check_documents.dart          # + 'UseItem' (45 → 46)
lib/repository/services/graphql/graphql.dart           # + Future<UseItemResult> useItem(String itemId)
lib/repository/services/graphql/graphql_error_code.dart# + reader of another extension key (sibling of graphQlErrorCode)
lib/repository/item_use_repository.dart                # NEW
lib/repository/item_use_failure.dart                   # NEW
lib/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart, potion_state.dart, potion_notice.dart   # NEW
lib/screens/mainScreen/tabs/journal/potionRecoveryCubit/…   # NEW countdown cubit (name at the planner's choice)
lib/screens/mainScreen/tabs/journal/sections/items_section.dart   # NEW: «Oggetti» extracted from journal.dart (pattern CompanionSection)
lib/screens/mainScreen/tabs/journal/components/potion_sheet.dart  # NEW: confirmation + feedback on parchment
lib/screens/mainScreen/components/potion_outcome_listener.dart    # NEW: notices at session level
lib/screens/auth/authenticated_shell.dart, lib/screens/mainScreen/main_screen.dart   # provider + listener
(gated) lib/graphql/fragments/quest_fragment.dart, quest_result_fragment.dart, loot_fragment.dart, character_fragment.dart
```

### F1. Quest fragment and `QuestPrizes` [VERIFIED: codebase]
- Fragment `lib/graphql/fragments/quest_fragment.dart:10-96`: `prizes {` :60, `prizeItem { … ... on LootItem { simpleFields description effect power canHeal } }` :76-90, `pet { id name }` :91-94, closing `}` :95. Add `cure { lifePointsShare canHeal }` right after the `pet` block. It reaches `quests` (`quest_queries.dart`) and `OnQuestUpdated` (`quest_subscriptions.dart`) — the only two users of the fragment.
- **Pinned and turning RED:** `test/graphql/loot_fragment_test.dart:59-61` «the recommended and random loot keep the simple fields» asserts `RegExp(r'\bcanHeal\b').allMatches(QuestFragment.fields)` has length **1**; `cure { … canHeal }` makes it 2. Update the pin first (→ 2, or anchor it to the loot blocks). Not turning red: `board_documents_test.dart:85-86` (`contains('pet { id name }')`), :97-110, :112-117.
- Model `lib/models/quest/quest_prizes.dart`: ctor :9-15 (`this.pet` optional → add `this.cure`), `fromJson` :25-37 (`pet: Pet.tryFromJson(json['pet'])` :36 is the additive lenient precedent → `cure: QuestCure.tryFromJson(json['cure'])`), `toJson` :39-45, `copyWith` :47-61, `props` :64. There is no `spell` field on the FE `QuestPrizes` (the BE SDL has `QuestPrizes.spell`, the FE never selected it) — the only additive example is `pet`. `QuestPrizes(` is constructed only inside the model (grep) → the new optional parameter is free.
- Boundary: `Quest.tryFromJson` (`lib/models/quest/quest.dart:38-45`) catches any throw and drops the quest. `QuestCure.tryFromJson` must therefore never throw: non-map → null; `lifePointsShare` not a finite `num` in [0, 1] → null [ASSUMED: out-of-range = malformed, see A2]; `canHeal` not a list → null (or `[]`: planner's choice, state it in the test title); unknown names dropped. Probe P4: today an unknown `prizes.cure` key is ignored and the quest parses.
- Tests: `test/models/quest/quest_test.dart:218-240` (group for `prizes.pet`) is the place for the `cure` cases; fixture `questJson(prizes: …)` (`test/helpers/fixtures/quest_fixtures.dart:22-63`) takes a free map → add a `questCureJson({share, canHeal})` helper, no signature change. New file `test/models/quest/quest_cure_test.dart`.

### F2. `QuestInfoSheet` per-family layouts and the injuries input [VERIFIED: codebase]
- The widget renders only `QuestSheetDetails` (`lib/models/quest/quest_sheet_details.dart:55-162`, factory `.of(quest, {viewer, travelPreview})` :72-123, props :147-161). Family: `questSheetFamilyOf` :24-32 — `hunt/enemy/boss/dungeon/aid` → combat, `story/worldMission` → narrative, **everything else (heal, job, study) → service**.
- Bodies in `lib/shared/components/popup/quest_info_sheet.dart`: `_combatBody` :186-209 (right column :196-204: `_timeLine`, `_travelLine`, `_titleLine`, `_slotLines`), `_narrativeBody` :246-265 (`_costLine`, `_titleLine`, `_slotLines` at :260-262, after the lore paragraphs), `_serviceBody` :267-281 (`_timeLine`, `_travelLine`, `_titleLine`, `_recommendedLoot`, `_slotLines` at :273-277). Line builders are `List<Widget>` spreads (`_timeLine` :297-306, `_travelLine` :337-349 with a `ValueKey`).
- **Insertion (D-05: keyed by `cure`, all three families):** a `List<Widget> _cureLines(details)` spread right after `..._timeLine()` in `_combatBody` (:199) and `_serviceBody` (:273), and before `..._costLine(details)` in `_narrativeBody` (:260). Two new keys (`QuestInfoSheet.cureLineKey`, `lifeLineKey`, pattern `ValueKey('questSheet.…')` :43-54). The strings come from `QuestSheetDetails` (two nullable `String` fields computed in `.of` with `curableInjuriesLine` / `lifeShareLine`, added to `props`): the widget stays dumb, the rule is unit-tested in `quest_sheet_details_test.dart`.
- **Where the character's injuries are available (OQ4):**
  - Board: `board.dart:126-143` `_viewerOf` has the `CharacterLoaded` character and builds `QuestViewer.of(character:, twitchPoints:, cityPointIds:)` (`lib/models/quest/quest_viewer.dart:16-26`); the sheet is built at `board.dart:322-326` with `viewer`. `QuestViewer` carries `characterId, title, quests, cityPointIds, twitchPoints` — **no injuries**.
  - Map: `world_map.dart:346-348` builds `QuestInfoOverlay`, which builds `QuestInfoSheet(quest:, stateLabel:, onAbandon:)` with **no viewer** (`quest_info_overlay.dart:49-53`; the sheet doc says «Null = sola lettura (mappa)» :29-31). The lane sheet of an accepted heal (2 / 5 / 8 h of waiting) is opened from here.
  - Recommended: one explicit input, independent of the viewer — `QuestInfoSheet({…, List<InjuryType>? characterInjuries})` forwarded to `QuestSheetDetails.of(…, characterInjuries:)`; the Board passes `character.status?.injuries`, `QuestInfoOverlay` gains the same parameter and `WorldMap` passes it from `CharacterCubit`. `null` → no cure line (the life row still shows). Alternative: `QuestViewer.injuries` (Board only) → on the Map the sheet of a heal would show «Vita: …» and never the cure line, which reads as «none of your injuries is healed» (contradicts D-03's meaning).
- `QuestViewer(` is constructed in `quest_viewer.dart:20` and `test/helpers/fixtures/quest_fixtures.dart:163` only; `QuestSheetDetails(` only in its factory → any new optional parameter is free.
- Harness: `test/shared/components/popup/quest_info_sheet_test.dart:62-75` `_pump(tester, quest, {viewer, stateLabel, onAbandon, travelPreview})` (add the new parameter), `useLandscapePhone`, `seedSvgCache`; `_inCombat` finder :57-60.

### F3. Quest result fragment, model and sheet [VERIFIED: codebase]
- Fragment `lib/graphql/fragments/quest_result_fragment.dart:15-119`: `hpBefore hpAfter maxLifePoints injuriesAdded` :29-32 → add `injuriesHealed` after `injuriesAdded` (:32). No test pins that adjacency (`grep -n "injuriesAdded\|hpAfter" test/graphql/*.dart` → nothing). Update the doc comment :5-13.
- Model `lib/models/quest_result/quest_result.dart`: ctor :19-49 (optional named at the end: `kind`, `ambush`, `acknowledgedAt`, `loreUnlocked`), `injuriesAdded` parse :130 is **strict** (`json['injuriesAdded'] as List`; probe P5: a result without it is dropped) → `injuriesHealed` needs its own lenient read (`json is List ? … : const []`), not `_injuriesFrom` :181-186 as is; `toJson` :215-252 must write `injuriesHealed` (round trip `quest_result_test.dart:586-589` iterates the fixtures); `props` :255-285. `QuestResult(` is never constructed outside the model.
- Sheet `lib/shared/components/popup/quest_result_sheet.dart`: `_content` :160-182 — `..._hp()` **:168**, `..._injuries()` **:169** → insert `..._line(healedLine(_result.injuriesHealed), QuestResultSheet.healedKey)` between them. `_line` :405-413 returns `[]` for a null text (hidden when empty for free). `_hp()` :288-320 returns `[]` for `rescued`/`death` — the healed line does not depend on it. `_injuries()` :322-329 is a section «Ferite» with one `Text(injury.label)` per row (capitalised labels). Keys :37-55 (`ValueKey('questResult.<name>')`).
- Fixtures `test/helpers/fixtures/quest_result_fixtures.dart:71-142` `questResultJson`: add `List<Object?> injuriesHealed = const []` → `'injuriesHealed': injuriesHealed`; add a `healResultJson()` (heal quest, `hpBefore < hpAfter`, no enemies, one healed injury) and put it in the round-trip map of `quest_result_test.dart` (:586).
- The ambush carousel (`ambush_report_carousel.dart`) reuses the sheet: unaffected (the line is hidden when empty).

### F4. Journal «Oggetti» today [VERIFIED: codebase]
- `lib/screens/mainScreen/tabs/journal/journal.dart`: `_buildOwnedItemsSection(character, lootSize)` **:241-276** — a `Dropdown(sectionName: "Oggetti")` with the effect chips (`ItemsFilter<EffectType>` :259-264) and one `ItemRow(assetItem:, quantity:, showCoins: false, size:)` per owned item **:267-272, with no `onSelect`** today. The equipment rows are the tappable precedent (:204-215: `onSelect: (item) => _equipItem(…)`, `onLongTap`). `_dropVanishedEffectFilter` :232-239 and the `_selectedEffect` state :49 belong to the same section. Called from `build` :482. The file is 500 lines; «Magie imparate» and «Compagno» already live in `sections/` as their own widgets.
- `ItemRow` (`lib/shared/components/item_row.dart:11-100`): `onSelect` is forwarded to the **card** only (`LootItemCard(onTap: (item) => onSelect?.call(item))` :52-58; `loot_item_card.dart:28-29` `GestureDetector(onTap: onTap != null ? … : null)`) — the texts on the right are not tappable. Lines are built in `build` :35-37 (`itemEffectLabel`, `healedInjuriesLine`) and rendered by `_buildTexts` :78-98 (keys `item-effect-<id>`, `item-injuries-<id>`).
  - «Ricarica: …» → a third line from `recoveryLine(lootItem.recovery)` after the injuries line (key `item-recovery-<id>`): it appears in the shop (`shop_modal.dart:143, :186`, `transaction_modal.dart:230`) and in the Journal with no call-site change; on the result sheet rows (`quest_result_sheet.dart:376`) `recovery` is never selected → no line (D-14 intact).
  - Disabled state + countdown: `ItemRow` has no disabled notion. Add two optional inputs (e.g. `bool isDisabled = false`, `String? statusLine`): the card wrapped in `AnimatedOpacity(opacity: isDisabled ? KlimmeckGuideTheme.pendingInkOpacity : 1, duration: pendingInkDuration)` (precedent `owned_companion_row.dart:35-37`, tokens `kg_theme.dart:16-17`) and the countdown as a fourth text line (key `item-status-<id>`). The caller passes `onSelect: null` while disabled (a tap makes no call, D-12).
- Wiring of the two existing Journal cubits (the pattern to mirror):
  - Provided at the shell because the `PageView` destroys off-screen tabs: `authenticated_shell.dart:259-264` (`SpellsCubit`, `CompanionCubit`, each with its repository built from `graphQl`).
  - Section widget reads `CharacterCubit` with a `BlocSelector` and the feature cubit with a `BlocBuilder`: `sections/companion_section.dart:31-67`; the tap calls the cubit and gives haptics.
  - Outcomes at session level: `lib/screens/mainScreen/components/companion_outcome_listener.dart:11-68` (mounted in `main_screen.dart:153-154` next to `SpellOutcomeListener`) — a `BlocListener<CharacterCubit>` forwards every new character to `cubit.sync(...)`, a `BlocListener<CompanionCubit>` with `listenWhen: outcome changed` calls `companionNoticeFor(outcome)` and `InAppNotificationsCubit.publishNotice(notice, dedupKey: …)` (:53-62); stale views trigger a silent `refreshCharacter()`.
  - **How a notice is rendered:** `companion_notice.dart:10-20` / `spell_notice.dart:14-30` are **functions returning a `KGNotification(title:, description:)`**, shown by the in-app banner `KgNotificationBanner` (`lib/shared/components/kg_notification_banner.dart:8-80`: a thin parchment strip at the top, title + description, max 2 lines) through `InAppNotificationsCubit.publishNotice` (`in_app_notifications_cubit.dart:64-73`, deduplicated by key for the display duration). There is no «notice on the parchment of the row» anywhere in the app (C3).
- `awaitingAid`: the Journal stays reachable while awaiting aid (`satchel_availability.dart:20-29` disables Board and Shop only) → «hidden while `awaitingAid` is set» = the heal parchments get no `onSelect` and no countdown when `character.status?.awaitingAid != null`. In travel nothing is disabled (D-11).
- Harness: `test/helpers/journal_harness.dart` — `journalCharacter({spellbook, ownedItems})` :33-53 (status with `injuries: []`, no `potionRecoveryUntil`, no `awaitingAid` → needs optional parameters), `seedJournalSvgs()` :56-75, `idleCompanionCubit()` :78-86, `pumpJournalPage(tester, {characterCubit, spellsCubit, companionCubit})` :89-115 (provides `FakeServerClockService(spellFixtureNow)` as `ServerClockService`). Both `journal_items_test.dart` and `journal_spells_test.dart` go through it → the new cubit provider(s) must be added here with an idle default, or every Journal test fails with `ProviderNotFoundException`.

### F5. In-world confirmation on parchment [VERIFIED: codebase]
- `lib/screens/mainScreen/tabs/map/components/abandon_party_sheet.dart:13-117`: a `Column` with a title, a question (`static const String question`), two `TextButton`s with `Semantics`, `minimumSize: Size(44, 44)`, keys `party.abandon` / `party.stay`; `BlocListener` closes the sheet on a settled state (`_closeSettled` :45-48, `ModalRoute.isCurrent` guard), `PopScope(canPop: state is! QuestAbandoning)` and disabled buttons while the mutation flies — no spinner.
- Opened by `world_map.dart:613-635` `_confirmAbandon`: `showModalBottomSheet(useSafeArea: false, isScrollControlled: true, backgroundColor: Colors.transparent, constraints: maxWidth = screen width, builder: (_) => BlocProvider.value(value: cubit, child: NotificationListener<DraggableScrollableNotification>(… child: PaperSheetModal(child: AbandonPartySheet(…)))))`. `PaperSheetModal` (`lib/shared/components/modal/paper_sheet_modal.dart:5-50`) draws `CloudinaryAssets.bottomEmptySheet`. The route is on the ROOT navigator, outside the shell providers (`authenticated_shell.dart:97-99`): cubits are passed with `BlocProvider.value`, and `ServerClockService` must be read before opening.
- The travel confirmation (`travel_confirmation_sheet.dart`) is the same surface. `ui-ux.md` names it «foglio di pergamena (bottom sheet, mai `AlertDialog`)». The REPO-RULES line «never … a bottom sheet with app styling» is satisfied by this parchment sheet (it has no app styling); the «Magie imparate» rule (memory: never text rows that open a bottom sheet) concerns the SECTION layout, not a confirmation — but it is the orchestrator's call (OQ7).
- Recommended potion surface (discretion «parchment vs small overlay»): **one `PotionSheet` in `PaperSheetModal`** with three faces driven by `PotionCubit`: confirm («Bevi <nome>?» + two actions) → drinking (actions disabled, no spinner, `PopScope` blocks) → drunk (`HpDeltaBar` animated with the `TweenAnimationBuilder` of `quest_result_sheet.dart:303-316`, «Guarite: …», «Nuova pagina delle Conoscenze: <name>», one «Continua» action). A refusal closes the sheet and the banner says why. It reuses a proven surface, keeps the HP animation visible (the «Punti vita» section is at the top of the Journal, far from «Oggetti») and needs no new overlay machinery. `UseItemResult` has no `maxLifePoints`: `HpDeltaBar(max:)` takes it from `character.status.maxLifePoints` read before opening.

### F6. Character status and loot selection [VERIFIED: codebase]
- Status fragment `lib/graphql/fragments/character_fragment.dart:24-67`: `awaitingAid { quest aidQuest since }` :50-54, `spells {` :55, `spellStates { … }` :58-64, `unlockedLore` :65, closing :66. **Pin:** `test/graphql/character_fragment_test.dart:94-98` asserts `contains('spellStates { usages recoveries spell { id } } unlockedLore }')` — appending after `unlockedLore` turns it RED. Put `potionRecoveryUntil` right after the `awaitingAid` block (:54, before `spells`): no existing pin changes (`:87-92` only `contains('awaitingAid { quest aidQuest since }')`). The fragment feeds `character` (`character_queries.dart`) and `characterUpdated` only.
- Model `lib/models/character/character_status.dart`: ctor :13-28, `fromJson` :54-76, lenient helpers :78-98, `toJson` :100-115, **`copyWith` :117-145 rebuilds the status and carries the non-parameter fields by hand (:140-143: `activeTravel`, `spellStates`, `awaitingAid`, `unlockedLore`)** → `potionRecoveryUntil` must be carried there or any copy clears the countdown; `props` :148-163. Date precedents: `AwaitingAid.since` = `DateTime.parse(json['since'] as String).toUtc()` inside a `tryFromJson` (`awaiting_aid.dart:16-30`); `QuestResult._instantFrom` (`quest_result.dart:212-213`, `json is String ? DateTime.parse(json).toUtc() : null` — throws on a malformed string). For the status use `json is String ? DateTime.tryParse(json)?.toUtc() : null` (a bad date must not kill the whole character). `CharacterStatus(` is constructed only inside the model.
- Test helper `test/models/character/character_status_test.dart:13-30` `statusJson` with the `_absent` sentinel → add `potionRecoveryUntil`; new group mirroring `unlockedLore` (:~200-225): parsed as UTC, absent/null/malformed → null, `toJson`, props, `copyWith` keeps it.
- Stream: `CharacterCubit` (`lib/screens/mainScreen/characterCubit/character_cubit.dart`) emits `CharacterLoaded(character)` from `loadCharacter` :68-83, `refreshCharacter` :89-106 and the subscription `_onCharacter` :116-120 (`KlimmeckGraphQl.subscribeToCharacter`, `graphql.dart` «characterUpdated»). The Journal rebuilds through its `BlocConsumer<CharacterCubit>` (`journal.dart:430-498`) and the sections' `BlocSelector`s — after `useItem` the new HP, injuries, stack and `potionRecoveryUntil` arrive with no refetch (BE D-17: change stream).
- **Loot selection — where it really is:** `lib/graphql/fragments/loot_fragment.dart`: `definition` :6-23 and `fields` :25-43 select `id name description rarity effect power canHeal buyPrice {…} sellPrice {…}`; `simpleFields` :45-50 selects `id name itemType rarity` only.
  - `LootFragment.fields` users: `character_fragment.dart:93` (Journal `ownedItems`), `shop_queries.dart:25` (shop), `loot_item_queries.dart:8, :17`.
  - `LootFragment.simpleFields` users: `quest_fragment.dart:55, :72, :83` (recommended loot, random loot, prize item) and `quest_result_fragment.dart:41, :67` (consumables used, reward items).
  - → `recovery { time turns }` belongs in **`fields` and `definition`** (C1). Position: after the `sellPrice { … }` block keeps the two pins `test/graphql/loot_fragment_test.dart:27-39` (`'effect power canHeal buyPrice {'`) green; between `canHeal` and `buyPrice` would need both updated.
- Model `lib/models/loot_item.dart:9-97`: `canHeal` is the additive precedent (ctor `this.canHeal = const []` :19, `_canHealFrom` :91-97, `toJson` :60, `copyWith` :63-85, `props` :88). `LootItem(` is constructed in 3 tests (`item_lines_test.dart:17`, `item_row_test.dart:17`, `loot_item_card_test.dart:11`) with named parameters → an optional `this.recovery` is free. `LootRecovery.tryFromJson`: non-map → null; `time` not an `int`/`num` ≥ 0 → null; `turns` missing → [ASSUMED] null as well (the SDL says `Int!`; state the choice in the test title).
- Tests: `test/models/loot_item_test.dart:5-12` `_potion({injuries})` helper → add `recovery`; new file `test/models/loot_recovery_test.dart`; `test/graphql/loot_fragment_test.dart` gains «fields/definition select recovery { time turns }», «simpleFields stay without recovery», and the five `_fullLootDocuments` (:17-23) «select recovery».

### F7. Repository, failure and `extensions.recoveryUntil` [VERIFIED: codebase + probes P1, P2]
- Pattern: `lib/repository/quest_abandon_repository.dart:10-38` (ctor `{required KlimmeckGraphQl graphQl, this.timeout = defaultTimeout}` 15 s; `try { await _graphQl.x(...).timeout(timeout) } on OperationException → XException(xFailureFrom(error)); on TimeoutException → timedOut; on Object → unknown`) and `quest_abandon_failure.dart:9-49` (enum + `class QuestAbandonException implements Exception { const …(this.failure); }` + `questAbandonFailureFrom(OperationException)`). The typed-result variant is `companion_repository.dart:38-48` `_guard<T>`.
- Code reading: `graphQlErrorCode(OperationException?)` (`lib/repository/services/graphql/graphql_error_code.dart:17-33`) reads `extensions['code']` from `exception.graphqlErrors` AND from `ServerException.parsedResponse.errors` (HTTP ≥ 300, Phase 12 D-13a) through `_firstCodeOf` :35-38. Mapping rule of every failure file: `code == null && exception.linkException != null → connection` first, then the `switch` with `badUserInputCode` (:7), `notFoundCode`, `forbiddenCode`, `unauthenticatedCode` (`auth_api_exception.dart`).
- Existing code constants to import, not redeclare: `awaitingAidCode = 'AWAITING_AID'` (`travel_failure.dart:11`), `itemNotOwnedCode = 'ITEM_NOT_OWNED'` (`transaction_failure.dart:8`). New: `ITEM_NOT_USABLE`, `POTION_RECOVERING`, `ITEM_NO_EFFECT`.
- **Other extension keys:** the only precedent is the session path, which is NOT reusable as is: `auth_api_exception.dart:65-99` `mapAuthOperationException` → `_firstCodedError(exception.graphqlErrors)` + `_revokeReasonOf(error)` = `error.extensions?['reason']` (private, `graphqlErrors` only, no HTTP-400 path). **There is no shared helper for a non-code extension key.** Add one next to `graphQlErrorCode` (same two sources; e.g. `Object? graphQlErrorExtension(OperationException? exception, String key)`, returning the value from the first error that carries a `code`), unit-tested with the two shapes of `test/repository/quest_abandon_failure_test.dart:7-23` (`_withCode`, `_fromHttp400`). Probes P1/P2: `extensions: {'code': 'POTION_RECOVERING', 'recoveryUntil': '2026-11-10T12:30:00.000Z'}` is readable on both paths; `DateTime.tryParse` gives a UTC instant.
- BE side today: `GameRuleException` (`src/gameRules/game-rule.exception.ts` on `origin/develop`) sets `extensions = { code }` only; the BE REPO-RULES require `extensions.recoveryUntil` to survive `formatDomainError` with an allow-list of that one key (as `reason` did in BE Phase 17) — to be confirmed by the BE research; the FE gate cannot grep an extension in the SDL (A1).
- **`ItemUseFailure` cannot carry a date as an enum value** (REPO-RULES: «values `potionRecovering` carrying the server `recoveryUntil`»). Every failure in the repo is a plain enum + an exception with one field. Smallest consistent shape: keep the enum with the fixed values and put the date on the exception — `class ItemUseException implements Exception { const ItemUseException(this.failure, {this.recoveryUntil}); }`, `toString` printing the failure name only (pattern `travel_failure_test.dart:119`). OQ5.
- The fixed value list has no `timedOut`, `unauthenticated`, `forbidden`, `notFound`. The repository pattern produces `timedOut` (client timeout) and every other notice file maps `unauthenticated` → **no notice** («il flusso di sessione sta già agendo», `companion_notice.dart:27`, `spell_notice.dart:40`). The planner may add names: add `timedOut` and `unauthenticated` (OQ5); `FORBIDDEN`/`NOT_FOUND` can stay under `unknown` → generic.
- Service method: `KlimmeckGraphQl.useItem(String itemId)` beside the pet mutations (`graphql.dart:719-731`), built on `_dataOrThrow(await performMutation(query:, variables: {'itemId': itemId}))` (pattern `abandonQuest` :611-622; `performMutation` :91-103 is `noCache`); returns `UseItemResult.fromJson(data['useItem'])` or throws `FormatException` → the repository maps it to `unknown`.
- Document: `CharacterMutations.useItem` in `lib/graphql/mutations/character_mutations.dart` («the other character/journal mutations», `equipPet` :57-63), operation name **`UseItem`**: `mutation UseItem($itemId: ID!) { useItem(itemId: $itemId) { hpBefore hpAfter injuriesHealed quantityLeft recoveryUntil loreUnlocked { id name type } } }` (`loreUnlocked` selection = the Phase 17 one, `quest_result_fragment.dart:90-94`).
- `UseItemResult`: `hpBefore`/`hpAfter` strict ints, `recoveryUntil` strict date (UTC), `injuriesHealed` lenient, `quantityLeft` int (not used by the UI: the stack arrives from the stream), `loreUnlocked` lenient `List<Lore>`. The lenient lore reader is private to `QuestResult` (`quest_result.dart:193-208` `_loreUnlockedFrom` / `_loreRefOrNull`) → extract it (e.g. a static on `Lore`) and use it from both; the three private copies of the lenient injury reader (`loot_item.dart:91-97`, `character_status.dart:92-98`, `quest_result.dart:181-186`) become one shared function used by `QuestCure`, `injuriesHealed`, `UseItemResult` (Boy Scout, same plan as the first model).

### F8. `tool/schema_check` and the gate [VERIFIED: codebase + BE `origin/develop` read-only]
- Registry: `tool/schema_check/schema_check_documents.dart:42-90`, a `Map<String, String>` keyed by **operation name** (45 entries). `dump_documents.dart` writes one `<name>.graphql` per entry and prints `dumped N documents`; `validate_documents.js` (Node, `graphql` from the BE `node_modules`) validates them against a schema file. There is no single `dart run tool/schema_check` entry point (REPO-RULES wording): the two commands are `dart run tool/schema_check/dump_documents.dart "$SCRATCH/docs"` and `NODE_PATH=$BE/node_modules node tool/schema_check/validate_documents.js "$SCRATCH/schema.gql" "$SCRATCH/docs"` (17-RESEARCH F8, used at 15-08 / 16-07 / 17-09).
- Adding a mutation = the document constant in `lib/graphql/mutations/` + one registry line (`'UseItem': CharacterMutations.useItem`) + the doc comment :26-41. Enforced by `test/tool/schema_check_documents_test.dart:28-30` (registry keys == every `query|mutation|subscription <Name>` declared under `lib/graphql/{queries,mutations,subscriptions}`) and :36-44 (one operation per document, named like its key) → **document and registry line in the same commit**.
- **Count pins 45 → 46 (four places, RED first):** `test/tool/schema_check_documents_test.dart:32-34`, `test/graphql/shop_documents_test.dart:128`, `test/graphql/travel_documents_test.dart:178-179`, `test/graphql/loot_fragment_test.dart:86-88`.
- The CI (`.github/workflows/ci.yml`: analyze, test, `tool/hardening_check.sh`, release build, bundle greps) does NOT run the schema validation → a `UseItem` document committed before the BE merge keeps the CI green; it is sent only when a heal parchment with a `recovery` is tapped, which cannot happen before `recovery` is selected. The four fragment selections, on the contrary, break `character`, `characterUpdated`, `quests`, `GetCityShop` and the results against a BE without Phase 18 the moment they are selected → they are the gated plan (OQ6).
- Gate today (read-only, no fetch): BE `origin/develop` = `86095d89`; `grep -cF` on `src/schema.gql` → `type QuestCure` 0, `injuriesHealed` 0, `type LootRecovery` 0, `potionRecoveryUntil` 0, `useItem(` 0, `type UseItemResult` 0. Current SDL: `type LootItem { buyPrice canHeal description effect id itemType name power rarity sellPrice sellable }`, `type QuestPrizes { pet prizeCoins prizeItem randomLoot spell xpPrize }`, `type CharacterStatus { … unlockedLore xp }`, `scalar DateTime`, `Spell.recoveryTime: Int!`. BE `BACKEND-NOTES.md` for Phase 18 does not exist yet.
- Gate plan shape (pattern 17-09): scratch dir outside the repo; `git -C $BE show origin/develop:src/schema.gql > "$SCRATCH/schema.gql"`; the six `grep -cF` ≥ 1 else STOP + STATE park note; `awk '/^type QuestCure /,/^}/'` etc. to quote the SDL in the SUMMARY; RED the four fragment tests + pins, GREEN the four selections; `dump_documents` → «dumped 46 documents»; `validate_documents.js … | grep -vc OK` → 0; full suite foreground; analyzer; `dart format --output=none --set-exit-if-changed` per touched file; trailer grep over `develop..HEAD` = 0.

### F9. Lines and the duration humaniser [VERIFIED: codebase + probe P3]
- `lib/utils/item_lines.dart` (65 lines, «ogni stringa delle righe oggetto vive qui»): `healedInjuriesLine(LootItem)` :57-65 iterates `InjuryType.values` (enum order), lowercases `type.label`, joins with `', '`, prefix `'Cura: '`, returns `null` when empty. The four new helpers are siblings:
  - `curableInjuriesLine(QuestCure? cure, List<InjuryType>? characterInjuries)` → iterate the **character's** list (D-03 order), keep those in `cure.canHeal`, de-duplicate, lowercase, `'Cura le tue ferite: '` + join; `null` when cure is null, the list is null/empty or nothing matches.
  - `lifeShareLine(QuestCure? cure)` → `null` for null cure or share ≤ 0; share ≥ 1 → `'Vita: al massimo'`; else `'Vita: almeno il ${(share * 100).round()}%'` (the only arithmetic allowed by D-10).
  - `healedLine(List<InjuryType> injuries)` → `'Guarite: '` + labels, `null` when empty (case of the labels: OQ8).
  - `recoveryLine(LootRecovery? recovery)` → `'Ricarica: '` + humanised `Duration(milliseconds: recovery.time)`, `null` for a null recovery (and for `time` 0? [ASSUMED] null: «a potion without `time` is not drinkable», BE D-15).
  - plus the countdown label (`'pronta fra '` + humanised remaining).
- **Existing humanisers:** `formatGameDuration(Duration)` (`lib/utils/game_duration_format.dart:7-20`, «Condivisa da viaggio (Phase 7) e magie (Phase 8, D-13)», rounds UP to the minute, `≥ 24 h` → days) — used by `spell_lines.dart:27-43` («prossimo tra …», «Recupero: …»), the travel sheet, the map marker, the innkeeper label; pinned by `test/utils/game_duration_format_test.dart:6-19`. `getStringToShowFromDuration` (`lib/utils/utils.dart:4-6`, «5 ore , 30 minuti») is the legacy one used only by the quest time line (`quest_info_sheet.dart:302`) — do not reuse.
- Probe P3 (`formatGameDuration`): 30 min → «30 min», 45 → «45 min», 60 → «1 h», 72 → «1 h 12 min», **90 → «1 h 30 min»**, 120 → «2 h», 600 → «10 h», **1440 → «1 g»**; 71 min 01 s → «1 h 12 min» (ceil). So the fixed copy «pronta fra 1 h 12 min» and «Ricarica: 30 min» match the shared function, «Ricarica: 1 h 30» and «Ricarica: 24 h» do not (C2 / OQ2).
- Tests: `test/utils/item_lines_test.dart` (groups per helper, `LootItem(...)` built directly :17) — add four groups with `(D-03)`, `(D-04)`, `(D-06)`, `(D-13)` titles.

### F10. `PotionCubit`, `PotionNotice`, listener [VERIFIED: patterns; shape recommended]
- The potion call is **not optimistic** (no overlay on HP/stack/injuries: the BE decides what a potion does) → the closest pattern is `QuestAbandonCubit` (`lib/screens/mainScreen/questAbandonCubit/quest_abandon_cubit.dart:12-39`: `if (isClosed || state is QuestAbandoning) return; emit(QuestAbandoning); try { await repository…; emit(QuestAbandoned) } on XException catch (e) { emit(Failed(e.failure)) } catch (_) { emit(Failed(unknown)) }`, `reset()`), sealed states with `Equatable` (`quest_abandon_state.dart:3-40`), `with SafeEmit` (`lib/shared/bloc/safe_emit.dart`). From `CompanionCubit` take only the `sequence` counter on the outcome (`companion_state.dart:27-44`) so two identical refusals in a row are two events.
- Recommended states: `PotionIdle`, `PotionDrinking(itemId)`, `PotionDrunk(itemId, UseItemResult result)`, `PotionRefused(itemId, ItemUseFailure failure, {DateTime? recoveryUntil, int sequence})`; one action `drink(String itemId)` (ignored while `PotionDrinking`), `reset()`.
- Scope: provided at the shell beside `CompanionCubit` (`authenticated_shell.dart:262-264`) with `ItemUseRepository(graphQl: graphQl)`: the mutation may answer after the player left the Journal (PageView destroys the tab) or with the sheet (root route) open.
- Notices: `potion_notice.dart` in `potionCubit/` — «pattern `companionCubit` / `spellsCubit`» is a **function** `KGNotification? potionNoticeFor(...)` plus title constants, not a class named `PotionNotice` (OQ5). It needs the remaining time: `potionNoticeFor(failure, {Duration? remaining})` with `remaining = recoveryUntil.difference(clock.now())` computed by the listener (a widget: it may read `ServerClockService` from the context; the cubit stays clock-free). `KGNotification` requires a **title** — a string that is not in the fixed copy list (OQ3). A `POTION_RECOVERING` refusal without a readable `extensions.recoveryUntil` → fall back to the generic notice (never a local estimate) [ASSUMED, OQ9].
- `PotionOutcomeListener` in `lib/screens/mainScreen/components/` mounted in `main_screen.dart:153-155` (chain of outcome listeners): `listenWhen: current is PotionRefused && previous != current` → `publishNotice(notice, dedupKey: 'potion|${failure.name}|$itemId|$sequence')` (the banner dedup window is the display duration, `in_app_notifications_cubit.dart:64-73`: without the sequence a second identical refusal inside the window is silently dropped). No `refreshCharacter()` is needed on success (the stream delivers); on `notOwned`/`timedOut` a silent `refreshCharacter()` realigns a stale view (pattern `_staleViewFailures`, `companion_outcome_listener.dart:19-23`).
- Mocks to add in `test/helpers/mocks.dart` (pattern :104, :159): `MockItemUseRepository`, `MockPotionCubit extends MockCubit<PotionState>`.

### F11. Countdown [VERIFIED: codebase]
- The «travel ETA» pattern is `TravelProgressCubit` (`lib/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit.dart:18-148`): `ServerClockService` injected, `Timer.periodic(_tick = 1 s)` created lazily in `_refresh()` (:84-89) and stopped when nothing can change (`_isSettled`), `clock.offsetChanges` re-computes (:28, :77-80), `close()` cancels timer and subscription (:142-147); remaining = `endTime.difference(serverNow)` clamped at zero (:132-135). Its Journal twin, closer to this use, is `SpellRecoveryCubit` (`…/journal/spellRecoveryCubit/spell_recovery_cubit.dart:15-77`): `follow(inputs)` + `_refresh()` + `_timer ??= Timer.periodic(...)` only while a countdown is shown; **created and closed by the section** (`sections/spells_section.dart:57-61` `BlocProvider(create: (context) => SpellRecoveryCubit(clock: context.read<ServerClockService>()))`), fed by a `BlocListener<CharacterCubit>` plus an initial `_follow` in `initState` (:82-99, :116-120) because a `BlocListener` does not fire for the state present at mount.
- `ServerClockService.now()` = device time + offset measured against `serverTime` (`server_clock_service.dart:33, :44-56`), zero offset until the first sync; «server date vs local clock» of D-12 is exactly this.
- Recommended: a small section-scoped cubit (e.g. `PotionRecoveryCubit` under `…/journal/potionRecoveryCubit/`) with `follow(DateTime? potionRecoveryUntil)` and a state `{Duration? remaining}` (`null` = ready); tick 1 s (the label changes per minute; 1 s keeps the re-enable prompt), timer stopped when `remaining` is null. Keeping it separate from `PotionCubit` matches the existing split (mutation cubit at the shell, ticker with the section) and keeps `PotionCubit` free of timers. The label is `'pronta fra ${humanise(remaining)}'` built in `item_lines.dart`.
- How tests drive time: `test/helpers/fakes/fake_server_clock_service.dart:6-37` (`current`, `advance(delta)`, `resync(serverNow)` emitting `offsetChanges`) inside `fakeAsync((async) { … clock.advance(d); async.elapse(d); … })` (`spell_recovery_cubit_test.dart:60-70`); probe P6 confirms the humanised sequence over elapsed fake time (`[1 h 12 min, 36 min, 0 min]`). Never `Future.delayed` on real time (REPO-RULES).

### F12. Device E2E shape (last plan, human checkpoint)
Pattern 17-10 / 16-08: `autonomous: false`, re-check the gate, `18-HUMAN-UAT.md` (frontmatter + Setup, Session data, Steps table «Step | Requirements | Decisions | Expected | Result | Note»), results only from the user's words, `requirements mark-complete` per passed id, ROADMAP/STATE/REQUIREMENTS closed, FE `BACKEND-NOTES.md`. Phase 18 specifics: player identity (the dev bypass is the innkeeper, memory); prerequisites owned by the orchestrator after the BE merge — content written at DB (166 heals by size, `recovery` on the 28 potions, lore «Il limite del corpo» linked), injuries seeded on the test character, the three example heals from the BE handoff. Steps: (1) village heal sheet with one listed + one unlisted injury → cure line lists one, «Vita: almeno il 50%»; (2) result → «Guarite: …», HP to 50%, the unlisted injury still in the Journal; (3) city; (4) capital → everything healed, «Vita: al massimo»; (5) a quest without `cure` → no rows; (6) shop and Journal rows «Ricarica: …»; (7) Journal: tap a field herb → «Bevi …?» → HP animation, «Guarite», «Nuova pagina delle Conoscenze: Il limite del corpo», Library «Nuovo»; (8) every heal parchment disabled with «pronta fra …», a tap does nothing; (9) second potion → `POTION_RECOVERING` notice with the server's remaining time (needs a way to force it: e.g. device clock moved forward, or a second device — to be written in the UAT setup); (10) full HP and no curable injury → «Questa pozione non ti farebbe nulla adesso» (`ITEM_NO_EFFECT`, after the recovery has passed or been cleared at DB); (11) in travel the potion is drinkable; awaiting aid → parchments not tappable.

### Anti-Patterns to Avoid
- Putting `recovery` in `LootFragment.simpleFields` (C1).
- A second duration formatter next to `formatGameDuration` without a ruling (OQ2); reusing `getStringToShowFromDuration`.
- Keying the sheet rows on `QuestType.heal` or on the service family only (D-05).
- Deciding on the FE that a potion would have no effect (HP full, nothing curable) and hiding/disabling it: only the countdown and `awaitingAid` gate the tap; `ITEM_NO_EFFECT` is the server's answer.
- Applying `UseItemResult` to the character state (HP, stack, injuries) — the stream is the only source (rule 2 / D-11).
- A spinner in the sheet or a `JournalLoading`-style state for the mutation; `PotionCubit` calling `InAppNotificationsCubit` or `CharacterCubit` directly.
- `AlertDialog`, `SnackBar`, `showDialog` for the confirmation.
- Hard-coding any recovery time, or computing the remaining time of the refusal notice from the local `potionRecoveryUntil` when the server sent its own.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Lenient injury lists | a fourth private `_injuriesFrom` | one shared reader on `InjuryType.values.asNameMap()` | three identical copies exist already |
| Lenient lore refs | a new parser in `UseItemResult` | the `QuestResult` reader, extracted | same `{ id name type }` selection, same rules (17 D-04/D-16) |
| Server time | `DateTime.now()` in a widget/cubit | `ServerClockService.now()` + `offsetChanges` | offset, foreground resync, fake for tests |
| Ticker | `Stream.periodic`, `Ticker`, `Timer` in a `State` | cubit with lazy `Timer.periodic` (pattern `SpellRecoveryCubit`) | stops itself, closes with the section, `fakeAsync`-testable |
| Confirmation surface | a custom overlay / dialog | `showModalBottomSheet` + `PaperSheetModal` (pattern `_confirmAbandon`) | proven in-world surface, root-navigator caveats already solved |
| Refusal surface | inline error widgets | `KGNotification` + `InAppNotificationsCubit.publishNotice` | dedup, queue, survives tab changes |
| Error code reading | `exception.graphqlErrors.first.extensions` | `graphQlErrorCode` + its new sibling for another key | HTTP-400 path (Phase 12 D-13a) |
| HP animation | a new bar | `HpDeltaBar(isGain: true)` in a `TweenAnimationBuilder` (`quest_result_sheet.dart:303-316`) | `healGreen` ink, tested |

## Conflicts (CONTEXT / REPO-RULES vs the code)

- **C1 — `recovery { time turns }` «joins `LootFragment.simpleFields`» (CONTEXT D-13, REPO-RULES §GraphQL) vs the code.** `simpleFields` (`loot_fragment.dart:45-50`) is the 4-field selection nested in quest and result documents; shop, Journal and loot queries select `LootFragment.fields` (F6). In `simpleFields` the field would (a) never reach a shop or Journal row, (b) be selected on quest recommended/random/prize loot and on the result's `consumablesUsed`/`rewards.items` (against D-14's spirit), (c) break the pinned literal `'... on LootItem { id name itemType rarity description effect power }'` (`quest_result_documents_test.dart:41-46`), and (d) contradict the design pin «simpleFields stay without canHeal» (`loot_fragment_test.dart:41-43`). **Recommendation:** amend both documents to «joins `LootFragment.fields` and `LootFragment.definition`» (where `canHeal` is). No rename involved.
- **C2 — fixed copy «Ricarica: 1 h 30» / «Ricarica: 24 h» + «one humaniser shared by «Ricarica: …» and «pronta fra …»» vs «pronta fra 1 h 12 min» and the existing `formatGameDuration`.** The shared function prints «1 h 30 min» and «1 g» (pinned, P3); one rule cannot print «1 h 30» for 90 min and «1 h 12 min» for 72 min. **Options:** (a) reuse `formatGameDuration` unchanged → «Ricarica: 1 h 30 min», «Ricarica: 1 g», «pronta fra 1 h 12 min» (consistent with «Recupero: …» of the spells; zero new code); (b) a new potion humaniser in hours without days («24 h») and with «min» always written («1 h 30 min») for both lines; (c) literal copy = two formatters (contradicts the REPO-RULES sentence). Recommendation: (a), or (b) if «24 h» must read in hours. Needs the orchestrator/user (OQ2).
- **C3 — «Refusals are notices on the parchment (pattern of the companion and spell notices)» (D-11) vs what that pattern is.** Companion and spell notices are in-app banners (`KgNotificationBanner`, parchment strip at the top of the screen) published at session level; nothing is drawn on the row's parchment. Following the cited pattern = banner. It needs a title string not in the fixed copy (OQ3).
- **C4 — «`ItemUseFailure` … values `potionRecovering` carrying the server `recoveryUntil`» vs enum failures.** A Dart enum value cannot carry a per-instance date; see F7 (date on `ItemUseException`). Also the value list lacks `timedOut`/`unauthenticated`, which the repository and notice patterns need (OQ5).
- **C5 — «notice type `PotionNotice`» vs `companion_notice.dart` / `spell_notice.dart`.** Those files hold a top-level function `xNoticeFor(...)` and title constants, no type. Naming only (OQ5).
- **C6 — «`dart run tool/schema_check` where the plan says so».** No such entry point: `dump_documents.dart` + `validate_documents.js` (F8). Wording only.
- **C7 — CONTEXT D-01 «(`pet`, `spell` as additive examples)».** The FE `QuestPrizes` has no `spell` field; `pet` is the only precedent (F1). Informational.
- **C8 — CONTEXT `<code_context>` «`CharacterCubit` state: `status.injuries` already available for the intersection».** True for the Board; the Map's sheet receives no character data today (F2, OQ4).

## Common Pitfalls

### Pitfall 1: A throwing `QuestCure` parser empties the board
`Quest.tryFromJson` drops the whole quest on any throw (`quest.dart:38-45`). `QuestCure.tryFromJson` must return null on every malformed shape (casts with `as` are the usual culprit). Test: «a malformed cure keeps the quest with cure null (D-01)» for non-map, share as string, share out of range, `canHeal` not a list.

### Pitfall 2: `CharacterStatus.copyWith` clears `potionRecoveryUntil`
`copyWith` rebuilds the object and carries four fields by hand (`character_status.dart:140-143`). A fifth not carried → every copy re-enables the potions. Test: «copyWith keeps potionRecoveryUntil».

### Pitfall 3: Incomplete `props` / `toJson`
`QuestPrizes.props` (:64), `LootItem.props` (:88), `QuestResult.props` (:255-285), `CharacterStatus.props` (:148-163), `QuestSheetDetails.props` (:147-161): a field missing from `props` makes `BlocSelector`/`Equatable` swallow the update (the sheet would not refresh when the cure changes via `OnQuestUpdated`; the Journal would not see a new `potionRecoveryUntil`). `QuestResult.toJson` must write `injuriesHealed` or the fixture round trip (`quest_result_test.dart:586-589`) fails for the heal fixture.

### Pitfall 4: `canHeal` count pin on the quest fragment
`loot_fragment_test.dart:59-61` counts `\bcanHeal\b` in `QuestFragment.fields` (= 1). The cure selection makes it 2: update the pin in the RED commit of the gated plan, otherwise the GREEN commit «fixes» an unrelated test.

### Pitfall 5: `unlockedLore }` pin on the status fragment
Appending `potionRecoveryUntil` after `unlockedLore` breaks `character_fragment_test.dart:94-98`. Insert after the `awaitingAid` block.

### Pitfall 6: Journal tests without the new providers
`pumpJournalPage` (`journal_harness.dart:89-115`) provides `CharacterCubit`, `SpellsCubit`, `CompanionCubit`, `ServerClockService` only. Once the «Oggetti» section reads `PotionCubit`, every test of `journal_items_test.dart` and `journal_spells_test.dart` throws `ProviderNotFoundException` until the harness provides an idle mock. Harness change and section change in the same commit.

### Pitfall 7: Timers alive at the end of a widget test
A countdown cubit with a live `Timer.periodic` provided with `BlocProvider.value` from the test is not closed with the tree → «A Timer is still pending even after the widget tree was disposed». Either let the section create it (`BlocProvider(create:)` closes it, as `SpellsSection` does) or `addTearDown(cubit.close)`. `pumpAndSettle` does not wait for timers, only for frames; with a future `potionRecoveryUntil` use `tester.pump(duration)` to cross a tick. The harness clock is `FakeServerClockService(spellFixtureNow)`: fixture dates must be relative to `spellFixtureNow`.

### Pitfall 8: The sheet lives on the root navigator
`showModalBottomSheet` mounts outside the shell providers (`authenticated_shell.dart:97-99`): `PotionCubit` must be passed with `BlocProvider.value`, and anything else (`CharacterCubit` for the max HP, `ServerClockService`) read before opening or passed the same way. Widget tests of the sheet pump it directly inside `PaperSheetModal`-free scaffolds (pattern of the abandon sheet tests).

### Pitfall 9: Optimistic temptation vs the stream
`UseItemResult.quantityLeft`/`hpAfter` arrive before or after `characterUpdated`. Showing them as state (decrementing the stack locally) creates a flicker when the stream confirms. Use the result only for the feedback face of the sheet; rows read `CharacterCubit`. Corollary: after a success the row may still be enabled for an instant until the stream brings `potionRecoveryUntil` → a second tap opens the sheet again; `PotionCubit.drink` must ignore a call while `PotionDrinking`, and the sheet should not reopen while `PotionDrunk` is shown (it is modal: fine).

### Pitfall 10: Banner dedup swallows the second refusal
`publishNotice` drops a notice whose `dedupKey` is still inside the display window (`in_app_notifications_cubit.dart:64-73`). Include the outcome `sequence` (or the `recoveryUntil` minute) in the key.

### Pitfall 11: `tool/hardening_check.sh` greps
(a) any `debugPrint(`/`print(`/`developer.log(` outside `lib/utils/app_log.dart` fails the CI → `appLog` only; (b) the credential grep looks at the 3 lines after every `appLog(` for an interpolation `$…token|bearer|jwt|authorization|password|secret` → a cubit that copies the `_token` naming of `CompanionCubit` must not interpolate it near a log call (simplest: no token field at all in `PotionCubit`, it is not optimistic); (c) nothing of this phase writes `SharedPreferences`.

### Pitfall 12: Clock skew and the «ready» edge
`ServerClockService` has zero offset until the first sync; a device clock ahead of the server re-enables the parchment early → the tap is allowed and the server refuses with `POTION_RECOVERING` + its date (D-12: exactly the designed behaviour — do not add a local guard). Remaining ≤ 0 → state «ready», never «pronta fra 0 min».

### Pitfall 13: Greps and tall-style formatting
Acceptance greps anchored to one identifier; the multi-line `ItemRow(...)` and `showModalBottomSheet(...)` calls reflow. Four touched-candidate files are formatter-dirty (see below): formatting them reflows untouched members (note it in the SUMMARY) — prefer not touching them.

### Pitfall 14: Pre-gate builds
Before the gated plan the branch runs against any BE (nothing new is selected): the heal parchments are never tappable (`recovery` absent → null) and the sheets show no cure rows. After the gated plan the branch works only against a BE with Phase 18 (Phase 17 D-14 lesson): say it in the SUMMARY of the gated plan.

## Code Examples

### Lenient cure (pattern `Pet.tryFromJson` / `_canHealFrom`, `loot_item.dart:91-97`)
```dart
static QuestCure? tryFromJson(Object? json) {
  if (json is! Map<String, dynamic>) return null;
  final share = json['lifePointsShare'];
  final canHeal = json['canHeal'];
  if (share is! num || !share.isFinite || share < 0 || share > 1) return null;
  if (canHeal is! List) return null;
  return QuestCure(
    lifePointsShare: share.toDouble(),
    canHeal: injuryTypesFrom(canHeal), // shared reader on asNameMap()
  );
}
```

### Viewer-filtered line (sibling of `healedInjuriesLine`, `item_lines.dart:57-65`)
```dart
String? curableInjuriesLine(QuestCure? cure, List<InjuryType>? characterInjuries) {
  if (cure == null || characterInjuries == null) return null;
  final labels = <String>{
    for (final injury in characterInjuries)
      if (cure.canHeal.contains(injury)) injury.label.toLowerCase(),
  };
  if (labels.isEmpty) return null;
  return 'Cura le tue ferite: ${labels.join(', ')}';
}
```

### Another extension key (sibling of `graphQlErrorCode`, `graphql_error_code.dart:17-38`)
```dart
Object? graphQlErrorExtension(OperationException? exception, String key) {
  if (exception == null) return null;
  final link = exception.linkException;
  final errors = [
    ...exception.graphqlErrors,
    if (link is ServerException) ...?link.parsedResponse?.errors,
  ];
  return errors
      .where((error) => error.extensions?['code'] is String)
      .map((error) => error.extensions?[key])
      .firstOrNull;
}
```

### Countdown refresh (pattern `SpellRecoveryCubit._refresh`, `spell_recovery_cubit.dart:53-64`)
```dart
void _refresh() {
  final until = _until;
  final remaining = until?.difference(_clock.now());
  final isRecovering = remaining != null && remaining > Duration.zero;
  emit(PotionRecoveryState(isRecovering ? remaining : null));
  if (!isRecovering) return _stopTimer();
  _timer ??= Timer.periodic(_tick, (_) => _refresh());
}
```

## State of the Art
| Old | New | Impact |
|-----|-----|--------|
| a won `heal` clears every injury and refills HP (BE 9 D-15) | `prizes.cure` on any quest (BE 18 D-01/D-07) | sheet rows keyed by `cure`; a heal may leave injuries |
| owned loot rows are display only (`journal.dart:267-272`) | heal parchments tappable with a recovery | first Journal mutation with a typed result |
| failures read `extensions.code` only | + one more extension key (`recoveryUntil`) | new shared reader |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `extensions.recoveryUntil` (ISO 8601 string) survives the BE error formatter in production, on the first coded error [CITED: BE `18-REPO-RULES.md` §Pozioni — «la ricerca conferma il punto esatto»] | F7 | the `POTION_RECOVERING` notice cannot show the server's remaining time → generic notice (OQ9); visible only in the device E2E |
| A2 | A `lifePointsShare` outside [0, 1] or non-finite is «malformed» → `cure` null [ASSUMED] | F1 | a BE value like 1.0000001 would hide both rows; alternative: clamp |
| A3 | `LootRecovery` with a missing `turns` or a negative `time` is malformed → null; `time == 0` → no «Ricarica» line and not tappable [ASSUMED from BE D-15 «senza `time` non si beve»] | F6, F9 | a zero-time potion at DB would look non-drinkable on the FE while the BE refuses it anyway (`ITEM_NOT_USABLE`) — consistent either way |
| A4 | `characterUpdated` re-emits after `useItem` in the same order of magnitude as the mutation answer (BE D-17 change stream) [CITED: BE CONTEXT D-17] | F5, Pitfall 9 | a late stream leaves the row enabled for a moment; a second tap gets `POTION_RECOVERING` (designed) |
| A5 | `UseItemResult.loreUnlocked` uses the same `Lore` shape as `QuestResult.loreUnlocked` (`id name type`) [CITED: REPO-RULES contract] | F7 | selection mismatch caught by the schema check in the gated plan |
| A6 | The BE allows `useItem` during an active travel and with a quest lane pending [CITED: BE D-17 «Consentita in città e in viaggio»] | F4 | a new refusal code would fall under the generic notice |

## Open Questions (RESOLVED)

All closed on 2026-11-10 in `18-CONTEXT.md`: questions 1, 4, 5, 6, 8, 9, 10 → D-19; question 2 → D-17; questions 3, 7 → D-18.

1. **OQ1 = C1 — where `recovery` is selected.** Verified: `simpleFields` does not feed shop/Journal. Recommendation: `LootFragment.fields` + `definition`. Needs the orchestrator's amendment of CONTEXT D-13 and REPO-RULES.
2. **OQ2 = C2 — the humaniser and the copy.** Verified: `formatGameDuration` → «1 h 30 min», «1 g». Decide (a) reuse as is, (b) hours-only variant, (c) literal copy. User-visible → user/orchestrator.
3. **OQ3 — banner title and the missing action labels.** New strings outside the fixed copy: a notice title (suggested «Pozione non bevuta»), the two confirmation actions (suggested «Bevi» / «Non ora»), the feedback close (existing «Continua»), an optional connection line (existing «Connessione assente, riprova» is used by the other notices; the REPO-RULES say «every other refusal → generic»). Orchestrator's go.
4. **OQ4 = C8 — injuries on the Map sheet.** Verified: `QuestInfoOverlay` has no viewer. Inference: without them a lane heal shows the life row but never the cure line. Recommendation: explicit `characterInjuries` input on the sheet, passed by Board and Map.
5. **OQ5 = C4/C5 — failure and notice shapes.** Date on `ItemUseException` (enum unchanged); add `timedOut` and `unauthenticated` (no notice for the latter, as everywhere); `potion_notice.dart` as a function file. Confirm or rule otherwise.
6. **OQ6 — is the `UseItem` document gated?** Verified: the CI runs no schema validation and the document is never sent before `recovery` is selected. Recommendation: document + registry (45 → 46) + service + repository in a NON-gated plan (the cubit and Journal plans need them), fragments in the gated plan, where `validate_documents.js` checks all 46. Conservative alternative: move the document and the 46 pins into the gated plan and test the repository against `MockKlimmeckGraphQl.useItem` only — but `KlimmeckGraphQl.useItem` cannot exist without the constant.
7. **OQ7 — confirmation surface.** `PaperSheetModal` bottom sheet (pattern abandon/travel) hosting confirmation and feedback (F5) vs an in-Journal overlay like the equipment/spell info sheet (`journal.dart:278-316`). Recommendation: the paper sheet. Device-reviewed either way.
8. **OQ8 — «Guarite: …» label case.** D-06 says «the same labels as the injury chips» (capitalised `label`); the quest-sheet and item lines are lowercase joined by commas. Recommendation: lowercase, one helper `healedLine` for the result sheet and the potion feedback.
9. **OQ9 — `POTION_RECOVERING` without a readable `recoveryUntil`.** Recommendation: generic notice (no local estimate); alternative: the character's own `potionRecoveryUntil` (also a server date).
10. **OQ10 — forcing the second-potion refusal in the E2E.** With a correct clock the parchments are disabled, so the FE never sends the second `useItem`. The UAT needs a trick (device clock forward, or `potionRecoveryUntil` awaited on a stale view): to be agreed with the BE handoff.

## Formatter state of the candidate files [VERIFIED: `dart format --output=none --set-exit-if-changed <file>`, one by one, 69 files]

**Dirty (4):** `lib/models/asset_item.dart`, `lib/shared/components/cards/loot_item_card.dart`, `lib/shared/components/section.dart`, `lib/screens/mainScreen/tabs/journal/components/injury_name_icon.dart`. None of them needs an edit in the recommended design (the disabled look wraps the card inside `ItemRow`; «Guarite» is plain text) — avoid touching them.

**Clean (65):** all four fragments, `character_mutations.dart`, `quest_prizes.dart`, `quest_sheet_details.dart`, `quest_viewer.dart`, `quest.dart`, `quest_result.dart`, `loot_item.dart`, `character_status.dart`, `injury_type.dart`, `lore.dart`, `item_lines.dart`, `game_duration_format.dart`, `utils.dart`, both sheets, `item_row.dart`, `hp_delta_bar.dart`, `dropdown.dart`, `paper_sheet_modal.dart`, `journal.dart`, `injury_chips.dart`, `board.dart`, `quest_info_overlay.dart`, `world_map.dart`, `authenticated_shell.dart`, `main_screen.dart`, `graphql.dart`, `graphql_error_code.dart`, `shop_modal.dart`, `transaction_modal.dart`, the two outcome listeners, `schema_check_documents.dart`, and every test/helper file listed in F13.

## F13. Pinned tests to update RED first [VERIFIED: codebase]

| File:line | Pin | Change | Plan |
|-----------|-----|--------|------|
| `test/graphql/loot_fragment_test.dart:59-61` | `canHeal` appears once in `QuestFragment.fields` | → 2 (or anchor to the loot blocks); new «the prizes select cure { lifePointsShare canHeal } (D-01)» | gated |
| `test/graphql/loot_fragment_test.dart:27-39` | `'effect power canHeal buyPrice {'` in `fields` and `definition` | unchanged if `recovery` goes after `sellPrice`; new «fields/definition select recovery { time turns } (D-13)», «simpleFields stay without recovery» | gated |
| `test/graphql/loot_fragment_test.dart:64-75` | the 5 full-loot documents select `canHeal` | add «select recovery» | gated |
| `test/graphql/character_fragment_test.dart:94-98` | `'… } unlockedLore }'` | unchanged if inserted after `awaitingAid`; new «statusFields selects potionRecoveryUntil (D-12)» | gated |
| `test/graphql/quest_result_documents_test.dart:33-47` | `'... on LootItem { id name itemType rarity description effect power }'` | unchanged (proves `simpleFields` untouched); new «selects injuriesHealed after injuriesAdded (D-02)» | gated |
| `test/graphql/board_documents_test.dart:85-86` | `contains('pet { id name }')` | unchanged; new `contains('pet { id name } cure { lifePointsShare canHeal }')` | gated |
| `test/tool/schema_check_documents_test.dart:32-34`, `test/graphql/shop_documents_test.dart:128`, `test/graphql/travel_documents_test.dart:178-179`, `test/graphql/loot_fragment_test.dart:86-88` | registry length 45 | → 46 with `UseItem` | plan of the document (OQ6) |
| `test/tool/schema_check_documents_test.dart:28-30` | registry keys == declared operations | forces document + registry in one commit | same |
| `test/helpers/fixtures/quest_result_fixtures.dart:71-142` | `questResultJson` shape | + `injuriesHealed` param (default `const []`), + `healResultJson()` | models |
| `test/models/quest_result/quest_result_test.dart:586-589` | `fromJson(toJson())` over the fixture map | add the heal fixture → proves `toJson` writes the field | models |
| `test/models/quest/quest_test.dart:218-240` | `prizes.pet` group | sibling group for `prizes.cure` (lenient cases, D-01) | models |
| `test/models/loot_item_test.dart:5-12, :45-66` | `_potion` helper, toJson/round trip/copyWith for `canHeal` | same trio for `recovery` | models |
| `test/models/character/character_status_test.dart:13-30` | `statusJson` helper | + `potionRecoveryUntil`; new group | models |
| `test/models/quest/quest_sheet_details_test.dart` (prizes cases :281-300) | details from prizes | new cases: cure line per injuries, life line per share, any quest type (D-03..D-05) | quest sheet |
| `test/shared/components/popup/quest_info_sheet_test.dart:62-75` | `_pump` signature | + injuries input; new cases per family (service heal, combat with cure, narrative with cure, heal without cure, no match → only life) | quest sheet |
| `test/shared/components/popup/quest_result_sheet_test.dart:76-126` | success content order | new «Guarite: … sits between the HP bar and the injuries (D-06)», hidden when empty | result sheet |
| `test/utils/item_lines_test.dart:164-200` | `healedInjuriesLine` group | four new groups | lines |
| `test/utils/game_duration_format_test.dart:6-19` | the 12 pinned cases | unchanged under OQ2 (a); new cases under (b) | lines |
| `test/shared/components/item_row_test.dart:97-130` | injuries line group | new «recovery line», «disabled», «status line» groups | item row |
| `test/helpers/journal_harness.dart:33-53, :89-115` | `journalCharacter`, `pumpJournalPage` | + status params (`injuries`, `potionRecoveryUntil`, `awaitingAid`), + potion cubit provider(s) | Journal |
| `test/screens/mainScreen/tabs/journal/journal_items_test.dart:131-212` | chips/filter behaviours | must stay green through the section extraction; new potion cases | Journal |
| `test/screens/auth/authenticated_shell_test.dart` | shell providers | add «provides PotionCubit» if the file lists providers (check at plan time) | cubit |

No golden-image tests exist in the repo for these widgets (text/tree assertions only).

## Suggested plan breakdown

**Non-gated (fixtures, fakes, mocks):**
1. **18-01 Quest cure models** — shared lenient injury reader (Boy Scout, three call sites), `QuestCure`, `QuestPrizes.cure`, `QuestResult.injuriesHealed`, fixtures (`questCureJson`, `injuriesHealed`, `healResultJson`). HEAL-01/02.
2. **18-02 Potion models** — `LootRecovery` + `LootItem.recovery`, `CharacterStatus.potionRecoveryUntil`, lenient lore-ref reader extracted, `UseItemResult`. HEAL-04/05.
3. **18-03 Lines** — `curableInjuriesLine`, `lifeShareLine`, `healedLine`, `recoveryLine`, countdown label, the humaniser per the OQ2 ruling. HEAL-01/02/05.
4. **18-04 Quest sheet** — `QuestSheetDetails` cure/life lines, `QuestInfoSheet` three families, injuries input from Board and Map (OQ4). HEAL-01.
5. **18-05 Result sheet** — «Guarite: …» between HP and injuries. HEAL-02.
6. **18-06 `useItem` plumbing** — `UseItem` document + registry 46, `KlimmeckGraphQl.useItem`, `graphQlErrorExtension`, `ItemUseFailure`/`ItemUseException`, `ItemUseRepository` (OQ5, OQ6). HEAL-04.
7. **18-07 Potion cubits and notices** — `PotionCubit`/state, `potion_notice.dart`, `PotionOutcomeListener` in `main_screen.dart`, shell provider, the countdown cubit, mocks. HEAL-04/05.
8. **18-08 Item rows** — `ItemRow` «Ricarica: …» line (shop + Journal), disabled state and status line. HEAL-05.
9. **18-09 Journal potion flow** — `ItemsSection` extracted from `journal.dart`, tappable heal parchments (travel yes, `awaitingAid` no, countdown disables), `PotionSheet` confirmation + feedback on parchment, harness update. HEAL-04/05.

**Gated on the BE Phase 18 merge:**
10. **18-10 Wire selection + schema gate** — the six `grep -cF`, the four fragment selections with their document tests (pins of F13), `dump_documents` 46 + `validate_documents.js` 46 × OK, full suite, analyzer, format, trailer grep. HEAL-03.
11. **18-11 Device E2E** — human checkpoint, `18-HUMAN-UAT.md`, FE `BACKEND-NOTES.md`, requirements closed. HEAL-03 (+ confirms 01/02/04/05).

Dependencies: 01 → 03 → 04, 05; 02 → 03, 06 → 07 → 09; 03 → 08 → 09; 10 after 01–09 and the BE merge; 11 last. Sequential execution (REPO-RULES).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK / `flutter test` / `flutter analyze` | all plans | ✓ | Flutter 3.35.5; analyzer 47 info, 0 error/warning | — |
| Node + BE `node_modules/graphql` | `validate_documents.js` (gated plan) | ✓ | Node v22.12.0 | — |
| BE `origin/develop` with Phase 18 (six names) | gated plans | ✗ (0/6 at `86095d89`) | — | park the gated plans (D-07) |
| BE `BACKEND-NOTES.md` (Phase 18) | UAT plan (example heals, identity, content runbook) | ✗ (not written yet) | — | read at the gate |
| Android device + local BE + player identity + content at DB | UAT plan | human checkpoint | — | — |

**Missing dependencies with no fallback:** none for the non-gated plans. **Missing with fallback (park):** the BE merge and its handoff for plans 18-10 and 18-11.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (Flutter 3.35.5) + `bloc_test ^10.0.0` + `mocktail ^1.0.5` + `fake_async ^1.3.3` |
| Config file | none beyond `pubspec.yaml` / `analysis_options.yaml`; helpers in `test/helpers/` (`test_app.dart`, `landscape.dart`, `svg_cache_seed.dart`, `mocks.dart`, `journal_harness.dart`, `fakes/fake_server_clock_service.dart`, `fixtures/`) |
| Quick run command | `flutter test <touched test files>` |
| Full suite command | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (foreground, gate plans only; ~3700 tests after Phase 12 per the project memory, Bash timeout ≥ 300 000 ms) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HEAL-01 | `QuestCure` lenient parse, toJson, copyWith, props | unit | `flutter test test/models/quest/quest_cure_test.dart` | ❌ Wave 0 |
| HEAL-01 | `QuestPrizes.cure` (malformed → null, quest stays) | unit | `flutter test test/models/quest/quest_test.dart` | ✅ (add group) |
| HEAL-01 | `curableInjuriesLine`, `lifeShareLine` | unit | `flutter test test/utils/item_lines_test.dart` | ✅ (add groups) |
| HEAL-01 | details carry the two lines for any type with a cure | unit | `flutter test test/models/quest/quest_sheet_details_test.dart` | ✅ (add cases) |
| HEAL-01 | rows in the three families, absent without cure / without match | widget | `flutter test test/shared/components/popup/quest_info_sheet_test.dart` | ✅ (add cases) |
| HEAL-02 | `injuriesHealed` lenient, round trip | unit | `flutter test test/models/quest_result/quest_result_test.dart` | ✅ (add group) |
| HEAL-02 | `healedLine`; «Guarite» between HP and injuries, hidden when empty | unit + widget | `flutter test test/utils/item_lines_test.dart test/shared/components/popup/quest_result_sheet_test.dart` | ✅ (add cases) |
| HEAL-03 | fragments select the new names; registry 46 | unit | `flutter test test/graphql test/tool/schema_check_documents_test.dart` | ✅ (pins of F13) |
| HEAL-03 | merged-schema validation 46 × OK | gate | `dump_documents.dart` + `validate_documents.js` | ✅ (gated plan) |
| HEAL-03 | device E2E, one heal per size | manual | `18-HUMAN-UAT.md` | ❌ (UAT plan) |
| HEAL-04 | `UseItemResult` parse | unit | `flutter test test/models/use_item_result_test.dart` | ❌ Wave 0 |
| HEAL-04 | another extension key on both error shapes | unit | `flutter test test/repository/services/graphql/graphql_error_code_test.dart` | check at plan time (❌ if absent) |
| HEAL-04 | failure mapping (five codes, `BAD_USER_INPUT`, connection, unknown, `recoveryUntil` carried) | unit | `flutter test test/repository/item_use_failure_test.dart` | ❌ Wave 0 |
| HEAL-04 | repository: sends the id, maps errors, timeout | unit | `flutter test test/repository/item_use_repository_test.dart` | ❌ Wave 0 |
| HEAL-04 | `PotionCubit` state sequences (success, each refusal, ignored while drinking, reset) | cubit | `flutter test test/screens/mainScreen/tabs/journal/potionCubit/potion_cubit_test.dart` | ❌ Wave 0 |
| HEAL-04 | notice copy per failure, remaining time from the server date | unit | `flutter test test/screens/mainScreen/tabs/journal/potionCubit/potion_notice_test.dart` | ❌ Wave 0 |
| HEAL-04 | listener publishes one banner per refusal, none on success | widget | `flutter test test/screens/mainScreen/components/potion_outcome_listener_test.dart` | ❌ Wave 0 |
| HEAL-04 | sheet: «Bevi <nome>?», confirm calls `drink`, disabled while drinking, feedback face (HP gain, «Guarite», lore line), closes on refusal | widget | `flutter test test/screens/mainScreen/tabs/journal/components/potion_sheet_test.dart` | ❌ Wave 0 |
| HEAL-04 | Journal: heal parchment with recovery tappable, others not; in travel yes; awaiting aid no | widget | `flutter test test/screens/mainScreen/tabs/journal/journal_items_test.dart` (or `sections/items_section_test.dart`) | ✅ / ❌ Wave 0 |
| HEAL-05 | `LootRecovery` + `LootItem.recovery`; `potionRecoveryUntil` | unit | `flutter test test/models/loot_recovery_test.dart test/models/loot_item_test.dart test/models/character/character_status_test.dart` | ❌ Wave 0 / ✅ / ✅ |
| HEAL-05 | `recoveryLine`, countdown label, humaniser | unit | `flutter test test/utils/item_lines_test.dart test/utils/game_duration_format_test.dart` | ✅ |
| HEAL-05 | `ItemRow` «Ricarica» line, disabled look, status line | widget | `flutter test test/shared/components/item_row_test.dart` | ✅ (add groups) |
| HEAL-05 | countdown cubit: ticks on the fake server clock, stops when ready, follows a new date, resync | cubit (`fakeAsync`) | `flutter test test/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_cubit_test.dart` | ❌ Wave 0 |
| HEAL-05 | Journal: future date → every heal parchment disabled with «pronta fra …», tap makes no call; date passed → enabled | widget | `flutter test test/screens/mainScreen/tabs/journal/journal_items_test.dart` | ✅ (add cases) |

### Sampling Rate
- **Per task commit:** the touched test files + repo-wide `flutter analyze --no-fatal-infos` (0 error / 0 warning, baseline 47 info) + trailer check.
- **Per plan:** the plan's test directories.
- **Phase gate:** full suite foreground, analyzer, format of the touched files one by one, trailer grep, schema check 46 × OK.

### Wave 0 Gaps
- [ ] `test/models/quest/quest_cure_test.dart`, `test/models/loot_recovery_test.dart`, `test/models/use_item_result_test.dart`
- [ ] `test/repository/item_use_failure_test.dart`, `test/repository/item_use_repository_test.dart` (+ the extension-key cases next to the existing `graphQlErrorCode` tests under `test/repository/services/`)
- [ ] `test/screens/mainScreen/tabs/journal/potionCubit/potion_cubit_test.dart`, `potion_notice_test.dart`
- [ ] `test/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_cubit_test.dart`
- [ ] `test/screens/mainScreen/tabs/journal/components/potion_sheet_test.dart`, `test/screens/mainScreen/tabs/journal/sections/items_section_test.dart` (if the section is extracted)
- [ ] `test/screens/mainScreen/components/potion_outcome_listener_test.dart`
- [ ] Fixtures: `questCureJson` (`quest_fixtures.dart`), `injuriesHealed` + `healResultJson` (`quest_result_fixtures.dart`), a `lootRecoveryJson` / heal-potion-with-recovery entry and `useItemResultJson` (new `test/helpers/fixtures/potion_fixtures.dart`), `journalCharacter` status params
- [ ] Mocks: `MockItemUseRepository`, `MockPotionCubit`, mock/idle countdown cubit in `test/helpers/mocks.dart`; idle helpers + providers in `journal_harness.dart`
- No framework install needed; `FakeServerClockService` already covers the clock.

### Manual-only
Device E2E (`18-HUMAN-UAT.md`): real cure by city size, the HP animation and banner timing on the phone, the countdown across app background/foreground (clock resync), the `POTION_RECOVERING` remaining time from the real BE, the lore page arriving in the Library — BE timing and content cannot be reproduced in widget tests.

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2/V3 Authentication/Session | no (unchanged; `UNAUTHENTICATED` on `useItem` is left to the session flow) | — |
| V4 Access Control | yes (ownership and recovery are BE-enforced on the bearer's character) | the FE sends only `itemId`; never a character id, never a time |
| V5 Input Validation | yes | lenient parsers that never throw (`QuestCure`, `LootRecovery`, `injuriesHealed`, `potionRecoveryUntil`, `UseItemResult` lists), strict numbers/dates on the mutation result mapped to `unknown` |
| V6 Cryptography | no | — |

| Threat | STRIDE | Mitigation |
|--------|--------|-----------|
| Device clock moved forward to drink during the recovery | Tampering | the countdown is display only; the BE compares its own date and answers `POTION_RECOVERING` (D-12) |
| Malformed cure / recovery / result crashing a sheet, the board or the Journal | DoS | `tryFromJson` boundaries, per-entry drop, tests for each malformed shape |
| Server error text shown to the player | Information disclosure | notices built from `extensions.code` only (pattern of every failure file); `ItemUseException.toString` prints the failure name |
| Double tap sending two `useItem` | Tampering / DoS | `PotionCubit` ignores `drink` while drinking; the BE write is atomic with the recovery filter (BE D-17) |
| Logging the mutation payload or ids near credential-like names | Information disclosure | `appLog` with the error `runtimeType` only; `tool/hardening_check.sh` credential grep (Pitfall 11) |

## Sources

### Primary (HIGH confidence)
- Codebase files cited by path:line (read this session at `3e76010`); probe `test/_probe_phase18_test.dart` (P1–P6, all green, deleted; `git status --short` back to ` M pubspec.lock`).
- `dart format --output=none --set-exit-if-changed` on 69 candidate files (read-only); `flutter analyze --no-fatal-infos` → 47 info, 0 error/warning.
- BE `origin/develop:src/schema.gql` at `86095d89` (read with `git show`, no fetch): the six gate names count 0; `type LootItem`, `QuestPrizes`, `CharacterStatus`; `src/gameRules/game-rule.exception.ts` (`extensions = { code }`).

### Secondary (MEDIUM confidence)
- BE `.planning/phases/18-quest-heal-per-taglia/18-CONTEXT.md` D-01..D-19 and `18-REPO-RULES.md` (contract names and codes, not merged).
- `.planning/phases/17-unlockable-lore/17-RESEARCH.md` F8 (gate and UAT shapes), project memory (suite size, device run notes).

### Tertiary (LOW confidence)
- None.

## Metadata
**Confidence breakdown:** integration points / pinned tests / formatter state HIGH (code read + tools); potion flow design MEDIUM-HIGH (assembled from three existing patterns, shape recommended, surface device-reviewed); BE contract MEDIUM (agreed, unmerged; `extensions.recoveryUntil` survival unverified, A1); copy MEDIUM until OQ2/OQ3 are ruled.
**Research date:** 2026-11-10 — **Valid until:** the BE Phase 18 merge (re-check the names and `BACKEND-NOTES.md` in the gated plan).

## RESEARCH COMPLETE
