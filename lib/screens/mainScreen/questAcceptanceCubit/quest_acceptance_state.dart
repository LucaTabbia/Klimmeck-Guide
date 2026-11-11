part of 'quest_acceptance_cubit.dart';

sealed class QuestAcceptanceState extends Equatable {
  const QuestAcceptanceState();
}

final class QuestAcceptanceIdle extends QuestAcceptanceState {
  const QuestAcceptanceIdle();

  @override
  List<Object?> get props => [];
}

final class QuestAccepting extends QuestAcceptanceState {
  const QuestAccepting(this.questId);

  final String questId;

  @override
  List<Object?> get props => [questId];
}

final class QuestAccepted extends QuestAcceptanceState {
  const QuestAccepted(this.questId);

  final String questId;

  @override
  List<Object?> get props => [questId];
}

final class QuestAcceptanceFailed extends QuestAcceptanceState {
  const QuestAcceptanceFailed(
    this.questId,
    this.failure, {
    this.imprisonedUntil,
  });

  final String questId;
  final QuestAcceptanceFailure failure;

  /// Fine della prigione detta dal server (quick 261110-cgd); solo per
  /// [QuestAcceptanceFailure.imprisoned].
  final DateTime? imprisonedUntil;

  @override
  List<Object?> get props => [questId, failure, imprisonedUntil];
}
