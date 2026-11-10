import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/quest/quest_cure.dart';

import '../../helpers/fixtures/quest_fixtures.dart';

void main() {
  group('QuestCure.tryFromJson', () {
    test('parses the share and the injuries it heals (D-01)', () {
      final cure = QuestCure.tryFromJson(questCureJson())!;
      expect(cure.lifePointsShare, 0.5);
      expect(cure.canHeal, [InjuryType.contusion, InjuryType.deepCut]);
    });

    test('an integer share is read as a double (D-01)', () {
      expect(
        QuestCure.tryFromJson(questCureJson(share: 1))!.lifePointsShare,
        1.0,
      );
      expect(
        QuestCure.tryFromJson(questCureJson(share: 0))!.lifePointsShare,
        0.0,
      );
    });

    test('drops an unknown injury name and keeps the cure (D-01)', () {
      final cure = QuestCure.tryFromJson(
        questCureJson(canHeal: ['contusion', 'dragonBite']),
      );
      expect(cure!.canHeal, [InjuryType.contusion]);
    });

    test('a malformed cure is null (D-01)', () {
      expect(QuestCure.tryFromJson(null), isNull);
      expect(QuestCure.tryFromJson('cure'), isNull);
      expect(QuestCure.tryFromJson([]), isNull);
      expect(QuestCure.tryFromJson(questCureJson(share: '0.5')), isNull);
      expect(
        QuestCure.tryFromJson(questCureJson()..remove('lifePointsShare')),
        isNull,
      );
      expect(QuestCure.tryFromJson(questCureJson(share: -0.1)), isNull);
      expect(QuestCure.tryFromJson(questCureJson(share: 1.5)), isNull);
      expect(QuestCure.tryFromJson(questCureJson(share: double.nan)), isNull);
      expect(
        QuestCure.tryFromJson(questCureJson(share: double.infinity)),
        isNull,
      );
      expect(
        QuestCure.tryFromJson(questCureJson(canHeal: 'contusion')),
        isNull,
      );
      expect(QuestCure.tryFromJson(questCureJson()..remove('canHeal')), isNull);
    });

    test('toJson round trips (D-01)', () {
      final cure = QuestCure.tryFromJson(questCureJson())!;
      expect(QuestCure.tryFromJson(cure.toJson()), cure);
      expect(cure.toJson()['canHeal'], ['contusion', 'deepCut']);
    });

    test('props and copyWith (D-01)', () {
      final cure = QuestCure.tryFromJson(questCureJson())!;
      expect(cure.copyWith(lifePointsShare: 0.8), isNot(cure));
      expect(cure.copyWith(canHeal: [InjuryType.blindness]), isNot(cure));
      expect(cure.copyWith(lifePointsShare: 1).canHeal, cure.canHeal);
    });

    test('the parsed list cannot be modified (D-01)', () {
      final cure = QuestCure.tryFromJson(questCureJson())!;
      expect(
        () => cure.canHeal.add(InjuryType.blindness),
        throwsUnsupportedError,
      );
    });
  });
}
