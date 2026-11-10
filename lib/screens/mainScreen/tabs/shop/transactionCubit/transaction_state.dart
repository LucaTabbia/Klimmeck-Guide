part of 'transaction_cubit.dart';

@immutable
sealed class TransactionState {}

final class TransactionInitial extends TransactionState {}

final class TransactionLoading extends TransactionState {}

final class TransactionDone extends TransactionState {}

final class TransactionError extends TransactionState {
  TransactionError(this.failure, {this.imprisonedUntil});

  final TransactionFailure failure;

  /// Fine della prigione detta dal server (quick 261110-cgd); solo per
  /// [TransactionFailure.imprisoned].
  final DateTime? imprisonedUntil;
}
