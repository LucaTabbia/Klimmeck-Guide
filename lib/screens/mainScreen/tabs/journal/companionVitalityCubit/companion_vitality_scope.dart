import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionVitalityCubit/companion_vitality_cubit.dart';

/// Fornisce al Diario la vita dei compagni e la riallinea in silenzio a ogni
/// personaggio servito (D-09; regola 2: nessun caricamento).
class CompanionVitalityScope extends StatelessWidget {
  const CompanionVitalityScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocProvider<CompanionVitalityCubit>(
    create: (context) => _followed(
      CompanionVitalityCubit(clock: context.read<ServerClockService>()),
      context.read<CharacterCubit>().state,
    ),
    child: BlocListener<CharacterCubit, CharacterState>(
      listenWhen: (previous, current) =>
          current is CharacterLoaded &&
          _characterOf(previous) != current.character,
      listener: (context, state) =>
          _followed(context.read<CompanionVitalityCubit>(), state),
      child: child,
    ),
  );

  static CompanionVitalityCubit _followed(
    CompanionVitalityCubit cubit,
    CharacterState state,
  ) => cubit..follow(_ownedOf(state), equippedPetId: _equippedIdOf(state));

  static Character? _characterOf(CharacterState state) =>
      state is CharacterLoaded ? state.character : null;

  static List<OwnedPet> _ownedOf(CharacterState state) =>
      _characterOf(state)?.assets?.ownedPets ?? const [];

  static String? _equippedIdOf(CharacterState state) =>
      _characterOf(state)?.assets?.pet?.id;
}
