import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_port.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'notification_permission_state.dart';

/// Legge (mai chiede) il permesso notifiche per la riga di Impostazioni (D-10): alla montatura
/// della shell e a ogni ritorno in foreground, cioè anche al rientro dalle impostazioni di sistema.
class NotificationPermissionCubit extends Cubit<NotificationPermissionState>
    with SafeEmit<NotificationPermissionState> {
  NotificationPermissionCubit(
    this._permission, {
    required AppLifecycleEvents lifecycle,
  }) : super(const NotificationPermissionState()) {
    _foregrounded = lifecycle.foregrounded.listen((_) => refresh());
  }

  final NotificationPermissionPort _permission;
  late final StreamSubscription<void> _foregrounded;

  Future<void> refresh() async {
    try {
      emit(NotificationPermissionState(status: await _permission.status()));
    } on Object catch (error) {
      debugPrint(
        '[NotificationPermission] status failed: ${error.runtimeType}',
      );
    }
  }

  Future<void> openSettings() async {
    try {
      await _permission.openSettings();
    } on Object catch (error) {
      debugPrint(
        '[NotificationPermission] settings not opened: ${error.runtimeType}',
      );
    }
  }

  /// `super.close()` parte subito, in parallelo alla cancellazione: chi chiude senza
  /// attendere (il provider della shell) trova il cubit già chiuso.
  @override
  Future<void> close() => Future.wait([_foregrounded.cancel(), super.close()]);
}
