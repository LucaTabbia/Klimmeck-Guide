import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../../../models/request/transaction_request.dart';
import '../../../../../repository/services/graphql/graphql.dart';

part 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit(this.graphQl) : super(TransactionInitial());
  final KlimmeckGraphQl graphQl;

  Future<void> doTransaction(TransactionRequest input) async {
    emit(TransactionLoading());
    try {
      await graphQl.doTransaction(input);
      emit(TransactionDone());
      Future.delayed(Duration(seconds: 4), () => {emit(TransactionInitial())});
    } catch (e) {
      print(e.toString());
      emit(TransactionError());
      Future.delayed(Duration(seconds: 4), () => {emit(TransactionInitial())});
    }
  }
}
