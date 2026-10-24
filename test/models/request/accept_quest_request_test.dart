import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/request/accept_quest_request.dart';

void main() {
  group('AcceptQuestRequest', () {
    test('serialises the character id as id and the quest id', () {
      const request = AcceptQuestRequest(id: 'c-1', questId: 'q-1');

      expect(request.toJson(), {'id': 'c-1', 'questId': 'q-1'});
    });

    test('is equal by id and questId', () {
      expect(
        const AcceptQuestRequest(id: 'c-1', questId: 'q-1'),
        const AcceptQuestRequest(id: 'c-1', questId: 'q-1'),
      );
      expect(
        const AcceptQuestRequest(id: 'c-1', questId: 'q-1'),
        isNot(const AcceptQuestRequest(id: 'c-1', questId: 'q-2')),
      );
    });
  });
}
