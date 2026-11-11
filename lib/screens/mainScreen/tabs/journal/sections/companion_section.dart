import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/companion_content.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';

Character? _characterOf(CharacterState state) =>
    state is CharacterLoaded ? state.character : null;

List<OwnedPet> _ownedPetsOf(Character character) =>
    character.assets?.ownedPets ?? const <OwnedPet>[];

/// Il compagno da mostrare: prima tra i posseduti, poi l'equipaggiato.
Pet? _displayedPet(Character character, String? displayedId) {
  if (displayedId == null) return null;
  for (final owned in _ownedPetsOf(character)) {
    if (owned.pet.id == displayedId) return owned.pet;
  }
  final equipped = character.assets?.pet;
  return equipped?.id == displayedId ? equipped : null;
}

/// Sezione «Compagno» del Diario (D-10, D-17): un dropdown come «Magie
/// imparate», con lo slot in testa e le pergamene dei posseduti; il tocco
/// equipaggia, il tocco su chi è al fianco lo toglie (overlay ottimistico di
/// `CompanionCubit`). Interattiva anche in viaggio (BE D-15).
class CompanionSection extends StatelessWidget {
  const CompanionSection({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<CharacterCubit, CharacterState, Character?>(
        selector: _characterOf,
        builder: (context, character) {
          if (character == null) return const SizedBox.shrink();
          return BlocBuilder<CompanionCubit, CompanionState>(
            builder: (context, companion) => Dropdown(
              sectionName: 'Compagno',
              data: CompanionContent(
                owned: _ownedPetsOf(character),
                displayed: _displayedPet(
                  character,
                  companion.displayedPetId(character),
                ),
                pendingPetId: companion.pending?.petId,
                cardSize: size,
                onToggle: (petId) => _toggle(context, character, petId),
              ),
            ),
          );
        },
      );

  /// Con un'operazione in corso il tocco non fa nulla e si riprova dopo
  /// l'esito (IN-04); altrimenti l'aptica conferma l'intento.
  void _toggle(BuildContext context, Character character, String petId) {
    final intent = context.read<CompanionCubit>().toggle(character, petId);
    if (intent == CompanionToggleIntent.ignoredPending) return;
    HapticFeedback.lightImpact();
  }
}
