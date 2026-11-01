import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/request/complete_pending_request_input.dart';
import 'package:klimmeck_guide/models/request/travel_request.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures/pending_request_fixtures.dart';
import '../helpers/fixtures/quest_result_fixtures.dart';
import '../helpers/mocks.dart';

Matcher _failsWith(InnkeeperFailure failure) => throwsA(
  isA<InnkeeperException>().having((e) => e.failure, 'failure', failure),
);

OperationException _coded(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  late MockKlimmeckGraphQl graphQl;
  late InnkeeperRepository repository;

  const input = CompletePendingRequestInput(
    pendingQuestId: 'pq-story-1',
    outcomes: [],
  );
  const teleportRequest = TravelRequest(
    id: 'char-bea',
    poiId: 'poi-borgo-marker',
  );

  setUpAll(() {
    registerFallbackValue(input);
    registerFallbackValue(teleportRequest);
  });

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    repository = InnkeeperRepository(graphQl: graphQl);
  });

  test('times out after 15 seconds by default', () {
    expect(InnkeeperRepository.defaultTimeout, const Duration(seconds: 15));
  });

  test('watchQueue exposes the service stream unchanged', () {
    final stream = Stream<List<PendingRequest>>.value(const []);
    when(() => graphQl.subscribeToPendingRequests()).thenAnswer((_) => stream);

    expect(repository.watchQueue(), same(stream));
  });

  group('fetchQueue', () {
    test('passes the queue through', () async {
      final queue = [PendingRequest.fromJson(pendingRequestJson())];
      when(() => graphQl.getPendingRequests()).thenAnswer((_) async => queue);

      expect(await repository.fetchQueue(), queue);
    });

    test('maps FORBIDDEN to forbidden', () async {
      when(() => graphQl.getPendingRequests()).thenThrow(_coded('FORBIDDEN'));

      await expectLater(
        repository.fetchQueue(),
        _failsWith(InnkeeperFailure.forbidden),
      );
    });

    test('maps a FormatException to malformed', () async {
      when(
        () => graphQl.getPendingRequests(),
      ).thenThrow(const FormatException('pendingRequests missing'));

      await expectLater(
        repository.fetchQueue(),
        _failsWith(InnkeeperFailure.malformed),
      );
    });

    test('fails as timedOut after 15 seconds without an answer', () {
      fakeAsync((async) {
        when(
          () => graphQl.getPendingRequests(),
        ).thenAnswer((_) => Completer<List<PendingRequest>>().future);
        Object? failure;

        repository.fetchQueue().then<void>(
          (_) {},
          onError: (Object error) => failure = error,
        );
        async.elapse(const Duration(seconds: 14));
        expect(failure, isNull);
        async.elapse(const Duration(seconds: 1));

        expect(
          failure,
          isA<InnkeeperException>().having(
            (e) => e.failure,
            'failure',
            InnkeeperFailure.timedOut,
          ),
        );
      });
    });
  });

  group('readCharacter', () {
    test('passes the character through', () async {
      final character = Character.fromJson(
        participantCharacterJson(id: 'char-bea', name: 'Bea'),
      );
      when(
        () => graphQl.getCharacter('char-bea'),
      ).thenAnswer((_) async => character);

      expect(await repository.readCharacter('char-bea'), character);
    });

    final byCode = {
      'NOT_FOUND': InnkeeperFailure.notFound,
      'FORBIDDEN': InnkeeperFailure.forbidden,
    };
    byCode.forEach((code, failure) {
      test('maps an access denied $code to ${failure.name}', () async {
        when(() => graphQl.getCharacter(any())).thenThrow(
          GraphQlAccessDeniedException(operation: 'character', code: code),
        );

        await expectLater(
          repository.readCharacter('char-bea'),
          _failsWith(failure),
        );
      });
    });

    test('maps a plain Exception to unknown', () async {
      when(
        () => graphQl.getCharacter(any()),
      ).thenThrow(Exception('character read failed'));

      await expectLater(
        repository.readCharacter('char-bea'),
        _failsWith(InnkeeperFailure.unknown),
      );
    });
  });

  group('complete', () {
    test('sends the input and returns the created results', () async {
      final results = [QuestResult.tryFromJson(gmCompletedResultJson())!];
      when(
        () => graphQl.completePendingRequest(input),
      ).thenAnswer((_) async => results);

      expect(await repository.complete(input), results);
      verify(() => graphQl.completePendingRequest(input)).called(1);
    });

    final byCode = {
      'OUTCOME_OVERRIDE_INVALID': InnkeeperFailure.overrideInvalid,
      'NOT_FOUND': InnkeeperFailure.notFound,
    };
    byCode.forEach((code, failure) {
      test('maps $code to ${failure.name}', () async {
        when(
          () => graphQl.completePendingRequest(any()),
        ).thenThrow(_coded(code));

        await expectLater(repository.complete(input), _failsWith(failure));
      });
    });
  });

  group('teleport', () {
    test('sends the character and the destination', () async {
      when(
        () => graphQl.teleportCharacter(any()),
      ).thenAnswer((_) async => true);

      await repository.teleport(
        characterId: 'char-bea',
        poiId: 'poi-borgo-marker',
      );

      verify(() => graphQl.teleportCharacter(teleportRequest)).called(1);
    });

    test('turns successful false into declined', () async {
      when(
        () => graphQl.teleportCharacter(any()),
      ).thenAnswer((_) async => false);

      await expectLater(
        repository.teleport(characterId: 'char-bea', poiId: 'poi-borgo-marker'),
        _failsWith(InnkeeperFailure.declined),
      );
    });

    test('maps QUEST_IN_PROGRESS to questInProgress', () async {
      when(
        () => graphQl.teleportCharacter(any()),
      ).thenThrow(_coded('QUEST_IN_PROGRESS'));

      await expectLater(
        repository.teleport(characterId: 'char-bea', poiId: 'poi-borgo-marker'),
        _failsWith(InnkeeperFailure.questInProgress),
      );
    });
  });
}
