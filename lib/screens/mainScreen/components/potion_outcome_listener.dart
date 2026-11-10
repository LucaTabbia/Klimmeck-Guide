import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/item_use_failure.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_notice.dart';

/// Rifiuti delle pozioni a livello di sessione (D-11, D-18): il banner
/// sopravvive al cambio tab. Una bevuta riuscita non pubblica nulla: lo stato
/// nuovo arriva dal flusso del personaggio.
class PotionOutcomeListener extends StatelessWidget {
  const PotionOutcomeListener({super.key, required this.child});

  final Widget child;

  /// Dopo questi rifiuti la vista può essere stantia (oggetto non più
  /// posseduto) o l'esito incerto (timeout): rilettura silenziosa.
  static const Set<ItemUseFailure> _staleViewFailures = {
    ItemUseFailure.notOwned,
    ItemUseFailure.timedOut,
  };

  @override
  Widget build(BuildContext context) => BlocListener<PotionCubit, PotionState>(
    listenWhen: (previous, current) =>
        current is PotionRefused && previous != current,
    listener: (context, state) => _onRefused(context, state as PotionRefused),
    child: child,
  );

  void _onRefused(BuildContext context, PotionRefused refused) {
    final notice = potionNoticeFor(
      refused.failure,
      remaining: refused.recoveryUntil?.difference(
        context.read<ServerClockService>().now(),
      ),
    );
    if (notice != null) {
      context.read<InAppNotificationsCubit>().publishNotice(
        notice,
        dedupKey:
            'potion|${refused.failure.name}|${refused.itemId}'
            '|${refused.sequence}',
      );
    }
    if (_staleViewFailures.contains(refused.failure)) {
      context.read<CharacterCubit>().refreshCharacter();
    }
  }
}
