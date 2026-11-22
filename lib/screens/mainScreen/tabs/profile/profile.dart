import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/shared/components/section.dart';
import 'package:klimmeck_guide/shared/components/background_entries.dart';
import 'package:klimmeck_guide/models/enums/new_entry_category.dart';
import 'package:klimmeck_guide/screens/mainScreen/newEntriesCubit/new_entries_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/new_entries_builder.dart';
import 'package:klimmeck_guide/models/enums/class_type.dart';
import 'package:klimmeck_guide/models/enums/pronoun_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/profile/components/profile_image.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';
import 'package:klimmeck_guide/shared/components/text_section.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../../models/character/character.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  void initState() {
    super.initState();
    context.read<NewEntriesCubit>().visit(NewEntryCategory.profile);
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundImage(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0),
        child: Container(
          decoration: BoxDecoration(color: KlimmeckGuideTheme.parchment),
          child: BlocSelector<CharacterCubit, CharacterState, Character?>(
            selector: (state) =>
                state is CharacterLoaded ? state.character : null,
            builder: (context, character) {
              final infos = character?.infos;
              if (infos == null) {
                return Center(child: Placeholder());
              }
              return SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),
                      SizedBox(
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            ProfileImage(
                              imagePath: infos.imagePath,
                              title: character?.status?.title,
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width - 340,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Column(
                                  children: [
                                    TextSection(
                                      sectionName: "Nome",
                                      data: infos.name ?? "",
                                    ),
                                    TextSection(
                                      sectionName: "Razza",
                                      data: infos.race?.label ?? "",
                                    ),
                                    TextSection(
                                      sectionName: "Classe",
                                      data: infos.classType?.label ?? "",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextSection(
                        sectionName: "Pronome",
                        data: infos.pronoun?.label ?? "",
                      ),
                      TextSection(
                        sectionName: "Età (anni)",
                        data: infos.age.toString(),
                      ),
                      Section(
                        sectionName: "Background",
                        data: NewEntriesBuilder(
                          category: NewEntryCategory.background,
                          builder: (context, newEntries) => BackgroundEntries(
                            entries: infos.background,
                            newEntries: newEntries,
                          ),
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
