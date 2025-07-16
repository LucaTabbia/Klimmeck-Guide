import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../theme/kg_theme.dart';

class KGError extends StatefulWidget {
  const KGError({super.key});

  @override
  State<KGError> createState() => _ElErrorState();
}

class _ElErrorState extends State<KGError> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        Center(
          child: SvgPicture.asset("assets/icons/error/lucyError.svg",
              width: MediaQuery.of(context).size.width * 0.45),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Text(
            'error',
            style: KlimmeckGuideTheme.instance.bodyMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            'turnOffLight',
            style: KlimmeckGuideTheme.instance.bodyMedium,
          ),
        ),
        const Spacer()
      ],
    );
  }
}
