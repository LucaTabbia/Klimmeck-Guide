import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/utils/poke_streak.dart';

void main() {
  final start = DateTime(2026, 11, 27, 12);

  DateTime at(int milliseconds) =>
      start.add(Duration(milliseconds: milliseconds));

  test('the tenth poke in a row annoys the shopkeeper', () {
    final streak = PokeStreak();
    final annoyed = [for (var i = 0; i < 10; i++) streak.poke(at(i * 300))];

    expect(annoyed.where((isAnnoyed) => isAnnoyed), hasLength(1));
    expect(annoyed.last, isTrue);
  });

  test('a pause longer than the gap starts the count again', () {
    final streak = PokeStreak();
    for (var i = 0; i < 9; i++) {
      streak.poke(at(i * 300));
    }

    expect(streak.poke(at(8 * 300 + 1500)), isFalse);
  });

  test('after an outburst the count starts from zero', () {
    final streak = PokeStreak();
    for (var i = 0; i < 10; i++) {
      streak.poke(at(i * 300));
    }

    expect(streak.poke(at(10 * 300)), isFalse);
  });
}
