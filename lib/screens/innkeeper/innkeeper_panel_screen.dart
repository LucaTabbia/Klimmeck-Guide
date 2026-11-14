import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/generate_quests_button.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/request_card_view.dart';
import 'package:klimmeck_guide/screens/innkeeper/completion_exit.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/results_recap_dialog.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_access.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_route.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_route.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/questGenerationCubit/quest_generation_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Pannello della Locanda (10-CONTEXT D-01/D-05..D-09): utility screen con la
/// coda viva del GM; il loader solo fino al primo snapshot (apertura
/// esplicita). Si chiude da solo su `FORBIDDEN` o sul ruolo perso (D-04).
/// Il teletrasporto parte dal wizard (passo «Luogo», UAT 2026-11-14): il salto
/// alla Mappa lo fa `TeleportModeLanding` (D-15). «Genera missioni» sta in cima, fuori dalla
/// coda (14-CONTEXT D-08). Richiede [PendingRequestsCubit], [AuthCubit],
/// [TeleportModeCubit] e [QuestGenerationCubit] sopra di sé.
class InnkeeperPanelScreen extends StatelessWidget {
  const InnkeeperPanelScreen({
    super.key,
    this.openCompletion = openMissionCompletion,
    this.resumeCardKey,
    this.resumesAtPlace = false,
  });

  static const Key resumeCurtainKey = ValueKey('innkeeper.resumeCurtain');
  static const String title = 'Locanda';
  static const String emptyTitle = 'Nessuna richiesta in attesa';
  static const String emptyNote = 'La coda si aggiorna da sola';
  static const String unavailableMessage = 'La Locanda non è disponibile';
  static const String goneMessage = 'Richiesta non più disponibile';
  static const String busyMessage =
      'Un partecipante è impegnato in una missione';
  static const String teleportUnavailableMessage =
      'Impossibile aprire la mappa per il teletrasporto';
  static const String generateTitle = 'Genera missioni';
  static const String generateBody = 'Generare nuove missioni nel mondo?';
  static const String generateConfirmLabel = 'Genera';
  static const String noQuestsGeneratedMessage = 'Nessuna missione da generare';
  static const String generateFailedMessage =
      'Non è stato possibile generare le missioni. Riprova.';

  /// Copy provvisoria dell'esito (D-09).
  static String generatedMessage(int created) => switch (created) {
    0 => noQuestsGeneratedMessage,
    1 => 'Generata 1 missione',
    _ => 'Generate $created missioni',
  };

  /// Apre il wizard della missione (21-CONTEXT D-25, D-28); iniettabile per
  /// guidare gli esiti nei test.
  final Future<CompletionExit?> Function(
    BuildContext,
    RequestCard, {
    bool atPlace,
  })
  openCompletion;

  /// Carta il cui completamento si riapre dopo il teletrasporto (D-28); `null` = nessuno.
  final String? resumeCardKey;

  /// La ripresa segue un teletrasporto annullato: il wizard riapre su «Luogo»
  /// invece che sul passo servito (UAT 2026-11-14).
  final bool resumesAtPlace;

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
          listener: _onTeleportPreparationFailed,
        ),
        BlocListener<QuestGenerationCubit, QuestGenerationState>(
          listenWhen: (_, current) =>
              current is QuestGenerationSucceeded ||
              current is QuestGenerationFailed,
          listener: _onGenerationOutcome,
        ),
      ],
      child: PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) _cancelTeleportRead(context);
        },
        child: _ResumeCurtain(
          isResuming: resumeCardKey != null,
          onResume: (state) => _resume(context, state),
          child: _buildScaffold(context),
        ),
      ),
    );
  }

  /// Una lettura avviata dal wizard e lasciata in volo tornando al pannello
  /// vive col pannello: uscire la annulla. Con la modalità già attiva il pop è
  /// l'atterraggio sulla Mappa (D-15).
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

  /// Esito in SnackBar come le altre azioni del pannello; `FORBIDDEN` chiude
  /// la Locanda come Phase 10 D-04 (D-09, D-14).
  static void _onGenerationOutcome(
    BuildContext context,
    QuestGenerationState state,
  ) {
    switch (state) {
      case QuestGenerationSucceeded(:final created):
        _showSnackBar(context, generatedMessage(created));
      case QuestGenerationFailed(failure: InnkeeperFailure.forbidden):
        _closeUnavailable(context);
      case QuestGenerationFailed():
        _showSnackBar(context, generateFailedMessage);
      case QuestGenerationIdle() || QuestGenerationSubmitting():
        return;
    }
  }

  /// Con il wizard sopra il pannello l'avviso lo dà il wizard: uno solo (D-28).
  /// Il pannello lo dà per una lettura che il wizard ha lasciato in volo.
  static void _onTeleportPreparationFailed(
    BuildContext context,
    TeleportModeState _,
  ) {
    if (ModalRoute.of(context)?.isCurrent == false) return;
    _showSnackBar(context, teleportUnavailableMessage);
  }

  static void _showSnackBar(BuildContext context, String message) =>
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

  /// Conferma esplicita (D-09): il GM forza una corsa normale del generatore.
  static Future<void> _confirmGeneration(BuildContext context) async {
    final generation = context.read<QuestGenerationCubit>();
    final confirmed = await showDestructiveConfirmation(
      context,
      title: generateTitle,
      body: generateBody,
      confirmLabel: generateConfirmLabel,
      confirmButtonStyle: KlimmeckGuideTheme.primaryButtonStyle,
    );
    if (confirmed && !generation.isClosed) await generation.generate();
  }

  /// Dopo la Mappa (21-CONTEXT D-28, Pitfall 1/5): la carta si ricostruisce
  /// dalle richieste grezze del primo snapshot, anche se non è azionabile.
  Future<void> _resume(BuildContext context, PendingRequestsState state) {
    final card = requestCardsOf(
      state.requests,
    ).where((card) => card.cardKey == resumeCardKey).firstOrNull;
    if (card == null) {
      _showSnackBar(context, goneMessage);
      return Future.value();
    }
    return _complete(context, card, atPlace: resumesAtPlace);
  }

  /// Traduce l'esito del wizard (10-CONTEXT D-13/D-14).
  Future<void> _complete(
    BuildContext context,
    RequestCard card, {
    bool atPlace = false,
  }) async {
    final queue = context.read<PendingRequestsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final exit = await openCompletion(context, card, atPlace: atPlace);
    if (!context.mounted) return;
    switch (exit) {
      case CompletionCompleted(:final results):
        queue.markCompleted(card.cardKey);
        await showResultsRecap(context, card: card, results: results);
      case CompletionGone():
        queue.markCompleted(card.cardKey);
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  KlimmeckGuideTheme.spacingLg,
                  KlimmeckGuideTheme.spacingLg,
                  KlimmeckGuideTheme.spacingLg,
                  0,
                ),
                child:
                    BlocSelector<
                      QuestGenerationCubit,
                      QuestGenerationState,
                      bool
                    >(
                      selector: (state) => state is QuestGenerationSubmitting,
                      builder: (_, isSubmitting) => GenerateQuestsButton(
                        isSubmitting: isSubmitting,
                        onPressed: () => _confirmGeneration(panelContext),
                      ),
                    ),
              ),
              Expanded(
                child: BlocBuilder<PendingRequestsCubit, PendingRequestsState>(
                  builder: (_, state) => _buildQueue(panelContext, state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueue(BuildContext panelContext, PendingRequestsState state) {
    if (!state.isLoaded) return const Center(child: KGLoader());
    final cards = state.cards;
    if (cards.isEmpty) return const _EmptyQueue();
    return ListView.separated(
      padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingLg),
      itemCount: cards.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: KlimmeckGuideTheme.spacingMd),
      itemBuilder: (_, index) => RequestCardView(
        key: RequestCardView.keyFor(cards[index].cardKey),
        card: cards[index],
        serverNow: state.serverNow,
        onComplete: (card) => _complete(panelContext, card),
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

/// Dopo la Mappa il pannello riapre subito il wizard: finché non torna, la
/// coda resta dietro una pergamena, così la Locanda non lampeggia fra la Mappa
/// e il wizard (UAT 2026-11-14).
class _ResumeCurtain extends StatefulWidget {
  const _ResumeCurtain({
    required this.isResuming,
    required this.onResume,
    required this.child,
  });

  final bool isResuming;
  final Future<void> Function(PendingRequestsState state) onResume;
  final Widget child;

  @override
  State<_ResumeCurtain> createState() => _ResumeCurtainState();
}

class _ResumeCurtainState extends State<_ResumeCurtain> {
  late bool _isDrawn = widget.isResuming;

  Future<void> _resume(PendingRequestsState state) async {
    await widget.onResume(state);
    if (mounted) setState(() => _isDrawn = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PendingRequestsCubit, PendingRequestsState>(
      listenWhen: (previous, current) =>
          _isDrawn && !previous.isLoaded && current.isLoaded,
      listener: (_, state) => unawaited(_resume(state)),
      child: _isDrawn
          ? Scaffold(
              key: InnkeeperPanelScreen.resumeCurtainKey,
              body: DecoratedBox(
                decoration: KlimmeckGuideTheme.getParchmentBackground(),
                child: const Center(child: KGLoader()),
              ),
            )
          : widget.child,
    );
  }
}
