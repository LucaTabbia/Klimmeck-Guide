import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/companion/companion_vitality.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_cubit.dart';

import '../../../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../../../helpers/fixtures/shop_fixtures.dart';

const _worg = 'pet-worg';
const _cat = 'pet-cat';

final DateTime _t0 = DateTime.utc(2026, 11, 14, 10);
final DateTime _exampleFullLifeAt = _t0.add(
  const Duration(milliseconds: 4848485),
);

OwnedPet _owned({
  String id = _worg,
  int currentLifePoints = 20,
  int speciesMax = 100,
  int? ownMax,
  bool? defeated,
  DateTime? lifeAsOf,
  DateTime? fullLifeAt,
  DateTime? potionRecoveryUntil,
}) => OwnedPet.tryFromJson(
  ownedPetJson(
    pet: petJson(id: id, name: id, maxLifePoints: speciesMax),
    currentLifePoints: currentLifePoints,
    maxLifePoints: ownMax,
    defeated: defeated,
    lifeAsOf: lifeAsOf?.toIso8601String(),
    fullLifeAt: fullLifeAt?.toIso8601String(),
    potionRecoveryUntil: potionRecoveryUntil?.toIso8601String(),
  ),
)!;

OwnedPet _resting() => _owned(lifeAsOf: _t0, fullLifeAt: _exampleFullLifeAt);

void main() {
  late FakeServerClockService clock;
  late CompanionVitalityCubit cubit;
  late List<CompanionVitalityState> states;

  void startAt(DateTime now) {
    clock = FakeServerClockService(now);
    cubit = CompanionVitalityCubit(clock: clock);
    states = [];
    cubit.stream.listen(states.add);
  }

  void tickAfter(FakeAsync async, Duration delta) {
    clock.advance(delta);
    async.elapse(CompanionVitalityCubit.defaultTick);
  }

  test('starts empty and reads an unknown id as null', () {
    final cubit = CompanionVitalityCubit(clock: FakeServerClockService(_t0));

    expect(cubit.state, const CompanionVitalityState());
    expect(cubit.state.vitalityOf(_worg), isNull);
    expect(cubit.state.potionWaitOf(_worg), isNull);
    cubit.close();
  });

  test('follow emits a vitality per owned companion keyed by pet id '
      '(D-09)', () {
    fakeAsync((async) {
      startAt(_t0);

      cubit.follow([
        _owned(currentLifePoints: 30),
        _owned(id: _cat, currentLifePoints: 8, speciesMax: 10),
      ]);
      async.flushMicrotasks();

      expect(states, const [
        CompanionVitalityState(
          vitalities: {
            _worg: CompanionSteady(life: 30, maxLifePoints: 100),
            _cat: CompanionSteady(life: 8, maxLifePoints: 10),
          },
        ),
      ]);
      cubit.close();
    });
  });

  test('a resting companion rises at each tick until fullLifeAt '
      '(D-09, D-24)', () {
    fakeAsync((async) {
      startAt(_t0);
      cubit.follow([_resting()]);

      tickAfter(async, const Duration(minutes: 20));

      final twentyMinutesIn = _t0.add(const Duration(minutes: 20));
      expect(
        cubit.state.vitalityOf(_worg),
        CompanionResting(
          life: 40,
          maxLifePoints: 100,
          remaining: _exampleFullLifeAt.difference(twentyMinutesIn),
        ),
      );

      clock.current = _exampleFullLifeAt;
      async.elapse(CompanionVitalityCubit.defaultTick);

      expect(
        cubit.state.vitalityOf(_worg),
        const CompanionSteady(life: 100, maxLifePoints: 100),
      );
      expect(async.pendingTimers, isEmpty);
      cubit.close();
    });
  });

  test('the equipped companion never rises (D-04)', () {
    fakeAsync((async) {
      startAt(_t0);
      cubit.follow([_resting()], equippedPetId: _worg);

      tickAfter(async, const Duration(minutes: 20));

      expect(
        cubit.state.vitalityOf(_worg),
        const CompanionSteady(life: 20, maxLifePoints: 100),
      );
      expect(async.pendingTimers, isEmpty);
      cubit.close();
    });
  });

  test('a levelled companion rises to its own max (D-37)', () {
    fakeAsync((async) {
      startAt(_t0);
      cubit.follow([
        _owned(
          currentLifePoints: 100,
          ownMax: 200,
          lifeAsOf: _t0,
          fullLifeAt: _t0.add(const Duration(hours: 2)),
        ),
      ]);

      tickAfter(async, const Duration(hours: 1));

      expect(
        cubit.state.vitalityOf(_worg),
        const CompanionResting(
          life: 150,
          maxLifePoints: 200,
          remaining: Duration(hours: 1),
        ),
      );
      cubit.close();
    });
  });

  test('the companion potion wait ticks with the same timer and disappears '
      'when over (D-05)', () {
    fakeAsync((async) {
      startAt(_t0);
      cubit.follow([
        _owned(
          currentLifePoints: 100,
          potionRecoveryUntil: _t0.add(const Duration(minutes: 20)),
        ),
      ]);

      expect(cubit.state.potionWaitOf(_worg), const Duration(minutes: 20));
      expect(async.pendingTimers, hasLength(1));

      tickAfter(async, const Duration(minutes: 5));
      expect(cubit.state.potionWaitOf(_worg), const Duration(minutes: 15));

      tickAfter(async, const Duration(minutes: 15));
      expect(cubit.state.potionWaitOf(_worg), isNull);
      expect(cubit.state.potionWaits, isEmpty);
      expect(async.pendingTimers, isEmpty);
      cubit.close();
    });
  });

  test('the ticker stops when nothing rests and nothing waits (D-09)', () {
    fakeAsync((async) {
      startAt(_t0);
      cubit.follow([_owned(currentLifePoints: 100)]);
      async.flushMicrotasks();
      states.clear();

      tickAfter(async, const Duration(minutes: 20));

      expect(states, isEmpty);
      expect(async.pendingTimers, isEmpty);
      cubit.close();
    });
  });

  test('a defeated companion keeps the timer alive (D-02, D-09)', () {
    fakeAsync((async) {
      startAt(_t0);
      cubit.follow([
        _owned(
          currentLifePoints: 1,
          defeated: true,
          lifeAsOf: _t0,
          fullLifeAt: _t0.add(const Duration(hours: 3)),
        ),
      ]);

      tickAfter(async, const Duration(hours: 1));

      expect(cubit.state.vitalityOf(_worg), isA<CompanionDefeated>());
      expect(async.pendingTimers, hasLength(1));
      cubit.close();
    });
  });

  test('vitalityFor never serves the vitality of an older entry of the same '
      'companion (D-02)', () {
    fakeAsync((async) {
      startAt(_t0);
      final followed = _resting();
      cubit.follow([followed]);
      final served = _owned(
        currentLifePoints: 1,
        defeated: true,
        lifeAsOf: _t0,
        fullLifeAt: _t0.add(const Duration(hours: 3)),
      );

      expect(cubit.state.vitalityFor(followed), isA<CompanionResting>());
      expect(cubit.state.vitalityFor(served), isNull);
      cubit.close();
    });
  });

  test('an offset change recomputes at once (D-24)', () {
    fakeAsync((async) {
      startAt(_t0);
      cubit.follow([_resting()]);

      clock.resync(_t0.add(const Duration(minutes: 20)));
      async.flushMicrotasks();

      expect(cubit.state.vitalityOf(_worg)?.life, 40);
      cubit.close();
    });
  });

  test('close cancels the timer and the offset listener', () {
    fakeAsync((async) {
      startAt(_t0);
      cubit.follow([_resting()]);
      expect(async.pendingTimers, hasLength(1));

      cubit.close();
      async.flushMicrotasks();
      states.clear();
      clock.resync(_t0.add(const Duration(minutes: 20)));
      async.elapse(const Duration(seconds: 5));

      expect(async.pendingTimers, isEmpty);
      expect(states, isEmpty);
      expect(cubit.isClosed, isTrue);
    });
  });
}
