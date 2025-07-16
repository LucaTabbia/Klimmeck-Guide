import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/storage/cubit/storage_cubit.dart';
import '../../routes/routes.dart';
import '../../shared/components/custom_page_indicator.dart';
import '../../shared/components/kg_button.dart';
import '../../theme/kg_theme.dart';
import 'components/on_boarding_card.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> with TickerProviderStateMixin {
  int pageSelected = 0;
  PageController pageController = PageController();

  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    animation = CurvedAnimation(parent: controller, curve: Curves.linear);

    pageController.addListener(() {
      setState(() {
        pageSelected = pageController.page!.round();
        if (pageSelected == 2) {
          controller.forward();
        } else {
          controller.value = 0;
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StorageCubit, StorageState>(
      listener: (context, state) {
        if (state is StorageUpdated) {
          Navigator.of(context).pushReplacement(signInRoute());
        }
      },
      child: BlocBuilder<StorageCubit, StorageState>(
        builder: (context, state) {
          // if(state is StorageInitial){
          return Scaffold(
              backgroundColor: KlimmeckGuideTheme.deepNight,
              body: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Stack(alignment: Alignment.bottomCenter, children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: PageView(
                        physics: const ClampingScrollPhysics(),
                        controller: pageController,
                        children: [
                          OnBoardingCard(
                            title: "onBoarding1Title",
                            subtitle: "onBoarding1Subtitle",
                            text: "onBoarding1Description",
                            svg: "assets/icons/onBoarding/onBoarding1.svg",
                            isShownPage: pageSelected == 0,
                          ),
                          OnBoardingCard(
                            title: "onBoarding2Title",
                            subtitle: "onBoarding2Subtitle",
                            text: "onBoarding2Description",
                            svg: "assets/icons/onBoarding/onBoarding2.svg",
                            isShownPage: pageSelected == 1,
                          ),
                          OnBoardingCard(
                            title: "onBoarding3Title",
                            subtitle: "onBoarding3Subtitle",
                            text: "onBoarding3Description",
                            svg: "assets/icons/onBoarding/onBoarding3.svg",
                            isShownPage: pageSelected == 2,
                          )
                        ],
                      ),
                    ),
                    pageIndicatorOrContinue()
                  ]),
                ],
              ));
          // }
        },
      ),
    );
  }

  Widget pageIndicatorOrContinue() {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom + 60,
          left: MediaQuery.of(context).size.width * 0.2,
          right: MediaQuery.of(context).size.width * 0.2),
      child: pageSelected != 2
          ? SizedBox(
              height: 42,
              child: Center(
                child: CustomPageIndicator(
                  currentPage: pageSelected,
                ),
              ),
            )
          : Row(
              children: [
                const Spacer(),
                FadeTransition(
                  opacity: animation,
                  child: KGButton(
                    text: "continue",
                    onTap: () => context
                        .read<StorageCubit>()
                        .saveShowOnBoarding(false),
                  ),
                ),
                const Spacer(),
              ],
            ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
