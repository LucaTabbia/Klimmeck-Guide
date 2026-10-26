part of 'quest_abandon_cubit.dart';

sealed class QuestAbandonState extends Equatable {
  const QuestAbandonState();
}

final class QuestAbandonIdle extends QuestAbandonState {
  const QuestAbandonIdle();

  @override
  List<Object?> get props => [];
}

final class QuestAbandoning extends QuestAbandonState {
  const QuestAbandoning(this.questId);

  final String questId;

  @override
  List<Object?> get props => [questId];
}

final class QuestAbandoned extends QuestAbandonState {
  const QuestAbandoned(this.questId);

  final String questId;

  @override
  List<Object?> get props => [questId];
}

final class QuestAbandonFailed extends QuestAbandonState {
  const QuestAbandonFailed(this.questId, this.failure);

  final String questId;
  final QuestAbandonFailure failure;

  @override
  List<Object?> get props => [questId, failure];
}
