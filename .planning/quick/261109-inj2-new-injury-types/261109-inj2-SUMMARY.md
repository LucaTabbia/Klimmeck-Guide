---
phase: quick-261109-inj2
plan: 01
subsystem: models
tags: [injuries, enum, parsing, character-status, tolerant-read]
requirements: [LOOT-01]
key-files:
  modified:
    - lib/models/enums/injury_type.dart
    - lib/models/character/character_status.dart
    - test/models/enums/injury_type_test.dart
    - test/models/character/character_status_test.dart
    - test/screens/innkeeper/components/completion_form_test.dart
commits:
  - { message: "test(models): expect the nine new injury types" }
  - { message: "feat(models): add nine injury types with labels and effects" }
  - { message: "test(models): drop unknown injuries of the character status" }
  - { message: "fix(models): read the character injuries tolerantly" }
---

# Quick 261109-inj2: nove ferite nuove nella FE

`InjuryType` passa da 28 a 37 valori: `contusion`, `punctureWound`, `muscleTear`, `exhaustion`, `sprain`, `dislocatedShoulder`, `brokenNose`, `hypothermia`, `stunned` in coda dopo `spinalInjury`, nell'ordine della tabella del piano, con `severity`, `effects` ed etichetta italiana (Contusione, Ferita da punta, Strappo muscolare, Sfinimento, Distorsione, Spalla lussata, Naso rotto, Assideramento, Stordimento). `CharacterStatus.fromJson` non lancia più su un nome di ferita ignoto: lo scarta con `asNameMap()` come già fanno `QuestResult._injuriesFrom` e `LootItem`, così un BE più nuovo non rompe mai la lettura del personaggio. La riga «Cura: …» del quick 261109-inj mostra da sola le nuove etichette (nessuna modifica a `item_lines.dart`).

## Modifiche
- `injury_type.dart`: nove valori appesi dopo `spinalInjury` (37 in tutto) con severity/effects della tabella; nove `case` nello `switch` esaustivo di `InjuryTypeExtension.label`. `dart format` ha riavvolto anche le righe lunghe preesistenti dei 28 valori (il file non era formatter-clean a HEAD).
- `character_status.dart`: `injuries: _injuriesFrom(json['injuries'])`; il nuovo parser statico restituisce `const []` su assente/null/non-lista e `List<InjuryType>.unmodifiable` dei soli nomi conosciuti (`asNameMap()` + `nonNulls`). `toJson`, `copyWith`, `props` invariati.
- Test Task 1: `test/models/enums/injury_type_test.dart` (6 casi: registro dei nomi a 37, etichette, gruppo «quick 261109-inj2» con ordine in coda, severity/effects dei nove, pin su `blackEye` 5 e `spinalInjury` 80; RED per compilazione: «Member not found: 'contusion'» e gli altri otto); `test/screens/innkeeper/components/completion_form_test.dart` (pin 28→37 su `InjuryType.values.length` e `findsNWidgets`; RED `Expected: <37> Actual: <28>`). GREEN: 22 verdi sui due file.
- Test Task 2: `test/models/character/character_status_test.dart` (+7 casi nel gruppo «injuries (quick 261109-inj2)»: nome ignoto scartato `['deepCut','brokenWing','stunned']` → `[deepCut, stunned]`, assente → lista vuota non null, null → lista vuota, non-lista → lista vuota e stato intero, lista immutabile, `toJson`, `copyWith`; RED 3/7: «Invalid argument (name): No enum value with that name: "brokenWing"», «NoSuchMethodError: Class 'String' has no instance method 'map'», nessun `UnsupportedError` sulla `add`). GREEN: 39 verdi sul file.

## Gate
- `flutter test` (suite intera, foreground): 3565 verdi.
- `flutter analyze 2>&1 | grep -cE '^ *(error|warning) •'` → `0` (50 info, baseline; nessuna info sui file toccati).
- Registro GraphQL: `tool/schema_check/schema_check_documents.dart` intatto, 45 voci (test `the registry lists 45 documents (D-12)` verde). Nessun documento, dipendenza o id Cloudinary nuovo (`git diff 187e069..HEAD -- lib/graphql pubspec.yaml pubspec.lock lib/config/cloudinary_assets.dart tool/` vuoto).
- `dart format` sui 4 file Dart toccati, uno per uno (`completion_form_test.dart` già formattato: 0 changed).

## Deviazioni
- `test/screens/innkeeper/components/completion_form_test.dart` non era nei `files_modified` del piano: pinnava 28 valori e 28 `FilterChip`, sarebbe andato rosso col Task 1 (Rule 3). Aggiornato a 37 nel commit RED `test(models)`; i 37 chip stanno in un `SingleChildScrollView`, nessun overflow.
- Il parser tollera anche un payload `injuries` non-lista (→ lista vuota), caso non elencato dal piano ma coerente con `_unlockedLoreFrom` e `LootItem` e con la truth «un BE più nuovo non rompe mai la lettura».
- La lista `injuries` assente resta vuota e non null (comportamento pinnato), ma ora è immutabile: nessun chiamante in `lib/` muta `status.injuries` (grep su add/remove/clear/sort/insert vuoto).
- Boy Scout nello stesso commit GREEN del Task 1: il riavvolgimento delle righe lunghe dell'enum dovuto a `dart format` (sopra).

## Known Stubs
Nessuno.

## Self-Check: PASSED
