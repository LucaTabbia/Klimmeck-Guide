import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klimmeck_guide/utils/app_log.dart';

import '../../repository/cache/svg_cache.dart';
import '../../repository/cache/svg_cache_manager.dart';

/// SVG di dominio letto dalla cache in memoria, poi dal disco/rete.
///
/// Mentre il file arriva mostra una scatola vuota della misura richiesta
/// (la pergamena traspare): nessun indicatore di caricamento in sessione
/// (Phase 17 D-21).
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
  File? _file;

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  @override
  void didUpdateWidget(CachedSvg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadSvg();
    }
  }

  Future<void> _loadSvg() async {
    final cached = SvgCache().getFile(widget.url);
    if (cached != null) {
      if (mounted) setState(() => _file = cached);
      return;
    }

    try {
      final file = await SvgCacheManager().getSingleFile(widget.url);
      SvgCache().add(widget.url, file);
      if (mounted) setState(() => _file = file);
    } catch (e) {
      appLog('CachedSvg: failed to load ${e.runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    if (file == null) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    return SvgPicture.file(
      file,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
