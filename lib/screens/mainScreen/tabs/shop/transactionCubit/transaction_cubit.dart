import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

import '../../../../../models/request/transaction_request.dart';
import '../../../../../repository/services/graphql/graphql.dart';

part 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState>
    with SafeEmit<TransactionState> {
  TransactionCubit(this.graphQl, {this.resetDelay = defaultResetDelay})
    : super(TransactionInitial());

  static const Duration defaultResetDelay = Duration(seconds: 4);

  final KlimmeckGraphQl graphQl;
  final Duration resetDelay;
  Timer? _resetTimer;

  Future<void> doTransaction(TransactionRequest input) async {
    _resetTimer?.cancel();
    emit(TransactionLoading());
    try {
      await graphQl.doTransaction(input);
      emit(TransactionDone());
    } on OperationException catch (error) {
      emit(TransactionError(transactionFailureFrom(error)));
    } on Object {
      emit(TransactionError(TransactionFailure.unknown));
    }
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
