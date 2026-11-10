import '../fragments/user_fragment.dart';

class CharacterMutations {
  static const String createCharacter =
      r'''
    mutation CreateCharacter($input: CreateCharacterInput!) {
      createCharacter(input: $input) {
        ...UserFields
      }
    }
  ''' +
      UserFragment.definition;

  /// Archivia il personaggio corrente del chiamante (identità dal bearer, BE 03.1).
  static const String deleteCharacter =
      r'''
    mutation DeleteCharacter {
      deleteCharacter {
        ...UserFields
      }
    }
  ''' +
      UserFragment.definition;

  static const String doTransaction = r'''
    mutation doTransaction($request: TransactionRequest!) {
      doTransaction(request: $request) {
        response
        successful
      }
    }''';

  static const String equipItem = r'''
    mutation equipItem($request: EquipItemRequest!) {
      equipItem(request: $request) {
        response
        successful
      }
    }''';

  static const String equipSpell = r'''
    mutation EquipSpell($request: EquipSpellRequest!) {
      equipSpell(request: $request) {
        response
        successful
      }
    }''';

  static const String unequipSpell = r'''
    mutation UnequipSpell($request: EquipSpellRequest!) {
      unequipSpell(request: $request) {
        response
        successful
      }
    }''';

  static const String equipPet = r'''
    mutation EquipPet($request: EquipPetRequest!) {
      equipPet(request: $request) {
        response
        successful
      }
    }''';

  static const String unequipPet = r'''
    mutation UnequipPet($request: UnequipPetRequest!) {
      unequipPet(request: $request) {
        response
        successful
      }
    }''';

  /// Beve una pozione dal Diario (BE Phase 18): l'identità è il bearer, si
  /// manda solo l'id dell'oggetto.
  static const String useItem = r'''
    mutation UseItem($itemId: ID!) {
      useItem(itemId: $itemId) {
        hpBefore
        hpAfter
        injuriesHealed
        quantityLeft
        recoveryUntil
        loreUnlocked {
          id
          name
          type
        }
      }
    }''';
}
