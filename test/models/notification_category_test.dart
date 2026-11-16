import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';

void main() {
  test('exposes the categories in display order (D-02, D-11)', () {
    expect(NotificationCategory.values, [
      NotificationCategory.travelEnd,
      NotificationCategory.streamerLive,
      NotificationCategory.questEnd,
      NotificationCategory.questCancelled,
      NotificationCategory.ambush,
      NotificationCategory.prisonRelease,
      NotificationCategory.missionStart,
      NotificationCategory.petRecovered,
    ]);
  });

  test(
    'pins the storage keys so renaming a value cannot orphan saved data',
    () {
      expect(NotificationCategory.travelEnd.storageKey, 'travel_end');
      expect(NotificationCategory.streamerLive.storageKey, 'streamer_live');
      expect(NotificationCategory.questEnd.storageKey, 'quest_end');
      expect(NotificationCategory.questCancelled.storageKey, 'quest_cancelled');
      expect(NotificationCategory.ambush.storageKey, 'ambush_defeat');
      expect(NotificationCategory.prisonRelease.storageKey, 'prison_release');
      expect(NotificationCategory.missionStart.storageKey, 'mission_start');
      expect(NotificationCategory.petRecovered.storageKey, 'pet_recovered');
    },
  );

  test('ambush keeps the storage key of the old toggle (D-30)', () {
    expect(NotificationCategory.ambush.storageKey, 'ambush_defeat');
  });

  group('wireType', () {
    test('pins the backend push types so renaming a value cannot break '
        'the wire mapping', () {
      expect(NotificationCategory.travelEnd.wireType, 'travelEnd');
      expect(NotificationCategory.streamerLive.wireType, 'streamerLive');
      expect(NotificationCategory.questEnd.wireType, 'questEnd');
      expect(NotificationCategory.questCancelled.wireType, 'questCancelled');
      expect(NotificationCategory.ambush.wireType, 'ambush');
      expect(NotificationCategory.prisonRelease.wireType, 'prisonRelease');
      expect(NotificationCategory.missionStart.wireType, 'missionStart');
      expect(NotificationCategory.petRecovered.wireType, 'petRecovered');
    });
  });

  group('fromWireType', () {
    test('maps every known backend type onto its category', () {
      expect(
        NotificationCategory.fromWireType('travelEnd'),
        NotificationCategory.travelEnd,
      );
      expect(
        NotificationCategory.fromWireType('streamerLive'),
        NotificationCategory.streamerLive,
      );
      expect(
        NotificationCategory.fromWireType('questEnd'),
        NotificationCategory.questEnd,
      );
      expect(
        NotificationCategory.fromWireType('questCancelled'),
        NotificationCategory.questCancelled,
      );
      expect(
        NotificationCategory.fromWireType('ambush'),
        NotificationCategory.ambush,
      );
      expect(
        NotificationCategory.fromWireType('prisonRelease'),
        NotificationCategory.prisonRelease,
      );
      expect(
        NotificationCategory.fromWireType('missionStart'),
        NotificationCategory.missionStart,
      );
      expect(
        NotificationCategory.fromWireType('petRecovered'),
        NotificationCategory.petRecovered,
      );
    });

    test('both ambush and ambushDefeat map to the ambush category '
        '(D-14, D-30)', () {
      expect(
        NotificationCategory.fromWireType('ambush'),
        NotificationCategory.ambush,
      );
      expect(
        NotificationCategory.fromWireType('ambushDefeat'),
        NotificationCategory.ambush,
      );
    });

    test('the research pushes are quest ends (D-29, D-31)', () {
      expect(
        NotificationCategory.fromWireType('spellResearchSucceeded'),
        NotificationCategory.questEnd,
      );
      expect(
        NotificationCategory.fromWireType('spellResearchFailed'),
        NotificationCategory.questEnd,
      );
      expect(
        NotificationCategory.fromWireType('ambushDefeat'),
        NotificationCategory.ambush,
      );
      expect(NotificationCategory.fromWireType('spellResearch'), isNull);
    });

    test('returns null for an unknown backend type', () {
      expect(NotificationCategory.fromWireType('combatResult'), isNull);
    });

    test('does not accept the storage key as a wire type', () {
      expect(NotificationCategory.fromWireType('travel_end'), isNull);
    });

    test('returns null for a missing or non-string value', () {
      expect(NotificationCategory.fromWireType(null), isNull);
      expect(NotificationCategory.fromWireType(42), isNull);
    });
  });

  group('isPersonal', () {
    test('is true for the events of a single player', () {
      expect(NotificationCategory.travelEnd.isPersonal, isTrue);
      expect(NotificationCategory.questEnd.isPersonal, isTrue);
      expect(NotificationCategory.questCancelled.isPersonal, isTrue);
    });

    test('an ambush is a personal event (D-02, D-14)', () {
      expect(NotificationCategory.ambush.isPersonal, isTrue);
    });

    test('petRecovered is a personal category with its own storage key '
        '(D-11)', () {
      expect(NotificationCategory.petRecovered.isPersonal, isTrue);
      expect(NotificationCategory.petRecovered.storageKey, 'pet_recovered');
      final storageKeys = NotificationCategory.values.map((c) => c.storageKey);
      expect(
        storageKeys.toSet(),
        hasLength(NotificationCategory.values.length),
      );
    });

    test('is false for the streamer live broadcast', () {
      expect(NotificationCategory.streamerLive.isPersonal, isFalse);
    });
  });
}
