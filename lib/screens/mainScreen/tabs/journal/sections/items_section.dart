import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/enums/new_entry_category.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/new_entries_builder.dart';
import 'package:klimmeck_guide/shared/components/new_entry_sigil.dart';
import 'package:klimmeck_guide/config/companion_care.dart';
import 'package:klimmeck_guide/models/asset_item.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/companion/companion_potion_target.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/potion_sheet.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_cubit.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';
import 'package:klimmeck_guide/shared/components/items_filter.dart';
import 'package:klimmeck_guide/shared/components/modal/paper_sheet_modal.dart';
import 'package:klimmeck_guide/utils/filter_values.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';
import 'package:klimmeck_guide/utils/mission_lines.dart';

Character? _characterOf(CharacterState state) =>
    state is CharacterLoaded ? state.character : null;

List<AssetQuantity> _ownedItemsOf(Character character) =>
    character.assets?.ownedItems ?? const <AssetQuantity>[];

/// Pozione bevibile dal Diario (D-11): effetto heal con una ricarica
/// servita dal backend. Null = riga di sola lettura.
LootItem? _potionOf(AssetItem item) {
  final loot = item.asLoot;
  if (loot == null || loot.effect != EffectType.heal) return null;
  return loot.recovery == null ? null : loot;
}

/// Sezione «Oggetti» del Diario. Possiede il countdown delle pozioni: vive
/// solo mentre la pagina del Diario è a schermo (Phase 18 D-12). Le pozioni
/// heal con una ricarica si bevono toccandone la pergamena, anche in viaggio,
/// mai in attesa di soccorso (D-11). Durante l'attesa del personaggio la
/// pergamena resta toccabile se un compagno può bere (D-32), solo a cura dei
/// compagni accesa (Pitfall 3).
class ItemsSection extends StatelessWidget {
  const ItemsSection({
    super.key,
    required this.size,
    this.isCompanionCareEnabled = companionCareEnabled,
  });

  final double size;
  final bool isCompanionCareEnabled;

  @override
  Widget build(BuildContext context) => BlocProvider<PotionRecoveryCubit>(
    create: (context) =>
        PotionRecoveryCubit(clock: context.read<ServerClockService>()),
    child: _ItemsSectionBody(
      size: size,
      isCompanionCareEnabled: isCompanionCareEnabled,
    ),
  );
}

class _ItemsSectionBody extends StatefulWidget {
  const _ItemsSectionBody({
    required this.size,
    required this.isCompanionCareEnabled,
  });

  final double size;
  final bool isCompanionCareEnabled;

  @override
  State<_ItemsSectionBody> createState() => _ItemsSectionBodyState();
}

class _ItemsSectionBodyState extends State<_ItemsSectionBody> {
  /// Selezione dei chip: stato di vista locale, mai persistito né inviato (D-22).
  EffectType? _selectedEffect;

  @override
  void initState() {
    super.initState();
    _follow(context.read<CharacterCubit>().state);
  }

  /// Ogni nuovo personaggio riallinea il countdown alla fine della ricarica
  /// servita dal backend (D-12).
  void _follow(CharacterState state) {
    if (state is! CharacterLoaded) return;
    context.read<PotionRecoveryCubit>().follow(
      state.character.status?.potionRecoveryUntil,
    );
  }

  void _onCharacter(CharacterState state) {
    _follow(state);
    _dropVanishedEffectFilter(state);
  }

  /// Un effetto sparito dagli oggetti riporta i chip a «Tutti» (D-23).
  void _dropVanishedEffectFilter(CharacterState state) {
    if (state is! CharacterLoaded) return;
    final retained = retainedFilterSelection(
      _selectedEffect,
      presentEffectTypes(_ownedItemsOf(state.character)),
    );
    if (retained != _selectedEffect) setState(() => _selectedEffect = retained);
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
          builder: (context, character) => character == null
              ? const SizedBox.shrink()
              : NewEntriesBuilder(
                  category: NewEntryCategory.items,
                  builder: (context, newItemIds) =>
                      _buildSection(character, newItemIds),
                ),
        ),
      );

  Widget _buildSection(Character character, Set<String> newItemIds) {
    final ownedItems = _ownedItemsOf(character);
    final effectTypes = presentEffectTypes(ownedItems);
    final selectedEffect = retainedFilterSelection(
      _selectedEffect,
      effectTypes,
    );
    final shownItems = selectedEffect == null
        ? ownedItems
        : ownedItems.where(
            (owned) => owned.item?.asLoot?.effect == selectedEffect,
          );
    return Dropdown(
      sectionName: 'Oggetti',
      badge: newItemIds.isEmpty ? null : const NewEntrySigil(),
      data: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (effectTypes.isNotEmpty)
            ItemsFilter<EffectType>(
              values: effectTypes,
              current: selectedEffect,
              onTap: (effect) => setState(() => _selectedEffect = effect),
              getImage: (effect) => effect.imagePath,
            ),
          BlocBuilder<CompanionVitalityCubit, CompanionVitalityState>(
            builder: (context, vitalities) =>
                BlocBuilder<PotionRecoveryCubit, PotionRecoveryState>(
                  builder: (context, recovery) {
                    final targets = _targetsOf(character, vitalities);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final owned in shownItems)
                          if (owned.item case final item?)
                            _row(
                              context,
                              character: character,
                              item: item,
                              quantity: owned.quantity,
                              remaining: recovery.remaining,
                              targets: targets,
                              isNew: newItemIds.contains(item.id),
                            ),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  /// I compagni che potrebbero bere, letti dalla vita servita (D-07, D-32);
  /// nessuno a cura spenta (Pitfall 3).
  List<CompanionPotionTarget> _targetsOf(
    Character character,
    CompanionVitalityState vitalities,
  ) {
    if (!widget.isCompanionCareEnabled) return const [];
    return companionPotionTargetsOf(
      character.assets?.ownedPets ?? const [],
      vitalityOf: vitalities.vitalityOf,
      potionWaitOf: vitalities.potionWaitOf,
    );
  }

  /// Fatti dai modelli, nulla di calcolato: pozione (effetto + ricarica),
  /// attesa di soccorso, missione in corso (Phase 21 D-12), countdown della
  /// ricarica (D-11, D-12) e compagni che possono bere durante l'attesa del
  /// personaggio (D-32).
  Widget _row(
    BuildContext context, {
    required Character character,
    required AssetItem item,
    required int? quantity,
    required Duration? remaining,
    required List<CompanionPotionTarget> targets,
    required bool isNew,
  }) => NewEntryMarked(
    isNew: isNew,
    corner: Offset(ItemRow.padding.left + widget.size, ItemRow.padding.top),
    child: _potionAwareRow(
      context,
      character: character,
      item: item,
      quantity: quantity,
      remaining: remaining,
      targets: targets,
    ),
  );

  Widget _potionAwareRow(
    BuildContext context, {
    required Character character,
    required AssetItem item,
    required int? quantity,
    required Duration? remaining,
    required List<CompanionPotionTarget> targets,
  }) {
    final potion = _potionOf(item);
    final isAwaitingAid = character.status?.awaitingAid != null;
    if (potion == null || isAwaitingAid) {
      return _itemRow(character, item, quantity);
    }
    if (character.isOnMission) {
      return _itemRow(
        character,
        item,
        quantity,
        isDisabled: true,
        statusLine: missionInProgressLabel,
      );
    }
    final statusLine = remaining == null ? null : potionReadyInLine(remaining);
    if (statusLine != null && targets.isEmpty) {
      return _itemRow(
        character,
        item,
        quantity,
        isDisabled: true,
        statusLine: statusLine,
      );
    }
    return _itemRow(
      character,
      item,
      quantity,
      statusLine: statusLine,
      onSelect: (_) => _confirmDrink(context, character, potion, targets),
    );
  }

  /// Le ferite dell'oste del personaggio restano fuori da «Cura: …» (D-15).
  Widget _itemRow(
    Character character,
    AssetItem item,
    int? quantity, {
    void Function(AssetItem)? onSelect,
    bool isDisabled = false,
    String? statusLine,
  }) => ItemRow(
    assetItem: item,
    quantity: quantity,
    showCoins: false,
    size: widget.size,
    onSelect: onSelect,
    isDisabled: isDisabled,
    statusLine: statusLine,
    injuriesBeyondCure: _injuriesBeyondCureOf(character),
  );

  List<InjuryType> _injuriesBeyondCureOf(Character character) =>
      character.status?.innkeeperInjuries ?? const [];

  /// Il foglio vive sul navigator radice, fuori dai provider della shell: i
  /// cubit gli arrivano per valore, la vita massima e i compagni che possono
  /// bere per parametro (letti all'apertura).
  void _confirmDrink(
    BuildContext context,
    Character character,
    LootItem potion,
    List<CompanionPotionTarget> targets,
  ) {
    final potionCubit = context.read<PotionCubit>()..reset();
    final recoveryCubit = context.read<PotionRecoveryCubit>();
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      useSafeArea: false,
      isScrollControlled: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<PotionCubit>.value(value: potionCubit),
          BlocProvider<PotionRecoveryCubit>.value(value: recoveryCubit),
        ],
        child: NotificationListener<DraggableScrollableNotification>(
          onNotification: (_) => potionCubit.state is PotionDrinking,
          child: PaperSheetModal(
            child: PotionSheet(
              item: potion,
              maxLifePoints: character.status?.maxLifePoints,
              targets: targets,
              injuriesBeyondCure: _injuriesBeyondCureOf(character),
            ),
          ),
        ),
      ),
    );
  }
}
