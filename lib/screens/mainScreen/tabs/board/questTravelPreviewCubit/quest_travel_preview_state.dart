part of 'quest_travel_preview_cubit.dart';

sealed class QuestTravelPreviewState extends Equatable {
  const QuestTravelPreviewState();
}

final class QuestTravelPreviewIdle extends QuestTravelPreviewState {
  const QuestTravelPreviewIdle();

  @override
  List<Object?> get props => [];
}

final class QuestTravelPreviewLoading extends QuestTravelPreviewState {
  const QuestTravelPreviewLoading();

  @override
  List<Object?> get props => [];
}

final class QuestTravelPreviewLoaded extends QuestTravelPreviewState {
  const QuestTravelPreviewLoaded(this.preview);

  /// `null` = l'accettazione non comporta un viaggio: nessuna riga (D-04).
  final TravelPreview? preview;

  @override
  List<Object?> get props => [preview];
}

/// Nessun banner: la riga non c'è e lo swipe resta com'è, il rifiuto del BE
/// resta la difesa (D-04).
final class QuestTravelPreviewFailed extends QuestTravelPreviewState {
  const QuestTravelPreviewFailed(this.failure);

  final TravelFailure failure;

  @override
  List<Object?> get props => [failure];
}
