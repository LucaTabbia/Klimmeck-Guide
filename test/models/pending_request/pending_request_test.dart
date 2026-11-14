import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/awaiting_aid.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/queued_travel.dart';

import '../../helpers/fixtures/pending_request_fixtures.dart';

void main() {
  group('PendingRequest.fromJson', () {
    test('reads the story entry as the FE selects it', () {
      final request = PendingRequest.fromJson(pendingRequestJson());

      expect(request.id, 'pq-story-1');
      expect(request.startDate, DateTime.utc(2026, 10, 29, 10));
      expect(request.quest.id, storyQuestId);
      expect(request.quest.title, 'La cripta di Valantar');
      expect(request.quest.type, QuestType.story);
      expect(request.quest.totalSeats, 1);
      expect(request.character.id, 'char-aldo');
      expect(request.character.name, 'Aldo');
      expect(request.character.locationId, 'poi-valantar-marker');
      expect(request.character.travel, isNull);
      expect(request.character.hasUnreadableTravel, isFalse);
      expect(request.character.awaitingAid, isNull);
      expect(request.character.pendingQuestId, isNull);
      expect(request.character.isBusy, isFalse);
    });

    test('an entry without the pendingQuest key (BE develop) is not busy', () {
      final json = pendingRequestJson();
      expect((json['character'] as Map).containsKey('pendingQuest'), isFalse);

      final request = PendingRequest.fromJson(json);

      expect(request.character.pendingQuestId, isNull);
      expect(request.character.isBusy, isFalse);
    });

    test('an occupied standard lane makes the character busy', () {
      final request = PendingRequest.fromJson(
        pendingRequestJson(pendingQuest: 'pq-hunt-1'),
      );

      expect(request.character.pendingQuestId, 'pq-hunt-1');
      expect(request.character.isBusy, isTrue);
    });

    test('the merged BE shape with a busy lane makes the character busy', () {
      final request = PendingRequest.fromJson(
        mergedPendingRequestJson(pendingQuest: 'pq-hunt-7'),
      );

      expect(request.character.pendingQuestId, 'pq-hunt-7');
      expect(request.character.isBusy, isTrue);
    });

    test('the merged BE shape with an explicit null lane is not busy', () {
      final json = mergedPendingRequestJson();
      expect((json['character'] as Map)['pendingQuest'], isNull);
      expect((json['character'] as Map).containsKey('pendingQuest'), isTrue);

      final request = PendingRequest.fromJson(json);

      expect(request.character.pendingQuestId, isNull);
      expect(request.character.isBusy, isFalse);
    });

    test('a free travel is read with a UTC endTime and its destination', () {
      final endTime = DateTime.utc(2026, 10, 29, 12, 12);
      final request = PendingRequest.fromJson(
        pendingRequestJson(activeTravel: queuedTravelJson(endTime: endTime)),
      );

      expect(
        request.character.travel,
        QueuedTravel(endTime: endTime, destinationId: 'poi-borgo-marker'),
      );
      expect(request.character.travel!.endTime.isUtc, isTrue);
      expect(request.character.hasUnreadableTravel, isFalse);
    });

    test('an unreadable travel is fail-closed, never «not travelling»', () {
      final request = PendingRequest.fromJson(
        pendingRequestJson(activeTravel: {'to': 'poi-borgo-marker'}),
      );

      expect(request.character.travel, isNull);
      expect(request.character.hasUnreadableTravel, isTrue);
    });

    test('awaitingAid is read as an AwaitingAid', () {
      final request = PendingRequest.fromJson(
        pendingRequestJson(awaitingAid: awaitingAidJson()),
      );

      expect(request.character.awaitingAid, isA<AwaitingAid>());
    });

    test('an unknown quest type keeps the entry with a null type', () {
      final request = PendingRequest.fromJson(
        pendingRequestJson(questType: 'emperorQuest'),
      );

      expect(request.quest.type, isNull);
      expect(request.id, 'pq-story-1');
    });

    test('totalSeats sums every slot, any rank included', () {
      final request = PendingRequest.fromJson(
        pendingRequestJson(
          requiredAdventurers: const [
            {'title': null, 'count': 2},
            {'title': 'paladin', 'count': 1},
          ],
        ),
      );

      expect(request.quest.totalSeats, 3);
    });

    test('two parses of the same JSON are equal', () {
      final json = pendingRequestJson(
        activeTravel: queuedTravelJson(
          endTime: DateTime.utc(2026, 10, 29, 12, 12),
        ),
        awaitingAid: awaitingAidJson(),
        pendingQuest: 'pq-hunt-1',
      );

      expect(PendingRequest.fromJson(json), PendingRequest.fromJson(json));
    });
  });

  group('missionDraftStartedAt (Phase 21)', () {
    test('reads missionDraftStartedAt when served (D-17)', () {
      final request = PendingRequest.fromJson(
        pendingRequestJson()
          ..['missionDraftStartedAt'] = '2026-11-14T11:00:00.000+01:00',
      );

      expect(request.missionDraftStartedAt, DateTime.utc(2026, 11, 14, 10));
      expect(request.missionDraftStartedAt!.isUtc, isTrue);
    });

    test('absent or malformed missionDraftStartedAt is null and the entry '
        'survives (D-17, Pitfall 8)', () {
      for (final raw in <Object?>[null, 'not-a-date', 42, true]) {
        final json = pendingRequestJson()..['missionDraftStartedAt'] = raw;

        final request = PendingRequest.tryFromJson(json);

        expect(request, isNotNull, reason: '$raw');
        expect(request!.missionDraftStartedAt, isNull, reason: '$raw');
      }
      expect(
        PendingRequest.fromJson(pendingRequestJson()).missionDraftStartedAt,
        isNull,
      );
    });

    test('two entries differing only in the draft are not equal (D-17)', () {
      final started = pendingRequestJson()
        ..['missionDraftStartedAt'] = '2026-11-14T10:00:00.000Z';

      expect(
        PendingRequest.fromJson(started),
        isNot(PendingRequest.fromJson(pendingRequestJson())),
      );
    });
  });

  group('PendingRequest.tryFromJson', () {
    test('returns the entry for a valid JSON', () {
      expect(PendingRequest.tryFromJson(pendingRequestJson()), isNotNull);
    });

    test('returns null for a non-map', () {
      expect(PendingRequest.tryFromJson('pq-story-1'), isNull);
      expect(PendingRequest.tryFromJson(null), isNull);
    });

    test('returns null without the character name', () {
      final json = pendingRequestJson();
      (json['character'] as Map<String, dynamic>).remove('name');

      expect(PendingRequest.tryFromJson(json), isNull);
    });

    test('returns null without the quest id', () {
      final json = pendingRequestJson();
      (json['quest'] as Map<String, dynamic>).remove('id');

      expect(PendingRequest.tryFromJson(json), isNull);
    });

    test('returns null for an unknown slot title', () {
      final json = pendingRequestJson(
        requiredAdventurers: const [
          {'title': 'emperor', 'count': 1},
        ],
      );

      expect(PendingRequest.tryFromJson(json), isNull);
    });

    test('returns null for a non-string pendingQuest', () {
      expect(
        PendingRequest.tryFromJson(pendingRequestJson(pendingQuest: 42)),
        isNull,
      );
    });
  });

  group('totalSeats (quick 261111-enm)', () {
    const seats = [
      {'title': 'rookie', 'count': 3},
    ];

    PendingRequest requestOf(String type) => PendingRequest.fromJson(
      pendingRequestJson(questType: type, requiredAdventurers: seats),
    );

    test('an enemy counts one seat whatever it carries '
        '(quick 261111-enm)', () {
      expect(requestOf('enemy').quest.totalSeats, 1);
    });

    test('a boss counts its wire seats (quick 261111-enm)', () {
      expect(requestOf('boss').quest.totalSeats, 3);
    });
  });
}
