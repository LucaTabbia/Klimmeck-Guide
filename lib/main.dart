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
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
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
    final manifestJson = await rootBundle.loadString('AssetManifest.json');
    List svgsPaths =
        (json
                    .decode(manifestJson)
                    .keys
                    .where((String key) => key.startsWith('assets/icons/') && key.endsWith('.svg'))
                as Iterable)
            .toList();

    for (var svgPath in svgsPaths as List<String>) {
      var loader = SvgAssetLoader(svgPath);
      await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
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
        BlocProvider<MainScreenCubit>(create: (context) => MainScreenCubit(api)),
        BlocProvider<StorageCubit>(create: (context) => StorageCubit()),
        BlocProvider<SignInCubit>(create: (context) => SignInCubit(api)),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: Platform.isIOS
            ? SystemUiOverlayStyle.light
            : const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                systemNavigationBarIconBrightness: Brightness.light,
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
