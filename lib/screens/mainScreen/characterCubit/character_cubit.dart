import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/character/character.dart';

part 'character_state.dart';

class CharacterCubit extends Cubit<CharacterState> {
  final KlimmeckGraphQl api;
  StreamSubscription<Character>? _sub;

  CharacterCubit(this.api) : super(CharacterInitial());

  Future<void> loadCharacter(String id) async {
    emit(CharacterLoading());
    try {
      final character = await api.getCharacter(id);
      emit(CharacterLoaded(character));
      subscribeToCharacter(id);
    } catch (e) {
      emit(CharacterError(e.toString()));
    }
  }

  Future<void> changeCharacterLocation(
    LatLng newLocation,
    String locationId,
  ) async {}

  void subscribeToCharacter(String id) {
    if (_sub != null) {
      _sub!.cancel();
    }

    _sub = api.subscribeToCharacter(id).listen((character) {
      emit(CharacterLoaded(character));
    }, onError: (e) => emit(CharacterError(e.toString())));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
