import 'package:flutter/material.dart';
import 'package:klimmeck_guide/repository/services/image/portrait_picker.dart';
import 'package:klimmeck_guide/screens/characterCreation/components/character_creation_messages.dart';
import 'package:klimmeck_guide/shared/components/character_portrait.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Anteprima del ritratto con le azioni galleria / fotocamera / rimuovi.
class PortraitColumn extends StatelessWidget {
  const PortraitColumn({
    super.key,
    required this.portraitPath,
    required this.pickFailure,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  static const double _portraitAspectRatio = 3 / 4;
  static const double _minTapTarget = 44;

  final String? portraitPath;
  final PortraitPickFailure? pickFailure;
  final bool enabled;
  final ValueChanged<PortraitSource> onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    final failure = pickFailure;
    return Padding(
      padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ritratto', style: theme.titleMedium),
          const SizedBox(height: KlimmeckGuideTheme.spacingSm),
          Flexible(
            child: AspectRatio(
              aspectRatio: _portraitAspectRatio,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: KlimmeckGuideTheme.darkBronze),
                  borderRadius: BorderRadius.circular(
                    KlimmeckGuideTheme.spacingSm,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    KlimmeckGuideTheme.spacingSm,
                  ),
                  child: CharacterPortrait(localFilePath: portraitPath),
                ),
              ),
            ),
          ),
          const SizedBox(height: KlimmeckGuideTheme.spacingSm),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              _action(
                Icons.photo_library_outlined,
                'Galleria',
                () => onPick(PortraitSource.gallery),
              ),
              _action(
                Icons.photo_camera_outlined,
                'Fotocamera',
                () => onPick(PortraitSource.camera),
              ),
              if (portraitPath != null)
                _action(Icons.delete_outline, 'Rimuovi', onRemove),
            ],
          ),
          if (failure != null)
            Flexible(
              child: SingleChildScrollView(
                child: Text(failure.message, style: theme.errorText),
              ),
            ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onPressed) =>
      TextButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        label: Text(label),
        style: TextButton.styleFrom(
          minimumSize: const Size(_minTapTarget, _minTapTarget),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          foregroundColor: KlimmeckGuideTheme.deepNight,
        ),
      );
}
