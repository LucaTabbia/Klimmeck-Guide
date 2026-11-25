import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/player_account_deletion_messages.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/playerAccountDeletionCubit/player_account_deletion_cubit.dart';
import 'package:klimmeck_guide/shared/components/modal/delete_player_account_confirmation_dialog.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Apre il dialog sul Navigator radice con uno stato pulito (tranne con una
/// cancellazione in volo, che [PlayerAccountDeletionCubit.reset] non tocca);
/// il chiamante legge il Cubit prima di qualunque await.
Future<void> showPlayerAccountDeletionDialog(
  BuildContext context,
  PlayerAccountDeletionCubit cubit,
) {
  cubit.reset();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const PlayerAccountDeletionDialog(),
    ),
  );
}

/// Nome utente Twitch del giocatore da eliminare (D-15, utility surface). Il
/// campo vive qui e non nel tab, che non si ridimensiona con la tastiera
/// (research C5). Il testo digitato non esce dal dialog: né log né memoria.
class PlayerAccountDeletionDialog extends StatefulWidget {
  const PlayerAccountDeletionDialog({super.key});

  static const String title = 'Elimina un account';
  static const Key fieldKey = Key('playerAccountDeletionField');

  @override
  State<PlayerAccountDeletionDialog> createState() =>
      _PlayerAccountDeletionDialogState();
}

class _PlayerAccountDeletionDialogState
    extends State<PlayerAccountDeletionDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlayerAccountDeletionCubit, PlayerAccountDeletionState>(
      listenWhen: (previous, current) =>
          !previous.hasDeleted && current.hasDeleted,
      listener: (context, _) => Navigator.of(context).pop(),
      builder: (context, state) =>
          PopScope(canPop: !state.isDeleting, child: _buildDialog(state)),
    );
  }

  /// Finché la cancellazione è in volo né «Annulla» né il tasto indietro
  /// chiudono il dialog: è l'unico a leggerne l'esito.
  Widget _buildDialog(PlayerAccountDeletionState state) {
    final theme = KlimmeckGuideTheme.instance;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: KlimmeckGuideTheme.spacingXl,
        vertical: KlimmeckGuideTheme.spacingSm,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        KlimmeckGuideTheme.spacingLg,
        KlimmeckGuideTheme.spacingMd,
        KlimmeckGuideTheme.spacingLg,
        0,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        KlimmeckGuideTheme.spacingLg,
        0,
        KlimmeckGuideTheme.spacingLg,
        KlimmeckGuideTheme.spacingSm,
      ),
      content: _scrollKeepingTheFieldInSight(
        children: [
          Text(PlayerAccountDeletionDialog.title, style: theme.titleMedium),
          const SizedBox(height: KlimmeckGuideTheme.spacingMd),
          TextField(
            key: PlayerAccountDeletionDialog.fieldKey,
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Nome utente Twitch'),
          ),
          if (state.failure case final failure?)
            Padding(
              padding: const EdgeInsets.only(top: KlimmeckGuideTheme.spacingXs),
              child: Text(failure.message, style: theme.errorText),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: state.isDeleting
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(
            'Annulla',
            style: theme.bodyMedium.copyWith(
              color: KlimmeckGuideTheme.deepNight,
            ),
          ),
        ),
        _NextButton(
          controller: _controller,
          isDeleting: state.isDeleting,
          onPressed: _confirmAndDelete,
        ),
      ],
    );
  }

  /// Ancorato in basso: con la tastiera aperta in landscape a scorrere via è
  /// il titolo, mai il campo (research C5).
  Widget _scrollKeepingTheFieldInSight({required List<Widget> children}) =>
      SingleChildScrollView(
        reverse: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );

  /// Il Cubit si legge prima dell'await: la conferma vive sul Navigator radice.
  Future<void> _confirmAndDelete() async {
    final cubit = context.read<PlayerAccountDeletionCubit>();
    final twitchLogin = _controller.text.trim();
    final confirmed = await showDeletePlayerAccountConfirmation(
      context,
      twitchLogin: twitchLogin,
    );
    if (confirmed && !cubit.isClosed) await cubit.deletePlayer(twitchLogin);
  }
}

/// «Avanti»: spento finché il nome è vuoto o la cancellazione è in volo; lo
/// spinner al posto dell'etichetta è l'unico caricamento (regola 2).
class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.controller,
    required this.isDeleting,
    required this.onPressed,
  });

  final TextEditingController controller;
  final bool isDeleting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final isBlank = value.text.trim().isEmpty;
          return ElevatedButton(
            style: KlimmeckGuideTheme.primaryButtonStyle,
            onPressed: isBlank || isDeleting ? null : onPressed,
            child: isDeleting
                ? const SizedBox.square(
                    dimension: KlimmeckGuideTheme.spacingMd,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KlimmeckGuideTheme.parchment,
                    ),
                  )
                : Text(
                    'Avanti',
                    style: KlimmeckGuideTheme.instance.bodyMedium.copyWith(
                      color: KlimmeckGuideTheme.parchment,
                    ),
                  ),
          );
        },
      );
}
