import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/travel_request.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_gate.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart';

/// Unico accesso del viaggio ai servizi: ogni errore diventa [TravelException]
/// (graphql.md: mai OperationException alla UI). Dopo un `startTravel` riuscito
/// chiede il permesso notifiche, senza attenderlo (Phase 5 D-10, Phase 7 D-05):
/// è l'unico punto dell'app che può mostrare il prompt.
class TravelRepository {
  TravelRepository({
    required KlimmeckGraphQl graphQl,
    required NotificationPermissionGate permissionGate,
    this.timeout = defaultTimeout,
  }) : _graphQl = graphQl,
       _permissionGate = permissionGate;

  /// Come l'accettazione quest: oltre questo tempo l'azione fallisce come
  /// `timedOut`; la richiesta non è annullata e un viaggio partito comunque
  /// arriva via `characterUpdated`.
  static const Duration defaultTimeout = Duration(seconds: 15);

  final KlimmeckGraphQl _graphQl;
  final NotificationPermissionGate _permissionGate;
  final Duration timeout;

  Future<TravelPreview> preview({
    required String characterId,
    required String poiId,
  }) => _guard(
    () => _graphQl.previewTravel(TravelRequest(id: characterId, poiId: poiId)),
  );

  Future<void> start({
    required String characterId,
    required String poiId,
  }) async {
    final started = await _guard(
      () => _graphQl.startTravel(TravelRequest(id: characterId, poiId: poiId)),
    );
    if (!started) throw const TravelException(TravelFailure.declined);
    _askNotificationPermission();
  }

  void _askNotificationPermission() {
    unawaited(
      _permissionGate.ensureRequested().then<void>(
        (_) {},
        onError: (Object _) {},
      ),
    );
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(timeout);
    } on OperationException catch (error) {
      throw TravelException(travelFailureFrom(error));
    } on TimeoutException {
      throw const TravelException(TravelFailure.timedOut);
    } on Object {
      throw const TravelException(TravelFailure.unknown);
    }
  }
}
