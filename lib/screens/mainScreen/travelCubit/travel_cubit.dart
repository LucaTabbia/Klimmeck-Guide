import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart';
import 'package:klimmeck_guide/repository/travel_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'travel_state.dart';

/// Conferma del viaggio libero (07-CONTEXT D-01..D-05): anteprima del BE,
/// "Parti"/"Resta", avvio. Il viaggio arriva su `characterUpdated`, mai da
/// `startTravel`; banner e reset li gestisce `TravelOutcomeListener` (un
/// Cubit non chiama Cubit).
class TravelCubit extends Cubit<TravelState> with SafeEmit<TravelState> {
  TravelCubit(
    this._repository, {
    required ServerClockService clock,
    Duration startedHold = defaultStartedHold,
  }) : _clock = clock,
       _startedHold = startedHold,
       super(const TravelIdle()) {
    _offsetSubscription = clock.offsetChanges.listen((_) => _fillPendingEta());
  }

  /// Se `activeTravel` non arriva (WS giù), il flusso torna libero da sé.
  static const Duration defaultStartedHold = Duration(seconds: 30);

  final TravelRepository _repository;
  final ServerClockService _clock;
  final Duration _startedHold;
  late final StreamSubscription<void> _offsetSubscription;
  String? _characterId;
  Timer? _holdTimer;

  /// Token della richiesta d'anteprima corrente: le risposte di richieste
  /// superate (annullate o rimpiazzate) vengono ignorate, anche se lo stato è
  /// uguale.
  int _previewToken = 0;

  Future<void> preview({
    required String characterId,
    required City destination,
  }) async {
    final poiId = destination.markerLocation?.id;
    if (state is! TravelIdle || poiId == null) return;
    _characterId = characterId;
    final token = ++_previewToken;
    emit(TravelPreviewing(destination));
    if (!_clock.isSynced) unawaited(_clock.sync());
    try {
      final result = await _repository.preview(
        characterId: characterId,
        poiId: poiId,
      );
      if (_isStale(token)) return;
      emit(_confirmingFrom(destination, result));
    } on TravelException catch (error) {
      _failPreview(token, destination, error.failure);
    } catch (_) {
      _failPreview(token, destination, TravelFailure.unknown);
    }
  }

  Future<void> start() async {
    final confirming = state;
    if (confirming is! TravelConfirming) return;
    emit(_startingFrom(confirming));
    final destination = confirming.destination;
    try {
      await _repository.start(
        characterId: _characterId!,
        poiId: destination.markerLocation!.id,
      );
      if (isClosed) return;
      emit(
        TravelStarted(destination: destination, preview: confirming.preview),
      );
      _holdStarted();
    } on TravelException catch (error) {
      _failStart(destination, error.failure);
    } catch (_) {
      _failStart(destination, TravelFailure.unknown);
    }
  }

  /// "Resta" o foglio chiuso: invalida l'anteprima ancora in volo.
  void cancel() {
    if (state is! TravelPreviewing && state is! TravelConfirming) return;
    _previewToken++;
    emit(const TravelIdle());
  }

  /// Dopo che la sessione ha gestito l'esito: la prossima meta riparte pulita.
  void reset() {
    if (state is TravelStarting) return;
    _holdTimer?.cancel();
    emit(const TravelIdle());
  }

  @override
  Future<void> close() {
    _holdTimer?.cancel();
    _offsetSubscription.cancel();
    return super.close();
  }

  bool _isStale(int token) =>
      token != _previewToken || state is! TravelPreviewing;

  /// WR-03: nessun ETA da un orologio non sincronizzato; il foglio tiene il
  /// segnaposto e [_fillPendingEta] lo completa al primo sync.
  TravelConfirming _confirmingFrom(City destination, TravelPreview result) {
    final now = _syncedNow();
    return TravelConfirming(
      destination: destination,
      preview: result,
      eta: _etaFrom(now, result),
      previewedAt: now,
    );
  }

  DateTime? _syncedNow() => _clock.isSynced ? _clock.now() : null;

  static DateTime? _etaFrom(DateTime? now, TravelPreview preview) =>
      now?.add(Duration(milliseconds: preview.duration.round()));

  void _fillPendingEta() {
    final now = _syncedNow();
    if (now == null) return;
    final current = state;
    if (current is TravelConfirming && current.eta == null) {
      emit(
        TravelConfirming(
          destination: current.destination,
          preview: current.preview,
          eta: _etaFrom(now, current.preview),
          previewedAt: now,
        ),
      );
    } else if (current is TravelStarting && current.eta == null) {
      emit(
        TravelStarting(
          destination: current.destination,
          preview: current.preview,
          eta: _etaFrom(now, current.preview),
          previewedAt: now,
        ),
      );
    }
  }

  TravelStarting _startingFrom(TravelConfirming confirming) => TravelStarting(
    destination: confirming.destination,
    preview: confirming.preview,
    eta: confirming.eta,
    previewedAt: confirming.previewedAt,
  );

  void _holdStarted() {
    _holdTimer?.cancel();
    _holdTimer = Timer(_startedHold, () {
      if (state is TravelStarted) emit(const TravelIdle());
    });
  }

  void _failPreview(int token, City destination, TravelFailure failure) {
    if (_isStale(token)) return;
    emit(
      TravelFailed(
        destination: destination,
        failure: failure,
        stage: TravelStage.preview,
      ),
    );
  }

  void _failStart(City destination, TravelFailure failure) => emit(
    TravelFailed(
      destination: destination,
      failure: failure,
      stage: TravelStage.start,
    ),
  );
}
