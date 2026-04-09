part of 'splash_cubit.dart';

@immutable
abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {}

class SplashData extends SplashState {}

class SplashError extends SplashState {
  final String error;
  const SplashError(this.error);

  @override
  List<Object?> get props => [error];
}
