part of 'main_screen_cubit.dart';

@immutable
abstract class MainScreenState {}

class MainScreenInitial extends MainScreenState {}

class MainScreenLoadData extends MainScreenState {
  final Character character;
  final List<City> cities;
  final List<Quest> quests;

  MainScreenLoadData(this.character, this.cities, this.quests);
}

class MainScreenLoading extends MainScreenState {}

class MainScreenError extends MainScreenState {
  final String errorMessage;

  MainScreenError(this.errorMessage);
}
