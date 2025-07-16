import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../theme/kg_theme.dart';

class CardIconList extends StatelessWidget {
  const CardIconList({
    super.key,
    required this.icon,
    this.title,
    required this.contents,
    this.onTap,
    this.maxLines,
    this.iconColor,
    this.isNotification = false,
  });

  final String icon;
  final String? title;
  final List<String> contents;
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: KlimmeckGuideTheme.instance.bodyMedium
                  ),
                Wrap(
                  direction: Axis.vertical,
                  children: [
                    for(var content in contents)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, top: 10, bottom: 10),
                            child: SizedBox(
                              width: constraints.maxWidth - 105,
                              child: AutoSizeText(
                                content,
                                maxLines: maxLines,
                                minFontSize: 12,
                                overflow: TextOverflow.ellipsis,
                                style: KlimmeckGuideTheme.instance.bodyMedium,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: onTap,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Center(
                                child: SvgPicture.asset(
                                  icon,
                                  width: 25,
                                  color: iconColor,
                                ),
                              ),
                            ),
                          )
                        ],
                      )],
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
