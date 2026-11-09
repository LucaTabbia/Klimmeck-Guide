---
phase: quick-261109-inj
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/models/loot_item.dart
  - lib/graphql/fragments/loot_fragment.dart
  - lib/graphql/fragments/quest_fragment.dart
  - lib/utils/item_lines.dart
  - lib/shared/components/item_row.dart
  - test/models/loot_item_test.dart
  - test/utils/item_lines_test.dart
  - test/shared/components/item_row_test.dart
  - test/graphql/character_fragment_test.dart
autonomous: true
requirements: [LOOT-01]

must_haves:
  truths:
    - "LootItem.effectedInjuries is an unmodifiable List<InjuryType>: const [] when the wire omits it or sends a non-list, unknown names dropped, written back by toJson, carried by copyWith, part of props"
    - "LootFragment.definition and LootFragment.fields select effectedInjuries; the quest fragment's inline LootItem block selects it too; simpleFields unchanged; the registry stays at 45 documents"
    - "healedInjuriesLine(item) is «Cura: <labels>» (Italian InjuryType labels in enum order, lower case, joined by ', ') only for a heal item with at least one injury; null otherwise"
    - "ItemRow shows that line under the effect line (shop and Journal), keyed item-injuries-<id>; LootItemCard unchanged"
  artifacts:
    - path: "lib/models/loot_item.dart"
      contains: "effectedInjuries"
    - path: "lib/utils/item_lines.dart"
      contains: "healedInjuriesLine"
    - path: "lib/shared/components/item_row.dart"
      contains: "item-injuries-"
  key_links:
    - from: "lib/shared/components/item_row.dart"
      to: "lib/utils/item_lines.dart"
      via: "healedInjuriesLine(lootItem)"
      pattern: "healedInjuriesLine"
---

# Quick 261109-inj: «Cura: …» dagli `effectedInjuries` dei LootItem

Regola dell'utente (2026-11-09): i `LootItem` hanno un nuovo campo `effectedInjuries` (lista di `InjuryType`) che dice quali ferite un oggetto heal può curare. Il BE lo aggiunge con il quick task gemello (stesso nome di branch, `effectedInjuries: [InjuryType!]!` su `type LootItem`); la FE lo legge in modo tollerante e lo mostra subito come riga «Cura: …» sugli oggetti heal nel negozio e nel Diario (scelta dell'utente), anche se la meccanica di cura non esiste ancora (nessun uso oggetti: le pozioni si bevono da sole in combattimento, le ferite si curano con le quest «heal»). Il contenuto a DB lo scrive l'orchestratore dopo la revisione dell'utente.

## Oggi (leggi prima)
- `lib/models/loot_item.dart`: `LootItem extends AssetItem` con `effect: EffectType?`, `power: int?`, `fromJson` tollerante su prezzi e `description`, `toJson`, `copyWith`, `props`.
- `lib/models/enums/injury_type.dart`: 28 valori con `label` italiana (estensione `InjuryTypeExtension`), nello stesso ordine del BE.
- `lib/graphql/fragments/loot_fragment.dart`: `definition` (fragment `LootItemFields`) e `fields` (id name description rarity effect power buyPrice{…} sellPrice{…}), `simpleFields` (id name itemType rarity). `lib/graphql/fragments/quest_fragment.dart:78-88`: blocco inline `... on LootItem { ${LootFragment.simpleFields} description effect power }`. `character_fragment.dart` usa `LootFragment.fields` (ownedItems). Registro: 45 documenti (nessun documento nuovo qui).
- `lib/utils/item_lines.dart`: `itemEffectLabel(LootItem)` («Cura: 12»), `accessoryUsageLine(EquipmentItem)` («Uso: attacco e difesa», etichette in minuscolo, ordine canonico) — ogni copy delle righe oggetto vive qui (D-28).
- `lib/shared/components/item_row.dart`: `_buildTexts(effectLine)` → `Column` con la descrizione e il `Text(effectLine, key: ValueKey('item-effect-<id>'))`; usato da `shop_modal.dart` e `journal.dart`.
- Test esistenti: `test/utils/item_lines_test.dart`, `test/shared/components/item_row_test.dart`, `test/shared/components/cards/loot_item_card_test.dart`, `test/graphql/character_fragment_test.dart`; nessun `test/models/loot_item_test.dart` (nuovo).
- Regole: `docs/rules/testing.md`, `docs/rules/graphql.md` (il registro conta i documenti, non i campi), analyzer 0 error / 0 warning (baseline ≈ 50 info), `dart format` solo sui file toccati, niente Co-Authored-By.

## Task
1. RED `test/models/loot_item_test.dart` (nuovo): parse di `effectedInjuries: ['deepCut', 'infection']` → `[InjuryType.deepCut, InjuryType.infection]` immutabile; nome ignoto (`'brokenWing'`) scartato; campo assente o non lista → `[]`; `toJson` scrive i nomi; `fromJson(toJson())` uguale (Equatable). GREEN in `loot_item.dart` (`this.effectedInjuries = const []`, parser tollerante, `List.unmodifiable`, `copyWith`, `props`).
2. RED `test/graphql/character_fragment_test.dart` (o un test dedicato in `test/graphql/`): `LootFragment.fields` e `LootFragment.definition` contengono `effectedInjuries`; il blocco inline del `QuestFragment` lo seleziona; `LootFragment.simpleFields` no; il conteggio del registro resta 45. GREEN nei due fragment (aggiungi `effectedInjuries` dopo `power`). Se un test dei documenti pinna il testo esatto del blocco, aggiornalo nello stesso commit del fragment e dillo nel SUMMARY.
3. RED `test/utils/item_lines_test.dart`: oggetto heal con `[blackEye, blindness]` → «Cura: cecità, occhio nero» (ordine dell'enum: `blindness` precede `blackEye`? NO: l'ordine è quello di `InjuryType.values` — `blindness` è il 5°, `blackEye` il 6° → «Cura: cecità, occhio nero»); heal senza ferite → `null`; `hunger` con ferite → `null`. GREEN `healedInjuriesLine(LootItem)` in `item_lines.dart`, etichette `label.toLowerCase()` unite da `', '`, filtro `effect == EffectType.heal`.
4. RED `test/shared/components/item_row_test.dart`: per un oggetto heal con ferite compare `find.byKey(ValueKey('item-injuries-<id>'))` con il testo «Cura: …» sotto la riga dell'effetto; per un oggetto senza ferite non compare. GREEN in `ItemRow._buildTexts` (terza `Text`, stesso stile `bodyMedium`). `LootItemCard` invariata.
5. Gate: `flutter test test/models test/utils test/shared/components test/graphql` verde; `flutter analyze 2>&1 | grep -cE '^ *(error|warning) •'` → `0`; `dart format` sui soli file toccati, uno per uno.

## Commit (subject ≤ 72 byte, nessun trailer, file per nome)
- `test(models): expect the injuries a heal item can cure`
- `feat(models): read the injuries a heal item can cure`
- `test(graphql): select the effected injuries of loot items`
- `feat(graphql): select the effected injuries of loot items`
- `test(items): expect the Cura line of a heal item`
- `feat(items): show the injuries a heal item can cure`
- `docs(quick): record 261109-inj`

## Fuori scope
Meccanica di cura, `LootItemCard`, fogli delle quest, nuovi documenti GraphQL, ROADMAP (solo una riga «Last activity» in STATE.md se il protocollo dei quick task lo prevede).
