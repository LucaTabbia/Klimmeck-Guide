import '../../config/cloudinary_assets.dart';
import '../enums/quest_type.dart';
import 'quest.dart';

/// Famiglia di asset del foglio sulla board (D-12), riusata dal foglio sulla mappa (D-07).
List<String> questPaperAssetIds(
  QuestType? type, {
  required bool isTorn,
}) => switch (type) {
  QuestType.boss || QuestType.enemy =>
    isTorn
        ? const [
            CloudinaryAssets.huntTornSheet1,
            CloudinaryAssets.huntTornSheet2,
          ]
        : const [CloudinaryAssets.huntSheet1, CloudinaryAssets.huntSheet2],
  QuestType.story || QuestType.worldMission =>
    isTorn
        ? const [
            CloudinaryAssets.storyTornSheet2,
            CloudinaryAssets.storyTornSheet1,
          ]
        : const [CloudinaryAssets.storySheet1, CloudinaryAssets.storySheet2],
  QuestType.crime =>
    isTorn
        ? const [
            CloudinaryAssets.crimeTornSheet1,
            CloudinaryAssets.crimeTornSheet2,
          ]
        : const [CloudinaryAssets.crimeSheet1, CloudinaryAssets.crimeSheet2],
  QuestType.guard =>
    isTorn
        ? const [
            CloudinaryAssets.guardTornSheet1,
            CloudinaryAssets.guardTornSheet2,
          ]
        : const [CloudinaryAssets.guardSheet1, CloudinaryAssets.guardSheet2],
  // Senza foglio strappato finché non arrivano gli asset:
  // hunt/job e study usano il foglio intero anche se strappati.
  QuestType.hunt || QuestType.job => const [
    CloudinaryAssets.jobSheet1,
    CloudinaryAssets.jobSheet2,
  ],
  QuestType.heal =>
    isTorn
        ? const [
            CloudinaryAssets.announcementTornSheet1,
            CloudinaryAssets.announcementTornSheet2,
          ]
        : const [
            CloudinaryAssets.announcementSheet1,
            CloudinaryAssets.announcementSheet2,
          ],
  QuestType.study => const [
    CloudinaryAssets.announcementSheet1,
    CloudinaryAssets.announcementSheet2,
  ],
  QuestType.magic =>
    isTorn
        ? const [CloudinaryAssets.magicTornSheet]
        : const [CloudinaryAssets.magicSheet],
  QuestType.dungeon || QuestType.aid || null =>
    isTorn
        ? const [
            CloudinaryAssets.questSheetTorn1,
            CloudinaryAssets.questSheetTorn2,
          ]
        : const [CloudinaryAssets.questSheet2, CloudinaryAssets.questSheet1],
};

/// Variante stabile per quest (mai Random): lo stesso foglio a ogni rebuild.
String questPaperAssetId(Quest quest, {required bool isTorn}) {
  final ids = questPaperAssetIds(quest.infos?.type, isTorn: isTorn);
  final seed = quest.id.codeUnits.fold(0, (sum, unit) => sum + unit);
  return ids[seed % ids.length];
}
