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

  /// Città dei POI in [cityPointIds].
  final String? cityId;

  /// POI della città corrente (GetCity); null = non noti.
  final Set<String>? cityPointIds;

  const QuestLoaded(this.quests, {this.cityId, this.cityPointIds});

  @override
  List<Object?> get props => [quests, cityId, cityPointIds];
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
