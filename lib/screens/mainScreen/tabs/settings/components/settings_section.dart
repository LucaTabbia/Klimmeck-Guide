import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Sezione del foglio Impostazioni: titolo Cinzel e contenuto.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: KlimmeckGuideTheme.instance.titleMedium),
        const SizedBox(height: KlimmeckGuideTheme.spacingSm),
        ...children,
      ],
    );
  }
}
