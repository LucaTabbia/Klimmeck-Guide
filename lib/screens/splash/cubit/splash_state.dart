part of 'splash_cubit.dart';

@immutable
abstract class SplashState {}

class SplashInitial extends SplashState {}

class SplashData extends SplashState {}

class SplashError extends SplashState {
  final String error;
  SplashError(this.error);
}
