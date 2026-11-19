import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/new_entry_category.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/newEntriesCubit/new_entries_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/profile/profile.dart';
import 'package:klimmeck_guide/shared/components/new_entry_sigil.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/landscape.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

const String _birth = 'Nata a Drustea.';
const String _deed = 'Ha salvato Bosa dai predoni.';

void main() {
  late MockCharacterCubit characterCubit;

  setUp(() => characterCubit = MockCharacterCubit());

  Future<MockNewEntriesCubit> pumpProfile(
    WidgetTester tester, {
    required List<String> background,
    Set<String> newEntries = const {},
  }) async {
    useLandscapePhone(tester);
    seedSvgCache([CloudinaryAssets.newEntrySigil]);
    whenListen(
      characterCubit,
      const Stream<CharacterState>.empty(),
      initialState: CharacterLoaded(
        Character.fromJson({
          'id': 'c-1',
          'infos': {'name': 'Aria', 'age': 25, 'background': background},
        }),
      ),
    );
    final entries = quietNewEntriesCubit(
      NewEntriesState(
        highlighted: {
          if (newEntries.isNotEmpty) NewEntryCategory.background: newEntries,
        },
      ),
    );
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<CharacterCubit>.value(value: characterCubit),
              BlocProvider<NewEntriesCubit>.value(value: entries),
            ],
            child: const Profile(),
          ),
        ),
      ),
    );
    await tester.pump();
    return entries;
  }

  testWidgets('shows every background entry in the served order', (
    tester,
  ) async {
    await pumpProfile(tester, background: [_birth, _deed]);

    expect(
      tester.getTopLeft(find.text(_birth)).dy,
      lessThan(tester.getTopLeft(find.text(_deed)).dy),
    );
    expect(find.byType(NewEntrySigil), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new background entry carries the sigil on its line', (
    tester,
  ) async {
    await pumpProfile(tester, background: [_birth, _deed], newEntries: {_deed});

    final sigil = tester.getRect(find.byType(NewEntrySigil));
    expect(find.byType(NewEntrySigil), findsOneWidget);
    expect(sigil.top, closeTo(tester.getTopLeft(find.text(_deed)).dy, 1));
    expect(sigil.right, lessThan(tester.getTopLeft(find.text(_deed)).dx));
  });

  testWidgets('a character without background shows an empty section', (
    tester,
  ) async {
    await pumpProfile(tester, background: const []);

    expect(find.text('Background'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('entering the Profile visits its categories', (tester) async {
    final entries = await pumpProfile(tester, background: [_birth]);

    verify(() => entries.visit(NewEntryCategory.profile)).called(1);
  });
}
