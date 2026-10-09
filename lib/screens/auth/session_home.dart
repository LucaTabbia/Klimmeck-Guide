import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/user.dart';

/// Ingresso della sessione autenticata (D-01): senza personaggio la scheda di
/// creazione, altrimenti la shell di gioco con l'id del personaggio (D-27).
class SessionHome extends StatelessWidget {
  const SessionHome({
    super.key,
    required this.user,
    required this.creationBuilder,
    required this.shellBuilder,
  });

  final User user;
  final WidgetBuilder creationBuilder;
  final Widget Function(BuildContext context, String characterId) shellBuilder;

  @override
  Widget build(BuildContext context) {
    final character = user.currentCharacter;
    if (character == null) return creationBuilder(context);
    return shellBuilder(context, character.id);
  }
}
