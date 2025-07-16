import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../theme/kg_theme.dart';


class EmptyListCard extends StatelessWidget {
  const EmptyListCard({super.key, required this.constraints, required this.text});

  final BoxConstraints constraints;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: constraints.maxHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/onBoarding/onBoarding1.svg',
              height: constraints.maxHeight * 0.5,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Text(
                text,
                style: KlimmeckGuideTheme.instance.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );
  }
}
