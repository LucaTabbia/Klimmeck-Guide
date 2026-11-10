import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_cubit.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';
import 'package:klimmeck_guide/shared/components/items_filter.dart';
import 'package:klimmeck_guide/utils/filter_values.dart';

Character? _characterOf(CharacterState state) =>
    state is CharacterLoaded ? state.character : null;

List<AssetQuantity> _ownedItemsOf(Character character) =>
    character.assets?.ownedItems ?? const <AssetQuantity>[];

/// Sezione «Oggetti» del Diario. Possiede il countdown delle pozioni: vive
/// solo mentre la pagina del Diario è a schermo (Phase 18 D-12).
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
          for (final owned in shownItems)
            if (owned.item case final item?)
              ItemRow(
                assetItem: item,
                quantity: owned.quantity,
                showCoins: false,
                size: widget.size,
              ),
        ],
      ),
    );
  }
}
