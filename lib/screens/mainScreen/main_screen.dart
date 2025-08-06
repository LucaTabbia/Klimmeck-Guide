import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/radial_menu.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/journal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/library.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/world_map.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/profile/profile.dart';

import '../../shared/components/kg_error.dart';
import '../../shared/components/kg_loader.dart';
import '../../theme/kg_theme.dart';
import 'cubit/main_screen_cubit.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with AutomaticKeepAliveClientMixin {
  late PageController pageController;
  int currentPage = 0;

  @override
  void initState() {
    pageController = PageController(initialPage: 0);
    pageController.addListener(() {
      setState(() {
        currentPage = pageController.page!.toInt();
      });
    });
    context.read<MainScreenCubit>().loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<MainScreenCubit, MainScreenState>(
      builder: (context, state) {
        if (state is MainScreenLoadData) {
          return Scaffold(
            body: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: pageController,
                  onPageChanged: onPageChanged,
                  children: _buildPages(state.character, state.cities),
                ),
                Positioned(
                  left: -110,
                  bottom: -60,
                  child: RadialMenu(currentPage: currentPage, onItemTap: onItemTap),
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
    );
  }

  List<Widget> _buildPages(Character character, List<City> cities) {
    return [
      WorldMap(character: character, cities: cities),
      Profile(character: character),
      Journal(character: character),
      Library(),
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
  bool get wantKeepAlive => true;
}
