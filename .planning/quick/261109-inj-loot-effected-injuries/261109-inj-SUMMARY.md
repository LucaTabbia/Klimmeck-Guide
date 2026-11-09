---
phase: quick-261109-inj
plan: 01
subsystem: items
tags: [loot, injuries, heal, parsing, graphql, item-row]
requirements: [LOOT-01]
key-files:
  created:
    - test/models/loot_item_test.dart
    - test/graphql/loot_fragment_test.dart
  modified:
    - lib/models/loot_item.dart
    - lib/graphql/fragments/loot_fragment.dart
    - lib/graphql/fragments/quest_fragment.dart
    - lib/utils/item_lines.dart
    - lib/shared/components/item_row.dart
    - test/utils/item_lines_test.dart
    - test/shared/components/item_row_test.dart
commits:
  - { message: "test(models): expect the injuries a heal item can cure" }
  - { message: "feat(models): read the injuries a heal item can cure" }
  - { message: "test(graphql): select the effected injuries of loot items" }
  - { message: "feat(graphql): select the effected injuries of loot items" }
  - { message: "test(items): expect the Cura line of a heal item" }
  - { message: "feat(items): show the injuries a heal item can cure" }
---

# Quick 261109-inj: «Cura: …» dagli `effectedInjuries` dei LootItem

`LootItem` legge il nuovo campo `effectedInjuries` del BE (lista di `InjuryType`, tollerante: vuota se assente o non lista, nomi ignoti scartati), i documenti del negozio, del Diario e dei loot lo selezionano via `LootFragment.fields`, il blocco `prizeItem` del `QuestFragment` lo seleziona inline, e `ItemRow` mostra la riga «Cura: cecità, occhio nero» sotto la riga dell'effetto per i soli oggetti heal con almeno una ferita (negozio e Diario). `LootItemCard` e la meccanica di cura restano fuori scope.

## Modifiche
- `loot_item.dart`: `effectedInjuries` (`List<InjuryType>`, default `const []`, `List.unmodifiable` dal filo, parser `_effectedInjuriesFrom` sul modello di `_accessoryUseTypesFrom`), scritto da `toJson`, portato da `copyWith`, nei `props`.
- `loot_fragment.dart`: `effectedInjuries` dopo `power` in `definition` e `fields`; `simpleFields` invariati. `quest_fragment.dart`: `effectedInjuries` nel blocco inline `... on LootItem` di `prizeItem` (recommendedLoot e randomLoot restano ai simpleFields).
- `item_lines.dart` (D-28): `healedInjuriesLine(LootItem)` → «Cura: …» con le etichette di `InjuryTypeExtension.label` in minuscolo, nell'ordine di `InjuryType.values`, unite da `', '`; `null` senza ferite o su un effetto diverso da `heal`.
- `item_row.dart`: terza `Text` in `_buildTexts`, chiave `item-injuries-<id>`, stesso `bodyMedium`.
- Test: `test/models/loot_item_test.dart` (nuovo, 6 casi; RED per compilazione: «The getter 'effectedInjuries' isn't defined for the type 'LootItem'»); `test/graphql/loot_fragment_test.dart` (nuovo, 12 casi: fields/definition, blocco prizeItem, simpleFields, 5 documenti con parse a una sola operazione, registro a 45; RED 9/12); `test/utils/item_lines_test.dart` (+4 casi; RED per compilazione: «Method not found: 'healedInjuriesLine'»); `test/shared/components/item_row_test.dart` (+2 casi; RED sul caso positivo: 0 widget con «Cura: cecità, occhio nero»).

## Gate
- `flutter test test/models test/utils test/shared/components test/graphql test/tool test/screens/mainScreen/tabs/shop test/screens/mainScreen/tabs/journal`: 1408 verdi.
- `flutter analyze 2>&1 | grep -cE '^ *(error|warning) •'` → `0` (50 info, baseline).
- Registro: `tool/schema_check/schema_check_documents.dart` intatto, 45 documenti (test a 45 verdi in `test/tool`, `shop_documents_test`, `travel_documents_test`, `loot_fragment_test`). Nessun documento, dipendenza o id Cloudinary nuovo.
- `dart format` sui 9 file toccati, uno per uno.

## Deviazioni
- Il test del Task 2 vive in un file dedicato `test/graphql/loot_fragment_test.dart` (specchio di `lib/graphql/fragments/loot_fragment.dart`) invece che in `character_fragment_test.dart`, come il piano consentiva.
- Nessun test pinnava il testo esatto del blocco `prizeItem` (solo regex su `effect`/`power` in `board_documents_test`): nessun pin aggiornato. `quest_result_documents_test` pinna il blocco LootItem del `QuestResultFragment`, fuori scope e invariato.
- Task 3 e 4 condividono i due commit `test(items)`/`feat(items)` come nella lista commit del piano (entrambi i RED scritti prima dei GREEN).
- Boy Scout nello stesso commit: virgolette uniformate a singole in `loot_item.dart`; `bodyMedium` estratto una volta in `ItemRow._buildTexts`.
- `LootFragment.definition` non è usato da alcun documento (solo `fields`/`simpleFields`): aggiornato comunque come chiesto dal piano.

## Self-Check: PASSED
