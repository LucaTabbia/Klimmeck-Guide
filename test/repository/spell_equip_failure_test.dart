import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/spell_equip_failure.dart';

OperationException _withCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  group('spellEquipFailureFrom', () {
    final byCode = {
      'SPELL_NOT_KNOWN': SpellEquipFailure.notKnown,
      'SPELL_ALREADY_ACTIVE': SpellEquipFailure.alreadyActive,
      'MAX_ACTIVE_SPELLS_REACHED': SpellEquipFailure.slotsFull,
      'SPELL_NOT_ACTIVE': SpellEquipFailure.notActive,
      'NOT_FOUND': SpellEquipFailure.notFound,
      'FORBIDDEN': SpellEquipFailure.forbidden,
      'BAD_USER_INPUT': SpellEquipFailure.badUserInput,
      'UNAUTHENTICATED': SpellEquipFailure.unauthenticated,
      'SPELL_NO_USAGES_LEFT': SpellEquipFailure.unknown,
    };
    byCode.forEach((code, failure) {
      test('maps $code to ${failure.name}', () {
        expect(spellEquipFailureFrom(_withCode(code)), failure);
      });
    });

    test('maps a link error without code to connection', () {
      final exception = OperationException(
        linkException: ServerException(
          originalException: const SocketException('offline'),
        ),
      );

      expect(spellEquipFailureFrom(exception), SpellEquipFailure.connection);
    });

    test('maps an error with neither code nor link to unknown', () {
      expect(
        spellEquipFailureFrom(OperationException()),
        SpellEquipFailure.unknown,
      );
    });

    test('ignores the message text and relies on the code only', () {
      final exception = OperationException(
        graphqlErrors: [
          GraphQLError(
            message: 'SPELL_NOT_KNOWN',
            extensions: {'code': 'FORBIDDEN'},
          ),
        ],
      );

      expect(spellEquipFailureFrom(exception), SpellEquipFailure.forbidden);
    });
  });

  test('SpellEquipException prints the failure name only', () {
    expect(
      const SpellEquipException(SpellEquipFailure.slotsFull).toString(),
      'SpellEquipException(slotsFull)',
    );
  });
}
