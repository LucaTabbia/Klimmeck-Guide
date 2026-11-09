part of 'library_cubit.dart';

@immutable
abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

class LibraryInitial extends LibraryState {
  const LibraryInitial();
}

class LibraryLoading extends LibraryState {
  const LibraryLoading();
}

class LibraryLoadData extends LibraryState {
  const LibraryLoadData({
    required this.book,
    required this.lore,
    required this.newLoreIds,
  });

  final LibraryBook book;

  /// Solo le lore di [book], come le restituisce il BE (D-02).
  final List<Lore> lore;

  /// Id da segnare «Nuovo» (D-07): mai inviati al BE.
  final Set<String> newLoreIds;

  @override
  List<Object?> get props => [book, lore, newLoreIds];
}

class LibraryError extends LibraryState {
  /// Il libro la cui apertura è fallita: la pagina d'errore ne usa la pergamena.
  final LibraryBook book;

  /// Solo per i log: mai mostrato a schermo.
  final String errorMessage;

  const LibraryError(this.book, this.errorMessage);

  @override
  List<Object?> get props => [book, errorMessage];
}
