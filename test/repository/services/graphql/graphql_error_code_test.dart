import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';
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

GraphQLError _errorWithCode(String code) =>
    GraphQLError(message: 'server text', extensions: {'code': code});

ServerException _serverException(String code, int status) => ServerException(
  statusCode: status,
  parsedResponse: Response(response: const {}, errors: [_errorWithCode(code)]),
);

OperationException _fromHttp(String code, int status) =>
    OperationException(linkException: _serverException(code, status));

OperationException _fromHttp400(String code) => _fromHttp(code, 400);

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

    test('reads the code of a GraphQL error answered with HTTP 400 (D-13)', () {
      expect(
        graphQlErrorCode(_fromHttp400('BAD_USER_INPUT')),
        'BAD_USER_INPUT',
      );
    });

    test('prefers the graphql errors over the parsed response (D-13)', () {
      final exception = OperationException(
        graphqlErrors: [_errorWithCode('FORBIDDEN')],
        linkException: _serverException('NOT_FOUND', 400),
      );

      expect(graphQlErrorCode(exception), 'FORBIDDEN');
    });

    test('returns null for an HTTP error without a code (D-13)', () {
      final exception = OperationException(
        linkException: ServerException(statusCode: 500, parsedResponse: null),
      );

      expect(graphQlErrorCode(exception), isNull);
    });

    test('a coded HTTP 500 reads as its code and classifies as unknown, an '
        'uncoded one stays connection (D-13)', () {
      final coded = _fromHttp('INTERNAL_SERVER_ERROR', 500);
      final uncoded = OperationException(
        linkException: ServerException(statusCode: 500, parsedResponse: null),
      );

      expect(graphQlErrorCode(coded), 'INTERNAL_SERVER_ERROR');
      expect(questAcceptanceFailureFrom(coded), QuestAcceptanceFailure.unknown);
      expect(
        questAcceptanceFailureFrom(uncoded),
        QuestAcceptanceFailure.connection,
      );
    });
  });

  group('graphQlErrorExtension', () {
    const recoveryUntil = '2026-10-27T10:30:00.000Z';
    final extensions = {
      'code': 'POTION_RECOVERING',
      'recoveryUntil': recoveryUntil,
    };

    test('reads another extension of the coded graphql error (D-19)', () {
      final exception = OperationException(
        graphqlErrors: [
          GraphQLError(message: 'server text', extensions: extensions),
        ],
      );

      expect(graphQlErrorExtension(exception, 'recoveryUntil'), recoveryUntil);
    });

    test('reads it from an error answered with HTTP 400 (D-19)', () {
      final exception = OperationException(
        linkException: ServerException(
          statusCode: 400,
          parsedResponse: Response(
            response: const {},
            errors: [
              GraphQLError(message: 'server text', extensions: extensions),
            ],
          ),
        ),
      );

      expect(graphQlErrorExtension(exception, 'recoveryUntil'), recoveryUntil);
    });

    test('returns null without the key, without a coded error or without an '
        'exception (D-19)', () {
      final withoutKey = _graphqlError('POTION_RECOVERING');
      final uncoded = OperationException(
        graphqlErrors: [
          GraphQLError(
            message: 'x',
            extensions: {'recoveryUntil': recoveryUntil},
          ),
        ],
      );

      expect(graphQlErrorExtension(withoutKey, 'recoveryUntil'), isNull);
      expect(graphQlErrorExtension(uncoded, 'recoveryUntil'), isNull);
      expect(graphQlErrorExtension(null, 'recoveryUntil'), isNull);
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

    test('a FORBIDDEN answered with HTTP 403 is an access denial (D-13)', () {
      expect(isAccessDeniedError(_fromHttp('FORBIDDEN', 403)), isTrue);
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
