import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/request_card_view.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/results_recap_dialog.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_access.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_route.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/request_completion_route.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Pannello della Locanda (10-CONTEXT D-01/D-05..D-09): utility screen con la
/// coda viva del GM; il loader solo fino al primo snapshot (apertura
/// esplicita). Si chiude da solo su `FORBIDDEN` o sul ruolo perso (D-04).
/// «Teletrasporta» prepara la modalità della shell: il salto alla Mappa lo fa
/// `TeleportModeLanding` (D-15). Richiede [PendingRequestsCubit], [AuthCubit]
/// e [TeleportModeCubit] sopra di sé.
class InnkeeperPanelScreen extends StatelessWidget {
  const InnkeeperPanelScreen({
    super.key,
    this.openCompletion = openRequestCompletion,
  });

  static const String title = 'Locanda';
  static const String emptyTitle = 'Nessuna richiesta in attesa';
  static const String emptyNote = 'La coda si aggiorna da sola';
  static const String unavailableMessage = 'La Locanda non è disponibile';
  static const String goneMessage = 'Richiesta non più disponibile';
  static const String busyMessage =
      'Un partecipante è impegnato in una missione';
  static const String teleportUnavailableMessage =
      'Impossibile aprire la mappa per il teletrasporto';

  /// Apre il form di completamento; iniettabile per guidare gli esiti nei test.
  final Future<CompletionExit?> Function(BuildContext, RequestCard)
  openCompletion;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PendingRequestsCubit, PendingRequestsState>(
          listenWhen: (previous, current) =>
              !previous.isForbidden && current.isForbidden,
          listener: (context, _) => _closeUnavailable(context),
        ),
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              isInnkeeperSession(previous) && !isInnkeeperSession(current),
          listener: (context, _) => closeInnkeeperPanel(context),
        ),
        BlocListener<TeleportModeCubit, TeleportModeState>(
          listenWhen: (previous, current) =>
              current is TeleportPreparationFailed && previous != current,
          listener: (context, _) => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(teleportUnavailableMessage)),
          ),
        ),
      ],
      child: PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) _cancelTeleportRead(context);
        },
        child: _buildScaffold(context),
      ),
    );
  }

  /// Una lettura per il teletrasporto vive col pannello: uscire la annulla.
  /// Con la modalità già attiva il pop è l'atterraggio sulla Mappa (D-15).
  static void _cancelTeleportRead(BuildContext context) {
    final teleport = context.read<TeleportModeCubit>();
    if (teleport.state is TeleportPreparing) teleport.cancel();
  }

  // default per veto (10-CONTEXT D-04/C8): SnackBar invece del pop silenzioso
  static void _closeUnavailable(BuildContext context) {
    if (ModalRoute.of(context)?.isActive != true) return;
    final messenger = ScaffoldMessenger.of(context);
    closeInnkeeperPanel(context);
    messenger.showSnackBar(const SnackBar(content: Text(unavailableMessage)));
  }

  /// Traduce l'esito del form (10-CONTEXT D-13/D-14).
  Future<void> _complete(BuildContext context, RequestCard card) async {
    final queue = context.read<PendingRequestsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final exit = await openCompletion(context, card);
    if (!context.mounted) return;
    switch (exit) {
      case CompletionCompleted(:final results):
        queue.markCompleted(card.questId);
        await showResultsRecap(context, card: card, results: results);
      case CompletionGone():
        queue.markCompleted(card.questId);
        unawaited(queue.refetch());
        messenger.showSnackBar(const SnackBar(content: Text(goneMessage)));
      case CompletionBusy():
        unawaited(queue.refetch());
        messenger.showSnackBar(const SnackBar(content: Text(busyMessage)));
      case CompletionForbidden():
        _closeUnavailable(context);
      case null:
        return;
    }
  }

  /// [panelContext] è quello della schermata: resta montato quando la coda si
  /// svuota con il form aperto, così l'esito arriva comunque (WR-01).
  Widget _buildScaffold(BuildContext panelContext) {
    return Scaffold(
      appBar: AppBar(title: const Text(title)),
      body: DecoratedBox(
        decoration: KlimmeckGuideTheme.getParchmentBackground(),
        child: SafeArea(
          child: BlocBuilder<PendingRequestsCubit, PendingRequestsState>(
            builder: (_, state) => _buildQueue(panelContext, state),
          ),
        ),
      ),
    );
  }

  Widget _buildQueue(BuildContext panelContext, PendingRequestsState state) {
    if (!state.isLoaded) return const Center(child: KGLoader());
    final cards = state.cards;
    if (cards.isEmpty) return const _EmptyQueue();
    return BlocSelector<TeleportModeCubit, TeleportModeState, String?>(
      selector: (teleport) =>
          teleport is TeleportPreparing ? teleport.characterId : null,
      builder: (_, preparingCharacterId) => ListView.separated(
        padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingLg),
        itemCount: cards.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: KlimmeckGuideTheme.spacingMd),
        itemBuilder: (_, index) => RequestCardView(
          key: RequestCardView.keyFor(cards[index].questId),
          card: cards[index],
          serverNow: state.serverNow,
          onComplete: (card) => _complete(panelContext, card),
          preparingCharacterId: preparingCharacterId,
          onTeleport: (participant) => panelContext
              .read<TeleportModeCubit>()
              .prepare(characterId: participant.id, name: participant.name),
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(InnkeeperPanelScreen.emptyTitle, style: theme.titleMedium),
          const SizedBox(height: KlimmeckGuideTheme.spacingSm),
          Text(InnkeeperPanelScreen.emptyNote, style: theme.bodyMedium),
        ],
      ),
    );
  }
}
