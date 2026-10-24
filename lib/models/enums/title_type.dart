enum TitleType {
  rookie('Recluta'),
  adventurer('Avventuriero'),
  paladin('Paladino'),
  mage('Mago'),
  hero('Eroe'),
  legend('Leggenda');

  const TitleType(this.label);

  /// Nome del titolo mostrato al giocatore (copy provvisoria, D-19).
  final String label;
}
