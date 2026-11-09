import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/quest_result_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/questResultsCubit/quest_result_notice.dart';

void main() {
  group('questResultNoticeFor (D-11)', () {
    test('a missing result explains it no longer exists', () {
      expect(
        questResultNoticeFor(QuestResultFailure.notFound),
        const KGNotification(
          title: 'Risultato non disponibile',
          description: 'Questo risultato non esiste più',
        ),
      );
    });

    test('a foreign result explains it is not yours', () {
      expect(
        questResultNoticeFor(QuestResultFailure.forbidden),
        const KGNotification(
          title: 'Risultato non disponibile',
          description: 'Questo risultato non ti appartiene',
        ),
      );
    });

    test('BAD_USER_INPUT shows the generic banner (D-13)', () {
      final notice = questResultNoticeFor(QuestResultFailure.badUserInput)!;

      expect(notice.title, questResultNoticeTitle);
      expect(notice.description, 'Qualcosa è andato storto, riprova');
    });

    test('connection stays silent (D-13)', () {
      expect(questResultNoticeFor(QuestResultFailure.connection), isNull);
    });

    test('every other failure stays silent', () {
      final silent = QuestResultFailure.values.where(
        (failure) =>
            failure != QuestResultFailure.notFound &&
            failure != QuestResultFailure.forbidden &&
            failure != QuestResultFailure.badUserInput,
      );

      for (final failure in silent) {
        expect(questResultNoticeFor(failure), isNull, reason: failure.name);
      }
    });
  });
}
