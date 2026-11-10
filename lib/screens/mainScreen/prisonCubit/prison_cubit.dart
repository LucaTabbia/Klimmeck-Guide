import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';
import 'package:klimmeck_guide/shared/bloc/server_deadline_countdown.dart';

part 'prison_state.dart';

/// Prigione del personaggio (quick 261110-cgd): nessuno sweep né evento la
/// chiude sul server, quindi il client si libera da sé all'istante sull'ora
/// del server. Lo alimentano lo stato del personaggio e la data di un rifiuto
/// `CHARACTER_IMPRISONED` (un client stantio si corregge); vale la più tarda
/// delle due. Solo visualizzazione: il giudice resta il backend.
class PrisonCubit extends Cubit<PrisonState> with SafeEmit<PrisonState> {
  PrisonCubit({required ServerClockService clock, Duration tick = defaultTick})
    : super(const PrisonState(null)) {
    _countdown = ServerDeadlineCountdown(
      clock: clock,
      tick: tick,
      onRemaining: (remaining) => emit(PrisonState(remaining)),
    );
  }

  static const Duration defaultTick = Duration(seconds: 1);

  late final ServerDeadlineCountdown _countdown;
  DateTime? _statusRelease;
  DateTime? _refusalRelease;

  void followStatus(DateTime? imprisonedUntil) {
    _statusRelease = imprisonedUntil;
    _countdown.follow(_latestRelease());
  }

  void learnRelease(DateTime? imprisonedUntil) {
    if (imprisonedUntil == null) return;
    _refusalRelease = imprisonedUntil;
    _countdown.follow(_latestRelease());
  }

  DateTime? _latestRelease() {
    final status = _statusRelease;
    final refusal = _refusalRelease;
    if (status == null) return refusal;
    if (refusal == null) return status;
    return status.isAfter(refusal) ? status : refusal;
  }

  @override
  Future<void> close() {
    unawaited(_countdown.dispose());
    return super.close();
  }
}
