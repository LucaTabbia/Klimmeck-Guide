import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/menu_background.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_menu.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/board.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/journal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/library.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/world_map.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/profile/profile.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shop.dart';

import '../../shared/components/kg_error.dart';
import '../../shared/components/kg_loader.dart';
import '../../theme/kg_theme.dart';
import 'cubit/main_screen_cubit.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late PageController pageController;
  int currentPage = 0;
  bool isFirstLoading = true;

  @override
  void initState() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    pageController = PageController(initialPage: 0);
    pageController.addListener(() {
      setState(() {
        currentPage = pageController.page!.toInt();
      });
    });
    context.read<CharacterCubit>().loadCharacter("68c191de541d89c481b8322b");
    context.read<QuestCubit>().loadQuest();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<CharacterCubit, CharacterState>(
      listener: (context, state) {
        if (state is CharacterLoaded && isFirstLoading) {
          setState(() {
            isFirstLoading = false;
          });
          context.read<MainScreenCubit>().loadData();
        }
      },
      child: BlocBuilder<MainScreenCubit, MainScreenState>(
        builder: (context, state) {
          if (state is MainScreenLoadData) {
            return Scaffold(
              body: Stack(
                alignment: Alignment.topLeft,
                children: [
                  PageView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: pageController,
                    onPageChanged: onPageChanged,
                    children: _buildPages(state.cities),
                  ),
                  MenuBackground(
                    selectedIndex: currentPage,
                    onTap: onItemTap,
                    opacityAnimation: _opacityAnimation,
                  ),
                  SatchelMenu(
                    currentPage: currentPage,
                    onItemTap: onItemTap,
                    parentAnimationController: _animationController,
                  ),
                ],
              ),
            );
          }
          if (state is MainScreenError) {
            return Scaffold(
              backgroundColor: KlimmeckGuideTheme.deepNight,
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () => context.read<MainScreenCubit>().loadData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height:
                          MediaQuery.of(context).size.height -
                          (MediaQuery.of(context).viewPadding.top +
                              MediaQuery.of(context).viewPadding.bottom),
                      child: const KGError(),
                    ),
                  ),
                ),
              ),
            );
          }
          return Scaffold(
            backgroundColor: KlimmeckGuideTheme.deepNight,
            body: SizedBox(
              height:
                  MediaQuery.of(context).size.height -
                  (MediaQuery.of(context).viewPadding.bottom +
                      MediaQuery.of(context).viewPadding.top),
              child: const Column(children: [Spacer(), KGLoader(), Spacer()]),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildPages(List<City> cities) {
    return [
      WorldMap(cities: cities),
      Profile(),
      Journal(),
      Library(),
      Board(),
      Shop(),
    ];
  }

  void onPageChanged(int page) {
    setState(() {
      currentPage = page;
    });
  }

  Future<void> onItemTap(int index) async {
    FocusScopeNode currentFocus = FocusScope.of(context);

    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
    pageController.jumpToPage(index);
  }

  @override
  void dispose() {
    _animationController.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
