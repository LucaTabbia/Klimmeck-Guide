import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/auth/auth_session.dart';
import 'package:klimmeck_guide/repository/services/auth/auth.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_holder.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_provider.dart';
import 'package:klimmeck_guide/repository/services/graphql/ws_reconnect_policy.dart';
import 'package:klimmeck_guide/repository/storage/session_store.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_session_fixtures.dart';
import '../../../helpers/fakes/fake_graphql_ws_server.dart';
import '../../../helpers/fakes/in_memory_session_store.dart';
import '../../../helpers/mocks.dart';

const Timeout _flowTimeout = Timeout(Duration(seconds: 20));

final AuthSession _session = buildAuthSession(refreshToken: 'r2');

final _userSubscription = gql('''
  subscription OnUserChanged { userUpdated { id } }
''');

/// Logout atomico end to end sul socket reale di loopback (HARDEN-03):
/// solo `test(...)` (socket reale), tempo reale, nessuna attesa a tempo.
void main() {
  late FakeGraphQlWsServer server;
  late List<String> events;
  late MockBackendAuthApi api;
  late MockPushSessionCleanup pushCleanup;
  late SessionAuthTokenService service;
  late GraphQLClientHolder holder;
  late AuthCubit cubit;
  late StreamSubscription<AuthState> stateRecorder;

  setUp(() async {
    server = FakeGraphQlWsServer();
    await server.start();
    server.onSubscribe = (ws, subscribe) =>
        server.emit(ws, subscribe['id'] as String, {
          'userUpdated': {'id': 'u1'},
        });
    events = [];
    api = MockBackendAuthApi();
    when(() => api.refreshSession('r1')).thenAnswer((_) async => _session);
    when(() => api.logout(any())).thenAnswer((invocation) async {
      events.add('api.logout:${invocation.positionalArguments.single}');
    });
    pushCleanup = MockPushSessionCleanup();
    when(() => pushCleanup.unregister()).thenAnswer((_) async {
      events.add('push.unregister');
    });
    void recordCloseSent(void _) => events.add('socket.close.sent');
    service = SessionAuthTokenService(
      api: api,
      store: _RecordingSessionStore(
        InMemorySessionStore(refreshToken: 'r1'),
        events,
      ),
      browser: MockBrowserAuthenticator(),
      backendBaseUrl: Uri.parse('http://backend.test/'),
      onSessionTeardown: () => holder.reset().then(recordCloseSent),
      now: () => testNow,
    );
    holder = GraphQLClientHolder(
      connect: () {
        final webSocketLink = buildWebSocketLink(
          url: server.url,
          policy: WsReconnectPolicy(authService: service, recovery: service),
        );
        return (
          client: GraphQLClient(
            link: webSocketLink,
            cache: GraphQLCache(store: InMemoryStore()),
          ),
          webSocketLink: webSocketLink,
        );
      },
    );
    stateRecorder = service.authStateStream.listen((state) {
      if (state is! AuthUnauthenticated) return;
      events.add('state:${state.reason.name}');
    });
    cubit = AuthCubit(service, pushCleanup: pushCleanup);

    final authenticated = expectLater(
      service.authStateStream,
      emitsThrough(isA<AuthAuthenticated>()),
    );
    await service.initialize();
    await authenticated;
  });

  tearDown(() async {
    await stateRecorder.cancel();
    await cubit.close();
    await holder.reset();
    service.dispose();
    await server.stop();
  });

  /// Apre una subscription sul client corrente e attende il primo evento:
  /// il socket del server è vivo e riconosciuto.
  Future<Stream<QueryResult>> openLiveSubscription() async {
    final stream = holder.client.value
        .subscribe(SubscriptionOptions(document: _userSubscription))
        .asBroadcastStream();
    await expectLater(stream, emits(isA<QueryResult>()));
    return stream;
  }

  WeakReference<GraphQLClient> weaklyHoldCurrentClient() =>
      WeakReference<GraphQLClient>(holder.client.value);

  test('logout tears the session down in order: push, backend logout, '
      'link disposed, store cleared, signedOut (D-08)', () async {
    await openLiveSubscription();
    final signedOut = expectLater(
      service.authStateStream,
      emitsThrough(const AuthUnauthenticated()),
    );

    await cubit.logout();
    await signedOut;

    expect(events, [
      'push.unregister',
      'api.logout:${_session.accessToken}',
      'socket.close.sent',
      'store.clear',
      'state:signedOut',
    ]);
  }, timeout: _flowTimeout);

  test('the server socket is closed after logout (D-08)', () async {
    await openLiveSubscription();
    final socket = server.sockets.single;

    await cubit.logout();
    await socket.done;

    expect(socket.closeCode, isNotNull);
  }, timeout: _flowTimeout);

  test('the old subscription stays silent after logout and its link never '
      'reconnects (D-08)', () async {
    final oldStream = await openLiveSubscription();
    final oldSubscriptionId = server.framesOf('subscribe').single['id'];
    final oldEvents = <QueryResult>[];
    final oldListener = oldStream.listen(oldEvents.add);
    final oldSocket = server.sockets.single;
    final liveBeforeLogout = expectLater(oldStream, emits(isA<QueryResult>()));
    server.emit(oldSocket, oldSubscriptionId as String, {
      'userUpdated': {'id': 'u-live'},
    });
    await liveBeforeLogout;
    await pumpEventQueue();
    expect(oldEvents, hasLength(1));
    oldEvents.clear();

    await cubit.logout();
    await oldSocket.done;
    final newStream = await openLiveSubscription();
    final newSocket = server.sockets.last;
    final newSubscriptionId = server.framesOf('subscribe').last['id'];
    server.emit(newSocket, oldSubscriptionId, {
      'userUpdated': {'id': 'u-old'},
    });
    final newEvent = expectLater(newStream, emits(isA<QueryResult>()));
    server.emit(newSocket, newSubscriptionId as String, {
      'userUpdated': {'id': 'u-new'},
    });
    await newEvent;
    await pumpEventQueue();

    expect(oldEvents, isEmpty);
    expect(server.framesOf('connection_init'), hasLength(2));
    expect(server.sockets, hasLength(2));
    await oldListener.cancel();
  }, timeout: _flowTimeout);

  test(
    'logout replaces the GraphQL client with a new one (D-08)',
    () async {
      await openLiveSubscription();
      final clientBefore = holder.client.value;

      await cubit.logout();

      expect(identical(holder.client.value, clientBefore), isFalse);
    },
    timeout: _flowTimeout,
  );

  test(
    'the old GraphQL client is released after logout (D-05)',
    () async {
      await openLiveSubscription();
      final oldClient = weaklyHoldCurrentClient();

      await cubit.logout();
      await forceGC(fullGcCycles: 3, timeout: const Duration(seconds: 10));

      expect(oldClient.target, isNull);
    },
    timeout: _flowTimeout,
  );

  test(
    'logout closes only the own session on the backend (D-10)',
    () async {
      await openLiveSubscription();

      await cubit.logout();

      verify(() => api.logout(_session.accessToken)).called(1);
      verifyNever(() => api.logout(any()));
    },
    timeout: _flowTimeout,
  );
}

/// Store di sessione che registra lo svuotamento nella sequenza del logout.
class _RecordingSessionStore implements SessionStore {
  _RecordingSessionStore(this._delegate, this._events);

  final InMemorySessionStore _delegate;
  final List<String> _events;

  @override
  Future<String?> readRefreshToken() => _delegate.readRefreshToken();

  @override
  Future<void> writeRefreshToken(String refreshToken) =>
      _delegate.writeRefreshToken(refreshToken);

  @override
  Future<void> clear() async {
    await _delegate.clear();
    _events.add('store.clear');
  }
}
