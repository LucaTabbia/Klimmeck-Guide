import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/prisonCubit/prison_cubit.dart';

/// Porta la fine della prigione dello stato del personaggio al PrisonCubit
/// (quick 261110-cgd): subito al montaggio e a ogni `characterUpdated` che la
/// cambia (un Cubit non ascolta un Cubit).
class PrisonStatusListener extends StatefulWidget {
  const PrisonStatusListener({super.key, required this.child});

  final Widget child;

  @override
  State<PrisonStatusListener> createState() => _PrisonStatusListenerState();
}

class _PrisonStatusListenerState extends State<PrisonStatusListener> {
  @override
  void initState() {
    super.initState();
    _follow(context.read<CharacterCubit>().state);
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<CharacterCubit, CharacterState>(
        listenWhen: (previous, current) =>
            _releaseOf(previous) != _releaseOf(current),
        listener: (_, state) => _follow(state),
        child: widget.child,
      );

  void _follow(CharacterState state) =>
      context.read<PrisonCubit>().followStatus(_releaseOf(state));

  static DateTime? _releaseOf(CharacterState state) =>
      state is CharacterLoaded ? state.character.status?.imprisonedUntil : null;
}
