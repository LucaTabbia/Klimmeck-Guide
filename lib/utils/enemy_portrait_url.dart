import 'package:klimmeck_guide/config/cloudinary_assets.dart';

final RegExp _cloudinaryRelativePath = RegExp(r'^v\d+/\S+$');

/// URL del ritratto di un nemico dal suo `imagePath` (D-03): un URL `https`
/// resta com'è, un percorso Cloudinary relativo `v<n>/…` passa da
/// [CloudinaryAssets.url]; tutto il resto (i segnaposto `assets/images/…`
/// del DB, BE Phase 11 D-13) non si mostra finché l'utente non carica le
/// immagini (BE Phase 11 D-24).
String? enemyPortraitUrl(String? imagePath) {
  final path = imagePath?.trim();
  if (path == null || path.isEmpty) return null;
  final uri = Uri.tryParse(path);
  if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) return path;
  if (_cloudinaryRelativePath.hasMatch(path)) return CloudinaryAssets.url(path);
  return null;
}
