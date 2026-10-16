import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/settings.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures/sync_event_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/test_app.dart';

void main() {
  late MockCharacterCubit characterCubit;
  late MockNotificationPreferencesCubit notificationCubit;
  late MockCharacterDeletionCubit deletionCubit;
  late MockAuthCubit authCubit;

  setUp(() {
    characterCubit = MockCharacterCubit();
    notificationCubit = MockNotificationPreferencesCubit();
    deletionCubit = MockCharacterDeletionCubit();
    authCubit = MockAuthCubit();
    whenListen(
      notificationCubit,
      const Stream<NotificationPreferencesState>.empty(),
      initialState: const NotificationPreferencesState(isLoaded: true),
    );
    whenListen(
      deletionCubit,
      const Stream<CharacterDeletionState>.empty(),
      initialState: const CharacterDeletionState(),
    );
    when(() => authCubit.logout()).thenAnswer((_) async {});
  });

  Future<void> pumpSettings(WidgetTester tester, CharacterState state) async {
    useLandscapePhone(tester);
    whenListen(
      characterCubit,
      const Stream<CharacterState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      buildTestApp(
        home: Material(
          child: MultiBlocProvider(
            providers: [
              BlocProvider<CharacterCubit>.value(value: characterCubit),
              BlocProvider<NotificationPreferencesCubit>.value(
                value: notificationCubit,
              ),
              BlocProvider<CharacterDeletionCubit>.value(value: deletionCubit),
              BlocProvider<AuthCubit>.value(value: authCubit),
            ],
            child: const Settings(),
          ),
        ),
      ),
    );
  }

  CharacterLoaded loadedAldo() => CharacterLoaded(
    Character.fromJson({
      ...characterJson(),
      'infos': {'name': 'Aldo'},
    }),
  );

  testWidgets('renders header, sections and controls in order', (tester) async {
    await pumpSettings(tester, loadedAldo());

    for (final text in [
      'Impostazioni',
      'Aldo',
      'Notifiche',
      'Fine viaggio',
      'Account',
      'Elimina personaggio',
      'Esci',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    final ordered = [
      'Impostazioni',
      'Aldo',
      'Notifiche',
      'Fine viaggio',
      'Account',
      'Elimina personaggio',
      'Esci',
    ].map(top).toList();
    expect(ordered, [...ordered]..sort());
    expect(find.text('Streamer in live'), findsOneWidget);
    expect(find.text('Fine quest'), findsOneWidget);
  });

  testWidgets('has no AppBar nor Scaffold, uses background and scroll', (
    tester,
  ) async {
    await pumpSettings(tester, loadedAldo());

    Finder inSettings(Type type) =>
        find.descendant(of: find.byType(Settings), matching: find.byType(type));
    expect(inSettings(AppBar), findsNothing);
    expect(inSettings(Scaffold), findsNothing);
    expect(inSettings(BackgroundImage), findsOneWidget);
    expect(inSettings(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('without a loaded character shows no name and no spinner', (
    tester,
  ) async {
    await pumpSettings(tester, CharacterInitial());

    expect(find.text('Aldo'), findsNothing);
    expect(find.text('Notifiche'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Esci is reachable by scrolling and opens the logout dialog', (
    tester,
  ) async {
    await pumpSettings(tester, loadedAldo());

    await tester.ensureVisible(find.text('Esci'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esci'));
    await tester.pumpAndSettle();

    expect(find.text('Sei sicuro di voler uscire?'), findsOneWidget);
  });

  testWidgets('deletion dialog names the character from the header', (
    tester,
  ) async {
    await pumpSettings(tester, loadedAldo());

    await tester.ensureVisible(find.text('Elimina personaggio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina personaggio'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "Sei sicuro di voler eliminare Aldo? L'azione è irreversibile.",
      ),
      findsOneWidget,
    );
  });
}
