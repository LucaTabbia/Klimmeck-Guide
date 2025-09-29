import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../shared/components/modal/paper_sheet_modal.dart';
import 'components/shop_modal.dart';
import 'cubit/shop_cubit.dart';

class Shop extends StatefulWidget {
  const Shop({super.key, required this.character});

  final Character character;

  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> {
  List<EquipmentItem> _allEquipments = [];
  List<EquipmentItem> _characterEquipments = [];
  List<LootItem> _allItems = [];
  List<LootItem> _characterItems = [];

  @override
  void initState() {
    context.read<ShopCubit>().getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShopCubit, ShopState>(
      listener: (context, state) {
        if (state is ShopLoadData) {
          List<String> equipmentIds = widget.character.assets!.ownedEquipments!
              .map((equipment) => equipment.item!.id)
              .toList();
          List<String> itemIds = widget.character.assets!.ownedItems!
              .map((item) => item.item!.id)
              .toList();

          setState(() {
            _characterEquipments = state.equipmentItems.where((equipItem) {
              return equipmentIds.contains(equipItem.id);
            }).toList();
            _characterItems = state.lootItems.where((lootItem) {
              return itemIds.contains(lootItem.id);
            }).toList();
            _allEquipments = state.equipmentItems;
            _allItems = state.lootItems;
          });
        }
      },
      builder: (context, state) {
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Image.asset('assets/images/shopBackground.png', fit: BoxFit.cover),
            ),
            Positioned(
              left: 0,
              bottom: -10,
              child: SizedBox(
                height: MediaQuery.of(context).size.height / 1.5,
                width: MediaQuery.of(context).size.width,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Spacer(),
                    GestureDetector(
                      onTap: () => _showModalShop(_allEquipments, _allItems),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height / 1.5,
                        child: CachedSvg(
                          url:
                              "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660789/buy_pqj7e9.svg",
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showModalShop(_characterEquipments, _characterItems),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height / 2,
                        child: CachedSvg(
                          url:
                              "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660787/sell_x0fw5i.svg",
                        ),
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showModalShop(List<EquipmentItem> equipments, List<LootItem> items) {
    showModalBottomSheet(
      useSafeArea: false,
      isScrollControlled: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return PaperSheetModal(
          child: ShopModal(equipments: equipments, items: items),
        );
      },
    );
  }
}
