import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/shared/components/modal/logout_confirmation_dialog.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

const _title = 'Sei sicuro di voler uscire?';

void main() {
  late MockAuthTokenService service;

  setUp(() {
    service = MockAuthTokenService();
    when(() => service.logout()).thenAnswer((_) async {});
  });

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestApp(
        home: BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(service),
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => confirmLogout(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows title, body and the two actions', (tester) async {
    await openDialog(tester);

    expect(find.text(_title), findsOneWidget);
    expect(find.text('La tua sessione verrà terminata.'), findsOneWidget);
    final cancel = tester.getTopLeft(find.text('Annulla'));
    final confirm = tester.getTopLeft(find.text('Esci'));
    expect(cancel.dx, lessThan(confirm.dx));
  });

  testWidgets('tapping the barrier keeps the dialog open', (tester) async {
    await openDialog(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text(_title), findsOneWidget);
  });

  testWidgets('Annulla closes without logging out', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(find.text(_title), findsNothing);
    verifyNever(() => service.logout());
  });

  testWidgets('Esci closes and logs out once', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('Esci'));
    await tester.pumpAndSettle();

    expect(find.text(_title), findsNothing);
    verify(() => service.logout()).called(1);
  });

  testWidgets('showLogoutConfirmationDialog returns false on Annulla and true '
      'on Esci', (tester) async {
    bool? result;
    await tester.pumpWidget(
      buildTestApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await showLogoutConfirmationDialog(context),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esci'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
