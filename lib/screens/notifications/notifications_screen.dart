import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import '../../models/notification.dart';
import '../../models/user.dart';
import '../../shared/components/card_icon.dart';
import '../../shared/components/title_icons.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.user});

  final User user;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<KGNotification> notifications = [
    KGNotification(title: 'Titolo', description: 'Descrizione'),
    KGNotification(
        title: 'Titolo',
        description:
            "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."),
    KGNotification(title: 'Titolo', description: 'Descrizione'),
    KGNotification(title: 'Titolo', description: 'Descrizione'),
    KGNotification(title: 'Titolo', description: 'Descrizione'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KlimmeckGuideTheme.deepNight,
      body: SafeArea(
        child: Column(
          children: [
            TitleAndIcons(
                hasBackButton: true,
                title: 'notifications',
                subTitle: "Cosa c'è di nuovo?",
                isNotification: true,
                user: widget.user),
            Padding(
              padding: const EdgeInsets.only(left: 30.0, right: 30, top: 40),
              child: SizedBox(
                height: MediaQuery.of(context).size.height -
                    (120 +
                        MediaQuery.of(context).size.width * 0.13 +
                        MediaQuery.of(context).viewPadding.bottom +
                        MediaQuery.of(context).viewPadding.top),
                child: ListView.builder(
                  itemCount: notifications.length,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 30,
                      ),
                      child: CardIcon(
                        content: notifications[index].description,
                        icon: "assets/icons/utils/video_line.svg",
                        title: notifications[index].title,
                        iconColor: KlimmeckGuideTheme.deepNight,
                        isNotification: true,
                        maxLines: 3,
                        onTap: () {
                          ///todo gestire
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
