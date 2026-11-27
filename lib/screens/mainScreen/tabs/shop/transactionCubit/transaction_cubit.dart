import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/character_imprisoned.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

import '../../../../../models/request/transaction_request.dart';
import '../../../../../repository/services/graphql/graphql.dart';

part 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState>
    with SafeEmit<TransactionState> {
  TransactionCubit(
    this.graphQl, {
    this.resetDelay = defaultResetDelay,
    this.minimumLoading = defaultMinimumLoading,
  }) : super(TransactionInitial());

  static const Duration defaultResetDelay = Duration(seconds: 4);

  /// Il negoziante conta le monete almeno per questo tempo, anche quando il
  /// server risponde prima.
  static const Duration defaultMinimumLoading = Duration(seconds: 2);

  final KlimmeckGraphQl graphQl;
  final Duration resetDelay;
  final Duration minimumLoading;
  Timer? _resetTimer;

  Future<void> doTransaction(TransactionRequest input) async {
    _resetTimer?.cancel();
    emit(TransactionLoading());
    final counting = Future<void>.delayed(minimumLoading);
    final outcome = await _outcomeOf(input);
    await counting;
    _settle(outcome);
  }

  /// Una borsa che non basta non arriva al server: il negoziante la rifiuta
  /// subito.
  void refuseInsufficientFunds() {
    _resetTimer?.cancel();
    _settle(TransactionError(TransactionFailure.insufficientFunds));
  }

  Future<TransactionState> _outcomeOf(TransactionRequest input) async {
    try {
      await graphQl.doTransaction(input);
      return TransactionDone();
    } on OperationException catch (error) {
      return TransactionError(
        transactionFailureFrom(error),
        imprisonedUntil: imprisonedUntilFrom(error),
      );
    } on Object {
      return TransactionError(TransactionFailure.unknown);
    }
  }

  void _settle(TransactionState outcome) {
    emit(outcome);
    _scheduleReset();
  }

  void _scheduleReset() {
    _resetTimer = Timer(resetDelay, () {
      if (!isClosed) emit(TransactionInitial());
    });
  }

  @override
  Future<void> close() {
    _resetTimer?.cancel();
    return super.close();
  }
}
