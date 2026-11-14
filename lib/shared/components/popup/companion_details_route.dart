import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/shared/components/popup/companion_info_sheet.dart';

const Duration _slideDuration = Duration(milliseconds: 300);
const double _sheetAspect = 1.3 * (315 / 375);

/// Dettaglio del compagno fuori dal Diario (negozio, carrello, foglio quest,
/// premi dell'oste — D-35): stesso foglio, chiuso dal tocco fuori.
Future<void> showCompanionDetails(
  BuildContext context, {
  required Pet pet,
  String? name,
}) => showGeneralDialog<void>(
  context: context,
  useRootNavigator: true,
  barrierDismissible: true,
  barrierLabel: 'Chiudi',
  barrierColor: Colors.transparent,
  transitionDuration: _slideDuration,
  pageBuilder: (context, _, _) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        height: screenHeight,
        width: screenHeight * _sheetAspect,
        child: SingleChildScrollView(
          child: CompanionInfoSheet(pet: pet, name: name),
        ),
      ),
    );
  },
  transitionBuilder: (_, animation, _, child) => SlideTransition(
    position: Tween(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn)),
    child: child,
  ),
);
