part of 'session_sync_cubit.dart';

/// Nessuna UI consuma questi stati per scelta di design (D-18): esistono per
/// rendere asseribile il comportamento del cubit nei test.
@immutable
sealed class SessionSyncState extends Equatable {
  const SessionSyncState();

  @override
  List<Object?> get props => [];
}

class SessionSyncStarting extends SessionSyncState {
  const SessionSyncStarting();
}

class SessionSyncLive extends SessionSyncState {
  const SessionSyncLive();
}

class SessionSyncRecovering extends SessionSyncState {
  const SessionSyncRecovering();
}
