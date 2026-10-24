import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/travel_request.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_gate.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_port.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart';
import 'package:klimmeck_guide/repository/travel_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes/fake_notification_permission_port.dart';
import '../helpers/fixtures/travel_fixtures.dart';
import '../helpers/mocks.dart';

Matcher _failsWith(TravelFailure failure) => throwsA(
  isA<TravelException>().having((e) => e.failure, 'failure', failure),
);

OperationException _coded(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

/// Porta il cui stato non arriva mai: il chiamante di `start` non deve attenderla.
class _HangingPermissionPort implements NotificationPermissionPort {
  int statusCalls = 0;

  @override
  Future<NotificationPermissionStatus> status() {
    statusCalls++;
    return Completer<NotificationPermissionStatus>().future;
  }

  @override
  Future<NotificationPermissionStatus> request() =>
      Completer<NotificationPermissionStatus>().future;

  @override
  Future<void> openSettings() async {}
}

void main() {
  const request = TravelRequest(id: 'c-1', poiId: 'city-marker-2');
  final preview = TravelPreview.fromJson(travelPreviewJson());

  late MockKlimmeckGraphQl graphQl;
  late FakeNotificationPermissionPort port;
  late TravelRepository repository;

  TravelRepository buildRepository(NotificationPermissionPort permission) =>
      TravelRepository(
        graphQl: graphQl,
        permissionGate: NotificationPermissionGate(permission),
      );

  setUpAll(() {
    registerFallbackValue(const TravelRequest(id: 'c', poiId: 'p'));
  });

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    port = FakeNotificationPermissionPort();
    repository = buildRepository(port);
  });

  test('the default timeout is 15 seconds', () {
    expect(TravelRepository.defaultTimeout, const Duration(seconds: 15));
  });

  group('preview', () {
    test(
      'sends the character and marker ids and returns the preview',
      () async {
        when(
          () => graphQl.previewTravel(any()),
        ).thenAnswer((_) async => preview);

        final result = await repository.preview(
          characterId: 'c-1',
          poiId: 'city-marker-2',
        );

        expect(result, preview);
        verify(() => graphQl.previewTravel(request)).called(1);
      },
    );

    test('maps an OperationException by its code', () async {
      when(
        () => graphQl.previewTravel(any()),
      ).thenThrow(_coded('TRAVEL_NO_PATH'));

      await expectLater(
        repository.preview(characterId: 'c-1', poiId: 'city-marker-2'),
        _failsWith(TravelFailure.noPath),
      );
    });

    test('maps a link error to connection', () async {
      when(
        () => graphQl.previewTravel(any()),
      ).thenThrow(OperationException(linkException: const ServerException()));

      await expectLater(
        repository.preview(characterId: 'c-1', poiId: 'city-marker-2'),
        _failsWith(TravelFailure.connection),
      );
    });

    test('maps a FormatException to unknown', () async {
      when(
        () => graphQl.previewTravel(any()),
      ).thenThrow(const FormatException('travelPreview malformed'));

      await expectLater(
        repository.preview(characterId: 'c-1', poiId: 'city-marker-2'),
        _failsWith(TravelFailure.unknown),
      );
    });

    test('fails as timedOut after 15 seconds without an answer', () {
      fakeAsync((async) {
        when(
          () => graphQl.previewTravel(any()),
        ).thenAnswer((_) => Completer<TravelPreview>().future);
        Object? failure;

        repository
            .preview(characterId: 'c-1', poiId: 'city-marker-2')
            .then<void>((_) {}, onError: (Object error) => failure = error);
        async.elapse(const Duration(seconds: 14));
        expect(failure, isNull);
        async.elapse(const Duration(seconds: 1));

        expect(
          failure,
          isA<TravelException>().having(
            (e) => e.failure,
            'failure',
            TravelFailure.timedOut,
          ),
        );
      });
    });

    test('never asks the notification permission', () async {
      when(() => graphQl.previewTravel(any())).thenAnswer((_) async => preview);

      await repository.preview(characterId: 'c-1', poiId: 'city-marker-2');
      await pumpEventQueue();

      expect(port.statusCalls, 0);
      expect(port.requestCalls, 0);
    });
  });

  group('start', () {
    test('sends the character and marker ids to the service', () async {
      when(() => graphQl.startTravel(any())).thenAnswer((_) async {});

      await repository.start(characterId: 'c-1', poiId: 'city-marker-2');

      verify(() => graphQl.startTravel(request)).called(1);
    });

    test(
      'asks the permission once, only after the mutation completed',
      () async {
        final mutation = Completer<void>();
        when(
          () => graphQl.startTravel(any()),
        ).thenAnswer((_) => mutation.future);

        final started = repository.start(
          characterId: 'c-1',
          poiId: 'city-marker-2',
        );
        await pumpEventQueue();
        expect(port.statusCalls, 0);

        mutation.complete();
        await started;
        await pumpEventQueue();

        expect(port.statusCalls, 1);
        expect(port.requestCalls, 1);
      },
    );

    test('does not prompt when the system already decided', () async {
      port.current = NotificationPermissionStatus.denied;
      when(() => graphQl.startTravel(any())).thenAnswer((_) async {});

      await repository.start(characterId: 'c-1', poiId: 'city-marker-2');
      await pumpEventQueue();

      expect(port.statusCalls, 1);
      expect(port.requestCalls, 0);
    });

    test(
      'a travel already in progress fails as inProgress, no prompt',
      () async {
        when(
          () => graphQl.startTravel(any()),
        ).thenThrow(_coded('TRAVEL_IN_PROGRESS'));

        await expectLater(
          repository.start(characterId: 'c-1', poiId: 'city-marker-2'),
          _failsWith(TravelFailure.inProgress),
        );
        await pumpEventQueue();

        expect(port.statusCalls, 0);
      },
    );

    test('a quest in progress fails as questInProgress, no prompt', () async {
      when(
        () => graphQl.startTravel(any()),
      ).thenThrow(_coded('QUEST_IN_PROGRESS'));

      await expectLater(
        repository.start(characterId: 'c-1', poiId: 'city-marker-2'),
        _failsWith(TravelFailure.questInProgress),
      );
      await pumpEventQueue();

      expect(port.statusCalls, 0);
    });

    test('an unsuccessful answer fails as unknown, no prompt', () async {
      when(
        () => graphQl.startTravel(any()),
      ).thenThrow(const FormatException('startTravel not successful'));

      await expectLater(
        repository.start(characterId: 'c-1', poiId: 'city-marker-2'),
        _failsWith(TravelFailure.unknown),
      );
      await pumpEventQueue();

      expect(port.statusCalls, 0);
    });

    test('a failing permission gate does not make start throw', () async {
      port.statusFailure = Exception('x');
      when(() => graphQl.startTravel(any())).thenAnswer((_) async {});

      await expectLater(
        repository.start(characterId: 'c-1', poiId: 'city-marker-2'),
        completes,
      );
      await pumpEventQueue();

      expect(port.statusCalls, 1);
    });

    test('completes even if the permission gate never answers', () async {
      final hanging = _HangingPermissionPort();
      when(() => graphQl.startTravel(any())).thenAnswer((_) async {});

      await expectLater(
        buildRepository(
          hanging,
        ).start(characterId: 'c-1', poiId: 'city-marker-2'),
        completes,
      );

      expect(hanging.statusCalls, 1);
    });

    test('fails as timedOut after 15 seconds, no prompt', () {
      fakeAsync((async) {
        when(
          () => graphQl.startTravel(any()),
        ).thenAnswer((_) => Completer<void>().future);
        Object? failure;

        repository
            .start(characterId: 'c-1', poiId: 'city-marker-2')
            .then<void>((_) {}, onError: (Object error) => failure = error);
        async.elapse(const Duration(seconds: 15));
        async.flushMicrotasks();

        expect(
          failure,
          isA<TravelException>().having(
            (e) => e.failure,
            'failure',
            TravelFailure.timedOut,
          ),
        );
        expect(port.statusCalls, 0);
      });
    });
  });
}
