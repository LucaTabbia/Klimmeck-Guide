/// Fase di combattimento in cui agisce un gioiello (BE Phase 13 D-24): la
/// semantica appartiene al motore del BE, il FE stampa solo la riga «Uso» (D-12).
enum AccessoryUseType {
  attack(label: 'Attacco'),
  defense(label: 'Difesa');

  const AccessoryUseType({required this.label});

  final String label;
}
