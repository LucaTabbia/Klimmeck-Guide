import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';


class CardIcon extends StatelessWidget {
  const CardIcon({
    super.key,
    this.icon, 
    this.title,
    required this.content,
    this.onTap,
    this.maxLines,
    this.iconColor,
    this.isNotification = false,
  });

  final String? icon;
  final String? title;
  final String content;
  final int? maxLines;
  final Color? iconColor;
  final GestureTapCallback? onTap;
  final bool isNotification;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: KlimmeckGuideTheme.parchment, width: 1.5),
          borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: KlimmeckGuideTheme.instance.bodyMedium
                      ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, top: 10, bottom: 10),
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: 50,
                          minWidth: constraints.maxWidth - 105,
                          maxWidth: constraints.maxWidth - 105,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              content,
                              maxLines: maxLines,
                              minFontSize: 12,
                              overflow: TextOverflow.ellipsis,
                              style: KlimmeckGuideTheme.instance.bodyMedium
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                if (icon != null)
                  InkWell(
                    onTap: onTap,
                    child: Container(
                      decoration: onTap != null
                          ? const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(25)),
                              color: KlimmeckGuideTheme.primaryGold,
                            )
                          : null,
                      height: 50,
                      width: 50,
                      child: Center(
                        child: SvgPicture.asset(
                          icon!,
                          width: 25,
                          color: iconColor,
                        ),
                      ),
                    ),
                  )
              ],
            );
          },
        ),
      ),
    );
  }
}
