import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_scope.dart';

import '../../../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../../../helpers/fixtures/shop_fixtures.dart';
import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/test_app.dart';

const _worg = 'pet-worg';

final DateTime _t0 = DateTime.utc(2026, 11, 14, 10);

Character _character({required int currentLifePoints, String? equipped}) =>
    Character.fromJson({
      'id': 'c-1',
      'assets': {
        'pet': equipped == null
            ? null
            : petJson(id: equipped, name: 'Worg', maxLifePoints: 100),
        'ownedPets': [
          ownedPetJson(
            pet: petJson(id: _worg, name: 'Worg', maxLifePoints: 100),
            currentLifePoints: currentLifePoints,
            lifeAsOf: _t0.toIso8601String(),
            fullLifeAt: _t0.add(const Duration(hours: 2)).toIso8601String(),
          ),
        ],
      },
    });

void main() {
  late MockCharacterCubit characterCubit;
  late StreamController<CharacterState> characterStates;

  setUp(() {
    characterCubit = MockCharacterCubit();
    characterStates = StreamController<CharacterState>.broadcast();
    addTearDown(characterStates.close);
    whenListen(
      characterCubit,
      characterStates.stream,
      initialState: CharacterLoaded(_character(currentLifePoints: 20)),
    );
  });

  Future<void> pumpScope(WidgetTester tester) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: RepositoryProvider<ServerClockService>.value(
          value: FakeServerClockService(_t0.add(const Duration(hours: 1))),
          child: BlocProvider<CharacterCubit>.value(
            value: characterCubit,
            child: CompanionVitalityScope(
              child:
                  BlocBuilder<CompanionVitalityCubit, CompanionVitalityState>(
                    builder: (context, state) =>
                        Text('life ${state.vitalityOf(_worg)?.life}'),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the scope follows the character\'s owned companions and the '
      'equipped pet (D-09)', (tester) async {
    await pumpScope(tester);
    expect(find.text('life 60'), findsOneWidget);

    characterStates.add(CharacterLoaded(_character(currentLifePoints: 40)));
    await tester.pumpAndSettle();
    expect(find.text('life 70'), findsOneWidget);

    characterStates.add(
      CharacterLoaded(_character(currentLifePoints: 40, equipped: _worg)),
    );
    await tester.pumpAndSettle();
    expect(find.text('life 40'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
