import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/kg_theme.dart';


class ELBottomNavigationBar extends StatelessWidget {
  const ELBottomNavigationBar({
    super.key,
    required this.currentPage,
    required this.onItemTap,
  });

  final int currentPage;
  final Function(int) onItemTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        navBarElement(
            'assets/icons/navbar/bills_fill.svg',
            'assets/icons/navbar/bills_line.svg',
            'bills',
            0,
            context),
        navBarElement(
            'assets/icons/navbar/self_reading_fill.svg',
            'assets/icons/navbar/self_reading_line.svg',
            'selfReading',
            1,
            context),
        navBarElement(
            'assets/icons/navbar/support_fill.svg',
            'assets/icons/navbar/support_line.svg',
            'support',
            2,
            context),
      ],
    );
  }

  InkWell navBarElement(String selectedSvg, String unselectedSvg, String label,
      int index, BuildContext context) {
    return InkWell(
      onTap: () => onItemTap(index),
      child: Column(
        children: [
          AnimatedContainer(
              height: currentPage == index
                  ? MediaQuery.of(context).size.width * 0.15 + 10
                  : MediaQuery.of(context).size.width * 0.15,
              width: currentPage == index
                  ? MediaQuery.of(context).size.width * 0.15 + 10
                  : MediaQuery.of(context).size.width * 0.15,
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(25)),
                  border: Border.all(
                      color: currentPage == index
                          ? KlimmeckGuideTheme.deepNight
                          : KlimmeckGuideTheme.parchment),
                  color: currentPage == index
                      ? KlimmeckGuideTheme.primaryGold
                      : KlimmeckGuideTheme.deepNight,
                  boxShadow: currentPage == index
                      ? [
                          const BoxShadow(
                              color: KlimmeckGuideTheme.primaryGold, blurRadius: 5)
                        ]
                      : null),
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Center(
                  child: SvgPicture.asset(
                    index == currentPage ? selectedSvg : unselectedSvg,
                    color: index == currentPage
                        ? KlimmeckGuideTheme.deepNight
                        : KlimmeckGuideTheme.parchment,
                    width: currentPage == index
                        ? MediaQuery.of(context).size.width * 0.15 - 23
                        : MediaQuery.of(context).size.width * 0.15 - 33,
                  ),
                ),
              )),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.15,
            height: 20,
            child: Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: AutoSizeText(
                  label,
                  maxLines: 1,
                  minFontSize: 6,
                  textAlign: TextAlign.center,
                  style: KlimmeckGuideTheme.instance
                      .bodyMedium,
                )),
          )
        ],
      ),
    );
  }
}
