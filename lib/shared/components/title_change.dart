import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/shared/components/title_badge.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Passaggio di titolo: badge di prima, freccia, badge di dopo.
class TitleChange extends StatelessWidget {
  const TitleChange({super.key, required this.before, required this.after});

  final TitleType before;
  final TitleType after;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      TitleBadge(title: before),
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KlimmeckGuideTheme.spacingXs,
        ),
        child: Text('→', style: KlimmeckGuideTheme.instance.bodyMedium),
      ),
      TitleBadge(title: after),
    ],
  );
}
