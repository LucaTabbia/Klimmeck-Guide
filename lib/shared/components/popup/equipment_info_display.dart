import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/shared/components/popup/equipment_info_sheet.dart';

class EquipmentInfoSheetDisplay extends StatefulWidget {
  final EquipmentItem? selectedEquipment;
  final AnimationController animationController;

  const EquipmentInfoSheetDisplay({
    super.key,
    required this.selectedEquipment,
    required this.animationController,
  });

  @override
  State<EquipmentInfoSheetDisplay> createState() =>
      _EquipmentInfoSheetDisplayState();
}

class _EquipmentInfoSheetDisplayState extends State<EquipmentInfoSheetDisplay> {
  late Animation<double> _positionAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _positionAnimation = Tween<double>(
      begin: MediaQuery.of(context).size.height,
      end: 0.0,
    ).animate(
      CurvedAnimation(
          parent: widget.animationController, curve: Curves.easeIn),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        if (widget.selectedEquipment != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => widget.animationController.reverse(),
              behavior: HitTestBehavior.opaque,
              child: Container(),
            ),
          ),
        AnimatedBuilder(
          animation: widget.animationController,
          builder: (context, child) {
            return Positioned(
              top: _positionAnimation.value,
              right: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: screenHeight,
                  width: screenHeight * 1.3 * (315 / 375),
                  child: widget.selectedEquipment != null
                      ? SingleChildScrollView(
                          child: EquipmentInfoSheet(
                            equipmentItem: widget.selectedEquipment!,
                            onEquip: () {},
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
