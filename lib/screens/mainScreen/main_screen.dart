import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/menu_background.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/notification_intent_landing.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/party_watch_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/quest_acceptance_outcome_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_availability.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_menu.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/spell_outcome_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/travel_outcome_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/board.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/journal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/library.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/world_map.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/profile/profile.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/settings.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shop.dart';

import '../../shared/components/kg_error.dart';
import '../../shared/components/kg_loader.dart';
import '../../theme/kg_theme.dart';
import 'cubit/main_screen_cubit.dart';

typedef _SatchelInputs = ({
  PointOfInterest? location,
  bool isTravelling,
  bool isAwaitingAid,
});

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
  late final MapAvailabilityCubit _mapAvailability;
  int currentPage = 0;
  bool isFirstLoading = true;

  @override
  void initState() {
    super.initState();
    _mapAvailability = context.read<MapAvailabilityCubit>();
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
    return MultiBlocListener(
      listeners: [
        BlocListener<CharacterCubit, CharacterState>(
          listener: (context, state) {
            if (state is CharacterLoaded && isFirstLoading) {
              setState(() {
                isFirstLoading = false;
              });
              context.read<MainScreenCubit>().loadData();
            }
          },
        ),
        BlocListener<MainScreenCubit, MainScreenState>(
          listenWhen: (previous, current) =>
              previous is! MainScreenLoadData && current is MainScreenLoadData,
          listener: (_, _) => _reportMapPage(currentPage),
        ),
      ],
      child: BlocBuilder<MainScreenCubit, MainScreenState>(
        builder: (context, state) {
          if (state is MainScreenLoadData) {
            return BlocSelector<CharacterCubit, CharacterState, _SatchelInputs>(
              selector: _satchelInputsOf,
              builder: (context, inputs) {
                final disabledPages = disabledSatchelPages(
                  location: inputs.location,
                  cities: state.cities,
                  isTravelling: inputs.isTravelling,
                  isAwaitingAid: inputs.isAwaitingAid,
                );
                return QuestAcceptanceOutcomeListener(
                  cities: state.cities,
                  child: PartyWatchListener(
                    child: TravelOutcomeListener(
                      child: SpellOutcomeListener(
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
    _reportMapPage(page);
  }

  /// Phase 9 D-23 (F1): la pagina iniziale non passa da `onPageChanged`, il
  /// loader di cold start non è mai la mappa.
  void _reportMapPage(int page) => _mapAvailability.pageChanged(
    isMapPage: page == NotificationIntentLanding.worldMapPageIndex,
  );

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
    final inputs = _satchelInputsOf(context.read<CharacterCubit>().state);
    return disabledSatchelPages(
      location: inputs.location,
      cities: screen.cities,
      isTravelling: inputs.isTravelling,
      isAwaitingAid: inputs.isAwaitingAid,
    ).contains(index);
  }

  /// Posizione, viaggio in corso e attesa di soccorso: gli input della
  /// disponibilità della borsa (D-12, Phase 9 D-16).
  static _SatchelInputs _satchelInputsOf(CharacterState state) {
    if (state is! CharacterLoaded) {
      return (location: null, isTravelling: false, isAwaitingAid: false);
    }
    final status = state.character.status;
    return (
      location: status?.location,
      isTravelling: status?.activeTravel != null,
      isAwaitingAid: status?.awaitingAid != null,
    );
  }

  @override
  void dispose() {
    _mapAvailability.pageChanged(isMapPage: false);
    _animationController.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
