# Phase 1: Dev Auth Stub - Research

**Researched:** 2026-04-14
**Domain:** Flutter service layer — stub auth contract, .env config, RepositoryProvider wiring
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Il contratto pubblico di `AuthTokenService` è quello definito nel context di Phase 11 (D-01..D-03). Phase 1 stub lo rispetta al 100%.
- **D-02:** La sostituzione Phase 1 → Phase 11 deve essere un cambio di **implementazione concreta** della classe `AuthTokenService`, non un cambio di interfaccia. Nessun consumer cambia.
- **D-03:** Role switching via `.env`: `DEV_AUTH_ROLE` abilita il test della Phase 10 Admin Panel.
- **D-04:** Niente secure storage: il token "dev" è in `.env`, già fuori dal VCS (regola CLAUDE.md §5).
- **D-05:** Flag `DEV_AUTH_ENABLED=true` in `.env` attiva lo stub. In produzione il flag è `false` e il consumer riceve l'implementazione reale (Phase 11).

### Claude's Discretion
Nessuna area di discrezionalità esplicitamente dichiarata nel CONTEXT.md di Phase 1. Tutto è determinato da D-01..D-05.

### Deferred Ideas (OUT OF SCOPE)
Tutto ciò che è out of scope in `01-CONTEXT.md §Out of scope`:
- OAuth PKCE, system browser flow, secure storage, refresh token rotation, refresh mutex
- Logout che revoca il token su Twitch, detection della revoca esterna
- Sign-in screen reale, account switching
(Vivono in Phase 11)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEV-AUTH-01 | `AuthTokenService` stub espone `Stream<AuthState>`, `Future<String?> getAccessToken()`, `Future<void> login()`, `Future<void> logout()`, `Future<void> handleRevocation()` — stessa public surface di Phase 11 | Contratto canonico in `11-CONTEXT.md` D-02; struttura `AuthState` sealed da definire qui |
| DEV-AUTH-02 | Legge identità e token da `.env` (`DEV_AUTH_ACCESS_TOKEN`, `DEV_AUTH_USER_ID`, `DEV_AUTH_TWITCH_ID`, `DEV_AUTH_ROLE`) | `flutter_dotenv` 6.0.0 disponibile; pattern `String.fromEnvironment` già in uso in `EnvConfig` ma non adatto per segreti runtime — dotenv è la via |
| DEV-AUTH-03 | Supporta role switching via `DEV_AUTH_ROLE` (`guard | adventurer | innkeeper`) | `RoleType` enum già presente in `lib/models/enums/role_type.dart`; parsing diretto con `RoleType.values.byName()` |
| DEV-AUTH-04 | `login()` e `logout()` no-op con warning log in debug only; nessuna sign-in screen costruita | `kDebugMode` da `package:flutter/foundation.dart`; `debugPrint` sufficiente |
| DEV-AUTH-05 | `AuthTokenService` esposto via `RepositoryProvider` sopra il `BlocProvider` tree; stesso wiring di Phase 11 | Pattern attuale: `MultiBlocProvider` in `main.dart`; `RepositoryProvider` (da `flutter_bloc`) deve essere aggiunto sopra `MultiBlocProvider` |
</phase_requirements>

---

## Summary

Phase 1 è pura infrastruttura di sviluppo: un servizio auth stub che espone esattamente il contratto che Phase 11 consegnerà, backed da variabili `.env` invece che da OAuth Twitch. Nessuna UI da costruire, nessun flusso visibile all'utente.

Il lavoro si articola in quattro aree: (1) definire i tipi `AuthState` (sealed class) e `AuthTokenService` (abstract class o classe concreta stub), (2) implementare `DevAuthTokenService` che legge da `flutter_dotenv`, (3) wirare il servizio via `RepositoryProvider` in `main.dart` sopra l'attuale `MultiBlocProvider`, (4) scrivere test unitari e cubit/service unit test prima dell'implementazione (TDD).

Il vincolo critico è la fedeltà del contratto: qualunque cosa Phase 1 esponga, Phase 11 deve poter sostituire con zero modifiche ai consumer downstream (GraphQL client, dio interceptor, AuthCubit, SplashCubit).

**Primary recommendation:** Definire `AuthState` come sealed class con tre sottotipi (`Bootstrapping`, `Authenticated`, `Unauthenticated`) e `AuthTokenService` come abstract class in `lib/repository/services/auth/`. Implementare `DevAuthTokenService extends AuthTokenService` che al cold start legge `.env` e emette immediatamente `Authenticated`. Wirare in `main.dart` con `RepositoryProvider<AuthTokenService>` sopra `MultiBlocProvider`. Aggiungere `flutter_dotenv` e `mocktail`/`bloc_test` in `pubspec.yaml`.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_dotenv` | 6.0.0 | Carica `.env` a runtime | Standard de facto per gestione env vars in Flutter dev; già usato nella community Klimmeck; evita `String.fromEnvironment` che richiede `--dart-define` al build |
| `flutter_bloc` | 9.1.1 (già in pubspec) | `RepositoryProvider` per wiring | Già in uso nel progetto; `RepositoryProvider` è parte di `flutter_bloc` |
| `equatable` | 2.0.0 (già in pubspec) | `AuthState` comparability | Già in uso |

[VERIFIED: flutter pub add --dry-run su macchina locale — flutter_dotenv 6.0.0 disponibile]
[VERIFIED: pubspec.yaml — flutter_bloc 9.1.1 e equatable 2.0.0 già presenti]

### Dev Dependencies aggiuntive

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `bloc_test` | 10.0.0 | Test sequenze stato Cubit | Obbligatorio per ogni Cubit non triviale (regola testing.md) |
| `mocktail` | 1.0.5 | Mock del service layer | Preferita dal progetto (testing.md) |

[VERIFIED: flutter pub add --dry-run — bloc_test 10.0.0, mocktail 1.0.5 disponibili]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `flutter_dotenv` | `String.fromEnvironment` (già in `EnvConfig`) | `fromEnvironment` richiede `--dart-define` a ogni `flutter run`, è scomodo per token lunghi come access token Twitch dev. `flutter_dotenv` carica un file `.env` ignorato da git, più ergonomico per segreti locali. |
| Sealed class `AuthState` | Enum semplice | L'enum non porta payload (es. `User` in `Authenticated`); sealed class è il pattern già usato in tutto il progetto per stati Cubit |

**Installation:**
```bash
# Runtime
flutter pub add flutter_dotenv

# Dev
flutter pub add --dev bloc_test mocktail
```

---

## Architecture Patterns

### Recommended Project Structure

```
lib/
├── repository/
│   └── services/
│       └── auth/
│           ├── auth_token_service.dart       # abstract class + AuthState sealed
│           └── dev_auth_token_service.dart   # implementazione stub .env
├── config/
│   └── env_config.dart                       # aggiungere DEV_AUTH_ENABLED flag
test/
└── repository/
    └── services/
        └── auth/
            └── dev_auth_token_service_test.dart
```

**Nota di collocazione:** `lib/repository/services/auth/` segue il pattern di `lib/repository/services/graphql/` (VERIFIED: codebase esistente). La regola di architettura `UI → BLoC → Repository → Service` impone che `AuthTokenService` stia nel layer service.

### Pattern 1: Contratto AuthTokenService (abstract class)

**What:** Abstract class che definisce la public surface condivisa tra stub (Phase 1) e implementazione reale (Phase 11).
**When to use:** Sempre — è la chiave del D-02 (sostituzione senza toccare i consumer).

```dart
// lib/repository/services/auth/auth_token_service.dart
// Source: 11-CONTEXT.md D-02 — contratto canonico

import 'package:klimmeck_guide/models/user.dart';

/// Stato di autenticazione emesso da AuthTokenService.
sealed class AuthState {
  const AuthState();
}

/// Bootstrap in corso (cold start, validazione token, ecc.)
class AuthBootstrapping extends AuthState {
  const AuthBootstrapping();
}

/// Sessione attiva: token valido, utente noto.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user, required this.accessToken});
  final User user;
  final String accessToken;
}

/// Nessuna sessione attiva.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Contratto pubblico condiviso tra Phase 1 (stub) e Phase 11 (OAuth reale).
/// Phase 11 sostituisce l'implementazione concreta; i consumer non cambiano.
abstract class AuthTokenService {
  /// Stream dello stato di autenticazione. Non completa mai (broadcast stream).
  Stream<AuthState> get authStateStream;

  /// Restituisce l'access token corrente valido, oppure null se non autenticato.
  /// Phase 11: esegue refresh silenzioso se il token è near-expiry.
  /// Phase 1 stub: restituisce il token da .env, niente refresh.
  Future<String?> getAccessToken();

  /// Avvia il flusso di login.
  /// Phase 11: apre il browser di sistema con PKCE.
  /// Phase 1 stub: no-op con warning in debug.
  Future<void> login();

  /// Esegue il logout completo.
  /// Phase 11: revoca token Twitch, clear storage, teardown GraphQL.
  /// Phase 1 stub: no-op con warning in debug.
  Future<void> logout();

  /// Gestisce la revoca esterna del token.
  /// Phase 11: naviga a sign-in con messaggio neutro.
  /// Phase 1 stub: no-op.
  Future<void> handleRevocation();

  /// Cleanup risorse (stream controller).
  void dispose();
}
```

[CITED: 11-CONTEXT.md §D-02 — public surface canonica]

### Pattern 2: DevAuthTokenService (implementazione stub)

**What:** Implementazione concreta che al cold start carica `.env` e emette immediatamente `AuthAuthenticated`.
**When to use:** Quando `DEV_AUTH_ENABLED=true` in `.env`.

```dart
// lib/repository/services/auth/dev_auth_token_service.dart
// [ASSUMED] — pattern derivato da flutter_dotenv docs e convenzioni progetto

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'auth_token_service.dart';

class DevAuthTokenService extends AuthTokenService {
  DevAuthTokenService() : _controller = StreamController<AuthState>.broadcast();

  final StreamController<AuthState> _controller;

  @override
  Stream<AuthState> get authStateStream => _controller.stream;

  Future<void> initialize() async {
    _controller.add(const AuthBootstrapping());
    final accessToken = dotenv.env['DEV_AUTH_ACCESS_TOKEN'] ?? '';
    final userId = dotenv.env['DEV_AUTH_USER_ID'] ?? 'dev-user';
    final twitchId = dotenv.env['DEV_AUTH_TWITCH_ID'] ?? 'dev-twitch';
    final roleRaw = dotenv.env['DEV_AUTH_ROLE'] ?? 'adventurer';
    final role = RoleType.values.byName(roleRaw);

    final user = User(
      id: userId,
      twitchId: twitchId,
      twitchPoints: 0,
      currentCharacter: null,
      role: role,
    );
    _controller.add(AuthAuthenticated(user: user, accessToken: accessToken));
  }

  @override
  Future<String?> getAccessToken() async {
    return dotenv.env['DEV_AUTH_ACCESS_TOKEN'];
  }

  @override
  Future<void> login() async {
    if (kDebugMode) {
      debugPrint('[DevAuth] login() called — no-op in dev stub');
    }
  }

  @override
  Future<void> logout() async {
    if (kDebugMode) {
      debugPrint('[DevAuth] logout() called — no-op in dev stub');
    }
  }

  @override
  Future<void> handleRevocation() async {
    if (kDebugMode) {
      debugPrint('[DevAuth] handleRevocation() called — no-op in dev stub');
    }
  }

  @override
  void dispose() {
    _controller.close();
  }
}
```

[ASSUMED — pattern derivato da flutter_dotenv 6.0.0 API e convenzioni del progetto]

### Pattern 3: Wiring in main.dart con RepositoryProvider

**What:** `RepositoryProvider<AuthTokenService>` posizionato sopra `MultiBlocProvider` in `main.dart`.
**When to use:** Sempre — è il requisito DEV-AUTH-05 e D-01 di Phase 11.

```dart
// lib/main.dart — modifica al build() di KlimmeckGuideApp
// Source: 11-CONTEXT.md D-01 e D-03

// Prima di runApp, inizializzare dotenv:
await dotenv.load(fileName: '.env');
final devAuthEnabled = dotenv.env['DEV_AUTH_ENABLED'] == 'true';

// Nel widget tree:
RepositoryProvider<AuthTokenService>(
  create: (_) {
    if (devAuthEnabled) {
      final svc = DevAuthTokenService();
      svc.initialize(); // non si blocca il frame
      return svc;
    }
    // Phase 11: return RealAuthTokenService(...)
    throw UnimplementedError('RealAuthTokenService not yet implemented');
  },
  child: MultiBlocProvider(
    providers: [ /* provider esistenti */ ],
    child: /* widget tree esistente */,
  ),
)
```

[ASSUMED — pattern derivato da documentazione flutter_bloc RepositoryProvider + codebase main.dart esaminata]

### Pattern 4: DEV_AUTH_ENABLED flag in EnvConfig

**What:** Lettura centralizzata del flag via `EnvConfig` per consistency con il pattern esistente.

```dart
// lib/config/env_config.dart — aggiunta
static bool get devAuthEnabled =>
    dotenv.env['DEV_AUTH_ENABLED'] == 'true';
```

[ASSUMED]

### Anti-Patterns to Avoid

- **`String.fromEnvironment` per token dev:** non funziona senza `--dart-define` e non è adatto a segreti runtime. Usare `flutter_dotenv`.
- **Singleton globale per `AuthTokenService`:** vietato (architecture.md — no service locator, no static globals). Solo `RepositoryProvider`.
- **`BlocProvider` al posto di `RepositoryProvider`:** `AuthTokenService` non è un Cubit; `RepositoryProvider` è il contenitore corretto per servizi non-Cubit.
- **`initialize()` awaited in `main()` bloccando il frame:** chiamare `initialize()` senza await nel `create` del provider, oppure awaited in `main()` prima di `runApp` — la scelta impatta il test della regola DEV-AUTH (niente splash prolungato). Raccomandato: chiamare prima di `runApp`.
- **Payload `AuthAuthenticated` senza `User`:** il contratto deve portare il `User` nel `Authenticated` state per non costringere i consumer a fare una query separata per ottenere l'identità.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Caricamento `.env` file | Parser manuale di file di testo | `flutter_dotenv` | Gestisce quoting, commenti, escaping, file multipli, test helpers |
| Broadcast stream per stati auth | `StreamController` nudo condiviso globalmente | `StreamController.broadcast()` dentro il service + dispose() | Stream broadcast permette multipli listener (GraphQL interceptor + SplashCubit); il dispose impedisce memory leak |
| Mock di `AuthTokenService` nei test | Classe mock scritta a mano | `mocktail` `Mock` + `when` | Mocktail già scelto dal progetto (testing.md) |

---

## Runtime State Inventory

> Phase 1 è greenfield (nessun rename/refactor). Nessun runtime state da migrare.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Nessuno — Phase 1 non persiste nulla | None |
| Live service config | Nessuno — nessun servizio esterno configurato | None |
| OS-registered state | Nessuno | None |
| Secrets/env vars | `.env` da creare ex-novo con 5 chiavi DEV_AUTH_* | Creare `.env` (già in .gitignore) |
| Build artifacts | Nessuno | None |

---

## Common Pitfalls

### Pitfall 1: `dotenv.load()` non awaited prima di `runApp`

**What goes wrong:** `dotenv.env['DEV_AUTH_ACCESS_TOKEN']` restituisce `null` perché il file non è ancora stato caricato quando `DevAuthTokenService.initialize()` viene invocato.
**Why it happens:** `dotenv.load()` è asincrono; se `main()` non è `async` o non fa `await`, le variabili non sono disponibili al primo frame.
**How to avoid:** `main()` deve essere `async`; `await dotenv.load(fileName: '.env')` deve precedere `runApp`. Il progetto ha già `Future<void> main() async` — [VERIFIED: main.dart].
**Warning signs:** `getAccessToken()` restituisce `null`, lo stream rimane su `AuthBootstrapping`.

### Pitfall 2: Il contratto `AuthState` non porta payload sufficiente

**What goes wrong:** `AuthAuthenticated` espone solo il token senza il `User`; i consumer downstream devono fare una query separata per ottenere `userId`, `role`, ecc. Phase 11 poi lo aggiunge e il contratto cambia.
**Why it happens:** Si progetta il minimo viable senza pensare ai consumer downstream.
**How to avoid:** Includere `User` e `accessToken` in `AuthAuthenticated` fin dalla Phase 1. Tutti i consumer possono leggerlo senza query aggiuntive.
**Warning signs:** `SplashCubit` o `CharacterCubit` fan query a `/me` immediatamente dopo l'auth — sintomo che lo stato non porta dati sufficienti.

### Pitfall 3: `RepositoryProvider` posizionato sotto `MultiBlocProvider`

**What goes wrong:** I Cubit che dipendono da `AuthTokenService` non trovano il provider nell'albero e generano `ProviderNotFoundException` a runtime.
**Why it happens:** L'ordine nel widget tree conta; `RepositoryProvider` deve essere antenato di `MultiBlocProvider`.
**How to avoid:** In `main.dart`, `RepositoryProvider<AuthTokenService>` wrappa `MultiBlocProvider`.
**Warning signs:** `context.read<AuthTokenService>()` lancia eccezione nei test o in debug run.

### Pitfall 4: `RoleType.values.byName()` lancia su valore non riconosciuto

**What goes wrong:** Se `DEV_AUTH_ROLE` ha un typo nel `.env` (es. `Adventurer` con maiuscola), `byName()` lancia `ArgumentError`.
**Why it happens:** `byName()` è case-sensitive.
**How to avoid:** Normalizzare con `.toLowerCase()` prima di passare a `byName()`. Aggiungere fallback a `RoleType.adventurer` se il valore non è riconosciuto (con warning log).

### Pitfall 5: Stream non closed su dispose()

**What goes wrong:** Memory leak se il widget tree viene rebuilt o in test. Il `StreamController` non viene mai chiuso.
**Why it happens:** `dispose()` non viene chiamato o viene dimenticato.
**How to avoid:** Implementare `dispose()` in `AuthTokenService` abstract class come metodo obbligatorio. Il `RepositoryProvider` in `flutter_bloc` chiama automaticamente `dispose()` se il valore implementa `Closeable` — ma `AuthTokenService` è una classe custom, non `Cubit`. Chiamare `dispose()` manualmente in `RepositoryProvider.dispose` callback oppure implementare `Closeable`.

---

## Code Examples

### flutter_dotenv: load e read

```dart
// Source: flutter_dotenv 6.0.0 README (pub.dev)
// In main():
await dotenv.load(fileName: '.env');

// In DevAuthTokenService:
final token = dotenv.env['DEV_AUTH_ACCESS_TOKEN'] ?? '';
```

[ASSUMED — pattern standard da flutter_dotenv docs, non verificato via Context7 in questa sessione]

### RepositoryProvider con dispose callback

```dart
// Source: flutter_bloc docs — RepositoryProvider
RepositoryProvider<AuthTokenService>(
  create: (_) => DevAuthTokenService()..initialize(),
  dispose: (svc) => svc.dispose(),
  child: child,
)
```

[ASSUMED]

### Test con mocktail di AuthTokenService

```dart
// Source: pattern da docs/rules/testing.md
class MockAuthTokenService extends Mock implements AuthTokenService {}

void main() {
  late MockAuthTokenService mockAuth;

  setUp(() {
    mockAuth = MockAuthTokenService();
    when(() => mockAuth.getAccessToken()).thenAnswer((_) async => 'test-token');
    when(() => mockAuth.authStateStream).thenAnswer(
      (_) => Stream.value(AuthAuthenticated(user: testUser, accessToken: 'test-token')),
    );
  });
}
```

[ASSUMED — pattern mocktail standard + testing.md]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `String.fromEnvironment` per tutte le config | `flutter_dotenv` per segreti dev | Pattern scelto in Phase 1 | Token Twitch dev non esposto in `flutter run` command line |
| `SignInCubit` con dipendenza da `KlimmeckGraphQl` | `AuthTokenService` astratto con `RepositoryProvider` | Phase 1 → Phase 11 | Separation of concerns: auth non dipende da GraphQL; GraphQL dipende da auth |

**Stato attuale della codebase da considerare:**

- `SplashCubit` attuale esegue il fetch delle immagini Cloudinary e poi naviga direttamente a `mainScreenRoute()` senza nessuna check auth [VERIFIED: splash_cubit.dart + splash_screen.dart]. Phase 1 deve integrare la check auth **nella splash esistente** senza rimuovere il flusso immagini, oppure aggiungere un auth gate separato prima della splash. Decisione da prendere nel plan.
- `SignInCubit` è attualmente un placeholder quasi vuoto con dipendenza da `KlimmeckGraphQl` [VERIFIED: sign_in_cubit.dart]. Non viene toccato da Phase 1 (DEV-AUTH-04: nessun sign-in screen).
- `main.dart` usa `MultiBlocProvider` direttamente sotto `GraphQLProvider` [VERIFIED: main.dart]. Il `RepositoryProvider<AuthTokenService>` deve inserirsi tra `GraphQLProvider` e `MultiBlocProvider`.
- `EnvConfig` usa `String.fromEnvironment` con `const` [VERIFIED: env_config.dart]. Non può essere usato per `flutter_dotenv` (che è runtime, non compile-time). Il flag `DEV_AUTH_ENABLED` deve essere letto da `dotenv.env`, non da `const String.fromEnvironment`.

---

## Open Questions

1. **SplashCubit: integrare auth check o usare AuthGate separato?**
   - Cosa sappiamo: `SplashCubit` attualmente fa solo cache immagini e poi naviga a main. Phase 11 (D-17) prevede che la splash esegua la validate Twitch come **prima azione**. Phase 1 stub emette `Authenticated` immediatamente — non c'è quasi nulla da integrare.
   - Gap: deve `SplashCubit` diventare il consumer di `authStateStream` già in Phase 1, preparando il terreno per Phase 11? Oppure Phase 1 aggiunge solo il wiring del service e lascia `SplashCubit` invariato (naviga sempre a main)?
   - Raccomandazione: In Phase 1, fare in modo che `SplashScreen` legga `authStateStream` da `RepositoryProvider` e navighi a `mainScreen` solo se `Authenticated`. Questo prepara l'hook per Phase 11 senza richiedere rework. Il planner deve decidere se questo rientra in scope o se è una semplificazione (dato che lo stub emette `Authenticated` immediatamente, il comportamento visibile è invariato).

2. **`dispose()` di `AuthTokenService` nel RepositoryProvider**
   - Cosa sappiamo: `flutter_bloc` `RepositoryProvider` ha un parametro `dispose` opzionale.
   - Gap: se viene usato `RepositoryProvider(dispose: (svc) => svc.dispose())`, funziona correttamente; ma il tipo `AuthTokenService` non è un `Cubit`, quindi l'auto-dispose di flutter_bloc non scatta automaticamente.
   - Raccomandazione: usare il parametro `dispose:` esplicito nel `RepositoryProvider`.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `flutter_dotenv` pkg | DEV-AUTH-02 | Da aggiungere | 6.0.0 | — (nessuna alternativa accettabile, vedi Don't Hand-Roll) |
| `bloc_test` pkg | Test TDD | Da aggiungere | 10.0.0 | — |
| `mocktail` pkg | Test TDD | Da aggiungere | 1.0.5 | — |
| Dart SDK | Tutto | ✓ | ^3.8.1 | — |
| Flutter SDK | Tutto | ✓ | (ambiente locale) | — |

**Missing dependencies con no fallback:**
- Nessuna (tutti aggiungibili via `flutter pub add`)

**Note:** `firebase_messaging`, `firebase_auth`, `firebase_core` sono in `pubspec.yaml` ma commentati/non inizializzati (`//await Firebase.initializeApp()` in `main.dart`). Phase 1 NON deve sbloccare quella inizializzazione.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK, già presente) + `bloc_test` 10.0.0 (da aggiungere) + `mocktail` 1.0.5 (da aggiungere) |
| Config file | nessuno — flutter test rileva automaticamente `test/` |
| Quick run command | `flutter test test/repository/services/auth/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Esiste? |
|--------|----------|-----------|-------------------|-------------|
| DEV-AUTH-01 | `AuthTokenService` ha tutti e 5 i metodi del contratto + `AuthState` sealed con 3 sottotipi | Unit (Dart puro) | `flutter test test/repository/services/auth/auth_token_service_contract_test.dart` | ❌ Wave 0 |
| DEV-AUTH-02 | `DevAuthTokenService.initialize()` legge da `.env` e emette `AuthAuthenticated` con token/user corretti | Unit (DevAuthTokenService) | `flutter test test/repository/services/auth/dev_auth_token_service_test.dart` | ❌ Wave 0 |
| DEV-AUTH-03 | `DEV_AUTH_ROLE=innkeeper` produce `AuthAuthenticated.user.role == RoleType.innkeeper`; idem guard e adventurer | Unit (DevAuthTokenService) | stessa file sopra, test parametrico sui 3 ruoli | ❌ Wave 0 |
| DEV-AUTH-04 | `login()` e `logout()` non lanciano eccezioni e non emettono nuovi stati | Unit (DevAuthTokenService) | stessa file sopra | ❌ Wave 0 |
| DEV-AUTH-05 | `RepositoryProvider<AuthTokenService>` è accessibile nell'albero; `context.read<AuthTokenService>()` non lancia | Widget smoke test su `KlimmeckGuideApp` | `flutter test test/app_provider_test.dart` | ❌ Wave 0 |

**Test di conformità contratto (DEV-AUTH-01 critico):**

Il test più importante per garantire la non-regressione quando Phase 11 atterra è un test che verifica che l'interfaccia pubblica di `DevAuthTokenService` sia identica al contratto atteso. Questo può essere fatto semplicemente con:

```dart
// test/repository/services/auth/auth_token_service_contract_test.dart
// Verifica statica: se il contratto cambia in Phase 11, questo file non compila
void main() {
  test('DevAuthTokenService implements AuthTokenService contract', () {
    final AuthTokenService svc = DevAuthTokenService(); // deve compilare
    expect(svc, isA<AuthTokenService>());
    expect(svc.authStateStream, isA<Stream<AuthState>>());
  });
}
```

Un diff dell'interfaccia pubblica di `AuthTokenService` tra Phase 1 e Phase 11 si ottiene semplicemente confrontando `lib/repository/services/auth/auth_token_service.dart` — se Phase 11 non tocca quel file (solo `DevAuthTokenService` viene sostituito), il contratto è invariato per costruzione.

### Sample Rate

- **Per task commit:** `flutter test test/repository/services/auth/`
- **Per wave merge:** `flutter test && flutter analyze`
- **Phase gate:** `flutter test` full suite verde + `flutter analyze` pulito prima di PR

### Wave 0 Gaps

- [ ] `test/repository/services/auth/auth_token_service_contract_test.dart` — copre DEV-AUTH-01
- [ ] `test/repository/services/auth/dev_auth_token_service_test.dart` — copre DEV-AUTH-02, DEV-AUTH-03, DEV-AUTH-04
- [ ] `test/app_provider_test.dart` — copre DEV-AUTH-05 (widget smoke test `RepositoryProvider`)
- [ ] `test/helpers/fixtures/dev_auth_env.dart` — fixture `.env` mock per i test (evita dipendenza da file `.env` reale)
- [ ] Framework install: `flutter pub add --dev bloc_test mocktail`
- [ ] Runtime dep: `flutter pub add flutter_dotenv`

---

## Security Domain

Phase 1 è un dev stub. `security_enforcement` non è esplicitamente configurato nel progetto. Le note seguenti si applicano:

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No (stub, non autentica realmente) | N/A in Phase 1 |
| V3 Session Management | No | N/A in Phase 1 |
| V4 Access Control | Parziale (DEV-AUTH-03: role switching) | `RoleType.values.byName()` — nessuna logica di enforcement in Phase 1 |
| V5 Input Validation | Basso rischio | Normalizzare `DEV_AUTH_ROLE` con `.toLowerCase()` + fallback |
| V6 Cryptography | No | Token in `.env`, niente crypto in Phase 1 |

### Security Notes Specifiche per Phase 1

- **`.env` non in VCS:** regola CLAUDE.md §5 invalicabile. Il planner deve aggiungere `.env` al `.gitignore` se non già presente, e creare `.env.example` con placeholder.
- **Token dev mai in `EnvConfig` come const:** `String.fromEnvironment` risolve a compile time e il valore appare negli artefatti di build. `flutter_dotenv` è runtime-only.
- **No `kReleaseMode` bypass:** `DevAuthTokenService` non deve mai essere istanziato in release builds. Il flag `DEV_AUTH_ENABLED=true` in `.env` non viene incluso nel bundle di release (`.env` non è un asset Flutter di default — deve essere aggiunto in `pubspec.yaml` solo per dev, oppure la factory in `main.dart` deve avere guardia esplicita).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `flutter_dotenv` 6.0.0 API: `dotenv.env['KEY']` e `dotenv.load(fileName: '.env')` | Standard Stack, Code Examples | API breaking change — verificare README su pub.dev prima di scrivere il codice |
| A2 | `RepositoryProvider(dispose: ...)` in flutter_bloc 9.1.1 accetta una callback `dispose` | Architecture Patterns | Se l'API è diversa, il dispose va gestito manualmente in `main.dart` |
| A3 | `DevAuthTokenService` con `StreamController.broadcast()` è sufficiente senza hot-reload complications | Architecture Patterns | In hot-reload il controller potrebbe non essere re-inizializzato — da testare in dev |
| A4 | `.env` non viene bundlato automaticamente da Flutter — deve essere aggiunto in `pubspec.yaml flutter.assets` per essere disponibile a `dotenv.load()` | Standard Stack | Se non aggiunto agli assets, `dotenv.load()` fallisce silenziosamente o lancia |
| A5 | Phase 11 non tocca `auth_token_service.dart` (abstract class + AuthState) — sostituisce solo `dev_auth_token_service.dart` | Don't Hand-Roll, Validation | Se Phase 11 modifica il contratto, i consumer cambiano — invalidando D-02 |

**Nota su A4 (critica):** `flutter_dotenv` richiede che `.env` sia dichiarato negli assets in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - .env
```
Il file `.env` reale è in `.gitignore`; il file `.env.example` può essere in VCS.

---

## Project Constraints (from CLAUDE.md)

Direttive operative attive per Phase 1:

| Direttiva | Impatto su Phase 1 |
|-----------|-------------------|
| No UI chrome fuori utility screens | Phase 1 non costruisce UI — N/A |
| No loading bloccanti in sessione attiva | `initialize()` non deve bloccare il frame; emettere `Bootstrapping` poi `Authenticated` |
| Branch + PR per ogni fase GSD | Branch `feat/01-dev-auth-stub` off `develop`, PR target `develop` |
| Backend è fonte di verità | N/A per Phase 1 (nessuna chiamata backend) |
| Nessun secret in repo | `.env` fuori da VCS; creare `.env.example` in VCS |
| TDD (Red → Green → Refactor) | Tutti i test scritti prima dell'implementazione |
| Clean Code + SoC | `DevAuthTokenService` non dipende da Flutter, solo da Dart + dotenv |
| Commit scope: `feat(phase-1):` | Vedi feedback_commit_phase_scope.md |
| Niente Co-Authored-By nei commit | Vedi feedback_no_coauthored_by.md |

---

## Sources

### Primary (HIGH confidence)
- `11-CONTEXT.md` D-01..D-03 — contratto canonico `AuthTokenService`
- `01-CONTEXT.md` D-01..D-05 — decisioni locked Phase 1
- `lib/main.dart` [VERIFIED: letto intero] — struttura provider tree esistente
- `lib/repository/services/graphql/graphql_client_provider.dart` [VERIFIED: letto] — pattern service layer
- `lib/models/user.dart` + `lib/models/enums/role_type.dart` [VERIFIED: letti] — modelli esistenti
- `lib/config/env_config.dart` [VERIFIED: letto] — pattern config esistente
- `pubspec.yaml` [VERIFIED: letto] — dipendenze esistenti
- `docs/rules/architecture.md`, `docs/rules/testing.md`, `docs/rules/state-management.md` [VERIFIED: letti]
- `flutter pub add --dry-run` [VERIFIED: eseguito] — flutter_dotenv 6.0.0, bloc_test 10.0.0, mocktail 1.0.5

### Secondary (MEDIUM confidence)
- flutter_dotenv pub.dev pattern (assets in pubspec.yaml) — standard documentato

### Tertiary (LOW confidence)
- `RepositoryProvider(dispose:)` API esatta in flutter_bloc 9.1.1 — non verificata via Context7
- Pattern `StreamController.broadcast()` con hot-reload in Flutter dev

---

## Metadata

**Confidence breakdown:**
- Standard Stack: HIGH — versioni verificate via `flutter pub add --dry-run`
- Architecture: HIGH — basata su codebase reale esaminata + contratto canonico in 11-CONTEXT.md
- Pitfalls: MEDIUM — derivati da esperienza con flutter_dotenv e flutter_bloc; A4 (assets pubspec) è critica e verificata da documentazione standard
- Test map: HIGH — basata su requirements espliciti DEV-AUTH-01..05 e regole testing.md

**Research date:** 2026-04-14
**Valid until:** 2026-05-14 (stack stabile; flutter_dotenv, bloc_test, mocktail sono librerie mature)
