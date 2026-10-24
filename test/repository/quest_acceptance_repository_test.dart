import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/accept_quest_request.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

Matcher _failsWith(QuestAcceptanceFailure failure) => throwsA(
  isA<QuestAcceptanceException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  late MockKlimmeckGraphQl graphQl;
  late QuestAcceptanceRepository repository;

  setUpAll(() {
    registerFallbackValue(const AcceptQuestRequest(id: 'c', questId: 'q'));
  });

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    repository = QuestAcceptanceRepository(graphQl: graphQl);
  });

  group('accept', () {
    test('sends the character and quest ids to the service', () async {
      when(() => graphQl.acceptQuest(any())).thenAnswer((_) async {});

      await repository.accept(characterId: 'c-1', questId: 'q-1');

      verify(
        () => graphQl.acceptQuest(
          const AcceptQuestRequest(id: 'c-1', questId: 'q-1'),
        ),
      ).called(1);
    });

    test(
      'a service call that never answers fails as timedOut after the timeout',
      () async {
        // UAT 2026-10-22: con Redis spento il BE non rispondeva e il client
        // restava appeso ~100 s; il repository deve chiudere da solo. Non è
        // `connection`: la richiesta non viene annullata e il BE può ancora
        // accettare la quest dopo la scadenza (WR-01).
        final completer = Completer<void>();
        when(
          () => graphQl.acceptQuest(any()),
        ).thenAnswer((_) => completer.future);
        final bounded = QuestAcceptanceRepository(
          graphQl: graphQl,
          timeout: const Duration(milliseconds: 20),
        );

        await expectLater(
          bounded.accept(characterId: 'c-1', questId: 'q-1'),
          _failsWith(QuestAcceptanceFailure.timedOut),
        );
      },
    );

    test('the default timeout is 15 seconds', () {
      expect(
        QuestAcceptanceRepository.defaultTimeout,
        const Duration(seconds: 15),
      );
    });

    test('maps an OperationException by its code', () async {
      when(() => graphQl.acceptQuest(any())).thenThrow(
        OperationException(
          graphqlErrors: [
            GraphQLError(
              message: 'server text',
              extensions: {'code': 'QUEST_FULL'},
            ),
          ],
        ),
      );

      await expectLater(
        repository.accept(characterId: 'c-1', questId: 'q-1'),
        _failsWith(QuestAcceptanceFailure.full),
      );
    });

    test('maps a FormatException to unknown', () async {
      when(
        () => graphQl.acceptQuest(any()),
      ).thenThrow(const FormatException('bad'));

      await expectLater(
        repository.accept(characterId: 'c-1', questId: 'q-1'),
        _failsWith(QuestAcceptanceFailure.unknown),
      );
    });

    test('maps any other error to unknown', () async {
      // graphql.md: il repository incapsula ogni errore, non solo i tre
      // tipi previsti; il catch-all del Cubit resta una rete di sicurezza.
      when(() => graphQl.acceptQuest(any())).thenThrow(StateError('bad'));

      await expectLater(
        repository.accept(characterId: 'c-1', questId: 'q-1'),
        _failsWith(QuestAcceptanceFailure.unknown),
      );
    });
  });
}
