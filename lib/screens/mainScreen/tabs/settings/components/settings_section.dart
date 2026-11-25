import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Sezione del foglio Impostazioni: una tendina chiusa col titolo Cinzel, che
/// si apre sul contenuto (UAT 25).
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
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(
        bottom: KlimmeckGuideTheme.spacingMd,
      ),
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: KlimmeckGuideTheme.deepNight,
      collapsedIconColor: KlimmeckGuideTheme.deepNight,
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      title: Text(title, style: KlimmeckGuideTheme.instance.titleMedium),
      children: children,
    );
  }
}
