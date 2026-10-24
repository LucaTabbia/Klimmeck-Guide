import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/travel/active_travel.dart';
import 'package:klimmeck_guide/models/travel/travel_route.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';
import 'package:latlong2/latlong.dart';

part 'travel_progress_state.dart';

/// Pedina e rotta del viaggio in corso, ricavate da `(activeTravel, ora
/// server)` (07-CONTEXT D-07, D-11): nessuna logica di completamento, lo
/// snap arriva solo con `follow(null)` all'evento del BE (D-10). Vive dentro
/// `WorldMap`: ticchetta solo con la mappa montata.
class TravelProgressCubit extends Cubit<TravelProgressState>
    with SafeEmit<TravelProgressState> {
  TravelProgressCubit({required ServerClockService clock})
    : _clock = clock,
      super(const TravelProgressIdle());

  /// Riletture silenziose dopo `endTime`: subito e oltre uno sweep del BE (60 s).
  static const List<Duration> arrivalRefetchDelays = [
    Duration(seconds: 5),
    Duration(seconds: 65),
  ];

  final ServerClockService _clock;
  ActiveTravel? _travel;
  TravelRoute? _route;

  void follow(ActiveTravel? travel) {
    if (travel == null) return _stopFollowing();
    if (_isSameTravel(travel)) return;
    _travel = travel;
    _route = TravelRoute.of(travel.road.points);
    emit(_snapshot());
  }

  void _stopFollowing() {
    if (_travel == null) return;
    _travel = null;
    _route = null;
    emit(const TravelProgressIdle());
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
}
