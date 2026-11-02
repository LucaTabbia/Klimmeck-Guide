import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart';
import 'package:klimmeck_guide/shared/components/companion_row.dart';
import 'package:klimmeck_guide/shared/components/modal/paper_sheet_modal.dart';
import 'package:klimmeck_guide/shared/components/section.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

const String emptyCompanionSlotLine = 'Nessun compagno al tuo fianco';
const String noOwnedCompanionsLine = 'Non possiedi compagni';

Character? _characterOf(CharacterState state) =>
    state is CharacterLoaded ? state.character : null;

List<Pet> _ownedPetsOf(Character character) =>
    character.assets?.ownedPets ?? const <Pet>[];

/// Il compagno da mostrare: prima tra i posseduti, poi l'equipaggiato.
Pet? _displayedPet(Character character, String? displayedId) {
  if (displayedId == null) return null;
  for (final pet in _ownedPetsOf(character)) {
    if (pet.id == displayedId) return pet;
  }
  final equipped = character.assets?.pet;
  return equipped?.id == displayedId ? equipped : null;
}

/// Slot «Compagno» del Diario (D-10): il compagno mostrato è quello
/// equipaggiato, o quello in attesa nell'overlay ottimistico; il tap apre i
/// compagni posseduti. Interattivo anche in viaggio (BE D-15). Visual provvisorio.
class CompanionSection extends StatelessWidget {
  const CompanionSection({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CharacterCubit, CharacterState>(
        builder: (context, characterState) {
          final character = _characterOf(characterState);
          if (character == null) return const SizedBox.shrink();
          return BlocBuilder<CompanionCubit, CompanionState>(
            builder: (context, companion) {
              final displayedId = companion.displayedPetId(character);
              return Section(
                sectionName: 'Compagno',
                data: GestureDetector(
                  key: const ValueKey('companion_slot'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openOwned(context, character, displayedId),
                  child: _slotOf(_displayedPet(character, displayedId)),
                ),
              );
            },
          );
        },
      );

  Widget _slotOf(Pet? pet) {
    if (pet == null) {
      return Text(
        emptyCompanionSlotLine,
        style: KlimmeckGuideTheme.instance.bodyMedium,
      );
    }
    return CompanionRow(
      pet: pet,
      size: size,
      showCoins: false,
      isEquipped: true,
    );
  }

  /// Il foglio vive sopra i provider della shell: il cubit si legge prima.
  void _openOwned(
    BuildContext context,
    Character character,
    String? displayedId,
  ) {
    final cubit = context.read<CompanionCubit>();
    final owned = _ownedPetsOf(character);
    showModalBottomSheet<void>(
      useSafeArea: false,
      isScrollControlled: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      backgroundColor: Colors.transparent,
      context: context,
      builder: (sheetContext) => PaperSheetModal(
        child: ListView(
          children: owned.isEmpty
              ? [
                  Text(
                    noOwnedCompanionsLine,
                    style: KlimmeckGuideTheme.instance.bodyMedium,
                  ),
                ]
              : [
                  for (final pet in owned)
                    CompanionRow(
                      key: ValueKey('owned-pet-${pet.id}'),
                      pet: pet,
                      size: size,
                      showCoins: false,
                      isEquipped: pet.id == displayedId,
                      onTap: () {
                        _toggleWithFeedback(cubit, character, pet);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
        ),
      ),
    );
  }

  void _toggleWithFeedback(CompanionCubit cubit, Character character, Pet pet) {
    final intent = cubit.toggle(character, pet.id);
    if (intent != CompanionToggleIntent.ignoredPending) {
      HapticFeedback.lightImpact();
    }
  }
}
