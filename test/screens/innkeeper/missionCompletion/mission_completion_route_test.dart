import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/screens/innkeeper/completion_exit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_route.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../helpers/landscape.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

final List<PendingRequest> _entries = worldMissionEntriesJson(
  names: const ['Aldo', 'Bea'],
).map(PendingRequest.fromJson).toList();

final RequestCard _card = requestCardsOf(_entries).single;

void main() {
  testWidgets(
    'openMissionCompletion pushes the wizard with the queue and the teleport mode of the panel and loads the draft (Phase 10 D-04, D-28)',
    (tester) async {
      useLandscapePhone(tester);
      final repository = MockInnkeeperRepository();
      final queue = MockPendingRequestsCubit();
      final teleport = MockTeleportModeCubit();
      when(
        () => repository.readMissionDraft(_card.pendingQuestId),
      ).thenAnswer((_) async => null);
      whenListen(
        queue,
        const Stream<PendingRequestsState>.empty(),
        initialState: PendingRequestsState(
          serverNow: DateTime.utc(2026, 11, 14, 12),
          requests: _entries,
          isLoaded: true,
        ),
      );
      whenListen(
        teleport,
        const Stream<TeleportModeState>.empty(),
        initialState: const TeleportIdle(),
      );
      final exits = <CompletionExit?>[];
      await tester.pumpWidget(
        buildTestApp(
          home: RepositoryProvider<InnkeeperRepository>.value(
            value: repository,
            child: MultiBlocProvider(
              providers: [
                BlocProvider<PendingRequestsCubit>.value(value: queue),
                BlocProvider<TeleportModeCubit>.value(value: teleport),
              ],
              child: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async =>
                        exits.add(await openMissionCompletion(context, _card)),
                    child: const Text('apri'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('apri'));
      await tester.pumpAndSettle();

      expect(find.byType(MissionCompletionScreen), findsOneWidget);
      expect(find.byKey(MissionCompletionScreen.startKey), findsOneWidget);
      verify(() => repository.readMissionDraft(_card.pendingQuestId)).called(1);
      verifyNever(() => repository.startMissionDraft(any()));
      expect(exits, isEmpty);
    },
  );
}
