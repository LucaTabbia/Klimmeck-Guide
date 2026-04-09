part of 'profile_cubit.dart';

@immutable
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileError extends ProfileState {
  final String errorMessage;

  const ProfileError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class ProfileResetError extends ProfileState {
  final String errorMessage;

  const ProfileResetError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class ProfileData extends ProfileState {
  const ProfileData();
}

class ProfileReset extends ProfileState {}

class ProfileLogOut extends ProfileState {}
