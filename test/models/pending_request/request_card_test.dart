import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';

import '../../helpers/fixtures/pending_request_fixtures.dart';

final DateTime serverNow = DateTime.utc(2026, 10, 29, 12);

List<PendingRequest> requestsOf(List<Map<String, dynamic>> json) =>
    json.map(PendingRequest.fromJson).toList();

List<String> namesOf(RequestCard card) =>
    card.participants.map((character) => character.name).toList();

void main() {
  group('requestCardsOf', () {
    test('a story entry is one card without seats', () {
      final cards = requestCardsOf(requestsOf([pendingRequestJson()]));

      final card = cards.single;
      expect(card.questId, storyQuestId);
      expect(card.questTitle, 'La cripta di Valantar');
      expect(card.questType, QuestType.story);
      expect(card.pendingQuestId, 'pq-story-1');
      expect(namesOf(card), ['Aldo']);
      expect(card.entryCount, 1);
      expect(card.totalSeats, 1);
      expect(card.showsSeats, isFalse);
      expect(card.hasHiddenParticipants, isFalse);
    });

    test('a worldMission is one card with its participants in entry order', () {
      final cards = requestCardsOf(
        requestsOf(
          worldMissionEntriesJson(
            names: const ['Bea', 'Cosimo', 'Dora'],
            requiredAdventurers: const [
              {'title': null, 'count': 3},
              {'title': 'paladin', 'count': 1},
            ],
          ),
        ),
      );

      final card = cards.single;
      expect(card.questId, worldMissionQuestId);
      expect(card.pendingQuestId, 'pq-world-1');
      expect(namesOf(card), ['Bea', 'Cosimo', 'Dora']);
      expect(card.entryCount, 3);
      expect(card.totalSeats, 4);
      expect(card.showsSeats, isTrue);
    });

    test('a card takes the rank of its earliest entry (BE order)', () {
      final world = worldMissionEntriesJson();
      final cards = requestCardsOf(
        requestsOf([world[0], pendingRequestJson(), world[1]]),
      );

      expect(cards.map((card) => card.questId), [
        worldMissionQuestId,
        storyQuestId,
      ]);
      expect(namesOf(cards.first), ['Bea', 'Cosimo']);
    });

    test('a busy story makes no card', () {
      final cards = requestCardsOf(
        requestsOf([pendingRequestJson(pendingQuest: 'pq-hunt-1')]),
      );

      expect(cards, isEmpty);
    });

    test('a busy worldMission participant is hidden and blocks the card', () {
      final cards = requestCardsOf(
        requestsOf(
          worldMissionEntriesJson(
            names: const ['Bea', 'Cosimo', 'Dora'],
            busyLanes: const {'Cosimo': 'pq-hunt-1'},
          ),
        ),
      );

      final card = cards.single;
      expect(namesOf(card), ['Bea', 'Dora']);
      expect(card.entryCount, 3);
      expect(card.hasHiddenParticipants, isTrue);
      expect(card.canComplete(serverNow), isFalse);
    });

    test('a worldMission whose participants are all busy makes no card', () {
      final cards = requestCardsOf(
        requestsOf(
          worldMissionEntriesJson(
            busyLanes: const {'Bea': 'pq-hunt-1', 'Cosimo': 'pq-hunt-2'},
          ),
        ),
      );

      expect(cards, isEmpty);
    });

    test('hidden quest ids drop their card and keep the others', () {
      final cards = requestCardsOf(
        requestsOf([...worldMissionEntriesJson(), pendingRequestJson()]),
        hiddenQuestIds: const {worldMissionQuestId},
      );

      expect(cards.map((card) => card.questId), [storyQuestId]);
    });

    test('the cards are unmodifiable', () {
      final cards = requestCardsOf(requestsOf([pendingRequestJson()]));

      expect(() => cards.add(cards.first), throwsUnsupportedError);
    });
  });

  group('RequestCard.canComplete', () {
    RequestCard storyCardWith({
      Map<String, dynamic>? activeTravel,
      Map<String, dynamic>? awaitingAid,
    }) => requestCardsOf(
      requestsOf([
        pendingRequestJson(
          activeTravel: activeTravel,
          awaitingAid: awaitingAid,
        ),
      ]),
    ).single;

    test('a present participant can complete', () {
      expect(storyCardWith().canComplete(serverNow), isTrue);
    });

    test('a traveller blocks until its endTime on the server clock', () {
      final card = storyCardWith(
        activeTravel: queuedTravelJson(
          endTime: serverNow.add(const Duration(minutes: 5)),
        ),
      );

      expect(card.canComplete(serverNow), isFalse);
      expect(
        card.canComplete(serverNow.add(const Duration(minutes: 5))),
        isTrue,
      );
    });

    test('an unreadable travel blocks the completion', () {
      final card = storyCardWith(activeTravel: {'to': 'poi-borgo-marker'});

      expect(card.canComplete(serverNow), isFalse);
    });

    test('a participant awaiting aid can complete', () {
      final card = storyCardWith(awaitingAid: awaitingAidJson());

      expect(card.canComplete(serverNow), isTrue);
    });
  });
}
