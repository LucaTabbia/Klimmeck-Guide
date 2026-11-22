import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/shared/components/character_portrait.dart';
import 'package:klimmeck_guide/shared/components/title_badge.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Ritratto incorniciato del personaggio nel profilo, con la medaglia del
/// rango sull'angolo in alto a destra; il fallback è di [CharacterPortrait]
/// (D-14).
class ProfileImage extends StatelessWidget {
  const ProfileImage({super.key, this.imagePath, this.title});

  static const Key frameKey = ValueKey('profile.portraitFrame');

  static const double _frameSide = 200;
  static const double _frameMargin = 10;
  static const double _medalSize = 64;

  /// Quanto la medaglia sporge oltre l'angolo della cornice.
  static const double _medalOverhang = 14;

  final String? imagePath;
  final TitleType? title;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return Padding(
      padding: const EdgeInsets.all(_frameMargin),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            key: frameKey,
            height: _frameSide,
            width: _frameSide,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(30)),
              border: Border.all(color: KlimmeckGuideTheme.darkWood, width: 2),
            ),
            child: CharacterPortrait(imagePath: imagePath),
          ),
          if (title != null)
            Positioned(
              top: -_medalOverhang,
              right: -_medalOverhang,
              child: TitleBadge(title: title, size: _medalSize),
            ),
        ],
      ),
    );
  }
}
