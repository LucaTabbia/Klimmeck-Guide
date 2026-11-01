import 'package:flutter/material.dart';

import '../../../../../repository/innkeeper_failure.dart';
import '../../../../../theme/kg_theme.dart';

/// Copy provvisoria (10-CONTEXT D-17, D-22): solo testo per codice, mai il
/// messaggio del server.
String? teleportFailureTextOf(InnkeeperFailure? failure) => switch (failure) {
  null => null,
  InnkeeperFailure.questInProgress =>
    'Il personaggio è in una missione in corso',
  InnkeeperFailure.notFound => 'Personaggio o luogo non trovato',
  _ => 'Teletrasporto non riuscito, riprova',
};

/// Unico controllo sulla Mappa in teletrasporto (gameplay: niente chrome, 10-CONTEXT D-16/D-17).
class TeleportModeChip extends StatelessWidget {
  const TeleportModeChip({
    super.key,
    required this.characterName,
    required this.failure,
    required this.isTeleporting,
    required this.onCancel,
  });

  static const Key cancelKey = ValueKey('map.teleportCancel');
  static const String cancelLabel = 'Annulla';
  static const double _minTapTarget = 44;

  final String characterName;
  final InnkeeperFailure? failure;
  final bool isTeleporting;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: KlimmeckGuideTheme.darkWood);
    final failureText = teleportFailureTextOf(failure);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KlimmeckGuideTheme.parchment,
        borderRadius: BorderRadius.circular(KlimmeckGuideTheme.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KlimmeckGuideTheme.spacingMd,
          vertical: KlimmeckGuideTheme.spacingXs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_instruction, style: labelStyle),
            if (failureText != null)
              Text(failureText, style: KlimmeckGuideTheme.instance.errorText),
            _buildCancel(labelStyle),
          ],
        ),
      ),
    );
  }

  String get _instruction => isTeleporting
      ? 'Teletrasporto in corso…'
      : 'Trascina $characterName su una città';

  Widget _buildCancel(TextStyle? labelStyle) {
    return Semantics(
      button: true,
      enabled: !isTeleporting,
      label: 'Annulla teletrasporto',
      child: GestureDetector(
        key: cancelKey,
        behavior: HitTestBehavior.opaque,
        onTap: isTeleporting ? null : onCancel,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _minTapTarget,
            minHeight: _minTapTarget,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(cancelLabel, style: labelStyle),
          ),
        ),
      ),
    );
  }
}
