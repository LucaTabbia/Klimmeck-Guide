import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/notification_preferences_section.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/test_app.dart';

void main() {
  late MockNotificationPreferencesCubit cubit;

  setUpAll(() => registerFallbackValue(NotificationCategory.travelEnd));

  setUp(() {
    cubit = MockNotificationPreferencesCubit();
    when(
      () => cubit.toggle(any(), enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpSection(
    WidgetTester tester,
    NotificationPreferencesState state,
  ) async {
    whenListen(
      cubit,
      const Stream<NotificationPreferencesState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      buildTestApp(
        home: Material(
          child: BlocProvider<NotificationPreferencesCubit>.value(
            value: cubit,
            child: const SingleChildScrollView(
              child: NotificationPreferencesSection(),
            ),
          ),
        ),
      ),
    );
  }

  Finder tileOf(String storageKey) =>
      find.byKey(ValueKey('notification-switch-$storageKey'));

  SwitchListTile tile(WidgetTester tester, String storageKey) =>
      tester.widget<SwitchListTile>(tileOf(storageKey));

  testWidgets('shows title and three labelled switches in order', (
    tester,
  ) async {
    await pumpSection(
      tester,
      const NotificationPreferencesState(isLoaded: true),
    );

    expect(find.text('Notifiche'), findsOneWidget);
    final travel = tester.getTopLeft(find.text('Fine viaggio')).dy;
    final live = tester.getTopLeft(find.text('Streamer in live')).dy;
    final quest = tester.getTopLeft(find.text('Fine quest')).dy;
    expect(travel < live && live < quest, isTrue);
    for (final key in ['travel_end', 'streamer_live', 'quest_end']) {
      expect(tile(tester, key).value, isTrue);
    }
  });

  testWidgets('reflects a disabled category', (tester) async {
    await pumpSection(
      tester,
      const NotificationPreferencesState(
        enabled: {
          NotificationCategory.travelEnd: true,
          NotificationCategory.streamerLive: false,
          NotificationCategory.questEnd: true,
        },
        isLoaded: true,
      ),
    );

    expect(tile(tester, 'streamer_live').value, isFalse);
    expect(tile(tester, 'travel_end').value, isTrue);
    expect(tile(tester, 'quest_end').value, isTrue);
  });

  testWidgets('tapping a switch toggles its category once', (tester) async {
    await pumpSection(
      tester,
      const NotificationPreferencesState(isLoaded: true),
    );

    await tester.tap(tileOf('quest_end'));
    await tester.pump();

    verify(
      () => cubit.toggle(NotificationCategory.questEnd, enabled: false),
    ).called(1);
  });

  testWidgets('is inert without a spinner until loaded', (tester) async {
    await pumpSection(tester, const NotificationPreferencesState());

    for (final key in ['travel_end', 'streamer_live', 'quest_end']) {
      expect(tile(tester, key).onChanged, isNull);
    }
    await tester.tap(tileOf('travel_end'));
    await tester.pump();

    verifyNever(() => cubit.toggle(any(), enabled: any(named: 'enabled')));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows no permission hint and keeps tap targets >= 44', (
    tester,
  ) async {
    await pumpSection(
      tester,
      const NotificationPreferencesState(isLoaded: true),
    );

    expect(
      find.textContaining(RegExp('permess', caseSensitive: false)),
      findsNothing,
    );
    for (final key in ['travel_end', 'streamer_live', 'quest_end']) {
      expect(tester.getSize(tileOf(key)).height, greaterThanOrEqualTo(44));
    }
  });
}
