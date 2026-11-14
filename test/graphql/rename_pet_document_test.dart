import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/graphql/mutations/character_mutations.dart';

import '../../tool/schema_check/schema_check_documents.dart';

String _collapsed(String document) => document.replaceAll(RegExp(r'\s+'), ' ');

void main() {
  test('RenamePet is a named mutation on RenamePetRequest selecting '
      'successful (D-19, D-23)', () {
    final document = _collapsed(CharacterMutations.renamePet);

    expect(
      document,
      contains(r'mutation RenamePet($request: RenamePetRequest!)'),
    );
    expect(
      document,
      contains(r'renamePet(request: $request) { response successful }'),
    );
  });

  test('RenamePet is registered for the schema check (D-19)', () {
    expect(schemaCheckDocuments['RenamePet'], CharacterMutations.renamePet);
  });
}
