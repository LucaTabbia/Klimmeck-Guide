class LoreQueries {
  static const String getAllLores = r'''
    query lores {
      lores {
        id
        image
        type
        name
        description
        unlocked
        relatedLore {
          id
          name
        }
      }
    }
  ''';

  static const String getLoreById = r'''
    query lore($id: String!) {
      lore(id: $id) {
        id
        image
        type
        name
        description
        unlocked
        relatedLore {
          id
          name
        }
      }
    }
  ''';
}
