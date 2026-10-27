const int _minutesPerHour = 60;
const int _minutesPerDay = 24 * _minutesPerHour;

/// Durata di gioco leggibile, arrotondata per eccesso al minuto: un tempo
/// positivo non si legge mai "0 min". Da 24 h in su: giorni e ore.
/// Condivisa da viaggio (Phase 7) e magie (Phase 8, D-13).
String formatGameDuration(Duration duration) {
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
