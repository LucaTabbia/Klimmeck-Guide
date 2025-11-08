import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/shared/components/popup/equipment_info_sheet.dart';

class EquipmentInfoSheetDisplay extends StatelessWidget {
  final EquipmentItem? selectedEquipment;
  final AnimationController animationController;

  const EquipmentInfoSheetDisplay({
    super.key,
    required this.selectedEquipment,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final Animation<double> positionAnimation =
        Tween<double>(
          begin: MediaQuery.of(context).size.height,
          end: 0.0,
        ).animate(
          CurvedAnimation(parent: animationController, curve: Curves.easeIn),
        );

    return Stack(
      children: [
        if (selectedEquipment != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => animationController.reverse(),
              behavior: HitTestBehavior.opaque,
              child: Container(),
            ),
          ),
        AnimatedBuilder(
          animation: animationController,
          builder: (context, child) {
            return Positioned(
              top: positionAnimation.value,
              right: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.height * 1.3 * (315 / 375),
                  child: selectedEquipment != null
                      ? SingleChildScrollView(
                          child: EquipmentInfoSheet(
                            equipmentItem: selectedEquipment!,
                            onEquip: () {}, // Implementa logica se necessario
                          ),
                        )
                      : null,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
