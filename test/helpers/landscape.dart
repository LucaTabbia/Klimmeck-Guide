import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Superficie di un telefono in landscape: 780x360 logici a 3.0
/// (l'app e' solo landscape).
void useLandscapePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(2340, 1080);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}
