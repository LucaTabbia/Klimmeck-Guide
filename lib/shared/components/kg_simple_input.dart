import 'package:flutter/material.dart';

import '../../theme/kg_theme.dart';

class KGSimpleInput extends StatelessWidget {
  const KGSimpleInput({
    super.key,
    this.hintText,
    this.keyboardType,
    this.textMaxLength,
    required this.textInputAction,
    this.controller,
    this.isDark = false,
  });

  final String? hintText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final int? textMaxLength;
  final TextInputAction textInputAction;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: isDark ? KlimmeckGuideTheme.deepNight : KlimmeckGuideTheme.parchment, width: 1.5),
          borderRadius: BorderRadius.circular(10)
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        child: Center(
          child: TextFormField(
            controller: controller,
            textAlign: TextAlign.start,
            maxLines: 1,
            textInputAction: textInputAction,
            keyboardType: keyboardType ?? TextInputType.text,
            maxLength: textMaxLength,
            style: KlimmeckGuideTheme.instance.bodyMedium,
            autocorrect: false,
            decoration: InputDecoration(
              isCollapsed: true,
              counterText: "",
              hintStyle: KlimmeckGuideTheme.instance.bodyMedium,
              border: InputBorder.none,
              hintText: hintText,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        )
      ),
    );
  }
}

