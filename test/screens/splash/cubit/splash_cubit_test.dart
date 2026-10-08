import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';

import '../../../helpers/mocks.dart';

void main() {
  late SplashCubit cubit;

  setUp(() {
    cubit = SplashCubit(MockKlimmeckRest());
  });

  group('bootstrap watch', () {
    test('emits SplashNetworkDelayed exactly after 10 seconds', () {
      fakeAsync((async) {
        cubit.startBootstrapWatch();

        async.elapse(const Duration(milliseconds: 9900));
        expect(cubit.state, const SplashInitial());

        async.elapse(const Duration(milliseconds: 100));
        expect(cubit.state, const SplashNetworkDelayed());
      });
    });

    test('stop before the delay prevents the emission', () {
      fakeAsync((async) {
        final states = <SplashState>[];
        cubit.stream.listen(states.add);

        cubit.startBootstrapWatch();
        async.elapse(const Duration(seconds: 5));
        cubit.stopBootstrapWatch();
        async.elapse(const Duration(seconds: 10));

        expect(states, isEmpty);
        expect(cubit.state, const SplashInitial());
      });
    });

    test('stop after the delay returns to SplashInitial', () {
      fakeAsync((async) {
        cubit.startBootstrapWatch();
        async.elapse(SplashCubit.connectionHintDelay);
        expect(cubit.state, const SplashNetworkDelayed());

        cubit.stopBootstrapWatch();
        async.flushMicrotasks();

        expect(cubit.state, const SplashInitial());
      });
    });

    test('starting twice keeps a single timer', () {
      fakeAsync((async) {
        final states = <SplashState>[];
        cubit.stream.listen(states.add);

        cubit.startBootstrapWatch();
        async.elapse(const Duration(seconds: 4));
        cubit.startBootstrapWatch();
        async.elapse(const Duration(seconds: 20));

        expect(states, [const SplashNetworkDelayed()]);
      });
    });

    test('close cancels the pending timer', () {
      fakeAsync((async) {
        cubit.startBootstrapWatch();
        cubit.close();

        expect(
          () => async.elapse(const Duration(seconds: 15)),
          returnsNormally,
        );
        expect(async.pendingTimers, isEmpty);
      });
    });
  });
}
