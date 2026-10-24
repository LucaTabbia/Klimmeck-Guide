import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

import '../../../helpers/fixtures/quest_fixtures.dart';
import '../../../helpers/fixtures/sync_event_fixtures.dart';
import 'graphql_character_deletion_test.dart' show operationNameOf;

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
    handler = (_) => Stream.value(dataResponse({}));
  });

  group('getCityPointIds', () {
    test('sends GetCity with the city id as a variable', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'city': {
            'id': 'city-1',
            'markerLocation': {'id': 'm-1'},
          },
        }),
      );

      await buildGraphQl().getCityPointIds('city-1');

      expect(operationNameOf(requests.single), 'GetCity');
      expect(requests.single.variables, {'id': 'city-1'});
    });

    test('returns the marker and every POI id', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'city': {
            'id': 'city-1',
            'markerLocation': {'id': 'm-1'},
            'pointsOfInterest': [
              {'id': 'p-1'},
              {'id': 'p-2'},
            ],
          },
        }),
      );

      expect(await buildGraphQl().getCityPointIds('city-1'), {
        'm-1',
        'p-1',
        'p-2',
      });
    });

    test('a null POI list leaves only the marker', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'city': {
            'id': 'city-1',
            'markerLocation': {'id': 'm-1'},
            'pointsOfInterest': null,
          },
        }),
      );

      expect(await buildGraphQl().getCityPointIds('city-1'), {'m-1'});
    });

    test('throws the OperationException on NOT_FOUND', () async {
      handler = (_) => Stream.value(errorCodeResponse('NOT_FOUND'));

      await expectLater(
        buildGraphQl().getCityPointIds('city-1'),
        throwsA(isA<OperationException>()),
      );
    });

    test('throws a FormatException on a null city', () async {
      handler = (_) => Stream.value(dataResponse({'city': null}));

      await expectLater(
        buildGraphQl().getCityPointIds('city-1'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('getQuests', () {
    test('keeps valid quests and skips the malformed one', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'quests': [
            questJson(id: 'a'),
            questJson(id: 'b', type: 'treasure'),
            legacyQuestJson(id: 'c'),
          ],
        }),
      );

      final quests = await buildGraphQl().getQuests();

      expect(quests.map((q) => q.id), ['a', 'c']);
    });

    test('still throws on an error response', () async {
      handler = (_) => Stream.value(errorCodeResponse('UNAUTHENTICATED'));

      await expectLater(buildGraphQl().getQuests(), throwsA(isA<Exception>()));
    });
  });
}
