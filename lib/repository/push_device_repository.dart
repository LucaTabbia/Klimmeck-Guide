import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/push_device_failure.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

/// Unico accesso del push ai servizi GraphQL: ogni errore diventa [PushDeviceException].
class PushDeviceRepository {
  PushDeviceRepository({required KlimmeckGraphQl graphQl}) : _graphQl = graphQl;

  /// Valore `PushPlatform` registrato: la fase è solo Android (D-03); la fase iOS aggiunge `ios`.
  static const String androidPlatform = 'android';

  final KlimmeckGraphQl _graphQl;

  Future<void> register({required String deviceId, required String token}) =>
      _guard(
        () => _graphQl.registerPushDevice(
          deviceId: deviceId,
          token: token,
          platform: androidPlatform,
        ),
      );

  Future<void> unregister(String deviceId) =>
      _guard(() => _graphQl.unregisterPushDevice(deviceId));

  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } on OperationException catch (error) {
      throw PushDeviceException(pushDeviceFailureFrom(error));
    } on FormatException {
      throw const PushDeviceException(PushDeviceFailure.unknown);
    }
  }
}
