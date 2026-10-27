import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/repository/quest_result_failure.dart';
import 'package:klimmeck_guide/repository/quest_result_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures/quest_result_fixtures.dart';
import '../helpers/mocks.dart';

Matcher _failsWith(QuestResultFailure failure) => throwsA(
  isA<QuestResultException>().having((e) => e.failure, 'failure', failure),
);

OperationException _coded(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  late MockKlimmeckGraphQl graphQl;
  late QuestResultRepository repository;

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    repository = QuestResultRepository(graphQl: graphQl);
  });

  test('times out after 15 seconds by default', () {
    expect(QuestResultRepository.defaultTimeout, const Duration(seconds: 15));
  });

  group('fetch', () {
    test('returns the result read by id', () async {
      final result = questResult(successResultJson());
      when(
        () => graphQl.getQuestResult('result-1'),
      ).thenAnswer((_) async => result);

      expect(await repository.fetch('result-1'), result);
    });

    final byCode = {
      'NOT_FOUND': QuestResultFailure.notFound,
      'FORBIDDEN': QuestResultFailure.forbidden,
      'UNAUTHENTICATED': QuestResultFailure.unauthenticated,
    };
    byCode.forEach((code, failure) {
      test('maps $code to ${failure.name}', () async {
        when(() => graphQl.getQuestResult(any())).thenThrow(_coded(code));

        await expectLater(repository.fetch('result-1'), _failsWith(failure));
      });
    });

    test('maps a FormatException to malformed', () async {
      when(
        () => graphQl.getQuestResult(any()),
      ).thenThrow(const FormatException('questResult malformed'));

      await expectLater(
        repository.fetch('result-1'),
        _failsWith(QuestResultFailure.malformed),
      );
    });

    test('maps any other error to unknown', () async {
      when(() => graphQl.getQuestResult(any())).thenThrow(StateError('boom'));

      await expectLater(
        repository.fetch('result-1'),
        _failsWith(QuestResultFailure.unknown),
      );
    });

    test('fails as timedOut after 15 seconds without an answer', () {
      fakeAsync((async) {
        when(
          () => graphQl.getQuestResult(any()),
        ).thenAnswer((_) => Completer<QuestResult>().future);
        Object? failure;

        repository
            .fetch('result-1')
            .then<void>((_) {}, onError: (Object error) => failure = error);
        async.elapse(const Duration(seconds: 14));
        expect(failure, isNull);
        async.elapse(const Duration(seconds: 1));

        expect(
          failure,
          isA<QuestResultException>().having(
            (e) => e.failure,
            'failure',
            QuestResultFailure.timedOut,
          ),
        );
      });
    });
  });

  test('watch exposes the service stream unchanged', () {
    final stream = Stream<QuestResult>.value(questResult(successResultJson()));
    when(
      () => graphQl.subscribeToQuestResults('c-1'),
    ).thenAnswer((_) => stream);

    expect(repository.watch('c-1'), same(stream));
  });
}
