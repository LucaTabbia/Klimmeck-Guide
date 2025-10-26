import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

class PaperSheetModal extends StatelessWidget {
  const PaperSheetModal({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: true,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 1,
      builder: (context, scrollController) {
        return Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            child: Stack(
              children: [
                CachedSvg(
                  url:
                      "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660758/bottomEmptySheet_se1k2l.svg",
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width / 7,
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.width,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
