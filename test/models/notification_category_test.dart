import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';

void main() {
  test('exposes the five categories in display order (D-02)', () {
    expect(NotificationCategory.values, [
      NotificationCategory.travelEnd,
      NotificationCategory.streamerLive,
      NotificationCategory.questEnd,
      NotificationCategory.questCancelled,
      NotificationCategory.ambushDefeat,
      NotificationCategory.prisonRelease,
    ]);
  });

  test(
    'pins the storage keys so renaming a value cannot orphan saved data',
    () {
      expect(NotificationCategory.travelEnd.storageKey, 'travel_end');
      expect(NotificationCategory.streamerLive.storageKey, 'streamer_live');
      expect(NotificationCategory.questEnd.storageKey, 'quest_end');
      expect(NotificationCategory.questCancelled.storageKey, 'quest_cancelled');
      expect(NotificationCategory.ambushDefeat.storageKey, 'ambush_defeat');
      expect(NotificationCategory.prisonRelease.storageKey, 'prison_release');
    },
  );

  group('wireType', () {
    test('pins the backend push types so renaming a value cannot break '
        'the wire mapping', () {
      expect(NotificationCategory.travelEnd.wireType, 'travelEnd');
      expect(NotificationCategory.streamerLive.wireType, 'streamerLive');
      expect(NotificationCategory.questEnd.wireType, 'questEnd');
      expect(NotificationCategory.questCancelled.wireType, 'questCancelled');
      expect(NotificationCategory.ambushDefeat.wireType, 'ambushDefeat');
      expect(NotificationCategory.prisonRelease.wireType, 'prisonRelease');
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
        NotificationCategory.fromWireType('ambushDefeat'),
        NotificationCategory.ambushDefeat,
      );
      expect(
        NotificationCategory.fromWireType('prisonRelease'),
        NotificationCategory.prisonRelease,
      );
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

    test('an ambush defeat is a personal event (D-02)', () {
      expect(NotificationCategory.ambushDefeat.isPersonal, isTrue);
    });

    test('is false for the streamer live broadcast', () {
      expect(NotificationCategory.streamerLive.isPersonal, isFalse);
    });
  });
}
