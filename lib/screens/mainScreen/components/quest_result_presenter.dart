import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/quest_result/quest_end_event.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questResultsCubit/quest_result_notice.dart';
import 'package:klimmeck_guide/screens/mainScreen/questResultsCubit/quest_results_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_cubit.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_result_sheet.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Presenta i fogli esiti sul Navigator radice (09-CONTEXT D-01, D-05..D-08,
/// D-12, D-13, D-23): solo a mappa visibile e libera, oppure ovunque per una
/// coda sbloccata da una morte; banner o soppressione per gli arrivi live;
/// pop esterno → di nuovo in coda, mai confermato.
class QuestResultPresenter extends StatefulWidget {
  const QuestResultPresenter({super.key, required this.child});

  final Widget child;

  @override
  State<QuestResultPresenter> createState() => _QuestResultPresenterState();
}

class _QuestResultPresenterState extends State<QuestResultPresenter> {
  static const Duration _transitionDuration = Duration(milliseconds: 250);

  late final QuestResultsCubit _results;
  late final MapAvailabilityCubit _availability;
  late int _handledArrival;
  late int _handledNotice;
  Character? _lastLoadedCharacter;
  bool _isPresenting = false;

  @override
  void initState() {
    super.initState();
    _results = context.read<QuestResultsCubit>();
    _availability = context.read<MapAvailabilityCubit>();
    _handledArrival = _results.state.arrivalSerial;
    _handledNotice = _results.state.notice?.serial ?? 0;
    _rememberCharacter(context.read<CharacterCubit>().state);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryPresent());
  }

  /// Una route sopra la shell (dialog, foglio, il foglio esiti stesso) copre la
  /// mappa (D-07, D-23): il segnale si scrive dopo il frame, mai in build.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCovered = !(ModalRoute.isCurrentOf(context) ?? true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _availability.routeCoveredChanged(isCovered);
    });
  }

  @override
  void dispose() {
    _availability.routeCoveredChanged(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<QuestResultsCubit, QuestResultsState>(
        listener: (_, state) => _onResults(state),
      ),
      BlocListener<MapAvailabilityCubit, MapAvailabilityState>(
        listener: (_, _) => _tryPresent(),
      ),
      BlocListener<TravelCubit, TravelState>(
        listenWhen: (previous, current) =>
            (previous is TravelIdle) != (current is TravelIdle),
        listener: (_, _) => _tryPresent(),
      ),
      BlocListener<CharacterCubit, CharacterState>(
        listenWhen: (_, current) => current is CharacterLoaded,
        listener: (_, state) => _rememberCharacter(state),
      ),
      BlocListener<CharacterCubit, CharacterState>(
        listenWhen: (previous, current) =>
            previous is! CharacterUnavailable &&
            current is CharacterUnavailable,
        listener: (_, _) => unawaited(_results.refetchPending()),
      ),
    ],
    child: widget.child,
  );

  void _rememberCharacter(CharacterState state) {
    if (state is CharacterLoaded) _lastLoadedCharacter = state.character;
  }

  void _onResults(QuestResultsState state) {
    _announceArrival(state);
    _announceNotice(state);
    _tryPresent();
  }

  /// Banner solo lontano dai fogli (D-07, C6, checker I1): sulla mappa
  /// libera, o con una morte in coda, l'arrivo si apre ora o dopo il foglio
  /// già aperto (09-REVIEW IN-03).
  void _announceArrival(QuestResultsState state) {
    final arrival = state.arrival;
    if (arrival == null || state.arrivalSerial == _handledArrival) return;
    _handledArrival = state.arrivalSerial;
    final event = questEndEventOf(arrival);
    final notices = context.read<InAppNotificationsCubit>();
    if (_isSheetGround()) {
      notices.suppress(event.dedupKey);
      return;
    }
    if (!_isQuestEndBannerEnabled) return;
    notices.publish(event);
  }

  bool get _isQuestEndBannerEnabled => context
      .read<NotificationPreferencesCubit>()
      .state
      .isEnabled(NotificationCategory.questEnd);

  void _announceNotice(QuestResultsState state) {
    final notice = state.notice;
    if (notice == null || notice.serial == _handledNotice) return;
    _handledNotice = notice.serial;
    final notification = questResultNoticeFor(notice.failure);
    if (notification == null) return;
    context.read<InAppNotificationsCubit>().publishNotice(
      notification,
      dedupKey: 'questResult|${notice.resultId}',
    );
  }

  /// Mappa visibile e libera senza viaggi in corso di scelta (D-06, D-07);
  /// una morte in coda apre ovunque, purché nessuna route copra la shell
  /// (D-08, D-13). Dopo la conferma della morte nessun altro foglio.
  bool _canPresent() {
    final state = _results.state;
    if (_isShowingSheet || state.head == null) return false;
    return _isSheetGround();
  }

  bool get _isShowingSheet => _isPresenting || _results.state.showing != null;

  /// Dove un foglio si apre, a parte quello già aperto: la sua route copre la
  /// shell ma non conta come un'altra route sopra la mappa.
  bool _isSheetGround() {
    final state = _results.state;
    if (!state.isAcceptingSheets) return false;
    final availability = _availability.state;
    if (availability.isRouteCovered && !_isShowingSheet) return false;
    if (state.isUnlockedByDeath) return true;
    return availability.isFreeBeneathRoutes &&
        context.read<TravelCubit>().state is TravelIdle;
  }

  void _tryPresent() {
    if (!mounted || !_canPresent()) return;
    unawaited(_present(_results.state.head!));
  }

  /// Chiude solo il bottone (`pop(true)`, D-05); un pop esterno restituisce
  /// `null` e il risultato torna in coda senza conferma (D-10, D-23).
  Future<void> _present(QuestResult result) async {
    _isPresenting = true;
    _results.presented(result.id);
    final characterName = _deadCharacterName(result);
    final isClosedByButton = await showGeneralDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: KlimmeckGuideTheme.disabledScrim,
      transitionDuration: _transitionDuration,
      pageBuilder: (_, _, _) => BlocProvider.value(
        value: _results,
        child: PopScope(
          canPop: false,
          child: _QuestResultRoute(
            result: result,
            characterName: characterName,
          ),
        ),
      ),
    );
    _isPresenting = false;
    if (_results.isClosed) return;
    if (isClosedByButton == true) {
      _results.closed(result.id);
    } else {
      _results.dismissedExternally(result.id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryPresent());
  }

  /// Nome solo per il personaggio della shell (D-14, C7): un foglio storico
  /// di un altro personaggio resta senza nome.
  String? _deadCharacterName(QuestResult result) {
    final character = _lastLoadedCharacter;
    if (!result.isDeath || character?.id != result.characterId) return null;
    return character?.infos?.name;
  }
}

/// Contenuto della route: per la morte il bottone attende la conferma e la
/// route si chiude solo a conferma riuscita (D-10, D-13).
class _QuestResultRoute extends StatelessWidget {
  const _QuestResultRoute({required this.result, this.characterName});

  final QuestResult result;
  final String? characterName;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<QuestResultsCubit, QuestResultsState>(
        listenWhen: (previous, current) =>
            result.isDeath &&
            previous.deathAcknowledgement != current.deathAcknowledgement &&
            current.deathAcknowledgement == DeathAcknowledgement.done,
        listener: (context, _) => Navigator.of(context).pop(true),
        builder: (context, state) => Material(
          type: MaterialType.transparency,
          child: Center(
            child: QuestResultSheet(
              result: result,
              characterName: characterName,
              position: state.position,
              total: state.total,
              isAcknowledging:
                  result.isDeath &&
                  state.deathAcknowledgement == DeathAcknowledgement.inFlight,
              hasAcknowledgeFailed:
                  result.isDeath &&
                  state.deathAcknowledgement == DeathAcknowledgement.failed,
              onContinue: () => _onContinue(context),
            ),
          ),
        ),
      );

  void _onContinue(BuildContext context) {
    if (!result.isDeath) {
      Navigator.of(context).pop(true);
      return;
    }
    unawaited(context.read<QuestResultsCubit>().acknowledgeDeath(result.id));
  }
}
