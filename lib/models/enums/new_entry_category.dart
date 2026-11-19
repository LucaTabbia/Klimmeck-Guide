/// Ciò che può aggiungersi a Diario e Profilo e che il sigillo segnala.
enum NewEntryCategory {
  spells(storageKey: 'spells'),
  companions(storageKey: 'companions'),
  equipment(storageKey: 'equipment'),
  injuries(storageKey: 'injuries'),
  items(storageKey: 'items'),
  background(storageKey: 'background');

  const NewEntryCategory({required this.storageKey});

  final String storageKey;

  static const Set<NewEntryCategory> journal = {
    spells,
    companions,
    equipment,
    injuries,
    items,
  };

  static const Set<NewEntryCategory> profile = {background};
}
