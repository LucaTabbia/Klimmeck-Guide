import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_fight.dart';

import '../../helpers/fixtures/mission_fixtures.dart';
import '../../helpers/fixtures/pending_request_fixtures.dart';

void main() {
  group('MissionDraft', () {
    test('reads the whole served draft (D-09, D-17)', () {
      final draft = MissionDraft.tryFromJson(
        missionDraftJson(
          step: 'fights',
          place: 'poi-ruins-1',
          participants: [
            missionParticipantJson(),
            missionParticipantJson(
              character: 'char-bea',
              name: 'Bea',
              title: 'mage',
              maxLifePoints: 600,
              pendingQuest: 'pq-world-2',
            ),
          ],
          fights: [
            missionFightJson(
              verdict: 'success',
              outcomes: [missionOutcomeJson(simulated: missionEffectsJson())],
            ),
          ],
          prizes: [missionPrizeJson()],
        ),
      )!;

      expect(draft.id, 'draft-1');
      expect(draft.questId, worldMissionQuestId);
      expect(draft.questType, QuestType.worldMission);
      expect(draft.step, MissionDraftStep.fights);
      expect(draft.placeId, 'poi-ruins-1');
      expect(draft.startedAt, DateTime.utc(2026, 11, 14, 10));
      expect(draft.updatedAt, DateTime.utc(2026, 11, 14, 10, 5));
      expect(draft.participants, [
        const MissionParticipant(
          characterId: 'char-aldo',
          name: 'Aldo',
          title: TitleType.paladin,
          maxLifePoints: 1000,
          pendingQuestId: 'pq-world-1',
        ),
        const MissionParticipant(
          characterId: 'char-bea',
          name: 'Bea',
          title: TitleType.mage,
          maxLifePoints: 600,
          pendingQuestId: 'pq-world-2',
        ),
      ]);
      expect(draft.fights.single.verdict, MissionFightVerdict.success);
      expect(draft.prizes.single.coins, const Coins(gold: 2));
    });

    test('an unknown step reads null and the draft survives (Pitfall 8)', () {
      final draft = MissionDraft.tryFromJson(
        missionDraftJson(step: 'celebration', questType: 'festival'),
      )!;

      expect(draft.step, isNull);
      expect(draft.questType, isNull);
      expect(draft.id, 'draft-1');
    });

    test('a malformed participant or prize is dropped (Pitfall 8)', () {
      final draft = MissionDraft.tryFromJson(
        missionDraftJson(
          participants: [
            missionParticipantJson(maxLifePoints: null),
            missionParticipantJson(character: 'char-bea', name: 'Bea'),
          ],
          prizes: [
            missionPrizeJson(xp: null),
            missionPrizeJson(character: 'char-bea'),
          ],
        ),
      )!;

      expect(draft.participants.map((p) => p.characterId), ['char-bea']);
      expect(draft.prizes.map((p) => p.characterId), ['char-bea']);
    });

    test('an unknown title reads null, the participant stays (Pitfall 8)', () {
      final draft = MissionDraft.tryFromJson(
        missionDraftJson(participants: [missionParticipantJson(title: 'king')]),
      )!;

      expect(draft.participants.single.title, isNull);
    });

    test('a draft without id or quest is null', () {
      expect(MissionDraft.tryFromJson(missionDraftJson(id: null)), isNull);
      expect(MissionDraft.tryFromJson(missionDraftJson(quest: null)), isNull);
      expect(MissionDraft.tryFromJson('draft-1'), isNull);
      expect(MissionDraft.tryFromJson(null), isNull);
    });

    test('zero fights is a valid draft (D-24)', () {
      final draft = MissionDraft.tryFromJson(missionDraftJson())!;

      expect(draft.fights, isEmpty);
      expect(draft.step, MissionDraftStep.teleport);
    });

    test('allFightsSimulated is false while a fight has no verdict (D-24)', () {
      MissionDraft draftWith(List<Map<String, dynamic>> fights) =>
          MissionDraft.tryFromJson(missionDraftJson(fights: fights))!;

      expect(draftWith(const []).allFightsSimulated, isTrue);
      expect(
        draftWith([missionFightJson(verdict: 'success')]).allFightsSimulated,
        isTrue,
      );
      expect(
        draftWith([
          missionFightJson(verdict: 'success'),
          missionFightJson(),
        ]).allFightsSimulated,
        isFalse,
      );
    });

    test('prizeOf finds a character\'s prize', () {
      final draft = MissionDraft.tryFromJson(
        missionDraftJson(
          prizes: [
            missionPrizeJson(),
            missionPrizeJson(character: 'char-bea', xp: 90),
          ],
        ),
      )!;

      expect(draft.prizeOf('char-bea')!.xp, 90);
      expect(draft.prizeOf('char-aldo')!.xp, 150);
      expect(draft.prizeOf('char-ghost'), isNull);
    });

    test('place is optional (D-01)', () {
      final draft = MissionDraft.tryFromJson(missionDraftJson())!;

      expect(draft.placeId, isNull);
    });
  });
}
