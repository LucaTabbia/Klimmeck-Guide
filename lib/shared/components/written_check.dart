import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/written_ink.dart';

/// Spunta che si scrive: comparendo si scopre da sinistra a destra come un
/// tratto di penna, sparendo si cancella nello stesso verso. Una spunta già
/// presente alla prima costruzione si vede intera, senza animazione.
class WrittenCheck extends StatefulWidget {
  const WrittenCheck({super.key, required this.isShown, required this.side});

  final bool isShown;
  final double side;

  static const Duration strokeDuration = Duration(milliseconds: 300);

  @override
  State<WrittenCheck> createState() => _WrittenCheckState();
}

class _WrittenCheckState extends State<WrittenCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stroke;

  @override
  void initState() {
    super.initState();
    _stroke = AnimationController(
      vsync: this,
      duration: WrittenCheck.strokeDuration,
      value: widget.isShown ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(WrittenCheck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isShown == oldWidget.isShown) return;
    if (widget.isShown) {
      _stroke.forward();
    } else {
      _stroke.reverse();
    }
  }

  @override
  void dispose() {
    _stroke.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.side,
      child: WrittenInk(
        stroke: _stroke,
        child: CachedSvg(
          url: CloudinaryAssets.url(CloudinaryAssets.check),
          width: widget.side,
          height: widget.side,
        ),
      ),
    );
  }
}
