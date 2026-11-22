import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/story_and_wound_corrections.dart';

void main() {
  test('the switch is on after the gate', () {
    expect(storyAndWoundCorrectionsEnabled, isTrue);
  });
}
