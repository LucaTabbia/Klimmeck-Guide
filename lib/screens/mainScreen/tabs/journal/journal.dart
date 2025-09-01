import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';
import 'package:klimmeck_guide/shared/components/coins_column.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
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
  late Equipment _tempEquipment;

  @override
  void initState() {
    context.read<JournalCubit>().getData(
      widget.character.assets!.ownedItems!.map((equip) => equip.item!.id).toList(),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double mannequinWidth = 400 * (127.5 / 374.999989);
    return BlocConsumer<JournalCubit, JournalState>(
      listener: (context, state) {
        if (state is JournalLoadData) {
          setState(() {
            _tempEquipment = Equipment(
              head: state.equipmentItems.firstWhere(
                (equip) => equip.id == widget.character.assets!.wearedEquipment!.head?.id,
              ),
              chest: state.equipmentItems.firstWhere(
                (equip) => equip.id == widget.character.assets!.wearedEquipment!.chest?.id,
              ),
              arms: state.equipmentItems.firstWhere(
                (equip) => equip.id == widget.character.assets!.wearedEquipment!.arms?.id,
              ),
              foots: state.equipmentItems.firstWhere(
                (equip) => equip.id == widget.character.assets!.wearedEquipment!.foots?.id,
              ),
              legs: state.equipmentItems.firstWhere(
                (equip) => equip.id == widget.character.assets!.wearedEquipment!.legs?.id,
              ),
              leftHand: state.equipmentItems.firstWhere(
                (equip) => equip.id == widget.character.assets!.wearedEquipment!.leftHand?.id,
              ),
              rightHand: state.equipmentItems.firstWhere(
                (equip) => equip.id == widget.character.assets!.wearedEquipment!.rightHand?.id,
              ),
              firstAccessory: state.equipmentItems.firstWhere(
                (equip) => equip.id == widget.character.assets!.wearedEquipment!.firstAccessory?.id,
              ),
              secondAccessory: state.equipmentItems.firstWhere(
                (equip) =>
                    equip.id == widget.character.assets!.wearedEquipment!.secondAccessory?.id,
              ),
            );
          });
        }
      },
      builder: (context, state) {
        if (state is JournalLoadData) {
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
                          data: CoinsColumn(
                            height: 70,
                            width: MediaQuery.of(context).size.width,
                            coins: widget.character.status?.coins,
                          ),
                        ),
                        TextSection(
                          sectionName: "Magie imparate",
                          data:
                              widget.character.status?.spells
                                  ?.map((spell) => spell.name)
                                  .join(", ") ??
                              "",
                        ),
                        TextSection(
                          sectionName: "Ferite",
                          data:
                              widget.character.status?.injuries
                                  ?.map((injury) => injury.label)
                                  .join(", ") ??
                              "",
                        ),
                        TextSection(
                          sectionName: "Punti vita",
                          data:
                              "${widget.character.status?.currentLifePoints}/${widget.character.status?.maxLifePoints}",
                        ),
                        TextSection(
                          sectionName: "XP ottenuti",
                          data: widget.character.status?.xp?.toString() ?? "0",
                        ),
                        Dropdown(
                          sectionName: "Armatura",
                          data: SizedBox(
                            height: 430,
                            width: MediaQuery.of(context).size.width,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                                  child: SizedBox(
                                    width: mannequinWidth,
                                    height: 400,
                                    child: SvgPicture.asset(
                                      widget.character.infos!.sex!.mannequinPath,
                                    ),
                                  ),
                                ),
                                if (_tempEquipment.head != null)
                                  Positioned(
                                    left: (mannequinWidth / 2) - 40,
                                    top: 0,
                                    child: SizedBox(
                                      height: 80,
                                      width: 80,
                                      child: SvgPicture.asset(
                                        widget.character.infos!.sex!.helmetPath,
                                      ),
                                    ),
                                  ),
                                if (_tempEquipment.head != null)
                                  Positioned(
                                    left: (mannequinWidth / 2) - 40,
                                    top: 0,
                                    child: SizedBox(
                                      height: 80,
                                      width: 80,
                                      child: SvgPicture.asset(
                                        widget.character.infos!.sex!.helmetPath,
                                      ),
                                    ),
                                  ),
                                if (_tempEquipment.legs != null)
                                  Positioned(
                                    left: (mannequinWidth / 2) - ((140 * (300 / 337.499995) / 2)),
                                    top: 170,
                                    child: SizedBox(
                                      height: 140,
                                      width: 140 * (300 / 337.499995),
                                      child: SvgPicture.asset(
                                        widget.character.infos!.sex!.gravesPath,
                                      ),
                                    ),
                                  ),
                                if (_tempEquipment.foots != null)
                                  Positioned(
                                    left: (mannequinWidth / 2) - ((115 * (375 / 374.999991) / 2)),
                                    top: 299,
                                    child: SizedBox(
                                      height: 115,
                                      width: 115 * (375 / 374.999991),
                                      child: SvgPicture.asset(
                                        widget.character.infos!.sex!.bootsPath,
                                      ),
                                    ),
                                  ),
                                if (_tempEquipment.chest != null)
                                  Positioned(
                                    left: (mannequinWidth / 2) - 70,
                                    top: 70,
                                    child: SizedBox(
                                      height: 140,
                                      width: 140,
                                      child: SvgPicture.asset(
                                        widget.character.infos!.sex!.chestPiecePath,
                                      ),
                                    ),
                                  ),
                                if (_tempEquipment.arms != null)
                                  Positioned(
                                    left: (mannequinWidth / 2) - ((85 * (375 / 225) / 2)),
                                    top: 170,
                                    child: SizedBox(
                                      height: 85,
                                      width: 85 * (375 / 225),
                                      child: SvgPicture.asset(
                                        widget.character.infos!.sex!.glovesPath,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return Placeholder();
      },
    );
  }
}
