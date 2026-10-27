import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spell_recovery_status.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';
import 'package:klimmeck_guide/shared/components/spell_info.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Foglio di dettaglio della magia (D-09), costruito come `EquipmentInfoSheet`:
/// pergamena, carta, dettagli; il segnalibro rosso è l'interruttore equip/disequip.
class SpellInfoSheet extends StatelessWidget {
  const SpellInfoSheet({
    super.key,
    required this.spell,
    required this.usages,
    required this.recovery,
    required this.isActive,
    required this.isPending,
    this.onToggle,
  });

  final Spell spell;
  final int? usages;
  final SpellRecoveryStatus recovery;
  final bool isActive;
  final bool isPending;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final svgWidth = screenHeight * 1.3 * (315 / 375);
    final svgHeight = screenHeight * 1.3;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        CachedSvg(
          url: CloudinaryAssets.url(CloudinaryAssets.emptySheet),
          height: svgHeight,
          width: svgWidth,
        ),
        SizedBox(
          width: svgWidth,
          height: svgHeight,
          child: Padding(
            padding: EdgeInsets.only(
              top: svgHeight / 6,
              left: svgWidth / 9,
              right: svgWidth / 9,
              bottom: svgHeight / 8,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  SpellCard(spell: spell, size: constraints.maxWidth / 2),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SpellInfo(
                        spell: spell,
                        usages: usages,
                        recovery: recovery,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        BookmarkRibbon(
          isMarked: isActive,
          length: screenHeight / 2.5,
          peek: screenHeight / 4,
          left: 20,
          curve: Curves.linear,
          opacity: isPending ? KlimmeckGuideTheme.pendingInkOpacity : 1,
          onTap: onToggle,
        ),
      ],
    );
  }
}
