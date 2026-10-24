import 'package:klimmeck_guide/models/travel/active_travel.dart';

/// Riletture d'arrivo già chieste per il viaggio corrente (D-10, WR-02). Vive
/// con la sessione, non con la mappa: rimontare la tab o un resync all'indietro
/// non riaprono una soglia già consumata.
class ArrivalRereadLedger {
  ActiveTravel? _travel;
  int _claimed = 0;

  /// `true` se [due] (soglie raggiunte) supera le riletture già chieste per
  /// questo viaggio: la registra e l'autorizza. Un viaggio diverso riparte da 0.
  bool claim(ActiveTravel travel, {required int due}) {
    if (!_isCurrent(travel)) {
      _travel = travel;
      _claimed = 0;
    }
    if (_claimed >= due) return false;
    _claimed++;
    return true;
  }

  /// Identità del viaggio: la polilinea ripetuta dal BE non è un viaggio nuovo.
  bool _isCurrent(ActiveTravel travel) =>
      _travel?.startTime == travel.startTime &&
      _travel?.endTime == travel.endTime &&
      _travel?.to == travel.to;
}
