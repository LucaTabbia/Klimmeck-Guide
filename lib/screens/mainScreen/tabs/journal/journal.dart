import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/equipment_mannequin.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';
import 'package:klimmeck_guide/shared/components/coins_column.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/shared/components/equipment_item_card.dart';
import 'package:klimmeck_guide/shared/components/popup/equipment_info_sheet.dart';
import 'package:klimmeck_guide/shared/components/section.dart';
import 'package:klimmeck_guide/shared/components/text_section.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

class Journal extends StatefulWidget {
  const Journal({super.key, required this.character});

  final Character character;

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends State<Journal> with SingleTickerProviderStateMixin {
  late Equipment _tempEquipment;
  List<EquipmentItem> _allEquipmentItems = [];
  List<EquipmentItem> _equippedItems = [];
  EquipmentItem? _selectedEquipment;
  List<EquipmentItem> _filteredItems = [];

  List<EquipType>? _selectedTypes;

  late AnimationController _animationController;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));

    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.addStatusListener((status) {
      if (status.isDismissed) {
        setState(() {
          _selectedEquipment = null;
        });
      }
    });
    context.read<JournalCubit>().getData(
      widget.character.assets!.ownedItems!.map((equip) => equip.item!.id).toList(),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      _positionAnimation = Tween<double>(
        begin: MediaQuery.of(context).size.height,
        end: 0.0,
      ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    });

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
            _equippedItems = _tempEquipment.values.whereType<EquipmentItem>().toList();
            _allEquipmentItems = state.equipmentItems;
            _filteredItems = _equippedItems;
          });
        }
      },
      builder: (context, state) {
        if (state is JournalLoadData) {
          return GestureDetector(
            onTap: () => _animationController.reverse(),
            child: BackgroundImage(
              child: Stack(
                children: [
                  Padding(
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
                                data: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    EquipmentMannequin(
                                      selectedTypes: _selectedTypes,
                                      sexType: widget.character.infos!.sex!,
                                      equipment: _tempEquipment,
                                      onTap: _selectTypes,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 20.0, top: 20),
                                      child: Container(
                                        height: MediaQuery.of(context).size.height - 40,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              width: 1,
                                              color: KlimmeckGuideTheme.darkBronze,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return SizedBox(
                                            height: MediaQuery.of(context).size.height,
                                            width: constraints.maxWidth,
                                            child: Column(
                                              children: [
                                                AutoSizeText(
                                                  "${_selectedTypes != null ? _selectedTypes!.first.label : "Oggetti equipaggiati"} :",
                                                  maxLines: 1,
                                                  maxFontSize: 20,
                                                  minFontSize: 10,
                                                  textAlign: TextAlign.center,
                                                  style: KlimmeckGuideTheme.instance.headlineLarge,
                                                ),
                                                GridView.builder(
                                                  padding: EdgeInsets.only(
                                                    top: 10,
                                                    bottom: 0,
                                                    right: 15,
                                                  ),
                                                  shrinkWrap: true,
                                                  gridDelegate:
                                                      SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: 4,
                                                        crossAxisSpacing: 10,
                                                        mainAxisSpacing: 10,
                                                        childAspectRatio: 1,
                                                      ),
                                                  itemCount: _filteredItems.length,
                                                  itemBuilder: (context, index) {
                                                    final item = _filteredItems[index];
                                                    return EquipmentItemCard(
                                                      onTap: _equipItem,
                                                      onLongPress: _selectEquipment,
                                                      isSelected: _equippedItems.contains(item),
                                                      size: constraints.maxWidth / 4,
                                                      equipmentItem: item,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _positionAnimation.value,
                        right: 0,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height,
                            width: MediaQuery.of(context).size.height * 1.3 * (315 / 375),
                            child: _selectedEquipment != null
                                ? SingleChildScrollView(
                                    child: EquipmentInfoSheet(
                                      equipmentItem: _selectedEquipment,
                                      onEquip: () {},
                                      isEquipped: _equippedItems.contains(_selectedEquipment),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }
        return Placeholder();
      },
    );
  }

  void _selectTypes(List<EquipType> types, bool isSame) {
    setState(() {
      _selectedTypes = isSame ? null : types;

      _filteredItems = isSame
          ? _equippedItems
          : _allEquipmentItems.where((item) => _selectedTypes!.contains(item.equipType)).toList();
    });
  }

  void _selectEquipment(EquipmentItem item) {
    setState(() {
      _selectedEquipment = item;
    });
    _animationController.forward();
  }

  void _equipItem(EquipmentItem item) {
    setState(() {
      if (!_equippedItems.remove(item)) {
        _equippedItems.add(item);
      }
    });
  }
}
