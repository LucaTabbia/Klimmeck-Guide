import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';

import '../../../helpers/fixtures/quest_fixtures.dart';
import '../../../helpers/fixtures/sync_event_fixtures.dart';
import 'graphql_sync_test.dart' show operationNameOf;

Matcher _streamFailure(String code) => isA<SubscriptionStreamException>()
    .having((e) => e.operation, 'operation', 'questUpdated')
    .having((e) => e.code, 'code', code);

void main() {
  late List<Request> requests;
  late Stream<Response> Function(Request request) handler;

  KlimmeckGraphQl buildGraphQl() => KlimmeckGraphQl(
    resolveClient: () => GraphQLClient(
      link: Link.function((request, [forward]) {
        requests.add(request);
        return handler(request);
      }),
      cache: GraphQLCache(store: InMemoryStore()),
    ),
  );

  setUp(() {
    requests = [];
    handler = (_) => const Stream.empty();
  });

  group('subscribeToQuest', () {
    test(
      'sends OnQuestUpdated with the quest id and emits the quest',
      () async {
        handler = (_) => Stream.value(
          dataResponse({
            'questUpdated': questJson(
              id: 'q-1',
              registered: [
                {'character': 'c-1', 'title': 'rookie'},
              ],
            ),
          }),
        );

        final quest = await buildGraphQl().subscribeToQuest('q-1').first;

        expect(operationNameOf(requests.single), 'OnQuestUpdated');
        expect(requests.single.variables, {'questId': 'q-1'});
        expect(quest.id, 'q-1');
        expect(quest.registeredAdventurers, hasLength(1));
      },
    );

    test('emits the snapshot and every update in order', () async {
      handler = (_) => Stream.fromIterable([
        dataResponse({'questUpdated': questJson(id: 'q-1')}),
        dataResponse({
          'questUpdated': questJson(
            id: 'q-1',
            registered: [
              {'character': 'c-1', 'title': 'rookie'},
              {'character': 'c-2', 'title': 'rookie'},
            ],
          ),
        }),
      ]);

      final counts = await buildGraphQl()
          .subscribeToQuest('q-1')
          .map((quest) => quest.registeredAdventurers.length)
          .toList();

      expect(counts, [0, 2]);
    });

    test('maps NOT_FOUND to a typed error, then completes', () {
      handler = (_) => Stream.value(errorCodeResponse('NOT_FOUND'));

      expect(
        buildGraphQl().subscribeToQuest('q-1'),
        emitsInOrder([emitsError(_streamFailure('NOT_FOUND')), emitsDone]),
      );
    });

    test('turns a missing quest into a FormatException', () {
      handler = (_) => Stream.value(dataResponse({'questUpdated': null}));

      expect(
        buildGraphQl().subscribeToQuest('q-1'),
        emitsInOrder([emitsError(isA<FormatException>()), emitsDone]),
      );
    });
  });
}
