import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/push_device_failure.dart';
import 'package:klimmeck_guide/repository/push_device_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

OperationException _graphqlCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

final OperationException _connectionError = OperationException(
  linkException: ServerException(
    originalException: const SocketException('offline'),
  ),
);

Matcher _failsWith(PushDeviceFailure failure) => throwsA(
  isA<PushDeviceException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  late MockKlimmeckGraphQl graphQl;
  late PushDeviceRepository repository;

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    repository = PushDeviceRepository(graphQl: graphQl);
  });

  group('register', () {
    void stubRegister(Future<void> Function() answer) => when(
      () => graphQl.registerPushDevice(
        deviceId: any(named: 'deviceId'),
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) => answer());

    test('registers the device as android once', () async {
      stubRegister(() async {});

      await repository.register(deviceId: 'd-1', token: 't-1');

      verify(
        () => graphQl.registerPushDevice(
          deviceId: 'd-1',
          token: 't-1',
          platform: 'android',
        ),
      ).called(1);
    });

    test('maps PUSH_INVALID_DEVICE_ID to invalidDeviceId', () {
      stubRegister(() => throw _graphqlCode('PUSH_INVALID_DEVICE_ID'));

      expect(
        repository.register(deviceId: 'd-1', token: 't-1'),
        _failsWith(PushDeviceFailure.invalidDeviceId),
      );
    });

    test('maps a FormatException to unknown', () {
      stubRegister(() => throw const FormatException());

      expect(
        repository.register(deviceId: 'd-1', token: 't-1'),
        _failsWith(PushDeviceFailure.unknown),
      );
    });

    test('maps a socket link error to connection', () {
      stubRegister(() => throw _connectionError);

      expect(
        repository.register(deviceId: 'd-1', token: 't-1'),
        _failsWith(PushDeviceFailure.connection),
      );
    });
  });

  group('unregister', () {
    test('unregisters the device once', () async {
      when(() => graphQl.unregisterPushDevice(any())).thenAnswer((_) async {});

      await repository.unregister('d-1');

      verify(() => graphQl.unregisterPushDevice('d-1')).called(1);
    });

    test('maps UNAUTHENTICATED to unauthenticated', () {
      when(
        () => graphQl.unregisterPushDevice(any()),
      ).thenThrow(_graphqlCode('UNAUTHENTICATED'));

      expect(
        repository.unregister('d-1'),
        _failsWith(PushDeviceFailure.unauthenticated),
      );
    });

    test('maps a socket link error to connection', () {
      when(
        () => graphQl.unregisterPushDevice(any()),
      ).thenThrow(_connectionError);

      expect(
        repository.unregister('d-1'),
        _failsWith(PushDeviceFailure.connection),
      );
    });
  });
}
