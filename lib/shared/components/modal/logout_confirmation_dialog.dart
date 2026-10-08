import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Dialog di sistema (utility surface, niente texture di gioco) per confermare il logout.
class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    return AlertDialog(
      title: Text('Sei sicuro di voler uscire?', style: theme.titleMedium),
      content: Text(
        'La tua sessione verrà terminata.',
        style: theme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Annulla',
            style: theme.bodyMedium.copyWith(
              color: KlimmeckGuideTheme.deepNight,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: KlimmeckGuideTheme.bloodRed,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Esci',
            style: theme.bodyMedium.copyWith(
              color: KlimmeckGuideTheme.parchment,
            ),
          ),
        ),
      ],
    );
  }
}

Future<bool> showLogoutConfirmationDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LogoutConfirmationDialog(),
    ) ??
    false;

/// Entry point per Settings (Phase 4): chiede conferma ed esegue `AuthCubit.logout()`.
/// Il cubit viene letto prima dell'await, così `context` non è usato dopo il gap asincrono.
Future<void> confirmLogout(BuildContext context) async {
  final authCubit = context.read<AuthCubit>();
  if (await showLogoutConfirmationDialog(context)) await authCubit.logout();
}
