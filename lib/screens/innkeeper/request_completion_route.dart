import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/screens/innkeeper/completion_exit.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/requestCompletionCubit/request_completion_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/request_completion_screen.dart';

export 'completion_exit.dart';

/// Il form vive sul Navigator radice come il pannello: repository e coda passano con `.value` (P1).
Future<CompletionExit?> openRequestCompletion(
  BuildContext panelContext,
  RequestCard card,
) {
  final repository = panelContext.read<InnkeeperRepository>();
  final queue = panelContext.read<PendingRequestsCubit>();
  return Navigator.of(panelContext).push<CompletionExit>(
    MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<PendingRequestsCubit>.value(value: queue),
          BlocProvider<RequestCompletionCubit>(
            create: (_) =>
                RequestCompletionCubit(repository: repository, card: card)
                  ..load(),
          ),
        ],
        child: RequestCompletionScreen(card: card),
      ),
    ),
  );
}
