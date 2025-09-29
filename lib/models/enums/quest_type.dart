enum QuestType {
  hunt(
    imagePath: "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660721/huntPawn_h7bdwj.svg",
  ),
  aid(
    imagePath: "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660712/aidPawn_zyoz99.svg",
  ),
  enemy(
    imagePath: "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660715/enemyPawn_c4vstz.svg",
  ),
  worldMission(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660713/worldMissionPawn_bjjzc0.svg",
  ),
  boss(
    imagePath: "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660719/bossPawn_vsz4pf.svg",
  ),
  dungeon(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660716/dungeonPawn_bhbatx.svg",
  ),
  story(
    imagePath: "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660718/storyPawn_rvclmp.svg",
  ),
  study(imagePath: ""),
  heal(imagePath: ""),
  job(imagePath: ""),
  crime(imagePath: ""),
  guard(imagePath: "");

  final String imagePath;

  const QuestType({required this.imagePath});
}
