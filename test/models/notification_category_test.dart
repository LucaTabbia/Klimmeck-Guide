import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';

void main() {
  test('exposes the three categories in display order', () {
    expect(NotificationCategory.values, [
      NotificationCategory.travelEnd,
      NotificationCategory.streamerLive,
      NotificationCategory.questEnd,
    ]);
  });

  test(
    'pins the storage keys so renaming a value cannot orphan saved data',
    () {
      expect(NotificationCategory.travelEnd.storageKey, 'travel_end');
      expect(NotificationCategory.streamerLive.storageKey, 'streamer_live');
      expect(NotificationCategory.questEnd.storageKey, 'quest_end');
    },
  );
}
