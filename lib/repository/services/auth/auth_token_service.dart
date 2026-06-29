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
/// Phase 11 (OAuthTokenService): token validato contro Twitch.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user, required this.accessToken});

  /// L'utente autenticato con ruolo, twitchId e punti canale.
  final User user;

  /// Token di accesso OAuth (o stub in Phase 1). Usato da GraphQL
  /// auth link e dio interceptor per costruire l'header `Authorization`.
  final String accessToken;

  @override
  List<Object?> get props => [user, accessToken];
}

/// Stato emesso quando l'utente non è autenticato (es. dopo logout
/// o revoca del token). Phase 1 non lo emette mai; sarà utilizzato
/// pienamente da Phase 11.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

// ============================================================
// AuthTokenService — contratto pubblico
// ============================================================

/// Contratto canonico del servizio di autenticazione.
///
/// Implementazioni:
/// - `DevAuthTokenService` (Phase 1): stub backed da `.env` per sviluppo locale.
/// - `OAuthTokenService` (Phase 11): OAuth PKCE Twitch con secure storage e
///   refresh automatico. Sostituisce `DevAuthTokenService` senza toccare i
///   consumer (GraphQL link, dio interceptor, AuthCubit).
///
/// Tutti i consumer devono dipendere da questo tipo astratto, mai dall'
/// implementazione concreta.
abstract class AuthTokenService {
  /// Bootstrap hook. DEVE essere chiamato esattamente una volta da `main.dart`
  /// tramite `await authTokenService.initialize()` (tipo astratto, NO
  /// type-check `is DevAuthTokenService`) prima di `runApp`.
  ///
  /// Phase 1 (Dev stub): emette immediatamente `AuthBootstrapping` →
  /// `AuthAuthenticated` con il test user letto da `.env`.
  ///
  /// Phase 11 (OAuth reale): carica token da secure storage e valida contro
  /// Twitch prima di emettere `AuthAuthenticated` o `AuthUnauthenticated`.
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
  /// Phase 11: apre il browser OAuth PKCE Twitch.
  Future<void> login();

  /// Effettua il logout dell'utente corrente.
  ///
  /// Phase 1: no-op (con `debugPrint` in `kDebugMode`).
  /// Phase 11: revoca il token su Twitch e pulisce il secure storage.
  Future<void> logout();

  /// Gestisce la revoca esterna del token (es. webhook Twitch).
  ///
  /// Phase 1: no-op (con `debugPrint` in `kDebugMode`).
  /// Phase 11: invalida la sessione locale e transiziona a `AuthUnauthenticated`.
  Future<void> handleRevocation();

  /// Chiude lo `StreamController` interno e libera le risorse.
  ///
  /// Da chiamare nel `dispose()` del widget root o del service locator.
  /// Dopo `dispose()`, lo stream non emette ulteriori eventi.
  void dispose();
}
