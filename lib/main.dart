import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/config/env_config.dart';
import 'package:klimmeck_guide/repository/character_creation_repository.dart';
import 'package:klimmeck_guide/repository/services/auth/auth.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_holder.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_provider.dart';
import 'package:klimmeck_guide/repository/services/image/image_picker_portrait_picker.dart';
import 'package:klimmeck_guide/repository/services/rest/rest.dart';
import 'package:klimmeck_guide/repository/services/rest/rest_client_provider.dart';
import 'package:klimmeck_guide/repository/storage/session_store.dart';
import 'package:klimmeck_guide/screens/auth/auth_gate.dart';
import 'package:klimmeck_guide/screens/auth/authenticated_shell.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/auth/session_home.dart';
import 'package:klimmeck_guide/screens/characterCreation/character_creation_screen.dart';
import 'package:klimmeck_guide/screens/characterCreation/cubit/character_creation_cubit.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  late final GraphQLClientHolder graphQlHolder;
  final auth = _buildAuth(onSessionTeardown: () => graphQlHolder.reset());
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
      restClient: restClient,
      graphQlClient: graphQlHolder.client,
    ),
  );
}

/// Composition root dell'auth (D-23): l'unico punto che legge [EnvConfig] per
/// scegliere l'implementazione. Il bypass dev non ha recovery (nessun refresh).
({AuthTokenService service, UnauthorizedRecovery? recovery}) _buildAuth({
  required Future<void> Function() onSessionTeardown,
}) {
  final backendAuthApi = GraphQlBackendAuthApi.forEndpoint(
    EnvConfig.graphqlHttpUrl,
  );
  if (EnvConfig.devAuthEnabled) {
    return (
      service: DevAuthTokenService(
        meSource: backendAuthApi,
        onSessionTeardown: onSessionTeardown,
      ),
      recovery: null,
    );
  }
  final service = SessionAuthTokenService(
    api: backendAuthApi,
    store: SecureSessionStore(),
    browser: const FlutterWebAuth2BrowserAuthenticator(),
    backendBaseUrl: Uri.parse(EnvConfig.baseUrl),
    onSessionTeardown: onSessionTeardown,
  );
  return (service: service, recovery: service);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class KlimmeckGuideApp extends StatefulWidget {
  const KlimmeckGuideApp({
    super.key,
    required this.authTokenService,
    required this.restClient,
    required this.graphQlClient,
  });

  final AuthTokenService authTokenService;
  final RestClient restClient;
  final ValueNotifier<GraphQLClient> graphQlClient;

  @override
  State<KlimmeckGuideApp> createState() => _KlimmeckGuideAppState();
}

class _KlimmeckGuideAppState extends State<KlimmeckGuideApp> {
  late final KlimmeckRest rest;
  late final KlimmeckGraphQl graphQl = KlimmeckGraphQl(
    resolveClient: () => widget.graphQlClient.value,
  );

  @override
  void initState() {
    super.initState();
    rest = KlimmeckRest(widget.restClient);
    loadSvg();
  }

  Future<void> loadSvg() async {
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestJson);

      final svgPaths = manifestMap.keys
          .where(
            (String key) =>
                key.startsWith('assets/icons/') && key.endsWith('.svg'),
          )
          .toList();

      await Future.wait(
        svgPaths.map((svgPath) async {
          final loader = SvgAssetLoader(svgPath);
          await svg.cache.putIfAbsent(
            loader.cacheKey(null),
            () => loader.loadBytes(null),
          );
        }),
      );
    } catch (e, stack) {
      debugPrint('Error during Svg loading: $e\n$stack');
    }
  }

  Future<void> preloadImages(BuildContext context) async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final imagePaths = manifestMap.keys
          .where(
            (key) =>
                key.startsWith('assets/images/') &&
                (key.endsWith('.png') ||
                    key.endsWith('.jpg') ||
                    key.endsWith('.jpeg')),
          )
          .toList();

      await Future.wait(
        imagePaths.map((path) => precacheImage(AssetImage(path), context)),
      );

      debugPrint('Precached ${imagePaths.length} images');
    } catch (e, stack) {
      debugPrint('Error during image preloading: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthTokenService>(
      create: (_) => widget.authTokenService,
      dispose: (svc) => svc.dispose(),
      child: BlocProvider<AuthCubit>(
        lazy: false,
        create: (_) => AuthCubit(widget.authTokenService)..start(),
        child: BlocProvider<SplashCubit>(
          create: (_) => SplashCubit(rest),
          child: GraphQLProvider(
            client: widget.graphQlClient,
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: Platform.isIOS
                  ? SystemUiOverlayStyle.light
                  : const SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: Brightness.light,
                      systemNavigationBarIconBrightness: Brightness.dark,
                      systemNavigationBarColor: Colors.transparent,
                    ),
              child: MaterialApp(
                theme: KlimmeckGuideTheme.instance.materialTheme,
                color: KlimmeckGuideTheme.deepNight,
                debugShowCheckedModeBanner: false,
                title: 'Guida di Klimmeck',
                navigatorKey: navigatorKey,
                home: Builder(
                  builder: (context) {
                    preloadImages(context);
                    return AuthGate(
                      authenticatedBuilder: (context, user) => SessionHome(
                        user: user,
                        creationBuilder: (context) =>
                            BlocProvider<CharacterCreationCubit>(
                              create: (_) => CharacterCreationCubit(
                                CharacterCreationRepository(
                                  graphQl: graphQl,
                                  rest: rest,
                                  picker: ImagePickerPortraitPicker(),
                                ),
                              )..loadRaceTraits(),
                              child: const CharacterCreationScreen(),
                            ),
                        shellBuilder: (context, characterId) =>
                            AuthenticatedShell(
                              graphQl: graphQl,
                              characterId: characterId,
                            ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
