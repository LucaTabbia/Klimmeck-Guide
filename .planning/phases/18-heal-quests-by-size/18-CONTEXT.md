# Phase 18: Heal Quests by City Size - Context

**Gathered:** 2026-11-09 (joint interactive discuss with the BE Phase 18, from this repo; branch `feat/18-heal-quests-by-size` from `develop` `ac75702`, the merge of PR #44, in a separate git worktree because the Phase 12 Hardening sits on `refactor/12-hardening` in the main working tree and the BE Phase 17 was being planned by another session)
**Amended:** 2026-11-09 evening, user decision («riprendiamo l'idea delle pozioni consumabili»): heal potions drunk from the Journal leave the stand-by with a **global recovery** (BE `LootItem.recovery { time, turns }`, `CharacterStatus.potionRecoveryUntil`, mutation `useItem`; D-11..D-15) and a new lore «Il limite del corpo» explains the rule in the world (D-16). Out of scope updated accordingly; scope S → M.
**Status:** Ready for planning — no UI phase, no UI-SPEC (every visual is provisional, user-reviewed on the device). **Planned now, executed after the Phase 12 Hardening merge** (user decision, D-08): the Phase 12 stops being «the last phase of v1.0», this one is. The plans that select the new contract names (`QuestPrizes.cure`, `QuestCure.lifePointsShare`, `QuestCure.canHeal`, `QuestResult.injuriesHealed`, `LootItem.recovery`, `CharacterStatus.potionRecoveryUntil`, `useItem` / `UseItemResult`) and the device E2E are **gated by the BE Phase 18 merge** on BE `develop` (pattern 13-10 / 14-10 / 15-08 / 16-07 / 17-09); every other plan runs before it on fixtures with the names fixed in the BE CONTEXT (`../Klimmeck-Guide-BE/.planning/phases/18-quest-heal-per-taglia/18-CONTEXT.md`) and its `18-REPO-RULES.md` (written at plan time, before the research).

<domain>
## Phase Boundary

Heal quests stop being all alike. Today a won `heal` removes every injury and refills the HP in any city (BE Phase 9 D-15) and the 166 fixed heals at DB are identical. From this phase every quest carries its cure as an explicit prize: `prizes.cure` with two independent dials, the share of the maximum HP the quest restores to (a ceiling) and the list of injuries it heals (`canHeal`, same name and meaning as on heal items). The backend applies the cure to every won quest that carries it; the content (lists by city size with lore touches by city type, HP share, hours, description) is written at DB by the orchestrator after the user's review. The frontend consumes the field: the quest sheet shows only the viewer's own injuries that this quest heals plus the life row; the result sheet lists the injuries actually healed. The frontend computes no game rule: intersecting the character's injuries with the quest's list is display filtering.

In the same phase the **heal potions are drunk from the Journal**: a tap on a heal parchment of the «Oggetti» section opens an in-world confirmation, the `useItem` mutation applies HP, injuries, stack and the **global recovery** owned by the backend (`CharacterStatus.potionRecoveryUntil`: one date per character, no potion of any kind until it has passed; 30 min for field herbs up to 24 h for the strongest), the Journal shows the gain, the injuries healed and the countdown «pronta fra …» from the server date; item rows show «Ricarica: 2 h» from `LootItem.recovery.time`. The first potion unlocks the lore «Il limite del corpo» (backend, via `LootItem.relatedLore`) and the Library shows it as any new page. Potions in combat are the user's engine (`recovery.turns` is data only, not shown).

Out of scope (user decisions of 2026-11-09): any change to travel food and HP (gradual hunger, progressive meals, hunger debt: «ci ripenseremo più avanti»), potions in combat (the user's engine), the recommended heal item on quest requirements, a severity table in the backend, the full cure list on the sheet, a per-size label.

</domain>

<decisions>
## Implementation Decisions

### Contract consumed (HEAL-01, HEAL-02, HEAL-03)
- **D-01 (BE Phase 18 D-01/D-02, user — «separare i danni guariti dalle ferite guarite»):** `QuestPrizes.cure: QuestCure` nullable with `lifePointsShare: Float!` (0..1, a ceiling on the maximum HP) and `canHeal: [InjuryType!]!`; the FE adds `cure { lifePointsShare canHeal }` to the shared `QuestFragment` and a `QuestCure` model inside `QuestPrizes` (`copyWith`, `toJson`, `props`). Parsing is lenient on the cure: an unknown injury name is dropped (`InjuryType.values.asNameMap()`, pattern of the quick 261109-inj2 tolerant reading), a malformed `cure` becomes null; the board's strict rules on type/title/slots (D-20 C6) are untouched. `null` = the quest heals nothing: no rows.
- **D-02 (BE Phase 18 D-08):** `QuestResult.injuriesHealed: [InjuryType!]!` (default empty) joins the result fragment next to the HP delta and the injuries added; lenient parsing (unknown names dropped, the result stays). Names are technical defaults to be fixed in the BE `18-REPO-RULES.md`.

### Quest sheet (HEAL-01)
- **D-03 (user, free text «Dice solo le tue ferite curabili», confirmed):** on the sheet of a quest with `cure` the cure line lists **only the current character's injuries that are in `canHeal`** («Cura le tue ferite: taglio profondo, contusione», Italian labels in lowercase as on the item line of the quick 261109-inj), in the order of the character's injuries; no count, never the full list; **no cure line at all when none of the character's injuries is in the list** (confirmed: «Nessuna riga di cura, solo la vita»). The intersection is computed on the FE from `CharacterStatus.injuries` and `cure.canHeal` for display only.
- **D-04 (technical default, stated in the question):** the **life row is always shown** when `cure` is present: «Vita: almeno il 50%» from `lifePointsShare` (percentage, no HP numbers; share 1 → «Vita: al massimo»; share 0 → row hidden, the quest heals injuries only). Copy at Claude's discretion, in-world, user-reviewed on the device.
- **D-05 (BE Phase 18 D-07, default stated in the question):** the rows are keyed by the presence of `cure`, not by `QuestType.heal`: a `story` or a `job` with `cure` shows them; a heal without `cure` shows nothing. The heal sheet keeps its announcement paper (`QuestPaperAsset`), the description (Phase 14 D-05) and the time line (`timeToComplete`, now 2 / 5 / 8 h by size: data only, nothing to change in the FE).

### Result sheet (HEAL-02)
- **D-06 (Claude, confirmed by the question text):** the result sheet shows «Guarite: <labels>» from `QuestResult.injuriesHealed` after the HP delta bar (gain animation already exists, `healGreen`) and before the injuries-added line; hidden when empty; the same labels as the injury chips.

### Gating, order, out of scope
- **D-07 (pattern 17-09/17-10):** the plans that select the new names on the wire and the device E2E are gated by the BE Phase 18 merge on BE `develop`; the device E2E seeds injuries on the test character and plays one heal per size (village: a listed and a non-listed injury → one healed, HP to 50%; city; capital: everything) with the three example quests from the BE handoff.
- **D-08 (user, «12 Hardening prima, poi la 18»):** execution after the Phase 12 Hardening merge on `develop` (and after the BE Phase 17 merge on BE `develop` for the BE side); the two branches live in parallel from `develop`; at the second merge `STATE.md`, `ROADMAP.md`, `REQUIREMENTS.md` and `PROJECT.md` are reconciled by hand (both phases add rows at the same places).
- **D-09 (user):** out of scope as listed in the boundary: Journal item use (stand-by; the BE primitive is born reusable), travel food (deferred), potions in combat, recommended loot.
- **D-10 (rule 4, restated):** no game rule on the FE: no severity, no «which tier» logic, no HP math beyond turning the share into a percentage for the copy.

### Journal potions (HEAL-04)
- **D-11 (user, «riprendiamo l'idea delle pozioni consumabili… Ogni oggetto heal ha un suo recoveryTime, come per le magie»; shape `recovery { time: int; turns: int }`):** in the Journal «Oggetti» section the parchments of heal items (`effect: heal`, `recovery` non-null) become tappable (`ItemRow.onSelect`, pattern of the equipment rows); the tap opens an **in-world confirmation on parchment** («Bevi <nome>?», no app chrome, rule 1), then a `JournalCubit`/dedicated cubit calls `useItem(itemId)` through a repository with its own failures (pattern `quest_abandon_repository.dart` / `quest_abandon_failure.dart`). On success the `UseItemResult` (`hpBefore`, `hpAfter`, `injuriesHealed`, `quantityLeft`, `recoveryUntil`, `loreUnlocked`) drives the feedback: `HpDeltaBar` gain animation, «Guarite: …» with the same labels as the result sheet, «Nuova pagina delle Conoscenze: <name>» when `loreUnlocked` is not empty (copy of the Phase 17 line); the character stream brings the new state (no refetch, rule 2). Refusals are notices on the parchment (pattern of the companion and spell notices): `POTION_RECOVERING` → «Il tuo corpo non reggerebbe un'altra pozione: pronta fra <remaining>» with the remaining time from `extensions.recoveryUntil` (never the local estimate), `ITEM_NO_EFFECT` → «Questa pozione non ti farebbe nulla adesso», `AWAITING_AID`/`ITEM_NOT_OWNED`/`ITEM_NOT_USABLE` → generic in-world notice. **Allowed in travel** (the Journal is open there), hidden while `awaitingAid` is set.
- **D-12 (technical default):** `CharacterStatus.potionRecoveryUntil` (nullable `DateTime`) joins the status selection and model; while it is in the future the heal parchments are shown disabled with a countdown «pronta fra 1 h 12 min» ticking from the server date against the local clock (pattern of the travel ETA), re-enabled when it passes; the tap during the countdown does nothing (no call). The backend is the judge: a refusal despite a finished countdown (clock skew) is shown as the `POTION_RECOVERING` notice with the server's remaining time.
- **D-13 (technical default):** item rows in the shop and in the Journal show «Ricarica: 2 h» (humanised from `recovery.time` ms: «30 min», «1 h 30», «24 h») under the «Cura: …» line of heal items; `recovery.turns` is not shown (combat engine, later). `LootFragment.simpleFields` gains `recovery { time turns }`; the `LootItem` model gets a nullable `LootRecovery` (lenient: malformed → null).
- **D-14 (BE D-16, user):** nothing of this touches combat on the FE: the result sheet of a fight keeps showing the consumables used as today.
- **D-15 (user, «il tempo minimo lo metterei a 30 minuti che può aumentare fino a 24 ore»):** the times live at DB (BE D-18 table: base by power, step by rarity, floors by the gravest injury cured); the FE never hard-codes them. The device E2E drinks a field herb (30 min) and shows the countdown, then tries a second potion → `POTION_RECOVERING` notice.

### Lore of the body's limit (HEAL-05)
- **D-16 (user, «aggiungiamo anche la creazione di una nuova lore che spieghi come mai le pozioni non si possono bere in sequenza»):** the backend writes a new `knowledge` lore («Il limite del corpo», text drafted in the review file and curated by the user at DB) linked from the 28 heal potions (`LootItem.relatedLore`) and unlocks it on the first potion drunk (BE D-19). The FE needs nothing new in the Library: the Phase 17 flow (`unlockedLore` change → refetch → «Nuovo» bookmark on the Conoscenze book) shows the page; the Journal shows the «Nuova pagina delle Conoscenze: …» line from `loreUnlocked` once. `LootItem.relatedLore` is not selected by the FE (not needed on the sheets).

### Claude's Discretion
- Exact copy of the rows («Cura le tue ferite: …», «Vita: almeno il N%», «Guarite: …», «Ricarica: …», «pronta fra …», the confirmation and the notices) and their place on the papers.
- Whether the potion feedback lives on the Journal parchment or in a small result overlay (device review); cubit split (reuse `JournalCubit` vs a `PotionCubit`).
- Helper name for the viewer-filtered cure line (sibling of `healedInjuriesLine` in `item_lines.dart`), model file names, fixture shapes.
- Whether the «Guarite» line reuses the injury chips or plain text (device review).

</decisions>

<canonical_refs>
## Canonical References

### BE contract (companion phase)
- `../Klimmeck-Guide-BE/.planning/phases/18-quest-heal-per-taglia/18-CONTEXT.md` — D-01..D-14 (`prizes.cure`, ceiling 50/80/100, lists ≤20/≤40/all + lore touches, hours 2/5/8, `injuriesHealed`, content script after the merge)
- `../Klimmeck-Guide-BE/.planning/phases/18-quest-heal-per-taglia/18-REPO-RULES.md` — contract names (written at BE plan time)
- `../Klimmeck-Guide-BE/.planning/phases/18-quest-heal-per-taglia/BACKEND-NOTES.md` — handoff with the three example quests and the test identity (after the BE phase)
- BE `18-CONTEXT.md` D-15..D-19 — `LootItem.recovery { time, turns }`, `CharacterStatus.potionRecoveryUntil`, `useItem` rules and codes (`ITEM_NOT_USABLE`, `POTION_RECOVERING`, `ITEM_NO_EFFECT`), times table, lore «Il limite del corpo» via `LootItem.relatedLore`

### Prior FE decisions carried forward
- `.planning/phases/06-quest-accept-info-sheets/` — per-type sheet layouts (QUEST-01), heal/study on the announcement paper
- `.planning/phases/09-combat-result-sheet/` — result parchment, `HpDeltaBar`, injuries line, `healGreen`
- `.planning/phases/14-quest-generation/14-CONTEXT.md` — D-05 announcement/description on the sheet
- `.planning/quick/261109-inj-loot-effected-injuries/` — `LootItem.canHeal` and the «Cura: …» item line (`healedInjuriesLine`), lowercase labels
- `.planning/quick/261109-inj2-new-injury-types/` — 37 `InjuryType` with labels and tolerant parsing

### Code
- `lib/graphql/fragments/quest_fragment.dart`, `lib/graphql/fragments/quest_result_fragment.dart` — single selection shared by list and subscription
- `lib/models/quest/quest_prizes.dart`, `lib/models/quest/quest.dart` — prizes model (`pet`, `spell` as additive examples), `tryFromJson` boundary
- `lib/models/enums/injury_type.dart` — labels (`InjuryTypeExtension.label`), severity (display only)
- `lib/utils/item_lines.dart` — `healedInjuriesLine(LootItem)` (pattern for the new viewer-filtered line)
- `lib/shared/components/popup/quest_info_sheet.dart`, `lib/shared/components/popup/quest_result_sheet.dart` — the two sheets
- `lib/shared/components/hp_delta_bar.dart`, `lib/screens/innkeeper/components/injury_chips.dart`, `lib/screens/mainScreen/tabs/journal/components/injury_name_icon.dart` — HP animation and injury visuals
- `lib/screens/mainScreen/tabs/journal/journal.dart` (`_buildOwnedItemsSection`, `_equipItem`), `lib/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart`, `lib/screens/mainScreen/tabs/journal/companionCubit/companion_notice.dart`, `lib/screens/mainScreen/tabs/journal/spellsCubit/spell_notice.dart` — Journal rows, equip call pattern, notices
- `lib/shared/components/item_row.dart` (`onSelect`, `onLongTap`), `lib/graphql/fragments/loot_fragment.dart`, `lib/models/loot_item.dart` — item rows and the loot selection/model (`recovery` joins them)
- `lib/repository/quest_abandon_repository.dart`, `lib/repository/quest_abandon_failure.dart` — repository + failure pattern for `useItem`
- `lib/models/character/` (status model with `injuries`, `awaitingAid`, `unlockedLore`) — `potionRecoveryUntil` joins the status
- `lib/screens/mainScreen/tabs/map/travelProgressCubit/` — server date vs local clock countdown pattern

### Rules
- `CLAUDE.md` rules 1, 2, 4 (no chrome, no blocking loading, backend as truth); `docs/rules/graphql.md`, `docs/rules/ui-ux.md`, `docs/rules/testing.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `healedInjuriesLine(LootItem)` + `InjuryTypeExtension.label`: the lowercase-label join to mirror for the viewer-filtered line.
- `QuestPrizes` additive fields (`pet` via `Pet.tryFromJson`): the same lenient style for `QuestCure`.
- `HpDeltaBar(isGain)` and the result sheet lines («Magia appresa», «Conoscenza appresa», Phase 17): insertion point for «Guarite: …».
- `QuestPaperAsset`: heal already on the announcement sheet; no asset work.
- `ItemRow.onSelect` + the Journal equip flow (`_equipItem` → `JournalCubit.equipItem` → GraphQL): the same path for the potion tap and the confirmation.
- Companion/spell notices in the Journal: the surface for the potion refusals and the lore line.
- Travel ETA countdown (server date, local tick): the «pronta fra …» countdown.

### Established Patterns
- One fragment per entity shared by query and subscription; `tryFromJson` boundary drops only the malformed quest.
- Tolerant enum parsing with `asNameMap()` (quick 261109-inj2, Phase 17 `LoreType`).
- Gated plans with a schema gate (`grep -cF` of the names on the merged BE SDL) before the device E2E.

### Integration Points
- `QuestInfoSheet` per-type layout: the cure rows join the heal variant and any quest whose `prizes.cure` is non-null.
- `QuestResultSheet`: new line from `injuriesHealed`.
- `CharacterCubit` state: `status.injuries` already available for the intersection; `status.potionRecoveryUntil` for the countdown and the disabled parchments.
- Journal «Oggetti» section: tap, confirmation, mutation, feedback; shop and Journal `ItemRow`: «Ricarica: …» line.

</code_context>

<specifics>
## Specific Ideas

- User verbatim: «Secondo me dovremmo separare i danni guariti dalle ferite guarite. Così un posto può guarire determinati tipi di ferite e altri un altro. Le quest heal restano gratuite.»; «Variamo le ore richieste per taglia»; «Dice solo le tue ferite curabili».
- Discuss data (read-only DB, 2026-11-09): 166 open heals all on the city marker (98 village / 59 city / 9 capital), identical (rookie, free, 5 h, no prize); 37 injuries, 28 heal items with `canHeal`; 6 characters, 3 with injuries.
- Lists by size (BE D-03/D-04): village = 19 injuries of severity ≤ 20, city = 28 (≤ 40), capital = all 37; lore touches: mountain/north villages + frostbite, hypothermia; desert + severeBurn, exhaustion; tropical + infection, poisonInjection; sea cities + hypothermia, infection.

</specifics>

<deferred>
## Deferred Ideas

- **Potions in combat** (`recovery.turns`): the user's engine; nothing on the FE in this phase.
- **Turns shown on the item rows**: later, with the combat engine.
- **Travel food**: gradual HP per kilometre, meals eaten only when needed, hunger debt: deferred by the user; the travel stays as Phase 15 shipped it.
- **Per-size cure label** («Cure leggere» …) and the full list on the sheet: rejected options, kept here for the record.

</deferred>

---

*Phase: 18-heal-quests-by-size*
*Context gathered: 2026-11-09*
