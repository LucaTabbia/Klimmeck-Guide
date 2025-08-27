part of 'library_cubit.dart';

@immutable
abstract class LibraryState {}

class LibraryInitial extends LibraryState {}

class LibraryLoadData extends LibraryState {
  final List<Lore> lore;

  LibraryLoadData(this.lore);
}

class LibraryLoading extends LibraryState {}

class LibraryError extends LibraryState {
  final String errorMessage;

  LibraryError(this.errorMessage);
}
