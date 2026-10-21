part of 'notification_permission_cubit.dart';

/// Stato del permesso di sistema visto da Impostazioni; `null` finché non è stato letto.
class NotificationPermissionState extends Equatable {
  const NotificationPermissionState({this.status});

  final NotificationPermissionStatus? status;

  /// D-10: la riga compare solo con il permesso davvero negato, mai per "mai chiesto".
  bool get showsDisabledHint => status == NotificationPermissionStatus.denied;

  @override
  List<Object?> get props => [status];
}
