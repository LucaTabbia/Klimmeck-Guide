import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Città che il personaggio non conosce ancora (D-11): il BE non manda la sua
/// lore; solo il nome e una riga, niente immagine né descrizione.
class UnknownCityModal extends StatelessWidget {
  const UnknownCityModal({super.key, required this.cityName});

  static const String line = 'Non conosci ancora questa città.';

  final String cityName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height / 7),
        AutoSizeText(
          cityName,
          maxFontSize: 24,
          minFontSize: 16,
          textAlign: TextAlign.center,
          style: KlimmeckGuideTheme.instance.specialText.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 20),
        Text(
          line,
          textAlign: TextAlign.center,
          style: KlimmeckGuideTheme.instance.bodyMedium.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}
