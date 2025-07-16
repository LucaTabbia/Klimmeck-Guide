part of 'storage_cubit.dart';

@immutable
abstract class StorageState {}

class StorageInitial extends StorageState {}

class StorageUpdated extends StorageState {}

class StorageError extends StorageState {}
