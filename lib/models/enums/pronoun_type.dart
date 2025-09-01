enum PronounType { he, she, them }

extension PronounTypeExtension on PronounType {
  String get label {
    switch (this) {
      case PronounType.he:
        return 'Lui';
      case PronounType.she:
        return 'Lei';
      case PronounType.them:
        return 'Loro';
    }
  }
}
