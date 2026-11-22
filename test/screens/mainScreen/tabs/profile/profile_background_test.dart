import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/new_entry_category.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/newEntriesCubit/new_entries_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/profile/components/profile_image.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/profile/profile.dart';
import 'package:klimmeck_guide/shared/components/new_entry_sigil.dart';
import 'package:klimmeck_guide/shared/components/title_badge.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/landscape.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

const String _birth = 'Nata a Drustea.';
const String _deed = 'Ha salvato Bosa dai predoni.';
const String _addition = "L'oste racconta ancora del suo coraggio.";

void main() {
  late MockCharacterCubit characterCubit;

  setUp(() => characterCubit = MockCharacterCubit());

  Future<MockNewEntriesCubit> pumpProfile(
    WidgetTester tester, {
    required List<String> background,
    Set<String> newEntries = const {},
    String? title,
  }) async {
    useLandscapePhone(tester);
    seedSvgCache([
      CloudinaryAssets.newEntrySigil,
      CloudinaryAssets.adventurerRank,
    ]);
    whenListen(
      characterCubit,
      const Stream<CharacterState>.empty(),
      initialState: CharacterLoaded(
        Character.fromJson({
          'id': 'c-1',
          'infos': {'name': 'Aria', 'age': 25, 'background': background},
          if (title != null) 'status': {'title': title},
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
    expect(
      sigil.left,
      greaterThanOrEqualTo(tester.getTopRight(find.text(_deed)).dx),
    );
  });

  testWidgets('only the appended entry carries the sigil (D-09)', (
    tester,
  ) async {
    await pumpProfile(
      tester,
      background: [_birth, _deed, _addition],
      newEntries: {_addition},
    );

    expect(find.byType(NewEntrySigil), findsOneWidget);
    final sigil = tester.getRect(find.byType(NewEntrySigil));
    final appended = tester.getTopLeft(find.text(_addition));
    expect(sigil.top, closeTo(appended.dy, 1));
    expect(
      sigil.left,
      greaterThanOrEqualTo(tester.getTopRight(find.text(_addition)).dx),
    );
    expect(sigil.top, greaterThan(tester.getTopLeft(find.text(_deed)).dy));
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

  testWidgets('the rank medal sits on the top right corner of the portrait', (
    tester,
  ) async {
    await pumpProfile(tester, background: [_birth], title: 'adventurer');

    final medal = tester.getRect(find.byType(TitleBadge));
    final portrait = tester.getRect(find.byKey(ProfileImage.frameKey));
    expect(
      tester.widget<TitleBadge>(find.byType(TitleBadge)).title,
      TitleType.adventurer,
    );
    expect(medal.center.dx, closeTo(portrait.right, medal.width / 2));
    expect(medal.center.dy, closeTo(portrait.top, medal.height / 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a character without rank shows no medal', (tester) async {
    await pumpProfile(tester, background: [_birth]);

    expect(find.byType(TitleBadge), findsNothing);
  });
}
