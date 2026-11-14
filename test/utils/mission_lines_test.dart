import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/mission_in_progress.dart';
import 'package:klimmeck_guide/utils/mission_lines.dart';

void main() {
  test('the pawn and Journal label is «Missione in corso» (D-30)', () {
    expect(missionInProgressLabel, 'Missione in corso');
  });

  test("the refusal line is «Sei impegnato in una missione: aspetta l'esito» "
      '(D-30)', () {
    expect(
      missionInProgressRefusalLine,
      "Sei impegnato in una missione: aspetta l'esito",
    );
  });

  test('the refusal code is MISSION_IN_PROGRESS (D-11)', () {
    expect(missionInProgressCode, 'MISSION_IN_PROGRESS');
  });
}
