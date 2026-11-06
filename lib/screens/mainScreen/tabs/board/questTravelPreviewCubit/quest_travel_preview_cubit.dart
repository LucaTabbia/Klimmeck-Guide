import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart';
import 'package:klimmeck_guide/repository/travel_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'quest_travel_preview_state.dart';

/// Anteprima del viaggio automatico del foglio aperto sulla Bacheca
/// (15-CONTEXT D-04, D-08): vive quanto il foglio; `refresh` dopo un rifiuto
/// per fame dell'accettazione (D-05). Nessuno spinner: lo stato in attesa
/// non mostra nulla.
class QuestTravelPreviewCubit extends Cubit<QuestTravelPreviewState>
    with SafeEmit<QuestTravelPreviewState> {
  QuestTravelPreviewCubit(this._repository)
    : super(const QuestTravelPreviewIdle());

  final TravelRepository _repository;
  String? _characterId;
  String? _questId;

  /// Le risposte di richieste superate vengono ignorate.
  int _requestToken = 0;

  Future<void> load({required String characterId, required String questId}) {
    _characterId = characterId;
    _questId = questId;
    return _fetch();
  }

  Future<void> refresh() async {
    if (_characterId == null || _questId == null) return;
    await _fetch();
  }

  Future<void> _fetch() async {
    final token = ++_requestToken;
    emit(const QuestTravelPreviewLoading());
    try {
      final preview = await _repository.previewQuest(
        characterId: _characterId!,
        questId: _questId!,
      );
      if (token == _requestToken) emit(QuestTravelPreviewLoaded(preview));
    } on TravelException catch (error) {
      if (token == _requestToken) emit(QuestTravelPreviewFailed(error.failure));
    } catch (_) {
      if (token == _requestToken) {
        emit(const QuestTravelPreviewFailed(TravelFailure.unknown));
      }
    }
  }
}
