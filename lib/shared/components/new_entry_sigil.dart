import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

/// Sigillo di ceralacca che segnala un'aggiunta non ancora vista.
class NewEntrySigil extends StatelessWidget {
  const NewEntrySigil({super.key, this.size = 32});

  static final String url = CloudinaryAssets.url(
    CloudinaryAssets.newEntrySigil,
  );

  final double size;

  @override
  Widget build(BuildContext context) =>
      CachedSvg(url: url, width: size, height: size);
}
