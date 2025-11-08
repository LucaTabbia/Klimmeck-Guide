import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

class TransactionMessageBubble extends StatelessWidget {
  final String message;
  const TransactionMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: MediaQuery.of(context).size.width / 10,
      child: Stack(
        children: [
          const CachedSvg(
            url:
                "https://res.cloudinary.com/dzuhywp53/image/upload/v1761422762/comic_balloon_grteoq.svg",
            height: 200,
            width: 200,
          ),
          SizedBox(
            height: 200,
            width: 200,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 50.0,
                horizontal: 30,
              ),
              child: Center(
                child: AutoSizeText(
                  message,
                  textAlign: TextAlign.center,
                  style: KlimmeckGuideTheme.instance.titleMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
