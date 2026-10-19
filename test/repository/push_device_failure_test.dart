import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/push_device_failure.dart';

OperationException _withCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  group('pushDeviceFailureFrom', () {
    final byCode = {
      'PUSH_INVALID_DEVICE_ID': PushDeviceFailure.invalidDeviceId,
      'PUSH_INVALID_TOKEN': PushDeviceFailure.invalidToken,
      'UNAUTHENTICATED': PushDeviceFailure.unauthenticated,
      'PUSH_DISABLED': PushDeviceFailure.unknown,
      'SOMETHING_ELSE': PushDeviceFailure.unknown,
    };
    byCode.forEach((code, failure) {
      test('maps $code to ${failure.name}', () {
        expect(pushDeviceFailureFrom(_withCode(code)), failure);
      });
    });

    test('maps a link error without code to connection', () {
      final exception = OperationException(
        linkException: ServerException(
          originalException: const SocketException('x'),
        ),
      );

      expect(pushDeviceFailureFrom(exception), PushDeviceFailure.connection);
    });

    test('maps no code and no link error to unknown', () {
      expect(
        pushDeviceFailureFrom(OperationException()),
        PushDeviceFailure.unknown,
      );
    });

    test('ignores the server message text', () {
      final exception = OperationException(
        graphqlErrors: [GraphQLError(message: 'PUSH_INVALID_TOKEN')],
      );

      expect(pushDeviceFailureFrom(exception), PushDeviceFailure.unknown);
    });
  });

  group('isRetryable', () {
    const retryable = {PushDeviceFailure.connection, PushDeviceFailure.unknown};

    for (final failure in PushDeviceFailure.values) {
      test('is ${retryable.contains(failure)} for ${failure.name}', () {
        expect(failure.isRetryable, retryable.contains(failure));
      });
    }
  });

  group('PushDeviceException', () {
    test('prints only the failure name', () {
      expect(
        const PushDeviceException(PushDeviceFailure.invalidToken).toString(),
        'PushDeviceException(invalidToken)',
      );
    });
  });
}
