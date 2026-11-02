import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/city_shop.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fixtures/shop_fixtures.dart';
import '../../../../../helpers/mocks.dart';

CityShop _poolOf(String cityId) =>
    CityShop.fromJson(cityShopJson(cityId: cityId));

void main() {
  late MockKlimmeckGraphQl graphQl;

  setUp(() => graphQl = MockKlimmeckGraphQl());

  group('getData', () {
    blocTest<ShopCubit, ShopState>(
      'getData(cityId) emits loading then the pool of that city (D-01)',
      setUp: () => when(
        () => graphQl.getCityShop('city-a'),
      ).thenAnswer((_) async => _poolOf('city-a')),
      build: () => ShopCubit(graphQl),
      act: (cubit) => cubit.getData('city-a'),
      expect: () => [
        const ShopLoading('city-a'),
        ShopLoadData(_poolOf('city-a')),
      ],
      verify: (_) => verify(() => graphQl.getCityShop('city-a')).called(1),
    );

    blocTest<ShopCubit, ShopState>(
      'a failure emits ShopError with the city id and no raw text',
      setUp: () => when(
        () => graphQl.getCityShop('city-a'),
      ).thenThrow(Exception('server text')),
      build: () => ShopCubit(graphQl),
      act: (cubit) => cubit.getData('city-a'),
      expect: () => [const ShopLoading('city-a'), const ShopError('city-a')],
      verify: (cubit) =>
          expect(cubit.state.props, isNot(contains(contains('server text')))),
    );

    test(
      'drops the response of a superseded city (D-03 last-request-wins)',
      () async {
        final poolA = Completer<CityShop>();
        final poolB = Completer<CityShop>();
        when(
          () => graphQl.getCityShop('city-a'),
        ).thenAnswer((_) => poolA.future);
        when(
          () => graphQl.getCityShop('city-b'),
        ).thenAnswer((_) => poolB.future);
        final cubit = ShopCubit(graphQl);
        final states = <ShopState>[];
        final subscription = cubit.stream.listen(states.add);

        final loadA = cubit.getData('city-a');
        final loadB = cubit.getData('city-b');
        poolB.complete(_poolOf('city-b'));
        await loadB;
        poolA.complete(_poolOf('city-a'));
        await loadA;
        await subscription.cancel();
        await cubit.close();

        expect(states.last, ShopLoadData(_poolOf('city-b')));
        expect(states, isNot(contains(ShopLoadData(_poolOf('city-a')))));
      },
    );

    test('drops the failure of a superseded city (D-03)', () async {
      final poolA = Completer<CityShop>();
      when(() => graphQl.getCityShop('city-a')).thenAnswer((_) => poolA.future);
      when(
        () => graphQl.getCityShop('city-b'),
      ).thenAnswer((_) async => _poolOf('city-b'));
      final cubit = ShopCubit(graphQl);
      final states = <ShopState>[];
      final subscription = cubit.stream.listen(states.add);

      final loadA = cubit.getData('city-a');
      await cubit.getData('city-b');
      poolA.completeError(Exception('late failure'));
      await loadA;
      await subscription.cancel();
      await cubit.close();

      expect(states.last, ShopLoadData(_poolOf('city-b')));
      expect(states, isNot(contains(const ShopError('city-a'))));
    });
  });

  test('ShopLoadData exposes the city id of its pool', () {
    expect(ShopLoadData(_poolOf('city-a')).cityId, 'city-a');
  });
}
