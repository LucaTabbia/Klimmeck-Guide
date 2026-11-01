import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/completion_recap.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/participant_override_section.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/requestCompletionCubit/request_completion_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/request_completion_route.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Form di completamento del GM (10-CONTEXT D-11..D-14): utility screen, il
/// loader solo fino alla lettura dei partecipanti (apertura esplicita). Esce
/// con un [CompletionExit] che il pannello traduce.
/// Richiede [RequestCompletionCubit] e [PendingRequestsCubit] sopra di sé.
class RequestCompletionScreen extends StatelessWidget {
  const RequestCompletionScreen({super.key, required this.card});

  static const String title = 'Completa la richiesta';
  static const String confirmLabel = 'Conferma';
  static const String loadFailedMessage =
      'Non è stato possibile leggere i partecipanti';
  static const String retryLabel = 'Riprova';

  final RequestCard card;

  /// Durante l'invio l'uscita è bloccata: la risposta deve arrivare al
  /// pannello (WR-03).
  @override
  Widget build(BuildContext context) {
    return BlocSelector<RequestCompletionCubit, RequestCompletionState, bool>(
      selector: (state) =>
          state is RequestCompletionEditing && state.isSubmitting,
      builder: (context, isSubmitting) =>
          PopScope(canPop: !isSubmitting, child: _buildScaffold()),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: AppBar(title: const Text(title)),
      body: DecoratedBox(
        decoration: KlimmeckGuideTheme.getParchmentBackground(),
        child: SafeArea(
          child: BlocConsumer<RequestCompletionCubit, RequestCompletionState>(
            listenWhen: _isExitOrNewFailure,
            listener: _onOutcome,
            builder: _buildBody,
          ),
        ),
      ),
    );
  }

  static bool _isExitOrNewFailure(
    RequestCompletionState previous,
    RequestCompletionState current,
  ) => switch (current) {
    RequestCompletionEditing(:final failureSerial) =>
      previous is! RequestCompletionEditing ||
          previous.failureSerial != failureSerial,
    _ => true,
  };

  void _onOutcome(BuildContext context, RequestCompletionState state) {
    switch (state) {
      case RequestCompletionSucceeded(:final results):
        Navigator.of(context).pop(CompletionCompleted(results));
      case RequestCompletionLoadFailed(:final failure):
        _exitOn(context, failure);
      case RequestCompletionEditing(failure: InnkeeperFailure.notParticipant):
        context.read<PendingRequestsCubit>().refetch();
      case RequestCompletionEditing(:final failure?):
        _exitOn(context, failure);
      case RequestCompletionEditing() || RequestCompletionLoading():
        return;
    }
  }

  /// D-14: FORBIDDEN chiude il pannello, NOT_FOUND toglie la carta,
  /// QUEST_IN_PROGRESS rilegge la coda; gli altri codici restano nel form.
  void _exitOn(BuildContext context, InnkeeperFailure failure) {
    final exit = switch (failure) {
      InnkeeperFailure.forbidden => const CompletionForbidden(),
      InnkeeperFailure.notFound => const CompletionGone(),
      InnkeeperFailure.questInProgress => const CompletionBusy(),
      _ => null,
    };
    if (exit != null) Navigator.of(context).pop(exit);
  }

  Widget _buildBody(BuildContext context, RequestCompletionState state) {
    return switch (state) {
      RequestCompletionEditing() => _CompletionForm(card: card, editing: state),
      RequestCompletionLoadFailed() => const _LoadFailed(),
      RequestCompletionLoading() ||
      RequestCompletionSucceeded() => const Center(child: KGLoader()),
    };
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed();

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            RequestCompletionScreen.loadFailedMessage,
            style: theme.bodyMedium,
          ),
          const SizedBox(height: KlimmeckGuideTheme.spacingSm),
          ElevatedButton(
            style: KlimmeckGuideTheme.primaryButtonStyle,
            onPressed: () => context.read<RequestCompletionCubit>().load(),
            child: const Text(RequestCompletionScreen.retryLabel),
          ),
        ],
      ),
    );
  }
}

class _CompletionForm extends StatelessWidget {
  const _CompletionForm({required this.card, required this.editing});

  final RequestCard card;
  final RequestCompletionEditing editing;

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    final cubit = context.read<RequestCompletionCubit>();
    final error = _formErrorOf(editing.failure);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(card.questTitle, style: theme.titleMedium),
                for (final draft in editing.drafts) ...[
                  const SizedBox(height: KlimmeckGuideTheme.spacingLg),
                  ParticipantOverrideSection(
                    draft: draft,
                    onHpChanged: (hp) => cubit.setHp(draft.characterId, hp),
                    onInjuryToggled: (injury) =>
                        cubit.toggleInjury(draft.characterId, injury),
                    onConsumableChanged: (itemId, quantity) => cubit
                        .setConsumableUsed(draft.characterId, itemId, quantity),
                    onSpellChanged: (spellId, usages) =>
                        cubit.setSpellUsed(draft.characterId, spellId, usages),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                Text(error, style: theme.errorText),
                const SizedBox(height: KlimmeckGuideTheme.spacingSm),
              ],
              ElevatedButton(
                style: KlimmeckGuideTheme.primaryButtonStyle,
                onPressed: editing.isSubmitting
                    ? null
                    : () => _confirm(context),
                child: const Text(RequestCompletionScreen.confirmLabel),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Conferma esplicita col riepilogo (D-11, T-10-26): la chiusura è irreversibile.
  Future<void> _confirm(BuildContext context) async {
    final cubit = context.read<RequestCompletionCubit>();
    final confirmed = await showDestructiveConfirmation(
      context,
      title: RequestCompletionScreen.title,
      body: confirmationRecapOf(card: card, drafts: editing.drafts),
      confirmLabel: RequestCompletionScreen.confirmLabel,
      confirmButtonStyle: KlimmeckGuideTheme.primaryButtonStyle,
    );
    if (confirmed && !cubit.isClosed) await cubit.submit();
  }

  /// Errori che lasciano il form aperto (D-14/C2); gli altri escono dalla route.
  static String? _formErrorOf(InnkeeperFailure? failure) => switch (failure) {
    null ||
    InnkeeperFailure.notFound ||
    InnkeeperFailure.questInProgress ||
    InnkeeperFailure.forbidden => null,
    InnkeeperFailure.overrideInvalid =>
      'Valori non accettati: controlla il modulo',
    InnkeeperFailure.notParticipant =>
      'Un partecipante non fa più parte della richiesta',
    _ => 'Non è stato possibile completare la richiesta. Riprova.',
  };
}
