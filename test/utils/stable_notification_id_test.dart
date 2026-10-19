import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/utils/stable_notification_id.dart';

void main() {
  test('matches the FNV-1a 31-bit reference vectors', () {
    expect(stableNotificationId(''), 18652613);
    expect(stableNotificationId('a'), 1678518572);
    expect(
      stableNotificationId('travelEnd|6712a0c4e1b2c3d4e5f60718'),
      2137633466,
    );
    expect(
      stableNotificationId('streamerLive|2026-10-18T12:00:00.000Z'),
      1382011903,
    );
  });

  test('always returns a non-negative 31-bit value', () {
    for (final key in ['', 'a', 'travelEnd|x', 'é漢字🙂', 'x' * 500]) {
      expect(stableNotificationId(key), inInclusiveRange(0, 0x7fffffff));
    }
  });

  test('returns the same value for the same key', () {
    expect(
      stableNotificationId('questEnd|q-1'),
      stableNotificationId('questEnd|q-1'),
    );
  });

  test('distinguishes the same id under different types', () {
    expect(
      stableNotificationId('travelEnd|x'),
      isNot(stableNotificationId('questEnd|x')),
    );
  });
}
