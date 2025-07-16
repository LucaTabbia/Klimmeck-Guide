import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/user.dart';
import '../../shared/components/kg_error.dart';
import '../../shared/components/kg_loader.dart';
import '../../theme/kg_theme.dart';
import 'components/navbar.dart';
import '../../shared/components/title_icons.dart';
import 'cubit/main_screen_cubit.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with AutomaticKeepAliveClientMixin {
  late PageController pageController;
  int currentPage = 0;

  bool loadingZendeskKeys = false;
  String androidZendeskKey = "";
  String iosZendeskKey = "";

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
        if (state is MainScreenLoadData && !loadingZendeskKeys) {
          return Scaffold(
            backgroundColor: KlimmeckGuideTheme.deepNight,
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: SizedBox(
                height: MediaQuery.of(context).size.width * 0.15 + 50,
                child: ELBottomNavigationBar(
                    currentPage: currentPage, onItemTap: onItemTap),
              ),
            ),
            body: SafeArea(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 90),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height -
                          (125 +
                              MediaQuery.of(context).size.width * 0.15 +
                              MediaQuery.of(context).viewPadding.bottom +
                              MediaQuery.of(context).viewPadding.top),
                      child: PageView(
                        physics: const NeverScrollableScrollPhysics(),
                        controller: pageController,
                        onPageChanged: onPageChanged,
                        children: _buildTabs(state.user),
                      ),
                    ),
                  ),
                  TitleAndIcons(
                    title: getTitle(),
                    subTitle: getSubTitle(state.user),
                    user: state.user,
                  )
                ],
              ),
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
                      height: MediaQuery.of(context).size.height -
                          (MediaQuery.of(context).viewPadding.top +
                              MediaQuery.of(context).viewPadding.bottom),
                      child: const KGError()),
                ),
              ),
            ),
          );
        }

        if (loadingZendeskKeys) {
          return Scaffold(
            backgroundColor: KlimmeckGuideTheme.deepNight,
            body: SizedBox(
                height: MediaQuery.of(context).size.height -
                    (MediaQuery.of(context).viewPadding.bottom +
                        MediaQuery.of(context).viewPadding.top),
                child: const Column(
                  children: [Spacer(), KGLoader(), Spacer()],
                )),
          );
        }
        return Scaffold(
          backgroundColor: KlimmeckGuideTheme.deepNight,
          body: SizedBox(
              height: MediaQuery.of(context).size.height -
                  (MediaQuery.of(context).viewPadding.bottom +
                      MediaQuery.of(context).viewPadding.top),
              child: const Column(
                children: [Spacer(), KGLoader(), Spacer()],
              )),
        );
      },
    );
  }

  String getTitle() {
    switch (currentPage) {
      case 0:
        return 'bills';
      case 1:
        return 'selfReading';
      case 2:
        return 'support';
      default:
        return '';
    }
  }

  String getSubTitle(User user) {
    switch (currentPage) {
      case 0:
        return 'paymentsSummary';
      case 1:
        return 'manageInAutonomy';
      case 2:
        return 'supportSubtitle';
      default:
        return '';
    }
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

    if (index == 2) {

    } else {
      pageController.jumpToPage(index);
    }
  }

  List<Widget> _buildTabs(User user) {
    return [

    ];
  }

  @override
  bool get wantKeepAlive => true;
}
