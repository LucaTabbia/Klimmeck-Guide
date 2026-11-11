import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' hide Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';
import 'package:klimmeck_guide/models/auth/auth_session.dart';
import 'package:klimmeck_guide/repository/services/auth/auth.dart';
import 'package:klimmeck_guide/repository/services/graphql/auth_link.dart';
import 'package:klimmeck_guide/repository/services/rest/auth_interceptor.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_session_fixtures.dart';
import '../../../helpers/fakes/in_memory_session_store.dart';
import '../../../helpers/mocks.dart';

const Timeout _flowTimeout = Timeout(Duration(seconds: 20));

final AuthSession _coldStartSession = buildAuthSession(refreshToken: 'r2');

final AuthSession _rotatedSession = buildAuthSession(
  accessToken: buildTestJwt(issuedAt: testNow.add(const Duration(minutes: 1))),
  refreshToken: 'r3',
);

final String _a1 = _coldStartSession.accessToken;
final String _a2 = _rotatedSession.accessToken;

const Response _unauthenticated = Response(
  response: {'data': null},
  errors: [
    GraphQLError(
      message: 'Unauthorized',
      extensions: {'code': 'UNAUTHENTICATED'},
    ),
  ],
);

const Response _questData = Response(
  response: {
    'data': {'ok': true},
  },
  data: {'ok': true},
);

Request _graphQlRequest() => Request(
  operation: Operation(document: DocumentNode(definitions: const [])),
);

/// Due 401 simultanei (GraphQL + REST) sullo stesso servizio (HARDEN-04):
/// tempo reale, nessuna attesa a tempo.
void main() {
  late MockBackendAuthApi api;
  late Completer<AuthSession> rotation;
  late SessionAuthTokenService service;
  late List<AuthState> states;
  late StreamSubscription<AuthState> stateRecorder;
  late _BearerGatedTerminalLink graphQlTerminal;
  late _BearerGatedAdapter restAdapter;
  late Link graphQlLink;
  late Dio dio;

  setUp(() async {
    api = MockBackendAuthApi();
    rotation = Completer<AuthSession>();
    when(
      () => api.refreshSession('r1'),
    ).thenAnswer((_) async => _coldStartSession);
    when(() => api.refreshSession('r2')).thenAnswer((_) => rotation.future);
    service = SessionAuthTokenService(
      api: api,
      store: InMemorySessionStore(refreshToken: 'r1'),
      browser: MockBrowserAuthenticator(),
      backendBaseUrl: Uri.parse('http://backend.test/'),
      onSessionTeardown: () async {},
      now: () => testNow,
    );
    states = [];
    stateRecorder = service.authStateStream.listen(states.add);
    final authenticated = expectLater(
      service.authStateStream,
      emitsThrough(isA<AuthAuthenticated>()),
    );
    await service.initialize();
    await authenticated;

    graphQlTerminal = _BearerGatedTerminalLink(acceptedToken: _a2);
    graphQlLink = Link.concat(
      AuthAuthLink(authService: service, recovery: service),
      graphQlTerminal,
    );
    restAdapter = _BearerGatedAdapter(acceptedToken: _a2);
    dio = Dio(BaseOptions(baseUrl: 'https://backend.test'));
    dio
      ..httpClientAdapter = restAdapter
      ..interceptors.add(
        AuthInterceptor(authService: service, recovery: service, dio: dio),
      );
  });

  tearDown(() async {
    await stateRecorder.cancel();
    service.dispose();
  });

  /// Spara le due richieste senza attenderle, aspetta che entrambe siano
  /// state rifiutate e parcheggiate sulla rotazione, poi la sblocca.
  Future<(List<Response>, int?)> fireBothAndRotate() async {
    final graphQl = graphQlLink.request(_graphQlRequest()).toList();
    final rest = dio.get<dynamic>('/character');
    await Future.wait([
      graphQlTerminal.firstAttempt.future,
      restAdapter.firstAttempt.future,
    ]);
    await pumpEventQueue();
    rotation.complete(_rotatedSession);
    return (await graphQl, (await rest).statusCode);
  }

  test(
    'two concurrent unauthorized answers trigger exactly one refresh (D-08)',
    () async {
      await fireBothAndRotate();

      verify(() => api.refreshSession('r2')).called(1);
      verify(() => api.refreshSession('r1')).called(1);
    },
    timeout: _flowTimeout,
  );

  test(
    'both requests are retried with the refreshed token (D-08)',
    () async {
      final (graphQlResponses, restStatus) = await fireBothAndRotate();

      expect(graphQlResponses, [_questData]);
      expect(restStatus, 200);
      expect(graphQlTerminal.authorizations, ['Bearer $_a1', 'Bearer $_a2']);
      expect(restAdapter.authorizations, ['Bearer $_a1', 'Bearer $_a2']);
    },
    timeout: _flowTimeout,
  );

  test(
    'concurrent unauthorized answers never sign the user out (D-08)',
    () async {
      await fireBothAndRotate();

      expect(states.whereType<AuthUnauthenticated>(), isEmpty);
      expect(await service.getAccessToken(), _a2);
    },
    timeout: _flowTimeout,
  );
}

/// Backend GraphQL finto: `UNAUTHENTICATED` per ogni bearer diverso da
/// [acceptedToken]; registra l'header `Authorization` di ogni richiesta.
class _BearerGatedTerminalLink extends Link {
  _BearerGatedTerminalLink({required this.acceptedToken});

  final String acceptedToken;
  final List<String?> authorizations = [];
  final Completer<void> firstAttempt = Completer<void>();

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    final authorization = request.context
        .entry<HttpLinkHeaders>()
        ?.headers['Authorization'];
    authorizations.add(authorization);
    if (!firstAttempt.isCompleted) firstAttempt.complete();
    yield authorization == 'Bearer $acceptedToken'
        ? _questData
        : _unauthenticated;
  }
}

/// Backend REST finto: 401 per ogni bearer diverso da [acceptedToken].
class _BearerGatedAdapter implements HttpClientAdapter {
  _BearerGatedAdapter({required this.acceptedToken});

  final String acceptedToken;
  final List<String?> authorizations = [];
  final Completer<void> firstAttempt = Completer<void>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    final authorization = options.headers['Authorization'] as String?;
    authorizations.add(authorization);
    if (!firstAttempt.isCompleted) firstAttempt.complete();
    final accepted = authorization == 'Bearer $acceptedToken';
    return ResponseBody.fromString(
      jsonEncode({'code': accepted ? 'OK' : 'UNAUTHENTICATED'}),
      accepted ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
