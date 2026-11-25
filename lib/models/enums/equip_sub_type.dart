/// Famiglia di un'arma servita dal BE (`EquipmentItem.equipSubType`); le armi
/// a due mani siedono in una mano e tengono vuota l'altra (regola del BE).
enum EquipSubType {
  sword(label: 'Spada'),
  greatsword(label: 'Spadone', isTwoHanded: true),
  dagger(label: 'Pugnale'),
  axe(label: 'Ascia'),
  mace(label: 'Mazza'),
  warHammer(label: 'Martello da guerra', isTwoHanded: true),
  spear(label: 'Lancia', isTwoHanded: true),
  bow(label: 'Arco', isTwoHanded: true),
  shortStaff(label: 'Bastone corto'),
  longStaff(label: 'Bastone lungo', isTwoHanded: true),
  wand(label: 'Bacchetta'),
  grimoire(label: 'Grimorio');

  const EquipSubType({required this.label, this.isTwoHanded = false});

  final String label;
  final bool isTwoHanded;
}
