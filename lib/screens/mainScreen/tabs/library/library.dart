import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/enums/lore_type.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/cubit/library_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_data_page.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_error_page.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_initial_page.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  late List<LoreType> _selectedTypes;
  late String _title;
  late String _bookmarkImagePath;

  @override
  void initState() {
    context.read<LibraryCubit>().goToInitial();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundImage(
      child: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          if (state is LibraryInitial) {
            return LibraryInitialPage(onTap: getData);
          } else if (state is LibraryLoadData) {
            return LibraryDataPage(
              lore: state.lore,
              types: _selectedTypes,
              onBack: () => context.read<LibraryCubit>().goToInitial(),
              title: _title,
              bookmarkImagePath: _bookmarkImagePath,
            );
          } else if (state is LibraryError) {
            return LibraryErrorPage();
          } else {
            return Placeholder();
          }
        },
      ),
    );
  }

  void getData(List<LoreType> types, String title, String bookmarkImagePath) {
    setState(() {
      _selectedTypes = types;
      _title = title;
      _bookmarkImagePath = bookmarkImagePath;
    });
    context.read<LibraryCubit>().loadLoreData(types);
  }
}
