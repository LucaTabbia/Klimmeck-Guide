part of 'in_app_notifications_cubit.dart';

class InAppNotificationsState extends Equatable {
  const InAppNotificationsState({this.current});

  /// Evento del banner visibile; `null` = nessun banner.
  final PushEvent? current;

  @override
  List<Object?> get props => [current];
}
