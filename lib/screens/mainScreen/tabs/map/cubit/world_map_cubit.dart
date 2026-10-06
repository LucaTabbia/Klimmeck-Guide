import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

import '../../../../../models/lore.dart';
import '../../../../../repository/services/graphql/graphql.dart';

part 'world_map_state.dart';

class WorldMapCubit extends Cubit<WorldMapState>
    with SafeEmit<WorldMapState> {
  WorldMapCubit(this.graphQl) : super(WorldMapInitial());

  final KlimmeckGraphQl graphQl;

  Future<void> loadLoreData(String id) async {
    emit(WorldMapLoading());
    try {
      final lore = await graphQl.getLoreById(id);

      emit(WorldMapLoadData(lore));
        } catch (e) {
      print(e.toString());
      emit(WorldMapError(e.toString()));
    }
  }
}
