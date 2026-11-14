import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

import '../../../helpers/fixtures/sync_event_fixtures.dart';
import '../../../helpers/fixtures/travel_fixtures.dart';
import 'graphql_sync_test.dart' show operationNameOf;

List<String> _idsOf(List<PointOfInterest> places) =>
    places.map((place) => place.id).toList();

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

  group('getPointsOfInterest', () {
    test('sends ListPointsOfInterest and parses every place (D-29)', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'pointOfInterests': [
            pointOfInterestJson(id: 'poi-talmvere-marker', types: ['city']),
            pointOfInterestJson(),
            pointOfInterestJson(id: 'poi-cave-1', types: ['cave']),
          ],
        }),
      );

      final places = await buildGraphQl().getPointsOfInterest();

      expect(operationNameOf(requests.single), 'ListPointsOfInterest');
      expect(requests.single.variables, isEmpty);
      expect(_idsOf(places), [
        'poi-talmvere-marker',
        'poi-ruins-1',
        'poi-cave-1',
      ]);
    });

    test('a malformed place is dropped, the others stay (Pitfall 8)', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'pointOfInterests': [
            pointOfInterestJson(),
            {...pointOfInterestJson(id: 'poi-broken'), 'location': 'x'},
            'not a place',
            pointOfInterestJson(id: 'poi-cave-1', types: ['cave']),
          ],
        }),
      );

      expect(_idsOf(await buildGraphQl().getPointsOfInterest()), [
        'poi-ruins-1',
        'poi-cave-1',
      ]);
    });

    test('a missing list is a FormatException', () async {
      handler = (_) => Stream.value(dataResponse({'pointOfInterests': null}));

      await expectLater(
        buildGraphQl().getPointsOfInterest(),
        throwsFormatException,
      );
    });

    test('an error keeps the OperationException code', () async {
      handler = (_) => Stream.value(errorCodeResponse('FORBIDDEN'));

      await expectLater(
        buildGraphQl().getPointsOfInterest(),
        throwsA(
          isA<OperationException>().having(
            graphQlErrorCode,
            'code',
            'FORBIDDEN',
          ),
        ),
      );
    });
  });
}
