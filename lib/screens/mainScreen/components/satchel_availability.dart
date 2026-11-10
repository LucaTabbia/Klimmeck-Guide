import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/quest/board_policy.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';

const Set<int> _boardAndShop = {
  SatchelLayout.boardPageIndex,
  SatchelLayout.shopPageIndex,
};
const Set<int> _shopOnly = {SatchelLayout.shopPageIndex};

/// Pagine della borsa non raggiungibili ora: Bacheca e Negozio solo su un
/// marker di città e mai durante un viaggio, anche quello automatico verso una
/// quest (Phase 6 D-11, Phase 7 D-12). La posizione resta quella di partenza
/// finché il BE non chiude il viaggio, quindi serve il flag del viaggio.
/// Mai neppure in attesa di soccorso (Phase 9 D-16). In prigione si chiude il
/// solo Negozio: la Bacheca mostra i fogli strappati (quick 261110-cgd).
/// Su una città senza negozio per il BE (`City.hasShop`, Necrorian o un pool
/// svuotato a DB) si chiude solo il Negozio: la Bacheca resta aperta
/// (Phase 13 D-04).
Set<int> disabledSatchelPages({
  required PointOfInterest? location,
  required List<City> cities,
  required bool isTravelling,
  bool isAwaitingAid = false,
  bool isImprisoned = false,
}) {
  final city = currentCityOf(cities, location);
  if (city == null || isTravelling || isAwaitingAid) return _boardAndShop;
  return city.hasShop && !isImprisoned ? const {} : _shopOnly;
}
