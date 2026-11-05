---
phase: quick-261105-hea
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/models/enums/use_type.dart
  - lib/config/cloudinary_assets.dart
  - lib/models/spell.dart
  - test/models/enums/use_type_test.dart
autonomous: true
requirements: [SPELL-01]

must_haves:
  truths:
    - "UseType has a ninth value heal, labelled «Cura», parsed from the wire name heal"
    - "A spell whose useType is unknown to the client parses with useType null instead of throwing"
    - "spellDamageLabel prefixes a heal spell's energy with «Cura»"
  artifacts:
    - path: "lib/models/enums/use_type.dart"
      contains: "heal("
    - path: "lib/models/spell.dart"
      contains: "UseType.values.asNameMap()[json['useType']]"
    - path: "test/models/enums/use_type_test.dart"
      contains: "heal reads Cura"
---

# Quick 261105-hea: `heal` fra i tipi d'uso delle magie

Regola dell'utente (2026-11-05, contenuto dei mostri): le magie di cura hanno un `useType` proprio, `heal`. Il BE lo aggiunge all'enum Mongoose (quick task BE sullo stesso nome di branch, nessuna modifica SDL: `useType` viaggia come `String`); la FE deve conoscerlo prima che il DB contenga magie `heal`, perché `UseType.values.byName` lancia su un nome ignoto.

## Task
1. RED `test/models/enums/use_type_test.dart`: nomi sul filo con `heal` in coda, etichetta «Cura», parsing di una magia `heal`, etichetta «Cura: Radioso 600», un `useType` ignoto ⇒ `null`.
2. GREEN: `UseType.heal(imageId: CloudinaryAssets.healUse, label: "Cura")`; `CloudinaryAssets.healUse` provvisorio sull'icona di Potenziare finché l'utente non carica l'asset; `Spell.fromJson` legge il tipo con `asNameMap()` (ignoto ⇒ `null`, Boy Scout di robustezza).
3. Gate: test dei modelli e del diario, `flutter analyze` senza errori né warning, `dart format` sui soli file toccati.
