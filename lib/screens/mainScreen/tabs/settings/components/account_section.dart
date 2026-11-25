import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_access.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/accountDeletionCubit/account_deletion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/account_deletion_messages.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/character_deletion_messages.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/settings_section.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart';
import 'package:klimmeck_guide/shared/components/modal/delete_account_confirmation_dialog.dart';
import 'package:klimmeck_guide/shared/components/modal/delete_character_confirmation_dialog.dart';
import 'package:klimmeck_guide/shared/components/modal/logout_confirmation_dialog.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Fondo del foglio Impostazioni: la tendina delle azioni irreversibili
/// (eliminazione del personaggio e, sotto, dell'account) e per ultimo «Esci»,
/// sempre in vista (UAT 25, che emenda D-02). «Elimina account» è nascosto
/// all'oste (D-16, solo UX: decide il BE).
///
/// Mentre l'account si elimina gli altri due bottoni sono spenti: un logout
/// partito in quel momento vincerebbe sulla chiusura della sessione
/// dell'eliminazione e l'arrivo al login perderebbe il suo avviso (D-06).
/// Allo stesso modo, da «Esci» alla fine del logout nessun bottone della
/// sezione risponde: nessuna eliminazione può correre contro il logout.
class AccountSection extends StatefulWidget {
  const AccountSection({super.key, required this.characterName});

  final String? characterName;

  static const String irreversibleTitle = 'Azioni irreversibili';

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<AccountSection> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final isDeletingAccount = context.select<AccountDeletionCubit, bool>(
      (cubit) => cubit.state.isDeleting,
    );
    final isLocked = isDeletingAccount || _isLoggingOut;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<CharacterDeletionCubit, CharacterDeletionState>(
          builder: (context, state) => SettingsSection(
            title: AccountSection.irreversibleTitle,
            children: [
              _DestructiveOutlinedButton(
                label: 'Elimina personaggio',
                isBusy: state.isDeleting,
                onPressed: isLocked ? null : () => _confirmDeletion(context),
              ),
              if (state.failure case final failure?)
                _FailureLine(message: failure.message),
              _AccountDeletionEntry(isLoggingOut: _isLoggingOut),
            ],
          ),
        ),
        const SizedBox(height: KlimmeckGuideTheme.spacingLg),
        ElevatedButton(
          style: KlimmeckGuideTheme.destructiveButtonStyle,
          onPressed: isLocked ? null : _logOut,
          child: Text(
            'Esci',
            style: KlimmeckGuideTheme.instance.bodyMedium.copyWith(
              color: KlimmeckGuideTheme.parchment,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _logOut() async {
    setState(() => _isLoggingOut = true);
    await confirmLogout(context);
    if (mounted) setState(() => _isLoggingOut = false);
  }

  /// Il dialog vive sul Navigator radice: il Cubit si legge prima dell'await (D-19).
  Future<void> _confirmDeletion(BuildContext context) async {
    final cubit = context.read<CharacterDeletionCubit>();
    final confirmed = await showDeleteCharacterConfirmation(
      context,
      characterName: widget.characterName,
    );
    if (confirmed && !cubit.isClosed) await cubit.deleteCharacter();
  }
}

/// «Elimina account» sotto «Elimina personaggio», nella stessa tendina;
/// assente per l'oste (D-16).
class _AccountDeletionEntry extends StatelessWidget {
  const _AccountDeletionEntry({required this.isLoggingOut});

  final bool isLoggingOut;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<AuthCubit, AuthState, bool>(
        selector: isInnkeeperSession,
        builder: (context, isInnkeeper) =>
            isInnkeeper ? const SizedBox.shrink() : _buildEntry(),
      );

  Widget _buildEntry() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: KlimmeckGuideTheme.spacingMd),
      BlocBuilder<AccountDeletionCubit, AccountDeletionState>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DestructiveOutlinedButton(
              label: 'Elimina account',
              isBusy: state.isDeleting,
              onPressed: isLoggingOut
                  ? null
                  : () => _confirmAccountDeletion(context),
            ),
            if (state.failure case final failure?)
              _FailureLine(message: failure.message),
          ],
        ),
      ),
    ],
  );

  /// Il dialog vive sul Navigator radice: il Cubit si legge prima dell'await.
  Future<void> _confirmAccountDeletion(BuildContext context) async {
    final cubit = context.read<AccountDeletionCubit>();
    final confirmed = await showDeleteAccountConfirmation(context);
    if (confirmed && !cubit.isClosed) await cubit.deleteAccount();
  }
}

/// Bottone rosso a contorno con lo spinner al posto dell'etichetta finché
/// l'azione è in corso (l'unico caricamento ammesso, sul bottone toccato).
class _DestructiveOutlinedButton extends StatelessWidget {
  const _DestructiveOutlinedButton({
    required this.label,
    required this.isBusy,
    required this.onPressed,
  });

  final String label;
  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: KlimmeckGuideTheme.destructiveOutlinedButtonStyle,
    onPressed: isBusy ? null : onPressed,
    child: isBusy
        ? const SizedBox.square(
            dimension: KlimmeckGuideTheme.spacingMd,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: KlimmeckGuideTheme.bloodRed,
            ),
          )
        : Text(
            label,
            style: KlimmeckGuideTheme.instance.bodyMedium.copyWith(
              color: KlimmeckGuideTheme.bloodRed,
            ),
          ),
  );
}

class _FailureLine extends StatelessWidget {
  const _FailureLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: KlimmeckGuideTheme.spacingXs),
    child: Text(message, style: KlimmeckGuideTheme.instance.errorText),
  );
}
