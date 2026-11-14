import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/companion/companion_vitality.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'companion_vitality_state.dart';

/// Vita dei compagni sull'ora del server (D-09, D-24): interpola fra le date
/// servite, mai dal tempo di recupero del catalogo. Vive solo mentre il
/// Diario è a schermo.
class CompanionVitalityCubit extends Cubit<CompanionVitalityState>
    with SafeEmit<CompanionVitalityState> {
  CompanionVitalityCubit({
    required ServerClockService clock,
    Duration tick = defaultTick,
  }) : _clock = clock,
       _tick = tick,
       super(const CompanionVitalityState()) {
    _offsetSubscription = clock.offsetChanges.listen((_) => _refresh());
  }

  /// La vita sale di un punto alla volta: un secondo basta a non mostrarla in
  /// ritardo.
  static const Duration defaultTick = Duration(seconds: 1);

  final ServerClockService _clock;
  final Duration _tick;
  late final StreamSubscription<void> _offsetSubscription;
  Timer? _timer;
  List<OwnedPet> _owned = const [];
  String? _equippedPetId;

  void follow(List<OwnedPet> owned, {String? equippedPetId}) {
    _owned = List.unmodifiable(owned);
    _equippedPetId = equippedPetId;
    _refresh();
  }

  /// Un tick, nuovi compagni o un nuovo offset: ricalcola e tiene vivo il
  /// ticker solo finché qualche compagno riposa o aspetta la pozione.
  void _refresh() {
    final now = _clock.now();
    final vitalities = {
      for (final entry in _owned)
        entry.pet.id: companionVitalityOf(
          entry,
          now,
          isEquipped: entry.pet.id == _equippedPetId,
        ),
    };
    final potionWaits = {
      for (final entry in _owned)
        if (companionPotionWaitOf(entry, now) case final wait?)
          entry.pet.id: wait,
    };
    emit(
      CompanionVitalityState(
        vitalities: Map.unmodifiable(vitalities),
        potionWaits: Map.unmodifiable(potionWaits),
        sources: Map.unmodifiable({
          for (final entry in _owned) entry.pet.id: entry,
        }),
      ),
    );
    if (!_isChanging(vitalities.values) && potionWaits.isEmpty) {
      return _stopTimer();
    }
    _timer ??= Timer.periodic(_tick, (_) => _refresh());
  }

  static bool _isChanging(Iterable<CompanionVitality> vitalities) =>
      vitalities.any((vitality) => vitality is! CompanionSteady);

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
