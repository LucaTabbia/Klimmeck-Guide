import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../main.dart';
import '../../theme/kg_theme.dart';

class SimpleTitle extends StatelessWidget {
  const SimpleTitle(
      {super.key,
      required this.title,
      required this.subtitle,
      this.hasBackButton = false,
      this.onBack});

  final String title;
  final String subtitle;
  final bool hasBackButton;
  final GestureTapCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 20.0, left: 30, right: 30),
        child: SizedBox(
          height: 70,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (hasBackButton)
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: InkWell(
                      onTap: onBack ??
                          () {
                            navigatorKey.currentState?.pop();
                          },
                      child: SvgPicture.asset(
                        'assets/icons/utils/back.svg',
                        height: 30,
                        width: 30,
                      ),
                    ),
                  ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: KlimmeckGuideTheme.instance.titleMedium,
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: AutoSizeText(subtitle,
                              maxLines: 1, style: KlimmeckGuideTheme.instance.bodyMedium),
                        ),
                      )
                    ],
                  ),
                ),
              ]),
        ));
  }
}
