import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/abandon_quest_request.dart';
import 'package:klimmeck_guide/repository/quest_abandon_failure.dart';
import 'package:klimmeck_guide/repository/quest_abandon_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

Matcher _failsWith(QuestAbandonFailure failure) => throwsA(
  isA<QuestAbandonException>().having((e) => e.failure, 'failure', failure),
);

OperationException _withCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  late MockKlimmeckGraphQl graphQl;
  late QuestAbandonRepository repository;

  setUpAll(() {
    registerFallbackValue(const AbandonQuestRequest(id: 'c', questId: 'q'));
  });

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    repository = QuestAbandonRepository(graphQl: graphQl);
  });

  Future<void> abandon() =>
      repository.abandon(characterId: 'c-1', questId: 'q-1');

  test('sends the character and quest ids to the service', () async {
    when(() => graphQl.abandonQuest(any())).thenAnswer((_) async {});

    await abandon();

    verify(
      () => graphQl.abandonQuest(
        const AbandonQuestRequest(id: 'c-1', questId: 'q-1'),
      ),
    ).called(1);
  });

  final byCode = {
    'QUEST_NOT_WAITING': QuestAbandonFailure.notWaiting,
    'NOT_FOUND': QuestAbandonFailure.notFound,
    'FORBIDDEN': QuestAbandonFailure.forbidden,
  };
  byCode.forEach((code, failure) {
    test('maps $code to ${failure.name}', () async {
      when(() => graphQl.abandonQuest(any())).thenThrow(_withCode(code));

      await expectLater(abandon(), _failsWith(failure));
    });
  });

  test('maps a link error to connection', () async {
    when(() => graphQl.abandonQuest(any())).thenThrow(
      OperationException(
        linkException: ServerException(
          originalException: const SocketException('x'),
        ),
      ),
    );

    await expectLater(abandon(), _failsWith(QuestAbandonFailure.connection));
  });

  test('a call that never answers fails as timedOut', () async {
    final completer = Completer<void>();
    when(() => graphQl.abandonQuest(any())).thenAnswer((_) => completer.future);
    final bounded = QuestAbandonRepository(
      graphQl: graphQl,
      timeout: const Duration(milliseconds: 20),
    );

    await expectLater(
      bounded.abandon(characterId: 'c-1', questId: 'q-1'),
      _failsWith(QuestAbandonFailure.timedOut),
    );
  });

  test('the default timeout is 15 seconds', () {
    expect(QuestAbandonRepository.defaultTimeout, const Duration(seconds: 15));
  });

  test('maps any other error to unknown', () async {
    when(
      () => graphQl.abandonQuest(any()),
    ).thenThrow(const FormatException('bad'));

    await expectLater(abandon(), _failsWith(QuestAbandonFailure.unknown));
  });
}
