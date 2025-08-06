import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

class TextSection extends StatelessWidget {
  const TextSection({super.key, required this.sectionName, required this.data});

  final String sectionName;
  final String data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 50,
                child: AutoSizeText(
                  sectionName,
                  maxFontSize: 20,
                  minFontSize: 12,
                  style: KlimmeckGuideTheme.instance.titleMedium,
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width / 2,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: KlimmeckGuideTheme.darkBronze, width: 1)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 50,
                child: AutoSizeText(
                  data,
                  maxFontSize: 22,
                  style: KlimmeckGuideTheme.instance.bodyLarge,
                ),
              ),
            ),
          ],
        ),
        Spacer(),
      ],
    );
  }
}
