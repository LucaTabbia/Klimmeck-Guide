import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/requestCompletionCubit/request_completion_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/request_completion_screen.dart';

/// Esito del form per il pannello (10-CONTEXT D-13/D-14).
sealed class CompletionExit extends Equatable {
  const CompletionExit();

  @override
  List<Object?> get props => [];
}

/// Richiesta chiusa: i risultati, uno per partecipante.
final class CompletionCompleted extends CompletionExit {
  const CompletionCompleted(this.results);

  final List<QuestResult> results;

  @override
  List<Object?> get props => [results];
}

/// NOT_FOUND: completata altrove o sparita.
final class CompletionGone extends CompletionExit {
  const CompletionGone();
}

/// QUEST_IN_PROGRESS (BE-HARD-08).
final class CompletionBusy extends CompletionExit {
  const CompletionBusy();
}

/// FORBIDDEN: il ruolo non c'è più, il pannello si chiude (D-04).
final class CompletionForbidden extends CompletionExit {
  const CompletionForbidden();
}

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
