import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';
import 'package:klimmeck_guide/shared/bloc/server_deadline_countdown.dart';

part 'spell_learning_state.dart';

/// Tempo che manca alla fine della parte di apprendimento (D-26): la data è
/// `startDate + waitingTime` della corsia servita; solo visualizzazione, la
/// fine la decide il backend.
class SpellLearningCubit extends Cubit<SpellLearningState>
    with SafeEmit<SpellLearningState> {
  SpellLearningCubit({
    required ServerClockService clock,
    Duration tick = defaultTick,
  }) : super(const SpellLearningState(null)) {
    _countdown = ServerDeadlineCountdown(
      clock: clock,
      tick: tick,
      onRemaining: (remaining) => emit(SpellLearningState(remaining)),
    );
  }

  static const Duration defaultTick = Duration(seconds: 1);

  late final ServerDeadlineCountdown _countdown;

  void follow(DateTime? endsAt) => _countdown.follow(endsAt);

  @override
  Future<void> close() {
    unawaited(_countdown.dispose());
    return super.close();
  }
}
