import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:klimmeck_guide/models/auth/auth_session.dart';
import 'package:klimmeck_guide/models/auth/login_challenge.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/storage/session_store.dart';
import 'package:klimmeck_guide/utils/backoff.dart';

import 'access_token_lifetime.dart';
import 'auth_api_exception.dart';
import 'auth_state_channel.dart';
import 'auth_token_service.dart';
import 'backend_auth_api.dart';
import 'browser_authenticator.dart';
import 'login_callback.dart';
import 'login_exception.dart';
import 'unauthorized_recovery.dart';

/// [AuthTokenService] reale: sessione first-party del backend.
///
/// L'app non vede mai token Twitch (D-26): conserva solo il refresh token del
/// backend in [SessionStore] e tiene l'access JWT in memoria.
///
/// - Cold start (D-08, D-18, D-19): senza refresh token → `signedOut` subito;
///   altrimenti `refreshSession` col backend, ritentato con backoff (cap 30 s)
///   finché il backend non risponde. `initialize()` non attende la rete.
/// - Refresh single-flight (D-06): chiamanti concorrenti condividono un solo
///   `Completer<String>`, quindi un solo round-trip per ciclo.
/// - Persist-before-forget (D-05): il refresh token ruotato è scritto nello
///   storage prima di sostituire quello in memoria; se la scrittura fallisce
///   la sessione resta valida in memoria.
/// - Refresh proattivo (D-05): `durata JWT − 60 s` con floor 30 s, robusto
///   allo skew dell'orologio; un errore transitorio ritenta con backoff
///   (cap 60 s) e non fa mai logout (D-09).
/// - Solo [SessionRejected] chiude la sessione (AUTH-07).
/// - Epoch guard: logout, revoca, login e `dispose()` incrementano `_epoch`;
///   un refresh di una sessione superata non tocca né storage né memoria.
///
/// Tutte le dipendenze sono iniettate dal composition root: il servizio non
/// legge la configurazione d'ambiente e non logga mai token.
class SessionAuthTokenService extends AuthTokenService
    implements UnauthorizedRecovery {
  SessionAuthTokenService({
    required BackendAuthApi api,
    required SessionStore store,
    required BrowserAuthenticator browser,
    required Uri backendBaseUrl,
    required Future<void> Function() onSessionTeardown,
    DateTime Function() now = DateTime.now,
    LoginChallenge Function() createChallenge = LoginChallenge.generate,
    Duration logoutTimeout = const Duration(seconds: 4),
  }) : _api = api,
       _store = store,
       _browser = browser,
       _backendBaseUrl = backendBaseUrl,
       _onSessionTeardown = onSessionTeardown,
       _now = now,
       _createChallenge = createChallenge,
       _logoutTimeout = logoutTimeout;

  static const Duration _bootstrapRetryCap = Duration(seconds: 30);
  static const Duration _proactiveRetryCap = Duration(seconds: 60);

  final BackendAuthApi _api;
  final SessionStore _store;
  final BrowserAuthenticator _browser;
  final Uri _backendBaseUrl;
  final Future<void> Function() _onSessionTeardown;
  final DateTime Function() _now;
  final LoginChallenge Function() _createChallenge;
  final Duration _logoutTimeout;
  final AuthStateChannel _channel = AuthStateChannel();

  String? _accessToken;

  /// Access token emessi alla sessione corrente (rotazioni comprese).
  final Set<String> _issuedAccessTokens = {};
  String? _refreshToken;
  User? _user;
  DateTime? _refreshAt;
  Completer<String>? _refreshInFlight;
  Future<void>? _logoutInFlight;
  int _epoch = 0;
  Timer? _proactiveRefreshTimer;
  Timer? _bootstrapRetryTimer;
  int _bootstrapAttempt = 0;
  int _proactiveRetryAttempt = 0;
  bool _isDisposed = false;

  @override
  Stream<AuthState> get authStateStream => _channel.stream;

  /// Emette `AuthBootstrapping`, legge lo storage e avvia in background la
  /// verifica della sessione col backend: ritorna senza attendere la rete.
  /// Non lancia mai: uno storage illeggibile porta al sign-in.
  @override
  Future<void> initialize() async {
    final epoch = _epoch;
    _channel.emit(const AuthBootstrapping());
    final storedRefreshToken = await _readStoredRefreshToken();
    if (epoch != _epoch) return;
    if (storedRefreshToken == null) {
      _channel.emit(const AuthUnauthenticated());
      return;
    }
    _refreshToken = storedRefreshToken;
    unawaited(_attemptBootstrap(epoch));
  }

  /// Token in memoria finché è fresco; altrimenti refresh single-flight.
  /// Un errore transitorio ritorna il token precedente (mai logout).
  /// Un chiamante la cui sessione è stata sostituita durante l'attesa riceve
  /// `null`, mai il token della sessione successiva.
  @override
  Future<String?> getAccessToken() async {
    if (_hasFreshAccessToken || _refreshToken == null) return _accessToken;
    final epoch = _epoch;
    try {
      final token = await _refreshSingleFlight();
      return _tokenFor(epoch, token);
    } on SessionRejected {
      return null;
    } catch (_) {
      return _tokenFor(epoch, _accessToken);
    }
  }

  /// Login Twitch mediato dal backend nel browser di sistema (D-15).
  ///
  /// La sessione precedente (anche una ancora in retry al cold start) viene
  /// sostituita solo dopo un riscatto del ticket riuscito: un login annullato
  /// o fallito non interrompe la sua ripresa in background. Un login riscattato
  /// mentre un logout è ancora in corso viene installato solo dopo la fine di
  /// quel logout, che quindi non può mai chiudere la sessione nuova.
  /// Lancia [LoginException].
  @override
  Future<void> login() async {
    final challenge = _createChallenge();
    final callbackUrl = await _openLoginPage(challenge);
    final session = await _redeemTicket(_ticketFrom(callbackUrl), challenge);
    await _logoutInFlight;
    if (_isDisposed) return;
    await _startSession(session);
  }

  /// Logout atomico (D-12): (1) invalidazione best-effort della sessione sul
  /// backend, limitata da `logoutTimeout` (D-13: offline o backend lento non
  /// bloccano), (2–3) teardown iniettato (subscription e client GraphQL),
  /// (4) storage svuotato, (5) `AuthUnauthenticated(signedOut)`.
  ///
  /// La sessione viene staccata dal servizio prima del passo (1): nessun
  /// refresh in volo o successivo può chiuderla come `sessionExpired`, quindi
  /// il logout emette un solo stato terminale ed esegue teardown e pulizia
  /// dello storage una sola volta. L'access token resta leggibile fino al
  /// teardown, senza più essere rinnovato. Chiamate sovrapposte (doppio tap)
  /// condividono lo stesso logout. Non lancia mai.
  @override
  Future<void> logout() => _logoutInFlight ??= _performLogout().whenComplete(
    () => _logoutInFlight = null,
  );

  Future<void> _performLogout() async {
    final closing = _detachSession();
    final backendStep = _invalidateBackendSession(closing);
    await backendStep.timeout(_logoutTimeout, onTimeout: _logLogoutTimeout);
    await _endSession(UnauthenticatedReason.signedOut);
  }

  /// Revoca esplicita (AUTH-07): teardown locale senza chiamare il backend.
  @override
  Future<void> handleRevocation() =>
      _endSession(UnauthenticatedReason.sessionExpired);

  /// Unico punto d'ingresso del retry reattivo per link GraphQL, interceptor
  /// dio e WebSocket: passa sempre dal refresh single-flight.
  ///
  /// Se il token rifiutato non è più quello corrente (già ruotato) ritorna il
  /// corrente senza refresh. `null` se la sessione non è recuperabile
  /// ([SessionRejected]: teardown già eseguito), se l'errore è transitorio
  /// (mai logout, D-09) o se il token rifiutato non appartiene alla sessione
  /// corrente: una richiesta di una sessione precedente non viene mai
  /// ritentata con l'identità di quella nuova.
  @override
  Future<String?> recoverFromUnauthorized({String? rejectedToken}) async {
    if (!_issuedAccessTokens.contains(rejectedToken)) return null;
    final current = _accessToken;
    if (current != rejectedToken) return current;
    if (_refreshToken == null) return null;
    final epoch = _epoch;
    try {
      final token = await _refreshSingleFlight();
      return _tokenFor(epoch, token);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _supersedeSession();
    _channel.close();
  }

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  Future<String> _openLoginPage(LoginChallenge challenge) async {
    final startUrl = _backendBaseUrl
        .resolve('auth/twitch/start')
        .replace(queryParameters: {'challenge': challenge.codeChallenge});
    try {
      return await _browser.authenticate(
        startUrl: startUrl,
        callbackScheme: loginCallbackScheme,
      );
    } on BrowserAuthCancelled {
      throw const LoginCancelledException();
    } on BrowserAuthFailure catch (failure) {
      throw LoginFailedException(failure.code);
    }
  }

  String _ticketFrom(String callbackUrl) =>
      switch (parseLoginCallback(callbackUrl)) {
        LoginTicketReceived(:final ticket) => ticket,
        LoginDeniedByUser() => throw const LoginCancelledException(),
        LoginRejectedByBackend(code: twitchNotConfiguredError) =>
          throw const LoginUnavailableException(),
        LoginRejectedByBackend(:final code) => throw LoginFailedException(code),
      };

  Future<AuthSession> _redeemTicket(
    String ticket,
    LoginChallenge challenge,
  ) async {
    try {
      return await _api.exchangeLoginTicket(
        ticket: ticket,
        codeVerifier: challenge.codeVerifier,
      );
    } on LoginTicketInvalid {
      throw const LoginFailedException(loginTicketInvalidCode);
    } on TransientAuthFailure {
      throw const LoginFailedException(_networkFailureCode);
    } on AuthApiException catch (error) {
      throw LoginFailedException(error.runtimeType.toString());
    }
  }

  /// Sostituisce qualunque sessione precedente (bootstrap o refresh in volo
  /// compresi) con quella appena riscattata.
  Future<void> _startSession(AuthSession session) async {
    _supersedeSession();
    final epoch = _epoch;
    await _persistRefreshToken(session.refreshToken);
    if (epoch != _epoch) return;
    _applySession(session);
    _emitAuthenticated();
  }

  // ---------------------------------------------------------------------------
  // Cold start
  // ---------------------------------------------------------------------------

  Future<String?> _readStoredRefreshToken() async {
    try {
      return await _store.readRefreshToken();
    } catch (error) {
      debugPrint('[SessionAuth] session read failed: ${error.runtimeType}');
      return null;
    }
  }

  Future<void> _attemptBootstrap(int epoch) async {
    try {
      await _refreshSingleFlight();
    } on SessionRejected {
      return;
    } catch (error) {
      if (epoch != _epoch) return;
      debugPrint('[SessionAuth] session resolve failed: ${error.runtimeType}');
      _scheduleBootstrapRetry(epoch);
      return;
    }
    if (epoch != _epoch) return;
    _emitAuthenticated();
  }

  void _scheduleBootstrapRetry(int epoch) {
    final delay = exponentialBackoff(
      _bootstrapAttempt++,
      max: _bootstrapRetryCap,
    );
    _bootstrapRetryTimer = Timer(delay, () => _attemptBootstrap(epoch));
  }

  // ---------------------------------------------------------------------------
  // Refresh
  // ---------------------------------------------------------------------------

  String? _tokenFor(int epoch, String? token) => epoch == _epoch ? token : null;

  bool get _hasFreshAccessToken {
    final refreshAt = _refreshAt;
    return _accessToken != null &&
        refreshAt != null &&
        _now().isBefore(refreshAt);
  }

  Future<String> _refreshSingleFlight() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight.future;
    final completer = Completer<String>();
    _refreshInFlight = completer;
    unawaited(_rotateSession(completer, _epoch, _refreshToken!));
    return completer.future;
  }

  Future<void> _rotateSession(
    Completer<String> completer,
    int epoch,
    String refreshToken,
  ) async {
    try {
      final session = await _api.refreshSession(refreshToken);
      if (epoch != _epoch) return completer.completeError(_superseded);
      await _persistRefreshToken(session.refreshToken);
      if (epoch != _epoch) return completer.completeError(_superseded);
      final previousUserId = _user?.id;
      _applySession(session);
      _announceIdentityChange(previousUserId);
      completer.complete(session.accessToken);
    } on SessionRejected catch (error) {
      if (epoch != _epoch) return completer.completeError(_superseded);
      await _endSession(UnauthenticatedReason.sessionExpired);
      completer.completeError(error);
    } catch (error) {
      completer.completeError(error);
    } finally {
      if (identical(_refreshInFlight, completer)) _refreshInFlight = null;
    }
  }

  Future<void> _persistRefreshToken(String refreshToken) async {
    try {
      await _store.writeRefreshToken(refreshToken);
    } catch (error) {
      debugPrint(
        '[SessionAuth] refresh token persist failed: ${error.runtimeType}',
      );
    }
  }

  void _applySession(AuthSession session) {
    _accessToken = session.accessToken;
    _issuedAccessTokens.add(session.accessToken);
    _refreshToken = session.refreshToken;
    _user = session.user;
    final delay = refreshDelayFor(
      accessToken: session.accessToken,
      expiresAt: session.accessTokenExpiresAt,
      now: _now(),
    );
    _refreshAt = _now().add(delay);
    _bootstrapAttempt = 0;
    _proactiveRetryAttempt = 0;
    _scheduleProactiveRefresh(delay);
  }

  /// Le rotazioni non ri-emettono lo stato, salvo cambio di identità.
  void _announceIdentityChange(String? previousUserId) {
    if (_channel.current is! AuthAuthenticated) return;
    if (previousUserId == _user?.id) return;
    _emitAuthenticated();
  }

  void _scheduleProactiveRefresh(Duration delay) {
    _proactiveRefreshTimer?.cancel();
    _proactiveRefreshTimer = Timer(delay, _runProactiveRefresh);
  }

  Future<void> _runProactiveRefresh() async {
    final epoch = _epoch;
    try {
      await _refreshSingleFlight();
    } on SessionRejected {
      return;
    } catch (error) {
      if (epoch != _epoch || _refreshToken == null) return;
      debugPrint(
        '[SessionAuth] proactive refresh failed: ${error.runtimeType}',
      );
      _scheduleProactiveRefresh(
        exponentialBackoff(_proactiveRetryAttempt++, max: _proactiveRetryCap),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Session lifecycle
  // ---------------------------------------------------------------------------

  void _emitAuthenticated() {
    _channel.emit(AuthAuthenticated(user: _user!, accessToken: _accessToken!));
  }

  /// Invalida ogni lavoro in corso della sessione attuale (timer, refresh).
  void _supersedeSession() {
    _epoch++;
    _issuedAccessTokens.clear();
    _bootstrapRetryTimer?.cancel();
    _proactiveRefreshTimer?.cancel();
    _refreshInFlight = null;
  }

  void _forgetSession() {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _refreshAt = null;
  }

  /// Ferma timer e refresh in volo e rende la sessione non più rinnovabile;
  /// ritorna le sue credenziali per la chiamata di logout al backend.
  _ClosingSession _detachSession() {
    final accessToken = _accessToken;
    final hasFreshAccessToken = _hasFreshAccessToken;
    final refreshToken = _refreshToken;
    _supersedeSession();
    _refreshToken = null;
    return (
      epoch: _epoch,
      accessToken: accessToken,
      hasFreshAccessToken: hasFreshAccessToken,
      refreshToken: refreshToken,
    );
  }

  /// Passo (1) del logout, mai bloccante. Saltato senza token valido, o se la
  /// sessione che fa logout è già stata chiusa (timeout scaduto, nuovo
  /// login): non revoca mai una sessione successiva.
  Future<void> _invalidateBackendSession(_ClosingSession closing) async {
    try {
      final accessToken = await _backendLogoutToken(closing);
      if (accessToken == null || closing.epoch != _epoch) return;
      await _api.logout(accessToken);
    } catch (error) {
      debugPrint('[SessionAuth] backend logout failed: ${error.runtimeType}');
    }
  }

  /// D-36: un access scaduto viene prima rinnovato col refresh token della
  /// sessione che fa logout. Fuori dal single-flight: un rifiuto salta la
  /// chiamata al backend invece di chiudere la sessione come `sessionExpired`;
  /// un errore transitorio ripiega sull'access precedente. Il refresh token
  /// ruotato non viene persistito: lo storage sta per essere svuotato.
  Future<String?> _backendLogoutToken(_ClosingSession closing) async {
    final refreshToken = closing.refreshToken;
    if (closing.hasFreshAccessToken || refreshToken == null) {
      return closing.accessToken;
    }
    try {
      final session = await _api.refreshSession(refreshToken);
      return session.accessToken;
    } on SessionRejected {
      return null;
    } catch (_) {
      return closing.accessToken;
    }
  }

  void _logLogoutTimeout() => debugPrint(
    '[SessionAuth] backend logout timed out, continuing local teardown',
  );

  /// Teardown D-12 senza chiamata al backend: l'access JWT è scartato subito.
  Future<void> _endSession(UnauthenticatedReason reason) async {
    _supersedeSession();
    _forgetSession();
    await _runTeardown();
    await _clearStore();
    _channel.emit(AuthUnauthenticated(reason: reason));
  }

  Future<void> _runTeardown() async {
    try {
      await _onSessionTeardown();
    } catch (error) {
      debugPrint('[SessionAuth] session teardown failed: ${error.runtimeType}');
    }
  }

  Future<void> _clearStore() async {
    try {
      await _store.clear();
    } catch (error) {
      debugPrint(
        '[SessionAuth] session store clear failed: ${error.runtimeType}',
      );
    }
  }
}

const String _networkFailureCode = 'network';

/// Sessione staccata da `logout()`. `epoch` è quella in cui il logout è in
/// corso, prima che `_endSession` la chiuda.
typedef _ClosingSession = ({
  int epoch,
  String? accessToken,
  bool hasFreshAccessToken,
  String? refreshToken,
});

const _SessionSuperseded _superseded = _SessionSuperseded();

/// Esito di un refresh appartenente a una sessione già sostituita o chiusa.
class _SessionSuperseded implements Exception {
  const _SessionSuperseded();
}
