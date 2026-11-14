import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/companion/companion_vitality.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';
import 'package:klimmeck_guide/models/pet.dart';

final DateTime t0 = DateTime.utc(2026, 11, 14, 10);

OwnedPet ownedWith({
  int currentLifePoints = 20,
  int? maxLifePoints = 100,
  int? ownMaxLifePoints,
  bool isDefeated = false,
  DateTime? lifeAsOf,
  DateTime? fullLifeAt,
  DateTime? potionRecoveryUntil,
}) => OwnedPet(
  pet: Pet(
    id: 'worg',
    name: 'Worg',
    buyPrice: null,
    sellPrice: null,
    maxXp: null,
    imagePath: null,
    maxLifePoints: maxLifePoints,
  ),
  xp: 0,
  currentLifePoints: currentLifePoints,
  ownMaxLifePoints: ownMaxLifePoints,
  isDefeated: isDefeated,
  lifeAsOf: lifeAsOf,
  fullLifeAt: fullLifeAt,
  potionRecoveryUntil: potionRecoveryUntil,
);

void main() {
  final exampleFullLifeAt = t0.add(const Duration(milliseconds: 4848485));

  group('companionVitalityOf', () {
    test('an equipped companion never rises with time (D-04)', () {
      final owned = ownedWith(lifeAsOf: t0, fullLifeAt: exampleFullLifeAt);

      expect(
        companionVitalityOf(
          owned,
          t0.add(const Duration(minutes: 20)),
          isEquipped: true,
        ),
        const CompanionSteady(life: 20, maxLifePoints: 100),
      );
    });

    test('without dates the served life is steady (D-24)', () {
      expect(
        companionVitalityOf(ownedWith(), t0, isEquipped: false),
        const CompanionSteady(life: 20, maxLifePoints: 100),
      );
    });

    test('the user\'s example reads 40 after 20 minutes of rest (D-24)', () {
      final owned = ownedWith(lifeAsOf: t0, fullLifeAt: exampleFullLifeAt);
      final now = t0.add(const Duration(minutes: 20));

      expect(
        companionVitalityOf(owned, now, isEquipped: false),
        CompanionResting(
          life: 40,
          maxLifePoints: 100,
          remaining: exampleFullLifeAt.difference(now),
        ),
      );
    });

    test('the life never reads full before fullLifeAt (D-09)', () {
      final owned = ownedWith(lifeAsOf: t0, fullLifeAt: exampleFullLifeAt);
      final now = exampleFullLifeAt.subtract(const Duration(seconds: 1));

      expect(
        companionVitalityOf(owned, now, isEquipped: false),
        const CompanionResting(
          life: 99,
          maxLifePoints: 100,
          remaining: Duration(seconds: 1),
        ),
      );
    });

    test(
      'at fullLifeAt the companion is steady at full life, defeat over (D-02, D-24)',
      () {
        final owned = ownedWith(
          currentLifePoints: 1,
          isDefeated: true,
          lifeAsOf: t0,
          fullLifeAt: exampleFullLifeAt,
        );

        expect(
          companionVitalityOf(owned, exampleFullLifeAt, isEquipped: false),
          const CompanionSteady(life: 100, maxLifePoints: 100),
        );
      },
    );

    test(
      'a defeated companion before fullLifeAt is Defeated with the remaining time (D-02, D-09)',
      () {
        final owned = ownedWith(
          currentLifePoints: 1,
          isDefeated: true,
          lifeAsOf: t0,
          fullLifeAt: t0.add(const Duration(hours: 3)),
        );

        expect(
          companionVitalityOf(
            owned,
            t0.add(const Duration(hours: 1)),
            isEquipped: false,
          ),
          const CompanionDefeated(
            life: 34,
            maxLifePoints: 100,
            remaining: Duration(hours: 2),
          ),
        );
      },
    );

    test('a clock before lifeAsOf reads the served life (D-24)', () {
      final owned = ownedWith(lifeAsOf: t0, fullLifeAt: exampleFullLifeAt);
      final now = t0.subtract(const Duration(minutes: 5));

      expect(
        companionVitalityOf(owned, now, isEquipped: false),
        CompanionResting(
          life: 20,
          maxLifePoints: 100,
          remaining: exampleFullLifeAt.difference(now),
        ),
      );
    });

    test(
      'dates in the wrong order never crash and read one short of full (D-24)',
      () {
        final inverted = ownedWith(
          lifeAsOf: t0.add(const Duration(hours: 1)),
          fullLifeAt: t0.add(const Duration(minutes: 30)),
        );

        expect(
          companionVitalityOf(inverted, t0, isEquipped: false),
          const CompanionResting(
            life: 99,
            maxLifePoints: 100,
            remaining: Duration(minutes: 30),
          ),
        );
      },
    );

    test('a missing max keeps the served life steady (D-09)', () {
      final owned = ownedWith(
        maxLifePoints: null,
        lifeAsOf: t0,
        fullLifeAt: exampleFullLifeAt,
      );

      expect(
        companionVitalityOf(
          owned,
          t0.add(const Duration(minutes: 20)),
          isEquipped: false,
        ),
        const CompanionSteady(life: 20, maxLifePoints: null),
      );
    });
  });

  group('companion levels', () {
    final fullLifeAt = t0.add(const Duration(hours: 2));

    test('a levelled companion rests up to its own max (D-37, D-38)', () {
      final owned = ownedWith(
        currentLifePoints: 100,
        ownMaxLifePoints: 200,
        lifeAsOf: t0,
        fullLifeAt: fullLifeAt,
      );

      expect(
        companionVitalityOf(
          owned,
          t0.add(const Duration(hours: 1)),
          isEquipped: false,
        ),
        const CompanionResting(
          life: 150,
          maxLifePoints: 200,
          remaining: Duration(hours: 1),
        ),
      );
      expect(
        companionVitalityOf(owned, fullLifeAt, isEquipped: false),
        const CompanionSteady(life: 200, maxLifePoints: 200),
      );
    });

    test('without an own max the species max is used (D-38)', () {
      final owned = ownedWith(
        currentLifePoints: 50,
        lifeAsOf: t0,
        fullLifeAt: fullLifeAt,
      );

      expect(
        companionVitalityOf(
          owned,
          t0.add(const Duration(hours: 1)),
          isEquipped: false,
        ),
        const CompanionResting(
          life: 75,
          maxLifePoints: 100,
          remaining: Duration(hours: 1),
        ),
      );
    });
  });

  group('companionPotionWaitOf', () {
    test(
      'the companion potion wait is the time left to its own date (D-05)',
      () {
        final owned = ownedWith(
          potionRecoveryUntil: t0.add(const Duration(minutes: 20)),
        );

        expect(companionPotionWaitOf(owned, t0), const Duration(minutes: 20));
      },
    );

    test('a passed or absent potion wait reads null (D-05)', () {
      final passed = ownedWith(potionRecoveryUntil: t0);

      expect(companionPotionWaitOf(passed, t0), isNull);
      expect(companionPotionWaitOf(ownedWith(), t0), isNull);
    });
  });
}
