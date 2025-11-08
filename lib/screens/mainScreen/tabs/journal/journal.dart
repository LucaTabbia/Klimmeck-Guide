import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../models/coins.dart';
import '../../../../models/enums/injury_type.dart';
import '../../../../models/enums/slot_type.dart';
import '../../../../models/equipment_item.dart';
import '../../../../models/request/equip_item_request.dart';
import '../../../../models/spell.dart';
import '../../../../shared/components/cards/spell_card.dart';
import '../../../../shared/components/coins_display.dart';
import '../../../../shared/components/dropdown.dart';
import '../../../../shared/components/item_row.dart';
import '../../../../shared/components/popup/equipment_info_sheet.dart';
import '../../../../shared/components/section.dart';
import '../../../../shared/components/text_section.dart';
import '../../../../theme/kg_theme.dart';
import '../../characterCubit/character_cubit.dart';
import 'components/equipment_mannequin.dart';
import 'components/injury_name_icon.dart';
import 'cubit/journal_cubit.dart';

class Journal extends StatefulWidget {
  const Journal({super.key});

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends State<Journal> with SingleTickerProviderStateMixin {
  List<EquipmentItem> _equippedItems = [];
  EquipmentItem? _selectedEquipment;
  List<EquipmentItem> _filteredItems = [];
  SlotType? _selectedSlot;

  late AnimationController _animationController;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _positionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.addStatusListener((status) {
      if (status.isDismissed) {
        setState(() => _selectedEquipment = null);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildLifePointsSection() {
    return BlocSelector<
      CharacterCubit,
      CharacterState,
      ({int? current, int? max})
    >(
      selector: (state) {
        if (state is CharacterLoaded) {
          return (
            current: state.character.status?.currentLifePoints,
            max: state.character.status?.maxLifePoints,
          );
        }
        return (current: null, max: null);
      },
      builder: (context, lifePoints) {
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
                "${lifePoints.current} / ${lifePoints.max}",
                style: KlimmeckGuideTheme.instance.bodyLarge,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoinsSection() {
    return BlocSelector<CharacterCubit, CharacterState, Coins?>(
      selector: (state) {
        if (state is CharacterLoaded) {
          return state.character.status!.coins;
        }
        return null;
      },
      builder: (context, coins) {
        final screenWidth = MediaQuery.of(context).size.width;
        return Section(
          sectionName: "Monete",
          data: CoinsDisplay(height: 120, width: screenWidth, coins: coins),
        );
      },
    );
  }

  Widget _buildInjuriesSection() {
    return BlocSelector<CharacterCubit, CharacterState, List<InjuryType>?>(
      selector: (state) {
        if (state is CharacterLoaded) {
          return state.character.status!.injuries;
        }
        return null;
      },
      builder: (context, injuries) {
        return Section(
          sectionName: "Ferite",
          data: Column(
            children: injuries!
                .map((injury) => InjuryNameIcon(injury: injury))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildSpellsSection() {
    return BlocSelector<CharacterCubit, CharacterState, List<Spell>?>(
      selector: (state) {
        if (state is CharacterLoaded) {
          return state.character.status!.spells;
        }
        return null;
      },
      builder: (context, spells) {
        return Dropdown(
          sectionName: "Magie imparate",
          data: Column(
            children: [
              ...List.generate(
                spells!.length,
                (index) => SpellCard(spell: spells[index], size: 50),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArmorSection(
    Character character,
    double screenWidth,
    double lootSize,
  ) {
    return Dropdown(
      sectionName: "Armatura",
      data: Padding(
        padding: const EdgeInsets.only(right: 20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EquipmentMannequin(
              selectedSlot: _selectedSlot,
              sexType: character.infos!.sex!,
              equipment: character.assets!.wearedEquipment!,
              onTap: (slotType) => _selectSlot(slotType, character),
            ),
            const SizedBox(width: 20),
            Flexible(
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: AutoSizeText(
                      "${_selectedSlot?.label ?? "Oggetti equipaggiati"} :",
                      maxLines: 1,
                      maxFontSize: 20,
                      minFontSize: 10,
                      textAlign: TextAlign.center,
                      style: KlimmeckGuideTheme.instance.headlineLarge,
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 40,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        ...List.generate(
                          _filteredItems.length,
                          (index) => ItemRow(
                            assetItem: _filteredItems[index],
                            onLongTap: (item) => _selectEquipment(item),
                            onSelect: (item) =>
                                _equipItem(item as EquipmentItem, character),
                            isSelected: _equippedItems.contains(
                              _filteredItems[index],
                            ),
                            showCoins: false,
                            size: lootSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnedItemsSection(Character character, double lootSize) {
    return Dropdown(
      sectionName: "Oggetti",
      data: Column(
        children: [
          ...List.generate(
            character.assets!.ownedItems!.length,
            (index) => ItemRow(
              assetItem: character.assets!.ownedItems![index].item!,
              quantity: character.assets!.ownedItems![index].quantity!,
              showCoins: false,
              size: lootSize,
            ),
          ),
        ],
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
                  ? BlocBuilder<CharacterCubit, CharacterState>(
                      builder: (context, state) {
                        if (state is CharacterLoaded) {
                          return SingleChildScrollView(
                            child: EquipmentInfoSheet(
                              equipmentItem: _selectedEquipment!,
                              onEquip: () => _equipItem(
                                _selectedEquipment!,
                                state.character,
                              ),
                              isEquipped: _equippedItems.contains(
                                _selectedEquipment,
                              ),
                            ),
                          );
                        }
                        return Placeholder();
                      },
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  void _selectSlot(SlotType slotType, Character character) {
    if (_selectedSlot == slotType) {
      setState(() {
        _selectedSlot = null;
        _filteredItems = character.assets!.wearedEquipment!.values
            .whereType<EquipmentItem>()
            .toList();
      });
    } else {
      setState(() {
        _selectedSlot = slotType;
        _filteredItems = character.assets!.ownedEquipments!
            .where(
              (item) => slotType.types.contains(
                (item.item as EquipmentItem).equipType,
              ),
            )
            .map((item) => item.item as EquipmentItem)
            .toList();
      });
    }
  }

  void _selectEquipment(EquipmentItem item) {
    setState(() => _selectedEquipment = item);
    _animationController.forward();
  }

  SlotType? _findEquippedSlot(EquipmentItem item, Character character) {
    final equipment = character.assets?.wearedEquipment;
    if (equipment == null) return null;
    final equipmentMap = equipment.toJson();
    for (final slot in SlotType.values) {
      final itemIdInSlot = equipmentMap[slot.name];
      if (itemIdInSlot == item.id) {
        return slot;
      }
    }
    return null;
  }

  void _equipItem(EquipmentItem item, Character character) {
    final isCurrentlyEquipped = _equippedItems.contains(item);
    SlotType? targetSlot;
    String? itemIdToSend;

    if (isCurrentlyEquipped) {
      targetSlot = _findEquippedSlot(item, character);
      itemIdToSend = null;
    } else {
      if (_selectedSlot == null) {
        print("Impossibile equipaggiare: Selezionare prima uno slot.");
        return;
      }
      targetSlot = _selectedSlot;
      itemIdToSend = item.id;
    }

    if (targetSlot == null) {
      print("Errore: Impossibile determinare lo slot target per l'azione.");
      return;
    }

    final request = EquipItemRequest(
      id: character.id,
      itemId: itemIdToSend,
      slotType: targetSlot,
    );

    context.read<JournalCubit>().equipItem(request);
  }

  @override
  Widget build(BuildContext context) {
    _positionAnimation =
        Tween<double>(
          begin: MediaQuery.of(context).size.height,
          end: 0.0,
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
        );

    final screenWidth = MediaQuery.of(context).size.width;
    final lootSize = (screenWidth - 180) / 5;

    return BlocBuilder<CharacterCubit, CharacterState>(
      builder: (context, state) {
        if (state is CharacterLoaded) {
          Character character = state.character;

          _equippedItems = (character.assets?.wearedEquipment?.values ?? [])
              .whereType<EquipmentItem>()
              .toList();

          if (_selectedSlot == null && _filteredItems.isEmpty) {
            _filteredItems = _equippedItems;
          }

          if (_selectedSlot == null && _filteredItems != _equippedItems) {
            _filteredItems = _equippedItems;
          }
          return GestureDetector(
            onTap: () => _animationController.reverse(),
            child: BackgroundImage(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Container(
                      color: KlimmeckGuideTheme.parchment,
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
                                data: character.status?.xp?.toString() ?? "0",
                              ),
                              _buildCoinsSection(),
                              _buildInjuriesSection(),
                              _buildSpellsSection(),
                              _buildArmorSection(
                                character,
                                screenWidth,
                                lootSize,
                              ),
                              _buildOwnedItemsSection(character, lootSize),
                              const SizedBox(height: 120),
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
        }
        return Placeholder();
      },
    );
  }
}
