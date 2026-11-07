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
  final String errorMessage;

  const LibraryError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
