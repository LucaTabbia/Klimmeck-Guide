import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../repository/cache/svg_cache.dart';

class CachedSvg extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CachedSvg({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  State<CachedSvg> createState() => _CachedSvgState();
}

class _CachedSvgState extends State<CachedSvg> {
  // Cache the file lookup result to avoid repeated calls
  @override
  Widget build(BuildContext context) {
    final file = SvgCache().getFile(widget.url);

    if (file == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return SvgPicture.file(file, width: widget.width, height: widget.height, fit: widget.fit);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CachedSvgState &&
          runtimeType == other.runtimeType &&
          widget.url == other.widget.url &&
          widget.width == other.widget.width &&
          widget.height == other.widget.height &&
          widget.fit == other.widget.fit;

  @override
  int get hashCode =>
      widget.url.hashCode ^ widget.width.hashCode ^ widget.height.hashCode ^ widget.fit.hashCode;
}
