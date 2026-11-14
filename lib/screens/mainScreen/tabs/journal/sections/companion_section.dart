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
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/mission_lines.dart';

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
/// `CompanionCubit`). Interattiva anche in viaggio (BE D-15). Bloccata
/// durante una missione in corso (Phase 21 D-12): il tocco non fa nulla e
/// la sezione lo dice in testa.
class CompanionSection extends StatelessWidget {
  const CompanionSection({super.key, required this.size});

  static const Key missionLockedKey = ValueKey(
    'journal.companion.missionLocked',
  );

  final double size;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<CharacterCubit, CharacterState, Character?>(
        selector: _characterOf,
        builder: (context, character) {
          if (character == null) return const SizedBox.shrink();
          final isOnMission = character.status?.missionInProgress ?? false;
          return BlocBuilder<CompanionCubit, CompanionState>(
            builder: (context, companion) {
              final content = CompanionContent(
                owned: _ownedPetsOf(character),
                displayed: _displayedPet(
                  character,
                  companion.displayedPetId(character),
                ),
                pendingPetId: companion.pending?.petId,
                cardSize: size,
                onToggle: isOnMission
                    ? _ignoreToggle
                    : (petId) => _toggle(context, character, petId),
              );
              return Dropdown(
                sectionName: 'Compagno',
                data: isOnMission ? _missionLocked(content) : content,
              );
            },
          );
        },
      );

  static void _ignoreToggle(String _) {}

  static Widget _missionLocked(Widget content) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        missionInProgressLabel,
        key: missionLockedKey,
        style: KlimmeckGuideTheme.instance.bodyMedium,
      ),
      content,
    ],
  );

  /// Con un'operazione in corso il tocco non fa nulla e si riprova dopo
  /// l'esito (IN-04); altrimenti l'aptica conferma l'intento.
  void _toggle(BuildContext context, Character character, String petId) {
    final intent = context.read<CompanionCubit>().toggle(character, petId);
    if (intent == CompanionToggleIntent.ignoredPending) return;
    HapticFeedback.lightImpact();
  }
}
