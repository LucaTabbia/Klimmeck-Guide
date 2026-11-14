import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'mission_draft_state.dart';

/// Ciclo di vita della bozza del completamento guidato (D-09, D-11, D-28): la
/// bozza vive sul BE, il Cubit tiene solo quella servita e manda input costruiti
/// da essa. Nessuna fusione locale: ogni risposta sostituisce lo stato.
class MissionDraftCubit extends Cubit<MissionDraftState>
    with SafeEmit<MissionDraftState> {
  MissionDraftCubit({
    required InnkeeperRepository repository,
    required String pendingQuestId,
  }) : _repository = repository,
       _pendingQuestId = pendingQuestId,
       super(const MissionDraftLoading());

  final InnkeeperRepository _repository;
  final String _pendingQuestId;
  bool _isLoading = false;

  /// Apertura e «Riprova»: senza bozza la pagina di avvio, mai una bozza
  /// creata qui (D-28).
  Future<void> load() async {
    if (!_canLoad) return;
    _isLoading = true;
    if (state is! MissionDraftLoading) emit(const MissionDraftLoading());
    try {
      final draft = await _repository.readMissionDraft(_pendingQuestId);
      emit(draft == null ? const MissionDraftAbsent() : _readyAt(draft));
    } on InnkeeperException catch (error) {
      emit(MissionDraftLoadFailed(failure: error.failure));
    } finally {
      _isLoading = false;
    }
  }

  bool get _canLoad =>
      !_isLoading &&
      (state is MissionDraftLoading || state is MissionDraftLoadFailed);

  /// Crea la bozza su azione esplicita dell'oste: da qui i partecipanti sono
  /// bloccati (D-11, D-28).
  Future<void> start() async {
    final current = state;
    if (current is! MissionDraftAbsent || current.isStarting) return;
    emit(
      MissionDraftAbsent(
        isStarting: true,
        failureSerial: current.failureSerial,
      ),
    );
    try {
      emit(_readyAt(await _repository.startMissionDraft(_pendingQuestId)));
    } on InnkeeperException catch (error) {
      emit(
        MissionDraftAbsent(
          failure: error.failure,
          failureSerial: current.failureSerial + 1,
        ),
      );
    }
  }

  Future<void> saveStep(MissionDraftStep step, {String? placeId}) => _save(
    (_) => SaveMissionDraftInput(
      pendingQuestId: _pendingQuestId,
      step: step,
      placeId: placeId,
    ),
  );

  /// La sezione degli scontri è sostituita per intero: le correzioni servite
  /// restano solo sugli scontri coi nemici invariati, il BE invalida il resto.
  Future<void> saveFights(
    List<List<MissionEnemyInput>> enemiesPerFight, {
    MissionDraftStep? step,
  }) => _save(
    (draft) => SaveMissionDraftInput(
      pendingQuestId: _pendingQuestId,
      step: step,
      fights: fightsInputWithEnemies(draft, enemiesPerFight),
    ),
  );

  /// Simula lo scontro coi nemici serviti: l'esito è del BE, mai calcolato qui.
  /// Uno scontro che la bozza servita non ha non manda nulla.
  Future<void> simulate(int fightIndex) async {
    final fights = _servedDraft?.fights ?? const [];
    if (fightIndex < 0 || fightIndex >= fights.length) return;
    await _submit(
      (draft) => _repository.simulateMissionFight(
        SimulateMissionFightInput(
          pendingQuestId: _pendingQuestId,
          fightIndex: fightIndex,
          enemies: List.unmodifiable(
            draft.fights[fightIndex].enemies.map(MissionEnemyInput.of),
          ),
        ),
      ),
    );
  }

  Future<void> saveCorrections(
    int fightIndex,
    List<MissionCorrection> corrections, {
    MissionDraftStep? step,
  }) => _save(
    (draft) => SaveMissionDraftInput(
      pendingQuestId: _pendingQuestId,
      step: step,
      fights: fightsInputWithCorrections(draft, fightIndex, corrections),
    ),
  );

  Future<void> savePrizes(
    List<MissionPrizeInput> prizes, {
    MissionDraftStep? step,
  }) => _save(
    (_) => SaveMissionDraftInput(
      pendingQuestId: _pendingQuestId,
      step: step,
      prizes: List.unmodifiable(prizes),
    ),
  );

  /// Scarta la bozza: il BE libera i partecipanti (D-11).
  Future<void> discard() => _act((_) async {
    await _repository.discardMissionDraft(_pendingQuestId);
    return const MissionDraftDiscarded();
  });

  Future<void> complete() => _act(
    (_) async => MissionDraftCompleted(
      results: await _repository.completeGuidedMission(_pendingQuestId),
    ),
  );

  Future<void> _save(
    SaveMissionDraftInput Function(MissionDraft draft) inputOf,
  ) => _submit((draft) => _repository.saveMissionDraft(inputOf(draft)));

  /// La bozza resa da [call] sostituisce quella servita (D-09).
  Future<void> _submit(
    Future<MissionDraft> Function(MissionDraft draft) call,
  ) => _act(
    (ready) async =>
        _readyAt(await call(ready.draft), failureSerial: ready.failureSerial),
  );

  /// Una sola chiamata alla volta; un rifiuto lascia la bozza servita col suo
  /// codice e un nuovo seriale, le uscite le decide la schermata.
  Future<void> _act(
    Future<MissionDraftState> Function(MissionDraftReady ready) call,
  ) async {
    final current = state;
    if (current is! MissionDraftReady || current.isSubmitting) return;
    emit(current.copyWith(isSubmitting: true));
    try {
      emit(await call(current));
    } on InnkeeperException catch (error) {
      emit(
        current.copyWith(
          failure: error.failure,
          failureSerial: current.failureSerial + 1,
        ),
      );
    }
  }

  MissionDraft? get _servedDraft => switch (state) {
    MissionDraftReady(:final draft) => draft,
    _ => null,
  };

  MissionDraftReady _readyAt(MissionDraft draft, {int failureSerial = 0}) =>
      MissionDraftReady(draft: draft, failureSerial: failureSerial);
}
