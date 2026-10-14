import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';
import 'package:klimmeck_guide/repository/services/graphql/ws_reconnect_policy.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/sync_health.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';
import 'package:klimmeck_guide/utils/backoff.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/character/character.dart';

part 'character_state.dart';

/// Stato del personaggio della sessione. Al cold start `loadCharacter` emette
/// Loading poi Loaded | Error (D-16: KGError e pull-to-refresh del MainScreen).
/// In sessione, una volta caricato, esiste solo `CharacterLoaded` (CLAUDE.md
/// regola 2): errori e chiusure dello stream ri-sottoscrivono in silenzio con
/// backoff limitato (D-14) e ogni evento rimpiazza l'intero `Character` (D-19).
///
/// FORBIDDEN/NOT_FOUND sullo stream e' terminale (vincolo backend): ritentare
/// martellerebbe il server. Il cubit tiene l'ultimo stato e chiede un solo
/// refresh dell'utente via `UserRefreshRequests`; il recupero spetta al
/// proprietario dello stream utente (la shell si ri-chiava al cambio di
/// `currentCharacter`, plan 08).
class CharacterCubit extends Cubit<CharacterState>
    with SafeEmit<CharacterState> {
  CharacterCubit(
    this.api, {
    required SyncHealth health,
    required AppLifecycleEvents lifecycle,
    required UserRefreshRequests userRefresh,
  }) : _health = health,
       _lifecycle = lifecycle,
       _userRefresh = userRefresh,
       super(CharacterInitial());

  final KlimmeckGraphQl api;
  final SyncHealth _health;
  final AppLifecycleEvents _lifecycle;
  final UserRefreshRequests _userRefresh;

  StreamSubscription<Character>? _sub;
  String? _characterId;
  Timer? _resubscribeTimer;
  int _attempt = 0;
  int _eventCount = 0;
  bool _isStreamTerminated = false;

  Future<void> loadCharacter(String id) async {
    _characterId = id;
    emit(CharacterLoading());
    try {
      final character = await api.getCharacter(id);
      if (isClosed) return;
      emit(CharacterLoaded(character));
      subscribeToCharacter(id);
    } catch (error) {
      if (isAccessDeniedError(error)) _userRefresh.requestUserRefresh();
      emit(CharacterError(error.toString()));
    }
  }

  Future<void> changeCharacterLocation(
    LatLng newLocation,
    String locationId,
  ) async {}

  void subscribeToCharacter(String id) {
    _sub?.cancel();
    _sub = api
        .subscribeToCharacter(id)
        .listen(_onCharacter, onError: _onStreamError, onDone: _onStreamDone);
  }

  void _onCharacter(Character character) {
    _eventCount++;
    _attempt = 0;
    _health.markHealthy(SyncSource.characterStream);
    emit(CharacterLoaded(character));
  }

  void _onStreamError(Object error) {
    if (isAccessDeniedError(error)) {
      _terminateStream(error);
      return;
    }
    _scheduleResubscribe();
  }

  void _onStreamDone() {
    if (isClosed || _isStreamTerminated) return;
    _scheduleResubscribe();
  }

  void _terminateStream(Object error) {
    if (_isStreamTerminated) return;
    _isStreamTerminated = true;
    _sub?.cancel();
    _health.markTerminated(SyncSource.characterStream);
    final code = error is SubscriptionStreamException
        ? error.code
        : error.runtimeType;
    debugPrint('[Sync] characterUpdated rejected: $code');
    _userRefresh.requestUserRefresh();
  }

  void _scheduleResubscribe() {
    if (_resubscribeTimer != null ||
        isClosed ||
        _isStreamTerminated ||
        _characterId == null) {
      return;
    }
    _health.markDegraded(SyncSource.characterStream);
    _sub?.cancel();
    _resubscribeTimer = Timer(
      exponentialBackoff(_attempt++, max: WsReconnectPolicy.maxReconnectDelay),
      () {
        _resubscribeTimer = null;
        if (!isClosed) subscribeToCharacter(_characterId!);
      },
    );
  }

  @override
  Future<void> close() {
    _resubscribeTimer?.cancel();
    _health.release(SyncSource.characterStream);
    return Future.wait([?_sub?.cancel(), super.close()]);
  }
}
