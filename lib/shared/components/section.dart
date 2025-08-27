import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

class Section extends StatelessWidget {
  const Section({super.key, required this.sectionName, required this.data});

  final String sectionName;
  final Widget data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        return Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: SizedBox(
                    width: maxWidth - (maxWidth / 5),
                    child: AutoSizeText(
                      sectionName,
                      maxFontSize: 20,
                      minFontSize: 12,
                      style: KlimmeckGuideTheme.instance.titleMedium,
                    ),
                  ),
                ),
                Container(
                  width: maxWidth - (maxWidth / 5),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: KlimmeckGuideTheme.darkBronze, width: 1)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
                  child: SizedBox(width: maxWidth - maxWidth / 5, child: data),
                ),
              ],
            ),
            Spacer(),
          ],
        );
      },
    );
  }
}
