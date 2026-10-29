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

    test('every other failure stays silent', () {
      final silent = QuestResultFailure.values.where(
        (failure) =>
            failure != QuestResultFailure.notFound &&
            failure != QuestResultFailure.forbidden,
      );

      for (final failure in silent) {
        expect(questResultNoticeFor(failure), isNull, reason: failure.name);
      }
    });
  });
}
