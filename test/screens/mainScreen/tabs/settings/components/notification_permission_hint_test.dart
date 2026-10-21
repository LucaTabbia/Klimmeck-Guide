import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_port.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/notification_permission_hint.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/test_app.dart';

const String _message = 'Le notifiche di sistema sono disattivate';
const String _action = 'Attiva';

const NotificationPermissionState _denied = NotificationPermissionState(
  status: NotificationPermissionStatus.denied,
);

void main() {
  late MockNotificationPermissionCubit cubit;

  setUp(() {
    cubit = MockNotificationPermissionCubit();
    when(() => cubit.openSettings()).thenAnswer((_) async {});
  });

  Future<void> pumpHint(
    WidgetTester tester,
    NotificationPermissionState state, {
    Stream<NotificationPermissionState> stream =
        const Stream<NotificationPermissionState>.empty(),
  }) async {
    whenListen(cubit, stream, initialState: state);
    await tester.pumpWidget(
      buildTestApp(
        home: Material(
          child: BlocProvider<NotificationPermissionCubit>.value(
            value: cubit,
            child: const NotificationPermissionHint(),
          ),
        ),
      ),
    );
  }

  void expectNoBlockingFeedback() {
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  }

  testWidgets('a denied permission shows the row with its action', (
    tester,
  ) async {
    await pumpHint(tester, _denied);

    expect(find.text(_message), findsOneWidget);
    expect(find.text(_action), findsOneWidget);
    expectNoBlockingFeedback();
  });

  testWidgets('Attiva opens the app system settings', (tester) async {
    await pumpHint(tester, _denied);

    await tester.tap(find.text(_action));
    await tester.pump();

    verify(() => cubit.openSettings()).called(1);
    expectNoBlockingFeedback();
  });

  testWidgets('Attiva keeps a tap target of at least 44x44', (tester) async {
    await pumpHint(tester, _denied);

    final size = tester.getSize(
      find.ancestor(of: find.text(_action), matching: find.byType(TextButton)),
    );

    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  for (final state in const [
    NotificationPermissionState(),
    NotificationPermissionState(
      status: NotificationPermissionStatus.notDetermined,
    ),
    NotificationPermissionState(status: NotificationPermissionStatus.granted),
  ]) {
    testWidgets('shows nothing for status ${state.status}', (tester) async {
      await pumpHint(tester, state);

      expect(find.text(_message), findsNothing);
      expect(find.text(_action), findsNothing);
      expectNoBlockingFeedback();
    });
  }

  testWidgets('the row disappears once the permission is granted', (
    tester,
  ) async {
    final states = StreamController<NotificationPermissionState>();
    addTearDown(states.close);
    await pumpHint(tester, _denied, stream: states.stream);
    expect(find.text(_message), findsOneWidget);

    states.add(
      const NotificationPermissionState(
        status: NotificationPermissionStatus.granted,
      ),
    );
    await tester.pump();

    expect(find.text(_message), findsNothing);
    expect(find.text(_action), findsNothing);
  });
}
