import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/mission_lines.dart';

/// Tocco di una voce del Diario sotto il blocco della missione (Phase 21
/// D-11, D-16): non fa nulla, la riga sopra dice perché.
void ignoreMissionLockedToggle(String _) {}

/// Sezione del Diario bloccata dalla missione in corso: la riga «Missione in
/// corso» sopra il contenuto, che resta visibile.
class MissionLockedSection extends StatelessWidget {
  const MissionLockedSection({
    super.key,
    required this.lineKey,
    required this.child,
  });

  final Key lineKey;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        missionInProgressLabel,
        key: lineKey,
        style: KlimmeckGuideTheme.instance.bodyMedium,
      ),
      child,
    ],
  );
}
