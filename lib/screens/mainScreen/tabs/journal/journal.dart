import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/character.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
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
    return Container(
      decoration: BoxDecoration(color: KlimmeckGuideTheme.parchment),
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 40),
                TextSection(sectionName: "Monete", data: widget.character.coins.toString()),
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
    );
  }
}
