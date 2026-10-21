import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/quest/board_policy.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';

/// Pagine della borsa non raggiungibili ora. Phase 6: la Bacheca solo da un
/// marker di città (D-11); FE Phase 7 aggiunge qui il viaggio in corso (D-13).
Set<int> disabledSatchelPages({
  required PointOfInterest? location,
  required List<City> cities,
}) => isOnCityMarker(cities, location)
    ? const {}
    : const {SatchelLayout.boardPageIndex};
