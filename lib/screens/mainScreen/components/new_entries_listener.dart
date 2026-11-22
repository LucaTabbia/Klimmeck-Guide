import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/newEntriesCubit/new_entries_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/newEntriesCubit/new_entry_ids.dart';

/// Tiene il conto delle aggiunte a Diario e Profilo allineato al personaggio,
/// da qualunque pagina: serve al sigillo sulle voci del menù.
class NewEntriesListener extends StatefulWidget {
  const NewEntriesListener({super.key, required this.child});

  final Widget child;

  @override
  State<NewEntriesListener> createState() => _NewEntriesListenerState();
}

class _NewEntriesListenerState extends State<NewEntriesListener> {
  @override
  void initState() {
    super.initState();
    _sync(context.read<CharacterCubit>().state);
  }

  void _sync(CharacterState state) {
    if (state is! CharacterLoaded) return;
    context.read<NewEntriesCubit>().sync(newEntryIdsOf(state.character));
  }

  static bool _hasCharacterChanged(
    CharacterState previous,
    CharacterState current,
  ) =>
      current is CharacterLoaded &&
      (previous is! CharacterLoaded || previous.character != current.character);

  @override
  Widget build(BuildContext context) {
    return BlocListener<CharacterCubit, CharacterState>(
      listenWhen: _hasCharacterChanged,
      listener: (_, state) => _sync(state),
      child: widget.child,
    );
  }
}
