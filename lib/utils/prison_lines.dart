import 'package:klimmeck_guide/models/quest/quest_blocked_reason.dart';
import 'package:klimmeck_guide/utils/game_duration_format.dart';

/// «Sei in prigione: uscirai fra 9 h 12 min» (quick 261110-cgd), nella forma
/// «fra …» della ricarica delle pozioni; senza un tempo che manca (data del
/// server assente o già passata) la sola riga della prigione.
String prisonReleaseLine(Duration? remaining) {
  if (remaining == null || remaining <= Duration.zero) {
    return questImprisonedLine;
  }
  return '$questImprisonedLine: uscirai fra ${formatGameDuration(remaining)}';
}
