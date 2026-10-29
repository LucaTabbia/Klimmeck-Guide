import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/pending_request/participant_presence.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';

import '../../helpers/fixtures/pending_request_fixtures.dart';

final DateTime serverNow = DateTime.utc(2026, 10, 29, 12);

PendingRequestCharacter characterOf(Map<String, dynamic> json) =>
    PendingRequest.fromJson(json).character;

void main() {
  group('presenceOf', () {
    test('a character awaiting aid is awaiting aid, even while travelling', () {
      final character = characterOf(
        pendingRequestJson(
          awaitingAid: awaitingAidJson(),
          activeTravel: queuedTravelJson(
            endTime: serverNow.add(const Duration(minutes: 12)),
          ),
        ),
      );

      expect(presenceOf(character, serverNow), const ParticipantAwaitingAid());
    });

    test('a travel ending after the server time is travelling', () {
      final character = characterOf(
        pendingRequestJson(
          activeTravel: queuedTravelJson(
            endTime: serverNow.add(const Duration(minutes: 12)),
          ),
        ),
      );

      expect(
        presenceOf(character, serverNow),
        const ParticipantTravelling(remaining: Duration(minutes: 12)),
      );
    });

    test('a travel ending at the server time has arrived', () {
      final character = characterOf(
        pendingRequestJson(activeTravel: queuedTravelJson(endTime: serverNow)),
      );

      expect(presenceOf(character, serverNow), const ParticipantArrived());
    });

    test('a travel ended before the server time has arrived', () {
      final character = characterOf(
        pendingRequestJson(
          activeTravel: queuedTravelJson(
            endTime: serverNow.subtract(const Duration(seconds: 30)),
          ),
        ),
      );

      expect(presenceOf(character, serverNow), const ParticipantArrived());
    });

    test('an unreadable travel is travelling with an unknown time', () {
      final character = characterOf(
        pendingRequestJson(activeTravel: {'to': 'poi-borgo-marker'}),
      );

      expect(
        presenceOf(character, serverNow),
        const ParticipantTravellingUnknown(),
      );
    });

    test('a character without travel nor aid is present', () {
      expect(
        presenceOf(characterOf(pendingRequestJson()), serverNow),
        const ParticipantPresent(),
      );
    });
  });

  test('only a travel in progress or unreadable blocks the completion', () {
    expect(const ParticipantPresent().blocksCompletion, isFalse);
    expect(const ParticipantArrived().blocksCompletion, isFalse);
    expect(const ParticipantAwaitingAid().blocksCompletion, isFalse);
    expect(
      const ParticipantTravelling(
        remaining: Duration(minutes: 1),
      ).blocksCompletion,
      isTrue,
    );
    expect(const ParticipantTravellingUnknown().blocksCompletion, isTrue);
  });
}
