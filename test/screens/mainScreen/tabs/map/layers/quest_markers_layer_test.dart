import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/quest_markers_layer.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/utils/map_constants.dart';

import '../../../../../helpers/fixtures/quest_fixtures.dart';
import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/map_harness.dart';
import '../../../../../helpers/mocks.dart';

/// Sotto lo zoom delle quest il marker esiste ma non disegna l'icona: i test
/// guardano la presenza del marker, non la sua resa.
void main() {
  Future<void> pumpLayer(WidgetTester tester, List<Quest> quests) async {
    useLandscapePhone(tester);
    final questCubit = MockQuestCubit();
    whenListen(
      questCubit,
      const Stream<QuestState>.empty(),
      initialState: QuestLoaded(quests),
    );
    await tester.pumpWidget(
      BlocProvider<QuestCubit>.value(
        value: questCubit,
        child: mapHarness([
          QuestMarkersLayer(
            cities: const [],
            zoomNotifier: ValueNotifier(MapConstants.questVisibleZoom),
            onQuestSelected: (_) {},
          ),
        ]),
      ),
    );
    await tester.pump();
  }

  List<Marker> markersOf(WidgetTester tester) =>
      tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers;

  testWidgets('a quest with a place gets its marker', (tester) async {
    await pumpLayer(tester, [buildQuest(id: 'q-placed')]);

    expect(markersOf(tester).map((m) => m.key), [const ValueKey('q-placed')]);
    expect(find.byKey(const ValueKey('q-placed')), findsOneWidget);
  });

  testWidgets('a story served without a place gets no marker', (tester) async {
    await pumpLayer(tester, [
      buildQuest(id: 'q-placed'),
      buildQuest(
        id: 's-nowhere',
        type: 'story',
        requiredPoints: 100,
        markerId: null,
      ),
    ]);

    expect(tester.takeException(), isNull);
    expect(markersOf(tester).map((m) => m.key), [const ValueKey('q-placed')]);
  });
}
