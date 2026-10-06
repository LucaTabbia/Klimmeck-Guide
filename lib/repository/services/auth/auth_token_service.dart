import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/user.dart';

// ============================================================
// AuthState — sealed hierarchy
// ============================================================

/// Base sealed type per lo stato di autenticazione.
///
/// I consumer devono usare pattern matching (switch/when) per
/// gestire tutti e tre i sottotipi in modo esaustivo.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Stato emesso subito dopo `initialize()`, prima che il risultato
/// dell'autenticazione sia noto. I consumer mostrano uno splash
/// o loading indicator in questo stato.
final class AuthBootstrapping extends AuthState {
  const AuthBootstrapping();
}

/// Stato emesso quando l'utente è autenticato con successo.
///
/// Contiene l'utente autenticato e il token di accesso corrente.
/// Phase 1 (DevAuthTokenService): valori letti da `.env`.
/// Phase 11 (SessionAuthTokenService): sessione del backend.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user, required this.accessToken});

  /// L'utente autenticato con ruolo, twitchId e punti canale.
  final User user;

  /// Token di accesso al momento dell'emissione: i consumer usano sempre
  /// `getAccessToken()`; le rotazioni non ri-emettono lo stato.
  final String accessToken;

  @override
  List<Object?> get props => [user, accessToken];

  @override
  bool get stringify => false;
}

/// Motivo per cui l'utente non è autenticato.
enum UnauthenticatedReason {
  /// Nessuna sessione o logout dell'utente.
  signedOut,

  /// Sessione rifiutata dal backend: SignIn mostra «La sessione è scaduta,
  /// accedi di nuovo.» (D-10/D-31).
  sessionExpired,
}

/// Stato emesso quando l'utente non è autenticato (es. dopo logout
/// o sessione rifiutata dal backend). Phase 1 non lo emette mai.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.reason = UnauthenticatedReason.signedOut});

  final UnauthenticatedReason reason;

  @override
  List<Object?> get props => [reason];
}

// ============================================================
// AuthTokenService — contratto pubblico
// ============================================================

/// Contratto canonico del servizio di autenticazione.
///
/// Implementazioni:
/// - `DevAuthTokenService` (Phase 1): stub backed da `.env` per sviluppo locale.
/// - `SessionAuthTokenService` (Phase 11): sessione del backend (refresh token
///   rotante, nessun token Twitch nell'app, D-26). Sostituisce
///   `DevAuthTokenService` senza toccare i consumer (GraphQL link, dio
///   interceptor, AuthCubit).
///
/// Tutti i consumer devono dipendere da questo tipo astratto, mai dall'
/// implementazione concreta.
abstract class AuthTokenService {
  /// Bootstrap hook: chiamato una volta da `AuthCubit.start()` dopo `runApp`
  /// (D-33); non va atteso prima del primo frame.
  ///
  /// Phase 1 (Dev stub): emette immediatamente `AuthBootstrapping` →
  /// `AuthAuthenticated` con il test user letto da `.env`.
  ///
  /// Phase 11 (sessione reale): carica la sessione dal secure storage e la
  /// ripristina col backend prima di emettere `AuthAuthenticated` o
  /// `AuthUnauthenticated`.
  Future<void> initialize();

  /// Stream broadcast dello stato di autenticazione.
  ///
  /// Supporta listener multipli (SplashCubit, GraphQL auth link, dio
  /// interceptor). Non chiude automaticamente; usare `dispose()` per
  /// rilasciare le risorse quando il servizio non è più necessario.
  Stream<AuthState> get authStateStream;

  /// Ritorna il token di accesso corrente, o `null` se non disponibile.
  ///
  /// Chiamato da GraphQL auth link e dio interceptor per ogni request.
  Future<String?> getAccessToken();

  /// Avvia il flusso di login.
  ///
  /// Phase 1: no-op (con `debugPrint` in `kDebugMode`).
  /// Phase 11: apre il login Twitch mediato dal backend nel browser di
  /// sistema; può lanciare `LoginException`.
  Future<void> login();

  /// Effettua il logout dell'utente corrente.
  ///
  /// Phase 1: no-op (con `debugPrint` in `kDebugMode`).
  /// Phase 11: teardown D-12.
  Future<void> logout();

  /// Gestisce il rifiuto della sessione da parte del backend.
  ///
  /// Phase 1: no-op (con `debugPrint` in `kDebugMode`).
  /// Phase 11: teardown senza chiamata al backend ed emissione di
  /// `AuthUnauthenticated(reason: sessionExpired)`.
  Future<void> handleRevocation();

  /// Chiude lo `StreamController` interno e libera le risorse.
  ///
  /// Da chiamare nel `dispose()` del widget root o del service locator.
  /// Dopo `dispose()`, lo stream non emette ulteriori eventi.
  void dispose();
}
