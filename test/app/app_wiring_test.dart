import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:mocktail/mocktail.dart';

/// RED — RepositoryProvider wiring (DEV-AUTH-05).
/// Diventerà GREEN dopo Plan 03.
class MockAuthTokenService extends Mock implements AuthTokenService {}

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
}
