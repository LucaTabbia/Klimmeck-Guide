import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/cubit/main_screen_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/main_screen.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

void main() {
  late MockCharacterCubit characterCubit;
  late MockQuestCubit questCubit;
  late MockMainScreenCubit mainScreenCubit;

  setUp(() {
    characterCubit = MockCharacterCubit();
    questCubit = MockQuestCubit();
    mainScreenCubit = MockMainScreenCubit();
    whenListen(
      characterCubit,
      Stream<CharacterState>.empty(),
      initialState: CharacterInitial(),
    );
    whenListen(
      questCubit,
      Stream<QuestState>.empty(),
      initialState: QuestInitial(),
    );
    whenListen(
      mainScreenCubit,
      Stream<MainScreenState>.empty(),
      initialState: MainScreenInitial(),
    );
    when(() => characterCubit.loadCharacter(any())).thenAnswer((_) async {});
    when(() => questCubit.loadQuest()).thenAnswer((_) async {});
  });

  testWidgets('loads exactly the character of the session', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<QuestCubit>.value(value: questCubit),
            BlocProvider<MainScreenCubit>.value(value: mainScreenCubit),
          ],
          child: const MainScreen(characterId: 'c-42'),
        ),
      ),
    );
    await tester.pump();

    verify(() => characterCubit.loadCharacter('c-42')).called(1);
    verify(() => questCubit.loadQuest()).called(1);
  });
}
