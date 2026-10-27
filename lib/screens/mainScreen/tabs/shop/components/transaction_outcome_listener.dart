import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice.dart';

/// Rifiuti del negozio che meritano un banner per codice (D-16); gli altri
/// restano al fumetto del negoziante in `Shop`.
class TransactionOutcomeListener extends StatelessWidget {
  const TransactionOutcomeListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocListener<TransactionCubit, TransactionState>(
        listenWhen: (_, current) => current is TransactionError,
        listener: (context, state) =>
            _announce(context, state as TransactionError),
        child: child,
      );

  void _announce(BuildContext context, TransactionError state) {
    final notice = transactionNoticeFor(state.failure);
    if (notice == null) return;
    context.read<InAppNotificationsCubit>().publishNotice(
      notice,
      dedupKey: 'transaction|${state.failure.name}',
    );
  }
}
