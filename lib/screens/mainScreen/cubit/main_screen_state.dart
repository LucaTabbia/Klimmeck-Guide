part of 'main_screen_cubit.dart';

@immutable
abstract class MainScreenState extends Equatable {
  const MainScreenState();

  @override
  List<Object?> get props => [];
}

class MainScreenInitial extends MainScreenState {}

class MainScreenLoadData extends MainScreenState {
  final List<City> cities;

  const MainScreenLoadData(this.cities);

  @override
  List<Object?> get props => [cities];
}

class MainScreenLoading extends MainScreenState {}

class MainScreenError extends MainScreenState {
  final String errorMessage;

  const MainScreenError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
