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
  final List<Lore> lore;

  const LibraryLoadData(this.lore);

  @override
  List<Object?> get props => [lore];
}

class LibraryError extends LibraryState {
  final String errorMessage;

  const LibraryError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
