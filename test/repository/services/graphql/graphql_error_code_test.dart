import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';

OperationException _graphqlError(String? code) => OperationException(
  graphqlErrors: [
    GraphQLError(
      message: 'x',
      extensions: code == null ? null : {'code': code},
    ),
  ],
);

OperationException _subscriptionError(Object? payload) => OperationException(
  linkException: UnknownException(
    SubscriptionError('1', payload),
    StackTrace.empty,
  ),
);

void main() {
  group('graphQlErrorCode', () {
    test('reads the code of a graphql error (backend wire shape)', () {
      expect(graphQlErrorCode(_graphqlError('FORBIDDEN')), 'FORBIDDEN');
    });

    test('reads the code of a subscription error payload (defensive)', () {
      final exception = _subscriptionError([
        {
          'message': 'x',
          'extensions': {'code': 'NOT_FOUND'},
        },
      ]);

      expect(graphQlErrorCode(exception), 'NOT_FOUND');
    });

    test('returns null without exception or without code', () {
      expect(graphQlErrorCode(null), isNull);
      expect(graphQlErrorCode(_graphqlError(null)), isNull);
      expect(graphQlErrorCode(_subscriptionError('boom')), isNull);
    });

    test('the first error carrying a string code wins', () {
      final exception = OperationException(
        graphqlErrors: [
          GraphQLError(message: 'a'),
          GraphQLError(message: 'b', extensions: {'code': 'NOT_FOUND'}),
          GraphQLError(message: 'c', extensions: {'code': 'FORBIDDEN'}),
        ],
      );

      expect(graphQlErrorCode(exception), 'NOT_FOUND');
    });
  });

  group('isAccessDeniedError', () {
    test('accessDeniedCodes are FORBIDDEN and NOT_FOUND', () {
      expect(accessDeniedCodes, {'FORBIDDEN', 'NOT_FOUND'});
    });

    test('recognises stream exceptions by code', () {
      expect(
        isAccessDeniedError(
          const SubscriptionStreamException(
            operation: 'characterUpdated',
            code: 'FORBIDDEN',
          ),
        ),
        isTrue,
      );
      expect(
        isAccessDeniedError(
          const SubscriptionStreamException(
            operation: 'characterUpdated',
            code: 'INTERNAL_SERVER_ERROR',
          ),
        ),
        isFalse,
      );
      expect(
        isAccessDeniedError(
          const SubscriptionStreamException(operation: 'characterUpdated'),
        ),
        isFalse,
      );
    });

    test('recognises the access denied exception', () {
      expect(
        isAccessDeniedError(
          const GraphQlAccessDeniedException(
            operation: 'character',
            code: 'NOT_FOUND',
          ),
        ),
        isTrue,
      );
    });

    test('recognises a raw operation exception', () {
      expect(isAccessDeniedError(_graphqlError('FORBIDDEN')), isTrue);
      expect(isAccessDeniedError(_graphqlError('OTHER')), isFalse);
    });

    test('ignores unrelated errors', () {
      expect(isAccessDeniedError(Exception('x')), isFalse);
      expect(isAccessDeniedError(const FormatException('x')), isFalse);
    });
  });

  group('exceptions toString', () {
    test('carry operation and code only', () {
      expect(
        const SubscriptionStreamException(
          operation: 'userUpdated',
          code: 'FORBIDDEN',
        ).toString(),
        'SubscriptionStreamException(userUpdated, code: FORBIDDEN)',
      );
      expect(
        const GraphQlAccessDeniedException(
          operation: 'character',
          code: 'NOT_FOUND',
        ).toString(),
        'GraphQlAccessDeniedException(character, code: NOT_FOUND)',
      );
    });
  });
}
