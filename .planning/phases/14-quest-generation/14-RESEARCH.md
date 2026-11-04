# Phase 14: Quest Generation (frontend companion) - Research

**Researched:** 2026-11-04
**Domain:** Flutter wire-contract migration (GraphQL fragments + models), parchment sheets, innkeeper utility action, remote enemy portraits
**Confidence:** HIGH for code facts (file:line read this session); MEDIUM for the remote-portrait rendering and the BE names not yet merged

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** `QuestInfos.enemies: List<QuestEnemy>` with `QuestEnemy { enemy, quantity }` replaces `enemy` in the model, `toJson`/`copyWith`/`props`, the fixtures and `QuestFragment` (`infos { … enemies { quantity enemy { id name imagePath xp } } }`; `xp` only to pick the strongest enemy, D-02); the single `enemy` selection disappears from every document. `QuestResult.enemies` (same shape), `stagesCleared`, `stagesTotal` (nullable, dungeon only) replace `QuestResult.enemy`. Additive: `QuestInfos.description`, `QuestPrizes.pet`, `QuestRewards.pet`, `EquipmentItem.accessoryUseTypes` (`List<AccessoryUseType>?`, enum `attack | defense`), mutation `generateQuests` (returns `{ created }`). Parsing stays tolerant: a malformed `enemies` entry makes `Quest.tryFromJson` skip the quest, not the board.
- **D-02:** one portrait (strongest enemy, highest `xp`) + one «Nx nome» line per type (format of the «Consigliati» lines); one enemy with quantity 1 renders as today. `AutoSizeText` sizing and ordering at Claude's discretion.
- **D-03:** portrait loaded from the network, hidden when missing (Cloudinary convention, cached via `flutter_cache_manager`); unresolvable path or failed download → name only. Same rule in the result sheet; prepares Phase 17.
- **D-04:** «Consigliati» also in the combat body, under the enemy lines, omitted when empty.
- **D-05:** `infos.description` under the title in all three families, italic, scrollable when long, omitted when null.
- **D-06 (technical default):** `prizes.pet` → line «Compagno in premio: <nome>», no image.
- **D-07:** result sheet: enemies fought («3x Goblin» + portrait of the strongest, `QuestResultSheet.enemyKey` kept on the block); dungeon (`stagesTotal` set) → «Esplorazione: tappa k di N»; `rewards.pet` → «Compagno ottenuto: <nome>». Ambush (Phase 16) reuses the list.
- **D-08:** «Genera missioni» at the top of the innkeeper panel list, always visible (also with «Nessuna richiesta in attesa»).
- **D-09:** tap → `showDestructiveConfirmation` neutral style «Generare nuove missioni nel mondo?» «Genera»/«Annulla»; outcome in SnackBar «Generate N missioni» / «Nessuna missione da generare»; network/timeout/unknown in SnackBar; `FORBIDDEN` closes the panel with «La Locanda non è disponibile» (Phase 10 D-04); button disabled in flight.
- **D-10 (technical default):** dedicated cubit (idle → submitting → succeeded{created} / failed{failure, serial}) provided by the panel route; `InnkeeperRepository.generateQuests()` with the 15 s timeout and `innkeeperFailureFrom`; `GenerateQuests` enters the schema-check registry and its test.
- **D-11 (technical default):** QGEN-04 satisfied by `questSheetFamilyOf`; research checks empty `imagePath` of crime/guard and the state label; fix only if something breaks.
- **D-12:** `accessoryUseTypes` in model + equipment fragment; item sheet (Journal and shop) shows «Uso: attacco» / «Uso: difesa» / «Uso: attacco e difesa» only for ring/necklace; no filter, no equip constraint, no icon in lists.
- **D-13:** pre-merge plans on mocks with the BE CONTEXT names; schema gate + device E2E (`14-HUMAN-UAT.md`) after the BE PR merges; `BACKEND-NOTES.md` closes; TDD; `dart format` only touched files; analyzer vs `develop` baseline (error/warning); no `Co-Authored-By` trailer.

### Claude's Discretion
Copy of every new line and SnackBar; spacing in the combat body; cubit and widget names; fixture shapes; how `imagePath` maps to a Cloudinary URL; no visual mark for generated quests.

### Deferred Ideas (OUT OF SCOPE)
Darkened unknown enemies (Phase 17); live board refresh on inserts (BE D-18); companion prize beyond a text line; state labels for crime/guard; any mark for generated quests; good/evil alignment (v2).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QGEN-01 | Sheets list every enemy with quantity; `infos.enemy` gone from documents/models | §Models, §Fragments, §Combat body, §Portrait |
| QGEN-02 | Result sheet lists enemies fought (+ stages, pet reward) | §Result sheet |
| QGEN-03 | «Genera missioni» from the Locanda, confirmation, outcome, FORBIDDEN | §Locanda |
| QGEN-04 | crime/guard → service, dungeon → combat, no alignment | §QGEN-04 audit |
| QGEN-05 | Announcement `infos.description` under the title in every family | §Combat body / description |
| QGEN-06 | Rings/necklaces `accessoryUseTypes` + «Uso: …» line | §Jewels |
</phase_requirements>

## Project Constraints (from CLAUDE.md)
- Clean Code, SoC (UI no networking; Cubit no Flutter imports; models no Flutter), TDD red→green→refactor, Boy Scout.
- Rule 1: no app chrome on gameplay; the Locanda is a utility screen (AppBar + SnackBar allowed). Rule 2: no blocking loaders in session (portrait has no spinner). Rule 3: branch `feat/14-quest-generation`, PR → `develop`. Rule 4: backend is source of truth (FE never generates/filters/balances). Rule 5: no secrets.
- `flutter analyze` clean (error/warning), `dart format` only on touched files (memory: never on a directory), commits without `Co-Authored-By`, docs scope `docs(phase-14)`.
- `docs/rules/assets.md`: raster remote → `cached_network_image`; SVG → `CachedSvg`; "Asset di gioco locali nel bundle → vietato"; never `Image.network` scattered in widgets.
- `docs/rules/state-management.md`: Cubit folder lowerCamelCase (`questGenerationCubit/`), sealed states with Equatable, `BlocListener` for SnackBars.

## Summary

The phase is a hard wire replacement on two shared fragments plus four additive fields and one mutation. Only two fragments carry the enemy today: `QuestFragment` (`lib/graphql/fragments/quest_fragment.dart:19-23`, used by `quests` and `OnQuestUpdated`) and `QuestResultFragment` (`quest_result_fragment.dart:80-84`, used by 4 documents). Only two widgets read it: `quest_info_sheet.dart:148` and `quest_result_sheet.dart:224`. The schema gate is **not passed**: BE `origin/develop` = `0585b2e` (fetch succeeded this session, 2026-11-04) and `grep -c QuestEnemy` = **0**; its `QuestRewards` is `{ coins items }` so the reward field will be `QuestRewards.pet`.

The portrait (D-03) is the only design gap: enemy `imagePath` on the DB is today the placeholder `assets/images/<slug>.png` (BE Phase 11 D-13), later a Cloudinary URL written by the user (BE 11 D-24). A pure resolver plus one shared `EnemyPortrait` widget (raster → `CachedNetworkImage`, `.svg` → `CachedSvg`) solves both sheets and Phase 17.

**Primary recommendation:** 8 ungated plans (models → documents → shared enemy lines/portrait → info sheet → result sheet → generateQuests service/repo/cubit → Locanda UI → jewels line) + 2 gated plans (schema gate, device E2E + handoff), with a `14-REPO-RULES.md` cloned from `13-REPO-RULES.md`.

## Standard Stack (all already in `pubspec.lock`, no new dependency)

| Library | Locked | Use in this phase |
|---------|--------|-------------------|
| flutter | 3.35.5 stable | — |
| flutter_bloc / bloc_test | 9.1.1 / 10.0.0 | `QuestGenerationCubit` + tests |
| mocktail | 1.0.5 | `MockInnkeeperRepository`, `MockKlimmeckGraphQl`, new `MockQuestGenerationCubit` |
| graphql_flutter / gql | 5.2.1 | `GenerateQuests` document, registry test parses with `gql` |
| cached_network_image | 3.4.1 (`octo_image` 2.1.0) | raster enemy portrait (`CharacterPortrait` already uses `CachedNetworkImageProvider`, `character_portrait.dart:23`) |
| flutter_cache_manager | 3.4.1 | backs both `CachedNetworkImage` (DefaultCacheManager) and `CachedSvg` (`SvgCacheManager`) |
| auto_size_text | 3.0.0 | sheet text |
[VERIFIED: pubspec.lock, `flutter --version`]

## Architecture Patterns

### Recommended files
```
lib/models/quest/quest_enemy.dart              # QuestEnemy {enemy, quantity}, listFrom, enemy lines + strongest
lib/models/enums/accessory_use_type.dart       # enum AccessoryUseType { attack, defense } + label
lib/models/enemy_portrait_url.dart (or utils)  # pure resolver imagePath → URL?
lib/shared/components/enemy_portrait.dart      # one widget, both sheets
lib/graphql/mutations/quest_mutations.dart     # + QuestMutations.generateQuests
lib/screens/innkeeper/questGenerationCubit/    # quest_generation_cubit.dart + _state.dart
lib/screens/innkeeper/components/generate_quests_button.dart
```

### 1. Models (QGEN-01/02/05/06) [VERIFIED: codebase]
- `QuestInfos` (`quest_infos.dart:8-76`): field `enemy` :20, `fromJson` :28, `toJson` :42 (`"enemy": enemy?.id`), `copyWith` :52/:60, `props` :71. Replace with `final List<QuestEnemy> enemies` (non-null, `const []` when missing), add `final String? description`. `toJson`: `"enemies": [{ "enemy": e.enemy.id, "quantity": e.quantity }]`, `"description"`.
- `Quest.tryFromJson` (`quest.dart:38-45`) catches `Object` → a throwing `QuestEnemy.fromJson` already skips only that quest (D-01). Make `QuestEnemy.fromJson` strict: `enemy` must be a `Map`, `quantity` a `num` ≥ 1, else `FormatException`.
- `Enemy` (`enemy.dart:37-63`): `xp: json["xp"]?.toInt()` :56 is already parsed; `imagePath` :61. **Pitfall:** `locations` :40-42 assigns a lazy `Iterable` to `List<PoiType>?` → a selected `locations` crashes (this is why `quest_result.dart:149-158` whitelists keys). Never select `locations`.
- `QuestResult` (`quest_result.dart`): `enemy` :37/:69/:111/:187-189/:218. Replace with `enemies` + `int? stagesCleared`, `int? stagesTotal`. `_enemyFrom` whitelist (:151-158) must gain `xp`. Recommend a **lenient per-entry** parser for results modelled on `assetQuantitiesFrom` (:129-137: skip malformed entries) so a bad entry never drops a whole result sheet (see C3). `toJson` must round-trip (`quest_result_test.dart:273` asserts `fromJson(toJson()) == result`).
- `QuestRewards` (`quest_rewards.dart:7-27`): add `final Pet? pet`; **`isEmpty` (:13) must include `pet == null`**, otherwise `QuestResult.hasRewards` (:81) hides a pet-only reward and `_rewards()` (`quest_result_sheet.dart:311`) returns nothing.
- `QuestPrizes` (`quest_prizes.dart:7-56`): add `final Pet? pet` (`Pet.fromJson` tolerates `{id,name}` only, `pet.dart`).
- `EquipmentItem` (`equipment_item.dart:10-94`): add `final List<AccessoryUseType>? accessoryUseTypes`; parse with `AccessoryUseType.values.asNameMap()` dropping unknown names (do not use `byName`, which throws like `equipType` :32-34).
- `AccessoryUseType`: follow `lib/models/enums/use_type.dart` (enhanced enum, `label` field, `const` ctor) without image: `attack(label: 'attacco')`, `defense(label: 'difesa')` — lowercase because the label sits mid-sentence. UseType labels are capitalised ("Difesa"/"Attacco", `use_type.dart:4-11`); a separate enum avoids touching spells.

### 2. Enemy lines and strongest enemy (D-02) — pure model function
```dart
// lib/models/quest/quest_enemy.dart (sketch)
List<String> enemyLinesOf(List<QuestEnemy> enemies);   // «3x Goblin»
Enemy? strongestEnemyOf(List<QuestEnemy> enemies);     // max xp, null xp = 0, first wins ties
```
Rules recommended (tests name D-02): aggregate by `enemy.id` (one line per **type**: a dungeon may repeat an enemy across stages), quantities summed, **first-occurrence order preserved** (dungeon order = stage order, BE D-12; generated titles list enemies in BE order, BE D-22); a single entry with quantity 1 → bare name (= "renders as today"); otherwise «${qty}x ${name}» exactly like `recommendedLootLines` (`quest_sheet_details.dart:89-93`). Names null/empty are skipped. Expose through `QuestSheetDetails` (`enemyLines`, `strongestEnemy`) so the widget renders only data (D-09 of Phase 6 pattern, `quest_sheet_details.dart:49`).

### 3. Portrait (D-03) [VERIFIED codebase; rendering MEDIUM]
Facts: no `Image.network` helper exists; remote raster = `CachedNetworkImageProvider` (`character_portrait.dart:18-26`); remote SVG = `CachedSvg` (`cached_svg.dart`, memory + `SvgCacheManager` disk cache, empty `SizedBox` on failure :76-78, a 14 px spinner while loading :66-73); `CloudinaryAssets.url(path)` = `'$cloudinaryBaseUrl/$path'` (`env_config.dart:114-120`, default `https://res.cloudinary.com/dzuhywp53/image/upload`). DB values: BE 11 D-13 «`imagePath` provvisorio e deterministico `assets/images/<slug>.png` come l'Arbusto Maligno, sostituito dal passaggio immagini (D-24)»; D-24: URL Cloudinary filled by the user [CITED: BE `11-popolamento-del-mondo/11-CONTEXT.md:34,57`]. Phase 9 research saw `'enemies/wolf.png'` (`09-RESEARCH.md:197`). Only `assets/images/arbustoMaligno.png` is bundled (`assets/images/`).

Resolver rule (pure, unit-tested):
1. null/blank → null.
2. `Uri.tryParse` with scheme `https` and a host → as is.
3. Cloudinary-relative `^v\d+/` (the app's convention, e.g. `v1757660751/emptySheet_jiip7r.svg`) → `CloudinaryAssets.url(path)`.
4. Anything else (`assets/images/…`, `enemies/wolf.png`, `http://`, `file:`, `data:`) → null → hidden.

Widget `EnemyPortrait({imagePath, height})`: url null → `SizedBox.shrink()`; `.svg` → `CachedSvg`; else `CachedNetworkImage(imageUrl:, fit: BoxFit.contain, placeholder: (_, _) => SizedBox.shrink(), errorWidget: (_, _, _) => SizedBox.shrink(), memCacheHeight:)` — no spinner (rule 2). In the info sheet the portrait sits in `Expanded` only when the URL resolves, so an unresolved one leaves the lines on top exactly like today (`quest_info_sheet.dart:156-163`).

Tests: unit-test the resolver (like `character_portrait_test.dart:16-32`, which tests `resolve` statically and never pumps network). For the widget, give `EnemyPortrait` an optional `BaseCacheManager? cacheManager` passed to `CachedNetworkImage.cacheManager` and stub it with mocktail (`getFileStream` → error stream → assert `SizedBox.shrink`/no exception). `useSvgHttpOverrides()` (`test/helpers/fakes/svg_http_overrides.dart:12-16`) answers every HTTP request with a 1×1 SVG: usable for the `.svg` branch, **not** for PNG decoding. Sheet widget tests should use unresolvable paths (or a seeded `CachedSvg` URL via `seedSvgCache`, `test/helpers/svg_cache_seed.dart`) to stay offline.

### 4. Quest sheet (QGEN-01/04/05) — `quest_info_sheet.dart`
- `_buildQuestInfo` (:96-130): title `Flexible` :101-110, then body `Expanded(flex: 4)` :111-118. Insert the announcement between them: `if (description != null && description.isNotEmpty) Flexible(child: SingleChildScrollView(child: Text(description, key: descriptionKey, style: bodyLarge.copyWith(fontStyle: FontStyle.italic))))` — serves all three families with one insertion (D-05). Add a theme token if preferred (token-based visuals).
- `_combatBody` (:147-188): left `Expanded(Column)` becomes `[if url resolves Expanded(EnemyPortrait), Flexible(SingleChildScrollView(Column[enemy lines (AutoSizeText max 12/min 8, as :164-170), if recommendedLootLines.isNotEmpty «Consigliati» specialText + lines (copy of :220-224)]))]`; show the left column when `enemyLines` or `recommendedLootLines` are non-empty. Right column unchanged (time, title, slots).
- `_serviceBody` and `_narrativeBody` unchanged (description above them).
- Prizes (`_buildRewards` :279-326): add a line under the Row: `if (prizes.pet?.name != null) Text('Compagno in premio: …', key: petPrizeKey)` (D-06).
- Existing test to rewrite: `quest_info_sheet_test.dart:90-98` expects `find.byType(Image)` for `assets/images/arbustoMaligno.png` (:16-20) — under D-03 that path hides the image (see C5). Families loop :53-87 already covers all 12 types (QGEN-04). Groups to extend: `combat` :89, `service` :206.

### 5. Result sheet (QGEN-02) — `quest_result_sheet.dart`
- `_enemy()` :223-247 → `_enemies()`: `Column(key: QuestResultSheet.enemyKey, children: [EnemyPortrait(strongest, height: _enemyImageHeight 48 :83), ...lines as Text bodyMedium])`; nothing when empty (gmCompleted test :277-282 expects `enemyKey` findsNothing).
- After it, `..._line(_stagesText(), QuestResultSheet.stagesKey)` with `'Esplorazione: tappa ${stagesCleared ?? 0} di $stagesTotal'` when `stagesTotal != null` (reuse `_line` :360-368). Composition order :144-163.
- `_rewards()` :310-326: add `if (rewards.pet?.name != null) Text('Compagno ottenuto: …', key: petRewardKey)`.
- Fixtures: `quest_result_fixtures.dart:74` `hasEnemy` and :109-115 `'enemy': {...}` → `enemies` param (default one `{quantity: 1, enemy: {id: 'enemy-1', name: 'Lupo grigio', imagePath: 'enemies/wolf.png', xp: 10}}`), `stagesCleared`, `stagesTotal`, `rewardPet`; `gmCompletedResultJson` :169 passes empty enemies. `quest_fixtures.dart:18,31,115,129` `enemy:` → `enemies:`, plus `description:` and `prizes:` (today the fixture has **no** `prizes` key).

### 6. Locanda (QGEN-03)
- Screen: `innkeeper_panel_screen.dart` — `_buildScaffold` :126-138 wraps a `BlocBuilder<PendingRequestsCubit>` whose `_buildQueue` :140-162 returns the loader, `_EmptyQueue` (:165-182) or the `ListView`. Put the button **outside** that builder: `Column([Padding(GenerateQuestsButton), Expanded(BlocBuilder…)])` so it shows in loading/empty/list states (D-08).
- Messages are static consts on the screen (:30-38); SnackBars via `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(…)))` (:61-63, :113-116). FORBIDDEN path: `_closeUnavailable` :83-88 (checks `ModalRoute.isActive`, `closeInnkeeperPanel`, then SnackBar `unavailableMessage`); add a `BlocListener<QuestGenerationCubit, QuestGenerationState>` to the existing `MultiBlocListener` :46-65 that calls `_closeUnavailable` on `failed(forbidden)` and shows SnackBars otherwise.
- Confirmation: `showDestructiveConfirmation(context, title:, body:, confirmLabel:, confirmButtonStyle: KlimmeckGuideTheme.primaryButtonStyle)` exactly as `request_completion_screen.dart:192-202`; it returns `false` on «Annulla» (`destructive_confirmation_dialog.dart:54-71`, `barrierDismissible: false`). Recommended: title «Genera missioni», body «Generare nuove missioni nel mondo?», confirm «Genera»; call `cubit.generate()` only `if (confirmed && !cubit.isClosed)`.
- Route: `innkeeper_panel_route.dart:15-37` builds providers from `context.read<InnkeeperRepository>()`; add `BlocProvider<QuestGenerationCubit>(create: (_) => QuestGenerationCubit(repository: repository))` next to `PendingRequestsCubit` (:25-31). Lazy creation means route/landing/settings tests (`innkeeper_panel_route_test.dart:94-121`, `teleport_mode_landing_test.dart:74-96`, `innkeeper_section_test.dart:52-76`) need no new stubs until a tap.
- Repository: `InnkeeperRepository` (`innkeeper_repository.dart`) — add `Future<int> generateQuests() => _guard(_graphQl.generateQuests);` (`_guard` :58-76 maps OperationException via `innkeeperFailureFrom`, `GraphQlAccessDeniedException` FORBIDDEN, timeout 15 s :24, Format → malformed). `innkeeperFailureFrom` (`innkeeper_failure.dart:43-57`) already maps `FORBIDDEN`, `UNAUTHENTICATED`, link errors → `connection`; no new code (BE D-16 defines only FORBIDDEN).
- Service: `KlimmeckGraphQl.generateQuests()` modelled on `completePendingRequest` (`graphql.dart:221-237`: `_dataOrThrow(await performMutation(query:, variables:))`, `FormatException` when `created` is not an `int`). Test harness: `graphql_pending_requests_test.dart:26-41` (`Link.function` + `dataResponse`).
- Cubit (`questGenerationCubit/`): sealed `QuestGenerationIdle | QuestGenerationSubmitting | QuestGenerationSucceeded(created) | QuestGenerationFailed(failure, serial)`; `generate()` returns early when submitting; mixin `SafeEmit` like `request_completion_cubit.dart:18-19`. Because `Submitting` sits between two outcomes, two identical outcomes are still distinct transitions; the serial is harmless and follows D-10.
- Copy: `created == 0` → «Nessuna missione da generare»; `1` → «Generata 1 missione»; `N` → «Generate N missioni»; connection/timedOut/unknown/malformed → e.g. «Non è stato possibile generare le missioni. Riprova.»
- Tests: panel harness `innkeeper_panel_screen_test.dart:106-131` (`MultiBlocProvider` with mock cubits) needs `BlocProvider<QuestGenerationCubit>.value(MockQuestGenerationCubit)`; add the mock to `test/helpers/mocks.dart` (pattern :167-175).

### 7. Jewels (QGEN-06)
- One widget serves Journal and shop: `EquipmentInfoSheet` (`lib/shared/components/popup/equipment_info_sheet.dart`), used by `journal.dart:294` and `equipment_info_display.dart:62` (shop, `shop.dart:24`). Insert the line under the name box (:64-87), before the stats `Expanded` (:89): `if (line != null) Text(line, key: EquipmentInfoSheet.usageKey, style: bodyMedium)`.
- Line from a pure function (model layer): ring/necklace only, non-empty list, canonical order attack→defense, deduped: «Uso: attacco» / «Uso: difesa» / «Uso: attacco e difesa»; else null. No change to `ItemRow` or cards (D-12).
- Fragment fields to extend with `accessoryUseTypes`: `EquipmentFragment.fields` (:30-65; used by `GetCityShop` `shop_queries.dart:17`, `equipment` `character_queries.dart:27`, `equipmentItems*`) and `fieldsWithFullSpell` (:75-104; Journal assets `character_fragment.dart:72,78`). `EquipmentFragment.definition`/`name` (:6-28) has no consumer (`grep EquipmentItemFields` → only itself): Boy Scout candidate. `simpleFields` (:67-73, quest/result items) stays without it.
- Test: `equipment_info_sheet_test.dart:13-40` (helm fixture; pumps with `seedSvgCache`) → add ring/necklace/helm cases; no `test/models/equipment_item_test.dart` exists (Wave 0).

### 8. QGEN-04 audit (D-11) [VERIFIED]
- `questSheetFamilyOf` (`quest_sheet_details.dart:19-27`): crime/guard → service (default arm), dungeon → combat; per-type widget tests exist (`quest_info_sheet_test.dart:53-87`).
- Empty `QuestType.imagePath` for study/heal/job/crime/guard (`quest_type.dart:11-19` returns `''`) is used only by the map pawn `CachedSvg(url: quest.infos!.type!.imagePath)` (`quest_markers_layer.dart:68`). Services sit on the city marker (BE 11 §3: «servizi sul marker della città») and `_getShowableQuests` drops quests on a city marker (`quest_markers_layer.dart:40-49`), so the empty URL is never drawn; if it were, `CachedSvg` catches the failed load and renders an empty box (`cached_svg.dart:58-61,76-78`) — no crash.
- Board paper: crime → `crimeSheet*`, guard → `jobSheet*` (`quest_paper_asset.dart:24-31`). State label: crime/guard → «In corso…» (`quest_state_label.dart:10-19`, deferred).
- Dungeon: `registeredQuestTypes` = worldMission/boss/enemy/aid (`quest_lane.dart:14-19`) → no slot lines for dungeon (solo, BE fixed quests): acceptable. Generated enemy/boss are registered → slot lines from `requiredAdventurers` (BE D-09). **No fix needed.**

### Anti-Patterns to Avoid
- `Image.asset(enemy.imagePath!)` (IN-03, `quest_info_sheet.dart:158`, `quest_result_sheet.dart:233`) — replace in both.
- Sorting enemies by xp in the lines (breaks dungeon stage order) — sort only to pick the portrait.
- Selecting `enemies { enemy { relatedLore … } }` or `locations` (BE 11 §1 depth-1 rule; `Enemy.fromJson` crash).
- Reading the server message instead of `extensions.code`.

## Don't Hand-Roll
| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Remote raster cache | custom HTTP + file cache | `CachedNetworkImage` (flutter_cache_manager) |
| Remote SVG cache | new SVG loader | `CachedSvg` + `seedSvgCache` in tests |
| Confirmation dialog | new AlertDialog | `showDestructiveConfirmation` + `primaryButtonStyle` |
| Error classification | string matching | `innkeeperFailureFrom` / `_guard` |
| Panel close on FORBIDDEN | new pop logic | `_closeUnavailable` / `closeInnkeeperPanel` |
| «Nx nome» format | second formatter | same template as `recommendedLootLines` |

## Common Pitfalls
1. **Stale `contains('enemy { id name imagePath }')` tests** (`board_documents_test.dart:50-51`, `quest_result_documents_test.dart:50-51`): after the change `enemy { id name imagePath xp }` no longer matches, but a nested `enemy {` does. Assert `contains('enemies { quantity enemy { id name imagePath xp } }')` and that the count of `enemy {` equals the count of `enemies {`.
2. **`hasRewards` blind to the pet** (§1): pet-only reward invisible.
3. **`_enemyFrom` whitelist** drops `xp` → strongest enemy always the first.
4. **Fragment ahead of the BE**: once `enemies` is selected the app cannot talk to BE `develop` `0585b2e` (validation error on `quests` → empty board). No device run before the gated plans (Phase 13 D-16).
5. **Overflow in the combat column**: many enemy lines + Consigliati inside a fixed-height Row → wrap in `Flexible` + `SingleChildScrollView`; widget tests run in landscape phone (`useLandscapePhone`) and assert `tester.takeException()` is null.
6. **Registry test** (`test/tool/schema_check_documents_test.dart:28-40`) fails until `'GenerateQuests': QuestMutations.generateQuests` is registered; operation name must equal the key (`mutation GenerateQuests {`).
7. **STATE.md edits** only with Edit tool/python (13-REPO-RULES).

## Code Examples
```graphql
# QuestFragment.infos (replaces lines 19-23) and prizes
description
enemies { quantity enemy { id name imagePath xp } }
prizes { … pet { id name } }
# QuestResultFragment (replaces 80-84)
enemies { quantity enemy { id name imagePath xp } }
stagesCleared
stagesTotal
rewards { coins {…} items {…} pet { id name } }
# QuestMutations.generateQuests
mutation GenerateQuests {
  generateQuests {
    created
  }
}
```

## State of the Art
| Old | New | When |
|-----|-----|------|
| `infos.enemy` / `QuestResult.enemy` | `enemies: [QuestEnemy]` + stages | BE Phase 13 (non-additive) |
| `Image.asset(imagePath)` (never renders) | resolver + network portrait | this phase |

## Conflicts with the CONTEXT (recommended amendments)
- **C1 (D-03 «cached through flutter_cache_manager»):** the app has two remote paths, `CachedSvg` (SVG) and `cached_network_image` (raster; both sit on flutter_cache_manager). Amend D-03 to «`https` URL or Cloudinary-relative `v<n>/…` path; `.svg` through `CachedSvg`, raster through `CachedNetworkImage`; anything else hidden». Side effect: the bundled `assets/images/arbustoMaligno.png` placeholder stops showing (game assets must not live in the bundle, `docs/rules/assets.md`).
- **C2 (D-02 ordering «strongest first»):** sorting the lines by xp breaks the dungeon stage order (BE D-12) and the generated titles' order (BE D-22). Amend to «lines in BE order, aggregated by enemy id; the portrait alone picks the strongest»; one entry ×1 = bare name.
- **C3 (D-01 tolerance):** D-01 speaks only of quests. For `QuestResult` drop the malformed entry, never the result (a lost death/ack sheet is worse); mirrors `assetQuantitiesFrom`.
- **C4 (ROADMAP SC1 «3 × Goblin»):** D-02 «3x Goblin» (format of `recommendedLootLines`) wins; amend the ROADMAP example when the phase closes.
- **C5 (existing test):** `quest_info_sheet_test.dart:90-98` asserts an `Image` for `assets/images/arbustoMaligno.png`; under D-03 that path is unresolvable → the test is rewritten, not a regression.

## Assumptions Log
| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | BE field names: `QuestEnemy`, `QuestRewards.pet`, `GenerateQuestsResult { created }`, `AccessoryUseType { attack defense }` as fixed by the orchestrator; not yet on `origin/develop` | all | gate plan aligns names (pattern 13-10) |
| A2 | Real enemy images will be `https://res.cloudinary.com/...` URLs, mostly raster [ASSUMED] | §3 | resolver/branch tweak; both branches covered |
| A3 | `CachedNetworkImage` with a mocked `BaseCacheManager` renders the errorWidget without reported exceptions in widget tests [ASSUMED] | §3 | fall back to resolver unit tests + device check |
| A4 | `bodyLarge.copyWith(fontStyle: italic)` renders acceptably (Cormorant Garamond via google_fonts, runtime fetching off in tests, `test_app.dart:10`) [ASSUMED] | §4 | cosmetic, device review |
| A5 | BE `generateQuests` has no error code besides FORBIDDEN (BE D-16) | §6 | unknown codes fall to the generic SnackBar |

## Open Questions (RESOLVED)
1. **Rewards type name?** — RESOLVED: BE `origin/develop` `type QuestRewards { coins: Coins! items: [AssetQuantity!]! }` → field `QuestRewards.pet: Pet`; re-check in the gate.
2. **How does `imagePath` map to a URL?** — RESOLVED: §3 resolver (https as is, `v\d+/` via `CloudinaryAssets.url`, else hidden).
3. **Line order / duplicates / single enemy?** — RESOLVED (discretion): wire order, aggregate by id, bare name for one ×1 entry (C2).
4. **Malformed `enemies` entry in a result?** — RESOLVED: drop the entry, keep the result (C3).
5. **Does crime/guard break anything?** — RESOLVED: no (§8); no fix plan.
6. **Where does the button live during loading?** — RESOLVED: outside the queue builder, always visible.
7. **Exact copy** — delegated to the planner (provisional, user-reviewed on device).
8. **Gate timing** — delegated to the orchestrator: plans 09/10 park until `grep -c QuestEnemy` ≥ 1.

## Environment Availability
| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | all | ✓ | 3.35.5 | — |
| BE repo + `origin/develop` ref | gate | ✓ (fetch OK 2026-11-04) | `0585b2e`, no Phase 13 | if SSH fails, use the local ref and say so |
| node + BE `node_modules/graphql` | `validate_documents.js` | ✓ (used by 13-10) | — | — |
| Android device + local BE | E2E | manual | — | none (human checkpoint) |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (Flutter 3.35.5) + bloc_test 10.0.0 + mocktail 1.0.5 + fake_async 1.3.3 |
| Config file | none (`test/helpers/test_app.dart`, `landscape.dart`, `svg_cache_seed.dart`, `mocks.dart`) |
| Quick run command | `flutter test <touched test paths>` (phase-wide subset measured: 503 tests in 12 s) |
| Full suite command | `flutter test` (3031 tests, ~72 s at the end of Phase 13, `13-11-SUMMARY.md:100`) |
| Analyzer baseline | `flutter analyze` → `50 issues found`, 0 error / 0 warning (measured on this branch = `develop` + docs, 2026-11-04) |

### Phase Requirements → Test Map
| Req | Behavior | Type | Command | File |
|-----|----------|------|---------|------|
| QGEN-01 | `QuestEnemy` parse strict; quest with bad entry skipped, board kept | unit | `flutter test test/models/quest` | `quest_enemy_test.dart` ❌ W0; `quest_test.dart` ✅ |
| QGEN-01 | lines aggregate/order/bare-name; strongest by xp | unit | same | `quest_enemy_test.dart` ❌ W0, `quest_sheet_details_test.dart` ✅ |
| QGEN-01 | portrait URL resolver; widget hides on null/error | unit/widget | `flutter test test/models test/shared/components/enemy_portrait_test.dart` | `enemy_portrait_test.dart` ❌ W0 |
| QGEN-01/05 | combat body lines + Consigliati; description in 3 families; pet prize | widget | `flutter test test/shared/components/popup/quest_info_sheet_test.dart` | ✅ extend |
| QGEN-01 | fragment selects `enemies`, `description`, `pet`; no single `enemy` | unit | `flutter test test/graphql` | `board_documents_test.dart` ✅ |
| QGEN-02 | result parse (enemies lenient, stages, pet, round-trip, isEmpty) | unit | `flutter test test/models/quest_result` | ✅ extend |
| QGEN-02 | result sheet list/portrait/stages/pet line | widget | `flutter test test/shared/components/popup/quest_result_sheet_test.dart` | ✅ extend |
| QGEN-02 | result fragment | unit | `flutter test test/graphql/quest_result_documents_test.dart` | ✅ |
| QGEN-03 | service `generateQuests` (document, `created`, Format) | unit | `flutter test test/repository/services/graphql` | `graphql_generate_quests_test.dart` ❌ W0 |
| QGEN-03 | repository guard (FORBIDDEN, timeout, connection) | unit | `flutter test test/repository/innkeeper_repository_test.dart` | ✅ extend |
| QGEN-03 | cubit states | bloc_test | `flutter test test/screens/innkeeper/questGenerationCubit` | ❌ W0 |
| QGEN-03 | button always visible, dialog, SnackBars, FORBIDDEN closes, disabled in flight | widget | `flutter test test/screens/innkeeper` | ✅ extend |
| QGEN-03 | registry + operation name | unit | `flutter test test/tool test/graphql/quest_mutations_test.dart` | ✅ |
| QGEN-04 | families per type; state label; paper | widget/unit | `flutter test test/shared/components/popup/quest_info_sheet_test.dart test/models/quest` | ✅ existing |
| QGEN-06 | enum parse (unknown dropped), usage line | unit | `flutter test test/models` | `accessory_use_type_test.dart`, `equipment_item_test.dart` ❌ W0 |
| QGEN-06 | item sheet line ring/necklace only | widget | `flutter test test/shared/components/popup/equipment_info_sheet_test.dart` | ✅ extend |
| QGEN-06 | fragments select `accessoryUseTypes` | unit | `flutter test test/graphql` | `shop_documents_test.dart`, `character_fragment_test.dart` ✅ |
| all | documents valid against merged BE schema | gate | dump + `validate_documents.js` (44 documents) | gated plan |

### Sampling Rate
- Per task commit: targeted `flutter test <paths>` (< 15 s).
- Per plan: touched dirs + `flutter analyze` (0 error/0 warning).
- Phase gate (gated plan): full `flutter test` (foreground), analyzer, format of new files, trailer grep = 0, schema check 44 × OK.

### Wave 0 Gaps
- [ ] `test/models/quest/quest_enemy_test.dart`, `test/models/enums/accessory_use_type_test.dart`, `test/models/equipment_item_test.dart`
- [ ] `test/shared/components/enemy_portrait_test.dart` (+ mocktail `BaseCacheManager` fake)
- [ ] `test/repository/services/graphql/graphql_generate_quests_test.dart`
- [ ] `test/screens/innkeeper/questGenerationCubit/quest_generation_cubit_test.dart`
- [ ] `MockQuestGenerationCubit` in `test/helpers/mocks.dart`; fixtures `quest_fixtures.dart` (`enemies`, `description`, `prizes`) and `quest_result_fixtures.dart` (`enemies`, stages, `rewardPet`)

### Manual-only (device, `14-HUMAN-UAT.md`, mirror `13-HUMAN-UAT.md` table: Step | Requirements | Decisions | Expected | Result | Note)
1. Board: a generated `enemy` quest → sheet with announcement, «Nx nome» lines, Consigliati if any, one slot of rank (QGEN-01/05).
2. A `boss` quest → single enemy, party slot lines, «Compagno in premio» when set at DB (QGEN-01, D-06).
3. A fixed dungeon (enriched, 2–4 stages) → combat family, lines, Consigliati; after resolution the result shows the enemies and «Esplorazione: tappa k di N» (QGEN-02/04).
4. crime/guard quest sheet → service family, announcement (QGEN-04/05).
5. Locanda → «Genera missioni» visible with empty queue → Annulla (no call) → Genera → SnackBar with N or «Nessuna missione da generare»; reopen board → new quests (QGEN-03, BE D-18).
6. Non-innkeeper: not reachable; FORBIDDEN path covered by widget tests.
7. Journal/shop ring and necklace → «Uso: …»; helm → no line (QGEN-06).
8. Portrait: set one enemy `imagePath` to a Cloudinary URL at DB → portrait shows; placeholder path → name only (D-03).
Gate re-check at the top of the UAT: `git -C <BE> show origin/develop:src/schema.gql | grep -c "QuestEnemy"` ≥ 1.

### Schema gate procedure (pattern `13-10-SUMMARY.md:63-163`)
```bash
BE=/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE
git -C $BE fetch -q origin develop   # if SSH fails: rely on the local ref and record it
git -C $BE log --oneline -5 origin/develop
git -C $BE show origin/develop:src/schema.gql > "$SCRATCH/schema.gql"
grep -c "QuestEnemy" "$SCRATCH/schema.gql"          # ≥ 1, else park (today: 0)
# prove names: type QuestEnemy, QuestInfos.enemies/description, QuestResult.enemies/stagesCleared/stagesTotal,
# QuestPrizes.pet, QuestRewards.pet, enum AccessoryUseType, EquipmentItem.accessoryUseTypes, generateQuests: GenerateQuestsResult!
dart run tool/schema_check/dump_documents.dart "$SCRATCH/docs"      # dumped 44 documents
NODE_PATH=$BE/node_modules node tool/schema_check/validate_documents.js "$SCRATCH/schema.gql" "$SCRATCH/docs"
```

## Security Domain
| ASVS | Applies | Control |
|------|---------|---------|
| V4 Access Control | yes | BE `@Roles(innkeeper)` on `generateQuests` (BE D-16); FE only maps FORBIDDEN → close panel |
| V5 Input Validation | yes | strict `QuestEnemy` per quest, lenient per result entry, `asNameMap` for enums; texts rendered as plain `Text` |
| V12/V14 resources | yes | portrait only from `https` or Cloudinary-relative paths; no `http`/`file`/`data` |
| V2/V3/V6 | no | unchanged |

| Threat | STRIDE | Mitigation |
|--------|--------|------------|
| Repeated generate taps | DoS/Tampering | confirmation dialog + disabled button + BE target cap |
| Server message leak | Info disclosure | only `extensions.code` |
| Arbitrary image URL from DB | Tampering | resolver allow-list, `errorWidget` hides, `memCacheHeight` |
| Malformed quest/result payload | DoS | per-item tolerant parsing |

## Sources
- Codebase (all file:line above), `pubspec.lock`, `flutter analyze`, targeted `flutter test` (503 green).
- BE read-only: `origin/develop:src/schema.gql` (`0585b2e`), `.planning/phases/13-generazione-quest/13-CONTEXT.md` (D-01, D-12, D-16, D-18, D-21, D-22, D-24), `.planning/phases/11-popolamento-del-mondo/BACKEND-NOTES.md` §1, §3, §9, §11, `11-CONTEXT.md` D-13/D-24.
- FE planning: `13-10-SUMMARY.md`, `13-11-PLAN.md`, `13-HUMAN-UAT.md`, `13-REPO-RULES.md`, `09-RESEARCH.md:197`, `docs/rules/*.md`.

## Metadata
- Standard stack HIGH (lockfile); architecture HIGH (code read); portrait rendering MEDIUM (A2/A3); BE names MEDIUM until the gate.
- Valid until the BE Phase 13 merge (then re-check names in the gate plan).
