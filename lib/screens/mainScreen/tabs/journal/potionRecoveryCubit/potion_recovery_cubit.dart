import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';
import 'package:klimmeck_guide/shared/bloc/server_deadline_countdown.dart';

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
  }) : super(const PotionRecoveryState(null)) {
    _countdown = ServerDeadlineCountdown(
      clock: clock,
      tick: tick,
      onRemaining: (remaining) => emit(PotionRecoveryState(remaining)),
    );
  }

  /// L'etichetta cambia al minuto: un secondo basta a riaccendere le
  /// pergamene senza ritardo.
  static const Duration defaultTick = Duration(seconds: 1);

  late final ServerDeadlineCountdown _countdown;

  void follow(DateTime? potionRecoveryUntil) =>
      _countdown.follow(potionRecoveryUntil);

  @override
  Future<void> close() {
    unawaited(_countdown.dispose());
    return super.close();
  }
}
