import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/character.dart';
import 'package:klimmeck_guide/models/enums/class_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/profile/components/profile_image.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';
import 'package:klimmeck_guide/shared/components/text_section.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

class Profile extends StatefulWidget {
  const Profile({super.key, required this.character});

  final Character character;

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return BackgroundImage(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0),
        child: Container(
          decoration: BoxDecoration(color: KlimmeckGuideTheme.parchment),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 40),
                  SizedBox(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ProfileImage(),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 340,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: Column(
                              children: [
                                TextSection(sectionName: "Nome", data: widget.character.name ?? ""),
                                TextSection(
                                  sectionName: "Razza",
                                  data: widget.character.race?.label ?? "",
                                ),
                                TextSection(
                                  sectionName: "Classe",
                                  data: widget.character.classType?.label ?? "",
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  TextSection(sectionName: "Età (anni)", data: widget.character.age.toString()),
                  TextSection(sectionName: "Background", data: widget.character.background ?? ""),
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
