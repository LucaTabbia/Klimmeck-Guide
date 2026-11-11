import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/graphql/mutations/character_mutations.dart';

import '../../tool/schema_check/schema_check_documents.dart';

String _collapsed(String document) => document.replaceAll(RegExp(r'\s+'), ' ');

void main() {
  test('UseItem is a named mutation with the itemId variable (D-11)', () {
    final document = _collapsed(CharacterMutations.useItem);

    expect(document, contains(r'mutation UseItem($itemId: ID!)'));
    expect(document, contains(r'useItem(itemId: $itemId)'));
  });

  test('selects the outcome fields and the unlocked lore refs (D-11)', () {
    expect(
      _collapsed(CharacterMutations.useItem),
      contains(
        '{ hpBefore hpAfter injuriesHealed quantityLeft recoveryUntil '
        'loreUnlocked { id name type } }',
      ),
    );
  });

  test('does not select the related lore of the item (D-16)', () {
    expect(
      _collapsed(CharacterMutations.useItem),
      isNot(contains('relatedLore')),
    );
  });

  test('UseItem is registered for the schema check (D-19)', () {
    expect(schemaCheckDocuments['UseItem'], CharacterMutations.useItem);
  });
}
