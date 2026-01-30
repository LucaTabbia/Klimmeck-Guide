/// Fragment for Lore fields
class _LoreFields {
  static const String full = '''
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
  ''';
}

class LoreQueries {
  static String get getAllLores => '''
    query lores {
      lores {
        ${_LoreFields.full}
      }
    }
  ''';

  static String get getLoreById => '''
    query lore(\$id: String!) {
      lore(id: \$id) {
        ${_LoreFields.full}
      }
    }
  ''';
}
