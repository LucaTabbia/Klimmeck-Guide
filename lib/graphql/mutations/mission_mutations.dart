import '../fragments/fragments.dart';
import '../fragments/mission_draft_fragment.dart';

class MissionMutations {
  /// Crea la bozza dalla pagina «Inizia la missione» (D-28): mai all'apertura.
  static String get startMissionDraft =>
      '''
    mutation StartMissionDraft(\$pendingQuestId: ID!) {
      startMissionDraft(pendingQuestId: \$pendingQuestId) {
        ${MissionDraftFragment.fields}
      }
    }
  ''';

  /// Salva passo, luogo, scontri, correzioni e premi (D-06, D-18): vince
  /// l'ultima scrittura; il BE convalida come gli override di oggi.
  static String get saveMissionDraft =>
      '''
    mutation SaveMissionDraft(\$input: SaveMissionDraftInput!) {
      saveMissionDraft(input: \$input) {
        ${MissionDraftFragment.fields}
      }
    }
  ''';

  /// Simulazione a secco di uno scontro (D-02, D-04, D-24): l'esito si legge
  /// dalla bozza restituita, mai calcolato nell'app.
  static String get simulateMissionFight =>
      '''
    mutation SimulateMissionFight(\$input: SimulateMissionFightInput!) {
      simulateMissionFight(input: \$input) {
        ${MissionDraftFragment.fields}
      }
    }
  ''';

  /// Scarta la bozza della richiesta (D-09).
  static const String discardMissionDraft = '''
    mutation DiscardMissionDraft(\$pendingQuestId: ID!) {
      discardMissionDraft(pendingQuestId: \$pendingQuestId) {
        successful
        response
      }
    }
  ''';

  /// Completa la missione leggendo la bozza (D-05, D-08, D-25): restituisce
  /// gli esiti creati, come `completePendingRequest`.
  static String get completeGuidedMission =>
      '''
    mutation CompleteGuidedMission(\$pendingQuestId: ID!) {
      completeGuidedMission(pendingQuestId: \$pendingQuestId) {
        ${QuestResultFragment.fields}
      }
    }
  ''';
}
