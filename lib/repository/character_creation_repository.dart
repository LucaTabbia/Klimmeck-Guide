import 'dart:io';

import 'package:dio/dio.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/character/race_traits.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/request/create_character_request.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/character_creation_failure.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/image/portrait_picker.dart';
import 'package:klimmeck_guide/repository/services/rest/image_upload_exception.dart';
import 'package:klimmeck_guide/repository/services/rest/rest.dart';

/// Unico accesso della creazione personaggio ai servizi: traduce ogni errore in
/// [CharacterCreationException] (graphql.md: mai OperationException alla UI).
class CharacterCreationRepository {
  CharacterCreationRepository({
    required KlimmeckGraphQl graphQl,
    required KlimmeckRest rest,
    required PortraitPicker picker,
  }) : _graphQl = graphQl,
       _rest = rest,
       _picker = picker;

  final KlimmeckGraphQl _graphQl;
  final KlimmeckRest _rest;
  final PortraitPicker _picker;

  Future<Map<RaceType, RaceTraits>> loadRaceTraits() => _guard(() async {
    final traits = await _graphQl.getRaceTraits();
    return Map.unmodifiable({for (final entry in traits) entry.race: entry});
  });

  Future<String?> pickPortrait(PortraitSource source) => _picker.pick(source);

  Future<String> uploadPortrait(String localPath) async {
    try {
      return await _rest.uploadImage(File(localPath));
    } on ImageUploadException {
      throw const CharacterCreationException(
        CharacterCreationFailure.uploadFailed,
      );
    } on DioException {
      throw const CharacterCreationException(
        CharacterCreationFailure.uploadFailed,
      );
    } on FileSystemException {
      throw const CharacterCreationException(
        CharacterCreationFailure.uploadFailed,
      );
    }
  }

  Future<User> createCharacter(CreateCharacterRequest request) =>
      _guard(() => _graphQl.createCharacter(request));

  Future<User> fetchCurrentUser() => _guard(_graphQl.getMe);

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on OperationException catch (error) {
      throw CharacterCreationException(characterCreationFailureFrom(error));
    } on FormatException {
      throw const CharacterCreationException(CharacterCreationFailure.unknown);
    }
  }
}
