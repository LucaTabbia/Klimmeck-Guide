part of 'sign_in_cubit.dart';

enum SignInFailure { connection, twitchNotConfigured }

sealed class SignInState extends Equatable {
  const SignInState();

  @override
  List<Object?> get props => [];
}

final class SignInIdle extends SignInState {
  const SignInIdle();
}

final class SignInInProgress extends SignInState {
  const SignInInProgress();
}

final class SignInFailed extends SignInState {
  const SignInFailed(this.failure);

  final SignInFailure failure;

  @override
  List<Object?> get props => [failure];
}
