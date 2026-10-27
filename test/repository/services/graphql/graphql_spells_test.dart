import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/equip_spell_request.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

import '../../../helpers/fixtures/sync_event_fixtures.dart';

void main() {
  late List<Request> requests;
  late Stream<Response> Function(Request request) handler;

  const request = EquipSpellRequest(id: 'c-1', spellId: 'spell-1');
  const requestVariables = {
    'request': {'id': 'c-1', 'spellId': 'spell-1'},
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

  void expectSpellSlotMutation({
    required String field,
    required String operationName,
    required Future<bool> Function(KlimmeckGraphQl graphQl) call,
  }) {
    Response answer({required bool successful}) => dataResponse({
      field: {'response': 'ok', 'successful': successful},
    });

    test('sends $operationName with the request variable', () async {
      handler = (_) => Stream.value(answer(successful: true));

      await call(buildGraphQl());

      expect(operationNameOf(requests.single), operationName);
      expect(requests.single.variables, requestVariables);
    });

    test('returns true when the mutation is successful', () async {
      handler = (_) => Stream.value(answer(successful: true));

      expect(await call(buildGraphQl()), isTrue);
    });

    test('returns false when the mutation is not successful', () async {
      handler = (_) => Stream.value(answer(successful: false));

      expect(await call(buildGraphQl()), isFalse);
    });

    test('throws FormatException when successful is missing', () async {
      handler = (_) => Stream.value(dataResponse({field: null}));

      await expectLater(call(buildGraphQl()), throwsFormatException);
    });

    test('throws the raw OperationException keeping the error code', () async {
      handler = (_) => Stream.value(errorCodeResponse('SPELL_NOT_KNOWN'));

      await expectLater(
        call(buildGraphQl()),
        throwsOperationCoded('SPELL_NOT_KNOWN'),
      );
    });
  }

  group('equipSpell', () {
    expectSpellSlotMutation(
      field: 'equipSpell',
      operationName: 'EquipSpell',
      call: (graphQl) => graphQl.equipSpell(request),
    );
  });

  group('unequipSpell', () {
    expectSpellSlotMutation(
      field: 'unequipSpell',
      operationName: 'UnequipSpell',
      call: (graphQl) => graphQl.unequipSpell(request),
    );
  });
}
