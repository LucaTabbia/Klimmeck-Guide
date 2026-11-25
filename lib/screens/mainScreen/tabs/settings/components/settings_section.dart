import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';

/// Sezione del foglio Impostazioni: la tendina dell'app, chiusa, col titolo
/// della sezione e il contenuto dentro (UAT 25).
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
    return Dropdown(
      sectionName: title,
      data: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
