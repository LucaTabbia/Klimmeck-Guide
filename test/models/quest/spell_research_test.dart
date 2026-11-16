import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/quest/quest_prizes.dart';
import 'package:klimmeck_guide/models/quest/spell_research.dart';

void main() {
  QuestPrizes prizes({required bool spellDraw}) =>
      QuestPrizes.fromJson({'spellDraw': spellDraw});

  test('the three school types are a research without any prizes (D-26)', () {
    for (final type in [
      QuestType.arcane,
      QuestType.shamanic,
      QuestType.theVoid,
    ]) {
      expect(isSpellResearchQuest(type, null), isTrue, reason: type.name);
    }
  });

  test('any other type is a research only with a served spell draw (D-26)', () {
    expect(
      isSpellResearchQuest(QuestType.study, prizes(spellDraw: true)),
      isTrue,
    );
    expect(
      isSpellResearchQuest(QuestType.study, prizes(spellDraw: false)),
      isFalse,
    );
    expect(isSpellResearchQuest(QuestType.study, null), isFalse);
    expect(
      isSpellResearchQuest(QuestType.hunt, prizes(spellDraw: true)),
      isTrue,
    );
    expect(isSpellResearchQuest(null, null), isFalse);
  });
}
