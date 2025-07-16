import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../theme/kg_theme.dart';
import 'checkbox.dart';

class OptionsAndFilter extends StatefulWidget {
  const OptionsAndFilter({super.key, required this.onTap, this.hasFilters, this.isOptionsSelected = false, this.hasContractCheckbox});

  final Function(int) onTap;
  final bool? hasFilters;
  final bool? hasContractCheckbox;
  final bool isOptionsSelected;

  @override
  State<OptionsAndFilter> createState() => _OptionsAndFilterState();
}

class _OptionsAndFilterState extends State<OptionsAndFilter> {
  int currentSelection = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: constraints.maxWidth * 0.6 - 10,
                height: MediaQuery.of(context).size.width * 0.13 + 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    billTypeButton(0, "assets/icons/bills/light_gas_fill.svg",
                        "assets/icons/bills/light_gas_line.svg"),
                    billTypeButton(1, "assets/icons/bills/light_fill.svg",
                        "assets/icons/bills/light_line.svg"),
                    billTypeButton(
                        2, "assets/icons/bills/gas_fill.svg", "assets/icons/bills/gas_line.svg"),
                  ],
                ),
              ),
              if(widget.hasContractCheckbox == true)
                ElCheckBox(onTap: () => widget.onTap(3), width: (constraints.maxWidth * 0.4 - 10) * 0.9, height:  widget.isOptionsSelected
                    ? MediaQuery.of(context).size.width * 0.11 + 5
                    : MediaQuery.of(context).size.width * 0.11, isSelected: widget.isOptionsSelected, text: 'Vedi inattivi',),
              if (widget.hasFilters == true)
                billTypeButton(3, "assets/icons/utils/options_fill.svg",
                    "assets/icons/utils/options_line.svg"),
            ]);
      },
    );
  }

  Widget billTypeButton(int index, String selectedSvg, String unselectedSvg) {
    return InkWell(
      onTap: () => {
        if (index != 3)
          {
            widget.onTap(index),
            setState(() {
              currentSelection = index;
            })
          }
        else
          {
            widget.onTap(index),
          }
      },
      child: AnimatedContainer(
          height: currentSelection == index || index == 3 && widget.isOptionsSelected
              ? MediaQuery.of(context).size.width * 0.11 + 5
              : MediaQuery.of(context).size.width * 0.11,
          width: currentSelection == index  || index == 3 && widget.isOptionsSelected
              ? MediaQuery.of(context).size.width * 0.11 + 5
              : MediaQuery.of(context).size.width * 0.11,
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(15)),
              border: Border.all(
                  color: currentSelection == index  || index == 3 && widget.isOptionsSelected
                      ? KlimmeckGuideTheme.deepNight
                      : KlimmeckGuideTheme.parchment),
              color:
                  currentSelection == index  || index == 3 && widget.isOptionsSelected ? KlimmeckGuideTheme.primaryGold : KlimmeckGuideTheme.deepNight,
              boxShadow: currentSelection == index
                  ? [const BoxShadow(color: KlimmeckGuideTheme.primaryGold, blurRadius: 5)]
                  : null),
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Center(
              child: SvgPicture.asset(
                currentSelection == index  || index == 3 && widget.isOptionsSelected ? selectedSvg : unselectedSvg,
                color:
                    currentSelection == index  || index == 3 && widget.isOptionsSelected ? KlimmeckGuideTheme.deepNight : KlimmeckGuideTheme.parchment,
                width: currentSelection == index  || index == 3 && widget.isOptionsSelected
                    ? MediaQuery.of(context).size.width * 0.11 - 15
                    : MediaQuery.of(context).size.width * 0.11 - 20,
              ),
            ),
          )),
    );
  }
}
