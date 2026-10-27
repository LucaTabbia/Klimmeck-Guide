import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/quest_result/quest_end_event.dart';

import '../../helpers/fixtures/quest_result_fixtures.dart';

void main() {
  test('the questEnd copy is the generic BE copy', () {
    expect(questEndTitle, 'Missione conclusa');
    expect(questEndBody, "La tua missione è terminata: scopri com'è andata.");
  });

  test('questEndEventOf builds the banner event of a result', () {
    final result = questResult(successResultJson(id: 'result-7'));

    final event = questEndEventOf(result);

    expect(event.category, NotificationCategory.questEnd);
    expect(event.id, 'result-7');
    expect(event.title, questEndTitle);
    expect(event.body, questEndBody);
    expect(event.sentAt, result.resolvedAt);
    expect(event.dedupKey, 'questEnd|result-7');
  });
}
