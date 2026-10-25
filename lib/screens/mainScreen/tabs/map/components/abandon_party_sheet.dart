import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAbandonCubit/quest_abandon_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Conferma su pergamena dell'abbandono del gruppo (ui-ux.md: le azioni
/// distruttive chiedono conferma, mai `AlertDialog`). "Abbandona" è l'unica
/// via ad `abandonQuest`; "Resta" chiude. Mentre l'abbandono è in volo il
/// foglio non si chiude: si chiude da sé all'esito (l'avviso lo pubblica
/// QuestAbandonOutcomeListener). Nessun undo. Stile provvisorio.
class AbandonPartySheet extends StatelessWidget {
  const AbandonPartySheet({
    super.key,
    required this.quest,
    required this.characterId,
  });

  final Quest quest;
  final String characterId;

  static const Key abandonKey = ValueKey('party.abandon');
  static const Key stayKey = ValueKey('party.stay');
  static const String question =
      'Vuoi abbandonare il gruppo? Il tuo posto sarà liberato.';
  static const Size _minTapTarget = Size(44, 44);

  @override
  Widget build(BuildContext context) =>
      BlocListener<QuestAbandonCubit, QuestAbandonState>(
        listenWhen: (_, current) =>
            current is QuestAbandoned || current is QuestAbandonFailed,
        listener: (context, _) => _closeSettled(context),
        child: BlocBuilder<QuestAbandonCubit, QuestAbandonState>(
          builder: (context, state) => PopScope(
            canPop: state is! QuestAbandoning,
            child: _content(context, state is QuestAbandoning),
          ),
        ),
      );

  /// `pop` e non `maybePop`: il PopScope blocca ancora l'uscita da
  /// `QuestAbandoning` finché non si ricostruisce.
  void _closeSettled(BuildContext context) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    Navigator.of(context).pop();
  }

  Widget _content(BuildContext context, bool isAbandoning) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: KlimmeckGuideTheme.spacingLg),
        AutoSizeText(
          quest.infos?.title ?? '',
          maxLines: 1,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: KlimmeckGuideTheme.spacingMd),
        Text(
          question,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: KlimmeckGuideTheme.spacingMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _action(
              key: stayKey,
              label: 'Resta',
              color: KlimmeckGuideTheme.darkWood,
              onPressed: isAbandoning
                  ? null
                  : () => Navigator.of(context).maybePop(),
            ),
            _action(
              key: abandonKey,
              label: 'Abbandona',
              color: KlimmeckGuideTheme.bloodRed,
              onPressed: isAbandoning
                  ? null
                  : () => context.read<QuestAbandonCubit>().abandon(
                      characterId: characterId,
                      questId: quest.id,
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _action({
    required Key key,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) => Flexible(
    child: Semantics(
      label: label,
      button: true,
      child: TextButton(
        key: key,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: _minTapTarget,
          foregroundColor: color,
        ),
        child: AutoSizeText(label, maxLines: 1),
      ),
    ),
  );
}
