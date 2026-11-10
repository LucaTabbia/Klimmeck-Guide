import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/asset_item.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/potion_sheet.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_cubit.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';
import 'package:klimmeck_guide/shared/components/items_filter.dart';
import 'package:klimmeck_guide/shared/components/modal/paper_sheet_modal.dart';
import 'package:klimmeck_guide/utils/filter_values.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

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
/// mai in attesa di soccorso (D-11).
class ItemsSection extends StatelessWidget {
  const ItemsSection({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => BlocProvider<PotionRecoveryCubit>(
    create: (context) =>
        PotionRecoveryCubit(clock: context.read<ServerClockService>()),
    child: _ItemsSectionBody(size: size),
  );
}

class _ItemsSectionBody extends StatefulWidget {
  const _ItemsSectionBody({required this.size});

  final double size;

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
              : _buildSection(character),
        ),
      );

  Widget _buildSection(Character character) {
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
          BlocBuilder<PotionRecoveryCubit, PotionRecoveryState>(
            builder: (context, recovery) => Column(
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
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tre fatti dai modelli, nulla di calcolato: pozione (effetto + ricarica),
  /// attesa di soccorso, countdown della ricarica (D-11, D-12).
  Widget _row(
    BuildContext context, {
    required Character character,
    required AssetItem item,
    required int? quantity,
    required Duration? remaining,
  }) {
    final potion = _potionOf(item);
    final isAwaitingAid = character.status?.awaitingAid != null;
    if (potion == null || isAwaitingAid) {
      return _itemRow(item, quantity);
    }
    if (remaining != null) {
      return _itemRow(
        item,
        quantity,
        isDisabled: true,
        statusLine: potionReadyInLine(remaining),
      );
    }
    return _itemRow(
      item,
      quantity,
      onSelect: (_) => _confirmDrink(context, character, potion),
    );
  }

  Widget _itemRow(
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
  );

  /// Il foglio vive sul navigator radice, fuori dai provider della shell: il
  /// cubit della shell gli arriva per valore, la vita massima per parametro.
  void _confirmDrink(
    BuildContext context,
    Character character,
    LootItem potion,
  ) {
    final potionCubit = context.read<PotionCubit>()..reset();
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      useSafeArea: false,
      isScrollControlled: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => BlocProvider.value(
        value: potionCubit,
        child: NotificationListener<DraggableScrollableNotification>(
          onNotification: (_) => potionCubit.state is PotionDrinking,
          child: PaperSheetModal(
            child: PotionSheet(
              item: potion,
              maxLifePoints: character.status?.maxLifePoints ?? 0,
            ),
          ),
        ),
      ),
    );
  }
}
