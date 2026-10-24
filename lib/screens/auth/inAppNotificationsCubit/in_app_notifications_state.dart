part of 'in_app_notifications_cubit.dart';

/// Avviso locale di dominio (es. rifiuto di una quest, Phase 6 D-04): stesso
/// banner dei push, ma il tap lo chiude soltanto.
class InAppNotice extends Equatable {
  const InAppNotice({required this.notification, required this.dedupKey});

  final KGNotification notification;
  final String dedupKey;

  @override
  List<Object?> get props => [notification, dedupKey];
}

class InAppNotificationsState extends Equatable {
  const InAppNotificationsState({this.current, this.notice});

  /// Evento push del banner visibile; `null` = nessun push.
  final PushEvent? current;

  /// Avviso locale visibile; mai insieme a [current].
  final InAppNotice? notice;

  bool get isShowing => current != null || notice != null;

  @override
  List<Object?> get props => [current, notice];
}
