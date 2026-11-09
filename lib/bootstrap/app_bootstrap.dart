import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klimmeck_guide/bootstrap/auth_composition.dart';
import 'package:klimmeck_guide/bootstrap/insecure_transport_screen.dart';
import 'package:klimmeck_guide/bootstrap/klimmeck_guide_app.dart';
import 'package:klimmeck_guide/config/env_config.dart';
import 'package:klimmeck_guide/config/insecure_transport_error.dart';
import 'package:klimmeck_guide/repository/services/auth/graphql_backend_auth_api.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_holder.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_provider.dart';
import 'package:klimmeck_guide/repository/services/push/push_bootstrap.dart';
import 'package:klimmeck_guide/repository/services/rest/rest_client_provider.dart';

/// Schermata che sostituisce l'app in release con URL in chiaro (D-03b), o null.
@visibleForTesting
Widget? secureTransportBlocker({required bool isRelease}) {
  try {
    EnvConfig.requireSecureTransport(isRelease: isRelease);
    return null;
  } on InsecureTransportError {
    return const InsecureTransportScreen();
  }
}

/// Composizione condivisa dai due entry point (D-01): push, client GraphQL e
/// REST, store, `runApp`. L'auth arriva dalla factory dell'entry point.
Future<void> bootstrapApp({
  required AuthCompositionFactory buildAuth,
  bool isRelease = kReleaseMode,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // D-03b: in release con URL in chiaro nessun client viene costruito.
  final blocker = secureTransportBlocker(isRelease: isRelease);
  if (blocker != null) return runApp(blocker);

  // Phase 5 D-02: senza google-services.json il push resta disabilitato, il gioco no.
  final push = await bootstrapPush();

  final api = GraphQlBackendAuthApi.forEndpoint(EnvConfig.graphqlHttpUrl);
  late final GraphQLClientHolder graphQlHolder;
  final auth = buildAuth(
    api: api,
    onSessionTeardown: () => graphQlHolder.reset(),
  );
  graphQlHolder = GraphQLClientHolder(
    connect: () => buildGraphQLConnection(
      authService: auth.service,
      recovery: auth.recovery,
    ),
  );
  final restClient = RestClient(
    authTokenService: auth.service,
    recovery: auth.recovery,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: true,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Il bootstrap della sessione parte da AuthCubit.start() dopo il primo
  // frame (D-33): nessuna chiamata di rete blocca runApp.
  runApp(
    KlimmeckGuideApp(
      authTokenService: auth.service,
      sessionTerminator: auth.terminator,
      openConnectionStream: graphQlHolder.watchConnection,
      restClient: restClient,
      graphQlClient: graphQlHolder.client,
      push: push,
    ),
  );
}
