import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/character_portrait.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Ritratto incorniciato del personaggio nel profilo; il fallback è di [CharacterPortrait] (D-14).
class ProfileImage extends StatelessWidget {
  const ProfileImage({super.key, this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        height: 200,
        width: 200,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(30)),
          border: Border.all(color: KlimmeckGuideTheme.darkWood, width: 2),
        ),
        child: CharacterPortrait(imagePath: imagePath),
      ),
    );
  }
}
