import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../../../models/lore.dart';

class CityModal extends StatefulWidget {
  const CityModal({super.key, required this.lore});

  final Lore lore;

  @override
  State<CityModal> createState() => _CityModalState();
}

class _CityModalState extends State<CityModal> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: true,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 1,
      builder: (context, scrollController) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            child: Stack(
              children: [
                SvgPicture.asset(
                  "assets/icons/svg/sheets/bottomEmptySheet.svg",
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height / 7),
                      if (widget.lore.image != null)
                        Image.asset(widget.lore.image!, width: 200, height: 200),
                      AutoSizeText(
                        widget.lore.name ?? "",
                        maxFontSize: 24,
                        minFontSize: 16,
                        textAlign: TextAlign.center,
                        style: KlimmeckGuideTheme.instance.specialText.copyWith(fontSize: 24),
                      ),

                      const SizedBox(height: 20),

                      AutoSizeText(
                        widget.lore.description ?? "",
                        maxFontSize: 18,
                        minFontSize: 12,
                        textAlign: TextAlign.left,
                        style: KlimmeckGuideTheme.instance.bodyMedium.copyWith(
                          fontSize: 18,
                          height: 1.5, // Better line height for readability
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
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
