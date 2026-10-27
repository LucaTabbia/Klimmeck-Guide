import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/use_type.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/spellbook_content.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/shared/components/popup/spell_info_sheet.dart';
import 'package:klimmeck_guide/utils/filter_values.dart';

/// Apre il foglio di dettaglio: il Diario lo ospita nel suo Stack con il cubit
/// del countdown della sezione (D-09, D-16).
typedef ShowSpellDetails =
    void Function(Spell spell, SpellRecoveryCubit recovery);

/// Tap su una magia (D-06..D-08, D-11): l'intento lo decide `SpellsCubit` sulla
/// vista ottimistica; qui solo l'aptica.
SpellToggleIntent toggleSpellWithFeedback(
  BuildContext context, {
  required Character character,
  required String spellId,
}) {
  final intent = context.read<SpellsCubit>().toggle(character, spellId);
  switch (intent) {
    case SpellToggleIntent.equip || SpellToggleIntent.unequip:
      HapticFeedback.lightImpact();
    case SpellToggleIntent.blockedSlotsFull || SpellToggleIntent.blockedNoSlots:
      HapticFeedback.selectionClick();
    case SpellToggleIntent.ignoredPending || SpellToggleIntent.ignoredUnknown:
      break;
  }
  return intent;
}

Character? _characterOf(CharacterState state) =>
    state is CharacterLoaded ? state.character : null;

/// Sezione «Magie imparate» del Diario (SPELL-01..07). Possiede il countdown:
/// vive solo mentre la pagina del Diario è a schermo (D-16).
class SpellsSection extends StatelessWidget {
  const SpellsSection({
    super.key,
    required this.cardSize,
    required this.onShowDetails,
  });

  final double cardSize;
  final ShowSpellDetails onShowDetails;

  @override
  Widget build(BuildContext context) => BlocProvider<SpellRecoveryCubit>(
    create: (context) =>
        SpellRecoveryCubit(clock: context.read<ServerClockService>()),
    child: _SpellsSectionBody(cardSize: cardSize, onShowDetails: onShowDetails),
  );
}

class _SpellsSectionBody extends StatefulWidget {
  const _SpellsSectionBody({
    required this.cardSize,
    required this.onShowDetails,
  });

  final double cardSize;
  final ShowSpellDetails onShowDetails;

  @override
  State<_SpellsSectionBody> createState() => _SpellsSectionBodyState();
}

class _SpellsSectionBodyState extends State<_SpellsSectionBody> {
  /// Selezione dei chip: stato di vista locale, mai persistito né inviato (D-22).
  UseType? _useTypeFilter;

  @override
  void initState() {
    super.initState();
    _follow(context.read<CharacterCubit>().state);
  }

  /// Ogni nuovo personaggio riallinea il countdown: così un uso recuperato
  /// lascia «in arrivo» (D-04).
  void _follow(CharacterState state) {
    if (state is! CharacterLoaded) return;
    context.read<SpellRecoveryCubit>().follow(
      SpellRecoveryCubit.inputsOf(Spellbook.of(state.character)),
    );
  }

  void _onCharacter(CharacterState state) {
    _follow(state);
    if (state is CharacterLoaded) _dropVanishedUseTypeFilter(state.character);
  }

  void _selectUseType(UseType? useType) =>
      setState(() => _useTypeFilter = useType);

  /// Un tipo sparito dalle magie conosciute riporta i chip a «Tutti» (D-23).
  void _dropVanishedUseTypeFilter(Character character) {
    final useTypes = presentFilterValues(
      UseType.values,
      Spellbook.of(character).entries.map((entry) => entry.spell.useType),
    );
    final retained = retainedFilterSelection(_useTypeFilter, useTypes);
    if (retained != _useTypeFilter) setState(() => _useTypeFilter = retained);
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<CharacterCubit, CharacterState>(
        listenWhen: (previous, current) =>
            current is CharacterLoaded &&
            _characterOf(previous) != current.character,
        listener: (context, state) => _onCharacter(state),
        child: BlocSelector<CharacterCubit, CharacterState, Character?>(
          selector: _characterOf,
          builder: (context, character) =>
              BlocBuilder<SpellsCubit, SpellsState>(
                builder: (context, spells) => _buildSection(character, spells),
              ),
        ),
      );

  Widget _buildSection(Character? character, SpellsState spells) {
    final spellbook = Spellbook.of(character, pending: spells.pending);
    if (character == null || !spellbook.isVisible) {
      return const SizedBox.shrink();
    }
    final outcome = spells.outcome;
    return Dropdown(
      sectionName: 'Magie imparate',
      data: BlocBuilder<SpellRecoveryCubit, SpellRecoveryState>(
        builder: (context, recovery) => SpellbookContent(
          spellbook: spellbook,
          recoveries: recovery.statuses,
          cardSize: widget.cardSize,
          onToggle: (spellId) => toggleSpellWithFeedback(
            context,
            character: character,
            spellId: spellId,
          ),
          onShowDetails: (spell) =>
              widget.onShowDetails(spell, context.read<SpellRecoveryCubit>()),
          resistSignal: outcome == null || !outcome.springsBack
              ? null
              : (spellId: outcome.spellId, sequence: outcome.sequence),
          useTypeFilter: _useTypeFilter,
          onUseTypeFilterChanged: _selectUseType,
        ),
      ),
    );
  }
}

/// Foglio del long-press legato allo stato vivo (D-09): attiva/in attesa da
/// `SpellsCubit`, usi da `CharacterCubit`, recupero dal countdown della sezione.
class SpellDetailsSheet extends StatelessWidget {
  const SpellDetailsSheet({super.key, required this.spell});

  final Spell spell;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<CharacterCubit, CharacterState, Character?>(
        selector: _characterOf,
        builder: (context, character) => BlocBuilder<SpellsCubit, SpellsState>(
          builder: (context, spells) =>
              BlocBuilder<SpellRecoveryCubit, SpellRecoveryState>(
                builder: (context, recovery) =>
                    _buildSheet(context, character, spells, recovery),
              ),
        ),
      );

  Widget _buildSheet(
    BuildContext context,
    Character? character,
    SpellsState spells,
    SpellRecoveryState recovery,
  ) {
    final spellbook = Spellbook.of(character, pending: spells.pending);
    final entry = spellbook.entryFor(spell.id);
    return SingleChildScrollView(
      child: SpellInfoSheet(
        spell: entry?.spell ?? spell,
        usages: entry?.usages,
        recovery: recovery.statusOf(spell.id),
        isActive: spellbook.activeSpellIds.contains(spell.id),
        isPending: spellbook.pending.containsKey(spell.id),
        onToggle: character == null
            ? null
            : () => toggleSpellWithFeedback(
                context,
                character: character,
                spellId: spell.id,
              ),
      ),
    );
  }
}
