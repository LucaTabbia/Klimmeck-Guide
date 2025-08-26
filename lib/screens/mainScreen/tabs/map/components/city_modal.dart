import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../../../models/city.dart';
import '../../../../../models/lore.dart';

class CityModal extends StatefulWidget {
  const CityModal({super.key, required this.city, required this.lore});

  final City city;
  final Lore lore;

  @override
  State<CityModal> createState() => _CityModalState();
}

class _CityModalState extends State<CityModal> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          currentFocus.focusedChild?.unfocus();
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: KlimmeckGuideTheme.parchment,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(KlimmeckGuideTheme.radius),
            topRight: Radius.circular(KlimmeckGuideTheme.radius),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (widget.city.image != null)
                Image.asset(widget.city.image!, width: 200, height: 200),
              AutoSizeText(
                maxFontSize: 24,
                widget.city.name ?? "",
                style: KlimmeckGuideTheme.instance.specialText.copyWith(fontSize: 24),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
                child: AutoSizeText(
                  maxFontSize: 18,
                  widget.lore.description ?? "",
                  style: KlimmeckGuideTheme.instance.bodyMedium.copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
