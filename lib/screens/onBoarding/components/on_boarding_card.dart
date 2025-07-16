import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../theme/kg_theme.dart';

class OnBoardingCard extends StatelessWidget {
  const OnBoardingCard({
    super.key,
    required this.text,
    required this.isShownPage, required this.title, required this.svg, required this.subtitle,
  });

  final String text;
  final String title;
  final String subtitle;
  final String svg;
  final bool isShownPage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 60.0, left: 40),
              child: AnimatedOpacity(
                  opacity: isShownPage ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 800),
                  child:Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: KlimmeckGuideTheme.instance.specialText,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 3.0),
                        child: Text(
                          subtitle,
                          style: KlimmeckGuideTheme.instance.titleMedium,
                        ),
                      ),
                    ],
                  )),
            ),
          ),
          const Spacer(),
          AnimatedOpacity(
              opacity: isShownPage ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 800),
              child: SvgPicture.asset(svg, width: 220, height: 220)),
          const Spacer(),
          AnimatedOpacity(
              opacity: isShownPage ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 2000),
              child: _description(context)),
          const Spacer(),
          const SizedBox(height: 60)
        ],
      ),
    );
  }

  Widget _description(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 13),
        child: Center(
          child: AutoSizeText(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
            style: KlimmeckGuideTheme.instance.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
