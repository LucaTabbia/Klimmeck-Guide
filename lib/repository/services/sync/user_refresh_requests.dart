import 'dart:async';

/// Richiesta di rinfrescare l'utente (`me`). Lo stream del personaggio
/// rifiutato con FORBIDDEN/NOT_FOUND non deve ritentare (martellerebbe il
/// server): l'unico rimedio a un `currentCharacter` obsoleto e' un refetch di
/// `me`, che spetta al proprietario dello stream utente (`SessionSyncCubit`).
/// Questo bus permette a `CharacterCubit` di chiederlo senza chiamate
/// cubit-to-cubit.
abstract interface class UserRefreshRequests {
  void requestUserRefresh();
}

class UserRefreshRequestBus implements UserRefreshRequests {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get requests => _controller.stream;

  @override
  void requestUserRefresh() {
    if (_controller.isClosed) return;
    _controller.add(null);
  }

  Future<void> close() => _controller.close();
}
