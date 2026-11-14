import 'package:flutter/material.dart';

/// «Indietro» del wizard: lo offre la schermata, lo dispone ogni pagina nella
/// propria riga di pulsanti in fondo (UAT 2026-11-14).
class MissionBackScope extends InheritedWidget {
  const MissionBackScope({
    super.key,
    required this.onBack,
    required super.child,
  });

  /// `null` = «Indietro» spento (prima pagina o chiamata in corso).
  final VoidCallback? onBack;

  @override
  bool updateShouldNotify(MissionBackScope oldWidget) =>
      (onBack == null) != (oldWidget.onBack == null);
}

/// Fuori dal wizard (una pagina da sola) non mostra nulla.
class MissionBackButton extends StatelessWidget {
  const MissionBackButton({super.key});

  static const String label = 'Indietro';
  static const Key buttonKey = ValueKey('mission.back');

  @override
  Widget build(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<MissionBackScope>();
    if (scope == null) return const SizedBox.shrink();
    return OutlinedButton(
      key: buttonKey,
      onPressed: scope.onBack,
      child: const Text(label),
    );
  }
}
