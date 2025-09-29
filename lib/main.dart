import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_provider.dart';
import 'package:klimmeck_guide/repository/services/rest/rest.dart';
import 'package:klimmeck_guide/repository/storage/cubit/storage_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/cubit/main_screen_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/cubit/library_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/cubit/shop_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/cubit/sign_in_cubit.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:klimmeck_guide/screens/splash/splash_screen.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();
  //await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true,badge: true,sound: true,);
  final client = initGraphQLClient();
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
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(KlimmeckGuideApp(client: client));
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class KlimmeckGuideApp extends StatefulWidget {
  const KlimmeckGuideApp({super.key, required this.client});

  final ValueNotifier<GraphQLClient> client;

  @override
  State<KlimmeckGuideApp> createState() => _KlimmeckGuideAppState();
}

class _KlimmeckGuideAppState extends State<KlimmeckGuideApp> {
  final KlimmeckRest rest = KlimmeckRest();
  final KlimmeckGraphQl graphQl = KlimmeckGraphQl();

  Future<void> loadSvg() async {
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestJson);

      final svgPaths = manifestMap.keys
          .where((String key) => key.startsWith('assets/icons/') && key.endsWith('.svg'))
          .toList();

      await Future.wait(
        svgPaths.map((svgPath) async {
          final loader = SvgAssetLoader(svgPath);
          await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
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
                (key.endsWith('.png') || key.endsWith('.jpg') || key.endsWith('.jpeg')),
          )
          .toList();

      await Future.wait(imagePaths.map((path) => precacheImage(AssetImage(path), context)));

      debugPrint('Precached ${imagePaths.length} images');
    } catch (e, stack) {
      debugPrint('Error during image preloading: $e\n$stack');
    }
  }

  @override
  void initState() {
    super.initState();
    loadSvg();
  }

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: widget.client,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<StorageCubit>(create: (context) => StorageCubit()),
          BlocProvider<MainScreenCubit>(create: (context) => MainScreenCubit(graphQl)),
          BlocProvider<WorldMapCubit>(create: (context) => WorldMapCubit(graphQl)),
          BlocProvider<ShopCubit>(create: (context) => ShopCubit(graphQl)),
          BlocProvider<LibraryCubit>(create: (context) => LibraryCubit(graphQl)),
          BlocProvider<StorageCubit>(create: (context) => StorageCubit()),
          BlocProvider<JournalCubit>(create: (context) => JournalCubit(graphQl)),
          BlocProvider<SplashCubit>(create: (context) => SplashCubit(rest)),
          BlocProvider<SignInCubit>(create: (context) => SignInCubit(graphQl)),
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
    );
  }
}
