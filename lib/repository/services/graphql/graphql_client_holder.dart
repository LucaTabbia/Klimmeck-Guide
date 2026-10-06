import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_provider.dart';

/// Possiede il client GraphQL corrente.
///
/// [reset] (logout, D-12 passi 2–3) dispone il WebSocket — chiude il socket e
/// quindi tutte le subscription in volo, e ferma i tentativi di riconnessione
/// — poi ricrea client + link: nessuno store riciclato, nessun listener che
/// sopravvive alla sessione. Sicuro da chiamare più volte di seguito; le
/// chiamate sovrapposte condividono la stessa ricreazione, così nessun link
/// sostituito resta senza `dispose`.
///
/// `GraphQLProvider(client: holder.client)` DEVE restare sopra `MaterialApp`:
/// `KlimmeckGraphQl` risolve il client dal contesto del `navigatorKey`.
class GraphQLClientHolder {
  GraphQLClientHolder({required GraphQLConnection Function() connect})
    : _connect = connect {
    final connection = _connect();
    _webSocketLink = connection.webSocketLink;
    client = ValueNotifier<GraphQLClient>(connection.client);
  }

  final GraphQLConnection Function() _connect;
  late WebSocketLink _webSocketLink;

  /// Client corrente, ascoltato da `GraphQLProvider`.
  late final ValueNotifier<GraphQLClient> client;

  Future<void>? _resetInFlight;

  Future<void> reset() =>
      _resetInFlight ??= _recreate().whenComplete(() => _resetInFlight = null);

  Future<void> _recreate() async {
    try {
      await _webSocketLink.dispose();
    } catch (error) {
      debugPrint(
        '[GraphQLClientHolder] websocket dispose failed: ${error.runtimeType}',
      );
    }
    final connection = _connect();
    _webSocketLink = connection.webSocketLink;
    client.value = connection.client;
  }
}
