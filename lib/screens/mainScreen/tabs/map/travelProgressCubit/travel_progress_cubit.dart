import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/travel/active_travel.dart';
import 'package:klimmeck_guide/models/travel/travel_route.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/travelProgressCubit/arrival_reread_ledger.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';
import 'package:latlong2/latlong.dart';

part 'travel_progress_state.dart';

/// Pedina e rotta del viaggio in corso, ricavate da `(activeTravel, ora
/// server)` (07-CONTEXT D-07, D-11): nessuna logica di completamento, lo
/// snap arriva solo con `follow(null)` all'evento del BE (D-10). Vive dentro
/// `WorldMap`: ticchetta solo con la mappa montata.
class TravelProgressCubit extends Cubit<TravelProgressState>
    with SafeEmit<TravelProgressState> {
  TravelProgressCubit({
    required ServerClockService clock,
    ArrivalRereadLedger? rereads,
    Duration tick = defaultTick,
  }) : _clock = clock,
       _rereads = rereads ?? ArrivalRereadLedger(),
       _tick = tick,
       super(const TravelProgressIdle()) {
    _offsetSubscription = clock.offsetChanges.listen((_) => _onOffsetChanged());
  }

  /// I viaggi durano da ~20 min a ~3,4 giorni (BE §8): un secondo basta.
  static const Duration defaultTick = Duration(seconds: 1);

  /// Riletture silenziose dopo `endTime`: subito e oltre uno sweep del BE (60 s).
  /// WorldMap rilegge il personaggio (in silenzio) quando [claimArrivalReread]
  /// lo autorizza: non è logica di completamento, solo una rilettura del BE (D-10).
  static const List<Duration> arrivalRefetchDelays = [
    Duration(seconds: 5),
    Duration(seconds: 65),
  ];

  final ServerClockService _clock;
  final ArrivalRereadLedger _rereads;
  final Duration _tick;
  late final StreamSubscription<void> _offsetSubscription;
  Timer? _timer;
  ActiveTravel? _travel;
  TravelRoute? _route;

  void follow(ActiveTravel? travel) {
    if (travel == null) return _stopFollowing();
    if (_isSameTravel(travel)) return;
    _travel = travel;
    _route = TravelRoute.of(travel.road.points);
    _refresh();
  }

  /// Al massimo una rilettura per soglia raggiunta e per viaggio, contata nel
  /// registro della sessione (WR-02): né un rimontaggio della mappa né un
  /// resync all'indietro superano il tetto di [arrivalRefetchDelays].
  bool claimArrivalReread() {
    final snapshot = state;
    if (snapshot is! TravelProgressActive) return false;
    return _rereads.claim(snapshot.travel, due: snapshot.arrivalRefetchCount);
  }

  void _stopFollowing() {
    if (_travel == null) return;
    _stopTimer();
    _travel = null;
    _route = null;
    emit(const TravelProgressIdle());
  }

  /// Un nuovo offset del server invalida l'ultimo snapshot (es. orologio del
  /// device spostato o primo sync dopo il cold start): ricalcola e riparte.
  void _onOffsetChanged() {
    if (_travel == null) return;
    _refresh();
  }

  /// Un tick, un nuovo viaggio o un nuovo offset: ricalcola e tiene vivo il
  /// ticker finché qualcosa può ancora cambiare.
  void _refresh() {
    final snapshot = _snapshot();
    emit(snapshot);
    if (_isSettled(snapshot)) return _stopTimer();
    _timer ??= Timer.periodic(_tick, (_) => _refresh());
  }

  /// Nulla cambia più fino all'evento del BE; mai su un orologio non sincronizzato.
  bool _isSettled(TravelProgressActive snapshot) =>
      _clock.isSynced &&
      snapshot.isArriving &&
      snapshot.arrivalRefetchCount == arrivalRefetchDelays.length;

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// D-06: la polilinea ripetuta a ogni `characterUpdated` non si rimisura.
  bool _isSameTravel(ActiveTravel travel) =>
      _travel?.startTime == travel.startTime &&
      _travel?.endTime == travel.endTime;

  TravelProgressActive _snapshot() {
    final travel = _travel!;
    final route = _route!;
    final serverNow = _clock.now();
    final progress = travelProgress(
      serverNow: serverNow,
      startTime: travel.startTime,
      durationMs: travel.duration,
    );
    final split = route.splitAt(progress);
    return TravelProgressActive(
      travel: travel,
      route: route,
      position: route.pointAt(progress),
      travelled: split.travelled,
      remaining: split.remaining,
      remainingTime: _remainingTimeAt(serverNow, travel),
      isArriving: progress >= 1,
      arrivalRefetchCount: _refetchCountAt(serverNow, travel),
    );
  }

  static Duration _remainingTimeAt(DateTime serverNow, ActiveTravel travel) {
    final remaining = travel.endTime.difference(serverNow);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static int _refetchCountAt(DateTime serverNow, ActiveTravel travel) =>
      arrivalRefetchDelays
          .where((delay) => !serverNow.isBefore(travel.endTime.add(delay)))
          .length;

  @override
  Future<void> close() {
    _stopTimer();
    _offsetSubscription.cancel();
    return super.close();
  }
}
