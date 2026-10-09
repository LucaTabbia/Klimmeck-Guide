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
  static const double _reservedHeight = 250;
  static const double _minPortraitHeight = 80;
  static const double _maxPortraitHeight = 240;

  final String? portraitPath;
  final PortraitPickFailure? pickFailure;
  final bool enabled;
  final ValueChanged<PortraitSource> onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingMd),
      child: _content(_portraitHeightFor(constraints.maxHeight)),
    ),
  );

  /// L'anteprima prende lo spazio che resta; con la tastiera aperta la colonna
  /// scorre invece di andare in overflow.
  double _portraitHeightFor(double availableHeight) =>
      (availableHeight - _reservedHeight).clamp(
        _minPortraitHeight,
        _maxPortraitHeight,
      );

  Widget _content(double portraitHeight) {
    final theme = KlimmeckGuideTheme.instance;
    final failure = pickFailure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ritratto', style: theme.titleMedium),
        const SizedBox(height: KlimmeckGuideTheme.spacingSm),
        SizedBox(
          height: portraitHeight,
          child: Center(
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
        if (failure != null) Text(failure.message, style: theme.errorText),
      ],
    );
  }

  /// Niente `VisualDensity.compact`: toglierebbe 8 px al minimo e porterebbe
  /// il bottone sotto i 44 px (ui-ux.md). `padded` tiene l'area di tocco a
  /// 48 px anche quando l'aspetto resta compatto.
  Widget _action(IconData icon, String label, VoidCallback onPressed) =>
      TextButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        label: Text(label),
        style: TextButton.styleFrom(
          minimumSize: const Size(_minTapTarget, _minTapTarget),
          tapTargetSize: MaterialTapTargetSize.padded,
          foregroundColor: KlimmeckGuideTheme.deepNight,
        ),
      );
}
