import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/written_check.dart';

import '../../models/pet.dart';
import '../../theme/kg_theme.dart';
import '../../utils/item_lines.dart';
import 'cards/companion_card.dart';
import 'cards/companion_details_gesture.dart';
import 'coins_display.dart';

/// Riga di un compagno (negozio, carrello, premi dell'oste): carta con immagine
/// e nome (D-22, D-34), prezzo e righe di testo; la velocità sta solo sulla
/// carta. Il tocco seleziona, il tocco prolungato apre il dettaglio (D-35).
class CompanionRow extends StatelessWidget {
  const CompanionRow({
    super.key,
    required this.pet,
    required this.size,
    this.isBuy = true,
    this.showCoins = true,
    this.isEquipped = false,
    this.isSelected = false,
    this.name,
    this.onTap,
    this.onLongPress,
  });

  final Pet pet;
  final double size;
  final bool isBuy;
  final bool showCoins;
  final bool isEquipped;
  final bool isSelected;

  /// Nome scelto del compagno posseduto (D-20); `null` = la specie.
  final String? name;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  static const double _checkShare = 0.4;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: companionDetailsGesture(pet, onLongPress),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          children: [
            _buildCard(),
            if (showCoins)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: CoinsDisplay(
                  coins: isBuy ? pet.buyPrice : pet.sellPrice,
                  height: size,
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: _buildTexts(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Il segnalibro rosso del Diario segna il compagno al fianco; la spunta,
  /// grande e sopra a tutto nell'angolo in alto a destra, quello scelto.
  Widget _buildCard() {
    final checkSide = size * _checkShare;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CompanionCard(
          pet: pet,
          size: size,
          name: name,
          isMarked: isEquipped ? true : null,
        ),
        Positioned(
          right: -checkSide * 0.2,
          top: -checkSide * 0.2,
          child: IgnorePointer(
            child: WrittenCheck(isShown: isSelected, side: checkSide),
          ),
        ),
      ],
    );
  }

  Widget _buildTexts() {
    final attack = petAttackLine(pet);
    final defense = petDefenseLine(pet);
    final style = KlimmeckGuideTheme.instance.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (attack != null)
          Text(
            attack,
            key: ValueKey('companion-attack-${pet.id}'),
            style: style,
          ),
        if (defense != null)
          Text(
            defense,
            key: ValueKey('companion-defense-${pet.id}'),
            style: style,
          ),
        if (isEquipped)
          Text(
            companionEquippedMark,
            key: ValueKey('companion-equipped-${pet.id}'),
            style: style,
          ),
      ],
    );
  }
}
