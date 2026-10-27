import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/equip_spell_request.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/spell_equip_failure.dart';
import 'package:klimmeck_guide/repository/spells_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

Matcher _failsWith(SpellEquipFailure failure) => throwsA(
  isA<SpellEquipException>().having((e) => e.failure, 'failure', failure),
);

OperationException _coded(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  const request = EquipSpellRequest(id: 'c-1', spellId: 'spell-1');

  late MockKlimmeckGraphQl graphQl;
  late SpellsRepository repository;

  setUpAll(() {
    registerFallbackValue(const EquipSpellRequest(id: '', spellId: ''));
  });

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    repository = SpellsRepository(graphQl: graphQl);
  });

  test('times out after 15 seconds by default', () {
    expect(SpellsRepository.defaultTimeout, const Duration(seconds: 15));
  });

  void expectSlotAction({
    required String name,
    required Future<bool> Function(EquipSpellRequest request) Function(
      KlimmeckGraphQl graphQl,
    )
    service,
    required Future<void> Function(SpellsRepository repository) action,
  }) {
    group(name, () {
      test('sends the character and spell ids and completes', () async {
        when(() => service(graphQl)(any())).thenAnswer((_) async => true);

        await action(repository);

        verify(() => service(graphQl)(request)).called(1);
      });

      test('throws declined when the service answers false', () async {
        when(() => service(graphQl)(any())).thenAnswer((_) async => false);

        await expectLater(
          action(repository),
          _failsWith(SpellEquipFailure.declined),
        );
      });

      test('maps a coded OperationException to its failure', () async {
        when(
          () => service(graphQl)(any()),
        ).thenThrow(_coded('MAX_ACTIVE_SPELLS_REACHED'));

        await expectLater(
          action(repository),
          _failsWith(SpellEquipFailure.slotsFull),
        );
      });

      test('maps a FormatException to unknown', () async {
        when(
          () => service(graphQl)(any()),
        ).thenThrow(const FormatException('malformed'));

        await expectLater(
          action(repository),
          _failsWith(SpellEquipFailure.unknown),
        );
      });

      test('maps any other error to unknown', () async {
        when(() => service(graphQl)(any())).thenThrow(StateError('boom'));

        await expectLater(
          action(repository),
          _failsWith(SpellEquipFailure.unknown),
        );
      });

      test('fails as timedOut after 15 seconds without an answer', () {
        fakeAsync((async) {
          when(
            () => service(graphQl)(any()),
          ).thenAnswer((_) => Completer<bool>().future);
          Object? failure;

          action(
            repository,
          ).then<void>((_) {}, onError: (Object error) => failure = error);
          async.elapse(const Duration(seconds: 14));
          expect(failure, isNull);
          async.elapse(const Duration(seconds: 1));

          expect(
            failure,
            isA<SpellEquipException>().having(
              (e) => e.failure,
              'failure',
              SpellEquipFailure.timedOut,
            ),
          );
        });
      });
    });
  }

  expectSlotAction(
    name: 'equip',
    service: (graphQl) => graphQl.equipSpell,
    action: (repository) =>
        repository.equip(characterId: 'c-1', spellId: 'spell-1'),
  );

  expectSlotAction(
    name: 'unequip',
    service: (graphQl) => graphQl.unequipSpell,
    action: (repository) =>
        repository.unequip(characterId: 'c-1', spellId: 'spell-1'),
  );
}
