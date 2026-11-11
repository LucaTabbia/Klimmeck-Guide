import 'package:klimmeck_guide/models/enums/lore_type.dart';
import 'package:klimmeck_guide/models/lore.dart';

const String bestiaryPageLinePrefix = 'Nuova pagina del Bestiario: ';
const String knowledgeLinePrefix = 'Conoscenza appresa: ';

/// Riga di una lore appena sbloccata, uguale sul foglio esiti e sul foglio
/// della pozione (Phase 17 D-10, Phase 18 D-21): un tipo sconosciuto vale
/// conoscenza.
String loreUnlockedLine(Lore lore) {
  final prefix = lore.type?.isBestiary ?? false
      ? bestiaryPageLinePrefix
      : knowledgeLinePrefix;
  return '$prefix${lore.name}';
}
