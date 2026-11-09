import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/auth/login_challenge.dart';
import 'package:klimmeck_guide/repository/services/auth/auth.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_holder.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_provider.dart';
import 'package:klimmeck_guide/repository/services/graphql/ws_reconnect_policy.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/auth_session_fixtures.dart';
import '../../../helpers/fakes/fake_graphql_ws_server.dart';
import '../../../helpers/fakes/fake_session_backend.dart';
import '../../../helpers/fakes/in_memory_session_store.dart';

const Timeout _flowTimeout = Timeout(Duration(seconds: 20));

const LoginChallenge _challenge = LoginChallenge(
  codeVerifier: 'verifier-test',
  codeChallenge: 'challenge-test',
);

final _userSubscription = gql('''
  subscription OnUserChanged { userUpdated { id } }
''');

/// «L'ultimo login caccia l'altro» (HARDEN-06) in-process: due dispositivi
/// sullo stesso [FakeSessionBackend], socket reali di loopback. Solo
/// `test(...)`, tempo reale, nessuna attesa a tempo.
void main() {
  late FakeGraphQlWsServer server;
  late FakeSessionBackend backend;
  late Map<String, WebSocket> socketsBySession;
  late List<String?> initSessions;
  late Map<WebSocket, String> subscriptionIdsBySocket;
  late _Device deviceA;
  late _Device deviceB;

  setUp(() async {
    server = FakeGraphQlWsServer();
    await server.start();
    backend = FakeSessionBackend(user: buildTestUser());
    socketsBySession = {};
    initSessions = [];
    subscriptionIdsBySocket = {};
    server.onSubscribe = (ws, subscribe) {
      final id = subscribe['id'] as String;
      subscriptionIdsBySocket[ws] = id;
      server.emit(ws, id, _userUpdated);
    };
    server.onConnectionInit = (ws, payload) {
      final token = _bearerOf(payload);
      final sessionId = token == null
          ? null
          : backend.sessionIdOfAccessToken(token);
      initSessions.add(sessionId);
      if (sessionId == null) return true;
      socketsBySession[sessionId] = ws;
      final reason = backend.revokeReasonOf(sessionId);
      if (reason == null) return true;
      unawaited(server.closeSocket(ws, wsSessionRevokedCloseCode, reason));
      return false;
    };
    backend.onRevoked = (sessionId, reason) {
      final ws = socketsBySession[sessionId];
      if (ws == null) return;
      unawaited(server.closeSocket(ws, wsSessionRevokedCloseCode, reason));
    };
    deviceA = _Device(backend: backend, wsUrl: server.url);
    deviceB = _Device(backend: backend, wsUrl: server.url);
  });

  tearDown(() async {
    await deviceA.dispose();
    await deviceB.dispose();
    await server.stop();
  });

  WebSocket serverSocketOf(_Device device) =>
      socketsBySession[backend.sessionIdOfAccessToken(device.accessToken)]!;

  /// Barriera deterministica attraverso il server: un `next` emesso sul
  /// socket di [device] arriva alla sua subscription viva.
  Future<void> roundTrip(_Device device, Stream<QueryResult> stream) async {
    final ws = serverSocketOf(device);
    final delivered = expectLater(stream, emits(isA<QueryResult>()));
    server.emit(ws, subscriptionIdsBySocket[ws]!, _userUpdated);
    await delivered;
  }

  Future<void> expectEndedWith(
    _Device device,
    UnauthenticatedReason reason,
    Future<void> Function() revoke,
  ) async {
    final ended = expectLater(
      device.service.authStateStream,
      emitsThrough(AuthUnauthenticated(reason: reason)),
    );
    await revoke();
    await ended;
  }

  test('the second login closes the first device with replacedByNewLogin '
      '(D-06, D-09, D-12)', () async {
    await deviceA.login();
    await deviceA.openLiveSubscription();
    final socketA = serverSocketOf(deviceA);
    final clientBeforeRevocation = deviceA.holder.client.value;
    final statesBeforeRevocation = deviceA.states.length;

    await expectEndedWith(
      deviceA,
      UnauthenticatedReason.replacedByNewLogin,
      deviceB.login,
    );
    final streamB = await deviceB.openLiveSubscription();
    await socketA.done;
    await roundTrip(deviceB, streamB);

    expect(deviceA.policies.first.closures, [
      (code: wsSessionRevokedCloseCode, reason: sessionRevokedReasonNewLogin),
    ]);
    expect(deviceA.states.skip(statesBeforeRevocation), [
      const AuthUnauthenticated(
        reason: UnauthenticatedReason.replacedByNewLogin,
      ),
    ]);
    expect(deviceA.store.refreshToken, isNull);
    expect(deviceA.holder.client.value, isNot(same(clientBeforeRevocation)));
    expect(deviceB.states.last, isA<AuthAuthenticated>());
    expect(deviceB.store.refreshToken, isNotNull);
    expect(serverSocketOf(deviceB).closeCode, isNull);
  }, timeout: _flowTimeout);

  test(
    'a device offline at the revocation is closed at reconnect (D-06)',
    () async {
      await deviceA.login();
      final sessionA = backend.sessionIdOfAccessToken(deviceA.accessToken)!;
      await deviceB.login();
      expect(backend.revokeReasonOf(sessionA), sessionRevokedReasonNewLogin);

      await expectEndedWith(
        deviceA,
        UnauthenticatedReason.replacedByNewLogin,
        () async => deviceA.subscribe().listen((_) {}),
      );

      await socketsBySession[sessionA]!.done;
      expect(deviceA.policies.first.closures, [
        (code: wsSessionRevokedCloseCode, reason: sessionRevokedReasonNewLogin),
      ]);
      expect(deviceA.store.refreshToken, isNull);
      expect(deviceB.states.last, isA<AuthAuthenticated>());
    },
    timeout: _flowTimeout,
  );

  test(
    'a role change ends the session with roleChanged (D-06, D-12)',
    () async {
      await deviceA.login();
      await deviceA.openLiveSubscription();
      final socketA = serverSocketOf(deviceA);

      await expectEndedWith(
        deviceA,
        UnauthenticatedReason.roleChanged,
        () async => backend.revokeAll(sessionRevokedReasonRoleChanged),
      );

      await socketA.done;
      expect(deviceA.policies.first.closures, [
        (
          code: wsSessionRevokedCloseCode,
          reason: sessionRevokedReasonRoleChanged,
        ),
      ]);
      expect(deviceA.store.refreshToken, isNull);
    },
    timeout: _flowTimeout,
  );

  test(
    'an unknown or missing reason ends with sessionExpired (D-06, D-12)',
    () async {
      await deviceA.login();
      await deviceA.openLiveSubscription();
      final socketA = serverSocketOf(deviceA);

      await expectEndedWith(
        deviceA,
        UnauthenticatedReason.sessionExpired,
        () async => backend.revokeAll('somethingNew'),
      );

      await deviceB.login();
      await deviceB.openLiveSubscription();
      final socketB = serverSocketOf(deviceB);

      await expectEndedWith(
        deviceB,
        UnauthenticatedReason.sessionExpired,
        () async => backend.revokeAll(null),
      );

      await Future.wait([socketA.done, socketB.done]);
      expect(deviceA.policies.first.closures, [
        (code: wsSessionRevokedCloseCode, reason: 'somethingNew'),
      ]);
      expect(deviceB.policies.first.closures, [
        (code: wsSessionRevokedCloseCode, reason: ''),
      ]);
      expect(deviceA.store.refreshToken, isNull);
      expect(deviceB.store.refreshToken, isNull);
    },
    timeout: _flowTimeout,
  );

  test(
    'a replaced device never hot-loops its reconnects (D-06, D-09)',
    () async {
      await deviceA.login();
      await deviceA.openLiveSubscription();
      final sessionA = backend.sessionIdOfAccessToken(deviceA.accessToken)!;
      final revokedPolicy = deviceA.policies.single;

      await expectEndedWith(
        deviceA,
        UnauthenticatedReason.replacedByNewLogin,
        deviceB.login,
      );
      final initsAfterTeardown = initSessions.length;
      final streamB = await deviceB.openLiveSubscription();
      await revokedPolicy.nextConnectAttempt;
      await roundTrip(deviceB, streamB);

      final initsFromA = initSessions
          .skip(initsAfterTeardown)
          .where((sessionId) => sessionId == null || sessionId == sessionA);
      expect(initsFromA, isEmpty);
      expect(deviceA.policies, hasLength(2));
    },
    timeout: _flowTimeout,
  );
}

const Map<String, dynamic> _userUpdated = {
  'userUpdated': {'id': testUserId},
};

String? _bearerOf(Map<String, dynamic>? payload) {
  final header = payload?['Authorization'];
  if (header is! String || !header.startsWith('Bearer ')) return null;
  return header.substring('Bearer '.length);
}

/// Un dispositivo: servizio di sessione, store, holder GraphQL e stati.
class _Device {
  _Device({required FakeSessionBackend backend, required String wsUrl}) {
    service = SessionAuthTokenService(
      api: backend,
      store: store,
      browser: const _TicketBrowser(),
      backendBaseUrl: Uri.parse('http://127.0.0.1/'),
      onSessionTeardown: () => holder.reset(),
      now: () => testNow,
      createChallenge: () => _challenge,
    );
    holder = GraphQLClientHolder(
      connect: () {
        final policy = _RecordingWsReconnectPolicy(service);
        policies.add(policy);
        final webSocketLink = buildWebSocketLink(url: wsUrl, policy: policy);
        return (
          client: GraphQLClient(
            link: webSocketLink,
            cache: GraphQLCache(store: InMemoryStore()),
          ),
          webSocketLink: webSocketLink,
        );
      },
    );
    _recorder = service.authStateStream.listen(states.add);
  }

  final InMemorySessionStore store = InMemorySessionStore();
  final List<AuthState> states = [];
  final List<_RecordingWsReconnectPolicy> policies = [];
  late final SessionAuthTokenService service;
  late final GraphQLClientHolder holder;
  late final StreamSubscription<AuthState> _recorder;

  String get accessToken => (states.last as AuthAuthenticated).accessToken;

  Future<void> login() async {
    final authenticated = expectLater(
      service.authStateStream,
      emitsThrough(isA<AuthAuthenticated>()),
    );
    await service.login();
    await authenticated;
  }

  Stream<QueryResult> subscribe() => holder.client.value
      .subscribe(SubscriptionOptions(document: _userSubscription))
      .asBroadcastStream();

  /// Apre una subscription e attende il primo evento: il socket è vivo.
  Future<Stream<QueryResult>> openLiveSubscription() async {
    final stream = subscribe();
    await expectLater(stream, emits(isA<QueryResult>()));
    return stream;
  }

  Future<void> dispose() async {
    await _recorder.cancel();
    await holder.reset();
    service.dispose();
  }
}

/// Browser che risponde subito con il ticket di login.
class _TicketBrowser implements BrowserAuthenticator {
  const _TicketBrowser();

  @override
  Future<String> authenticate({
    required Uri startUrl,
    required String callbackScheme,
  }) async => 'klimmeck://auth?ticket=T';
}

/// Politica reale che registra le chiusure viste dal suo link e ne segnala
/// ogni tentativo di connessione.
class _RecordingWsReconnectPolicy extends WsReconnectPolicy {
  _RecordingWsReconnectPolicy(SessionAuthTokenService service)
    : super(authService: service, recovery: service);

  final List<({int? code, String? reason})> closures = [];
  Completer<void> _attempted = Completer<void>();

  /// Il prossimo `connection_init` preparato dal link (anche uno che il link
  /// già disposto poi scarta senza connettersi).
  Future<void> get nextConnectAttempt => _attempted.future;

  @override
  Future<Map<String, dynamic>> buildInitialPayload() {
    _attempted.complete();
    _attempted = Completer<void>();
    return super.buildInitialPayload();
  }

  @override
  Future<Duration?> onConnectionLost(int? code, String? reason) {
    closures.add((code: code, reason: reason));
    return super.onConnectionLost(code, reason);
  }
}
