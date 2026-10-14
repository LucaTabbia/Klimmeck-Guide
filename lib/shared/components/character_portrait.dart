import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Ritratto di un personaggio (D-14): file locale scelto → URL remoto → silhouette.
/// Unico punto che decide il fallback: usarlo ovunque si mostri un `imagePath`.
class CharacterPortrait extends StatelessWidget {
  const CharacterPortrait({super.key, this.imagePath, this.localFilePath});

  static const String silhouetteAsset =
      'assets/images/placeholders/silhouette.jpeg';
  static const String semanticLabel = 'Ritratto del personaggio';

  final String? imagePath;
  final String? localFilePath;

  static ImageProvider resolve({String? imagePath, String? localFilePath}) {
    if (localFilePath != null && localFilePath.isNotEmpty) {
      return FileImage(File(localFilePath));
    }
    if (imagePath != null && imagePath.isNotEmpty) {
      return CachedNetworkImageProvider(imagePath);
    }
    return const AssetImage(silhouetteAsset);
  }

  @override
  Widget build(BuildContext context) => Image(
    image: resolve(imagePath: imagePath, localFilePath: localFilePath),
    fit: BoxFit.cover,
    semanticLabel: semanticLabel,
    errorBuilder: (_, _, _) => Image.asset(
      silhouetteAsset,
      fit: BoxFit.cover,
      semanticLabel: semanticLabel,
    ),
  );
}
