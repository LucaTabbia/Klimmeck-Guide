import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result_kind.dart';

void main() {
  test('reads quest and ambush from the wire (D-01)', () {
    expect(QuestResultKind.fromWire('quest'), QuestResultKind.quest);
    expect(QuestResultKind.fromWire('ambush'), QuestResultKind.ambush);
  });

  test('reads a missing or unknown kind as a quest (D-01)', () {
    expect(QuestResultKind.fromWire(null), QuestResultKind.quest);
    expect(QuestResultKind.fromWire('raid'), QuestResultKind.quest);
    expect(QuestResultKind.fromWire(3), QuestResultKind.quest);
  });
}
