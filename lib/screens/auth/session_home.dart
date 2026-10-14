import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/user.dart';

/// Ingresso della sessione autenticata (D-01): senza personaggio la scheda di
/// creazione, altrimenti la shell di gioco con l'id del personaggio (D-27).
///
/// La chiave sull'id fa ricreare shell e cubit a ogni cambio di personaggio:
/// lo stream `characterUpdated` precedente viene cancellato prima che si apra
/// il nuovo (Phase 3 D-08). `null -> id` e `id -> null` cambiano gia' il tipo
/// di widget.
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
    return KeyedSubtree(
      key: ValueKey<String>('character:${character.id}'),
      child: shellBuilder(context, character.id),
    );
  }
}
