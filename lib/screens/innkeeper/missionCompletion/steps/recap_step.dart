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
import 'package:klimmeck_guide/screens/innkeeper/components/completion_recap.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionPrizeOptionsCubit/mission_prize_options_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

/// Righe del riepilogo dalla sola bozza servita (D-08): missione, scontri, PV e ferite per personaggio.
List<String> missionRecapLinesOf({
  required String questTitle,
  required MissionDraft draft,
}) => [
  questTitle,
  for (final (index, fight) in draft.fights.indexed) _fightLine(index, fight),
  for (final participant in draft.participants)
    ..._characterLines(participant, draft.fights),
];

String _fightLine(int index, MissionFight fight) {
  final enemies = fight.enemies
      .map((entry) => quantityLine(entry.quantity, entry.enemy.name))
      .join(', ');
  final verdict = fight.verdict;
  final suffix = verdict == null ? '' : ' · ${verdict.label}';
  return 'Scontro ${index + 1}: $enemies$suffix';
}

/// D-24: senza scontri nessuna riga; PV dall'inizio del primo scontro
/// all'effetto valido dell'ultimo (la correzione vince, D-06).
List<String> _characterLines(
  MissionParticipant participant,
  List<MissionFight> fights,
) {
  final id = participant.characterId;
  final first = fights.firstOrNull?.outcomeOf(id);
  final last = fights.lastOrNull?.outcomeOf(id)?.effective;
  if (first == null || last == null) return const [];
  final injuries = <InjuryType>{
    for (final fight in fights)
      ...?fight.outcomeOf(id)?.effective?.injuriesAdded,
  };
  return [
    '${participant.name}: PV ${first.hpBefore} → ${last.hpAfter}',
    if (injuries.isNotEmpty)
      'Ferite: ${injuries.map((injury) => injury.label.toLowerCase()).join(', ')}',
  ];
}

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

/// Passo «Riepilogo» (D-05, D-08): righe della bozza servita e premi scelti
/// per personaggio. Senza una pagina successiva chiude il flusso: «Completa»
/// dopo la conferma. Con [onNext] mostra «Avanti» e non completa nulla: la
/// missione si chiude sull'ultima pagina (Phase 24 D-05).
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

  static const double _coinsHeight = 24;
  static const double _coinsWidth = 240;

  final RequestCard card;
  final MissionDraft draft;
  final bool isSubmitting;
  final VoidCallback onComplete;

  /// Apre la pagina successiva; `null` = il riepilogo è l'ultima pagina.
  final VoidCallback? onNext;

  List<String> get _lines =>
      missionRecapLinesOf(questTitle: card.questTitle, draft: draft);

  bool get _canGoOn => !isSubmitting && draft.allFightsSimulated;

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await confirmMissionCompletion(context, lines: _lines);
    if (confirmed) onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MissionPrizeOptionsCubit, MissionPrizeOptionsState>(
      builder: (context, state) {
        final rows = [
          for (final line in _lines) () => _text(line),
          for (final participant in draft.participants)
            if (draft.prizeOf(participant.characterId) case final prize?)
              ..._prizeRows(
                participant,
                prize,
                state.options[participant.characterId],
              ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, index) => rows[index](),
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

  /// Nomi dalle opzioni servite; prima che arrivino, i nomi di riserva.
  List<Widget Function()> _prizeRows(
    MissionParticipant participant,
    MissionPrize prize,
    MissionPrizeOptions? options,
  ) {
    final cureLine = lifeShareLine(prize.cure);
    return [
      () => Text(
        participant.name,
        style: KlimmeckGuideTheme.instance.titleMedium,
      ),
      () => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: _coinsWidth,
          child: CoinsDisplay(
            coins: prize.coins,
            height: _coinsHeight,
            layout: CoinLayoutType.row,
          ),
        ),
      ),
      () => _text('+${prize.xp} XP'),
      for (final item in prize.items)
        () => _text(
          quantityLine(
            item.quantity,
            options?.itemById(item.itemId)?.name ?? unnamedItemLabel,
          ),
        ),
      if (prize.petId case final petId?)
        () => _text(options?.petById(petId)?.name ?? petId),
      if (prize.spellId case final spellId?)
        () => _text(options?.spellById(spellId)?.name ?? unnamedSpellLabel),
      if (cureLine != null) () => _text(cureLine),
    ];
  }

  static Widget _text(String line) =>
      Text(line, style: KlimmeckGuideTheme.instance.bodyMedium);
}
