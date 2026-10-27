import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/spell/spell_recovery_status.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'spell_recovery_state.dart';

/// Countdown «prossimo tra X» sull'ora del server (D-04): ticchetta solo
/// finché almeno una magia mostra un countdown. Creato e chiuso dalla sezione
/// Magie: vive solo mentre la pagina del Diario è a schermo (D-16).
class SpellRecoveryCubit extends Cubit<SpellRecoveryState>
    with SafeEmit<SpellRecoveryState> {
  SpellRecoveryCubit({
    required ServerClockService clock,
    Duration tick = defaultTick,
  }) : _clock = clock,
       _tick = tick,
       super(const SpellRecoveryState({})) {
    _offsetSubscription = clock.offsetChanges.listen((_) => _refresh());
  }

  /// L'etichetta cambia al minuto: un secondo basta a non mostrarla in ritardo.
  static const Duration defaultTick = Duration(seconds: 1);

  /// Senza stato di recupero gli usi sono al massimo (fallback D-02/D-03).
  static List<SpellRecoveryInput> inputsOf(Spellbook spellbook) => [
    for (final entry in spellbook.entries)
      SpellRecoveryInput(
        spellId: entry.spell.id,
        usages: entry.usages ?? entry.spell.maxUsages ?? 0,
        maxUsages: entry.spell.maxUsages,
        recoveries: entry.recoveries,
      ),
  ];

  final ServerClockService _clock;
  final Duration _tick;
  late final StreamSubscription<void> _offsetSubscription;
  Timer? _timer;
  List<SpellRecoveryInput> _inputs = const [];

  void follow(List<SpellRecoveryInput> inputs) {
    _inputs = List.unmodifiable(inputs);
    _refresh();
  }

  /// Un tick, nuovi input o un nuovo offset: ricalcola e tiene vivo il ticker
  /// solo finché qualche countdown può ancora cambiare etichetta.
  void _refresh() {
    final now = _clock.now();
    final statuses = {
      for (final input in _inputs)
        input.spellId: spellRecoveryStatusOf(input, now),
    };
    emit(SpellRecoveryState(Map.unmodifiable(statuses)));
    if (!statuses.values.any((status) => status is SpellRecoveryCountdown)) {
      return _stopTimer();
    }
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
