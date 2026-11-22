import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/enums/column_layout_type.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_fight.dart';
import 'package:klimmeck_guide/models/mission/mission_prize.dart';
import 'package:klimmeck_guide/models/mission/mission_prize_options.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/quantity_line.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/mission_back_button.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/participant_story.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/completion_recap.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionPrizeOptionsCubit/mission_prize_options_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

/// Righe del riepilogo dalla sola bozza servita (D-08), come le legge la
/// conferma: quelle della missione, poi quelle di ogni personaggio precedute
/// dal suo nome.
List<String> missionRecapLinesOf({
  required String questTitle,
  required MissionDraft draft,
}) => [
  ...missionWideRecapLinesOf(questTitle: questTitle, draft: draft),
  for (final participant in draft.participants)
    ..._namedLines(
      participant.name,
      participantRecapLinesOf(participant, draft.fights),
    ),
];

/// Righe della missione intera: titolo e scontri (Phase 24 D-23).
List<String> missionWideRecapLinesOf({
  required String questTitle,
  required MissionDraft draft,
}) => [
  questTitle,
  for (final (index, fight) in draft.fights.indexed) _fightLine(index, fight),
];

String _fightLine(int index, MissionFight fight) {
  final enemies = fight.enemies
      .map((entry) => quantityLine(entry.quantity, entry.enemy.name))
      .join(', ');
  final verdict = fight.verdict;
  final suffix = verdict == null ? '' : ' · ${verdict.label}';
  return 'Scontro ${index + 1}: $enemies$suffix';
}

/// Righe di un personaggio senza il suo nome: PV, ferite aggiunte e ferite
/// tolte (Phase 24 D-13, D-23). D-24: senza scontri nessuna riga; PV
/// dall'inizio del primo scontro all'effetto valido dell'ultimo (la
/// correzione vince, D-06).
List<String> participantRecapLinesOf(
  MissionParticipant participant,
  List<MissionFight> fights,
) {
  final id = participant.characterId;
  final first = fights.firstOrNull?.outcomeOf(id);
  final last = fights.lastOrNull?.outcomeOf(id)?.effective;
  if (first == null || last == null) return const [];
  final effects = [for (final fight in fights) ?fight.outcomeOf(id)?.effective];
  final added = {for (final effect in effects) ...effect.injuriesAdded};
  final removed = {for (final effect in effects) ...effect.injuriesRemoved};
  return [
    'PV ${first.hpBefore} → ${last.hpAfter}',
    if (added.isNotEmpty) 'Ferite: ${_injuryNamesOf(added)}',
    if (removed.isNotEmpty) 'Ferite tolte: ${_injuryNamesOf(removed)}',
  ];
}

List<String> _namedLines(String name, List<String> lines) => [
  if (lines.firstOrNull case final first?) '$name: $first',
  ...lines.skip(1),
];

String _injuryNamesOf(Set<InjuryType> injuries) =>
    injuries.map((injury) => injury.label.toLowerCase()).join(', ');

/// Conferma esplicita, in stile neutro, prima di completare la missione
/// (D-08): la chiedono «Completa» sul riepilogo e «Concludi» sull'ultima
/// pagina (Phase 24 D-05).
Future<bool> confirmMissionCompletion(
  BuildContext context, {
  required List<String> lines,
}) => showDestructiveConfirmation(
  context,
  title: MissionCompletionScreen.title,
  body: lines.join('\n'),
  confirmLabel: RecapStep.completeLabel,
  confirmButtonStyle: KlimmeckGuideTheme.primaryButtonStyle,
);

/// Passo «Riepilogo» (D-05, D-08): in cima le righe della missione, poi una
/// tendina chiusa per personaggio con vita, ferite e premi scelti (Phase 24
/// D-23). Senza una pagina successiva chiude il flusso: «Completa» dopo la
/// conferma. Con [onNext] mostra «Avanti» e non completa nulla: la missione
/// si chiude sull'ultima pagina (Phase 24 D-05).
class RecapStep extends StatelessWidget {
  const RecapStep({
    super.key,
    required this.card,
    required this.draft,
    required this.isSubmitting,
    required this.onComplete,
    this.onNext,
  });

  static const String completeLabel = 'Completa';
  static const Key completeKey = ValueKey('mission.recap.complete');

  static Key participantKeyFor(String characterId) =>
      ValueKey('mission.recap.participant.$characterId');

  static const double _coinsHeight = 24;
  static const double _coinsWidth = 240;

  final RequestCard card;
  final MissionDraft draft;
  final bool isSubmitting;
  final VoidCallback onComplete;

  /// Apre la pagina successiva; `null` = il riepilogo è l'ultima pagina.
  final VoidCallback? onNext;

  bool get _canGoOn => !isSubmitting && draft.allFightsSimulated;

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await confirmMissionCompletion(
      context,
      lines: missionRecapLinesOf(questTitle: card.questTitle, draft: draft),
    );
    if (confirmed) onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MissionPrizeOptionsCubit, MissionPrizeOptionsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              // poche tendine, tutte costruite: una tendina aperta resta
              // aperta anche quando scorre fuori vista
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final line in missionWideRecapLinesOf(
                      questTitle: card.questTitle,
                      draft: draft,
                    ))
                      _text(line),
                    for (final participant in draft.participants)
                      ?_participantDropdown(
                        participant,
                        state.options[participant.characterId],
                      ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                const MissionBackButton(),
                const Spacer(),
                _buildForwardButton(context),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildForwardButton(BuildContext context) {
    final onNext = this.onNext;
    if (onNext == null) {
      return ElevatedButton(
        key: completeKey,
        style: KlimmeckGuideTheme.primaryButtonStyle,
        onPressed: _canGoOn ? () => _confirm(context) : null,
        child: const Text(completeLabel),
      );
    }
    return ElevatedButton(
      key: MissionCompletionScreen.nextKey,
      style: KlimmeckGuideTheme.primaryButtonStyle,
      onPressed: _canGoOn ? onNext : null,
      child: const Text(MissionCompletionScreen.nextLabel),
    );
  }

  /// `null` per un personaggio senza righe: nessuno scontro e nessun premio.
  Widget? _participantDropdown(
    MissionParticipant participant,
    MissionPrizeOptions? options,
  ) {
    final prize = draft.prizeOf(participant.characterId);
    final rows = [
      for (final line in participantRecapLinesOf(participant, draft.fights))
        _text(line),
      if (prize != null) ..._prizeRows(prize, options),
    ];
    if (rows.isEmpty) return null;
    return Dropdown(
      key: participantKeyFor(participant.characterId),
      sectionName: StoryReader.ofParticipant(participant).header,
      data: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  /// Nomi dalle opzioni servite; prima che arrivino, i nomi di riserva.
  List<Widget> _prizeRows(MissionPrize prize, MissionPrizeOptions? options) {
    final cureLine = lifeShareLine(prize.cure);
    return [
      SizedBox(
        width: _coinsWidth,
        child: CoinsDisplay(
          coins: prize.coins,
          height: _coinsHeight,
          layout: CoinLayoutType.row,
        ),
      ),
      _text('+${prize.xp} XP'),
      for (final item in prize.items)
        _text(
          quantityLine(
            item.quantity,
            options?.itemById(item.itemId)?.name ?? unnamedItemLabel,
          ),
        ),
      if (prize.petId case final petId?)
        _text(options?.petById(petId)?.name ?? petId),
      if (prize.spellId case final spellId?)
        _text(options?.spellById(spellId)?.name ?? unnamedSpellLabel),
      if (cureLine != null) _text(cureLine),
    ];
  }

  static Widget _text(String line) =>
      Text(line, style: KlimmeckGuideTheme.instance.bodyMedium);
}
