import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'potion_recovery_state.dart';

/// Conto alla rovescia «pronta fra …» sull'ora del server (D-12): ticchetta
/// solo durante una ricarica. Creato e chiuso dalla sezione «Oggetti»: vive
/// solo mentre la pagina del Diario è a schermo. È solo visualizzazione: il
/// giudice della ricarica è il backend.
class PotionRecoveryCubit extends Cubit<PotionRecoveryState>
    with SafeEmit<PotionRecoveryState> {
  PotionRecoveryCubit({
    required ServerClockService clock,
    Duration tick = defaultTick,
  }) : _clock = clock,
       _tick = tick,
       super(const PotionRecoveryState(null)) {
    _offsetSubscription = clock.offsetChanges.listen((_) => _refresh());
  }

  /// L'etichetta cambia al minuto: un secondo basta a riaccendere le
  /// pergamene senza ritardo.
  static const Duration defaultTick = Duration(seconds: 1);

  final ServerClockService _clock;
  final Duration _tick;
  late final StreamSubscription<void> _offsetSubscription;
  Timer? _timer;
  DateTime? _until;

  void follow(DateTime? potionRecoveryUntil) {
    _until = potionRecoveryUntil;
    _refresh();
  }

  void _refresh() {
    final left = _until?.difference(_clock.now());
    if (left == null || left <= Duration.zero) {
      emit(const PotionRecoveryState(null));
      return _stopTimer();
    }
    final minutes = (left.inMilliseconds / Duration.millisecondsPerMinute)
        .ceil();
    emit(PotionRecoveryState(Duration(minutes: minutes)));
    _timer ??= Timer.periodic(_tick, (_) => _refresh());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() {
    _stopTimer();
    unawaited(_offsetSubscription.cancel());
    return super.close();
  }
}
