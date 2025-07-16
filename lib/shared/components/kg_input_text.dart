import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../../theme/kg_theme.dart';


class KGInputText extends StatelessWidget {
  const KGInputText({
    super.key,
    this.hintText,
    this.keyboardType,
    this.textMaxLength,
    required this.textInputAction,
    required this.fieldName,
    this.controller,
    this.hideText = false,
    this.onTap,
    this.icon,
    this.iconWidth,
    this.formatter,
    this.validator,
    this.width,
  });

  final String? hintText;
  final String? icon;
  final double? iconWidth;
  final double? width;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final int? textMaxLength;
  final TextInputAction textInputAction;
  final String fieldName;
  final bool? hideText;
  final GestureTapCallback? onTap;
  final TextInputFormatter? formatter;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
          border: Border.all(color: KlimmeckGuideTheme.parchment, width: 1.5),
          borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 20,
                      width: icon == null ? constraints.maxWidth : (iconWidth != null
                          ? constraints.maxWidth - (40 + iconWidth!)
                          : constraints.maxWidth - 65),
                      child: AutoSizeText(
                        fieldName,
                        maxLines: 1,
                        minFontSize: 10,
                        style: KlimmeckGuideTheme.instance.bodyMedium,
                      ),
                    ),
                    SizedBox(
                      width: icon == null ? constraints.maxWidth : (iconWidth != null
                          ? constraints.maxWidth - (40 + iconWidth!)
                          : constraints.maxWidth - 65),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: TextFormField(
                          controller: controller,
                          obscureText: hideText!,
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          inputFormatters: formatter != null ? [formatter!] : null,
                          textInputAction: textInputAction,
                          keyboardType: keyboardType ?? TextInputType.text,
                          maxLength: textMaxLength,
                          validator: validator,
                          style: KlimmeckGuideTheme.instance.bodyMedium,
                          autocorrect: false,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            counterText: "",
                            hintStyle: KlimmeckGuideTheme.instance.bodyMedium,
                            border: InputBorder.none,
                            errorStyle: KlimmeckGuideTheme.instance.errorText,
                            hintText: hintText,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                if (icon != null)
                  InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Center(
                        child: SizedBox(
                          height: iconWidth ?? 25,
                          width: iconWidth ?? 25,
                          child: SvgPicture.asset(icon!),
                        ),
                      ),
                    ),
                  )
              ],
            );
          },
        ),
      ),
    );
  }
}
