import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/use_item_result.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart';
import 'package:klimmeck_guide/shared/components/hp_delta_bar.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';
import 'package:klimmeck_guide/utils/lore_lines.dart';

/// Foglio di pergamena di una pozione heal del Diario (D-18): chiede
/// conferma, resta aperto mentre la bevuta è in volo (azioni spente, nessun
/// indicatore d'attesa) e mostra l'esito sullo stesso foglio. A un rifiuto si
/// chiude: il motivo lo dice il banner di PotionOutcomeListener. Stile
/// provvisorio.
class PotionSheet extends StatelessWidget {
  const PotionSheet({
    super.key,
    required this.item,
    required this.maxLifePoints,
  });

  final LootItem item;

  /// Vita massima letta dal personaggio prima di aprire il foglio: l'esito
  /// del backend non la porta.
  final int maxLifePoints;

  static const Key drinkKey = ValueKey('potion.drink');
  static const Key notNowKey = ValueKey('potion.notNow');
  static const Key continueKey = ValueKey('potion.continue');
  static const Key hpKey = ValueKey('potion.hp');
  static const Key healedKey = ValueKey('potion.healed');
  static Key loreKeyOf(String loreId) => ValueKey('potion.lore.$loreId');

  static const String drinkLabel = 'Bevi';
  static const String notNowLabel = 'Non ora';
  static const String continueLabel = 'Continua';
  static String questionOf(String name) => 'Bevi $name?';
  static const Duration hpAnimationDuration = Duration(milliseconds: 900);
  static const Size _minTapTarget = Size(44, 44);

  @override
  Widget build(BuildContext context) => BlocListener<PotionCubit, PotionState>(
    listenWhen: (_, current) => current is PotionRefused,
    listener: (context, _) => _close(context),
    child: BlocBuilder<PotionCubit, PotionState>(
      builder: (context, state) => PopScope(
        canPop: state is! PotionDrinking,
        child: _faceOf(context, state),
      ),
    ),
  );

  /// `pop` e non `maybePop`: il PopScope può ancora bloccare l'uscita da
  /// `PotionDrinking` finché non si ricostruisce.
  void _close(BuildContext context) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    Navigator.of(context).pop();
  }

  Widget _faceOf(BuildContext context, PotionState state) {
    if (state is PotionDrunk && state.itemId == item.id) {
      return _outcome(context, state.result);
    }
    return _confirmation(context, isDrinking: state is PotionDrinking);
  }

  Widget _confirmation(BuildContext context, {required bool isDrinking}) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: KlimmeckGuideTheme.spacingLg),
        AutoSizeText(
          questionOf(item.name ?? ''),
          maxLines: 2,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
        for (final line in [
          healedInjuriesLine(item),
          recoveryLine(item.recovery),
        ].nonNulls)
          _line(context, line),
        const SizedBox(height: KlimmeckGuideTheme.spacingMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              child: _action(
                key: notNowKey,
                label: notNowLabel,
                color: KlimmeckGuideTheme.darkWood,
                onPressed: isDrinking
                    ? null
                    : () => Navigator.of(context).maybePop(),
              ),
            ),
            Flexible(
              child: _action(
                key: drinkKey,
                label: drinkLabel,
                color: KlimmeckGuideTheme.healGreen,
                onPressed: isDrinking
                    ? null
                    : () => context.read<PotionCubit>().drink(item.id),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _outcome(BuildContext context, UseItemResult result) {
    final textTheme = Theme.of(context).textTheme;
    final healed = healedLine(result.injuriesHealed);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: KlimmeckGuideTheme.spacingLg),
        AutoSizeText(
          item.name ?? '',
          maxLines: 1,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: KlimmeckGuideTheme.spacingSm),
        _hpBar(result),
        if (healed != null) _line(context, healed, key: healedKey),
        for (final lore in result.loreUnlocked)
          _line(context, loreUnlockedLine(lore), key: loreKeyOf(lore.id)),
        const SizedBox(height: KlimmeckGuideTheme.spacingMd),
        _action(
          key: continueKey,
          label: continueLabel,
          color: KlimmeckGuideTheme.darkWood,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Widget _hpBar(UseItemResult result) {
    final before = result.hpBefore.toDouble();
    final after = result.hpAfter.toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: before, end: after),
      duration: hpAnimationDuration,
      builder: (_, hp, _) => HpDeltaBar(
        key: hpKey,
        hp: hp,
        max: maxLifePoints,
        isGain: after > before,
      ),
    );
  }

  Widget _line(BuildContext context, String text, {Key? key}) => Padding(
    padding: const EdgeInsets.only(top: KlimmeckGuideTheme.spacingSm),
    child: Text(
      text,
      key: key,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );

  Widget _action({
    required Key key,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) => Semantics(
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
  );
}
