import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../main.dart';
import '../../routes/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool onNotificationTrigger = false;

  @override
  void initState() {
    context.read<SplashCubit>().getImages("main");
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(AssetImage('assets/images/worldMap.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is SplashData) {
          goToPage();
        }
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Image.asset('assets/images/splash.png', fit: BoxFit.fitWidth),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Text(
              "Caricamento",
              style: KlimmeckGuideTheme.instance.specialText.copyWith(
                color: KlimmeckGuideTheme.parchment,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> goToPage() async {
    navigatorKey.currentState?.pushReplacement(mainScreenRoute());
    /*var showOnBoarding = await KGStorageManager.getShowOnBoarding();
    Timer(const Duration(seconds: 3), () async {
      if (showOnBoarding == null || showOnBoarding == true) {
        Navigator.of(context).pushReplacement(onBoardingRoute());
      } else {
        bool alreadyLogged = await KGStorageManager.checkUserLogged();
        User? userLogged = await KGStorageManager.getLoggedUser();
        if (alreadyLogged && userLogged != null) {
          if (mounted) {
            var jsonString = await KGStorageManager.getToken();
            if (jsonString != '') {
              navigatorKey.currentContext
                  ?.read<SplashCubit>()
                  .initializeLoggedUser();
              navigatorKey.currentState?.pushReplacement(mainScreenRoute());
            } else {
              navigatorKey.currentState?.pushReplacement(signInRoute());
            }
          }
        } else {
          if (mounted) {
            Navigator.of(context).pushReplacement(signInRoute());
          }
        }
      }
    })*/
  }
}
