import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/spell/spell_recovery_status.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_cubit.dart';

import '../../../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../../../helpers/fixtures/spell_fixtures.dart';

const _spellA = 'spell-a';
const _spellB = 'spell-b';

DateTime _at(int minute, [int second = 0]) =>
    DateTime.utc(2026, 10, 27, 10, minute, second);

SpellRecoveryInput _input(
  String spellId, {
  required int usages,
  int? maxUsages = 3,
  List<DateTime> recoveries = const [],
}) => SpellRecoveryInput(
  spellId: spellId,
  usages: usages,
  maxUsages: maxUsages,
  recoveries: recoveries,
);

void main() {
  group('follow', () {
    test('starts empty and reads an unknown id as full', () {
      final cubit = SpellRecoveryCubit(
        clock: FakeServerClockService(spellFixtureNow),
      );

      expect(cubit.state, const SpellRecoveryState({}));
      expect(cubit.state.statusOf('x'), const SpellRecoveryFull());
      cubit.close();
    });

    test('inputsOf maps every spellbook entry in list order', () {
      final character = spellbookCharacter(
        spells: [
          spellJson(id: _spellA),
          spellJson(id: _spellB),
          spellJson(id: 'spell-c', maxUsages: null),
        ],
        spellStates: [spellStateJson(spellId: _spellA)],
      );

      final inputs = SpellRecoveryCubit.inputsOf(Spellbook.of(character));

      expect(inputs, [
        _input(_spellA, usages: 1, recoveries: [_at(12), _at(42)]),
        _input(_spellB, usages: 3),
        _input('spell-c', usages: 0, maxUsages: null),
      ]);
    });

    test('derives a countdown and a full status on server time', () {
      fakeAsync((async) {
        final cubit = SpellRecoveryCubit(
          clock: FakeServerClockService(spellFixtureNow),
        );
        final states = <SpellRecoveryState>[];
        final subscription = cubit.stream.listen(states.add);

        cubit.follow([
          _input(_spellA, usages: 1, recoveries: [_at(12), _at(42)]),
          _input(_spellB, usages: 3),
        ]);
        async.flushMicrotasks();

        expect(states, const [
          SpellRecoveryState({
            _spellA: SpellRecoveryCountdown(remainingMinutes: 12),
            _spellB: SpellRecoveryFull(),
          }),
        ]);
        subscription.cancel();
        cubit.close();
      });
    });

    test('the same inputs again emit nothing', () {
      fakeAsync((async) {
        final cubit = SpellRecoveryCubit(
          clock: FakeServerClockService(spellFixtureNow),
        );
        final inputs = [
          _input(_spellA, usages: 1, recoveries: [_at(12), _at(42)]),
          _input(_spellB, usages: 3),
        ];
        cubit.follow(inputs);
        final states = <SpellRecoveryState>[];
        final subscription = cubit.stream.listen(states.add);

        cubit.follow(List.of(inputs));
        async.flushMicrotasks();

        expect(states, isEmpty);
        subscription.cancel();
        cubit.close();
      });
    });

    test('usages below the maximum without instants read as unknown', () {
      fakeAsync((async) {
        final cubit = SpellRecoveryCubit(
          clock: FakeServerClockService(spellFixtureNow),
        );

        cubit.follow([_input(_spellA, usages: 1)]);

        expect(
          cubit.state,
          const SpellRecoveryState({_spellA: SpellRecoveryUnknown()}),
        );
        cubit.close();
      });
    });
  });
}
