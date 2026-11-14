import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/companion/companion_potion_target.dart';
import 'package:klimmeck_guide/models/companion/companion_vitality.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';

import '../../helpers/fixtures/shop_fixtures.dart';

const String _worg = 'pet-worg';
const String _owl = 'pet-owl';

OwnedPet _owned(String id, String species, {String? name}) =>
    OwnedPet.tryFromJson(
      ownedPetJson(
        pet: petJson(id: id, name: species, maxLifePoints: 100),
        currentLifePoints: 40,
        name: name,
      ),
    )!;

List<CompanionPotionTarget> _targetsOf(
  List<OwnedPet> owned, {
  Map<String, CompanionVitality> vitalities = const {},
  Map<String, Duration> waits = const {},
}) => companionPotionTargetsOf(
  owned,
  vitalityOf: (petId) => vitalities[petId],
  potionWaitOf: (petId) => waits[petId],
);

void main() {
  final worg = _owned(_worg, 'Worg', name: 'Fenrir');
  final owl = _owned(_owl, 'Gufo');

  test('targets are the companions below full life, equipped or resting '
      '(D-07)', () {
    final targets = _targetsOf(
      [worg, owl],
      vitalities: const {
        _worg: CompanionSteady(life: 40, maxLifePoints: 100),
        _owl: CompanionResting(
          life: 60,
          maxLifePoints: 100,
          remaining: Duration(minutes: 20),
        ),
      },
    );

    expect(targets, [
      CompanionPotionTarget(owned: worg, life: 40, maxLifePoints: 100),
      CompanionPotionTarget(owned: owl, life: 60, maxLifePoints: 100),
    ]);
  });

  test('a defeated companion is not a target (D-06)', () {
    final targets = _targetsOf(
      [worg],
      vitalities: const {
        _worg: CompanionDefeated(
          life: 10,
          maxLifePoints: 100,
          remaining: Duration(minutes: 80),
        ),
      },
    );

    expect(targets, isEmpty);
  });

  test('a companion in its own wait is not listed (D-32)', () {
    final targets = _targetsOf(
      [worg, owl],
      vitalities: const {
        _worg: CompanionSteady(life: 40, maxLifePoints: 100),
        _owl: CompanionSteady(life: 40, maxLifePoints: 100),
      },
      waits: const {_worg: Duration(minutes: 5)},
    );

    expect(targets.map((target) => target.petId), [_owl]);
  });

  test('a companion at full life or without a max is not a target (D-32)', () {
    final targets = _targetsOf(
      [worg, owl],
      vitalities: const {
        _worg: CompanionSteady(life: 100, maxLifePoints: 100),
        _owl: CompanionSteady(life: 40, maxLifePoints: null),
      },
    );

    expect(targets, isEmpty);
    expect(_targetsOf([worg]), isEmpty, reason: 'no vitality served');
  });

  test('a levelled companion is a target until its own max (D-37, D-38)', () {
    final targets = _targetsOf(
      [worg],
      vitalities: const {_worg: CompanionSteady(life: 150, maxLifePoints: 200)},
    );

    expect(targets.single.life, 150);
    expect(targets.single.maxLifePoints, 200);
  });

  test('targets read the display name (D-08, D-20)', () {
    final targets = _targetsOf(
      [worg, owl],
      vitalities: const {
        _worg: CompanionSteady(life: 40, maxLifePoints: 100),
        _owl: CompanionSteady(life: 40, maxLifePoints: 100),
      },
    );

    expect(targets.map((target) => target.name), ['Fenrir', 'Gufo']);
    expect(targets.map((target) => target.petId), [_worg, _owl]);
  });
}
