import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/menu_background.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/notification_intent_landing.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/party_waiting_refresh_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/quest_acceptance_outcome_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_availability.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_menu.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/travel_outcome_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/board.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/journal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/library.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/world_map.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/profile/profile.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/settings.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shop.dart';

import '../../shared/components/kg_error.dart';
import '../../shared/components/kg_loader.dart';
import '../../theme/kg_theme.dart';
import 'cubit/main_screen_cubit.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.characterId, this.pagesBuilder});

  final String characterId;

  /// Sostituisce le pagine reali nei test del cablaggio della borsa.
  @visibleForTesting
  final List<Widget> Function(List<City> cities)? pagesBuilder;

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
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
    context.read<CharacterCubit>().loadCharacter(widget.characterId);
    context.read<QuestCubit>().loadQuest();
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
            return BlocSelector<
              CharacterCubit,
              CharacterState,
              (PointOfInterest?, bool)
            >(
              selector: _satchelInputsOf,
              builder: (context, inputs) {
                final (location, isTravelling) = inputs;
                final disabledPages = disabledSatchelPages(
                  location: location,
                  cities: state.cities,
                  isTravelling: isTravelling,
                );
                return QuestAcceptanceOutcomeListener(
                  cities: state.cities,
                  child: PartyWaitingRefreshListener(
                    cities: state.cities,
                    child: TravelOutcomeListener(
                      child: Scaffold(
                        body: Stack(
                          alignment: Alignment.topLeft,
                          children: [
                            NotificationIntentLanding(
                              pageController: pageController,
                              child: PageView(
                                physics: const NeverScrollableScrollPhysics(),
                                controller: pageController,
                                onPageChanged: onPageChanged,
                                children:
                                    widget.pagesBuilder?.call(state.cities) ??
                                    _buildPages(state.cities),
                              ),
                            ),
                            MenuBackground(
                              selectedIndex: currentPage,
                              onTap: onItemTap,
                              opacityAnimation: _opacityAnimation,
                              disabledPages: disabledPages,
                            ),
                            SatchelMenu(
                              currentPage: currentPage,
                              onItemTap: onItemTap,
                              parentAnimationController: _animationController,
                              disabledPages: disabledPages,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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
    final pages = [
      WorldMap(cities: cities),
      Profile(),
      Journal(),
      Library(),
      Board(cities: cities, onQuestAccepted: _showMap),
      Shop(),
      const Settings(),
    ];
    assert(
      pages.length == SatchelLayout.entries.length,
      'Una pagina per ogni voce della borsa',
    );
    return pages;
  }

  /// QUEST-03: dopo l'accettazione si passa alla mappa (D-03).
  void _showMap() {
    if (!pageController.hasClients) return;
    pageController.jumpToPage(NotificationIntentLanding.worldMapPageIndex);
  }

  void onPageChanged(int page) {
    setState(() {
      currentPage = page;
    });
  }

  Future<void> onItemTap(int index) async {
    if (_isPageDisabled(index)) return;
    FocusScopeNode currentFocus = FocusScope.of(context);

    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
    pageController.jumpToPage(index);
  }

  /// Difesa: nessun percorso apre una pagina disabilitata (D-11, D-12).
  bool _isPageDisabled(int index) {
    final screen = context.read<MainScreenCubit>().state;
    if (screen is! MainScreenLoadData) return false;
    final (location, isTravelling) = _satchelInputsOf(
      context.read<CharacterCubit>().state,
    );
    return disabledSatchelPages(
      location: location,
      cities: screen.cities,
      isTravelling: isTravelling,
    ).contains(index);
  }

  /// Posizione e viaggio in corso: gli input della disponibilità della borsa (D-12).
  static (PointOfInterest?, bool) _satchelInputsOf(CharacterState state) =>
      state is CharacterLoaded
      ? (
          state.character.status?.location,
          state.character.status?.activeTravel != null,
        )
      : (null, false);

  @override
  void dispose() {
    _animationController.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
