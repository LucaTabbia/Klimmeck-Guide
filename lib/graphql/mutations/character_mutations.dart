class CharacterMutations {
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
}
