part of 'splash_cubit.dart';

@immutable
abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {
  const SplashInitial();
}

class SplashData extends SplashState {
  const SplashData();
}

class SplashError extends SplashState {
  final String error;
  const SplashError(this.error);

  @override
  List<Object?> get props => [error];
}

/// Cold start oltre [SplashCubit.connectionHintDelay] senza esito (D-18).
class SplashNetworkDelayed extends SplashState {
  const SplashNetworkDelayed();
}

/// Download delle immagini al cold start: quanta parte è arrivata, da 0 a 100.
class SplashPreloading extends SplashState {
  const SplashPreloading(this.percent);

  final int percent;

  @override
  List<Object?> get props => [percent];
}
