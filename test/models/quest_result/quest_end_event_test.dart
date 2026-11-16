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

  group('research outcome (Phase 23 D-29, D-31)', () {
    Map<String, dynamic> spell({Object? name = 'Dardo', Object? time}) => {
      'id': 's-1',
      'name': name,
      'requiredLearnTime': time,
    };

    test('the banner of a research with a spell found names the spell and '
        'the learning time (D-29, D-31)', () {
      final result = questResult(
        questResultJson(id: 'result-8', spellFound: spell(time: 1800000)),
      );

      final event = questEndEventOf(result);

      expect(event.title, 'Ricerca riuscita');
      expect(event.body, "Hai scoperto «Dardo»: l'apprendimento dura 30 min.");
      expect(event.category, NotificationCategory.questEnd);
      expect(event.dedupKey, 'questEnd|result-8');
    });

    test('the banner of a spell found without a valid learning time or a '
        'name (D-31)', () {
      for (final time in [null, 0]) {
        final event = questEndEventOf(
          questResult(questResultJson(spellFound: spell(time: time))),
        );
        expect(event.body, 'Hai scoperto «Dardo».', reason: '$time');
      }
      final unnamed = questEndEventOf(
        questResult(
          questResultJson(spellFound: spell(name: ' ', time: 1800000)),
        ),
      );
      expect(
        unnamed.body,
        "Hai scoperto una magia: l'apprendimento dura 30 min.",
      );
    });

    test('the banner of a failed research says so (D-29)', () {
      final event = questEndEventOf(
        questResult(questResultJson(spellResearchFailed: true)),
      );

      expect(event.title, 'Ricerca conclusa');
      expect(
        event.body,
        "Nessuna magia scoperta: scopri com'è andata la missione.",
      );
      expect(event.category, NotificationCategory.questEnd);
    });
  });
}
