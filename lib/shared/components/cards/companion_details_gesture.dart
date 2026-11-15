import 'package:flutter/widgets.dart';
import 'package:klimmeck_guide/models/pet.dart';

/// Pressione lunga che apre i dettagli di un compagno (D-22): non apre nulla
/// finché il viewer non ne ha sbloccato la lore (`Pet.known`, servito dal BE),
/// come la sagoma di un nemico mai sconfitto. La pressione resta catturata:
/// senza, al rilascio diventerebbe un tocco (equipaggiare, selezionare).
/// Unico punto della regola per ogni carta del compagno.
VoidCallback? companionDetailsGesture(Pet pet, VoidCallback? openDetails) {
  if (openDetails == null) return null;
  return pet.known ? openDetails : _keepClosed;
}

void _keepClosed() {}
