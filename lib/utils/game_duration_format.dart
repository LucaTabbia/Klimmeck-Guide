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

/// Durata della riga «Tempo richiesto» del foglio quest, a parole (ore,
/// minuti, secondi) invece delle sigle di [formatGameDuration]: è lo stile
/// storico di quella riga. Unisce solo le parti non nulle; i secondi compaiono
/// solo sotto il minuto, perché da quick 261113-aql un soccorso dura una quota
/// del dungeon e può valere pochi secondi. Arrotonda per eccesso al secondo.
String formatQuestDuration(Duration duration) {
  final ms = duration.inMilliseconds;
  if (ms <= 0) return '0 minuti';
  final seconds = (ms / Duration.millisecondsPerSecond).ceil();
  if (seconds < Duration.secondsPerMinute) {
    return _countOf(seconds, 'secondo', 'secondi');
  }
  final minutes = seconds ~/ Duration.secondsPerMinute;
  final hours = minutes ~/ _minutesPerHour;
  final rest = minutes % _minutesPerHour;
  return [
    if (hours > 0) _countOf(hours, 'ora', 'ore'),
    if (rest > 0) _countOf(rest, 'minuto', 'minuti'),
  ].join(', ');
}

String _countOf(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';
