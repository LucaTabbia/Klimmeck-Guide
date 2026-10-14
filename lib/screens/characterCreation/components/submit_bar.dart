import 'package:flutter/material.dart';
import 'package:klimmeck_guide/repository/character_creation_failure.dart';
import 'package:klimmeck_guide/screens/characterCreation/components/character_creation_messages.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Bottone "Crea" con progresso interno (D-05) e avviso d'errore del submit.
class SubmitBar extends StatelessWidget {
  const SubmitBar({
    super.key,
    required this.canSubmit,
    required this.isSubmitting,
    required this.failure,
    required this.onSubmit,
  });

  static const double _progressSize = 20;
  static const Size _buttonSize = Size(120, 44);

  final bool canSubmit;
  final bool isSubmitting;
  final CharacterCreationFailure? failure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    final currentFailure = failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (currentFailure != null) ...[
          Text(
            currentFailure.message,
            style: theme.errorText,
            textAlign: TextAlign.end,
          ),
          const SizedBox(height: KlimmeckGuideTheme.spacingSm),
        ],
        ElevatedButton(
          onPressed: canSubmit && !isSubmitting ? onSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: KlimmeckGuideTheme.darkBronze,
            foregroundColor: KlimmeckGuideTheme.parchment,
            minimumSize: _buttonSize,
          ),
          child: isSubmitting
              ? Semantics(
                  label: 'Creazione del personaggio in corso',
                  child: const SizedBox.square(
                    dimension: _progressSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KlimmeckGuideTheme.parchment,
                    ),
                  ),
                )
              : Text(
                  'Crea',
                  style: theme.titleMedium.copyWith(
                    color: KlimmeckGuideTheme.parchment,
                  ),
                ),
        ),
      ],
    );
  }
}
