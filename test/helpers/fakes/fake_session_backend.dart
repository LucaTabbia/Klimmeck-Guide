import 'package:klimmeck_guide/models/auth/auth_session.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/auth/auth.dart';

import '../auth_session_fixtures.dart';

/// BE in memoria condiviso da due dispositivi: l'ultimo login revoca gli altri
/// con `newLogin` (BE Phase 17 D-02), il refresh di una sessione revocata è
/// `SESSION_REVOKED` + motivo.
///
/// I JWT sono datati a [issuedAt] (il `now` iniettato nei servizi) e resi
/// unici arretrando l'`iat` di un secondo per ogni token emesso.
class FakeSessionBackend implements BackendAuthApi {
  FakeSessionBackend({required this.user, DateTime? issuedAt})
    : _issuedAt = issuedAt ?? testNow;

  final User user;
  final DateTime _issuedAt;

  /// Chiamato per ogni sessione revocata (id, motivo): il test chiude lì il
  /// socket.
  void Function(String sessionId, String reason)? onRevoked;

  final Map<String, _FakeSession> _sessions = {};
  int _sessionCount = 0;
  int _tokenCount = 0;

  @override
  Future<AuthSession> exchangeLoginTicket({
    required String ticket,
    required String codeVerifier,
  }) async {
    final sessionId = 's${++_sessionCount}';
    final session = _FakeSession();
    _sessions[sessionId] = session;
    final issued = _rotate(sessionId, session);
    _revokeOthers(sessionId);
    return issued;
  }

  @override
  Future<AuthSession> refreshSession(String refreshToken) async {
    final sessionId = _sessionIdWhere((s) => s.refreshToken == refreshToken);
    if (sessionId == null) throw const SessionRejected(sessionExpiredCode);
    final session = _sessions[sessionId]!;
    if (session.isRevoked) {
      throw SessionRejected(sessionRevokedCode, reason: session.revokeReason);
    }
    return _rotate(sessionId, session);
  }

  /// La revoca da logout non chiude socket via [onRevoked] (BE OQ3).
  @override
  Future<void> logout(String accessToken) async {
    final sessionId = sessionIdOfAccessToken(accessToken);
    if (sessionId == null) return;
    _sessions[sessionId]!.revoke(_userLogoutReason);
  }

  @override
  Future<User> fetchMe(String accessToken) async => user;

  /// Revoca ogni sessione attiva con [reason] (`null` = motivo assente).
  void revokeAll(String? reason) {
    for (final entry in _sessions.entries.toList()) {
      if (entry.value.isRevoked) continue;
      _revoke(entry.key, reason);
    }
  }

  String? sessionIdOfAccessToken(String accessToken) =>
      _sessionIdWhere((s) => s.accessTokens.contains(accessToken));

  /// Motivo della revoca di [sessionId]; `null` se attiva o sconosciuta.
  String? revokeReasonOf(String sessionId) {
    final session = _sessions[sessionId];
    if (session == null || !session.isRevoked) return null;
    return session.revokeReason ?? '';
  }

  void _revokeOthers(String keptSessionId) {
    for (final entry in _sessions.entries.toList()) {
      if (entry.key == keptSessionId || entry.value.isRevoked) continue;
      _revoke(entry.key, sessionRevokedReasonNewLogin);
    }
  }

  void _revoke(String sessionId, String? reason) {
    _sessions[sessionId]!.revoke(reason);
    onRevoked?.call(sessionId, reason ?? '');
  }

  AuthSession _rotate(String sessionId, _FakeSession session) {
    final count = ++_tokenCount;
    final accessToken = buildTestJwt(
      issuedAt: _issuedAt.subtract(Duration(seconds: count)),
      subject: user.id,
    );
    session
      ..accessTokens.add(accessToken)
      ..refreshToken = 'r-$sessionId-$count';
    return AuthSession(
      accessToken: accessToken,
      accessTokenExpiresAt: _issuedAt.add(testAccessTokenLifetime),
      refreshToken: session.refreshToken!,
      user: user,
    );
  }

  String? _sessionIdWhere(bool Function(_FakeSession session) test) {
    for (final entry in _sessions.entries) {
      if (test(entry.value)) return entry.key;
    }
    return null;
  }
}

const String _userLogoutReason = 'userLogout';

class _FakeSession {
  final List<String> accessTokens = [];
  String? refreshToken;
  bool isRevoked = false;
  String? revokeReason;

  void revoke(String? reason) {
    isRevoked = true;
    revokeReason = reason;
  }
}
