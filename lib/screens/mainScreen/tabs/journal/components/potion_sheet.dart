import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/companion/companion_potion_target.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/use_item_result.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_cubit.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_card.dart';
import 'package:klimmeck_guide/shared/components/hp_delta_bar.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/companion_lines.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';
import 'package:klimmeck_guide/utils/lore_lines.dart';

/// Foglio di pergamena di una pozione heal del Diario (D-18): chiede
/// conferma, resta aperto mentre la bevuta è in volo (azioni spente, nessun
/// indicatore d'attesa) e mostra l'esito sullo stesso foglio. A un rifiuto si
/// chiude: il motivo lo dice il banner di PotionOutcomeListener. Sotto la
/// conferma, una pergamena «Dai a …» per ogni compagno che può bere
/// (D-08); «Bevi» resta spento durante l'attesa del personaggio (D-32).
/// Stile provvisorio.
class PotionSheet extends StatelessWidget {
  const PotionSheet({
    super.key,
    required this.item,
    required this.maxLifePoints,
    this.targets = const [],
  });

  final LootItem item;

  /// Vita massima letta dal personaggio prima di aprire il foglio: l'esito
  /// del backend non la porta. Ignota o non positiva = nessuna barra.
  final int? maxLifePoints;

  /// Compagni che possono bere, letti all'apertura del foglio (D-08).
  final List<CompanionPotionTarget> targets;

  static const Key drinkKey = ValueKey('potion.drink');
  static const Key notNowKey = ValueKey('potion.notNow');
  static const Key continueKey = ValueKey('potion.continue');
  static const Key hpKey = ValueKey('potion.hp');
  static const Key healedKey = ValueKey('potion.healed');
  static const Key characterWaitKey = ValueKey('potion.characterWait');
  static Key targetKeyOf(String petId) => ValueKey('potion.target.$petId');
  static Key loreKeyOf(String loreId) => ValueKey('potion.lore.$loreId');

  static const String drinkLabel = 'Bevi';
  static const String notNowLabel = 'Non ora';
  static const String continueLabel = 'Continua';
  static String questionOf(String name) => 'Bevi $name?';
  static const Duration hpAnimationDuration = Duration(milliseconds: 900);
  static const Size _minTapTarget = Size(44, 44);
  static const double _targetCardSize = 56;

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
      final targetPetId = state.targetPetId;
      if (targetPetId == null) {
        return _outcome(
          context,
          state.result,
          title: item.name ?? '',
          max: maxLifePoints,
          healed: healedLine(state.result.injuriesHealed),
        );
      }
      return _outcome(
        context,
        state.result,
        title: state.targetName ?? '',
        max: _targetMaxOf(targetPetId),
      );
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
              child: BlocBuilder<PotionRecoveryCubit, PotionRecoveryState>(
                builder: (context, recovery) => _action(
                  key: drinkKey,
                  label: drinkLabel,
                  color: KlimmeckGuideTheme.healGreen,
                  onPressed: isDrinking || recovery.isRecovering
                      ? null
                      : () => context.read<PotionCubit>().drink(item.id),
                ),
              ),
            ),
          ],
        ),
        BlocBuilder<PotionRecoveryCubit, PotionRecoveryState>(
          builder: (context, recovery) => switch (recovery.remaining) {
            final remaining? => _line(
              context,
              potionReadyInLine(remaining),
              key: characterWaitKey,
            ),
            null => const SizedBox.shrink(),
          },
        ),
        for (final target in targets)
          _targetParchment(context, target, isDrinking: isDrinking),
      ],
    );
  }

  /// Pergamena di un compagno che può bere: tocco = la pozione va a lui
  /// (D-07); spenta mentre una pozione è in volo (single-flight).
  Widget _targetParchment(
    BuildContext context,
    CompanionPotionTarget target, {
    required bool isDrinking,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final label = giveToCompanionLabel(target.name);
    return Padding(
      padding: const EdgeInsets.only(top: KlimmeckGuideTheme.spacingSm),
      child: Semantics(
        label: label,
        button: true,
        child: GestureDetector(
          key: targetKeyOf(target.petId),
          behavior: HitTestBehavior.opaque,
          onTap: isDrinking
              ? null
              : () => context.read<PotionCubit>().give(
                  item.id,
                  petId: target.petId,
                  targetName: target.name,
                ),
          child: AnimatedOpacity(
            opacity: isDrinking ? KlimmeckGuideTheme.pendingInkOpacity : 1,
            duration: KlimmeckGuideTheme.pendingInkDuration,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: _minTapTarget.height),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CompanionCard(
                    pet: target.owned.pet,
                    size: _targetCardSize,
                    name: target.owned.name,
                  ),
                  const SizedBox(width: KlimmeckGuideTheme.spacingSm),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: textTheme.bodyLarge),
                        Text(
                          companionLifeLine(target.life, target.maxLifePoints)!,
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Vita massima del compagno servito all'apertura del foglio: l'esito del
  /// backend non la porta. Ignoto = nessuna barra.
  int? _targetMaxOf(String petId) {
    for (final target in targets) {
      if (target.petId == petId) return target.maxLifePoints;
    }
    return null;
  }

  /// Esito sullo stesso foglio: titolo della pozione per il personaggio, nome
  /// del compagno per lui (D-08): i compagni non hanno ferite, quindi niente
  /// [healed].
  Widget _outcome(
    BuildContext context,
    UseItemResult result, {
    required String title,
    required int? max,
    String? healed,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: KlimmeckGuideTheme.spacingLg),
        AutoSizeText(
          title,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: KlimmeckGuideTheme.spacingSm),
        ?_hpBar(result, max: max),
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

  Widget? _hpBar(UseItemResult result, {required int? max}) {
    if (max == null || max <= 0) return null;
    final before = result.hpBefore.toDouble();
    final after = result.hpAfter.toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: before, end: after),
      duration: hpAnimationDuration,
      builder: (_, hp, _) =>
          HpDeltaBar(key: hpKey, hp: hp, max: max, isGain: after > before),
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
