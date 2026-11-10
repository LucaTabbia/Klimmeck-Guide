import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/quest/quest_paper_asset.dart';

import '../../helpers/fixtures/quest_fixtures.dart';

void main() {
  group('questPaperAssetIds', () {
    test('enemy uses the enemy family', () {
      expect(questPaperAssetIds(QuestType.enemy, isTorn: false), [
        CloudinaryAssets.enemySheet1,
        CloudinaryAssets.enemySheet2,
      ]);
      expect(questPaperAssetIds(QuestType.enemy, isTorn: true), [
        CloudinaryAssets.enemyTornSheet1,
        CloudinaryAssets.enemyTornSheet2,
      ]);
    });

    test('boss has its own whole sheets and the torn enemy ones', () {
      expect(questPaperAssetIds(QuestType.boss, isTorn: false), [
        CloudinaryAssets.bossSheet1,
        CloudinaryAssets.bossSheet2,
      ]);
      expect(questPaperAssetIds(QuestType.boss, isTorn: true), [
        CloudinaryAssets.enemyTornSheet1,
        CloudinaryAssets.enemyTornSheet2,
      ]);
    });

    test('dungeon uses the quest family', () {
      expect(questPaperAssetIds(QuestType.dungeon, isTorn: false), [
        CloudinaryAssets.questSheet2,
        CloudinaryAssets.questSheet1,
      ]);
      expect(questPaperAssetIds(QuestType.dungeon, isTorn: true), [
        CloudinaryAssets.questSheetTorn1,
        CloudinaryAssets.questSheetTorn2,
      ]);
    });

    test('aid uses its own whole and torn sheets', () {
      expect(questPaperAssetIds(QuestType.aid, isTorn: false), [
        CloudinaryAssets.aidSheet1,
        CloudinaryAssets.aidSheet2,
      ]);
      expect(questPaperAssetIds(QuestType.aid, isTorn: true), [
        CloudinaryAssets.aidTornSheet1,
        CloudinaryAssets.aidTornSheet2,
      ]);
    });

    test('story has a torn variant', () {
      expect(questPaperAssetIds(QuestType.story, isTorn: false), [
        CloudinaryAssets.storySheet1,
        CloudinaryAssets.storySheet2,
      ]);
      expect(questPaperAssetIds(QuestType.story, isTorn: true), [
        CloudinaryAssets.storyTornSheet2,
        CloudinaryAssets.storyTornSheet1,
      ]);
    });

    test('worldMission uses its own whole and torn sheets', () {
      expect(questPaperAssetIds(QuestType.worldMission, isTorn: false), [
        CloudinaryAssets.worldMissionSheet,
      ]);
      expect(questPaperAssetIds(QuestType.worldMission, isTorn: true), [
        CloudinaryAssets.worldMissionTornSheet,
      ]);
    });

    test('job has a torn variant', () {
      expect(questPaperAssetIds(QuestType.job, isTorn: false), [
        CloudinaryAssets.jobSheet1,
        CloudinaryAssets.jobSheet2,
      ]);
      expect(questPaperAssetIds(QuestType.job, isTorn: true), [
        CloudinaryAssets.jobTornSheet1,
        CloudinaryAssets.jobTornSheet2,
      ]);
    });

    test('study uses the announcement sheets, whole and torn', () {
      expect(questPaperAssetIds(QuestType.study, isTorn: false), [
        CloudinaryAssets.announcementSheet1,
        CloudinaryAssets.announcementSheet2,
      ]);
      expect(questPaperAssetIds(QuestType.study, isTorn: true), [
        CloudinaryAssets.announcementTornSheet1,
        CloudinaryAssets.announcementTornSheet2,
      ]);
    });

    test('every quest type has a torn sheet of its own family', () {
      for (final type in QuestType.values) {
        expect(
          questPaperAssetIds(type, isTorn: true),
          isNot(questPaperAssetIds(type, isTorn: false)),
          reason: type.name,
        );
      }
    });

    test('hunt uses its own whole and torn sheets', () {
      expect(questPaperAssetIds(QuestType.hunt, isTorn: false), [
        CloudinaryAssets.huntSheet1,
        CloudinaryAssets.huntSheet2,
      ]);
      expect(questPaperAssetIds(QuestType.hunt, isTorn: true), [
        CloudinaryAssets.huntTornSheet1,
        CloudinaryAssets.huntTornSheet2,
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

    test('heal uses its own whole and torn sheets', () {
      expect(questPaperAssetIds(QuestType.heal, isTorn: false), [
        CloudinaryAssets.healSheet1,
        CloudinaryAssets.healSheet2,
      ]);
      expect(questPaperAssetIds(QuestType.heal, isTorn: true), [
        CloudinaryAssets.healTornSheet1,
        CloudinaryAssets.healTornSheet2,
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
        CloudinaryAssets.enemyTornSheet1,
        'v1794313032/tornHuntSheet1_tk1xqh.svg',
      );
      expect(
        CloudinaryAssets.enemyTornSheet2,
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

    test('the hunt sheets point to their files', () {
      expect(CloudinaryAssets.huntSheet1, 'v1794324911/gameSheet1_togp4w.svg');
      expect(CloudinaryAssets.huntSheet2, 'v1794324912/gameSheet2_zrmzpe.svg');
      expect(
        CloudinaryAssets.huntTornSheet1,
        'v1794324905/tornGameSheet1_ruztfx.svg',
      );
      expect(
        CloudinaryAssets.huntTornSheet2,
        'v1794324906/tornGameSheet2_j1xtv6.svg',
      );
    });

    test('the torn job sheets point to their files', () {
      expect(
        CloudinaryAssets.jobTornSheet1,
        'v1794329019/tornJobSheet1_ivb31s.svg',
      );
      expect(
        CloudinaryAssets.jobTornSheet2,
        'v1794329024/tornJobSheet2_muovna.svg',
      );
    });

    test('the heal sheets point to their files', () {
      expect(CloudinaryAssets.healSheet1, 'v1794329008/healSheet1_as1rng.svg');
      expect(CloudinaryAssets.healSheet2, 'v1794329013/healSheet2_yosyxa.svg');
      expect(
        CloudinaryAssets.healTornSheet1,
        'v1794329028/tornHealSheet1_am4kxg.svg',
      );
      expect(
        CloudinaryAssets.healTornSheet2,
        'v1794329034/tornHealSheet2_cppkog.svg',
      );
    });

    test('the world mission sheets point to their files', () {
      expect(
        CloudinaryAssets.worldMissionSheet,
        'v1794330767/worldMissionSheet_uvximo.svg',
      );
      expect(
        CloudinaryAssets.worldMissionTornSheet,
        'v1794330793/tornWorldMissionSheet_xaijpq.svg',
      );
    });

    test('the boss and aid sheets point to their files', () {
      expect(CloudinaryAssets.bossSheet1, 'v1794330835/bossSheet_kmcubi.svg');
      expect(CloudinaryAssets.bossSheet2, 'v1794331761/bossSheet2_jpfofw.svg');
      expect(CloudinaryAssets.aidSheet1, 'v1794331772/aidSheet1_bv1und.svg');
      expect(CloudinaryAssets.aidSheet2, 'v1794331778/aidSheet2_iuxlwt.svg');
      expect(
        CloudinaryAssets.aidTornSheet1,
        'v1794333401/tornAidSheet1_gbxr9p.svg',
      );
      expect(
        CloudinaryAssets.aidTornSheet2,
        'v1794333419/tornAidSheet2_t4eep5.svg',
      );
    });
  });
}
