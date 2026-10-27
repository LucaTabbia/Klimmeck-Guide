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

Character _character({
  int? maxActiveSpells = 2,
  List<String> known = const [_a, _b, _c],
  List<Map<String, dynamic>> activeSpells = const [],
  List<Map<String, dynamic>>? spellStates,
}) => spellbookCharacter(
  maxActiveSpells: maxActiveSpells,
  spells: [for (final id in known) spellJson(id: id)],
  activeSpells: activeSpells,
  spellStates: spellStates,
);

Map<String, dynamic> _active(String id, {int usages = 3}) =>
    activeSpellJson(spellId: id, usages: usages);

List<String> _entryIds(Spellbook spellbook) =>
    spellbook.entries.map((entry) => entry.spell.id).toList();

void main() {
  group('join', () {
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
        _character(maxActiveSpells: 4, activeSpells: [_active(_a)]),
      );

      expect(spellbook.slots, hasLength(4));
      expect(spellbook.slots[0].spell, _spellA);
      expect(spellbook.slots.skip(1).every((slot) => slot.isEmpty), isTrue);
    });

    test('an active entry with a null spell is skipped', () {
      final spellbook = Spellbook.of(
        _character(
          activeSpells: [
            {'usages': 3, 'spell': null},
            _active(_a),
          ],
        ),
      );

      expect(spellbook.slots[0].spell, _spellA);
      expect(spellbook.slots[1].isEmpty, isTrue);
    });

    test('active spells past the slot count stay only in the list', () {
      final spellbook = Spellbook.of(
        _character(
          maxActiveSpells: 1,
          activeSpells: [_active(_a), _active(_b)],
        ),
      );

      expect(spellbook.slots, hasLength(1));
      expect(spellbook.slots[0].spell, _spellA);
      expect(spellbook.entryFor(_b)?.isActive, isTrue);
    });

    test('entries keep the order of status.spells', () {
      final spellbook = Spellbook.of(
        _character(
          known: const [_c, _a, _b],
          activeSpells: [_active(_b), _active(_a)],
        ),
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
        _character(
          activeSpells: [_active(_a, usages: 3)],
          spellStates: [spellStateJson(spellId: _a, usages: 1)],
        ),
      );

      final entry = spellbook.entryFor(_a);
      expect(entry?.usages, 1);
      expect(spellbook.slots[0].usages, 1);
      expect(entry?.recoveries, [
        DateTime.utc(2026, 10, 27, 10, 12),
        DateTime.utc(2026, 10, 27, 10, 42),
      ]);
    });

    test('without spell states an active spell uses ActiveSpell.usages', () {
      final spellbook = Spellbook.of(
        _character(activeSpells: [_active(_a, usages: 2)]),
      );

      expect(spellbook.entryFor(_a)?.usages, 2);
      expect(spellbook.slots[0].usages, 2);
    });

    test('an inactive spell without state uses the catalog maxUsages', () {
      final entry = Spellbook.of(_character()).entryFor(_b);

      expect(entry?.usages, _spellB.maxUsages);
      expect(entry?.usages, 3);
      expect(entry?.recoveries, isEmpty);
    });

    test('spell states without the spell fall back to the active usages', () {
      final spellbook = Spellbook.of(
        _character(
          activeSpells: [_active(_a, usages: 2)],
          spellStates: [spellStateJson(spellId: _b, usages: 0)],
        ),
      );

      expect(spellbook.entryFor(_a)?.usages, 2);
      expect(spellbook.slots[0].usages, 2);
    });

    test('entryFor returns the entry or null for an unknown id', () {
      final spellbook = Spellbook.of(_character());

      expect(spellbook.entryFor(_a)?.spell, _spellA);
      expect(spellbook.entryFor('spell-unknown'), isNull);
    });

    test('equal inputs give equal spellbooks', () {
      Spellbook build() => Spellbook.of(
        _character(
          activeSpells: [_active(_a)],
          spellStates: [spellStateJson(spellId: _a)],
        ),
      );

      expect(build(), build());
    });
  });

  group('overlay', () {
    test('a pending equip is appended to the slots and marked pending', () {
      final spellbook = Spellbook.of(
        _character(activeSpells: [_active(_a)]),
        pending: const {_b: SpellOperation.equip},
      );

      expect(spellbook.activeSpellIds, [_a, _b]);
      expect(spellbook.slots[1].spell, _spellB);
      expect(spellbook.slots[1].isPending, isTrue);
      expect(spellbook.slots[0].isPending, isFalse);
      expect(spellbook.entryFor(_b)?.isActive, isTrue);
      expect(spellbook.entryFor(_b)?.isPending, isTrue);
    });

    test('a pending unequip leaves the slot and compacts the row', () {
      final spellbook = Spellbook.of(
        _character(activeSpells: [_active(_a), _active(_b)]),
        pending: const {_a: SpellOperation.unequip},
      );

      expect(spellbook.activeSpellIds, [_b]);
      expect(spellbook.slots[0].spell, _spellB);
      expect(spellbook.slots[1].isEmpty, isTrue);
      expect(spellbook.entryFor(_a)?.isActive, isFalse);
      expect(spellbook.entryFor(_a)?.isPending, isTrue);
    });

    test('pending equips are appended in tap order', () {
      final spellbook = Spellbook.of(
        _character(maxActiveSpells: 3, activeSpells: [_active(_a)]),
        pending: const {_c: SpellOperation.equip, _b: SpellOperation.equip},
      );

      expect(spellbook.activeSpellIds, [_a, _c, _b]);
    });

    test('a pending equip of a spell active server-side is not duplicated', () {
      final spellbook = Spellbook.of(
        _character(activeSpells: [_active(_a)]),
        pending: const {_a: SpellOperation.equip},
      );

      expect(spellbook.activeSpellIds, [_a]);
      expect(spellbook.slots[1].isEmpty, isTrue);
    });

    test('a pending equip of an unknown spell is ignored', () {
      final spellbook = Spellbook.of(
        _character(activeSpells: [_active(_a)]),
        pending: const {'spell-unknown': SpellOperation.equip},
      );

      expect(spellbook.activeSpellIds, [_a]);
      expect(spellbook.slots[1].isEmpty, isTrue);
      expect(spellbook.entryFor('spell-unknown'), isNull);
    });

    test('a pending equip slot takes its usages from the spell state', () {
      final spellbook = Spellbook.of(
        _character(spellStates: [spellStateJson(spellId: _b, usages: 1)]),
        pending: const {_b: SpellOperation.equip},
      );

      expect(spellbook.slots[0].spell, _spellB);
      expect(spellbook.slots[0].usages, 1);
    });

    test('a pending equip slot without state uses the catalog maxUsages', () {
      final spellbook = Spellbook.of(
        _character(),
        pending: const {_b: SpellOperation.equip},
      );

      expect(spellbook.slots[0].usages, _spellB.maxUsages);
    });
  });

  group('intentFor', () {
    test('a pending spell is ignored', () {
      final spellbook = Spellbook.of(
        _character(activeSpells: [_active(_a)]),
        pending: const {_a: SpellOperation.unequip},
      );

      expect(spellbook.intentFor(_a), SpellToggleIntent.ignoredPending);
    });

    test('an active spell is unequipped', () {
      final spellbook = Spellbook.of(_character(activeSpells: [_active(_a)]));

      expect(spellbook.intentFor(_a), SpellToggleIntent.unequip);
    });

    test('an inactive spell with a free slot is equipped', () {
      final spellbook = Spellbook.of(_character(activeSpells: [_active(_a)]));

      expect(spellbook.intentFor(_b), SpellToggleIntent.equip);
    });

    test('slots full on the optimistic count block the equip', () {
      final spellbook = Spellbook.of(
        _character(maxActiveSpells: 2, activeSpells: [_active(_a)]),
        pending: const {_c: SpellOperation.equip},
      );

      expect(spellbook.intentFor(_b), SpellToggleIntent.blockedSlotsFull);
    });

    test('slots full on the server count block the equip', () {
      final spellbook = Spellbook.of(
        _character(maxActiveSpells: 1, activeSpells: [_active(_a)]),
      );

      expect(spellbook.intentFor(_b), SpellToggleIntent.blockedSlotsFull);
    });

    test('no slots block the equip of an inactive spell', () {
      final spellbook = Spellbook.of(_character(maxActiveSpells: 0));

      expect(spellbook.intentFor(_b), SpellToggleIntent.blockedNoSlots);
    });

    test('no slots still allow the unequip of a legacy active spell', () {
      final spellbook = Spellbook.of(
        _character(maxActiveSpells: 0, activeSpells: [_active(_a)]),
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
        _character(maxActiveSpells: 1, activeSpells: [_active(_a)]),
        pending: const {_a: SpellOperation.unequip},
      );

      expect(spellbook.intentFor(_b), SpellToggleIntent.equip);
    });
  });
}
