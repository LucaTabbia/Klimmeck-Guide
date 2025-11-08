part of 'quest_cubit.dart';

@immutable
sealed class QuestState extends Equatable {
  const QuestState();
}

class QuestInitial extends QuestState {
  @override
  List<Object> get props => [];
}

class QuestLoaded extends QuestState {
  final List<Quest> quests;

  const QuestLoaded(this.quests);

  @override
  List<Object> get props => [quests, DateTime.now()];
}

class QuestLoading extends QuestState {
  @override
  List<Object> get props => [];
}

class QuestError extends QuestState {
  final String errorMessage;

  const QuestError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
