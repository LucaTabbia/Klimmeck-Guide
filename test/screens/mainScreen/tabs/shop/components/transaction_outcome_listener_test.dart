import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/prisonCubit/prison_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/transaction_outcome_listener.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/test_app.dart';

void main() {
  late MockTransactionCubit transaction;
  late MockInAppNotificationsCubit notices;
  late MockPrisonCubit prison;
  late StreamController<TransactionState> transactionStates;

  setUpAll(() {
    registerFallbackValue(const KGNotification(title: '', description: ''));
  });

  setUp(() {
    transaction = MockTransactionCubit();
    notices = MockInAppNotificationsCubit();
    prison = MockPrisonCubit();
    whenListen(
      prison,
      const Stream<PrisonState>.empty(),
      initialState: const PrisonState(Duration(hours: 9, minutes: 12)),
    );
    transactionStates = StreamController<TransactionState>.broadcast();
    addTearDown(transactionStates.close);
    whenListen(
      transaction,
      transactionStates.stream,
      initialState: TransactionInitial(),
    );
  });

  Future<void> pumpListener(WidgetTester tester) => tester.pumpWidget(
    buildTestApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<TransactionCubit>.value(value: transaction),
          BlocProvider<InAppNotificationsCubit>.value(value: notices),
          BlocProvider<PrisonCubit>.value(value: prison),
        ],
        child: const TransactionOutcomeListener(child: SizedBox()),
      ),
    ),
  );

  Future<void> emitTransaction(
    WidgetTester tester,
    TransactionState state,
  ) async {
    transactionStates.add(state);
    await tester.pump();
  }

  testWidgets('SHOP_NOT_IN_CITY publishes the out-of-city banner', (
    tester,
  ) async {
    await pumpListener(tester);

    await emitTransaction(
      tester,
      TransactionError(TransactionFailure.shopNotInCity),
    );

    verify(
      () => notices.publishNotice(
        const KGNotification(
          title: 'Negozio non disponibile',
          description: 'Il negozio è disponibile solo in città',
        ),
        dedupKey: 'transaction|shopNotInCity',
      ),
    ).called(1);
  });

  testWidgets('a prison refusal feeds the prison and announces the release '
      '(quick 261110-cgd)', (tester) async {
    final release = DateTime.utc(2026, 11, 10, 22);
    await pumpListener(tester);

    await emitTransaction(
      tester,
      TransactionError(TransactionFailure.imprisoned, imprisonedUntil: release),
    );

    verify(() => prison.learnRelease(release)).called(1);
    verify(
      () => notices.publishNotice(
        const KGNotification(
          title: 'Negozio non disponibile',
          description: 'Sei in prigione: uscirai fra 9 h 12 min',
        ),
        dedupKey: 'transaction|imprisoned',
      ),
    ).called(1);
  });

  testWidgets('other refusals publish no banner', (tester) async {
    await pumpListener(tester);

    await emitTransaction(
      tester,
      TransactionError(TransactionFailure.insufficientFunds),
    );

    verifyNever(
      () => notices.publishNotice(any(), dedupKey: any(named: 'dedupKey')),
    );
  });

  testWidgets('a successful transaction publishes no banner', (tester) async {
    await pumpListener(tester);

    await emitTransaction(tester, TransactionDone());

    verifyNever(
      () => notices.publishNotice(any(), dedupKey: any(named: 'dedupKey')),
    );
  });
}
