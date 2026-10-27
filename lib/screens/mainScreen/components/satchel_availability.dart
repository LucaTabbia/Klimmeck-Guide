import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/quest/board_policy.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';

/// Pagine della borsa non raggiungibili ora: Bacheca e Negozio solo su un
/// marker di città e mai durante un viaggio, anche quello automatico verso una
/// quest (Phase 6 D-11, Phase 7 D-12). La posizione resta quella di partenza
/// finché il BE non chiude il viaggio, quindi serve il flag del viaggio.
/// Mai neppure in attesa di soccorso (Phase 9 D-16).
Set<int> disabledSatchelPages({
  required PointOfInterest? location,
  required List<City> cities,
  required bool isTravelling,
  bool isAwaitingAid = false,
}) => isOnCityMarker(cities, location) && !isTravelling && !isAwaitingAid
    ? const {}
    : const {SatchelLayout.boardPageIndex, SatchelLayout.shopPageIndex};
