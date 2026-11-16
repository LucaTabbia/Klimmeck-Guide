import 'package:klimmeck_guide/models/energy_damage.dart';
import 'package:klimmeck_guide/models/enums/spell_origin.dart';
import 'package:klimmeck_guide/models/enums/use_type.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spell_recovery_status.dart';
import 'package:klimmeck_guide/utils/game_duration_format.dart';

// Copy provvisoria (D-19): ogni stringa della sezione Magie vive qui.

const String spellLineSeparator = ' · ';

/// Riga neutra al posto degli slot sotto il rango `mage` (D-11): niente numeri
/// né titoli.
const String noSpellSlotsLine = 'Nessuno slot per le magie: cresci di rango';

/// Slot presenti ma nessuna magia conosciuta (D-12).
const String noKnownSpellsLine = 'Non hai ancora imparato nessuna magia';

/// Usi correnti; senza `usages` (magia fuori dal libro del personaggio) vale
/// il massimo.
String? spellUsagesLabel({required int? usages, required int? maxUsages}) {
  final shown = usages ?? maxUsages;
  if (shown == null) return null;
  if (maxUsages == null || shown >= maxUsages) return 'Usi: $shown';
  return 'Usi: $shown/$maxUsages';
}

/// Tempo al prossimo uso; 0 minuti = meno di un minuto (D-04).
String formatRecoveryCountdown(int remainingMinutes) => remainingMinutes <= 0
    ? 'meno di 1 min'
    : formatGameDuration(Duration(minutes: remainingMinutes));

String? spellRecoveryLabel(SpellRecoveryStatus status) => switch (status) {
  SpellRecoveryFull() => null,
  SpellRecoveryCountdown(:final remainingMinutes) =>
    'prossimo tra ${formatRecoveryCountdown(remainingMinutes)}',
  SpellRecoveryArriving() => 'in arrivo…',
  SpellRecoveryUnknown() => 'in recupero',
};

String? spellRecoveryTimeLabel(Spell spell) {
  final milliseconds = spell.recoveryTime;
  if (milliseconds == null) return null;
  return 'Recupero: ${formatGameDuration(Duration(milliseconds: milliseconds))}';
}

/// Energia e potenza introdotte dal tipo d'uso («Attacco: Fuoco 12», D-24);
/// senza tipo d'uso resta «Danno».
String? spellDamageLabel(EnergyDamage? damage, {UseType? useType}) {
  final type = damage?.type;
  if (type == null) return null;
  final prefix = useType?.label ?? 'Danno';
  final power = damage?.power;
  if (power == null || power == 0) return '$prefix: ${type.label}';
  return '$prefix: ${type.label} $power';
}

/// Origine della magia (D-06), prima dell'uso.
String? spellOriginLabel(SpellOrigin? origin) =>
    origin == null ? null : 'Origine: ${origin.label}';

String? spellUseTypeLabel(UseType? useType) =>
    useType == null ? null : 'Uso: ${useType.label}';

String? spellMaxUsagesLabel(int? maxUsages) =>
    maxUsages == null ? null : 'Usi massimi: $maxUsages';

/// Il livello minimo è quello servito (D-07): mai un confronto col personaggio
/// (D-08), mai il tempo di apprendimento (D-28).
String? spellLearnLabel(Spell spell) {
  final level = spell.minLevelToLearn;
  if (level == null || level <= 0) return null;
  return 'Per impararla: Livello $level';
}

/// Riga compatta della lista (D-13, D-05, D-24): usi, poi recupero (durata a
/// usi pieni, countdown sotto il massimo), poi energia introdotta dal tipo
/// d'uso.
String spellSummaryLine({
  required Spell spell,
  required int? usages,
  required SpellRecoveryStatus recovery,
}) => [
  spellUsagesLabel(usages: usages, maxUsages: spell.maxUsages),
  recovery is SpellRecoveryFull
      ? spellRecoveryTimeLabel(spell)
      : spellRecoveryLabel(recovery),
  spellDamageLabel(spell.energyDamage, useType: spell.useType),
].whereType<String>().join(spellLineSeparator);
