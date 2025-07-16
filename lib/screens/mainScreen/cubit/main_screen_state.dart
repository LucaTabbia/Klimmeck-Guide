part of 'main_screen_cubit.dart';

@immutable
abstract class MainScreenState {}

class MainScreenInitial extends MainScreenState {}

class MainScreenLoadData extends MainScreenState {
  final User user;

  MainScreenLoadData(this.user);
}

class MainScreenLoading extends MainScreenState {}

class MainScreenError extends MainScreenState {
  final String errorMessage;

  MainScreenError(this.errorMessage);
}
