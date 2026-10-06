import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

class _CounterCubit extends Cubit<int> with SafeEmit<int> {
  _CounterCubit() : super(0);

  void set(int value) => emit(value);
}

void main() {
  group('SafeEmit', () {
    test('emits normally while open', () async {
      final cubit = _CounterCubit();
      final states = <int>[];
      final subscription = cubit.stream.listen(states.add);

      cubit.set(1);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, 1);
      expect(states, [1]);
      await subscription.cancel();
      await cubit.close();
    });

    test('an emit after close is a silent no-op', () async {
      final cubit = _CounterCubit()..set(1);
      await cubit.close();

      expect(() => cubit.set(2), returnsNormally);
      expect(cubit.state, 1);
    });
  });
}
