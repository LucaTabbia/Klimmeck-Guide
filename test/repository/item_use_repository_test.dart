import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/use_item_result.dart';
import 'package:klimmeck_guide/repository/item_use_failure.dart';
import 'package:klimmeck_guide/repository/item_use_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures/potion_fixtures.dart';
import '../helpers/mocks.dart';

Matcher _failsWith(ItemUseFailure failure) => throwsA(
  isA<ItemUseException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  late MockKlimmeckGraphQl graphQl;
  late ItemUseRepository repository;

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    repository = ItemUseRepository(graphQl: graphQl);
  });

  test('returns the result of useItem for the item id (D-11)', () async {
    final result = UseItemResult.fromJson(useItemResultJson());
    when(() => graphQl.useItem(any())).thenAnswer((_) async => result);

    expect(await repository.useItem('l-herb'), result);
    verify(() => graphQl.useItem('l-herb')).called(1);
  });

  test(
    'maps a refusal to ItemUseException with its date (D-11, D-19)',
    () async {
      when(() => graphQl.useItem(any())).thenThrow(
        OperationException(
          graphqlErrors: [
            GraphQLError(
              message: 'server text',
              extensions: {
                'code': 'POTION_RECOVERING',
                'recoveryUntil': '2026-10-27T10:30:00.000Z',
              },
            ),
          ],
        ),
      );

      await expectLater(
        repository.useItem('l-herb'),
        throwsA(
          isA<ItemUseException>()
              .having(
                (e) => e.failure,
                'failure',
                ItemUseFailure.potionRecovering,
              )
              .having(
                (e) => e.recoveryUntil,
                'recoveryUntil',
                DateTime.utc(2026, 10, 27, 10, 30),
              ),
        ),
      );
    },
  );

  test('a timeout is timedOut (D-19)', () async {
    final completer = Completer<UseItemResult>();
    when(() => graphQl.useItem(any())).thenAnswer((_) => completer.future);
    final bounded = ItemUseRepository(
      graphQl: graphQl,
      timeout: const Duration(milliseconds: 20),
    );

    await expectLater(
      bounded.useItem('l-herb'),
      _failsWith(ItemUseFailure.timedOut),
    );
  });

  test('the default timeout is 15 seconds', () {
    expect(ItemUseRepository.defaultTimeout, const Duration(seconds: 15));
  });

  test('any other error is unknown (D-11)', () async {
    when(() => graphQl.useItem(any())).thenThrow(const FormatException('bad'));

    await expectLater(
      repository.useItem('l-herb'),
      _failsWith(ItemUseFailure.unknown),
    );
  });
}
