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
      expect(card.cardKey, 'pq-story-1');
      expect(namesOf(card), ['Aldo']);
      expect(card.entryCount, 1);
      expect(card.totalSeats, 1);
      expect(card.showsSeats, isFalse);
      expect(card.hasHiddenParticipants, isFalse);
    });

    test('two story entries of different characters are two cards', () {
      final cards = requestCardsOf(
        requestsOf([
          pendingRequestJson(),
          pendingRequestJson(
            id: 'pq-story-2',
            characterId: 'char-bea',
            characterName: 'Bea',
          ),
        ]),
      );

      expect(cards.map((card) => card.cardKey), ['pq-story-1', 'pq-story-2']);
      expect(cards.map((card) => card.pendingQuestId), [
        'pq-story-1',
        'pq-story-2',
      ]);
      expect(cards.map(namesOf), [
        ['Aldo'],
        ['Bea'],
      ]);
      expect(cards.every((card) => card.questId == storyQuestId), isTrue);
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
      expect(card.cardKey, worldMissionQuestId);
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
        hiddenCardKeys: const {worldMissionQuestId},
      );

      expect(cards.map((card) => card.questId), [storyQuestId]);
    });

    test('the cards are unmodifiable', () {
      final cards = requestCardsOf(requestsOf([pendingRequestJson()]));

      expect(() => cards.add(cards.first), throwsUnsupportedError);
    });
  });

  group('RequestCard.isActionable (UAT 2026-11-01)', () {
    test('a present story is actionable', () {
      final card = requestCardsOf(requestsOf([pendingRequestJson()])).single;

      expect(card.hasAllSeats, isTrue);
      expect(card.isActionable(serverNow), isTrue);
    });

    test('a travelling participant blocks the card until its end time', () {
      final endTime = serverNow.add(const Duration(minutes: 12));
      final card = requestCardsOf(
        requestsOf([
          pendingRequestJson(activeTravel: queuedTravelJson(endTime: endTime)),
        ]),
      ).single;

      expect(card.isActionable(serverNow), isFalse);
      expect(card.isActionable(endTime), isTrue);
    });

    test('a worldMission with free seats is not actionable', () {
      final card = requestCardsOf(
        requestsOf(
          worldMissionEntriesJson(
            requiredAdventurers: const [
              {'title': null, 'count': 3},
            ],
          ),
        ),
      ).single;

      expect(card.hasAllSeats, isFalse);
      expect(card.isActionable(serverNow), isFalse);
    });

    test('a full worldMission with everyone present is actionable', () {
      final card = requestCardsOf(requestsOf(worldMissionEntriesJson())).single;

      expect(card.hasAllSeats, isTrue);
      expect(card.isActionable(serverNow), isTrue);
    });

    test('a hidden busy participant makes the card not actionable', () {
      final card = requestCardsOf(
        requestsOf(
          worldMissionEntriesJson(
            names: const ['Bea', 'Cosimo', 'Dora'],
            requiredAdventurers: const [
              {'title': null, 'count': 3},
            ],
            busyLanes: const {'Cosimo': 'pq-hunt-1'},
          ),
        ),
      ).single;

      expect(card.isActionable(serverNow), isFalse);
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

    test('a participant awaiting aid blocks the card (UAT 2026-11-01)', () {
      final card = storyCardWith(awaitingAid: awaitingAidJson());

      expect(card.canComplete(serverNow), isFalse);
      expect(card.isActionable(serverNow), isFalse);
    });
  });
}
