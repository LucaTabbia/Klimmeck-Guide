import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/request/abandon_quest_request.dart';

void main() {
  group('AbandonQuestRequest', () {
    test('serialises the character id as id and the quest id', () {
      const request = AbandonQuestRequest(id: 'c-1', questId: 'q-1');

      expect(request.toJson(), {'id': 'c-1', 'questId': 'q-1'});
    });

    test('is equal by id and questId', () {
      expect(
        const AbandonQuestRequest(id: 'c-1', questId: 'q-1'),
        const AbandonQuestRequest(id: 'c-1', questId: 'q-1'),
      );
      expect(
        const AbandonQuestRequest(id: 'c-1', questId: 'q-1'),
        isNot(const AbandonQuestRequest(id: 'c-1', questId: 'q-2')),
      );
    });
  });
}
