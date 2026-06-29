import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/config/env_config.dart';
import 'package:klimmeck_guide/repository/services/auth/auth.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_provider.dart';
import 'package:klimmeck_guide/repository/services/rest/rest.dart';
import 'package:klimmeck_guide/repository/services/rest/rest_client_provider.dart';
import 'package:klimmeck_guide/repository/storage/cubit/storage_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/cubit/main_screen_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/cubit/library_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/cubit/sign_in_cubit.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:klimmeck_guide/screens/splash/splash_screen.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final AuthTokenService authTokenService = _buildAuthTokenService();
  await authTokenService
      .initialize(); // polimorfico — NO type-check is DevAuthTokenService

  final restClient = RestClient(authTokenService: authTokenService);
  final graphQlClient = await initGraphQLClient(authTokenService);

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

  runApp(
    KlimmeckGuideApp(
      authTokenService: authTokenService,
      restClient: restClient,
      graphQlClient: graphQlClient,
    ),
  );
}

/// Factory che seleziona l'implementazione di `AuthTokenService` in base
/// alla configurazione runtime.
///
/// Phase 1: `DevAuthTokenService` quando `EnvConfig.devAuthEnabled == true`.
/// Phase 11: sostituirà il branch `else` con `OAuthTokenService` senza
/// toccare `main()` né i consumer (D-02 CONTEXT.md drop-in replacement).
AuthTokenService _buildAuthTokenService() {
  if (EnvConfig.devAuthEnabled) {
    return DevAuthTokenService();
  }
  throw UnimplementedError(
    'RealAuthTokenService not yet implemented — see Phase 11 (Auth & Session Bootstrap)',
  );
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
  final KlimmeckGraphQl graphQl = KlimmeckGraphQl();

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
      child: GraphQLProvider(
        client: widget.graphQlClient,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<StorageCubit>(create: (context) => StorageCubit()),
            BlocProvider<CharacterCubit>(
              create: (context) => CharacterCubit(graphQl),
            ),
            BlocProvider<QuestCubit>(create: (context) => QuestCubit(graphQl)),
            BlocProvider<TransactionCubit>(
              create: (context) => TransactionCubit(graphQl),
            ),
            BlocProvider<MainScreenCubit>(
              create: (context) => MainScreenCubit(graphQl),
            ),
            BlocProvider<WorldMapCubit>(
              create: (context) => WorldMapCubit(graphQl),
            ),
            BlocProvider<ShopCubit>(create: (context) => ShopCubit(graphQl)),
            BlocProvider<LibraryCubit>(
              create: (context) => LibraryCubit(graphQl),
            ),
            BlocProvider<JournalCubit>(
              create: (context) => JournalCubit(graphQl),
            ),
            BlocProvider<SplashCubit>(create: (context) => SplashCubit(rest)),
            BlocProvider<SignInCubit>(
              create: (context) => SignInCubit(graphQl),
            ),
          ],
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
                  return const SplashScreen();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
