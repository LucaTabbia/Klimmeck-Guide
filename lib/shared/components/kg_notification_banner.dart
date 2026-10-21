import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Banner in-app di gioco (NOTIF-07, D-17): striscia sottile di pergamena in
/// alto, nessun componente di sistema (regola 1: superficie gameplay). Il tap
/// lo decide il chiamante.
class KgNotificationBanner extends StatelessWidget {
  const KgNotificationBanner({
    super.key,
    required this.notification,
    required this.onTap,
  });

  static const double minHeight = 44;
  static const double maxWidth = 480;
  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(KlimmeckGuideTheme.spacingSm),
  );

  final KGNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    return Semantics(
      button: true,
      label: '${notification.title}. ${notification.description}',
      onTap: onTap,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: minHeight,
          maxWidth: maxWidth,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(
              color: KlimmeckGuideTheme.parchment,
              borderRadius: _radius,
              border: Border.all(color: KlimmeckGuideTheme.darkBronze),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: _radius,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KlimmeckGuideTheme.spacingMd,
                  vertical: KlimmeckGuideTheme.spacingSm,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleMedium.copyWith(
                        color: KlimmeckGuideTheme.darkWood,
                      ),
                    ),
                    const SizedBox(height: KlimmeckGuideTheme.spacingXs),
                    Text(
                      notification.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium.copyWith(
                        color: KlimmeckGuideTheme.darkWood,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
