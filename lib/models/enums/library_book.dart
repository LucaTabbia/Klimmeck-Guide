import 'package:klimmeck_guide/models/enums/lore_type.dart';

/// I quattro libri della Biblioteca (D-06): tipi di lore, titolo e chiave del
/// segnalibro sul device (D-07). Copertine e segnalibri sono della UI.
enum LibraryBook {
  bestiary(
    title: 'Bestiario',
    storageKey: 'bestiary',
    types: [LoreType.enemy, LoreType.animal, LoreType.plant],
  ),
  places(
    title: 'Luoghi',
    storageKey: 'places',
    types: [LoreType.city, LoreType.region, LoreType.state],
  ),
  religions(
    title: 'Religioni',
    storageKey: 'religions',
    types: [LoreType.religion, LoreType.ceremony, LoreType.god],
  ),
  knowledge(
    title: 'Conoscenze',
    storageKey: 'knowledge',
    types: [LoreType.character, LoreType.knowledge, LoreType.material],
  );

  const LibraryBook({
    required this.title,
    required this.storageKey,
    required this.types,
  });

  final String title;
  final String storageKey;

  /// Sezioni del libro nell'ordine di pagina.
  final List<LoreType> types;

  bool holds(LoreType? type) => type != null && types.contains(type);
}
