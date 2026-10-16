import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/character_deletion_messages.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/settings_section.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart';
import 'package:klimmeck_guide/shared/components/modal/delete_character_confirmation_dialog.dart';
import 'package:klimmeck_guide/shared/components/modal/logout_confirmation_dialog.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Sezione Account: eliminazione personaggio (con conferma) e, per ultimo, logout.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key, required this.characterName});

  final String? characterName;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CharacterDeletionCubit, CharacterDeletionState>(
      builder: (context, state) => SettingsSection(
        title: 'Account',
        children: [
          OutlinedButton(
            style: KlimmeckGuideTheme.destructiveOutlinedButtonStyle,
            onPressed: state.isDeleting
                ? null
                : () => _confirmDeletion(context),
            child: state.isDeleting
                ? const SizedBox.square(
                    dimension: KlimmeckGuideTheme.spacingMd,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KlimmeckGuideTheme.bloodRed,
                    ),
                  )
                : Text(
                    'Elimina personaggio',
                    style: KlimmeckGuideTheme.instance.bodyMedium.copyWith(
                      color: KlimmeckGuideTheme.bloodRed,
                    ),
                  ),
          ),
          if (state.failure case final failure?)
            Padding(
              padding: const EdgeInsets.only(top: KlimmeckGuideTheme.spacingXs),
              child: Text(
                failure.message,
                style: KlimmeckGuideTheme.instance.errorText,
              ),
            ),
          const SizedBox(height: KlimmeckGuideTheme.spacingLg),
          ElevatedButton(
            style: KlimmeckGuideTheme.destructiveButtonStyle,
            onPressed: () => confirmLogout(context),
            child: Text(
              'Esci',
              style: KlimmeckGuideTheme.instance.bodyMedium.copyWith(
                color: KlimmeckGuideTheme.parchment,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Il dialog vive sul Navigator radice: il Cubit si legge prima dell'await (D-19).
  Future<void> _confirmDeletion(BuildContext context) async {
    final cubit = context.read<CharacterDeletionCubit>();
    final confirmed = await showDeleteCharacterConfirmation(
      context,
      characterName: characterName,
    );
    if (confirmed) await cubit.deleteCharacter();
  }
}
