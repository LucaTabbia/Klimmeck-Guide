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

/// Passo «Riepilogo» (D-05, D-08): righe della bozza servita, premi scelti
/// per personaggio e «Completa» dopo la conferma esplicita in stile neutro.
/// La missione finisce sempre completata: nessun'altra uscita (D-05).
class RecapStep extends StatelessWidget {
  const RecapStep({
    super.key,
    required this.card,
    required this.draft,
    required this.isSubmitting,
    required this.onComplete,
  });

  static const String completeLabel = 'Completa';
  static const Key completeKey = ValueKey('mission.recap.complete');

  static const double _coinsHeight = 24;
  static const double _coinsWidth = 240;

  final RequestCard card;
  final MissionDraft draft;
  final bool isSubmitting;
  final VoidCallback onComplete;

  List<String> get _lines =>
      missionRecapLinesOf(questTitle: card.questTitle, draft: draft);

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDestructiveConfirmation(
      context,
      title: MissionCompletionScreen.title,
      body: _lines.join('\n'),
      confirmLabel: completeLabel,
      confirmButtonStyle: KlimmeckGuideTheme.primaryButtonStyle,
    );
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
                const Spacer(),
                ElevatedButton(
                  key: completeKey,
                  style: KlimmeckGuideTheme.primaryButtonStyle,
                  onPressed: isSubmitting ? null : () => _confirm(context),
                  child: const Text(completeLabel),
                ),
              ],
            ),
          ],
        );
      },
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
