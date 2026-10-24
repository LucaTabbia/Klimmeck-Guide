import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/quest/quest_paper_asset.dart';

import '../../helpers/fixtures/quest_fixtures.dart';

void main() {
  group('questPaperAssetIds', () {
    test('boss and enemy use the hunt family', () {
      for (final type in [QuestType.boss, QuestType.enemy]) {
        expect(questPaperAssetIds(type, isTorn: false), [
          CloudinaryAssets.huntSheet1,
          CloudinaryAssets.huntSheet2,
        ]);
        expect(questPaperAssetIds(type, isTorn: true), [
          CloudinaryAssets.huntTornSheet1,
          CloudinaryAssets.huntTornSheet2,
        ]);
      }
    });

    test('dungeon and aid use the quest family', () {
      for (final type in [QuestType.dungeon, QuestType.aid]) {
        expect(questPaperAssetIds(type, isTorn: false), [
          CloudinaryAssets.questSheet2,
          CloudinaryAssets.questSheet1,
        ]);
        expect(questPaperAssetIds(type, isTorn: true), [
          CloudinaryAssets.questSheetTorn1,
          CloudinaryAssets.questSheetTorn2,
        ]);
      }
    });

    test('story and worldMission have a torn variant', () {
      for (final type in [QuestType.story, QuestType.worldMission]) {
        expect(questPaperAssetIds(type, isTorn: false), [
          CloudinaryAssets.storySheet1,
          CloudinaryAssets.storySheet2,
        ]);
        expect(questPaperAssetIds(type, isTorn: true), [
          CloudinaryAssets.storyTornSheet2,
          CloudinaryAssets.storyTornSheet1,
        ]);
      }
    });

    test('job, announcement and crime families are never torn', () {
      for (final type in [
        QuestType.hunt,
        QuestType.job,
        QuestType.guard,
        QuestType.heal,
        QuestType.study,
        QuestType.crime,
      ]) {
        expect(
          questPaperAssetIds(type, isTorn: true),
          questPaperAssetIds(type, isTorn: false),
        );
      }
      expect(questPaperAssetIds(QuestType.job, isTorn: false), [
        CloudinaryAssets.jobSheet1,
        CloudinaryAssets.jobSheet2,
      ]);
      expect(questPaperAssetIds(QuestType.heal, isTorn: false), [
        CloudinaryAssets.announcementSheet1,
        CloudinaryAssets.announcementSheet2,
      ]);
      expect(questPaperAssetIds(QuestType.crime, isTorn: false), [
        CloudinaryAssets.crimeSheet1,
        CloudinaryAssets.crimeSheet2,
      ]);
    });

    test('a null type falls back to the quest family', () {
      expect(questPaperAssetIds(null, isTorn: false), [
        CloudinaryAssets.questSheet2,
        CloudinaryAssets.questSheet1,
      ]);
    });
  });

  group('questPaperAssetId', () {
    test('is stable for the same quest and drawn from the family', () {
      final quest = buildQuest(id: 'quest-abc', type: 'boss');
      final first = questPaperAssetId(quest, isTorn: true);

      for (var i = 0; i < 5; i++) {
        expect(questPaperAssetId(quest, isTorn: true), first);
      }
      expect(questPaperAssetIds(QuestType.boss, isTorn: true), contains(first));
    });
  });
}
