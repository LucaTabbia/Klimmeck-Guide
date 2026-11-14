import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:klimmeck_guide/graphql/fragments/fragments.dart';
import 'package:klimmeck_guide/graphql/fragments/mission_draft_fragment.dart';
import 'package:klimmeck_guide/graphql/mutations/mission_mutations.dart';
import 'package:klimmeck_guide/graphql/queries/mission_queries.dart';

import '../../tool/schema_check/schema_check_documents.dart';

String _collapsed(String document) =>
    document.replaceAll(RegExp(r'\s+'), ' ').trim();

OperationDefinitionNode _operationOf(String document) => parseString(
  document,
).definitions.whereType<OperationDefinitionNode>().single;

void main() {
  final draftSelection = _collapsed(MissionDraftFragment.fields);
  final enemySelection = _collapsed(MissionEnemyFragment.fields);

  final missionDocuments = <String, String>{
    'GetMissionDraft': MissionQueries.getMissionDraft,
    'ListMissionEnemies': MissionQueries.listMissionEnemies,
    'GetMissionPrizeOptions': MissionQueries.getMissionPrizeOptions,
    'StartMissionDraft': MissionMutations.startMissionDraft,
    'SaveMissionDraft': MissionMutations.saveMissionDraft,
    'SimulateMissionFight': MissionMutations.simulateMissionFight,
    'DiscardMissionDraft': MissionMutations.discardMissionDraft,
    'CompleteGuidedMission': MissionMutations.completeGuidedMission,
  };

  group('MissionDraftFragment', () {
    test('the draft fragment selects the served bounds of each fight '
        '(D-14, D-17)', () {
      expect(
        draftSelection,
        contains(
          'outcomes { character hpBefore injuriesBefore '
          'consumablesAvailable { item quantity } '
          'spellsAvailable { spell usages }',
        ),
      );
    });

    test('the draft fragment selects verdict, simulated and corrected '
        '(D-04, D-06, D-21)', () {
      expect(draftSelection, contains('fights { verdict'));
      expect(
        draftSelection,
        contains(
          'simulated { hpAfter injuriesAdded '
          'consumablesUsed { item quantity } spellsUsed { spell usages } }',
        ),
      );
      expect(
        draftSelection,
        contains(
          'corrected { hpAfter injuriesAdded '
          'consumablesUsed { item quantity } spellsUsed { spell usages } }',
        ),
      );
    });

    test('the draft fragment selects participants and prizes (D-17, D-22)', () {
      expect(
        draftSelection,
        contains(
          'participants { character name title maxLifePoints pendingQuest }',
        ),
      );
      expect(
        draftSelection,
        contains('cure { lifePointsShare canHeal } items { item quantity }'),
      );
    });

    test('the draft fragment nests the enemy fragment (D-03)', () {
      expect(
        draftSelection,
        contains('enemies { quantity enemy { $enemySelection } }'),
      );
    });
  });

  group('MissionEnemyFragment', () {
    test('the enemy fragment selects id name imagePath xp lifePoints '
        'legendary (D-03, D-19)', () {
      expect(enemySelection, 'id name imagePath xp lifePoints legendary');
    });
  });

  group('mission documents', () {
    missionDocuments.forEach((name, document) {
      test('$name is named and registered (D-17)', () {
        expect(_operationOf(document).name?.value, name);
        expect(schemaCheckDocuments[name], document);
      });
    });

    test('the reads are queries, the writes are mutations (D-17)', () {
      for (final name in [
        'GetMissionDraft',
        'ListMissionEnemies',
        'GetMissionPrizeOptions',
      ]) {
        expect(
          _operationOf(missionDocuments[name]!).type,
          OperationType.query,
          reason: name,
        );
      }
      for (final name in [
        'StartMissionDraft',
        'SaveMissionDraft',
        'SimulateMissionFight',
        'DiscardMissionDraft',
        'CompleteGuidedMission',
      ]) {
        expect(
          _operationOf(missionDocuments[name]!).type,
          OperationType.mutation,
          reason: name,
        );
      }
    });

    test('the draft operations return the shared draft selection (D-09)', () {
      for (final document in [
        MissionQueries.getMissionDraft,
        MissionMutations.startMissionDraft,
        MissionMutations.saveMissionDraft,
        MissionMutations.simulateMissionFight,
      ]) {
        expect(_collapsed(document), contains('{ $draftSelection }'));
      }
    });

    test('ListMissionEnemies passes showAll (D-03)', () {
      final variables = _operationOf(
        MissionQueries.listMissionEnemies,
      ).variableDefinitions.map((definition) => definition.variable.name.value);

      expect(variables, ['pendingQuestId', 'showAll']);
      expect(
        _collapsed(MissionQueries.listMissionEnemies),
        contains(
          'missionEnemies(pendingQuestId: \$pendingQuestId, '
          'showAll: \$showAll) { $enemySelection }',
        ),
      );
    });

    test('GetMissionPrizeOptions reads the rank block and the catalogue '
        '(D-07, D-22)', () {
      final document = _collapsed(MissionQueries.getMissionPrizeOptions);

      expect(document, contains('character title maxRarity block {'));
      expect(document, contains('randomLoot { quantity item {'));
      expect(document, contains('... on EquipmentItem {'));
      expect(document, contains('... on LootItem {'));
      expect(document, contains('pets {'));
      expect(document, contains('spells {'));
    });

    test('DiscardMissionDraft returns the common response (D-09)', () {
      expect(
        _collapsed(MissionMutations.discardMissionDraft),
        contains(
          'discardMissionDraft(pendingQuestId: \$pendingQuestId) '
          '{ successful response }',
        ),
      );
    });

    test('CompleteGuidedMission returns the quest result fields (D-08)', () {
      final document = _collapsed(MissionMutations.completeGuidedMission);

      expect(
        document,
        contains(
          'completeGuidedMission(pendingQuestId: \$pendingQuestId) '
          '{ id outcome kind',
        ),
      );
      expect(document, contains(_collapsed(QuestResultFragment.fields)));
    });

    test('no mission document selects missionInProgress', () {
      const lockFlag =
          'mission'
          'InProgress';
      const guidedFlag =
          'guidedMission'
          'InProgress';

      missionDocuments.forEach((name, document) {
        expect(document, isNot(contains(lockFlag)), reason: name);
        expect(document, isNot(contains(guidedFlag)), reason: name);
      });
    });
  });
}
