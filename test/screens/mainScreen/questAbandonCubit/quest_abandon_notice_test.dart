import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/quest_abandon_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAbandonCubit/quest_abandon_notice.dart';

void main() {
  group('questAbandonNoticeFor', () {
    const retry = 'Impossibile abbandonare ora, riprova';
    final descriptions = {
      QuestAbandonFailure.notWaiting:
          'La missione è già cominciata: non puoi più abbandonarla',
      QuestAbandonFailure.notFound: 'Non sei più in questa missione',
      QuestAbandonFailure.connection: retry,
      QuestAbandonFailure.timedOut: retry,
      QuestAbandonFailure.unknown: retry,
    };
    descriptions.forEach((failure, description) {
      test('${failure.name} has the fixed copy', () {
        final notice = questAbandonNoticeFor(failure)!;

        expect(notice.title, 'Abbandono non riuscito');
        expect(notice.description, description);
      });
    });

    test('forbidden and unauthenticated publish nothing', () {
      expect(questAbandonNoticeFor(QuestAbandonFailure.forbidden), isNull);
      expect(
        questAbandonNoticeFor(QuestAbandonFailure.unauthenticated),
        isNull,
      );
    });
  });
}
