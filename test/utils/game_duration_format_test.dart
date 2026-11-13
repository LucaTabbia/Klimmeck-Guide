import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/utils/game_duration_format.dart';

void main() {
  group('formatGameDuration', () {
    final cases = <Duration, String>{
      const Duration(seconds: 30): '1 min',
      const Duration(minutes: 40): '40 min',
      const Duration(minutes: 40, seconds: 1): '41 min',
      const Duration(hours: 1): '1 h',
      const Duration(hours: 2, minutes: 40): '2 h 40 min',
      const Duration(hours: 23, minutes: 59, seconds: 30): '1 g',
      const Duration(hours: 24): '1 g',
      const Duration(hours: 27, minutes: 10): '1 g 3 h',
      const Duration(hours: 48): '2 g',
      const Duration(hours: 82, minutes: 18): '3 g 10 h',
      Duration.zero: '0 min',
      const Duration(minutes: -5): '0 min',
    };

    cases.forEach((duration, expected) {
      test('$duration reads "$expected"', () {
        expect(formatGameDuration(duration), expected);
      });
    });
  });

  group(
    'formatQuestDuration (quick 261113-aql, user: «Su Tempo richiesto vedo ",7" secondi»)',
    () {
      final cases = <Duration, String>{
        const Duration(hours: 3): '3 ore',
        const Duration(hours: 1): '1 ora',
        const Duration(minutes: 15): '15 minuti',
        const Duration(minutes: 1): '1 minuto',
        const Duration(hours: 1, minutes: 15): '1 ora, 15 minuti',
        const Duration(hours: 2, minutes: 1): '2 ore, 1 minuto',
        const Duration(milliseconds: 7500): '8 secondi',
        const Duration(seconds: 30): '30 secondi',
        const Duration(seconds: 1): '1 secondo',
        const Duration(milliseconds: 300): '1 secondo',
        const Duration(seconds: 59, milliseconds: 500): '1 minuto',
        const Duration(hours: 25): '25 ore',
        Duration.zero: '0 minuti',
        const Duration(minutes: -5): '0 minuti',
      };

      cases.forEach((duration, expected) {
        test('$duration reads "$expected"', () {
          expect(formatQuestDuration(duration), expected);
        });
      });

      test('never prints a leading comma nor a stray space', () {
        for (final duration in cases.keys) {
          final text = formatQuestDuration(duration);
          expect(text, isNot(startsWith(',')));
          expect(text, text.trim());
          expect(text, isNot(contains(' ,')));
        }
      });
    },
  );

  group(
    'formatQuestDuration rounds up to the whole minute from one minute on and '
    'never reads less than the real time (WR-04)',
    () {
      final cases = <Duration, String>{
        const Duration(seconds: 61): '2 minuti',
        const Duration(seconds: 90): '2 minuti',
        const Duration(seconds: 119): '2 minuti',
        const Duration(seconds: 3600): '1 ora',
        const Duration(seconds: 3601): '1 ora, 1 minuto',
        const Duration(hours: 1, minutes: 15, seconds: 30): '1 ora, 16 minuti',
        const Duration(minutes: 22, seconds: 30): '23 minuti',
      };

      cases.forEach((duration, expected) {
        test('$duration reads "$expected" (WR-04)', () {
          expect(formatQuestDuration(duration), expected);
        });
      });
    },
  );
}
