import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/unauthorized_recovery.dart';
import 'package:klimmeck_guide/utils/backoff.dart';

/// Politica di (ri)connessione del WebSocket GraphQL per il `SocketClient` di
/// `graphql` 5.2.1, che rivaluta `initialPayload` a ogni connect e attende
/// `onConnectionLost` prima di armare il timer di riconnessione.
///
/// - [buildInitialPayload] legge il token CORRENTE a ogni connect (D-07): il
///   link non viene mai ricreato dopo un refresh, così le subscription vive
///   non si spezzano (D-37). Il link viene disposto e ricreato solo al logout
///   da `GraphQLClientHolder.reset()` (D-12).
/// - [onConnectionLost] su 4401 (`Token expired`) / 4403 (rifiuto al connect)
///   passa dalla [UnauthorizedRecovery] prima di riconnettere; ogni altro
///   caso usa un backoff esponenziale limitato, azzerato solo dopo una
///   connessione stabile: nessun hot loop con un token morto.
///
/// Gli eventi persi nel gap di riconnessione non sono recuperati qui: il
/// refetch-on-reconnect è responsabilità di Phase 3.
class WsReconnectPolicy {
  WsReconnectPolicy({
    required AuthTokenService authService,
    UnauthorizedRecovery? recovery,
    DateTime Function() now = DateTime.now,
  }) : _authService = authService,
       _recovery = recovery,
       _now = now;

  static const Set<int> authRejectedCloseCodes = {4401, 4403};
  static const Duration authRetryDelay = Duration(milliseconds: 500);
  static const Duration maxReconnectDelay = Duration(seconds: 60);
  static const Duration stableConnection = Duration(seconds: 30);

  final AuthTokenService _authService;
  final UnauthorizedRecovery? _recovery;
  final DateTime Function() _now;

  String? _lastSentToken;
  DateTime? _connectedAt;
  int _attempt = 0;

  /// Payload del `connection_init`. Non lancia MAI: nel client `await
  /// config.initOperation` sta fuori dal try di `_connect()` e un'eccezione
  /// fermerebbe la riconnessione in silenzio.
  Future<Map<String, dynamic>> buildInitialPayload() async {
    try {
      final token = await _currentToken();
      _lastSentToken = token;
      _connectedAt = _now();
      return {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Ritardo prima del prossimo tentativo di connessione.
  ///
  /// Il ritardo breve di [authRetryDelay] è concesso solo al primo tentativo
  /// dopo una connessione stabile: un rifiuto ripetuto con token appena
  /// rinnovato ricade nel backoff.
  Future<Duration?> onConnectionLost(int? code, String? reason) async {
    _resetAttemptsAfterStableConnection();
    if (authRejectedCloseCodes.contains(code) &&
        await _recoverSession() &&
        _attempt == 0) {
      _attempt++;
      return authRetryDelay;
    }
    return exponentialBackoff(_attempt++, max: maxReconnectDelay);
  }

  void _resetAttemptsAfterStableConnection() {
    final connectedAt = _connectedAt;
    _connectedAt = null;
    if (connectedAt == null) return;
    if (_now().difference(connectedAt) >= stableConnection) _attempt = 0;
  }

  Future<bool> _recoverSession() async {
    final recovery = _recovery;
    if (recovery == null) return false;
    try {
      return await _refreshedToken(recovery) != null;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _refreshedToken(UnauthorizedRecovery recovery) =>
      recovery.recoverFromUnauthorized(rejectedToken: _lastSentToken);

  Future<String?> _currentToken() async {
    try {
      return await _authService.getAccessToken();
    } catch (_) {
      return null;
    }
  }
}
