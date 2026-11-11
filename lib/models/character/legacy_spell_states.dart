// FINESTRA (BE prima della Phase 19) — file cancellato al gate (piano 19-11).

/// Status con l'unica lista di stati costruita dalle tre liste che la BE di
/// oggi serve ancora. Uno status senza la lista delle magie conosciute torna
/// com'è. Non lancia mai: ciò che non si legge si salta.
Map<String, dynamic> statusJsonWithLegacySpellStates(
  Map<String, dynamic> status,
  Object? assets,
) {
  final known = status['spells'];
  if (known is! List) return status;

  final statesById = _entriesBySpellId(status['spellStates']);
  final equippedById = _entriesBySpellId(
    assets is Map ? assets['activeSpells'] : null,
  );

  return {
    ...status,
    'spellStates': [
      for (final spell in known)
        if (_spellIdOf(spell) case final id?)
          <String, dynamic>{
            'spell': spell,
            'usages': _usagesOf(spell, statesById[id], equippedById[id]),
            'recoveries': _recoveriesOf(statesById[id]),
            'active': equippedById.containsKey(id),
          },
    ],
  };
}

/// Voci `{ spell: { id }, … }` per id della magia; a parità di id vale la prima.
Map<String, Map<Object?, Object?>> _entriesBySpellId(Object? entries) {
  final byId = <String, Map<Object?, Object?>>{};
  if (entries is! List) return byId;
  for (final entry in entries) {
    if (entry is! Map) continue;
    final id = _spellIdOf(entry['spell']);
    if (id == null) continue;
    byId.putIfAbsent(id, () => entry);
  }
  return byId;
}

String? _spellIdOf(Object? spell) {
  if (spell is! Map<String, dynamic>) return null;
  final id = spell['id'];
  return id is String ? id : null;
}

/// Stato per id, poi usi della magia equipaggiata, poi massimo di catalogo.
num _usagesOf(
  Object? spell,
  Map<Object?, Object?>? state,
  Map<Object?, Object?>? equipped,
) {
  final candidates = [
    state?['usages'],
    equipped?['usages'],
    if (spell is Map) spell['maxUsages'],
  ];
  return candidates.whereType<num>().firstOrNull ?? 0;
}

List<Object?> _recoveriesOf(Map<Object?, Object?>? state) {
  final recoveries = state?['recoveries'];
  return recoveries is List ? recoveries : const [];
}
