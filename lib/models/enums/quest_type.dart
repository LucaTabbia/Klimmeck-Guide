enum QuestType {
  hunt(imagePath: "assets/icons/svg/pawns/huntPawn.svg"),
  aid(imagePath: "assets/icons/svg/pawns/aidPawn.svg"),
  enemy(imagePath: "assets/icons/svg/pawns/enemyPawn.svg"),
  worldMission(imagePath: "assets/icons/svg/pawns/worldMissionPawn.svg"),
  boss(imagePath: "assets/icons/svg/pawns/bossPawn.svg"),
  dungeon(imagePath: "assets/icons/svg/pawns/dungeonPawn.svg"),
  story(imagePath: "assets/icons/svg/pawns/storyPawn.svg"),
  study(imagePath: ""),
  heal(imagePath: ""),
  job(imagePath: ""),
  crime(imagePath: ""),
  guard(imagePath: "");

  final String imagePath;

  const QuestType({required this.imagePath});
}
