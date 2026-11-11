import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

import '../../../helpers/fixtures/sync_event_fixtures.dart';
import '../../../helpers/fixtures/travel_fixtures.dart';

Map<String, dynamic> _cityJson(String id, {required String type}) => {
  ...travelCityJson(id: id, name: id),
  'type': type,
};

void main() {
  late Stream<Response> Function(Request request) handler;

  KlimmeckGraphQl buildGraphQl() => KlimmeckGraphQl(
    resolveClient: () => GraphQLClient(
      link: Link.function((incoming, [forward]) => handler(incoming)),
      cache: GraphQLCache(store: InMemoryStore()),
    ),
  );

  group('getCities', () {
    test('getCities keeps the cities that parse and drops a city with an '
        'unknown type (D-16)', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'cities': [
            _cityJson('city-1', type: 'drusteaCapital'),
            _cityJson('city-2', type: 'floatingCitadel'),
            _cityJson('city-3', type: 'valanCapital'),
          ],
        }),
      );

      final cities = await buildGraphQl().getCities();

      expect(cities.map((city) => city.id), ['city-1', 'city-3']);
    });

    test('getCities still throws when the list is missing (D-16)', () async {
      handler = (_) => Stream.value(dataResponse({'cities': null}));

      await expectLater(
        buildGraphQl().getCities(),
        throwsA(
          isA<Exception>().having(
            (error) => '$error',
            'message',
            contains('No cities found'),
          ),
        ),
      );
    });
  });
}
