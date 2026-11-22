part of 'new_entries_cubit.dart';

class NewEntriesState extends Equatable {
  const NewEntriesState({this.unseen = const {}, this.highlighted = const {}});

  /// Aggiunte non ancora viste, per categoria: accendono il sigillo sul menù.
  final Map<NewEntryCategory, Set<String>> unseen;

  /// Aggiunte da segnare nella pagina, fissate all'ultima visita.
  final Map<NewEntryCategory, Set<String>> highlighted;

  bool hasUnseenIn(Set<NewEntryCategory> categories) =>
      categories.any(unseen.containsKey);

  Set<String> highlightedOf(NewEntryCategory category) =>
      highlighted[category] ?? const {};

  @override
  List<Object?> get props => [unseen, highlighted];
}
