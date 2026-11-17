/// Lato in pixel del riquadro in cui Cloudinary fa stare i raster: basta al
/// marker più grande della mappa allo zoom massimo, e un'immagine alta e
/// stretta non esce sovradimensionata.
const int rasterDeliverySide = 1024;

const String _uploadSegment = '/image/upload/';

/// Gli SVG di dominio sono raster incapsulati da 1–5 MB: compilarli ferma lo
/// schermo. Cloudinary li consegna come WebP leggeri con la stessa
/// inquadratura (revisione layout 2026-11-17). Ogni altro url resta com'è.
String rasterDeliveryUrl(String url) {
  final isCloudinarySvg = url.contains(_uploadSegment) && url.endsWith('.svg');
  if (!isCloudinarySvg) return url;
  return url.replaceFirst(
    _uploadSegment,
    '${_uploadSegment}f_webp,c_fit,w_$rasterDeliverySide,h_$rasterDeliverySide/',
  );
}
