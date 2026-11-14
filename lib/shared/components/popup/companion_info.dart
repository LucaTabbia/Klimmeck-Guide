import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/companion/companion_display_name.dart';
import 'package:klimmeck_guide/models/companion/companion_vitality.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/companion_lines.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

/// Dettaglio del compagno nel foglio del tocco prolungato (D-22): ogni riga
/// compare solo se il dato è servito; la vita arriva già calcolata dalla
/// vitalità (massimo del compagno, D-38). Visual provvisorio.
class CompanionInfo extends StatelessWidget {
  const CompanionInfo({
    super.key,
    required this.pet,
    this.name,
    this.level,
    this.xp,
    this.vitality,
    this.potionWait,
    this.onRename,
  });

  static const Key levelKey = ValueKey('companion.info.level');
  static const Key titleKey = ValueKey('companion.info.title');
  static const Key speciesKey = ValueKey('companion.info.species');
  static const Key lifeKey = ValueKey('companion.info.life');
  static const Key statusKey = ValueKey('companion.info.status');
  static const Key potionWaitKey = ValueKey('companion.info.potionWait');
  static const Key recoveryTimeKey = ValueKey('companion.info.recoveryTime');
  static const Key attackKey = ValueKey('companion.info.attack');
  static const Key defenseKey = ValueKey('companion.info.defense');
  static const Key xpKey = ValueKey('companion.info.xp');
  static const Key renameKey = ValueKey('companion.info.rename');

  static const double _minTapTarget = 44;

  final Pet pet;
  final String? name;
  final int? level;
  final int? xp;
  final CompanionVitality? vitality;
  final Duration? potionWait;
  final VoidCallback? onRename;

  bool get _hasName => name?.trim().isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    final rename = onRename;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(),
        ..._rows().entries.map((row) => _line(row.key, row.value)),
        if (rename != null) _renameAction(rename),
      ],
    );
  }

  Map<Key, String> _rows() {
    final currentVitality = vitality;
    final wait = potionWait;
    final currentXp = xp;
    final rows = <Key, String?>{
      if (_hasName) speciesKey: pet.name,
      levelKey: companionLevelLine(level),
      if (currentVitality != null) ...{
        lifeKey: companionLifeLine(
          currentVitality.life,
          currentVitality.maxLifePoints,
        ),
        statusKey: companionStatusLine(currentVitality),
      },
      if (wait != null) potionWaitKey: companionPotionWaitLine(wait),
      recoveryTimeKey: companionRecoveryTimeLine(pet.recoveryDuration),
      attackKey: petAttackLine(pet),
      defenseKey: petDefenseLine(pet),
      if (currentXp != null) xpKey: companionXpLine(currentXp, pet.maxXp),
    };
    return {
      for (final MapEntry(:key, :value) in rows.entries)
        if (value != null && value.isNotEmpty) key: value,
    };
  }

  Widget _title() => Text(
    companionDisplayName(name: name, pet: pet),
    key: titleKey,
    style: KlimmeckGuideTheme.instance.titleMedium.copyWith(
      color: pet.rarity?.color,
    ),
  );

  Widget _line(Key key, String text) => Padding(
    padding: const EdgeInsets.only(top: 4.0),
    child: Text(text, key: key, style: KlimmeckGuideTheme.instance.bodyMedium),
  );

  Widget _renameAction(VoidCallback onTap) {
    final label = renameCompanionLabel(hasName: _hasName);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minTapTarget),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Text(
              label,
              key: renameKey,
              style: KlimmeckGuideTheme.instance.bodyMedium.copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
