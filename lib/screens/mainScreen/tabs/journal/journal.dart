import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/equipment_mannequin.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/injury_name_icon.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/cards/equipment_item_card.dart';
import 'package:klimmeck_guide/shared/components/cards/loot_item_card.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';
import 'package:klimmeck_guide/shared/components/coins_column.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/shared/components/popup/equipment_info_sheet.dart';
import 'package:klimmeck_guide/shared/components/section.dart';
import 'package:klimmeck_guide/shared/components/text_section.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../../shared/components/item_grid.dart';

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
  List<LootItem> _lootItems = [];

  List<EquipType>? _selectedTypes;

  late AnimationController _animationController;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.addStatusListener((status) {
      if (status.isDismissed) {
        setState(() => _selectedEquipment = null);
      }
    });

    context.read<JournalCubit>().getData(
      widget.character.assets!.ownedEquipments!.map((e) => e.item!.id).toList(),
      widget.character.assets!.ownedItems!.map((e) => e.item!.id).toList(),
      widget.character.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    _positionAnimation = Tween<double>(
      begin: MediaQuery.of(context).size.height,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    return BlocConsumer<JournalCubit, JournalState>(
      listener: (context, state) {
        if (state is JournalLoadData) {
          setState(() {
            _tempEquipment = state.equipment;
            _equippedItems = _tempEquipment.values.whereType<EquipmentItem>().toList();
            _allEquipmentItems = state.equipmentItems;
            _lootItems = state.lootItems;
            _filteredItems = _equippedItems;
          });
        }
      },
      builder: (context, state) {
        if (state is! JournalLoadData) return const Placeholder();

        final screenWidth = MediaQuery.of(context).size.width;
        final spellSize = (screenWidth - 165) / 5;
        final lootSize = (screenWidth - 180) / 5;
        final equipmentSize = (screenWidth - 180) / 4;

        return GestureDetector(
          onTap: () => _animationController.reverse(),
          child: BackgroundImage(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Container(
                    decoration: BoxDecoration(color: KlimmeckGuideTheme.parchment),
                    height: MediaQuery.of(context).size.height,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 40),
                            _buildLifePointsSection(),
                            TextSection(
                              sectionName: "XP ottenuti",
                              data: widget.character.status?.xp?.toString() ?? "0",
                            ),
                            Section(
                              sectionName: "Monete",
                              data: CoinsColumn(
                                height: 120,
                                width: screenWidth,
                                coins: widget.character.status?.coins,
                              ),
                            ),
                            _buildInjuriesSection(),
                            Dropdown(
                              sectionName: "Magie imparate",
                              data: ItemGrid(
                                items: widget.character.status!.spells!,
                                size: spellSize,
                                itemBuilder: (spell, size) => SpellCard(spell: spell, size: size),
                              ),
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
                                  const SizedBox(width: 20),
                                  Flexible(
                                    child: Column(
                                      children: [
                                        AutoSizeText(
                                          "${_selectedTypes?.first.label ?? "Oggetti equipaggiati"} :",
                                          maxLines: 1,
                                          maxFontSize: 20,
                                          minFontSize: 10,
                                          textAlign: TextAlign.center,
                                          style: KlimmeckGuideTheme.instance.headlineLarge,
                                        ),
                                        ItemGrid<EquipmentItem>(
                                          items: _filteredItems,
                                          size: equipmentSize,
                                          itemBuilder: (item, size) => EquipmentItemCard(
                                            equipmentItem: item,
                                            size: size,
                                            isSelected: _equippedItems.contains(item),
                                            onTap: _equipItem,
                                            onLongPress: _selectEquipment,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Dropdown(
                              sectionName: "Oggetti",
                              data: ItemGrid<LootItem>(
                                items: _lootItems,
                                size: lootSize,
                                itemBuilder: (item, size) =>
                                    LootItemCard(lootItem: item, size: size),
                              ),
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildEquipmentInfoSheet(screenWidth),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLifePointsSection() {
    return Section(
      sectionName: "Punti vita",
      data: Row(
        children: [
          CachedSvg(
            url:
                "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660480/healEffect_jc9bsg.svg",
            height: 50,
            width: 50,
          ),
          const SizedBox(width: 15),
          Text(
            "${widget.character.status?.currentLifePoints} / ${widget.character.status?.maxLifePoints}",
            style: KlimmeckGuideTheme.instance.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildInjuriesSection() {
    return Section(
      sectionName: "Ferite",
      data: Column(
        children: widget.character.status!.injuries!
            .map((injury) => InjuryNameIcon(injury: injury))
            .toList(),
      ),
    );
  }

  Widget _buildEquipmentInfoSheet(double screenWidth) {
    return AnimatedBuilder(
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
                        equipmentItem: _selectedEquipment!,
                        onEquip: () {},
                        isEquipped: _equippedItems.contains(_selectedEquipment),
                      ),
                    )
                  : null,
            ),
          ),
        );
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
    setState(() => _selectedEquipment = item);
    _animationController.forward();
  }

  void _equipItem(EquipmentItem item) {
    setState(() {
      if (!_equippedItems.remove(item)) _equippedItems.add(item);
    });
  }
}
