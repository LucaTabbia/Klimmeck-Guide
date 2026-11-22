import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/newsCubit/library_news_cubit.dart';

/// Tiene il conto dei libri con novità allineato alle lore sbloccate del
/// personaggio, da qualunque pagina: serve al sigillo sulla voce «Libreria».
class LibraryNewsListener extends StatefulWidget {
  const LibraryNewsListener({super.key, required this.child});

  final Widget child;

  @override
  State<LibraryNewsListener> createState() => _LibraryNewsListenerState();
}

class _LibraryNewsListenerState extends State<LibraryNewsListener> {
  @override
  void initState() {
    super.initState();
    _sync(context.read<CharacterCubit>().state);
  }

  void _sync(CharacterState state) {
    final unlocked = unlockedLoreOf(state);
    if (unlocked == null) return;
    context.read<LibraryNewsCubit>().syncUnlockedLore(unlocked);
  }

  static bool _hasUnlockedLoreChanged(
    CharacterState previous,
    CharacterState current,
  ) {
    final after = unlockedLoreOf(current);
    if (after == null) return false;
    final before = unlockedLoreOf(previous);
    return before == null || !setEquals(before.toSet(), after.toSet());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CharacterCubit, CharacterState>(
      listenWhen: _hasUnlockedLoreChanged,
      listener: (_, state) => _sync(state),
      child: widget.child,
    );
  }
}
