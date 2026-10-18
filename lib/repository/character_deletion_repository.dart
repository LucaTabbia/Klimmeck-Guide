import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/character_deletion_failure.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

/// Unico accesso dell'eliminazione personaggio ai servizi: ogni errore
/// diventa [CharacterDeletionException] (graphql.md: mai OperationException alla UI).
class CharacterDeletionRepository {
  CharacterDeletionRepository({required KlimmeckGraphQl graphQl})
    : _graphQl = graphQl;

  final KlimmeckGraphQl _graphQl;

  Future<User> deleteCurrentCharacter() => _guard(_graphQl.deleteCharacter);

  Future<User> fetchCurrentUser() => _guard(_graphQl.getMe);

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on OperationException catch (error) {
      throw CharacterDeletionException(characterDeletionFailureFrom(error));
    } on FormatException {
      throw const CharacterDeletionException(CharacterDeletionFailure.unknown);
    }
  }
}
