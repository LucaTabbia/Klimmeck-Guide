import 'package:flutter_test/flutter_test.dart';

const Duration _expansion = Duration(milliseconds: 300);

/// Apre la tendina (senza pumpAndSettle: uno spinner non si assesta mai) di una sezione del foglio Impostazioni, se c'è.
Future<void> openSettingsSection(WidgetTester tester, String title) async {
  final header = find.text(title);
  if (header.evaluate().isEmpty) return;
  await tester.ensureVisible(header);
  await tester.tap(header);
  await tester.pump();
  await tester.pump(_expansion);
}
