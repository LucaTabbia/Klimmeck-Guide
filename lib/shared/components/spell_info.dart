import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spell_recovery_status.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/spell_lines.dart';

/// Dettaglio di una magia nel foglio del long-press (D-09): presentazione pura,
/// ogni riga compare solo se il catalogo ne fornisce il dato.
class SpellInfo extends StatelessWidget {
  const SpellInfo({
    super.key,
    required this.spell,
    required this.usages,
    required this.recovery,
  });

  static const double _iconSize = 50;

  final Spell spell;
  final int? usages;
  final SpellRecoveryStatus recovery;

  @override
  Widget build(BuildContext context) {
    final energyType = spell.energyDamage?.type;
    final name = spell.name;
    final useType = spell.useType;
    final useTypeLabel = spellUseTypeLabel(useType);
    final description = spell.description;
    final currentLine = _currentLine();
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (energyType != null || name != null)
          _iconRow(
            iconUrl: energyType?.imagePath,
            child: name == null ? null : _title(name),
          ),
        if (useTypeLabel != null)
          _iconRow(iconUrl: useType?.imagePath, child: _line(useTypeLabel)),
        if (description != null) _line(description),
        ..._detailLines().map(_line),
        if (currentLine.isNotEmpty) _line(currentLine),
      ],
    );
  }

  List<String> _detailLines() => [
    spellDamageLabel(spell.energyDamage),
    spellMaxUsagesLabel(spell.maxUsages),
    spellRecoveryTimeLabel(spell),
    spellLearnLabel(spell),
  ].whereType<String>().toList();

  String _currentLine() => [
    spellUsagesLabel(usages: usages, maxUsages: spell.maxUsages),
    spellRecoveryLabel(recovery),
  ].whereType<String>().join(spellLineSeparator);

  Widget _iconRow({required String? iconUrl, required Widget? child}) {
    return SizedBox(
      height: _iconSize,
      child: Row(
        children: [
          if (iconUrl != null)
            SizedBox(
              height: _iconSize,
              width: _iconSize,
              child: CachedSvg(url: iconUrl),
            ),
          if (child != null)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: child,
              ),
            ),
        ],
      ),
    );
  }

  Widget _title(String name) => AutoSizeText(
    minFontSize: 10,
    maxFontSize: 20,
    name,
    style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
      fontWeight: FontWeight.w800,
    ),
  );

  Widget _line(String text) => Padding(
    padding: const EdgeInsets.only(top: 4.0),
    child: Text(text, style: KlimmeckGuideTheme.instance.bodyMedium),
  );
}
