import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/use_item_result.dart';
import 'package:klimmeck_guide/repository/item_use_failure.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

/// Unico accesso delle pozioni del Diario ai servizi: ogni errore diventa
/// [ItemUseException] (graphql.md: mai OperationException alla UI).
class ItemUseRepository {
  ItemUseRepository({
    required KlimmeckGraphQl graphQl,
    this.timeout = defaultTimeout,
  }) : _graphQl = graphQl;

  static const Duration defaultTimeout = Duration(seconds: 15);

  final KlimmeckGraphQl _graphQl;
  final Duration timeout;

  Future<UseItemResult> useItem(String itemId) async {
    try {
      return await _graphQl.useItem(itemId).timeout(timeout);
    } on OperationException catch (error) {
      throw itemUseExceptionFrom(error);
    } on TimeoutException {
      throw const ItemUseException(ItemUseFailure.timedOut);
    } on Object {
      throw const ItemUseException(ItemUseFailure.unknown);
    }
  }
}
