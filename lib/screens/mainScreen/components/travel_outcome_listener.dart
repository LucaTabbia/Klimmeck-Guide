import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/prisonCubit/prison_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_notice.dart';

/// Esiti del viaggio a livello di sessione (D-14, D-19): banner per codice e
/// reset sopravvivono al cambio tab; dopo "Parti" il flusso si chiude quando
/// `activeTravel` compare sul personaggio (lo stato arriva solo dalla
/// subscription, D-05). A un rifiuto per fame (D-03) il banner esce
/// all'ingresso in `TravelRequoting`, senza reset: il foglio resta aperto.
class TravelOutcomeListener extends StatelessWidget {
  const TravelOutcomeListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<TravelCubit, TravelState>(
        listenWhen: (_, current) =>
            current is TravelFailed || current is TravelStarted,
        listener: _onOutcome,
      ),
      BlocListener<TravelCubit, TravelState>(
        listenWhen: (previous, current) =>
            previous is! TravelRequoting && current is TravelRequoting,
        listener: (context, state) => _announce(
          context,
          failure: TravelFailure.starving,
          destination: (state as TravelRequoting).destination,
        ),
      ),
      BlocListener<CharacterCubit, CharacterState>(
        listenWhen: (previous, current) =>
            !_isTravelling(previous) && _isTravelling(current),
        listener: (context, _) => _settleStarted(context),
      ),
    ],
    child: child,
  );

  void _onOutcome(BuildContext context, TravelState state) {
    if (state is TravelFailed) {
      _announce(
        context,
        failure: state.failure,
        destination: state.destination,
        imprisonedFor: _learnPrison(context, state),
      );
      context.read<TravelCubit>().reset();
      return;
    }
    if (_isTravelling(context.read<CharacterCubit>().state)) {
      context.read<TravelCubit>().reset();
    }
  }

  /// Un rifiuto per prigione corregge un client stantio (quick 261110-cgd):
  /// il banner dice il tempo che manca secondo il PrisonCubit aggiornato.
  Duration? _learnPrison(BuildContext context, TravelFailed state) {
    if (state.failure != TravelFailure.imprisoned) return null;
    final prison = context.read<PrisonCubit>()
      ..learnRelease(state.imprisonedUntil);
    return prison.state.remaining;
  }

  void _announce(
    BuildContext context, {
    required TravelFailure failure,
    required City destination,
    Duration? imprisonedFor,
  }) {
    final notice = travelNoticeFor(failure, imprisonedFor: imprisonedFor);
    if (notice == null) return;
    context.read<InAppNotificationsCubit>().publishNotice(
      notice,
      dedupKey: 'travel|${failure.name}|${destination.id}',
    );
  }

  void _settleStarted(BuildContext context) {
    final travel = context.read<TravelCubit>();
    if (travel.state is TravelStarted) travel.reset();
  }

  static bool _isTravelling(CharacterState state) =>
      state is CharacterLoaded && state.character.status?.activeTravel != null;
}
