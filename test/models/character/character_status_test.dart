import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/awaiting_aid.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/character/character_status.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/spell/spell_state.dart';
import 'package:klimmeck_guide/models/travel/active_travel.dart';

import '../../helpers/fixtures/spell_fixtures.dart';
import '../../helpers/fixtures/travel_fixtures.dart';

Map<String, dynamic> statusJson({
  Object? activeTravel,
  Object? spellStates,
  Object? awaitingAid = _absent,
  Object? unlockedLore = _absent,
  Object? injuries = _absent,
  Object? potionRecoveryUntil = _absent,
  Object? imprisonedUntil = _absent,
}) => {
  'title': 'rookie',
  'xp': 1,
  'location': {'id': 'city-marker-1', 'location': departureWire},
  'activeTravel': activeTravel,
  if (spellStates != null) 'spellStates': spellStates,
  if (!identical(awaitingAid, _absent)) 'awaitingAid': awaitingAid,
  if (!identical(unlockedLore, _absent)) 'unlockedLore': unlockedLore,
  if (!identical(injuries, _absent)) 'injuries': injuries,
  if (!identical(potionRecoveryUntil, _absent))
    'potionRecoveryUntil': potionRecoveryUntil,
  if (!identical(imprisonedUntil, _absent)) 'imprisonedUntil': imprisonedUntil,
};

const Object _absent = Object();

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

    test('spellStates is an empty list when the field is absent (D-05)', () {
      final status = CharacterStatus.fromJson(statusJson());

      expect(status.spellStates, isEmpty);
      expectOtherFieldsParsed(status);
    });

    test(
      'spellStates is an empty list when the field is not a list (D-05)',
      () {
        for (final Object malformed in [
          'spell-states',
          7,
          <String, Object?>{},
        ]) {
          final status = CharacterStatus.fromJson(
            statusJson(spellStates: malformed),
          );

          expect(
            status.spellStates,
            isEmpty,
            reason: 'spellStates: $malformed',
          );
          expectOtherFieldsParsed(status);
        }
      },
    );

    test('an empty spellStates is an empty list', () {
      final status = CharacterStatus.fromJson(statusJson(spellStates: []));

      expect(status.spellStates, isEmpty);
    });

    test('a malformed state entry is dropped and the others stay (D-05)', () {
      final status = CharacterStatus.fromJson(
        statusJson(
          spellStates: [
            spellStateJson(),
            {'usages': 1},
            'not-a-state',
            spellStateJson(spellId: 'spell-2', active: true),
          ],
        ),
      );

      expect(status.spellStates, [
        SpellState.fromJson(spellStateJson()),
        SpellState.fromJson(spellStateJson(spellId: 'spell-2', active: true)),
      ]);
      expectOtherFieldsParsed(status);
    });

    test('parses active states with their full spell (D-05)', () {
      final status = CharacterStatus.fromJson(
        statusJson(
          spellStates: [
            spellStateJson(
              spellId: 's-1',
              spell: spellJson(id: 's-1', name: 'Scudo'),
              active: true,
            ),
            spellStateJson(
              spellId: 's-2',
              spell: spellJson(id: 's-2', name: 'Dardo'),
            ),
          ],
        ),
      );

      expect(status.spellStates.map((state) => state.spellId), ['s-1', 's-2']);
      expect(status.spellStates.map((state) => state.active), [true, false]);
      expect(status.spellStates.map((state) => state.spell.name), [
        'Scudo',
        'Dardo',
      ]);
    });

    test('toJson writes the spell states (D-05)', () {
      final status = CharacterStatus.fromJson(
        statusJson(spellStates: [spellStateJson(active: true)]),
      );

      expect(status.toJson()['spellStates'], [
        SpellState.fromJson(spellStateJson(active: true)).toJson(),
      ]);
      expect(
        CharacterStatus.fromJson(statusJson()).toJson()['spellStates'],
        isEmpty,
      );
    });

    test('props include spellStates', () {
      expect(
        CharacterStatus.fromJson(statusJson(spellStates: [spellStateJson()])) ==
            CharacterStatus.fromJson(statusJson()),
        isFalse,
      );
      expect(
        CharacterStatus.fromJson(statusJson(spellStates: [spellStateJson()])) ==
            CharacterStatus.fromJson(
              statusJson(spellStates: [spellStateJson(active: true)]),
            ),
        isFalse,
      );
    });

    test('copyWith keeps the spell states (D-05)', () {
      final status = CharacterStatus.fromJson(
        statusJson(spellStates: [spellStateJson(active: true)]),
      );

      final copy = status.copyWith(xp: 5);

      expect(copy.xp, 5);
      expect(copy.spellStates, status.spellStates);
      expect(copy.spellStates.single.active, isTrue);
    });
  });

  group('unlockedLore (BE Phase 16)', () {
    test('a missing unlockedLore is an empty list (D-01)', () {
      final status = CharacterStatus.fromJson(statusJson());

      expect(status.unlockedLore, isNotNull);
      expect(status.unlockedLore, isEmpty);
    });

    test('parses the unlocked lore ids (D-01)', () {
      final status = CharacterStatus.fromJson(
        statusJson(unlockedLore: ['lore-andogan', 'lore-region-1']),
      );

      expect(status.unlockedLore, ['lore-andogan', 'lore-region-1']);
    });

    test('drops non-string ids and keeps the status (D-01)', () {
      final status = CharacterStatus.fromJson(
        statusJson(
          unlockedLore: [
            'lore-andogan',
            42,
            null,
            {'id': 'x'},
          ],
        ),
      );

      expect(status.unlockedLore, ['lore-andogan']);
      expect(status.location!.id, 'city-marker-1');
    });

    test('a non-list unlockedLore is an empty list (D-01)', () {
      final status = CharacterStatus.fromJson(
        statusJson(unlockedLore: 'lore-andogan'),
      );

      expect(status.unlockedLore, isEmpty);
    });

    test('toJson writes the unlocked lore ids (D-01)', () {
      final status = CharacterStatus.fromJson(
        statusJson(unlockedLore: ['lore-andogan']),
      );

      expect(status.toJson()['unlockedLore'], ['lore-andogan']);
    });

    test('props include unlockedLore (D-01)', () {
      expect(
        CharacterStatus.fromJson(statusJson(unlockedLore: ['lore-andogan'])) ==
            CharacterStatus.fromJson(statusJson(unlockedLore: [])),
        isFalse,
      );
    });

    test('copyWith keeps the current unlockedLore (D-19)', () {
      final status = CharacterStatus.fromJson(
        statusJson(unlockedLore: ['lore-andogan']),
      );

      expect(status.copyWith(xp: 9).unlockedLore, ['lore-andogan']);
    });

    test('the parsed list cannot be modified (D-01)', () {
      final status = CharacterStatus.fromJson(
        statusJson(unlockedLore: ['lore-andogan']),
      );

      expect(() => status.unlockedLore.add('x'), throwsUnsupportedError);
    });
  });

  group('imprisonedUntil (quick 261110-cgd)', () {
    const releaseWire = '2026-11-10T22:00:00.000Z';
    final release = DateTime.utc(2026, 11, 10, 22);

    test('a missing, null or malformed imprisonedUntil is null '
        '(quick 261110-cgd)', () {
      for (final json in [
        statusJson(),
        statusJson(imprisonedUntil: null),
        statusJson(imprisonedUntil: 'soon'),
        statusJson(imprisonedUntil: 42),
      ]) {
        final status = CharacterStatus.fromJson(json);

        expect(status.imprisonedUntil, isNull);
        expect(status.location!.id, 'city-marker-1');
      }
    });

    test('parses the release as a UTC instant (quick 261110-cgd)', () {
      final status = CharacterStatus.fromJson(
        statusJson(imprisonedUntil: releaseWire),
      );

      expect(status.imprisonedUntil, release);
      expect(status.imprisonedUntil!.isUtc, isTrue);
    });

    test('toJson, props and copyWith carry imprisonedUntil '
        '(quick 261110-cgd)', () {
      final status = CharacterStatus.fromJson(
        statusJson(imprisonedUntil: releaseWire),
      );

      expect(status.toJson()['imprisonedUntil'], releaseWire);
      expect(status == CharacterStatus.fromJson(statusJson()), isFalse);
      expect(status.copyWith(xp: 9).imprisonedUntil, release);
    });
  });

  group('potionRecoveryUntil (BE Phase 18)', () {
    const recoveryEndWire = '2026-10-27T10:30:00.000Z';
    final recoveryEnd = DateTime.utc(2026, 10, 27, 10, 30);

    test('a missing or null potionRecoveryUntil is null (D-12)', () {
      expect(
        CharacterStatus.fromJson(statusJson()).potionRecoveryUntil,
        isNull,
      );
      expect(
        CharacterStatus.fromJson(
          statusJson(potionRecoveryUntil: null),
        ).potionRecoveryUntil,
        isNull,
      );
    });

    test('parses the recovery end as a UTC instant (D-12)', () {
      final utc = CharacterStatus.fromJson(
        statusJson(potionRecoveryUntil: recoveryEndWire),
      ).potionRecoveryUntil!;
      final offset = CharacterStatus.fromJson(
        statusJson(potionRecoveryUntil: '2026-10-27T11:30:00.000+01:00'),
      ).potionRecoveryUntil!;

      expect(utc, recoveryEnd);
      expect(utc.isUtc, isTrue);
      expect(offset, recoveryEnd);
      expect(offset.isUtc, isTrue);
    });

    test(
      'a malformed potionRecoveryUntil is null and the status stays (D-12)',
      () {
        for (final malformed in <Object>['soon', 42, <String, dynamic>{}]) {
          final status = CharacterStatus.fromJson(
            statusJson(potionRecoveryUntil: malformed),
          );

          expect(status.potionRecoveryUntil, isNull);
          expect(status.location!.id, 'city-marker-1');
          expect(status.title, TitleType.rookie);
          expect(status.xp, 1);
        }
      },
    );

    test('toJson writes the recovery end (D-12)', () {
      expect(
        CharacterStatus.fromJson(
          statusJson(potionRecoveryUntil: recoveryEndWire),
        ).toJson()['potionRecoveryUntil'],
        recoveryEndWire,
      );
      expect(
        CharacterStatus.fromJson(statusJson()).toJson(),
        containsPair('potionRecoveryUntil', isNull),
      );
    });

    test('props include potionRecoveryUntil (D-12)', () {
      expect(
        CharacterStatus.fromJson(
              statusJson(potionRecoveryUntil: recoveryEndWire),
            ) ==
            CharacterStatus.fromJson(statusJson()),
        isFalse,
      );
    });

    test('copyWith keeps the current potionRecoveryUntil (D-12)', () {
      final status = CharacterStatus.fromJson(
        statusJson(potionRecoveryUntil: recoveryEndWire),
      );

      expect(status.copyWith(xp: 9).potionRecoveryUntil, recoveryEnd);
    });
  });

  group('awaitingAid', () {
    void expectOtherFieldsParsed(CharacterStatus status) {
      expect(status.location!.id, 'city-marker-1');
      expect(status.title, TitleType.rookie);
      expect(status.xp, 1);
    }

    test('a missing awaitingAid is null (legacy payload)', () {
      final status = CharacterStatus.fromJson(statusJson());

      expect(status.awaitingAid, isNull);
      expectOtherFieldsParsed(status);
    });

    test('a null awaitingAid is null', () {
      final status = CharacterStatus.fromJson(statusJson(awaitingAid: null));

      expect(status.awaitingAid, isNull);
    });

    test('a valid awaitingAid is parsed', () {
      final status = CharacterStatus.fromJson(
        statusJson(awaitingAid: awaitingAidJson()),
      );

      expect(status.awaitingAid, AwaitingAid.fromJson(awaitingAidJson()));
      expectOtherFieldsParsed(status);
    });

    test('a malformed awaitingAid is null and the status survives', () {
      final status = CharacterStatus.fromJson(
        statusJson(awaitingAid: 'broken'),
      );

      expect(status.awaitingAid, isNull);
      expectOtherFieldsParsed(status);
    });

    test('toJson mirrors awaitingAid', () {
      final status = CharacterStatus.fromJson(
        statusJson(awaitingAid: awaitingAidJson()),
      );

      expect(status.toJson()['awaitingAid'], awaitingAidJson());
      expect(
        CharacterStatus.fromJson(statusJson()).toJson()['awaitingAid'],
        isNull,
      );
    });

    test('props include awaitingAid', () {
      expect(
        CharacterStatus.fromJson(statusJson(awaitingAid: awaitingAidJson())) ==
            CharacterStatus.fromJson(statusJson()),
        isFalse,
      );
    });

    test('copyWith keeps the current awaitingAid', () {
      final status = CharacterStatus.fromJson(
        statusJson(awaitingAid: awaitingAidJson()),
      );

      final copy = status.copyWith(xp: 5);

      expect(copy.xp, 5);
      expect(copy.awaitingAid, status.awaitingAid);
    });

    test('travellingCharacterJson sets the wounded state only on request', () {
      final wounded = Character.fromJson(
        travellingCharacterJson(awaitingAid: awaitingAidJson()),
      );
      final free = travellingCharacterJson();

      expect(wounded.status!.awaitingAid!.aidQuestId, 'aid-1');
      expect(
        (free['status'] as Map<String, dynamic>).containsKey('awaitingAid'),
        isFalse,
      );
    });
  });

  group('injuries (quick 261109-inj2)', () {
    void expectOtherFieldsParsed(CharacterStatus status) {
      expect(status.location!.id, 'city-marker-1');
      expect(status.title, TitleType.rookie);
      expect(status.xp, 1);
    }

    test('drops an injury name the client does not know', () {
      final status = CharacterStatus.fromJson(
        statusJson(injuries: ['deepCut', 'brokenWing', 'stunned']),
      );

      expect(status.injuries, [InjuryType.deepCut, InjuryType.stunned]);
      expectOtherFieldsParsed(status);
    });

    test('a missing injuries is an empty list, not null', () {
      final status = CharacterStatus.fromJson(statusJson());

      expect(status.injuries, isNotNull);
      expect(status.injuries, isEmpty);
    });

    test('a null injuries is an empty list', () {
      final status = CharacterStatus.fromJson(statusJson(injuries: null));

      expect(status.injuries, isEmpty);
    });

    test('a non-list injuries is an empty list and the status survives', () {
      final status = CharacterStatus.fromJson(statusJson(injuries: 'deepCut'));

      expect(status.injuries, isEmpty);
      expectOtherFieldsParsed(status);
    });

    test('the parsed list cannot be modified', () {
      final status = CharacterStatus.fromJson(
        statusJson(injuries: ['deepCut']),
      );

      expect(
        () => status.injuries!.add(InjuryType.blackEye),
        throwsUnsupportedError,
      );
    });

    test('toJson writes the injury names', () {
      final status = CharacterStatus.fromJson(
        statusJson(injuries: ['deepCut', 'stunned']),
      );

      expect(status.toJson()['injuries'], ['deepCut', 'stunned']);
    });

    test('copyWith keeps the injuries unless they are replaced', () {
      final status = CharacterStatus.fromJson(
        statusJson(injuries: ['deepCut']),
      );

      expect(status.copyWith(xp: 4).injuries, [InjuryType.deepCut]);
      expect(status.copyWith(injuries: [InjuryType.blackEye]).injuries, [
        InjuryType.blackEye,
      ]);
    });
  });

  group('lenient title (Phase 19)', () {
    test('an unknown title is null and the status survives (D-16)', () {
      final status = CharacterStatus.fromJson({
        'title': 'archmageOfNowhere',
        'level': 3,
      });

      expect(status.title, isNull);
      expect(status.level, 3);
    });

    test('a title that is not a string is null (D-16)', () {
      expect(CharacterStatus.fromJson({'title': 7}).title, isNull);
    });

    test('a known title still parses (D-16)', () {
      expect(
        CharacterStatus.fromJson({'title': 'paladin'}).title,
        TitleType.paladin,
      );
    });
  });

  test('spellbookCharacter has one known spell, none active, no states', () {
    final character = spellbookCharacter();

    expect(character.status!.spells, hasLength(1));
    expect(character.assets!.activeSpells, isEmpty);
    expect(character.status!.spellStates, isEmpty);
  });
}
