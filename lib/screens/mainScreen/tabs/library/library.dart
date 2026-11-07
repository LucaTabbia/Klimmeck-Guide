import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/library_book_art.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_data_page.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_error_page.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_initial_page.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';

import 'cubit/library_cubit.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  @override
  void initState() {
    super.initState();
    final library = context.read<LibraryCubit>()..goToInitial();
    final unlocked = _unlockedLoreOf(context.read<CharacterCubit>().state);
    if (unlocked != null) library.syncUnlockedLore(unlocked);
  }

  /// Solo gli id (D-01): il confronto per insieme vive nel cubit (D-05).
  static List<String>? _unlockedLoreOf(CharacterState state) =>
      state is CharacterLoaded
      ? state.character.status?.unlockedLore ?? const []
      : null;

  @override
  Widget build(BuildContext context) {
    return BackgroundImage(
      child: BlocListener<CharacterCubit, CharacterState>(
        listenWhen: (_, current) => current is CharacterLoaded,
        listener: (context, state) {
          final unlocked = _unlockedLoreOf(state);
          if (unlocked != null) {
            context.read<LibraryCubit>().syncUnlockedLore(unlocked);
          }
        },
        child: BlocBuilder<LibraryCubit, LibraryState>(
          builder: (context, state) {
            if (state is LibraryInitial) {
              return LibraryInitialPage(
                onOpen: (book) => context.read<LibraryCubit>().openBook(book),
              );
            } else if (state is LibraryLoadData) {
              return LibraryDataPage(
                lore: state.lore,
                types: state.book.types,
                onBack: () => context.read<LibraryCubit>().goToInitial(),
                title: state.book.title,
                bookmarkImagePath: state.book.bookmarkUrl,
              );
            } else if (state is LibraryError) {
              return LibraryErrorPage();
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}
