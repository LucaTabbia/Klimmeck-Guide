import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/auth/session_home.dart';

import '../../helpers/auth_fixtures.dart';

void main() {
  late int creationBuilds;
  late int shellBuilds;

  setUp(() {
    creationBuilds = 0;
    shellBuilds = 0;
  });

  Widget buildHome(user) => MaterialApp(
    home: SessionHome(
      user: user,
      creationBuilder: (_) {
        creationBuilds++;
        return const Text('creation');
      },
      shellBuilder: (_, characterId) {
        shellBuilds++;
        return Text('shell $characterId');
      },
    ),
  );

  testWidgets('shows the creation screen when the user has no character', (
    tester,
  ) async {
    await tester.pumpWidget(buildHome(buildTestUser()));

    expect(find.text('creation'), findsOneWidget);
    expect(shellBuilds, 0);
  });

  testWidgets('shows the shell with the character id when one exists', (
    tester,
  ) async {
    await tester.pumpWidget(buildHome(buildTestUserWithCharacter()));

    expect(find.text('shell $testCharacterId'), findsOneWidget);
    expect(creationBuilds, 0);
  });

  testWidgets('swaps creation for the shell once the character exists', (
    tester,
  ) async {
    await tester.pumpWidget(buildHome(buildTestUser()));
    await tester.pumpWidget(buildHome(buildTestUserWithCharacter()));

    expect(find.text('creation'), findsNothing);
    expect(find.text('shell $testCharacterId'), findsOneWidget);
  });
}
