import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/mutations/account_mutations.dart';

import '../../tool/schema_check/schema_check_documents.dart';

String _normalised(String document) =>
    document.replaceAll(RegExp(r'\s+'), ' ').trim();

OperationDefinitionNode _operationOf(String document) => parseString(
  document,
).definitions.whereType<OperationDefinitionNode>().single;

void main() {
  test('DeleteMyAccount asks the own deletion with no argument (D-20)', () {
    final operation = _operationOf(AccountMutations.deleteMyAccount);
    final field = operation.selectionSet.selections.single as FieldNode;

    expect(operation.type, OperationType.mutation);
    expect(operation.name?.value, 'DeleteMyAccount');
    expect(operation.variableDefinitions, isEmpty);
    expect(field.name.value, 'deleteMyAccount');
    expect(field.arguments, isEmpty);
    expect(field.selectionSet, isNull);
  });

  test('DeleteAccountByTwitchLogin sends the Twitch login and selects only '
      'twitchId (D-15, D-20)', () {
    expect(
      _normalised(AccountMutations.deleteAccountByTwitchLogin),
      r'mutation DeleteAccountByTwitchLogin($twitchLogin: String!) { '
      r'deleteAccountByTwitchLogin(twitchLogin: $twitchLogin) { twitchId } }',
    );
  });

  test('both are registered for the schema check (D-20)', () {
    expect(
      schemaCheckDocuments['DeleteMyAccount'],
      AccountMutations.deleteMyAccount,
    );
    expect(
      schemaCheckDocuments['DeleteAccountByTwitchLogin'],
      AccountMutations.deleteAccountByTwitchLogin,
    );
  });
}
