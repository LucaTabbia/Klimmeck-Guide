import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/lore.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fakes/recording_image_warmer.dart';
import '../../../helpers/fixtures/lore_fixtures.dart';
import '../../../helpers/mocks.dart';

const _folderUrls = [
  'https://res.cloudinary.com/x/image/upload/v1/main/arrow.svg',
  'https://res.cloudinary.com/x/image/upload/v1/main/bookmark.svg',
];
const _cityA = 'https://res.cloudinary.com/x/image/upload/v1/cities/a.svg';
const _cityB = 'https://res.cloudinary.com/x/image/upload/v1/cities/b.svg';

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

  group('image warm-up at the cold start', () {
    late MockKlimmeckRest rest;
    late MockKlimmeckGraphQl graphQl;
    late RecordingImageWarmer warmer;
    final lores = [
      Lore.fromJson(loreJson(id: 'lore-a', name: 'Andogan', image: _cityA)),
      Lore.fromJson(loreJson(id: 'lore-b', name: 'Bosa', image: _cityB)),
      Lore.fromJson(loreJson(id: 'lore-v', type: 'region', name: 'Valtorre')),
    ];

    setUp(() {
      // CacheExpiry and KGStorageManager read the legacy static
      // SharedPreferences: an empty store means «no valid cache yet».
      SharedPreferences.setMockInitialValues({});
      rest = MockKlimmeckRest();
      graphQl = MockKlimmeckGraphQl();
      warmer = RecordingImageWarmer();
      when(
        () => rest.fetchCloudinarySubfoldersUrls('main'),
      ).thenAnswer((_) async => _folderUrls);
    });

    test(
      "warms the viewer's lore images before the data state (D-22)",
      () async {
        when(() => graphQl.getAllLores()).thenAnswer((_) async => lores);
        final loreWarmUp = Completer<void>();
        warmer.holds[2] = loreWarmUp;
        final cubit = SplashCubit(rest, graphQl: graphQl, warmer: warmer);

        final preload = cubit.getImages('main');
        await pumpEventQueue();

        expect(warmer.calls, [
          _folderUrls,
          [_cityA, _cityB],
        ]);
        expect(cubit.state, const SplashInitial());

        loreWarmUp.complete();
        await preload;

        expect(cubit.state, const SplashData());
        await cubit.close();
      },
    );

    test('a cubit built without graphQl preloads the folder only, as today '
        '(D-22)', () async {
      final cubit = SplashCubit(rest, warmer: warmer);

      await cubit.getImages('main');

      expect(warmer.calls, [_folderUrls]);
      expect(cubit.state, const SplashData());
      await cubit.close();
    });

    test(
      'a failing lore read or warm-up still ends in the data state (D-22)',
      () async {
        when(() => graphQl.getAllLores()).thenThrow(StateError('offline'));
        final cubit = SplashCubit(rest, graphQl: graphQl, warmer: warmer);

        await cubit.getImages('main');

        expect(cubit.state, const SplashData());
        expect(warmer.calls, [_folderUrls]);
        await cubit.close();

        when(() => graphQl.getAllLores()).thenAnswer((_) async => lores);
        final failing = RecordingImageWarmer(throwFromCall: 2);
        final second = SplashCubit(rest, graphQl: graphQl, warmer: failing);

        await second.getImages('main');

        expect(second.state, const SplashData());
        expect(failing.calls.length, 2);
        await second.close();
      },
    );

    test('an empty folder still reads as the error state (D-22)', () async {
      when(
        () => rest.fetchCloudinarySubfoldersUrls('main'),
      ).thenAnswer((_) async => const <String>[]);
      final cubit = SplashCubit(rest, graphQl: graphQl, warmer: warmer);

      await cubit.getImages('main');

      expect(cubit.state, const SplashError('No images'));
      expect(warmer.calls, isEmpty);
      verifyNever(() => graphQl.getAllLores());
      await cubit.close();
    });
  });
}
