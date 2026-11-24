part of 'account_deletion_cubit.dart';

class AccountDeletionState extends Equatable {
  const AccountDeletionState({this.isDeleting = false, this.failure});

  final bool isDeleting;
  final AccountDeletionFailure? failure;

  @override
  List<Object?> get props => [isDeleting, failure];
}
