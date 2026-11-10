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

    test('job and study have no torn sheet yet', () {
      for (final type in [QuestType.job, QuestType.study]) {
        expect(
          questPaperAssetIds(type, isTorn: true),
          questPaperAssetIds(type, isTorn: false),
        );
      }
      expect(questPaperAssetIds(QuestType.job, isTorn: false), [
        CloudinaryAssets.jobSheet1,
        CloudinaryAssets.jobSheet2,
      ]);
      expect(questPaperAssetIds(QuestType.study, isTorn: false), [
        CloudinaryAssets.announcementSheet1,
        CloudinaryAssets.announcementSheet2,
      ]);
    });

    test('hunt uses the game sheets, whole and torn', () {
      expect(questPaperAssetIds(QuestType.hunt, isTorn: false), [
        CloudinaryAssets.gameSheet1,
        CloudinaryAssets.gameSheet2,
      ]);
      expect(questPaperAssetIds(QuestType.hunt, isTorn: true), [
        CloudinaryAssets.gameTornSheet1,
        CloudinaryAssets.gameTornSheet2,
      ]);
    });

    test('crime has a torn variant', () {
      expect(questPaperAssetIds(QuestType.crime, isTorn: false), [
        CloudinaryAssets.crimeSheet1,
        CloudinaryAssets.crimeSheet2,
      ]);
      expect(questPaperAssetIds(QuestType.crime, isTorn: true), [
        CloudinaryAssets.crimeTornSheet1,
        CloudinaryAssets.crimeTornSheet2,
      ]);
    });

    test('guard uses its own whole and torn sheets', () {
      expect(questPaperAssetIds(QuestType.guard, isTorn: false), [
        CloudinaryAssets.guardSheet1,
        CloudinaryAssets.guardSheet2,
      ]);
      expect(questPaperAssetIds(QuestType.guard, isTorn: true), [
        CloudinaryAssets.guardTornSheet1,
        CloudinaryAssets.guardTornSheet2,
      ]);
    });

    test('a torn heal uses the torn announcement sheets (D-20)', () {
      expect(questPaperAssetIds(QuestType.heal, isTorn: true), [
        CloudinaryAssets.announcementTornSheet1,
        CloudinaryAssets.announcementTornSheet2,
      ]);
      expect(questPaperAssetIds(QuestType.heal, isTorn: false), [
        CloudinaryAssets.announcementSheet1,
        CloudinaryAssets.announcementSheet2,
      ]);
    });

    test('magic uses its own whole and torn sheets (quick 261110-mag)', () {
      expect(questPaperAssetIds(QuestType.magic, isTorn: false), [
        CloudinaryAssets.magicSheet,
      ]);
      expect(questPaperAssetIds(QuestType.magic, isTorn: true), [
        CloudinaryAssets.magicTornSheet,
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

  group('quest sheet asset ids', () {
    test('the sheets re-uploaded on 2026-11-10 point to the new files', () {
      expect(
        CloudinaryAssets.crimeSheet2,
        'v1794314260/crimeSheet2_kenql4.svg',
      );
      expect(
        CloudinaryAssets.questSheetTorn1,
        'v1794313623/tornQuestSheet1_jo92rm.svg',
      );
      expect(
        CloudinaryAssets.questSheetTorn2,
        'v1794313329/tornQuestSheet2_gm4nz0.svg',
      );
      expect(
        CloudinaryAssets.storyTornSheet1,
        'v1794312688/tornStorySheet1_jyoucq.svg',
      );
      expect(
        CloudinaryAssets.storyTornSheet2,
        'v1794314149/tornStorySheet2_otpfcb.svg',
      );
      expect(
        CloudinaryAssets.huntTornSheet1,
        'v1794313032/tornHuntSheet1_tk1xqh.svg',
      );
      expect(
        CloudinaryAssets.huntTornSheet2,
        'v1794312697/tornHuntSheet2_kf1oy7.svg',
      );
      expect(
        CloudinaryAssets.announcementTornSheet1,
        'v1794303769/tornAnnouncementSheet1_ez2vyw.svg',
      );
      expect(
        CloudinaryAssets.announcementTornSheet2,
        'v1794303777/tornAnnouncementSheet2_ayfvwu.svg',
      );
    });

    test('the magic sheets point to their revised files', () {
      expect(CloudinaryAssets.magicSheet, 'v1794321047/magicSheet_inikhm.svg');
      expect(
        CloudinaryAssets.magicTornSheet,
        'v1794321051/tornMagicSheet_f8gu75.svg',
      );
    });

    test('the torn crime sheets point to their files', () {
      expect(
        CloudinaryAssets.crimeTornSheet1,
        'v1794321444/tornCrimeSheet1_digaof.svg',
      );
      expect(
        CloudinaryAssets.crimeTornSheet2,
        'v1794321440/tornCrimeSheet2_z2jugi.svg',
      );
    });

    test('the guard sheets point to their files', () {
      expect(
        CloudinaryAssets.guardSheet1,
        'v1794322926/guardSheet1_yfzvwp.svg',
      );
      expect(
        CloudinaryAssets.guardSheet2,
        'v1794322931/guardSheet2_g7rlqv.svg',
      );
      expect(
        CloudinaryAssets.guardTornSheet1,
        'v1794322936/tornGuardSheet1_tsxzu5.svg',
      );
      expect(
        CloudinaryAssets.guardTornSheet2,
        'v1794322939/tornGuardSheet2_aqqbsj.svg',
      );
    });

    test('the game sheets point to their files', () {
      expect(CloudinaryAssets.gameSheet1, 'v1794324911/gameSheet1_togp4w.svg');
      expect(CloudinaryAssets.gameSheet2, 'v1794324912/gameSheet2_zrmzpe.svg');
      expect(
        CloudinaryAssets.gameTornSheet1,
        'v1794324905/tornGameSheet1_ruztfx.svg',
      );
      expect(
        CloudinaryAssets.gameTornSheet2,
        'v1794324906/tornGameSheet2_j1xtv6.svg',
      );
    });
  });
}
