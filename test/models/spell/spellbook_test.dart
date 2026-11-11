import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';

import '../../helpers/fixtures/spell_fixtures.dart';

const _a = 'spell-a';
const _b = 'spell-b';
const _c = 'spell-c';

final _spellA = Spell.fromJson(spellJson(id: _a));
final _spellB = Spell.fromJson(spellJson(id: _b));

/// Magie conosciute nell'ordine di [known], a usi pieni e senza ricariche;
/// [active] sono le equipaggiate.
Character _character({
  int? maxActiveSpells = 2,
  List<String> known = const [_a, _b, _c],
  List<String> active = const [],
}) => _single([
  for (final id in known)
    spellStateJson(
      spellId: id,
      usages: 3,
      recoveries: const [],
      active: active.contains(id),
    ),
], slots: maxActiveSpells);

List<String> _entryIds(Spellbook spellbook) =>
    spellbook.entries.map((entry) => entry.spell.id).toList();

const _s1 = 's-1';
const _s2 = 's-2';
const _s3 = 's-3';

Character _single(List<Map<String, dynamic>> states, {int? slots = 2}) =>
    spellbookCharacter(maxActiveSpells: slots, spellStates: states);

Map<String, dynamic> _state(String id, {bool active = false, int usages = 1}) =>
    spellStateJson(spellId: id, usages: usages, active: active);

List<String?> _slotIds(Spellbook spellbook) =>
    spellbook.slots.map((slot) => slot.spell?.id).toList();

void main() {
  group('view', () {
    test('a null character is not visible and has nothing to render', () {
      final spellbook = Spellbook.of(null);

      expect(spellbook.isVisible, isFalse);
      expect(spellbook.slotCount, 0);
      expect(spellbook.slots, isEmpty);
      expect(spellbook.entries, isEmpty);
    });

    test('no spells and no slots is not visible', () {
      expect(
        Spellbook.of(_character(known: const [], maxActiveSpells: 0)).isVisible,
        isFalse,
      );
      expect(
        Spellbook.of(
          _character(known: const [], maxActiveSpells: null),
        ).isVisible,
        isFalse,
      );
    });

    test('no spells with slots is visible with empty slots', () {
      final spellbook = Spellbook.of(
        _character(known: const [], maxActiveSpells: 2),
      );

      expect(spellbook.isVisible, isTrue);
      expect(spellbook.slotCount, 2);
      expect(spellbook.slots, const [SpellSlot.empty(), SpellSlot.empty()]);
      expect(spellbook.entries, isEmpty);
    });

    test('one spell without slots is visible with no slot row', () {
      final spellbook = Spellbook.of(
        _character(known: const [_a], maxActiveSpells: 0),
      );

      expect(spellbook.isVisible, isTrue);
      expect(spellbook.slotCount, 0);
      expect(spellbook.slots, isEmpty);
      expect(_entryIds(spellbook), [_a]);
    });

    test('the slot row has maxActiveSpells slots filled in order', () {
      final spellbook = Spellbook.of(
        _character(maxActiveSpells: 4, active: const [_a]),
      );

      expect(spellbook.slots, hasLength(4));
      expect(spellbook.slots[0].spell, _spellA);
      expect(spellbook.slots.skip(1).every((slot) => slot.isEmpty), isTrue);
    });

    test('active spells past the slot count stay only in the list', () {
      final spellbook = Spellbook.of(
        _character(maxActiveSpells: 1, active: const [_a, _b]),
      );

      expect(spellbook.slots, hasLength(1));
      expect(spellbook.slots[0].spell, _spellA);
      expect(spellbook.entryFor(_b)?.isActive, isTrue);
    });

    test('entries keep the order of the states', () {
      final spellbook = Spellbook.of(
        _character(known: const [_c, _a, _b], active: const [_b, _a]),
      );

      expect(_entryIds(spellbook), [_c, _a, _b]);
      expect(spellbook.entries.map((entry) => entry.isActive), [
        false,
        true,
        true,
      ]);
    });

    test('usages and recoveries come from the spell state when present', () {
      final spellbook = Spellbook.of(
        _single([spellStateJson(spellId: _a, usages: 1, active: true)]),
      );

      final entry = spellbook.entryFor(_a);
      expect(entry?.usages, 1);
      expect(spellbook.slots[0].usages, 1);
      expect(entry?.recoveries, [
        DateTime.utc(2026, 10, 27, 10, 12),
        DateTime.utc(2026, 10, 27, 10, 42),
      ]);
    });

    test('entryFor returns the entry or null for an unknown id', () {
      final spellbook = Spellbook.of(_character());

      expect(spellbook.entryFor(_a)?.spell, _spellA);
      expect(spellbook.entryFor('spell-unknown'), isNull);
    });

    test('equal inputs give equal spellbooks', () {
      Spellbook build() =>
          Spellbook.of(_single([spellStateJson(spellId: _a, active: true)]));

      expect(build(), build());
    });
  });

  group('overlay', () {
    test(
      'a pending equip takes the next slot in list order and is marked pending',
      () {
        final spellbook = Spellbook.of(
          _character(active: const [_a]),
          pending: const {_b: SpellOperation.equip},
        );

        expect(spellbook.activeSpellIds, [_a, _b]);
        expect(spellbook.slots[1].spell, _spellB);
        expect(spellbook.slots[1].isPending, isTrue);
        expect(spellbook.slots[0].isPending, isFalse);
        expect(spellbook.entryFor(_b)?.isActive, isTrue);
        expect(spellbook.entryFor(_b)?.isPending, isTrue);
      },
    );

    test('a pending unequip leaves the slot and compacts the row', () {
      final spellbook = Spellbook.of(
        _character(active: const [_a, _b]),
        pending: const {_a: SpellOperation.unequip},
      );

      expect(spellbook.activeSpellIds, [_b]);
      expect(spellbook.slots[0].spell, _spellB);
      expect(spellbook.slots[1].isEmpty, isTrue);
      expect(spellbook.entryFor(_a)?.isActive, isFalse);
      expect(spellbook.entryFor(_a)?.isPending, isTrue);
    });

    test('pending equips follow the list order, not the tap order (D-14)', () {
      final spellbook = Spellbook.of(
        _character(maxActiveSpells: 3, active: const [_a]),
        pending: const {_c: SpellOperation.equip, _b: SpellOperation.equip},
      );

      expect(spellbook.activeSpellIds, [_a, _b, _c]);
    });

    test('a pending equip of a spell active server-side is not duplicated', () {
      final spellbook = Spellbook.of(
        _character(active: const [_a]),
        pending: const {_a: SpellOperation.equip},
      );

      expect(spellbook.activeSpellIds, [_a]);
      expect(spellbook.slots[1].isEmpty, isTrue);
    });

    test('a pending equip of an unknown spell is ignored', () {
      final spellbook = Spellbook.of(
        _character(active: const [_a]),
        pending: const {'spell-unknown': SpellOperation.equip},
      );

      expect(spellbook.activeSpellIds, [_a]);
      expect(spellbook.slots[1].isEmpty, isTrue);
      expect(spellbook.entryFor('spell-unknown'), isNull);
    });

    test('a pending equip slot takes its usages from the spell state', () {
      final spellbook = Spellbook.of(
        _single([_state(_a), _state(_b, usages: 1)]),
        pending: const {_b: SpellOperation.equip},
      );

      expect(spellbook.slots[0].spell, _spellB);
      expect(spellbook.slots[0].usages, 1);
    });
  });

  group('intentFor', () {
    test('a pending spell is ignored', () {
      final spellbook = Spellbook.of(
        _character(active: const [_a]),
        pending: const {_a: SpellOperation.unequip},
      );

      expect(spellbook.intentFor(_a), SpellToggleIntent.ignoredPending);
    });

    test('an active spell is unequipped', () {
      final spellbook = Spellbook.of(_character(active: const [_a]));

      expect(spellbook.intentFor(_a), SpellToggleIntent.unequip);
    });

    test('an inactive spell with a free slot is equipped', () {
      final spellbook = Spellbook.of(_character(active: const [_a]));

      expect(spellbook.intentFor(_b), SpellToggleIntent.equip);
    });

    test('slots full on the optimistic count block the equip', () {
      final spellbook = Spellbook.of(
        _character(maxActiveSpells: 2, active: const [_a]),
        pending: const {_c: SpellOperation.equip},
      );

      expect(spellbook.intentFor(_b), SpellToggleIntent.blockedSlotsFull);
    });

    test('slots full on the server count block the equip', () {
      final spellbook = Spellbook.of(
        _character(maxActiveSpells: 1, active: const [_a]),
      );

      expect(spellbook.intentFor(_b), SpellToggleIntent.blockedSlotsFull);
    });

    test('no slots block the equip of an inactive spell', () {
      final spellbook = Spellbook.of(_character(maxActiveSpells: 0));

      expect(spellbook.intentFor(_b), SpellToggleIntent.blockedNoSlots);
    });

    test('no slots still allow the unequip of a legacy active spell', () {
      final spellbook = Spellbook.of(
        _character(maxActiveSpells: 0, active: const [_a]),
      );

      expect(spellbook.intentFor(_a), SpellToggleIntent.unequip);
    });

    test('an unknown spell is ignored', () {
      final spellbook = Spellbook.of(_character());

      expect(
        spellbook.intentFor('spell-unknown'),
        SpellToggleIntent.ignoredUnknown,
      );
    });

    test('a pending unequip frees the slot for another equip', () {
      final spellbook = Spellbook.of(
        _character(maxActiveSpells: 1, active: const [_a]),
        pending: const {_a: SpellOperation.unequip},
      );

      expect(spellbook.intentFor(_b), SpellToggleIntent.equip);
    });
  });

  group('single state list (BE Phase 19)', () {
    test('known spells are all the states in list order (D-05)', () {
      final spellbook = Spellbook.of(
        _single([_state(_s2), _state(_s1), _state(_s3)]),
      );

      expect(_entryIds(spellbook), [_s2, _s1, _s3]);
      expect(spellbook.isVisible, isTrue);
    });

    test('equipped spells are the states with active (D-05)', () {
      final spellbook = Spellbook.of(
        _single([
          _state(_s1),
          _state(_s2, active: true),
          _state(_s3, active: true),
        ]),
      );

      expect(spellbook.activeSpellIds, [_s2, _s3]);
      expect(spellbook.entries[0].isActive, isFalse);
      expect(spellbook.entries[1].isActive, isTrue);
    });

    test('usages and recoveries come from the same entry (D-05)', () {
      final spellbook = Spellbook.of(
        _single([
          _state(_s1, usages: 3),
          spellStateJson(
            spellId: _s2,
            usages: 2,
            active: true,
            recoveries: const ['2026-10-27T11:00:00.000Z'],
          ),
        ]),
      );

      expect(spellbook.entries[1].usages, 2);
      expect(spellbook.slots[0].usages, 2);
      expect(spellbook.entries[1].recoveries, [DateTime.utc(2026, 10, 27, 11)]);
      expect(spellbook.entries[0].usages, 3);
    });

    test(
      'the slots follow the order of the states, not an equip order (D-14)',
      () {
        final spellbook = Spellbook.of(
          _single([
            _state(_s1, active: true),
            _state(_s2),
            _state(_s3, active: true),
          ]),
        );

        expect(_slotIds(spellbook), [_s1, _s3]);
      },
    );

    test('a pending equip takes its place in the list order (D-14)', () {
      final spellbook = Spellbook.of(
        _single([
          _state(_s1),
          _state(_s2, active: true),
          _state(_s3, active: true),
        ], slots: 3),
        pending: const {_s1: SpellOperation.equip},
      );

      expect(spellbook.activeSpellIds, [_s1, _s2, _s3]);
      expect(_slotIds(spellbook), [_s1, _s2, _s3]);
    });

    test(
      'a pending unequip frees its slot and the others keep their order (D-05, D-14)',
      () {
        final spellbook = Spellbook.of(
          _single([
            _state(_s1, active: true),
            _state(_s2, active: true),
            _state(_s3, active: true),
          ], slots: 3),
          pending: const {_s2: SpellOperation.unequip},
        );

        expect(spellbook.activeSpellIds, [_s1, _s3]);
        expect(_slotIds(spellbook), [_s1, _s3, null]);
        expect(spellbook.entryFor(_s2)?.isActive, isFalse);
      },
    );

    test(
      'a pending operation marks the entry and its slot as pending (D-05)',
      () {
        final spellbook = Spellbook.of(
          _single([_state(_s1), _state(_s2, active: true)]),
          pending: const {_s1: SpellOperation.equip},
        );

        expect(spellbook.entryFor(_s1)?.isPending, isTrue);
        expect(spellbook.slots[0].isPending, isTrue);
        expect(spellbook.entryFor(_s2)?.isPending, isFalse);
        expect(spellbook.slots[1].isPending, isFalse);
      },
    );

    test('more active states than slots fill only the slots (D-05)', () {
      final spellbook = Spellbook.of(
        _single([
          _state(_s1, active: true),
          _state(_s2, active: true),
          _state(_s3, active: true),
        ]),
      );

      expect(_slotIds(spellbook), [_s1, _s2]);
      expect(spellbook.entryFor(_s3)?.isActive, isTrue);
    });

    test('a pending equip of an unknown spell changes nothing (D-05)', () {
      final character = _single([_state(_s1, active: true), _state(_s2)]);
      final spellbook = Spellbook.of(
        character,
        pending: const {'s-unknown': SpellOperation.equip},
      );

      expect(spellbook.activeSpellIds, [_s1]);
      expect(_slotIds(spellbook), [_s1, null]);
      expect(spellbook.entries, Spellbook.of(character).entries);
      expect(spellbook.entryFor('s-unknown'), isNull);
    });

    test('a duplicated state of the same spell is listed once (D-05)', () {
      final spellbook = Spellbook.of(
        _single([_state(_s1, usages: 2), _state(_s1, usages: 0, active: true)]),
      );

      expect(_entryIds(spellbook), [_s1]);
      expect(spellbook.entries.single.usages, 2);
      expect(spellbook.activeSpellIds, isEmpty);
    });

    test('the section is hidden without states and without slots (D-05)', () {
      expect(Spellbook.of(_single(const [], slots: 0)).isVisible, isFalse);
      expect(Spellbook.of(_single(const [], slots: null)).isVisible, isFalse);
      expect(Spellbook.of(_single(const [], slots: 2)).isVisible, isTrue);
    });

    test('a null character gives an empty hidden view (D-05)', () {
      final spellbook = Spellbook.of(null);

      expect(spellbook.isVisible, isFalse);
      expect(spellbook.slots, isEmpty);
      expect(spellbook.entries, isEmpty);
      expect(spellbook.activeSpellIds, isEmpty);
    });
  });
}
