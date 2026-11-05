---
phase: quick-261105-hea
plan: 01
subsystem: spells
tags: [spell, use-type, heal, parsing]
requirements: [SPELL-01]
key-files:
  modified:
    - lib/models/enums/use_type.dart
    - lib/config/cloudinary_assets.dart
    - lib/models/spell.dart
    - test/models/enums/use_type_test.dart
commits:
  - { message: "test(spell): expect the heal use type and tolerant parsing" }
  - { message: "feat(spell): add the heal use type and parse unknown use types as null" }
---

# Quick 261105-hea: `heal` fra i tipi d'uso delle magie

`UseType` ha il nono valore `heal` («Cura»); `Spell.fromJson` non lancia più su un tipo d'uso ignoto (restituisce `null`), così una magia nuova sul server non rompe il diario né le schede. L'icona di `heal` è l'asset dedicato caricato dall'utente (`CloudinaryAssets.healUse`, `v1793889299/heal_edhg35.svg`).

## Modifiche
- `use_type.dart`: valore `heal` in coda (ordine del filo invariato per gli altri otto).
- `cloudinary_assets.dart`: costante `healUse` (asset dedicato, prima provvisoria sull'icona di Potenziare).
- `spell.dart`: `useType: UseType.values.asNameMap()[json['useType']]`.
- Test: `use_type_test.dart` (4 casi; RED confermato per compilazione: «Member not found: 'heal'»).

## Gate
- `flutter test test/models test/utils/spell_lines_test.dart`: verdi; `test/screens/mainScreen/tabs/journal`: verdi.
- `flutter analyze`: 0 errori, 0 warning (baseline di develop: 0).
- `dart format` sui 4 file toccati.

## Deviazioni
Nessuna. L'icona provvisoria del primo commit è stata sostituita dall'asset dedicato nello stesso quick task.
