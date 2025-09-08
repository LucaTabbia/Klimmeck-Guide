import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klimmeck_guide/repository/services/api.dart';
import 'package:klimmeck_guide/repository/storage/cubit/storage_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/cubit/main_screen_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/main_screen.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/cubit/library_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/cubit/sign_in_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();
  //await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true,badge: true,sound: true,);

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
    runApp(const KlimmeckGuideApp());
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class KlimmeckGuideApp extends StatefulWidget {
  const KlimmeckGuideApp({super.key});

  @override
  State<KlimmeckGuideApp> createState() => _KlimmeckGuideAppState();
}

class _KlimmeckGuideAppState extends State<KlimmeckGuideApp> {
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

  @override
  void initState() {
    super.initState();
    loadSvg();
  }

  Api api = Api();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<StorageCubit>(create: (context) => StorageCubit()),
        BlocProvider<MainScreenCubit>(create: (context) => MainScreenCubit()),
        BlocProvider<WorldMapCubit>(create: (context) => WorldMapCubit()),
        BlocProvider<LibraryCubit>(create: (context) => LibraryCubit()),
        BlocProvider<StorageCubit>(create: (context) => StorageCubit()),
        BlocProvider<JournalCubit>(create: (context) => JournalCubit()),
        BlocProvider<SignInCubit>(create: (context) => SignInCubit(api)),
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
          home: const MainScreen(),
        ),
      ),
    );
  }
}
