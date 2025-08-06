import 'dart:io';

import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

class ProfileImage extends StatelessWidget {
  const ProfileImage({super.key, this.image});

  final File? image;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        height: 200,
        width: 200,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(30)),
          border: Border.all(color: KlimmeckGuideTheme.darkWood, width: 2),
        ),
        child: image != null ? Image.file(image!) : Image.asset('assets/images/silhouette.jpeg'),
      ),
    );
  }
}
