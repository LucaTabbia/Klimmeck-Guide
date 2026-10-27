import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/character/character_status.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/spell/spell_state.dart';
import 'package:klimmeck_guide/models/travel/active_travel.dart';

import '../../helpers/fixtures/spell_fixtures.dart';
import '../../helpers/fixtures/travel_fixtures.dart';

Map<String, dynamic> statusJson({Object? activeTravel, Object? spellStates}) =>
    {
      'title': 'rookie',
      'xp': 1,
      'location': {'id': 'city-marker-1', 'location': departureWire},
      'activeTravel': activeTravel,
      if (spellStates != null) 'spellStates': spellStates,
    };

void main() {
  test('parses activeTravel', () {
    final status = CharacterStatus.fromJson(
      statusJson(activeTravel: activeTravelJson()),
    );
    expect(status.activeTravel, ActiveTravel.fromJson(activeTravelJson()));
  });

  test('a missing activeTravel is null', () {
    final json = statusJson()..remove('activeTravel');
    expect(CharacterStatus.fromJson(json).activeTravel, isNull);
  });

  test('a null activeTravel is null', () {
    expect(CharacterStatus.fromJson(statusJson()).activeTravel, isNull);
  });

  test('a malformed activeTravel is null and the status still parses', () {
    final status = CharacterStatus.fromJson(
      statusJson(activeTravel: {'startTime': 'x'}),
    );
    expect(status.activeTravel, isNull);
    expect(status.location!.id, 'city-marker-1');
    expect(status.title, TitleType.rookie);
  });

  test('toJson emits activeTravel and round trips', () {
    final status = CharacterStatus.fromJson(
      statusJson(activeTravel: activeTravelJson()),
    );
    expect(
      ActiveTravel.fromJson(
        status.toJson()['activeTravel'] as Map<String, dynamic>,
      ),
      status.activeTravel,
    );
    expect(
      CharacterStatus.fromJson(statusJson()).toJson()['activeTravel'],
      isNull,
    );
  });

  test('props include activeTravel', () {
    expect(
      CharacterStatus.fromJson(statusJson(activeTravel: activeTravelJson())) ==
          CharacterStatus.fromJson(statusJson()),
      isFalse,
    );
  });

  test('copyWith keeps the current activeTravel (Pitfall 6)', () {
    final status = CharacterStatus.fromJson(
      statusJson(activeTravel: activeTravelJson()),
    );
    final copy = status.copyWith(xp: 3);
    expect(copy.xp, 3);
    expect(copy.activeTravel, status.activeTravel);
  });

  test('Character.fromJson carries activeTravel.to as a plain id', () {
    final character = Character.fromJson(
      travellingCharacterJson(activeTravel: activeTravelJson()),
    );
    expect(character.status!.activeTravel!.to, 'city-marker-2');
  });

  group('spellStates', () {
    void expectOtherFieldsParsed(CharacterStatus status) {
      expect(status.location!.id, 'city-marker-1');
      expect(status.title, TitleType.rookie);
      expect(status.xp, 1);
    }

    test('a missing spellStates is null (pre-9.1 payload)', () {
      final status = CharacterStatus.fromJson(statusJson());

      expect(status.spellStates, isNull);
      expectOtherFieldsParsed(status);
    });

    test('an empty spellStates is an empty list, not null', () {
      final status = CharacterStatus.fromJson(statusJson(spellStates: []));

      expect(status.spellStates, isEmpty);
      expect(status.spellStates, isNotNull);
    });

    test('malformed entries are skipped and the status survives', () {
      final status = CharacterStatus.fromJson(
        statusJson(
          spellStates: [
            spellStateJson(),
            {'usages': 1},
          ],
        ),
      );

      expect(status.spellStates, [SpellState.fromJson(spellStateJson())]);
      expectOtherFieldsParsed(status);
    });

    test('a non-list spellStates is null and the status survives', () {
      final status = CharacterStatus.fromJson(
        statusJson(spellStates: 'spell-states'),
      );

      expect(status.spellStates, isNull);
      expectOtherFieldsParsed(status);
    });

    test('toJson emits the spell states, or null when absent', () {
      final status = CharacterStatus.fromJson(
        statusJson(spellStates: [spellStateJson()]),
      );

      expect(status.toJson()['spellStates'], [
        SpellState.fromJson(spellStateJson()).toJson(),
      ]);
      expect(
        CharacterStatus.fromJson(statusJson()).toJson()['spellStates'],
        isNull,
      );
    });

    test('props include spellStates', () {
      expect(
        CharacterStatus.fromJson(statusJson(spellStates: [spellStateJson()])) ==
            CharacterStatus.fromJson(statusJson()),
        isFalse,
      );
    });

    test('copyWith keeps the current spellStates', () {
      final status = CharacterStatus.fromJson(
        statusJson(spellStates: [spellStateJson()]),
      );

      final copy = status.copyWith(xp: 5);

      expect(copy.xp, 5);
      expect(copy.spellStates, status.spellStates);
    });
  });

  test('spellbookCharacter has one known spell, none active, no states', () {
    final character = spellbookCharacter();

    expect(character.status!.spells, hasLength(1));
    expect(character.assets!.activeSpells, isEmpty);
    expect(character.status!.spellStates, isNull);
  });
}
