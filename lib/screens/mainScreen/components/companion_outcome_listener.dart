import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/pet_equip_failure.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionCubit/companion_notice.dart';

/// Esiti dello slot «Compagno» a livello di sessione (D-06, D-10): l'overlay
/// segue ogni `characterUpdated`; banner e rilettura sopravvivono al cambio tab.
class CompanionOutcomeListener extends StatelessWidget {
  const CompanionOutcomeListener({super.key, required this.child});

  final Widget child;

  /// Dopo questi rifiuti la vista è stantia e il BE non emette nulla:
  /// rilettura silenziosa. Dopo un timeout l'esito è incerto: la richiesta
  /// può essere stata eseguita, quindi si rilegge comunque.
  static const Set<PetEquipFailure> _staleViewFailures = {
    PetEquipFailure.notOwned,
    PetEquipFailure.notFound,
    PetEquipFailure.timedOut,
  };

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<CharacterCubit, CharacterState>(
        listenWhen: (previous, current) =>
            current is CharacterLoaded &&
            (previous is! CharacterLoaded ||
                previous.character != current.character),
        listener: (context, state) => context.read<CompanionCubit>().sync(
          (state as CharacterLoaded).character,
        ),
      ),
      BlocListener<CompanionCubit, CompanionState>(
        listenWhen: (previous, current) =>
            current.outcome != null && previous.outcome != current.outcome,
        listener: (context, state) => _onOutcome(context, state.outcome!),
      ),
    ],
    child: child,
  );

  void _onOutcome(BuildContext context, CompanionOutcome outcome) {
    _announce(context, outcome);
    if (_isStaleView(outcome)) {
      context.read<CharacterCubit>().refreshCharacter();
    }
  }

  void _announce(BuildContext context, CompanionOutcome outcome) {
    final notice = companionNoticeFor(outcome);
    if (notice == null) return;
    context.read<InAppNotificationsCubit>().publishNotice(
      notice,
      dedupKey:
          'companion|${outcome.kind.name}|${outcome.failure?.name ?? '-'}'
          '|${outcome.petId}',
    );
  }

  static bool _isStaleView(CompanionOutcome outcome) => switch (outcome.kind) {
    CompanionOutcomeKind.settledByTimeout => true,
    CompanionOutcomeKind.failed => _staleViewFailures.contains(outcome.failure),
  };
}
