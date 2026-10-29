import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/request_card_view.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/fixtures/pending_request_fixtures.dart';
import '../../helpers/landscape.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

final DateTime _now = DateTime.utc(2026, 10, 29, 12);

List<PendingRequest> _queue(List<Map<String, dynamic>> entries) =>
    List.unmodifiable(entries.map(PendingRequest.fromJson));

Finder _greyedAncestorOf(Finder finder) => find.ancestor(
  of: finder,
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is Opacity &&
        widget.opacity == KlimmeckGuideTheme.pendingInkOpacity,
  ),
);

void main() {
  late MockPendingRequestsCubit cubit;
  late MockAuthCubit authCubit;

  setUp(() {
    cubit = MockPendingRequestsCubit();
    authCubit = MockAuthCubit();
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(
        user: buildTestUser(role: RoleType.innkeeper),
        accessToken: testAccessToken,
      ),
    );
  });

  Future<void> pumpPanel(
    WidgetTester tester,
    PendingRequestsState state,
  ) async {
    useLandscapePhone(tester);
    whenListen(
      cubit,
      const Stream<PendingRequestsState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      buildTestApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<PendingRequestsCubit>.value(value: cubit),
          ],
          child: const InnkeeperPanelScreen(),
        ),
      ),
    );
  }

  Future<void> pumpQueue(
    WidgetTester tester,
    List<Map<String, dynamic>> entries, {
    DateTime? serverNow,
  }) => pumpPanel(
    tester,
    PendingRequestsState(
      serverNow: serverNow ?? _now,
      requests: _queue(entries),
      isLoaded: true,
    ),
  );

  testWidgets('the AppBar title is «Locanda»', (tester) async {
    await pumpQueue(tester, []);

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Locanda')),
      findsOneWidget,
    );
  });

  testWidgets('before the first snapshot only the loader shows', (
    tester,
  ) async {
    await pumpPanel(tester, PendingRequestsState(serverNow: _now));

    expect(find.byType(KGLoader), findsOneWidget);
    expect(find.byType(RequestCardView), findsNothing);
    expect(find.text(InnkeeperPanelScreen.emptyTitle), findsNothing);
  });

  testWidgets('an empty queue shows the empty state without a loader', (
    tester,
  ) async {
    await pumpQueue(tester, []);

    expect(find.text('Nessuna richiesta in attesa'), findsOneWidget);
    expect(find.text('La coda si aggiorna da sola'), findsOneWidget);
    expect(find.byType(KGLoader), findsNothing);
  });

  testWidgets('a story card shows title, type and the present participant', (
    tester,
  ) async {
    await pumpQueue(tester, [pendingRequestJson()]);

    expect(find.byKey(RequestCardView.keyFor(storyQuestId)), findsOneWidget);
    expect(find.text('La cripta di Valantar'), findsOneWidget);
    expect(find.text('Storia'), findsOneWidget);
    expect(find.text('Aldo'), findsOneWidget);
    expect(find.text('Presente'), findsOneWidget);
    expect(find.textContaining('posti'), findsNothing);
  });

  testWidgets('a card shows only the quest and the rows (D-08)', (
    tester,
  ) async {
    await pumpQueue(tester, [pendingRequestJson()]);

    final texts = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(RequestCardView.keyFor(storyQuestId)),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .toSet();
    expect(texts, {'La cripta di Valantar', 'Storia', 'Aldo', 'Presente'});
  });

  testWidgets('a worldMission card shows the seats', (tester) async {
    await pumpQueue(tester, worldMissionEntriesJson());

    expect(find.text('Missione mondiale'), findsOneWidget);
    expect(find.text('2/3 posti'), findsOneWidget);
    expect(find.text('Bea'), findsOneWidget);
    expect(find.text('Cosimo'), findsOneWidget);
    expect(find.textContaining('registrati'), findsNothing);
  });

  testWidgets('a hidden busy participant leaves the caption', (tester) async {
    await pumpQueue(
      tester,
      worldMissionEntriesJson(
        names: ['Bea', 'Cosimo', 'Dario'],
        busyLanes: {'Dario': 'quest-standard-1'},
      ),
    );

    expect(find.text('Dario'), findsNothing);
    expect(find.text('3/3 posti'), findsOneWidget);
    expect(find.text('2 presenti su 3 registrati'), findsOneWidget);
    expect(
      find.text('Un partecipante è impegnato in una missione'),
      findsOneWidget,
    );
  });

  testWidgets('a traveller row is greyed with the remaining time', (
    tester,
  ) async {
    await pumpQueue(tester, [
      pendingRequestJson(
        activeTravel: queuedTravelJson(
          endTime: _now.add(const Duration(minutes: 12)),
        ),
      ),
    ]);

    expect(find.text('In viaggio · 12 min'), findsOneWidget);
    expect(_greyedAncestorOf(find.text('In viaggio · 12 min')), findsOneWidget);
  });

  testWidgets('a present row is not greyed', (tester) async {
    await pumpQueue(tester, [pendingRequestJson()]);

    expect(_greyedAncestorOf(find.text('Presente')), findsNothing);
  });

  testWidgets('after endTime the traveller reads «Arrivato», not greyed', (
    tester,
  ) async {
    await pumpQueue(tester, [
      pendingRequestJson(
        activeTravel: queuedTravelJson(
          endTime: _now.subtract(const Duration(seconds: 1)),
        ),
      ),
    ]);

    expect(find.text('Arrivato'), findsOneWidget);
    expect(_greyedAncestorOf(find.text('Arrivato')), findsNothing);
  });
}
