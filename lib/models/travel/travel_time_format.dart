import 'package:intl/intl.dart';

/// Etichetta sopra la pedina a fine percorso, finché il BE non chiude il viaggio (D-10).
const String travelArrivingLabel = 'In arrivo…';

const double _wholeKmThreshold = 100;

/// Km di gioco con la virgola: un decimale sotto i 100 km, interi da 100 in su.
String formatTravelDistance(double km) {
  if (km >= _wholeKmThreshold) return '${km.round()} km';
  return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// Ora di arrivo in ora locale: «oggi alle HH:mm», «domani alle HH:mm»,
/// altrimenti «il dd/MM alle HH:mm» (BE §8: al massimo ~3,4 giorni).
String formatArrival(DateTime eta, {required DateTime serverNow}) {
  final local = eta.toLocal();
  final serverLocal = serverNow.toLocal();
  final arrivalDay = DateTime(local.year, local.month, local.day);
  final today = DateTime(serverLocal.year, serverLocal.month, serverLocal.day);
  final tomorrow = DateTime(
    serverLocal.year,
    serverLocal.month,
    serverLocal.day + 1,
  );
  final time = DateFormat('HH:mm').format(local);
  if (arrivalDay == today) return 'oggi alle $time';
  if (arrivalDay == tomorrow) return 'domani alle $time';
  return 'il ${DateFormat('dd/MM').format(local)} alle $time';
}
