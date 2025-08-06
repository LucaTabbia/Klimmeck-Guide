part of 'profile_cubit.dart';

@immutable
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileError extends ProfileState {
  final String errorMessage;

  ProfileError(this.errorMessage);
}

class ProfileResetError extends ProfileState {
  final String errorMessage;

  ProfileResetError(this.errorMessage);
}

class ProfileData extends ProfileState {
  ProfileData();
}

class ProfileReset extends ProfileState {}

class ProfileLogOut extends ProfileState {}
