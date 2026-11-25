import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_access.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_route.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/player_account_deletion_dialog.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/settings_section.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/playerDeletionCubit/player_account_deletion_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Sezione «Locanda» (10-CONTEXT D-01, ADMIN-01): solo per il GM, viva col
/// ruolo della sessione (`userUpdated`). Solo UX: il BE resta il controllo (ADMIN-07).
/// Sotto «Apri la Locanda», l'eliminazione dell'account di un giocatore dal
/// nome utente Twitch (D-15).
class InnkeeperSection extends StatelessWidget {
  const InnkeeperSection({super.key});

  static const String title = 'Locanda';
  static const String openLabel = 'Apri la Locanda';

  @override
  Widget build(BuildContext context) =>
      BlocSelector<AuthCubit, AuthState, bool>(
        selector: isInnkeeperSession,
        builder: (context, isInnkeeper) =>
            isInnkeeper ? _buildSection(context) : const SizedBox.shrink(),
      );

  Widget _buildSection(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: KlimmeckGuideTheme.spacingXl),
    child: SettingsSection(
      title: title,
      children: [
        ElevatedButton(
          style: KlimmeckGuideTheme.primaryButtonStyle,
          onPressed: () => openInnkeeperPanel(context),
          child: Text(
            openLabel,
            style: KlimmeckGuideTheme.instance.bodyMedium.copyWith(
              color: KlimmeckGuideTheme.parchment,
            ),
          ),
        ),
        const _PlayerAccountDeletionEntry(),
      ],
    ),
  );
}

/// «Elimina un account» (contorno rosso) e, dopo un successo, la riga d'esito
/// senza il nome digitato: nulla del testo sopravvive al dialog.
class _PlayerAccountDeletionEntry extends StatelessWidget {
  const _PlayerAccountDeletionEntry();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: KlimmeckGuideTheme.spacingMd),
      OutlinedButton(
        style: KlimmeckGuideTheme.destructiveOutlinedButtonStyle,
        onPressed: () => showPlayerAccountDeletionDialog(
          context,
          context.read<PlayerAccountDeletionCubit>(),
        ),
        child: Text(
          PlayerAccountDeletionDialog.title,
          style: KlimmeckGuideTheme.instance.bodyMedium.copyWith(
            color: KlimmeckGuideTheme.bloodRed,
          ),
        ),
      ),
      BlocSelector<
        PlayerAccountDeletionCubit,
        PlayerAccountDeletionState,
        bool
      >(
        selector: (state) => state.hasDeleted,
        builder: (context, hasDeleted) => hasDeleted
            ? Padding(
                padding: const EdgeInsets.only(
                  top: KlimmeckGuideTheme.spacingXs,
                ),
                child: Text(
                  'Account eliminato.',
                  style: KlimmeckGuideTheme.instance.bodyMedium,
                ),
              )
            : const SizedBox.shrink(),
      ),
    ],
  );
}
