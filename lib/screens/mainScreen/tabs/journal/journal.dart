import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/character.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';
import 'package:klimmeck_guide/shared/components/section.dart';
import 'package:klimmeck_guide/shared/components/text_section.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

class Journal extends StatefulWidget {
  const Journal({super.key, required this.character});

  final Character character;

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends State<Journal> {
  @override
  Widget build(BuildContext context) {
    return BackgroundImage(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0),
        child: Container(
          decoration: BoxDecoration(color: KlimmeckGuideTheme.parchment),
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 40),
                  Section(
                    sectionName: "Monete",
                    data: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          "Gold: ${widget.character.coins?.gold ?? 0}",
                          maxFontSize: 22,
                          style: KlimmeckGuideTheme.instance.bodyLarge,
                        ),
                        AutoSizeText(
                          "Silver: ${widget.character.coins?.silver ?? 0}",
                          maxFontSize: 22,
                          style: KlimmeckGuideTheme.instance.bodyLarge,
                        ),
                        AutoSizeText(
                          "Copper: ${widget.character.coins?.copper ?? 0}",
                          maxFontSize: 22,
                          style: KlimmeckGuideTheme.instance.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  TextSection(
                    sectionName: "Magie imparate",
                    data: widget.character.spells?.map((spell) => spell.name).join(", ") ?? "",
                  ),
                  TextSection(
                    sectionName: "Ferite",
                    data: widget.character.injuries?.map((injury) => injury.label).join(", ") ?? "",
                  ),
                  TextSection(
                    sectionName: "Punti vita",
                    data: "${widget.character.currentLifePoints}/${widget.character.maxLifePoints}",
                  ),
                  TextSection(sectionName: "XP ottenuti", data: widget.character.xp.toString()),
                  SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
