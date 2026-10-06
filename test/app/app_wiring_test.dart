import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../helpers/mocks.dart';
import '../helpers/test_app.dart';

void main() {
  group('App wiring — AuthTokenService RepositoryProvider', () {
    testWidgets(
      'context.read<AuthTokenService>() non lancia ProviderNotFoundException',
      (tester) async {
        final mockService = MockAuthTokenService();
        AuthTokenService? capturedService;

        await tester.pumpWidget(
          MaterialApp(
            home: RepositoryProvider<AuthTokenService>.value(
              value: mockService,
              child: Builder(
                builder: (context) {
                  capturedService = context.read<AuthTokenService>();
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        expect(capturedService, isNotNull);
        expect(capturedService, same(mockService));
      },
    );
  });

  testWidgets('buildTestApp renderizza testo col tema senza scaricare font', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: Text('ciao', style: KlimmeckGuideTheme.instance.titleMedium),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ciao'), findsOneWidget);
  });
}
