import 'package:intl/intl.dart';

/// Etichetta sopra la pedina a fine percorso, finché il BE non chiude il viaggio (D-10).
const String travelArrivingLabel = 'In arrivo…';

const int _minutesPerHour = 60;
const int _minutesPerDay = 24 * _minutesPerHour;
const double _wholeKmThreshold = 100;

/// Durata leggibile (D-03, D-08), arrotondata per eccesso al minuto: un tempo
/// rimanente positivo non si legge mai "0 min". Da 24 h in su: giorni e ore.
String formatTravelDuration(Duration duration) {
  final ms = duration.inMilliseconds;
  if (ms <= 0) return '0 min';
  final minutes = (ms / Duration.millisecondsPerMinute).ceil();
  if (minutes < _minutesPerHour) return '$minutes min';
  if (minutes < _minutesPerDay) {
    final hours = minutes ~/ _minutesPerHour;
    final rest = minutes % _minutesPerHour;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }
  final days = minutes ~/ _minutesPerDay;
  final hours = (minutes % _minutesPerDay) ~/ _minutesPerHour;
  return hours == 0 ? '$days g' : '$days g $hours h';
}

/// Km di gioco con la virgola: un decimale sotto i 100 km, interi da 100 in su.
String formatTravelDistance(double km) {
  if (km >= _wholeKmThreshold) return '${km.round()} km';
  return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// Ora di arrivo in ora locale: «oggi alle HH:mm», «domani alle HH:mm»,
/// altrimenti «il dd/MM alle HH:mm» (BE §8: al massimo ~3,4 giorni).
String formatArrival(DateTime eta, {required DateTime serverNow}) {
  final local = eta.toLocal();
  final now = serverNow.toLocal();
  final arrivalDay = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final time = DateFormat('HH:mm').format(local);
  if (arrivalDay == today) return 'oggi alle $time';
  if (arrivalDay == tomorrow) return 'domani alle $time';
  return 'il ${DateFormat('dd/MM').format(local)} alle $time';
}
