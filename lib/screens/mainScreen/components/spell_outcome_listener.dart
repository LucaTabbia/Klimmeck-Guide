import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/spell_equip_failure.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spell_notice.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';

/// Esiti delle magie a livello di sessione (D-16, D-17): l'overlay segue ogni
/// `characterUpdated`; banner e riallineamento sopravvivono al cambio tab (F3).
class SpellOutcomeListener extends StatelessWidget {
  const SpellOutcomeListener({super.key, required this.child});

  final Widget child;

  /// Dopo questi rifiuti la vista è stantia e il BE non emette nulla:
  /// rilettura silenziosa (F1). Dopo un timeout l'esito è incerto: la
  /// richiesta può essere stata eseguita, quindi si rilegge comunque.
  static const Set<SpellEquipFailure> _staleViewFailures = {
    SpellEquipFailure.alreadyActive,
    SpellEquipFailure.notActive,
    SpellEquipFailure.notKnown,
    SpellEquipFailure.slotsFull,
    SpellEquipFailure.notFound,
    SpellEquipFailure.timedOut,
  };

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<CharacterCubit, CharacterState>(
        listenWhen: (previous, current) =>
            current is CharacterLoaded &&
            (previous is! CharacterLoaded ||
                previous.character != current.character),
        listener: (context, state) => context.read<SpellsCubit>().sync(
          (state as CharacterLoaded).character,
        ),
      ),
      BlocListener<SpellsCubit, SpellsState>(
        listenWhen: (previous, current) =>
            current.outcome != null && previous.outcome != current.outcome,
        listener: (context, state) => _onOutcome(context, state.outcome!),
      ),
    ],
    child: child,
  );

  void _onOutcome(BuildContext context, SpellOutcome outcome) {
    _announce(context, outcome);
    if (_isStaleView(outcome)) {
      context.read<CharacterCubit>().refreshCharacter();
    }
  }

  void _announce(BuildContext context, SpellOutcome outcome) {
    final notice = spellNoticeFor(outcome);
    if (notice == null) return;
    context.read<InAppNotificationsCubit>().publishNotice(
      notice,
      dedupKey:
          'spell|${outcome.kind.name}|${outcome.failure?.name ?? '-'}'
          '|${outcome.spellId}',
    );
  }

  static bool _isStaleView(SpellOutcome outcome) => switch (outcome.kind) {
    SpellOutcomeKind.settledByTimeout => true,
    SpellOutcomeKind.failed => _staleViewFailures.contains(outcome.failure),
    SpellOutcomeKind.blockedSlotsFull ||
    SpellOutcomeKind.blockedNoSlots => false,
  };
}
