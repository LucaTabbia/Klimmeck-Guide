# Phase 23: Spell Origins, Void and Shamanic Quests - Research

**Researched:** 2026-11-15
**Domain:** Flutter models, enums and GraphQL selections over a backend-owned classification (BE Phase 24 «Origini delle magie, quest void e shamanic»): spell origin, minimum level instead of minimum xp, two quest types, three city types, eight (+3) Cloudinary assets
**Confidence:** HIGH for code facts (file:line read this session on `feat/23-spell-origins-void-and-shamanic-quests` at `92cc07a9`, CONTEXT as amended in `07321fc8`; 44 candidate files checked one by one with `dart format --output=none --set-exit-if-changed`; a Dart probe run outside the repo; the 55 registered documents dumped and validated against two BE SDLs; `flutter analyze` → 47 issues; `git status --short` empty afterwards). MEDIUM for the wire (BE Phase 24 has only its CONTEXT, branch `feat/24-origini-magie-quest-void-shamanic` at `7544aa8b`: every new name below is a proposal, **BE to confirm**). One finding is INFERRED, not observed (F-4: the `cities` query on today's BE) because this research may not start the BE.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Copied by reference, authoritative text in `23-CONTEXT.md` §Implementation Decisions (do not paraphrase in plans):
- **Carried forward:** backend is the source of truth (rule 4), no app chrome on gameplay (rule 1), no blocking loading in session (rule 2); the world lives only in the DB (no content file in either repo, one-off migrators leave the repo); non-additive SDL changes declared in the BE handoff and the FE plans that select new fields gated on the BE merge (schema check on the merged SDL); assets with `feColorMatrix` masks flattened with headless Chrome, uploaded by the user, ids wired in TDD in `lib/config/cloudinary_assets.dart`.
- **D-01** every spell carries an origin; order origin → use → energy; wire values `void`, `arcane`, `shamanic` (BE enum next to `UseType`). Amended 2026-11-15: the origin is `arcane`, not `magic`; the quest type keeps its name `magic` and teaches the `arcane` origin.
- **D-02 / D-03** the DB is reviewed (96 spells) and filled to about 30 spells per `void` / `shamanic` origin by the orchestrator after the user's review (no FE work).
- **D-04** the origin has no effect on combat, on who can learn a spell or on the slots.
- **D-05** the app shows the origin with an **icon**, like use and energy. The three icons arrived on 2026-11-15 (`arcaneOrigin`, `shamanicOrigin`, `voidOrigin`, flattened at 1000 px into `~/Downloads/<name>_flat.svg`); the UI plan needs only their Cloudinary ids.
- **D-06** Italian names: «Arcana» (`arcane`), «Sciamanica» (`shamanic`), «Vuoto» (`void`).
- **D-07** `minXpToLearn` replaced by a minimum level (name fixed in the plan, e.g. `minLevelToLearn`); non-additive SDL change.
- **D-08** every reader moves to the level, the FE line of `lib/utils/spell_lines.dart` included; the app never computes a level, compares nothing, only prints the level the backend sends.
- **D-09** quest types `shamanic` and `void` work exactly like `magic`: same lane, same acceptance (no registration), same duration model, same study-lore pool, same spell draw.
- **D-10** each of the three types teaches only its own origin (BE): `magic` → `arcane`, `shamanic` → `shamanic`, `void` → `void`.
- **D-11** `void` only in Necrorian; `shamanic` in Murnborim and Thengran, from rank mage up (DB quests).
- **D-12** no Necrorian quest below mage (BE generator).
- **D-13** Italian names of the quest types: «Magia» stays, «Rito sciamanico», «Rito del Vuoto».
- **D-14** sheet assets `voidSheet` / `tornVoidSheet`, `shamanicSheet` / `tornShamanicSheet`, used exactly where `magicSheet` / `magicTornSheet` are used (`lib/models/quest/quest_paper_asset.dart`).
- **D-15** city types already at DB: Murnborim → `aarakocraCapital`, Thengran → `dragonbornCapital`, Veg Faldir → `dragonbornVillage`.
- **D-16** the two capitals have size `capital` (BE); FE marker size 39 like Talmvere; `dragonbornVillage` 30 like `aarakocraVillage`.
- **D-17** three new city assets; the `aarakocraVillage` asset is replaced.
- **D-18** home cities of dragonborn and aarakocra move to their capitals (BE, new characters only).
- **D-19** eight flattened files in `~/Downloads/<name>_flat.svg`; the user uploads them and gives the ids.

### Claude's Discretion
Wire shape and field names, where the origin sits in the BE model, how the generator recognises «a quest of Necrorian», the migrator (xp → level, origin default), the placement of the origin icon next to use and energy, final copy.

### Deferred Ideas (OUT OF SCOPE)
- Effects of the origin on combat or on who may learn a spell.
- `shamanic`/`void` quests in other cities.
</user_constraints>

<phase_requirements>
## Phase Requirements

ROADMAP §Phase 23 carries no requirement IDs and `REQUIREMENTS.md` stops at PET-10 (`SPELL-01..09` is taken by Phase 8). Proposed IDs, to be added to `REQUIREMENTS.md` + traceability by the first plan before any plan references them (`gsd-tools requirements mark-complete` fails on unknown IDs):

| ID (proposed) | Description | Decisions | Research Support |
|----|-------------|-----------|------------------|
| ORIGIN-01 | `SpellOrigin` (wire `void` / `arcane` / `shamanic`, labels «Vuoto» / «Arcana» / «Sciamanica») parsed leniently on `Spell.origin`; unknown or absent → null, the spell stays | D-01, D-04, D-06 | F-1 |
| ORIGIN-02 | A spell prints the minimum **level** the backend sends («Per impararla: Livello N · … di studio»); `minXpToLearn` leaves the model, the fragments and the copy; the app compares nothing | D-07, D-08 | F-2 |
| ORIGIN-03 | Quest types `shamanic` and `void` behave on the FE exactly like `magic` (standard lane, repeatable, unregistered, service sheet, «Studiando…», torn until the rank) with labels «Rito sciamanico» / «Rito del Vuoto» and their own whole and torn sheets; the wire value `void` is read through an explicit wire name | D-09, D-13, D-14 | F-3 |
| ORIGIN-04 | City types `aarakocraCapital`, `dragonbornCapital` (marker 39) and `dragonbornVillage` (marker 30) parse and draw; visibility by the served size; `aarakocraVillage` drawn with the new file | D-15, D-16, D-17 | F-4, F-5 |
| ORIGIN-05 | The origin icon sits before the use and energy icons wherever a spell is drawn with icons (spell card, spell details) | D-05 | F-1 (drawing sites) |
| ORIGIN-06 | Schema gate on the merged BE Phase 24 SDL (`origin` and the level selected, registry count, schema check, full suite) and device E2E | all | F-6, Validation |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Clean Code, SoC (models Flutter-free, UI no networking), **TDD red → green → refactor**, Boy Scout rule within scope.
- Rule 1 — no app chrome on gameplay: Journal, Board, Map, quest sheets, spell details are gameplay. Rule 2 — no blocking loading in session: nothing in this phase adds a loader. Rule 3 — branch `feat/23-spell-origins-void-and-shamanic-quests`, PR → `develop` (the branch is stacked on `feat/22-…`). Rule 4 — backend is the source of truth: the FE never compares a level, never filters a spell pool, never derives an origin, never decides where a quest type lives. Rule 5 — no secrets in repo.
- `docs/rules/graphql.md`: documents only in `lib/graphql/**`, fragments for fields reused in ≥ 2 operations. `docs/rules/assets.md`: domain SVG through `CachedSvg`, ids only in `lib/config/cloudinary_assets.dart`, never raw URLs in widgets. `docs/rules/naming.md`: enum values `lowerCamelCase`. `docs/rules/testing.md`: model tests first, fixtures in `test/helpers/fixtures/`. `docs/rules/ui-ux.md`: theme tokens only, no inline `TextStyle`.
- Repo practice (as `22-REPO-RULES.md`; **`23-REPO-RULES.md` does not exist yet**): sequential plans on the main tree, `dart format` per touched file only (never a directory), analyzer gate **47 info / 0 warning / 0 error** [VERIFIED: `flutter analyze --no-fatal-infos` this session → «47 issues found»], full suite only in the gate plan (last recorded count in the Phase 22 docs: 5041 [VERIFIED: grep of the Phase 22 summaries, not re-run]), no commit trailers, scope `phase-23`, BE read-only, registry **55** documents [VERIFIED: `dart run tool/schema_check/dump_documents.dart` → «dumped 55 documents»; pin `test/tool/schema_check_documents_test.dart:34`].

## Summary

**(1) `void` is a reserved word in Dart: neither `SpellOrigin.void` nor `QuestType.void` can exist.** [VERIFIED: probe of an enum with a value named `void` → `dart analyze`: «Expected an identifier» (Dart 3.9.2).] Every `QuestType` crossing of the wire today goes through the Dart **name**: `QuestType.values.byName(json["type"])` (`quest_infos.dart:34`), `asNameMap()` (`pending_request.dart:31`, `mission_draft.dart:116`, `quest_result_quest.dart:21`), `type?.name` in `toJson` (`quest_infos.dart:49`, `quest_result_quest.dart:28`), and tests pin `QuestType.values.byName('magic')` (`quest_type_test.dart:23`). The first plan must therefore give `QuestType` an explicit wire boundary (`wireName` + `fromWire`) before the value for `void` can be added, and `SpellOrigin` is born with it. Recommended Dart name for the wire value `void`: **`theVoid`** in both enums (O-1).

**(2) The level change can be made live-safe on this branch by removing before adding.** `minXpToLearn` is selected in exactly one place, `SpellFragment.fields` (`spell_fragment.dart:38`), which reaches the wire only through `CharacterFragment` (`character_fragment.dart:64` spell states; `:75`, `:81` via `EquipmentFragment.fieldsWithFullSpell`, `equipment_fragment.dart:78-80`) → two registered documents, `character` and `characterUpdated` [VERIFIED: grep of the 55 dumped documents]. Selecting the old field after the BE merge, or the new one before, invalidates both documents and the app loses its character. The only FE reader is one line of copy (`spell_lines.dart:65-75`); **the app filters nothing by xp** [VERIFIED: grep `minXpToLearn` in `lib/` → model, fragment, `spell_lines.dart` only; the innkeeper prize list is `MissionPrizeOptions.spells` served already filtered, BE `mission-prizes.ts:121-124`]. So: a pre-gate plan drops `minXpToLearn` from the fragment, the model and the copy (valid against today's SDL **and** the merged one), and the gate plan only **adds** `minLevelToLearn` and `origin`. The whole branch then never depends on the merge order.

**(3) Quest types are plain strings on the wire; city types are a GraphQL enum.** `QuestInfos.type: String!`, `Spell.useType: String!` (BE SDL), so `shamanic`/`void` need no SDL change and the whole FE quest work is pre-gate. `City.type: CityType!` and `City.size: CitySize!` are non-null and `cities: [City!]!`; the SDL enum has 33 values without the three new ones [VERIFIED: `git -C <BE> show origin/develop:src/schema.gql`, same on `fix/23-dungeon-xp-and-innkeeper-corrections`]. See (4).

**(4) Today the three cities do not reach the app at all — and they very probably take every other city with them.** On the FE an unknown city type is *dropped*, not a crash: `City.fromJson` is strict (`city.dart:35` `byName`), `City.tryFromJson` returns null (`city.dart:58-67`) and `getCities` skips it with a log (`graphql.dart:468-470`), pinned by `city_test.dart:50, :60`. But the value never gets that far: on today's BE the resolver returns the DB document as is (`cities.service.ts` `find()`; `cities.resolver.ts` `size` → `citySizeOf(city.type)` → `undefined`), so both `type` (enum cannot represent `aarakocraCapital`) and `size` (null for a non-null field) error, and with `[City!]!` the error propagates to `data: null` for the **whole** `cities` query → `getCities` throws (`graphql.dart:457-461`). [INFERRED from the SDL nullability + graphql-js enum serialisation; not observed: the BE was not started. One GraphQL probe by the orchestrator settles it.] Consequence if confirmed: any BE running `develop` against the current DB shows a Map without cities (and no current city for Board and shop) until the BE knows the three types. This is a BE-side urgency (O-3), not an FE task; the FE side is three enum values, which can be added today.

**(5) The origin icon has two homes, and five drawing sites share them.** Only `SpellCard` (`spell_card.dart:47-63`, use + energy icons in one `Row`) and `SpellInfo` (`spell_info.dart:37-43`, energy icon beside the name, use icon beside «Uso: …») draw spell icons. Every place a spell is shown with icons goes through one of them: Journal slots (`spell_slot_row.dart:70`), Journal known spells (`known_spell_row.dart:50`), the long-press details (`spell_info_sheet.dart:30-31`), «Magia infusa» on the equipment details (`equipment_info_sheet.dart:325`), the innkeeper prize rows and catalogue (`prizes_step.dart:481`, `prize_catalogue_sheet.dart:149`). The result sheet prints text only («Magia appresa: …», `quest_result_sheet.dart:518-521`; used spells `:371-377`); the quest sheet shows no spell (`prizes.spell` is not selected, `quest_fragment.dart:66-104`); **enemy sheets draw no spell** (`Enemy.spells` is parsed, `enemy.dart:44`, and never read by a widget; the quest fragment selects no enemy spells, `quest_fragment.dart:25-34`). Three icons at today's `size / 2.5` do not fit a card (3 × 0.4 = 1.2 × width): the icon size must shrink when the origin is present.

**Primary recommendation:** eight sequential plans — five pre-gate against today's BE (wire boundary of `QuestType`; spell model with origin and level, old field dropped; the two quest types; the three city types; asset ids), one waiting for the three icon ids (origin drawing), two gated on the BE Phase 24 merge (schema gate + selections; device E2E + closing). New constants are born pointing at the closest existing drawing so that only **one small plan** waits for the uploaded ids.

## Standard Stack (all already in `pubspec.yaml`, no new dependency)

| Library | Use in this phase | Source |
|---------|-------------------|--------|
| `equatable` | `Spell.props` with `origin`, `minLevelToLearn` | [VERIFIED: codebase `spell.dart:77-88`] |
| `flutter_test` / `bloc_test` / `mocktail` | model, enum, line and widget tests; no new Cubit in this phase | [VERIFIED: codebase] |
| `CachedSvg` + `seedSvgCache` | origin icon, new sheets and markers in widget tests (`test/helpers/svg_cache_seed.dart:7-16`) | [VERIFIED: codebase] |
| `graphql_flutter` via `KlimmeckGraphQl` | no new operation; three selections change at the gate | [VERIFIED: codebase] |
| Node v22.12.0 + BE `node_modules/graphql` | `tool/schema_check/validate_documents.js` | [VERIFIED: run this session] |

No package is installed in this phase, so no registry version check applies.

## Architecture Patterns

### Recommended files
```
lib/models/enums/spell_origin.dart          # NEW beside use_type.dart: theVoid('void'), arcane('arcane'), shamanic('shamanic'); label; fromWire; imageId added by the icon plan
lib/models/enums/quest_type.dart            # + wireName / fromWire (refactor), then shamanic, theVoid('void'); labels
lib/models/spell.dart                       # + origin (lenient), minLevelToLearn (lenient) ; − minXpToLearn
lib/utils/spell_lines.dart                  # spellLearnLabel prints «Livello N»; + spellOriginLabel
lib/graphql/fragments/spell_fragment.dart   # − minXpToLearn (pre-gate); + origin, minLevelToLearn (gate); dead `definition` removed
lib/graphql/fragments/equipment_fragment.dart  # addedSpell { … origin } in `fields` (gate)
lib/models/quest/quest_infos.dart, pending_request/pending_request.dart, mission/mission_draft.dart, quest_result/quest_result_quest.dart   # parse through QuestType.fromWire, write wireName
lib/models/quest/quest_paper_asset.dart     # two branches beside QuestType.magic
lib/models/quest/quest_state_label.dart, lib/utils/mission_lines.dart   # «Studiando…» for the two types
lib/models/enums/city_type.dart             # three values
lib/config/cloudinary_assets.dart           # voidSheet, tornVoidSheet, shamanicSheet, tornShamanicSheet, aarakocraCapital, dragonbornCapital, dragonbornVillage; aarakocraVillage re-pointed; later arcaneOrigin, shamanicOrigin, voidOrigin icons
lib/shared/components/cards/spell_card.dart, lib/shared/components/spell_info.dart   # origin icon first (icon plan)
```

### F-1. Spell origin [VERIFIED: codebase + SDL]

| Item | File:line | Note |
|------|-----------|------|
| Model | `spell.dart:6-89` — `useType` parsed `UseType.values.asNameMap()[json['useType']]` (`:33`, lenient: unknown → null, pinned by `use_type_test.dart` «an unknown use type parses as null») | `origin: SpellOrigin.fromWire(json['origin'])`; add to ctor, `toJson`, `copyWith`, `props` |
| Enum pattern | `use_type.dart:3-21`, `energy_type.dart:3-22` — value carries `imageId` + `label`, `imagePath => CloudinaryAssets.url(_imageId)` | `SpellOrigin` follows it, but **cannot** use `asNameMap` for `void` (Summary 1): explicit `wireName` |
| SDL today | `type Spell { description energyDamage id maxUsages minXpToLearn name recoveryTime requiredLearnTime useType: String! }` | proposal `origin: String!` (W-1) |
| Selections of a spell | `SpellFragment.fields` (`spell_fragment.dart:32-45`) → character spell states and owned/worn `addedSpell`; `SpellFragment.simpleFields` (`:22-30`) → `GetMissionDraft` prize block and `GetMissionPrizeOptions` (`mission_queries.dart:62-63, :79-80`); inline `addedSpell { id name useType energyDamage { type power } }` in `EquipmentFragment.fields` (`equipment_fragment.dart:31-38`) → shop, equipment queries, `character_queries.dart:27`; `spellLearned { id name }` and `spellsUsed { usages spell { id name } }` (`quest_result_fragment.dart:58-63, :105-108`) | `origin` goes into `fields`, `simpleFields` and the inline `addedSpell` (the three feed a `SpellCard`); the result fragment stays text-only (no icon there) |
| Dead code | `SpellFragment.definition` / `name` (`spell_fragment.dart:4-20`) is referenced nowhere (grep `SpellFragment\.` → only `fields` and `simpleFields`) and still lists `minXpToLearn` | delete it in the plan that drops the old field (Boy Scout; `spell_fragment.dart` is **not formatter-clean** → `style(graphql)` commit first) |

**Drawing sites (where the origin icon lands, all through two widgets):**

| Place | File:line | Widget | Fed by |
|-------|-----------|--------|--------|
| Journal slot | `spell_slot_row.dart:70` | `SpellCard` | `SpellFragment.fields` |
| Journal known spells | `known_spell_row.dart:50` | `SpellCard` | `SpellFragment.fields` |
| Spell details (long press) | `spell_info_sheet.dart:30-31` (opened at `spells_section.dart:204`) | `SpellCard` + `SpellInfo` | `SpellFragment.fields` |
| Equipment details «Magia infusa» | `equipment_info_sheet.dart:325` | `SpellCard` | `fieldsWithFullSpell` (Journal) / inline `addedSpell` (shop) |
| Innkeeper prize row | `prizes_step.dart:481` | `SpellCard` | `simpleFields` |
| Innkeeper prize catalogue | `prize_catalogue_sheet.dart:149` | `SpellCard` | `simpleFields` |
| Journal use filter | `spellbook_content.dart:63-67` | `ItemsFilter<UseType>` | — (an origin filter is not in the decisions: O-5) |
| Result sheet | `quest_result_sheet.dart:371-377, :518-521` | text | no icon; unchanged |
| Enemy sheets | — | none | no spell drawn today |

**Placement (Claude's discretion, provisional — no UI phase):**
- `SpellCard`: the icon `Row` (`spell_card.dart:47-63`) becomes origin → use → energy. With the origin present the three icons take `size / 3.2` each; without it the row keeps today's `size / 2.5` (a spell with a null origin renders exactly as today, so every existing card test stays green and the pre-gate app is unchanged).
- `SpellInfo`: a new first detail row `_iconRow(iconUrl: origin.imagePath, child: _line('Origine: Arcana'))` placed **before** the use row (`spell_info.dart:42-43`); the title row keeps the energy icon. Copy through a new `spellOriginLabel(SpellOrigin?)` in `spell_lines.dart` (all spell strings live there, `spell_lines.dart:7`).
- Until the three icon ids arrive (D-05: the files are flattened, the upload is pending) nothing draws the origin: the enum is born **without** `imageId`; the icon plan adds the three ids together with the widgets. The origin `arcane` and the quest type `magic` are different names on purpose: no code may map one to the other (the BE owns which quest teaches which origin).

### F-2. Minimum level instead of minimum xp [VERIFIED: codebase + SDL + BE read]

- **Every FE usage:** `spell.dart:14, :25, :36, :47, :60, :71, :85`; `spell_fragment.dart:13` (dead `definition`), `:38` (`fields`); `spell_lines.dart:66-69` («Per impararla: 100 XP · 1 h di studio»). Tests: `test/utils/spell_lines_test.dart:184-199`, `test/shared/components/spell_info_test.dart:22`, `test/helpers/fixtures/spell_fixtures.dart:17, :26`, raw payloads in `test/graphql/character_fragment_test.dart:331, :347`. The fragment pin `character_fragment_test.dart:57-70, :162` compares against `SpellFragment.fields` itself, so it follows the fragment without edits.
- **The app does not compute:** no comparison with the character's xp or level anywhere in `lib/` (grep). The BE filters: spell draw `resolution-loader.service.ts:167-187, :677`, innkeeper options `mission-prize-options.service.ts:138-148`, `mission-prizes.ts:121-124`, `chosen-rewards.ts:42`. No refusal code about xp or level is mapped on the FE (`spell_equip_failure.dart:7-10` holds the only spell codes).
- **Transition (non-additive):**

| Step | Plan | `SpellFragment.fields` | Valid on today's SDL | Valid on the merged SDL |
|------|------|------------------------|----------------------|-------------------------|
| today | — | `… minXpToLearn …` | yes | **no** → character lost |
| pre-gate | 23-02 | field removed | yes | yes |
| gate | 23-07 | `+ origin + minLevelToLearn` | no | yes |

  The model reads the new key from the start: `minLevelToLearn: (json['minLevelToLearn'] as num?)?.toInt()` (same lenient shape as `:35-38`), null while unselected. Pre-gate the learn line reads «Per impararla: 1 h di studio» (the xp part disappears a few plans early — acceptable on a development branch; the number is meaningless after D-07).
- **Copy:** `spellLearnLabel` → «Per impararla: Livello 6 · 1 h di studio»; a null or non-positive level prints no level part. Never «ti manca …», never a comparison with the character's level (D-08).

### F-3. Quest types `shamanic` and `void` [VERIFIED: codebase]

Precedent: quick task `261110-mag` added `magic` in two commits (`6546d9d5` tests, `f9b742ef` code: `cloudinary_assets.dart`, `quest_type.dart`, `quest_paper_asset.dart`, `quest_state_label.dart`, `quest_lane_test.dart`). «Exactly like magic» on the FE means, site by site:

| Site | File:line | Kind | What magic does | Action for the two types |
|------|-----------|------|-----------------|--------------------------|
| Enum + label | `quest_type.dart:3-41` | exhaustive `switch` (compile error = natural RED) | pawn `imageId: ''`, label «Magia» | values with `imageId: ''`; labels «Rito sciamanico», «Rito del Vuoto» |
| Sheet asset | `quest_paper_asset.dart:77-80` | exhaustive `switch` | `[magicSheet]` / `[magicTornSheet]` (one variant each) | `[shamanicSheet]` / `[tornShamanicSheet]`, `[voidSheet]` / `[tornVoidSheet]`; consumed by the Board (`sheet.dart:37`) and the Map paper (`quest_paper_layer.dart:63`) |
| Activity above the pawn | `mission_lines.dart:10-21` | exhaustive `switch` | «Studiando…» with `study` | join the `study || magic` arm |
| State label on the Map sheet | `quest_state_label.dart:10-19` | **`_ =>` default** («In corso…») | «Studiando…» | **silent miss**: must be added by hand to the `study || magic` arm (Pitfall 3) |
| Sheet family | `quest_sheet_details.dart:26-34` | default → `service` | service | nothing (test list `quest_sheet_details_test.dart:41` gains the two values) |
| Lane | `quest_lane.dart:7-11` | default → `standard` | standard | nothing (assert in tests) |
| Registration / repeatability | `quest_lane.dart:14-28` | sets | in neither set | nothing (assert in tests, as `quest_availability_test.dart:108-116`) |
| Title rule | `quest_availability.dart:51-61` | `story` exact, others `>=` | «Serve almeno il titolo Mago» (`quest_blocked_reason.dart:32-36`), «Titolo minimo: …» (`quest_sheet_details.dart:183-188`) | nothing |
| Board listing | `board_policy.dart:25-39` | default → by city | listed in its city, torn until the rank (`board_test.dart:299-318`) | nothing (mirror the board test) |
| Single-player / slots | `quest_capacity.dart:12` | `enemy` only | — | nothing |
| Busy-lane notice | `quest_acceptance_notice.dart:33-36` | default | «Hai già una missione in corso» | nothing |
| Map quest marker | `quest_markers_layer.dart:41-49, :68` | hidden when the marker is a city marker | hidden (DB quests sit on the city) | nothing; `type!.imagePath` is `''` for these types, never drawn |
| Result sheet | `quest_result_sheet.dart:248-261` | `type.label` | «Magia» | label only |
| Innkeeper | `pending_request.dart:31`, `mission_draft.dart:116`, `request_card.dart:39, :73`, `mission_completion_screen.dart:169` | lenient parse; only `worldMission` branches | never reaches the guided flow | parser moved to `fromWire`; nothing else |
| Push copy | — | built by the BE (`notification_category.dart`, `push_event.dart`) | — | nothing on the FE |
| Parsing of an unknown type | `quest_infos.dart:34` strict → `Quest.tryFromJson` drops the quest from the Board (`quest.dart:50-58`, `graphql.dart:481-493`); **strict** on the character's own quests (`character_quests.dart:20-34` → `Quest.fromJson`, type selected at `character_fragment.dart:118-129`) and on `questUpdated` (`graphql.dart:436-445`) | keep the catalogue behaviour (unknown → the quest is dropped) when moving to `fromWire`; see Pitfall 4 |

**Wire boundary refactor (first plan, no behaviour change):** `QuestType` gains a `wireName` (default = the Dart name; explicit only for `theVoid`) and `static QuestType? fromWire(Object? value)`; the four parsers and the two `toJson` use them; `QuestInfos.fromJson` keeps throwing on a non-null unknown type (so `Quest.tryFromJson` keeps dropping it and `city_test`-style pins such as «unknown type drops only this quest» stay green). Test helpers build quests from wire strings (`buildQuest(type: 'magic')`), so `buildQuest(type: 'void')` exercises the real path.

### F-4. City types [VERIFIED: codebase + SDL; one inference]

| Item | File:line | Note |
|------|-----------|------|
| Enum | `city_type.dart:3-57` — `size` (marker px), `imageId`, `alwaysVisible` (only `talmvereVillage`, `:15-19`); Talmvere 39, `aarakocraVillage` 30 (`:23`) | add `aarakocraCapital(size: 39, …)`, `dragonbornCapital(size: 39, …)`, `dragonbornVillage(size: 30, …)`; **not** `alwaysVisible` (see below) |
| Parsing | `city.dart:35` `byName` (strict) inside `tryFromJson` (`:58-67`); list boundary `graphql.dart:468-470` (skipped + log) | unknown type → the city is dropped, never a crash; pinned by `city_test.dart:38-60` |
| Size | `city_size_type.dart:1` `{ capital, city, village }`; `City.size` from the wire, lenient (`city.dart:53`) | no change: the BE derives the size from the type (`city-size.ts` `CITY_SIZE_BY_TYPE`) |
| Visibility | `city_markers_layer.dart:49-63` — hidden without a type; else `alwaysVisible` or by `City.size` (capital ≥ 0, city ≥ 2.5, village ≥ 3.2: `map_constants.dart:5-7`) | the two capitals arrive with `size: capital` → visible at every zoom like every capital; `dragonbornVillage` from 3.2. Talmvere needs `alwaysVisible` only because the BE calls it a village; the new capitals do not. `city_type_test.dart:5-9` («only Talmvere keeps its marker visible at every zoom») stays green |
| Marker | `city_marker.dart:25-29` (`type!.imagePath`, `type!.size`), scale `city_markers_layer.dart:36, :65-67` | data-driven, no change |
| Other per-type tables | none: grep `CityType` in `lib/` → `city.dart`, `city_marker.dart`, `city_markers_layer.dart` only. No FE table for shops, creation or home cities (BE `RACE_HOME_CITY_TYPES`); teleport destinations use `PoiType` labels (`teleport_destination.dart:66-88`) and select `city { id name }` only (`point_of_interest_queries.dart:5-15`) | D-18 needs no FE work |
| Where `type`/`size` are selected | `cities` query only (`city_queries.dart:6-11`) | one document |

**Right now (the question of the brief):** the app is neither crashing nor dropping the three cities, because they cannot be served: see Summary (4). If the orchestrator's probe confirms that `cities` returns `data: null` on today's BE, the options are a BE hotfix ahead of Phase 24 (three enum values + sizes) or reverting the three `type` values at DB until the BE boots with Phase 24 (O-3). After the BE knows the types and **before** this phase's enum values ship, an old app would drop the three cities (log «[Cities] skipped 3 malformed cities») and keep the rest — the three enum values are therefore worth an early pre-gate plan.

### F-5. Assets [VERIFIED: codebase + `ls ~/Downloads/*_flat.svg`]

- **Conventions:** one class of `static const String` ids grouped by section comments (`cloudinary_assets.dart:7-263`; «Quest Sheets» `:60`, «Use Types» `:156`, «Energy Types» `:193`, «Cities» `:220`); id = `v<version>/<name>_<suffix>.svg`; `CloudinaryAssets.url(id)` (`:262`). There is **no** `test/config/cloudinary_assets_test.dart`: ids are pinned as literals beside their consumer, e.g. `quest_paper_asset_test.dart:219-225` («the magic sheets point to their revised files»), and widget tests seed the cache with the constants (`sheet_test.dart:44-52`, `board_test.dart:98-99`).
- **Re-pointing an id is an established two-commit move** (`git log -- lib/config/cloudinary_assets.dart`: `471546e7 fix(assets): draw magic quests on the flattened sheet`, `bd8c2276`, `1870352c`, `59987499`, …): `test(…)` expecting the new literal, then the constant. The SVG cache is keyed by URL (`svg_cache.dart:10-13`), so a new id needs no invalidation.
- **Files waiting for upload (present in `~/Downloads`):** `voidSheet_flat.svg`, `tornVoidSheet_flat.svg`, `shamanicSheet_flat.svg`, `tornShamanicSheet_flat.svg`, `aarakocraCapital_flat.svg`, `dragonbornCapital_flat.svg`, `dragonbornVillage_flat.svg`, `aarakocraVillage_flat.svg`. Also waiting for upload (D-05, amended): `arcaneOrigin_flat.svg`, `shamanicOrigin_flat.svg`, `voidOrigin_flat.svg` — eleven ids owed in all.
- **How earlier phases handled missing ids:** Phase 22 forbade new ids; Phase 4 planned a placeholder and the real id reached the planner mid-planning by message; `QuestType` uses `imageId: ''` for pawn-less types with `imagePath` returning `''` (`quest_type.dart:11-21`) — a sentinel that only works because those pawns are never drawn.
- **Recommendation — stand-ins, one blocked plan:** the seven new constants are declared in the plans that need them, pointing at the closest existing drawing (`voidSheet`/`shamanicSheet` → the `magicSheet` id, torn ones → `magicTornSheet`; `aarakocraCapital` → the `aarakocraVillage` id; `dragonbornCapital`/`dragonbornVillage` → the `mountainVillage` id, today's dragonborn home). Every consumer and test references the constants by **name**. Plan 23-05 (blocked on the eight ids) then pins the eight literals RED-first, re-points the seven constants and `aarakocraVillage`, and adds one guard test («no new asset still points at a stand-in»: each new constant differs from the id it borrowed). If the ids arrive before planning ends, the planner writes the literals directly into 23-03/23-04 and 23-05 shrinks to the `aarakocraVillage` re-point. The origin icons get **no** stand-in (no existing drawing is close, and a null `imageId` path would be a flag): their three ids are wired by the plan that draws the origin (23-06).

### F-6. Pre-gate vs gated split [VERIFIED: schema check run this session]

- **Registry baseline:** 55 documents. Against `origin/develop` (`5ff0bdb9`, local ref) → 49 OK / 6 FAIL, every failure «Cannot query field "known" on type "Pet"» (the FE branch is stacked on Phase 22's last fix, which needs BE PR #43); against the BE branch `fix/23-dungeon-xp-and-innkeeper-corrections` (`3d2e1f1e`) → **55 × OK**. The gate of this phase reads the SDL that contains both PR #43 and Phase 24.
- **Pre-gate, safe on today's BE:** `QuestType` wire boundary; `SpellOrigin` + `Spell.origin`/`minLevelToLearn` (unselected, null); `minXpToLearn` removed from fragment, model, copy; the two quest types (strings on the wire; nothing serves them until the DB quests are written); the three city types; asset ids; the origin widgets (a null origin draws nothing).
- **Gated on the user (ids only, the files exist):** 23-05 (eight ids), 23-06 (three icon ids).
- **Gated on the BE Phase 24 merge:** `origin` in `SpellFragment.fields`, `SpellFragment.simpleFields` and the inline `addedSpell` of `EquipmentFragment.fields`; `minLevelToLearn` in `SpellFragment.fields`; schema check 55 × OK; full suite; device E2E.
- **Device E2E (human, orchestrator-guided, one step per message), needs the BE booted with Phase 24, the DB written (origins, levels, the three quests) and the eight ids wired:** (1) Map: Murnborim and Thengran visible from the widest zoom at the Talmvere size, Veg Faldir from the village zoom, Balkuldir with the new drawing; (2) Journal: a known spell shows the origin icon before use and energy, the details read «Origine: …» and «Per impararla: Livello N · …», no «XP»; (3) Board in Murnborim (character moved by DB script): «Rito sciamanico» on its sheet, torn below mage with «Serve almeno il titolo Mago», acceptable at mage; accept → Map paper on the shamanic sheet, «Studiando…»; result sheet with type «Rito sciamanico» and «Magia appresa: …» of a shamanic spell; (4) the same in Necrorian for «Rito del Vuoto»; (5) innkeeper prize catalogue and a shop item with an infused spell show the origin icon; (6) a new dragonborn and a new aarakocra are born in their capitals (BE rule, observed on the Map).

### Anti-Patterns to Avoid
- Naming an enum value `void` or escaping it with an underscore (reserved word; `void_` breaks `lowerCamelCase`).
- Reading or writing the wire through `.name` / `byName` / `asNameMap` for `QuestType` or `SpellOrigin`.
- Selecting `origin` or `minLevelToLearn` before the merge, or leaving `minXpToLearn` selected after it.
- Comparing the served level with the character's level, hiding or greying a spell by level, filtering the innkeeper's list (rule 4, D-08).
- A separate widget per origin, or an origin icon drawn outside `SpellCard` / `SpellInfo`.
- Making the new capitals `alwaysVisible` (their served size already shows them at every zoom).
- A raw Cloudinary id or URL in a widget or a test helper instead of the constant.
- Content in the repo: no list of spells, quests or levels on the FE (the world lives in the DB).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Wire ↔ enum for `void` | per-call `if (wire == 'void')` | one `wireName` + `fromWire` per enum | six call sites for `QuestType` alone |
| Level gate | FE comparison with `character.level` | the served list / the BE refusal | rule 4, D-08 |
| Icon rendering | `SvgPicture.network` | `CachedSvg` | `docs/rules/assets.md` |
| Spell copy | inline strings in widgets | `lib/utils/spell_lines.dart` | all spell strings live there |
| Schema validation | a new script | `dump_documents.dart` + `validate_documents.js` | registry of 55 |
| Marker visibility of the capitals | a per-type flag | `City.size` from the BE | D-16, `city_markers_layer.dart:58-63` |

**Key insight:** this phase adds values to tables the FE already has; the only new mechanism is the wire name, forced by one reserved word.

## Runtime State Inventory

Not a rename phase on the FE; one field is renamed on the wire and one asset id changes.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | BE DB: 96 spells with `minXpToLearn` → level + origin (BE migrator, orchestrator); three cities already carry the new types. FE: none — `Spell.toJson` writes the key (`spell.dart:47`) but no FE store persists spells (GraphQL cache only; a cached `character` without the field parses leniently) | FE: code edit only |
| Live service config | Cloudinary: eleven flattened files to upload by the user (eight of D-19, three origin icons) | user upload; ids to the orchestrator |
| OS-registered state | None — no notification channel, no route, no deep link changes in this phase (verified: no notification file in the touch list) | none |
| Secrets/env vars | None | none |
| Build artifacts | SVG disk cache keyed by URL: the old `aarakocraVillage` file stays cached under the old URL and is never requested again | none |

## Common Pitfalls

### Pitfall 1: `void` as an identifier
`enum X { void }` does not compile, and `asNameMap()['void']` can never match. Explicit wire names; tests feed the wire string `'void'`.

### Pitfall 2: the non-additive field on the character fragment
`minXpToLearn` and, later, `origin`/`minLevelToLearn` sit inside `CharacterFragment` → `character` and `characterUpdated`. A selection the server does not know loses the character. Remove first (pre-gate), add at the gate; never both in one plan. FE `develop` (Phase 22) still selects `minXpToLearn`: between the BE Phase 24 merge and this phase's merge, FE `develop` is invalid against BE `develop` (W-2).

### Pitfall 3: the defaulted switch
`quest_state_label.dart:18` has `_ => 'In corso…'`: adding enum values compiles and the two types silently read «In corso…» instead of «Studiando…». A test per type (mirror of `quest_state_label_test.dart:122-127`) is the only guard.

### Pitfall 4: lenient type vs the non-null assertions
If `QuestInfos.type` became null for an unknown wire value instead of throwing, `quest_markers_layer.dart:68` (`quest.infos!.type!.imagePath`) would throw for a quest with a POI marker. Keep the catalogue strict-then-dropped; any loosening of the character's own quests (`character_quests.dart:20-34`) is a separate hardening, out of scope.

### Pitfall 5: three icons on a card
`spell_card.dart:53-60` sizes each icon `size / 2.5`; three of them overflow the row. Shrink only when the origin is present; widget test at the smallest card size used (innkeeper `_entrySize`, Journal slot) with `tester.takeException()` null.

### Pitfall 6: the test lists that enumerate types
`mission_lines_test.dart:30` (map of every type), `quest_sheet_details_test.dart:41`, `quest_paper_asset_test.dart:96-103` (every type has a torn sheet different from the whole one — a stand-in must keep whole ≠ torn), `quest_type_test.dart:27-31` (every type has a label), `use_type_test.dart` (wire names list — add the same pin for `SpellOrigin`), cache seeds in `sheet_test.dart:44-52` and `board_test.dart:98-99`.

### Pitfall 7: files that are not formatter-clean
`lib/graphql/fragments/spell_fragment.dart`, `lib/models/enums/energy_type.dart`, `lib/screens/mainScreen/tabs/map/layers/quest_markers_layer.dart` (checked one by one, 44 files, the other 41 are clean). The first plan that touches one starts with `style(<scope>): format <file>`. `energy_type.dart` and `quest_markers_layer.dart` need no edit in this phase.

### Pitfall 8: a stand-in asset shipped by mistake
Stand-in ids draw the wrong picture without failing anything. The guard test of 23-05 and step 1/3/4 of the device E2E catch it; the PR must not open before 23-05.

### Pitfall 9: the `cities` query on today's BE
If Summary (4) is confirmed, no FE change can make the Map show cities against a BE without the three types; do not chase it on the FE.

### Pitfall 10: schema baseline
The registry validates 55 × OK only against a BE that includes PR #43 (`Pet.known`). A gate run against a stale `origin/develop` fails for a reason unrelated to this phase.

## Code Examples

### Enum with a wire name (pattern for `SpellOrigin`; `QuestType` adds the same two members)
```dart
// lib/models/enums/spell_origin.dart (sketch; imageId arrives with the icon plan)
enum SpellOrigin {
  theVoid(wireName: 'void', label: 'Vuoto'),
  arcane(wireName: 'arcane', label: 'Arcana'),
  shamanic(wireName: 'shamanic', label: 'Sciamanica');

  const SpellOrigin({required this.wireName, required this.label});

  final String wireName;
  final String label;

  static SpellOrigin? fromWire(Object? value) {
    for (final origin in values) {
      if (origin.wireName == value) return origin;
    }
    return null;
  }
}
```
[VERIFIED: probe run with Dart 3.9.2 — `fromWire('void')` → value, `fromWire('x')` → null, `asNameMap()['void']` → null]

### Lenient spell fields (pattern `spell.dart:33-38`)
```dart
origin: SpellOrigin.fromWire(json['origin']),
minLevelToLearn: (json['minLevelToLearn'] as num?)?.toInt(),
```

### Learn line (replaces `spell_lines.dart:65-75`)
```dart
String? spellLearnLabel(Spell spell) {
  final level = spell.minLevelToLearn;
  final learnTime = spell.requiredLearnTime;
  final parts = [
    if (level != null && level > 0) 'Livello $level',
    if (learnTime != null)
      '${formatGameDuration(Duration(milliseconds: learnTime))} di studio',
  ];
  if (parts.isEmpty) return null;
  return 'Per impararla: ${parts.join(spellLineSeparator)}';
}
```

### Sheet branches (beside `quest_paper_asset.dart:77-80`)
```dart
QuestType.shamanic =>
  isTorn
      ? const [CloudinaryAssets.tornShamanicSheet]
      : const [CloudinaryAssets.shamanicSheet],
QuestType.theVoid =>
  isTorn
      ? const [CloudinaryAssets.tornVoidSheet]
      : const [CloudinaryAssets.voidSheet],
```
(Constant names follow D-14 and the uploaded file names; the existing pair is `magicSheet` / `magicTornSheet`.)

## Copy table (provisional, no UI phase; Italian verbatim)

| Place | Copy | Note |
|-------|------|------|
| Origin labels | «Arcana», «Sciamanica», «Vuoto» | D-06 |
| Spell details — origin row | «Origine: Arcana» | pattern «Uso: Attacco» (`spell_lines.dart:57-58`) |
| Spell details — learn line | «Per impararla: Livello 6 · 1 h di studio» | D-07, D-08 |
| Quest type labels | «Magia», «Rito sciamanico», «Rito del Vuoto» | D-13 |
| Pawn / Map sheet while running | «Studiando…» | as `magic` (O-4) |
| Board refusal below the rank | «Serve almeno il titolo Mago» | existing |

## What the FE needs from the BE (for `BACKEND-NOTES.md`)

- **W-1 `Spell.origin`:** `String!` like `useType` (or an SDL enum — the FE reads both the same way), wire values exactly `void`, `arcane`, `shamanic`; served on every `Spell` (character spell states, `addedSpell`, mission prize options, enemy spells).
- **W-2 Minimum level:** `Spell.minLevelToLearn: Int!` (≥ 1), `minXpToLearn` removed. The FE drops the old selection pre-gate on this branch; say whether the BE keeps `minXpToLearn` as a deprecated field until the FE PR merges (it would keep FE `develop` valid in between) or the window is accepted as in Phases 19 and 22.
- **W-3 City types:** `CityType` + `aarakocraCapital`, `dragonbornCapital`, `dragonbornVillage` (additive), sizes capital / capital / village. Confirm what `cities` returns **today** with the three types at DB (Summary 4).
- **W-4 Quest types:** wire values `shamanic` and `void` on every `type` string (`QuestInfos.type`, the quest of a `QuestResult`, pending requests, `MissionDraft.questType`); no SDL change expected — say so in the handoff.
- **W-5 No new refusal code** reaches the FE for the level gate (the innkeeper's options are served filtered and re-validated as today); if one is added, name it.
- **W-6 Result sheet:** `spellLearned { id name }` is enough (text line); no origin needed there.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Spell = use + energy | origin → use → energy | D-01 | `SpellOrigin`, icon first |
| «Per impararla: N XP» | «Per impararla: Livello N» | D-07 | field renamed on the wire, gated |
| `magic` teaches every spell | one quest type per origin (`magic` → `arcane`) | D-10 | BE only; FE gets two types |
| Enum ↔ wire by Dart name | explicit wire name where needed | `void` | `QuestType`, `SpellOrigin` |
| Dragonborn at home in a mountain village | their own capital and village types | D-15..D-18 | three `CityType` values |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Wire names `origin`, `minLevelToLearn` (proposals; the BE research fixes them) | F-1, F-2 | one key in `Spell.fromJson` + one line per fragment renamed in the gate plan |
| A2 | Today's BE answers `cities` with `data: null` because of the three DB types (inferred, not observed) | Summary 4, F-4 | if the BE somehow serves them, an app without the three values just drops those cities — the FE plan is the same |
| A3 | Quest `type` stays `String!` after Phase 24 | F-3, W-4 | if it becomes an SDL enum nothing changes on the FE selection |
| A4 | `theVoid` as the Dart name of the wire value `void` | Summary 1 | pure naming; decided once in REPO-RULES |
| A5 | Icon size `size / 3.2` for three icons and the «Origine: …» row | F-1 | visual only; settled on the device |
| A6 | Full-suite baseline 5041 (from the Phase 22 records, not re-run) | Constraints | the gate SUMMARY records the real number |
| A7 | The DB quests of the two types sit on a city marker like «Iniziazione arcana a Valantar» (no pawn drawn) | F-3 | a quest on a free POI would draw `CachedSvg(url: '')` — same as `magic` today |

## Open Questions (RESOLVED)

Recommended defaults; the orchestrator confirms them in `23-REPO-RULES.md`.

1. **O-1 Dart name of `void`.** `theVoid` in `SpellOrigin` and `QuestType`, wire name `'void'`. Default: yes.
2. **O-2 Stand-in asset ids.** New constants born on the closest existing drawing, one plan re-points them when the ids arrive, guard test included. Default: yes — unless the eight ids arrive before planning ends (then literals from the start).
3. **O-3 The `cities` query today.** Orchestrator probes the running BE (`{ cities { id type size } }`); if it fails, BE hotfix of the three enum values ahead of Phase 24 or DB revert until the boot. Not an FE plan.
4. **O-4 Activity copy of the two rites.** «Studiando…» as `magic` («exactly like magic»). Default: yes; the user may want «Celebrando il rito…» (U-1).
5. **O-5 Origin filter in the spellbook.** Not in the decisions. Default: no filter in this phase.
6. **O-6 Transition of the learn line.** The «N XP» part disappears pre-gate and «Livello N» appears at the gate. Default: accepted (development branch).
7. **O-7 Requirement IDs.** `ORIGIN-01..06` as proposed. Default: yes.

### For the user (product-level)
- **U-1 — «Studiando…» per i riti.** «Durante un Rito sciamanico o un Rito del Vuoto sopra la pedina resta «Studiando…» come per la Magia, oppure vuoi un testo diverso?» Recommended: resta «Studiando…».
- **U-2 — Gli undici id.** The Cloudinary ids of the eleven flattened files (eight of D-19, the three origin icons).
- **U-3 — Filtro per origine nel Diario.** «Vuoi anche un filtro per origine accanto a quello per uso?» Recommended: no, in this phase.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter / Dart SDK | analyze, test, probe | ✓ | Flutter 3.35.5, Dart 3.9.2 | — |
| Node + BE `node_modules/graphql` | schema check | ✓ | Node v22.12.0; 55 documents validated this session | — |
| BE SDL with PR #43 | schema baseline | ✓ on the local branch `fix/23-dungeon-xp-and-innkeeper-corrections` (not on local `origin/develop`) | `3d2e1f1e` | orchestrator aligns `origin/develop` after the merge |
| BE SDL with Phase 24 | gated plans | ✗ (BE has only its CONTEXT) | — | park at the gate plan |
| Eight Cloudinary ids | 23-05 | ✗ (files in `~/Downloads`, upload pending) | — | stand-ins (O-2) |
| Three origin icon ids | 23-06 | ✗ (files flattened in `~/Downloads`, upload pending) | — | none (nothing draws the origin until then) |
| Device + BE boot + DB content | E2E | orchestrator/user | — | none (human checkpoint) |

**Missing dependencies with no fallback:** merged BE Phase 24 SDL (23-07, 23-08); the three icon ids (23-06).
**Missing dependencies with fallback:** the eight ids (stand-ins until 23-05).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test` + `mocktail` (no new Cubit expected) |
| Config file | none beyond `pubspec.yaml` / `analysis_options.yaml`; helpers `test/helpers/` (`svg_cache_seed.dart`, `test_app.dart`, fixtures `spell_fixtures.dart` `spellJson`, quest builders `buildQuest(type: …)`) |
| Quick run command | `flutter test <touched test files>` (foreground) |
| Full suite command | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (gate plan only, timeout ≥ 300 000 ms) |
| Analyzer gate | `flutter analyze --no-fatal-infos` → 0 error / 0 warning (baseline 47 info) |
| Schema gate | SDL of the merged BE in a `mktemp -d` dir + `dart run tool/schema_check/dump_documents.dart <dir>` + `NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js <schema> <dir>` → 55 × OK |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ORIGIN-01 | `SpellOrigin` wire names (`void`, `arcane`, `shamanic`), labels, `fromWire` null on unknown; `Spell.origin` lenient, in `props`/`copyWith`/`toJson` | unit | `flutter test test/models/enums/spell_origin_test.dart test/models/spell_test.dart` | ❌ W0 `spell_origin_test.dart`; ✅ extend |
| ORIGIN-02 | `minLevelToLearn` parsed leniently; learn line with level, without level, without both; no «XP»; `SpellFragment.fields` without `minXpToLearn` | unit + document pin | `flutter test test/utils/spell_lines_test.dart test/shared/components/spell_info_test.dart test/graphql/character_fragment_test.dart` | ✅ change |
| ORIGIN-03 | `QuestType.fromWire`/`wireName` round trip for every value (refactor keeps the four parsers and the dropped-quest rule); labels; standard lane, repeatable, unregistered, service family; «Studiando…» on both labels; own whole and torn sheets on Board and Map; torn below mage | unit + widget | `flutter test test/models/enums/quest_type_test.dart test/models/quest test/utils/mission_lines_test.dart test/models/pending_request test/models/mission test/models/quest_result test/screens/mainScreen/tabs/board` | ✅ extend |
| ORIGIN-04 | three city types parse (not dropped), sizes 39 / 39 / 30, capitals visible at zoom 0 through `size: capital`, village from the village zoom, only Talmvere `alwaysVisible`; ids pinned as literals; no stand-in left | unit + widget | `flutter test test/models/city_test.dart test/models/enums/city_type_test.dart test/screens/mainScreen/tabs/map/layers/city_markers_layer_test.dart test/models/quest/quest_paper_asset_test.dart` | ✅ extend |
| ORIGIN-05 | `SpellCard`: origin icon first, three icons without overflow at the smallest size, unchanged without origin; `SpellInfo`: «Origine: …» row with icon before the use row | widget | `flutter test test/shared/components/cards/spell_card_test.dart test/shared/components/spell_info_test.dart test/shared/components/popup/spell_info_sheet_test.dart` | ✅ extend |
| ORIGIN-06 | selections (`origin` × 3 places, `minLevelToLearn`), registry 55, schema check, full suite | gate | gate script + schema check + full suite | ✅ |
| ORIGIN-06 | device: markers, origin icon, level line, the two rites end to end, innkeeper and shop cards | manual | `23-HUMAN-UAT.md` | ❌ (created in the last plan) |

### Sampling Rate
- **Per task commit:** touched tests + analyzer gate + trailer check
- **Per plan:** the test directories named in the plan
- **Phase gate:** full suite green, schema check 55 × OK, before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/models/enums/spell_origin_test.dart` — ORIGIN-01
- [ ] `test/helpers/fixtures/spell_fixtures.dart` — `spellJson` gains `origin` and `minLevelToLearn`, loses `minXpToLearn` (ORIGIN-01, ORIGIN-02)
- [ ] Cache seeds for the new sheets and icons in `sheet_test.dart`, `board_test.dart`, `spell_card_test.dart` — ORIGIN-03, ORIGIN-05
- No framework install, no golden test (none exist).

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | unchanged |
| V3 Session Management | no | unchanged |
| V4 Access Control | yes (BE) | the level gate, the origin pool and the rank floor of the rites are enforced by the BE; the FE shows served facts and offers no bypass |
| V5 Input Validation | yes | lenient parsing at the model boundary: unknown origin → null, unknown quest type → quest dropped, unknown city type → city dropped; never a crash, never the character |
| V6 Cryptography | no | — |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Client pretends a level to learn a spell | Elevation | no client-side gate exists to tamper with; BE draw and prize validation |
| Malformed catalogue value (hand-edited DB) breaks the session | Denial of service | per-entry lenient parsers (`tryFromJson`, `fromWire`) |
| Asset URL injection | Tampering | ids only from `CloudinaryAssets` constants, URL built by `EnvConfig.cloudinaryUrl` |
| Secrets in logs or repo | Information disclosure | no new `appLog`; no `.env` touched |

## Sources

### Primary (HIGH confidence)
- Codebase `feat/23-spell-origins-void-and-shamanic-quests` `92cc07a9`: files cited inline; 44 files formatter-checked (`--output=none`); `flutter analyze` (47 issues); `dart run tool/schema_check/dump_documents.dart` (55) + `validate_documents.js` against two SDLs; Dart probe for `void` (outside the repo, in the session scratchpad).
- BE read-only: `origin/develop` `5ff0bdb9` and `fix/23-dungeon-xp-and-innkeeper-corrections` `3d2e1f1e` — `src/schema.gql` (`Spell`, `City`, `CityType`, `QuestInfos`, `Query.cities`, `MissionPrizeOptions`), `src/cities/{city-size,cities.resolver,cities.service}.ts`, readers of `minXpToLearn` (`resolution-loader.service.ts`, `mission-prizes.ts`, `mission-prize-options.service.ts`, `chosen-rewards.ts`); BE `24-CONTEXT.md` on `feat/24-origini-magie-quest-void-shamanic` `7544aa8b`.
- Planning: `23-CONTEXT.md`, `22-RESEARCH.md`, `22-REPO-RULES.md`, `22-16-PLAN.md` (gate plan model), quick task `261110-mag` (commits `6546d9d5`, `f9b742ef`), `ROADMAP.md`, `REQUIREMENTS.md`, `docs/rules/*.md`.

### Secondary / Tertiary
- None (no web source needed: the domain is this codebase and its BE). The graphql-js behaviour behind A2 is training knowledge applied to the read SDL, hence INFERRED.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — nothing new.
- Architecture: HIGH for the FE map (file:line, probe, schema check); MEDIUM for the wire names (BE research pending).
- Pitfalls: HIGH — each tied to a file:line, a probe or a tool run; Pitfall 9 depends on A2.

**Research date:** 2026-11-15
**Valid until:** the BE Phase 24 research fixes the SDL names (then refresh W-1/W-2 in both REPO-RULES), and the user delivers the eleven ids.

## Recommended plan order (sequential, TDD RED → GREEN, one concern per plan)

| # | Plan | Gate | Depends on | Req |
|---|------|------|-----------|-----|
| 23-01 | Requirements `ORIGIN-01..06`; `QuestType` wire boundary (`wireName`, `fromWire`; four parsers and two `toJson` moved; behaviour unchanged, unknown type still drops the quest) | pre-gate | — | ORIGIN-03 |
| 23-02 | Spell model: `SpellOrigin` (no icon), `Spell.origin` and `minLevelToLearn` lenient and unselected; `minXpToLearn` removed from model, fixtures, copy and `SpellFragment` (style commit first; dead `definition` deleted); `spellLearnLabel` with the level, `spellOriginLabel` | pre-gate | 23-01 (pattern) | ORIGIN-01, ORIGIN-02 |
| 23-03 | Quest types `shamanic` and `theVoid`: labels, sheets (constants, stand-in or real), «Studiando…» in both label functions, tests mirrored from `261110-mag` (lane, sets, family, Board torn until the rank, sheet on Board and Map) | pre-gate | 23-01 | ORIGIN-03 |
| 23-04 | City types: three values (39 / 39 / 30, constants stand-in or real), parse and visibility tests | pre-gate | — | ORIGIN-04 |
| 23-05 | Asset ids: eight literals pinned RED-first, seven constants re-pointed, `aarakocraVillage` replaced, guard «no stand-in left» | **blocked on the user's eight ids** | 23-03, 23-04 | ORIGIN-03, ORIGIN-04 |
| 23-06 | Origin drawing: three icon ids (`arcaneOrigin`, `shamanicOrigin`, `voidOrigin`) pinned as literals, `SpellOrigin.imagePath`, `SpellCard` (origin first, three-icon size), `SpellInfo` origin row; built on fixtures, invisible until the gate (origin null) | **blocked on the user's three icon ids** | 23-02 | ORIGIN-05 |
| 23-07 | Schema gate on the merged BE Phase 24 SDL → renames RED-first if names differ → `origin` in `SpellFragment.fields`, `simpleFields`, inline `addedSpell`; `minLevelToLearn` in `fields`; schema check 55 × OK; full suite | **gated on the BE Phase 24 merge** | 23-01..23-06 | ORIGIN-06 |
| 23-08 | Device E2E (`23-HUMAN-UAT.md`, orchestrator-guided, F-6 steps), fixes in TDD during the UAT, `BACKEND-NOTES.md`, requirements mark-complete, closing docs | **gated, human** | 23-07; BE boot + DB content + ids | ORIGIN-06 |

23-03 and 23-04 are independent of 23-02 and of each other. If the icon ids arrive after the BE merge, 23-06 moves after 23-07 (the gate then selects `origin` with nothing drawing it) and the E2E waits for it. `BACKEND-NOTES.md` (W-1..W-6) should be written by the orchestrator before the BE research, not in the last plan.

## RESEARCH COMPLETE
