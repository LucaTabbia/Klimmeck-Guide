import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../repository/cache/svg_cache.dart';
import '../../repository/cache/svg_cache_manager.dart';

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
  bool _loading = true;

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
    // Check in-memory cache first (instant)
    final cached = SvgCache().getFile(widget.url);
    if (cached != null) {
      if (mounted) setState(() { _file = cached; _loading = false; });
      return;
    }

    // Fall back to disk cache via SvgCacheManager
    try {
      final fileInfo = await SvgCacheManager().getSingleFile(widget.url);
      SvgCache().add(widget.url, fileInfo);
      if (mounted) setState(() { _file = fileInfo; _loading = false; });
    } catch (e) {
      debugPrint('CachedSvg: failed to load $e');
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    if (_file == null) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    return SvgPicture.file(_file!, width: widget.width, height: widget.height, fit: widget.fit);
  }
}
