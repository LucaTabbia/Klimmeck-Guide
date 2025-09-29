enum InjuryEffect {
  movementImpairment(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660619/movementInjury_p2afa1.svg",
  ),
  visionLoss(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660621/visionInjury_co2nry.svg",
  ),
  bleeding(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660617/bleedingInjury_rptyig.svg",
  ),
  pain(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660627/painInjury_qxcb2z.svg",
  ),
  paralysis(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660626/paralysisInjury_zmnbhi.svg",
  ),
  infection(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660628/infectionInjury_fwdxie.svg",
  ),
  consciousnessLoss(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660622/consciousnessInjury_bav1ef.svg",
  ),
  staminaDrain(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660625/staminaInjury_jtonqa.svg",
  ),
  poisoned(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660623/poisonInjury_qv9hpg.svg",
  ),
  burned(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660620/burnInjury_bp59xq.svg",
  );

  final String imagePath;

  const InjuryEffect({required this.imagePath});
}
