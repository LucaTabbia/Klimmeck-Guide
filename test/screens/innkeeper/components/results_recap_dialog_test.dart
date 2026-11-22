import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/results_recap_dialog.dart';

import '../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../helpers/fixtures/quest_result_fixtures.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/title_badge_finder.dart';

final RequestCard _card = requestCardsOf(
  worldMissionEntriesJson().map(PendingRequest.fromJson).toList(),
).single;

QuestResult _result({required String titleAfter}) => QuestResult.fromJson(
  questResultJson(
    character: 'char-bea',
    outcome: 'gmCompleted',
    titleBefore: 'rookie',
    titleAfter: titleAfter,
  ),
);

void main() {
  Future<void> openRecap(WidgetTester tester, QuestResult result) async {
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showResultsRecap(context, card: _card, results: [result]),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a title change is drawn with the two badges', (tester) async {
    await openRecap(tester, _result(titleAfter: 'adventurer'));

    expect(findTitleBadge(TitleType.rookie), findsOneWidget);
    expect(findTitleBadge(TitleType.adventurer), findsOneWidget);
    expect(find.textContaining('Recluta'), findsNothing);
  });

  testWidgets('an unchanged title draws no badge', (tester) async {
    await openRecap(tester, _result(titleAfter: 'rookie'));

    expect(findTitleBadge(TitleType.rookie), findsNothing);
  });
}
