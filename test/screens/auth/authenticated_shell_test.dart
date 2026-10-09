import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/screens/auth/authenticated_shell.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:klimmeck_guide/screens/splash/splash_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

void main() {
  late MockSplashCubit splashCubit;

  setUp(() {
    splashCubit = MockSplashCubit();
    when(() => splashCubit.getImages(any())).thenAnswer((_) async {});
    when(() => splashCubit.startBootstrapWatch()).thenReturn(null);
    when(() => splashCubit.stopBootstrapWatch()).thenReturn(null);
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    required SplashState state,
    Widget Function(BuildContext, String)? mainScreenBuilder,
  }) async {
    whenListen(
      splashCubit,
      const Stream<SplashState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      buildTestApp(
        home: BlocProvider<SplashCubit>.value(
          value: splashCubit,
          child: AuthenticatedShell(
            graphQl: KlimmeckGraphQl(),
            characterId: testCharacterId,
            mainScreenBuilder: mainScreenBuilder ?? (_, id) => Text('main $id'),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('preloads images once and shows the splash while loading', (
    tester,
  ) async {
    await pumpShell(tester, state: const SplashInitial());

    verify(() => splashCubit.getImages('main')).called(1);
    final splash = tester.widget<SplashScreen>(find.byType(SplashScreen));
    expect(splash.watchConnection, isFalse);
    expect(find.text('main $testCharacterId'), findsNothing);
    verifyNever(() => splashCubit.startBootstrapWatch());
  });

  testWidgets('enters the main screen once images are ready', (tester) async {
    await pumpShell(tester, state: const SplashData());

    expect(find.text('main $testCharacterId'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('a failed preload does not block the main screen', (
    tester,
  ) async {
    await pumpShell(tester, state: const SplashError('offline'));

    expect(find.text('main $testCharacterId'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('provides the gameplay cubits and closes them on removal', (
    tester,
  ) async {
    late CharacterCubit characterCubit;
    late QuestCubit questCubit;
    await pumpShell(
      tester,
      state: const SplashData(),
      mainScreenBuilder: (context, _) {
        characterCubit = context.read<CharacterCubit>();
        questCubit = context.read<QuestCubit>();
        return const Text('main');
      },
    );

    expect(characterCubit.isClosed, isFalse);

    await tester.pumpWidget(buildTestApp(home: const SizedBox.shrink()));

    expect(characterCubit.isClosed, isTrue);
    expect(questCubit.isClosed, isTrue);
  });
}
