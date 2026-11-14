import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/equip_item_request.dart';
import 'package:klimmeck_guide/repository/equipment_failure.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

/// Unico accesso del Diario a `equipItem`: ogni errore diventa
/// [EquipmentException] (graphql.md: mai OperationException alla UI). Lo
/// stato arriva solo da `characterUpdated`.
class EquipmentRepository {
  EquipmentRepository({
    required KlimmeckGraphQl graphQl,
    this.timeout = defaultTimeout,
  }) : _graphQl = graphQl;

  /// Come il compagno e le magie.
  static const Duration defaultTimeout = Duration(seconds: 15);

  final KlimmeckGraphQl _graphQl;
  final Duration timeout;

  Future<void> equip(EquipItemRequest request) async {
    final successful = await _guard(() => _graphQl.equipItem(request));
    if (!successful) {
      throw const EquipmentException(EquipmentFailure.declined);
    }
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(timeout);
    } on OperationException catch (error) {
      throw EquipmentException(equipmentFailureFrom(error));
    } on TimeoutException {
      throw const EquipmentException(EquipmentFailure.timedOut);
    } on Object {
      throw const EquipmentException(EquipmentFailure.unknown);
    }
  }
}
