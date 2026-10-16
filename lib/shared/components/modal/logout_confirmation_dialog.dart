import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';

const _logoutTitle = 'Sei sicuro di voler uscire?';
const _logoutBody = 'La tua sessione verrà terminata.';
const _logoutConfirmLabel = 'Esci';

/// Dialog di sistema (utility surface, niente texture di gioco) per confermare il logout.
class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) => const DestructiveConfirmationDialog(
    title: _logoutTitle,
    body: _logoutBody,
    confirmLabel: _logoutConfirmLabel,
  );
}

Future<bool> showLogoutConfirmationDialog(BuildContext context) =>
    showDestructiveConfirmation(
      context,
      title: _logoutTitle,
      body: _logoutBody,
      confirmLabel: _logoutConfirmLabel,
    );

/// Entry point del tab Impostazioni (SET-03): chiede conferma ed esegue `AuthCubit.logout()`.
/// Il cubit viene letto prima dell'await, così `context` non è usato dopo il gap asincrono.
Future<void> confirmLogout(BuildContext context) async {
  final authCubit = context.read<AuthCubit>();
  if (await showLogoutConfirmationDialog(context)) await authCubit.logout();
}
