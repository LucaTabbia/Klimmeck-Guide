import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/travel_request.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

import '../../../helpers/fixtures/sync_event_fixtures.dart';
import '../../../helpers/fixtures/travel_fixtures.dart';

void main() {
  late List<Request> requests;
  late Stream<Response> Function(Request request) handler;

  const request = TravelRequest(id: 'c-1', poiId: 'city-marker-2');
  const requestVariables = {
    'request': {'id': 'c-1', 'poiId': 'city-marker-2'},
  };

  KlimmeckGraphQl buildGraphQl() => KlimmeckGraphQl(
    resolveClient: () => GraphQLClient(
      link: Link.function((incoming, [forward]) {
        requests.add(incoming);
        return handler(incoming);
      }),
      cache: GraphQLCache(store: InMemoryStore()),
    ),
  );

  String? operationNameOf(Request sent) => sent.operation.document.definitions
      .whereType<OperationDefinitionNode>()
      .first
      .name
      ?.value;

  Matcher throwsOperationCoded(String code) =>
      throwsA(isA<OperationException>().having(graphQlErrorCode, 'code', code));

  setUp(() {
    requests = [];
    handler = (_) => Stream.value(dataResponse({}));
  });

  group('getServerTime', () {
    test('sends GetServerTime and parses the server time', () async {
      handler = (_) => Stream.value(
        dataResponse({'serverTime': '2026-10-24T10:00:00.000Z'}),
      );

      final serverTime = await buildGraphQl().getServerTime();

      expect(operationNameOf(requests.single), 'GetServerTime');
      expect(serverTime, DateTime.parse('2026-10-24T10:00:00.000Z'));
    });

    test('throws FormatException when serverTime is missing', () async {
      handler = (_) => Stream.value(dataResponse({'serverTime': null}));

      await expectLater(buildGraphQl().getServerTime(), throwsFormatException);
    });

    test('throws FormatException when serverTime is not a string', () async {
      handler = (_) => Stream.value(dataResponse({'serverTime': 42}));

      await expectLater(buildGraphQl().getServerTime(), throwsFormatException);
    });

    test('throws the raw OperationException keeping the error code', () async {
      handler = (_) => Stream.value(errorCodeResponse('UNAUTHENTICATED'));

      await expectLater(
        buildGraphQl().getServerTime(),
        throwsOperationCoded('UNAUTHENTICATED'),
      );
    });
  });

  group('previewTravel', () {
    test('sends GetTravelPreview with the request variable', () async {
      handler = (_) =>
          Stream.value(dataResponse({'travelPreview': travelPreviewJson()}));

      await buildGraphQl().previewTravel(request);

      expect(operationNameOf(requests.single), 'GetTravelPreview');
      expect(requests.single.variables, requestVariables);
    });

    test('returns the parsed preview', () async {
      handler = (_) =>
          Stream.value(dataResponse({'travelPreview': travelPreviewJson()}));

      final preview = await buildGraphQl().previewTravel(request);

      expect(preview, TravelPreview.fromJson(travelPreviewJson()));
    });

    test('never reuses a cached answer', () async {
      handler = (_) =>
          Stream.value(dataResponse({'travelPreview': travelPreviewJson()}));
      final graphQl = buildGraphQl();

      await graphQl.previewTravel(request);
      await graphQl.previewTravel(request);

      expect(requests, hasLength(2));
    });

    test('throws FormatException when the preview is missing', () async {
      handler = (_) => Stream.value(dataResponse({'travelPreview': null}));

      await expectLater(
        buildGraphQl().previewTravel(request),
        throwsFormatException,
      );
    });

    test('throws FormatException when the preview is malformed', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'travelPreview': {'distance': 'x'},
        }),
      );

      await expectLater(
        buildGraphQl().previewTravel(request),
        throwsFormatException,
      );
    });

    test('throws the raw OperationException keeping the error code', () async {
      handler = (_) => Stream.value(errorCodeResponse('TRAVEL_NO_PATH'));

      await expectLater(
        buildGraphQl().previewTravel(request),
        throwsOperationCoded('TRAVEL_NO_PATH'),
      );
    });
  });

  group('startTravel', () {
    test('sends StartTravel with the request variable', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'startTravel': {'response': 'Viaggio iniziato', 'successful': true},
        }),
      );

      await buildGraphQl().startTravel(request);

      expect(operationNameOf(requests.single), 'StartTravel');
      expect(requests.single.variables, requestVariables);
    });

    test('completes when the backend answers successful', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'startTravel': {'response': 'Viaggio iniziato', 'successful': true},
        }),
      );

      expect(await buildGraphQl().startTravel(request), isTrue);
    });

    test('returns false when the backend answers unsuccessful', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'startTravel': {'response': 'x', 'successful': false},
        }),
      );

      expect(await buildGraphQl().startTravel(request), isFalse);
    });

    test('throws FormatException when successful is missing', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'startTravel': {'response': 'x'},
        }),
      );

      await expectLater(
        buildGraphQl().startTravel(request),
        throwsFormatException,
      );
    });

    test('throws FormatException when the payload is missing', () async {
      handler = (_) => Stream.value(dataResponse({'startTravel': null}));

      await expectLater(
        buildGraphQl().startTravel(request),
        throwsFormatException,
      );
    });

    test('throws the raw OperationException keeping the error code', () async {
      handler = (_) => Stream.value(errorCodeResponse('TRAVEL_IN_PROGRESS'));

      await expectLater(
        buildGraphQl().startTravel(request),
        throwsOperationCoded('TRAVEL_IN_PROGRESS'),
      );
    });
  });
}
