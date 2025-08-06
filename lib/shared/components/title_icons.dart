import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../main.dart';
import '../../models/user.dart';
import '../../theme/kg_theme.dart';

class TitleAndIcons extends StatelessWidget {
  const TitleAndIcons({
    super.key,
    required this.title,
    required this.subTitle,
    this.isProfile,
    required this.user,
    this.isNotification = false,
    this.hasBackButton = false,
    this.onBack,
  });

  final String title;
  final String subTitle;
  final bool? isProfile;
  final bool isNotification;
  final GestureTapCallback? onBack;
  final User user;
  final bool hasBackButton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, left: 30, right: 30),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasBackButton)
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: InkWell(
                    onTap:
                        onBack ??
                        () {
                          navigatorKey.currentState?.pop();
                        },
                    child: SvgPicture.asset('assets/icons/utils/back.svg', height: 30, width: 30),
                  ),
                ),
              SizedBox(
                height: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AutoSizeText(
                      title,
                      maxLines: 1,
                      minFontSize: 8,
                      style: KlimmeckGuideTheme.instance.titleMedium,
                    ),
                    SizedBox(
                      width: constraints.maxWidth * 0.4,
                      child: AutoSizeText(
                        subTitle,
                        maxLines: 1,
                        minFontSize: 8,
                        style: KlimmeckGuideTheme.instance.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              /*InkWell(
                onTap: () => {
                      if (isNotification == true)
                        {navigatorKey.currentState?.pop()}
                      else
                        {
                          if (isProfile == true)
                            {
                              navigatorKey.currentState
                                  ?.pushReplacement(notificationRoute(customer))
                            }
                          else
                            {navigatorKey.currentState?.push(notificationRoute(customer))}
                        }
                    },
                child: SvgPicture.asset(
                  'assets/icons/utils/notifications_fill.svg',
                  height: 35,
                  width: 35,
                  color: isNotification == true ? KlimmeckGuideTheme.primary : null,
                )),*/
              const SizedBox(width: 30),
              InkWell(
                onTap: () => {
                  if (isProfile == true) {navigatorKey.currentState?.pop()} else {},
                },
                child: SvgPicture.asset(
                  'assets/icons/utils/profile_fill.svg',
                  height: 35,
                  width: 35,
                  color: isProfile == true ? KlimmeckGuideTheme.primaryGold : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
