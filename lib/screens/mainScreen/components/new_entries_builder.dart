import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/enums/new_entry_category.dart';
import 'package:klimmeck_guide/screens/mainScreen/newEntriesCubit/new_entries_cubit.dart';

/// Costruisce con le aggiunte di [category] da segnare nella pagina e si
/// ricostruisce solo quando cambiano.
class NewEntriesBuilder extends StatelessWidget {
  const NewEntriesBuilder({
    super.key,
    required this.category,
    required this.builder,
  });

  final NewEntryCategory category;
  final Widget Function(BuildContext context, Set<String> newIds) builder;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<NewEntriesCubit, NewEntriesState, Set<String>>(
        selector: (state) => state.highlightedOf(category),
        builder: builder,
      );
}
